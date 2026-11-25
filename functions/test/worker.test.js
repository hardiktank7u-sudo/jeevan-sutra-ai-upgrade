import test from "node:test";
import assert from "node:assert/strict";
import worker from "../index.js";

const PROJECT_NUMBER = "311459879132";
const APP_ID = "1:311459879132:android:fd34669cd00b4c6cb6fc19";
const encoder = new TextEncoder();
const env = {
  GEMINI_API_KEY: "test-gemini-api-key-not-real",
  FIREBASE_PROJECT_NUMBER: PROJECT_NUMBER,
  FIREBASE_APP_IDS: APP_ID,
  AI_RATE_LIMITER: {limit: async () => ({success: true})},
};
let appCheckToken;
let jwks;

function base64Url(value) { return Buffer.from(value).toString("base64url"); }

test.before(async () => {
  const {privateKey, publicKey} = await crypto.subtle.generateKey({
    name: "RSASSA-PKCS1-v1_5", modulusLength: 2048,
    publicExponent: new Uint8Array([1, 0, 1]), hash: "SHA-256",
  }, true, ["sign", "verify"]);
  jwks = await crypto.subtle.exportKey("jwk", publicKey);
  jwks.kid = "worker-test-key";
  jwks.alg = "RS256";
  const now = Math.floor(Date.now() / 1000);
  const header = base64Url(JSON.stringify({alg: "RS256", kid: jwks.kid, typ: "JWT"}));
  const payload = base64Url(JSON.stringify({
    aud: [`projects/${PROJECT_NUMBER}`], exp: now + 300, iat: now,
    iss: `https://firebaseappcheck.googleapis.com/${PROJECT_NUMBER}`, sub: APP_ID,
  }));
  const unsigned = `${header}.${payload}`;
  const signature = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", privateKey, encoder.encode(unsigned));
  appCheckToken = `${unsigned}.${base64Url(signature)}`;
});

function request(path, body, headers = {}) {
  return new Request(`https://example.workers.dev${path}`, {
    method: "POST",
    headers: {"Content-Type": "application/json", "X-Firebase-AppCheck": appCheckToken, ...headers},
    body: JSON.stringify(body),
  });
}

async function withMockFetch(geminiHandler, run) {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (url, options = {}) => {
    if (String(url) === "https://firebaseappcheck.googleapis.com/v1/jwks") {
      return new Response(JSON.stringify({keys: [jwks]}), {
        headers: {"Cache-Control": "public, max-age=60"},
      });
    }
    assert.match(String(url), /generativelanguage\.googleapis\.com\/v1beta\/models\/gemini-3\.8-flash:/);
    assert.equal(options.headers["x-goog-api-key"], env.GEMINI_API_KEY);
    return geminiHandler(String(url), options);
  };
  try { return await run(); } finally { globalThis.fetch = originalFetch; }
}

const plantResult = {
  organismType: "plant",
  plantName: "Tulsi", sanskritName: "Tulasi", hindiName: "Tulsi",
  scientificName: "Ocimum tenuiflorum", family: "Lamiaceae", confidence: 0.94,
  plantCategory: "herb",
  medicinalClassification: "medicinal",
  growingInformation: "Grows in warm climates with well-drained soil.",
  identification: "Opposite leaves and a square stem.",
  traditionalUses: "Traditionally used in household wellness.",
  scientificEvidence: "Evidence varies by preparation and study.",
  safetySummary: "Seek qualified advice before medicinal use. Do not consume or use medicinally based solely on image identification.",
  precautions: [
    "Do not infer medicinal safety from identification.",
    "Do not consume or use medicinally based solely on image identification.",
  ],
  isToxic: false,
  toxicityWarning: "Toxicity was not independently verified; do not consume.",
};

test("rejects requests without Firebase App Check", async () => {
  const response = await worker.fetch(new Request("https://example.workers.dev/geminiChat", {
    method: "POST", headers: {"Content-Type": "application/json"},
    body: JSON.stringify({prompt: "hello", history: []}),
  }), env);
  assert.equal(response.status, 401);
  assert.deepEqual(await response.json(), {error: "APP_CHECK_REJECTED"});
});

test("chat sends history to Gemini and translates Gemini SSE to app SSE", async () => {
  await withMockFetch(async (url, options) => {
    assert.match(url, /:streamGenerateContent\?alt=sse$/);
    const payload = JSON.parse(options.body);
    assert.match(payload.systemInstruction.parts[0].text, /Jeevan Sutra AI/);
    assert.deepEqual(payload.contents, [
      {role: "user", parts: [{text: "Tell me about herbs."}]},
      {role: "model", parts: [{text: "I can share educational information."}]},
      {role: "user", parts: [{text: "What is Tulsi?"}]},
    ]);
    assert.equal(payload.generationConfig.maxOutputTokens, 4096);
    assert.equal(payload.generationConfig.temperature, 0.7);
    return new Response(
      'data: {"candidates":[{"content":{"parts":[{"text":"Tulsi "}]}}]}\n\n' +
      'data: {"candidates":[{"content":{"parts":[{"text":"is traditionally valued."}]}}]}\n\n',
      {headers: {"Content-Type": "text/event-stream"}},
    );
  }, async () => {
    const response = await worker.fetch(request("/geminiChat", {
      prompt: "What is Tulsi?",
      history: [
        {role: "user", text: "Tell me about herbs."},
        {role: "model", text: "I can share educational information."},
      ],
    }), env);
    assert.equal(response.status, 200);
    assert.equal(await response.text(),
      'data: {"text":"Tulsi "}\n\n' +
      'data: {"text":"is traditionally valued."}\n\n' +
      "data: [DONE]\n\n");
  });
});

test("plant scan sends inline image data and returns validated Gemini JSON fields", async () => {
  const image = Buffer.from([0xff, 0xd8, 0xff, 0x00, 0x01]).toString("base64");
  await withMockFetch(async (url, options) => {
    assert.match(url, /:generateContent$/);
    const payload = JSON.parse(options.body);
    const parts = payload.contents[0].parts;
    assert.equal(parts.length, 2);
    // Part 0: Separate text prompt part only
    assert.equal(typeof parts[0].text, "string");
    assert.equal(parts[0].inlineData, undefined);
    assert.equal(parts[0].inline_data, undefined);
    assert.equal(parts[0].fileData, undefined);
    assert.deepEqual(Object.keys(parts[0]), ["text"]);
    // Part 1: Exactly one valid inlineData object with mimeType and base64 data, no oneof conflicts
    assert.equal(parts[1].text, undefined);
    assert.equal(parts[1].inline_data, undefined);
    assert.equal(parts[1].fileData, undefined);
    assert.ok(parts[1].inlineData, "inlineData must be defined");
    assert.equal(parts[1].inlineData.mimeType, "image/jpeg");
    assert.equal(parts[1].inlineData.data, image);
    assert.deepEqual(Object.keys(parts[1]), ["inlineData"]);
    assert.deepEqual(Object.keys(parts[1].inlineData).sort(), ["data", "mimeType"]);
    assert.equal(payload.generationConfig.maxOutputTokens, 4096);
    assert.equal(payload.generationConfig.responseMimeType, "application/json");
    assert.equal(payload.generationConfig.responseSchema.properties.family.nullable, true);
    assert.deepEqual(
        payload.generationConfig.responseSchema.properties.medicinalClassification.enum,
        ["medicinal", "non-medicinal", "unknown"],
    );
    assert.deepEqual(
        payload.generationConfig.responseSchema.properties.organismType.enum,
        ["plant", "fungus", "non-plant", "uncertain"],
    );
    return new Response(JSON.stringify({
      candidates: [{content: {parts: [{text: JSON.stringify(plantResult)}]}}],
    }), {headers: {"Content-Type": "application/json"}});
  }, async () => {
    const response = await worker.fetch(request("/geminiPlant", {
      mimeType: "image/jpeg", imageBase64: image,
    }), env);
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), plantResult);
  });
});

test("missing Gemini secret fails safely without calling provider", async () => {
  await withMockFetch(async () => {
    throw new Error("Provider must not be called when the secret is missing.");
  }, async () => {
    const response = await worker.fetch(request("/geminiChat", {
      prompt: "Hello", history: [],
    }), {...env, GEMINI_API_KEY: ""});
    assert.equal(response.status, 503);
    assert.deepEqual(await response.json(), {error: "AI_NOT_CONFIGURED"});
  });
});

test("plant identification handles all four existing supported plants", async () => {
  const supportedPlants = [
    ["Tulsi", "Ocimum tenuiflorum", "Lamiaceae"],
    ["Neem", "Azadirachta indica", "Meliaceae"],
    ["Amla", "Phyllanthus emblica", "Phyllanthaceae"],
    ["Aloe vera", "Aloe vera", "Asphodelaceae"],
  ];
  for (const [plantName, scientificName, family] of supportedPlants) {
    const expected = {
      ...plantResult,
      plantName,
      scientificName,
      family,
      confidence: 0.9,
    };
    await withMockFetch(async () => new Response(JSON.stringify({
      candidates: [{content: {parts: [{text: JSON.stringify(expected)}]}}],
    })), async () => {
      const response = await worker.fetch(request("/geminiPlant", {
        mimeType: "image/jpeg",
        imageBase64: Buffer.from([0xff, 0xd8, 0xff]).toString("base64"),
      }), env);
      assert.equal(response.status, 200);
      assert.deepEqual(await response.json(), expected);
    });
  }
});

test("plant identification accepts broad common plant categories", async () => {
  const examples = [
    ["Oak", "Quercus robur", "Fagaceae", "tree", "non-medicinal"],
    ["Rose", "Rosa chinensis", "Rosaceae", "flower", "unknown"],
    ["Rosemary", "Salvia rosmarinus", "Lamiaceae", "herb", "medicinal"],
    ["Hibiscus", "Hibiscus rosa-sinensis", "Malvaceae", "shrub", "unknown"],
    ["Rice", "Oryza sativa", "Poaceae", "crop", "non-medicinal"],
    ["Jade plant", "Crassula ovata", "Crassulaceae", "succulent", "unknown"],
    ["Saguaro", "Carnegiea gigantea", "Cactaceae", "cactus", "non-medicinal"],
    ["Pothos", "Epipremnum aureum", "Araceae", "indoor vine", "unknown"],
  ];
  for (const [plantName, scientificName, family, plantCategory, medicinalClassification] of examples) {
    const expected = {
      ...plantResult,
      plantName,
      scientificName,
      family,
      plantCategory,
      medicinalClassification,
    };
    await withMockFetch(async () => new Response(JSON.stringify({
      candidates: [{content: {parts: [{text: JSON.stringify(expected)}]}}],
    })), async () => {
      const response = await worker.fetch(request("/geminiPlant", {
        mimeType: "image/jpeg",
        imageBase64: Buffer.from([0xff, 0xd8, 0xff]).toString("base64"),
      }), env);
      assert.equal(response.status, 200, plantName);
      const actual = await response.json();
      assert.equal(actual.plantName, plantName);
      assert.equal(actual.medicinalClassification, medicinalClassification);
      assert.equal(actual.plantCategory, plantCategory);
    });
  }
});

test("uncertain, blurry, and ambiguous images abstain without plant-specific claims", async () => {
  for (const result of [
    {
      ...plantResult,
      organismType: "uncertain",
      plantName: "Unidentified Botanical",
      confidence: 0.9,
    },
    {...plantResult, confidence: 0.42},
  ]) {
    await withMockFetch(async () => new Response(JSON.stringify({
      candidates: [{content: {parts: [{text: JSON.stringify(result)}]}}],
    })), async () => {
      const response = await worker.fetch(request("/geminiPlant", {
        mimeType: "image/jpeg",
        imageBase64: Buffer.from([0xff, 0xd8, 0xff]).toString("base64"),
      }), env);
      const actual = await response.json();
      assert.equal(response.status, 200);
      assert.equal(actual.organismType, "uncertain");
      assert.equal(actual.plantName, "Unidentified Botanical");
      assert.equal(actual.scientificName, null);
      assert.equal(actual.family, null);
      assert.equal(actual.traditionalUses,
          "Not provided because the plant could not be identified reliably.");
      assert.equal(actual.isToxic, false);
      assert.match(actual.toxicityWarning, /unknown/i);
      assert.match(actual.safetySummary, /do not consume/i);
    });
  }
});

test("fungi and non-plant images are not presented as plants", async () => {
  const cases = [
    ["fungus", "Fungus detected (not a plant)"],
    ["non-plant", "No plant detected"],
  ];
  for (const [organismType, plantName] of cases) {
    const result = {...plantResult, organismType};
    await withMockFetch(async () => new Response(JSON.stringify({
      candidates: [{content: {parts: [{text: JSON.stringify(result)}]}}],
    })), async () => {
      const response = await worker.fetch(request("/geminiPlant", {
        mimeType: "image/jpeg",
        imageBase64: Buffer.from([0xff, 0xd8, 0xff]).toString("base64"),
      }), env);
      const actual = await response.json();
      assert.equal(response.status, 200);
      assert.equal(actual.organismType, organismType);
      assert.equal(actual.plantName, plantName);
      assert.match(actual.traditionalUses, /not applicable/i);
      assert.match(actual.safetySummary, /do not consume/i);
    });
  }
});

test("toxic plant results include a clear warning and precaution", async () => {
  const result = {
    ...plantResult,
    plantName: "Foxglove",
    scientificName: "Digitalis purpurea",
    family: "Plantaginaceae",
    isToxic: true,
    toxicityWarning: null,
    precautions: [],
  };
  await withMockFetch(async () => new Response(JSON.stringify({
    candidates: [{content: {parts: [{text: JSON.stringify(result)}]}}],
  })), async () => {
    const response = await worker.fetch(request("/geminiPlant", {
      mimeType: "image/jpeg",
      imageBase64: Buffer.from([0xff, 0xd8, 0xff]).toString("base64"),
    }), env);
    const actual = await response.json();
    assert.equal(response.status, 200);
    assert.equal(actual.isToxic, true);
    assert.match(actual.toxicityWarning, /toxicity|consume/i);
    assert.ok(actual.precautions.some((item) => /do not consume/i.test(item)));
  });
});

test("plant endpoint rejects invalid image formats before calling Gemini", async () => {
  await withMockFetch(async () => {
    throw new Error("Gemini must not be called for invalid images.");
  }, async () => {
    const unsupported = await worker.fetch(request("/geminiPlant", {
      mimeType: "image/gif",
      imageBase64: Buffer.from([0xff, 0xd8, 0xff]).toString("base64"),
    }), env);
    assert.equal(unsupported.status, 400);
    assert.deepEqual(await unsupported.json(), {error: "INVALID_REQUEST"});
    const mismatched = await worker.fetch(request("/geminiPlant", {
      mimeType: "image/png",
      imageBase64: Buffer.from([0xff, 0xd8, 0xff]).toString("base64"),
    }), env);
    assert.equal(mismatched.status, 400);
    assert.deepEqual(await mismatched.json(), {error: "INVALID_REQUEST"});
  });
});

test("plant endpoint reports missing Gemini configuration", async () => {
  await withMockFetch(async () => {
    throw new Error("Gemini must not be called when configuration is missing.");
  }, async () => {
    const response = await worker.fetch(request("/geminiPlant", {
      mimeType: "image/jpeg",
      imageBase64: Buffer.from([0xff, 0xd8, 0xff]).toString("base64"),
    }), {...env, GEMINI_API_KEY: ""});
    assert.equal(response.status, 503);
    assert.deepEqual(await response.json(), {error: "AI_NOT_CONFIGURED"});
  });
});

test("Gemini provider errors are sanitized", async () => {
  for (const [status, expectedStatus, expectedError] of [
    [429, 429, "AI_RATE_LIMITED"],
    [500, 502, "AI_UPSTREAM_UNAVAILABLE"],
  ]) {
    await withMockFetch(async () =>
      new Response("private provider detail", {status}), async () => {
      const response = await worker.fetch(request("/geminiPlant", {
        mimeType: "image/jpeg",
        imageBase64: Buffer.from([0xff, 0xd8, 0xff]).toString("base64"),
      }), env);
      assert.equal(response.status, expectedStatus);
      const body = await response.text();
      assert.deepEqual(JSON.parse(body), {error: expectedError});
      assert.doesNotMatch(body, /private provider detail/);
    });
  }
});
