--99c9f51e2351763a329a99a37e7431181fa7662e465fc9bd180c9eaa3725
Content-Disposition: form-data; name="index.js"

var __defProp = Object.defineProperty;
var __name = (target, value) => __defProp(target, "name", { value, configurable: true });

// ai_backend.js
var GEMINI_MODEL = "gemini-3.8-flash";
var CHAT_MODEL = GEMINI_MODEL;
var PLANT_MODEL = GEMINI_MODEL;
var MAX_IMAGE_BYTES = 5 * 1024 * 1024;
var MAX_BASE64_LENGTH = Math.ceil(MAX_IMAGE_BYTES / 3) * 4;
var MAX_HISTORY_MESSAGES = 20;
var MAX_MESSAGE_LENGTH = 4e3;
var SYSTEM_INSTRUCTION = `You are Jeevan Sutra AI, an educational guide to Indian Knowledge Systems, Ayurveda, wellness and medicinal plants.

Explain traditional knowledge alongside modern scientific understanding. You are not a doctor: never diagnose, prescribe medicines or doses, or advise stopping prescribed treatment. Recommend a qualified healthcare professional for serious or persistent symptoms. Clearly distinguish traditional knowledge from scientific evidence, mention plant safety concerns, and protect user privacy. Be warm, clear, concise, and use Markdown.`;
var PLANT_SYSTEM_INSTRUCTION = `You are a careful visual identification assistant for plants and other organisms.

Identify any plant that can be supported by visible evidence, including trees, flowers, herbs, shrubs, grasses, crops, succulents, cacti, and indoor or outdoor plants. Do not use a fixed species list or guess from location or commonness. Distinguish plants from fungi and other non-plants. Use organismType "fungus" for fungi, "non-plant" for clearly non-plant objects or animals, "uncertain" when the image does not support a reliable classification, and "plant" only for plants.

Never invent a common, scientific, family, Hindi, or Sanskrit name, traditional use, toxicity claim, or scientific evidence. Return null for names or family that cannot be verified confidently. State that uses or evidence are not established when you cannot support them. A photograph alone does not establish safety, edibility, or medicinal value. Never recommend consuming or medicinally using an image-identified organism. If toxicity is known or suspected, clearly warn against contact or consumption and state the uncertainty.`;
var PLANT_PROMPT = `Analyze the supplied image. Return only a JSON object containing every field in the schema:
organismType ("plant", "fungus", "non-plant", or "uncertain"), plantName (a common name for an identified plant, "Fungus detected (not a plant)" for fungi, "No plant detected" for a clearly non-plant image, or "Unidentified Botanical" when uncertain), scientificName (string or null), family (string or null), hindiName (string or null), sanskritName (string or null), plantCategory (a broad botanical category or null), medicinalClassification ("medicinal", "non-medicinal", or "unknown"), growingInformation (reliable care or habitat information, or null), confidence (number from 0 to 1), identification (a concise description and visible characteristics), traditionalUses, scientificEvidence, safetySummary, precautions (string array), isToxic (boolean), and toxicityWarning (string or null).

Use confidence below 0.6 when identification or plant/non-plant classification is uncertain. Use medicinalClassification "unknown" unless an established medicinal classification can be supported. Do not equate traditional use with proven benefit. Leave growingInformation null unless reliable information is known. For fungi, non-plants, and uncertain images, do not provide plant-specific category, uses, evidence, or growing information; use medicinalClassification "unknown". Never infer taxonomy or traditional use from appearance alone. Keep traditional uses distinct from scientific evidence; do not invent citations or claims. Always caution that image identification is not a basis for consuming or medicinally using an organism.`;
var PLANT_RESPONSE_SCHEMA = {
  type: "OBJECT",
  properties: {
    organismType: {
      type: "STRING",
      enum: ["plant", "fungus", "non-plant", "uncertain"]
    },
    plantName: { type: "STRING" },
    sanskritName: { type: "STRING", nullable: true },
    hindiName: { type: "STRING", nullable: true },
    scientificName: { type: "STRING", nullable: true },
    family: { type: "STRING", nullable: true },
    plantCategory: { type: "STRING", nullable: true },
    medicinalClassification: {
      type: "STRING",
      enum: ["medicinal", "non-medicinal", "unknown"]
    },
    growingInformation: { type: "STRING", nullable: true },
    confidence: { type: "NUMBER" },
    identification: { type: "STRING" },
    traditionalUses: { type: "STRING" },
    scientificEvidence: { type: "STRING" },
    safetySummary: { type: "STRING" },
    precautions: { type: "ARRAY", items: { type: "STRING" } },
    isToxic: { type: "BOOLEAN" },
    toxicityWarning: { type: "STRING", nullable: true }
  },
  required: [
    "organismType",
    "plantName",
    "scientificName",
    "family",
    "plantCategory",
    "medicinalClassification",
    "growingInformation",
    "hindiName",
    "sanskritName",
    "confidence",
    "identification",
    "traditionalUses",
    "scientificEvidence",
    "safetySummary",
    "precautions",
    "isToxic",
    "toxicityWarning"
  ]
};
function decodeBase64(value) {
  return Uint8Array.from(atob(value), (character) => character.charCodeAt(0));
}
__name(decodeBase64, "decodeBase64");
function hasSignature(bytes, signature) {
  return bytes.length >= signature.length && signature.every((byte, index) => bytes[index] === byte);
}
__name(hasSignature, "hasSignature");
function encodeBase64(bytes) {
  let binary = "";
  const chunkSize = 32768;
  for (let offset = 0; offset < bytes.length; offset += chunkSize) {
    binary += String.fromCharCode(...bytes.subarray(offset, offset + chunkSize));
  }
  return btoa(binary);
}
__name(encodeBase64, "encodeBase64");
function isHeif(bytes) {
  if (bytes.length < 12 || String.fromCharCode(...bytes.subarray(4, 8)) !== "ftyp") {
    return false;
  }
  return ["heic", "heix", "hevc", "hevx", "mif1", "msf1", "heif"].includes(
    String.fromCharCode(...bytes.subarray(8, 12))
  );
}
__name(isHeif, "isHeif");
function validateChatRequest(body) {
  if (!body || typeof body !== "object" || Array.isArray(body)) {
    throw new TypeError("Request body must be an object.");
  }
  if (typeof body.prompt !== "string" || body.prompt.trim().length === 0 || body.prompt.length > MAX_MESSAGE_LENGTH) {
    throw new TypeError(`Prompt must contain 1-${MAX_MESSAGE_LENGTH} characters.`);
  }
  if (!Array.isArray(body.history) || body.history.length > MAX_HISTORY_MESSAGES) {
    throw new TypeError(`History must contain at most ${MAX_HISTORY_MESSAGES} messages.`);
  }
  const history = body.history.map((message) => {
    if (!message || typeof message !== "object" || !["user", "model"].includes(message.role) || typeof message.text !== "string" || message.text.trim().length === 0 || message.text.length > MAX_MESSAGE_LENGTH) {
      throw new TypeError("Each history message must have a valid role and text.");
    }
    return {
      role: message.role,
      parts: [{ text: message.text.trim() }]
    };
  });
  while (history.length > 0 && history[0].role !== "user") {
    history.shift();
  }
  return { prompt: body.prompt.trim(), history };
}
__name(validateChatRequest, "validateChatRequest");
function validatePlantRequest(body) {
  const supportedTypes = [
    "image/jpeg",
    "image/png",
    "image/webp",
    "image/heic",
    "image/heif"
  ];
  if (!body || typeof body !== "object" || Array.isArray(body)) {
    throw new TypeError("Request body must be an object.");
  }
  if (typeof body.mimeType !== "string" || !supportedTypes.includes(body.mimeType)) {
    throw new TypeError("Image must be JPEG, PNG, WebP, HEIC, or HEIF.");
  }
  if (typeof body.imageBase64 !== "string" || body.imageBase64.length === 0 || !/^[A-Za-z0-9+/]*={0,2}$/.test(body.imageBase64)) {
    throw new TypeError("Image data is missing or invalid.");
  }
  if (body.imageBase64.length > MAX_BASE64_LENGTH) {
    throw new RangeError("Image must not exceed 5 MiB.");
  }
  const image = decodeBase64(body.imageBase64);
  if (image.length === 0 || image.length > MAX_IMAGE_BYTES) {
    throw new RangeError("Image must not exceed 5 MiB.");
  }
  if (encodeBase64(image) !== body.imageBase64) {
    throw new TypeError("Image data is missing or invalid.");
  }
  const isJpeg = hasSignature(image, [255, 216, 255]);
  const isPng = hasSignature(
    image,
    [137, 80, 78, 71, 13, 10, 26, 10]
  );
  const isWebp = image.length >= 12 && String.fromCharCode(...image.subarray(0, 4)) === "RIFF" && String.fromCharCode(...image.subarray(8, 12)) === "WEBP";
  const isValidImage = {
    "image/jpeg": isJpeg,
    "image/png": isPng,
    "image/webp": isWebp,
    "image/heic": isHeif(image),
    "image/heif": isHeif(image)
  }[body.mimeType];
  if (!isValidImage) {
    throw new TypeError("Image bytes do not match the declared format.");
  }
  return { mimeType: body.mimeType, imageBase64: body.imageBase64 };
}
__name(validatePlantRequest, "validatePlantRequest");

// app_check.js
var APP_CHECK_ISSUER = "https://firebaseappcheck.googleapis.com/";
var APP_CHECK_JWKS_URL = "https://firebaseappcheck.googleapis.com/v1/jwks";
var CLOCK_SKEW_SECONDS = 60;
var jwksCache;
var jwksCacheExpiresAt = 0;
var jwksCacheFetcher;
function decodeBase64Url(value) {
  const base64 = value.replace(/-/g, "+").replace(/_/g, "/");
  return atob(base64.padEnd(Math.ceil(base64.length / 4) * 4, "="));
}
__name(decodeBase64Url, "decodeBase64Url");
function decodeJsonPart(value) {
  return JSON.parse(decodeBase64Url(value));
}
__name(decodeJsonPart, "decodeJsonPart");
async function getJwks(fetcher, now) {
  const canCache = fetcher === globalThis.fetch;
  if (canCache && jwksCache && jwksCacheFetcher === fetcher && jwksCacheExpiresAt > now) {
    return jwksCache;
  }
  let response;
  try {
    response = await fetcher(APP_CHECK_JWKS_URL);
  } catch {
    throw new Error("Unable to retrieve Firebase App Check signing keys.");
  }
  if (!response.ok) {
    throw new Error("Unable to retrieve Firebase App Check signing keys.");
  }
  const jwks = await response.json();
  if (!Array.isArray(jwks.keys)) {
    throw new Error("Firebase App Check returned invalid signing keys.");
  }
  if (canCache) {
    const cacheControl = response.headers.get("cache-control") || "";
    const maxAge = Number(cacheControl.match(/max-age=(\d+)/i)?.[1] || 3600);
    jwksCache = jwks;
    jwksCacheExpiresAt = now + Math.max(60, maxAge) * 1e3;
    jwksCacheFetcher = fetcher;
  }
  return jwks;
}
__name(getJwks, "getJwks");
async function verifyAppCheckToken(token, {
  projectNumber,
  allowedAppIds,
  fetcher = globalThis.fetch,
  now = Date.now()
}) {
  if (typeof token !== "string" || token.length === 0 || token.length > 8192) {
    return null;
  }
  try {
    const parts = token.split(".");
    if (parts.length !== 3) return null;
    const header = decodeJsonPart(parts[0]);
    const payload = decodeJsonPart(parts[1]);
    const projectAudience = `projects/${projectNumber}`;
    const audienceIsValid = Array.isArray(payload.aud) && payload.aud.length > 0 && payload.aud.includes(projectAudience);
    const nowSeconds = Math.floor(now / 1e3);
    if (header.alg !== "RS256" || typeof header.kid !== "string" || !audienceIsValid || payload.iss !== `${APP_CHECK_ISSUER}${projectNumber}` || typeof payload.sub !== "string" || !allowedAppIds.includes(payload.sub) || !Number.isInteger(payload.exp) || payload.exp <= nowSeconds || !Number.isInteger(payload.iat) || payload.iat > nowSeconds + CLOCK_SKEW_SECONDS || payload.nbf !== void 0 && (!Number.isInteger(payload.nbf) || payload.nbf > nowSeconds + CLOCK_SKEW_SECONDS)) {
      return null;
    }
    let jwks;
    try {
      jwks = await getJwks(fetcher, now);
    } catch (error) {
      throw new Error("Unable to retrieve Firebase App Check signing keys.", {
        cause: error
      });
    }
    const jwk = jwks.keys.find((key2) => key2.kid === header.kid);
    if (!jwk || jwk.kty !== "RSA" || jwk.alg && jwk.alg !== "RS256") {
      return null;
    }
    const key = await crypto.subtle.importKey(
      "jwk",
      jwk,
      { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
      false,
      ["verify"]
    );
    const signature = Uint8Array.from(
      decodeBase64Url(parts[2]),
      (character) => character.charCodeAt(0)
    );
    const signedContent = new TextEncoder().encode(`${parts[0]}.${parts[1]}`);
    const signatureValid = await crypto.subtle.verify(
      "RSASSA-PKCS1-v1_5",
      key,
      signature,
      signedContent
    );
    return signatureValid ? payload : null;
  } catch (error) {
    if (error instanceof TypeError || error instanceof SyntaxError) {
      return null;
    }
    throw error;
  }
}
__name(verifyAppCheckToken, "verifyAppCheckToken");

// index.js
var CHAT_MAX_REQUEST_BYTES = 64 * 1024;
var PLANT_MAX_REQUEST_BYTES = 7 * 1024 * 1024;
var DEFAULT_CORS_ORIGINS = /* @__PURE__ */ new Set([
  "http://localhost",
  "http://127.0.0.1",
  "https://jeevan-b390e.web.app",
  "https://jeevan-b390e.firebaseapp.com"
]);
var HttpError = class extends Error {
  static {
    __name(this, "HttpError");
  }
  constructor(status, code) {
    super(code);
    this.status = status;
    this.code = code;
  }
};
function jsonResponse(body, status, headers = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8", ...headers }
  });
}
__name(jsonResponse, "jsonResponse");
function allowedOrigins(env) {
  const configured = env.CORS_ALLOWED_ORIGINS;
  if (!configured) return DEFAULT_CORS_ORIGINS;
  return new Set(configured.split(",").map((origin) => origin.trim()).filter(Boolean));
}
__name(allowedOrigins, "allowedOrigins");
function corsHeaders(origin, origins) {
  const headers = { "Vary": "Origin" };
  if (origin && origins.has(origin)) {
    headers["Access-Control-Allow-Origin"] = origin;
  }
  return headers;
}
__name(corsHeaders, "corsHeaders");
function isLocalDevOrigin(origin) {
  try {
    const url = new URL(origin);
    return url.protocol === "http:" && ["localhost", "127.0.0.1"].includes(url.hostname);
  } catch {
    return false;
  }
}
__name(isLocalDevOrigin, "isLocalDevOrigin");
function requestCors(request, env) {
  const origin = request.headers.get("Origin");
  const origins = allowedOrigins(env);
  const isAllowed = !origin || origins.has(origin) || isLocalDevOrigin(origin);
  if (!isAllowed) {
    return jsonResponse({ error: "ORIGIN_NOT_ALLOWED" }, 403, corsHeaders(null, origins));
  }
  const headers = corsHeaders(origin, origins);
  if (request.method === "OPTIONS") {
    headers["Access-Control-Allow-Methods"] = "POST, OPTIONS";
    headers["Access-Control-Allow-Headers"] = "Content-Type, X-Firebase-AppCheck";
    headers["Access-Control-Max-Age"] = "3600";
    return new Response(null, { status: 204, headers });
  }
  return { headers, origins };
}
__name(requestCors, "requestCors");
async function readJsonBody(request, maxBytes) {
  const declaredLength = request.headers.get("Content-Length");
  if (declaredLength && Number(declaredLength) > maxBytes) {
    throw new HttpError(413, "REQUEST_TOO_LARGE");
  }
  if (!request.body) throw new HttpError(400, "INVALID_REQUEST");
  const reader = request.body.getReader();
  const chunks = [];
  let total = 0;
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      total += value.byteLength;
      if (total > maxBytes) {
        await reader.cancel();
        throw new HttpError(413, "REQUEST_TOO_LARGE");
      }
      chunks.push(value);
    }
  } finally {
    reader.releaseLock();
  }
  const bodyBytes = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    bodyBytes.set(chunk, offset);
    offset += chunk.byteLength;
  }
  try {
    return JSON.parse(new TextDecoder().decode(bodyBytes));
  } catch {
    throw new HttpError(400, "INVALID_REQUEST");
  }
}
__name(readJsonBody, "readJsonBody");
async function requireAppCheck(request, env) {
  const token = request.headers.get("X-Firebase-AppCheck");
  const appIds = (env.FIREBASE_APP_IDS || "").split(",").map((appId) => appId.trim()).filter(Boolean);
  if (!env.FIREBASE_PROJECT_NUMBER || appIds.length === 0) {
    throw new HttpError(503, "AUTH_NOT_CONFIGURED");
  }
  try {
    const claims = await verifyAppCheckToken(token, {
      projectNumber: env.FIREBASE_PROJECT_NUMBER,
      allowedAppIds: appIds
    });
    if (!claims) throw new HttpError(401, "APP_CHECK_REJECTED");
  } catch (error) {
    if (error instanceof HttpError) throw error;
    console.error("Firebase App Check verification unavailable.");
    throw new HttpError(503, "APP_CHECK_UNAVAILABLE");
  }
}
__name(requireAppCheck, "requireAppCheck");
async function enforceRateLimit(request, env) {
  if (!env.AI_RATE_LIMITER) {
    throw new HttpError(503, "RATE_LIMITER_NOT_CONFIGURED");
  }
  const clientIp = request.headers.get("CF-Connecting-IP") || "unknown";
  const { success } = await env.AI_RATE_LIMITER.limit({ key: clientIp });
  if (!success) throw new HttpError(429, "RATE_LIMITED");
}
__name(enforceRateLimit, "enforceRateLimit");
function publicError(error) {
  if (error instanceof HttpError) {
    return { status: error.status, error: error.code };
  }
  const status = Number(error?.status || error?.httpStatus);
  if (status === 429) return { status: 429, error: "AI_RATE_LIMITED" };
  if (status === 401 || status === 403) {
    return { status: 503, error: "AI_UPSTREAM_UNAVAILABLE" };
  }
  return { status: 502, error: "AI_UPSTREAM_UNAVAILABLE" };
}
__name(publicError, "publicError");
function assertGemini(env) {
  if (typeof env.GEMINI_API_KEY !== "string" || env.GEMINI_API_KEY.length < 20) {
    throw new HttpError(503, "AI_NOT_CONFIGURED");
  }
}
__name(assertGemini, "assertGemini");
function geminiEndpoint(model, streaming = false) {
  const action = streaming ? "streamGenerateContent?alt=sse" : "generateContent";
  return `https://generativelanguage.googleapis.com/v1beta/models/${model}:${action}`;
}
__name(geminiEndpoint, "geminiEndpoint");
async function callGemini(env, model, payload, { streaming = false } = {}) {
  const url = geminiEndpoint(model, streaming);
  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-goog-api-key": env.GEMINI_API_KEY
    },
    body: JSON.stringify(payload),
    signal: AbortSignal.timeout(45e3)
  });
  if (!response.ok) {
    let errBody = "";
    try {
      errBody = await response.clone().text();
      console.error("Gemini upstream failed:", response.status, errBody);
    } catch (_) {
    }
    const status = response.status;
    if (status === 429) throw Object.assign(new Error("Gemini rate limited: " + errBody), { status });
    if (status === 400) throw Object.assign(new Error("Gemini rejected request: " + errBody), { status });
    if (status === 401 || status === 403) throw Object.assign(new Error("Gemini auth error: " + errBody), { status });
    throw Object.assign(new Error("Gemini upstream unavailable: " + errBody), { status: status >= 500 ? 502 : status });
  }
  return response;
}
__name(callGemini, "callGemini");
function diagnosticCode(error) {
  const status = Number(error?.status || error?.httpStatus || error?.code);
  if (status === 429) return "AI_RATE_LIMITED";
  if (status === 400) return "AI_INVALID_INPUT";
  if (status === 401 || status === 403) return "AI_ACCESS_DENIED";
  return "AI_UPSTREAM_UNAVAILABLE";
}
__name(diagnosticCode, "diagnosticCode");
function logAIDiagnostic(operation, model, code) {
  console.error("Gemini diagnostic.", { operation, model, code });
}
__name(logAIDiagnostic, "logAIDiagnostic");
function streamContentText(content) {
  if (typeof content === "string") return content;
  if (Array.isArray(content)) {
    return content.map((part) => typeof part === "string" ? part : part?.text || "").join("");
  }
  return "";
}
__name(streamContentText, "streamContentText");
function adaptAIStream(source, model, allowNaturalEnd = false) {
  const reader = source.getReader();
  const decoder = new TextDecoder();
  const encoder = new TextEncoder();
  let pending = "";
  let finished = false;
  let emittedText = false;
  let receivedEvent = false;
  let receivedDone = false;
  let diagnostic = "AI_STREAM_INTERRUPTED";
  function parseEvent(data, controller) {
    receivedEvent = true;
    if (data === "[DONE]") {
      receivedDone = true;
      return true;
    }
    let event;
    try {
      event = JSON.parse(data);
    } catch {
      diagnostic = "AI_STREAM_MALFORMED";
      return true;
    }
    if (event?.error) {
      const code = diagnosticCode(event.error);
      diagnostic = code === "AI_UPSTREAM_UNAVAILABLE" ? "AI_STREAM_UPSTREAM_ERROR" : code;
      return true;
    }
    const choices = Array.isArray(event.choices) ? event.choices : event.choices ? [event.choices] : [];
    const geminiParts = event?.candidates?.flatMap(
      (candidate) => candidate?.content?.parts || []
    ) || [];
    const text = geminiParts.map((part) => part?.text || "").join("") || choices.map(
      (choice) => streamContentText(
        choice?.delta?.content ?? choice?.message?.content ?? choice?.text
      )
    ).join("") || streamContentText(event.response ?? event.text);
    if (text) {
      controller.enqueue(encoder.encode(
        `data: ${JSON.stringify({ text })}

`
      ));
      emittedText = true;
    }
    return false;
  }
  __name(parseEvent, "parseEvent");
  function processFrame(frame, controller) {
    const data = frame.split(/\r?\n/).filter((line) => line.startsWith("data:")).map((line) => line.slice(5).replace(/^ /, "")).join("\n");
    if (!data) return false;
    return parseEvent(data, controller);
  }
  __name(processFrame, "processFrame");
  async function fail(controller, code) {
    finished = true;
    try {
      await reader.cancel();
    } catch {
    }
    controller.enqueue(encoder.encode(
      `event: error
data: ${JSON.stringify({ error: code })}

`
    ));
    controller.enqueue(encoder.encode("data: [DONE]\n\n"));
    logAIDiagnostic("chat_stream", model, code);
    controller.close();
  }
  __name(fail, "fail");
  return new ReadableStream({
    async pull(controller) {
      if (finished) return;
      try {
        while (true) {
          const separator = /\r?\n\r?\n/.exec(pending);
          if (separator) {
            const frame = pending.slice(0, separator.index);
            pending = pending.slice(separator.index + separator[0].length);
            if (processFrame(frame, controller)) {
              if (!receivedDone) {
                await fail(controller, diagnostic);
                return;
              }
              if (!emittedText) {
                await fail(controller, "EMPTY_AI_RESPONSE");
                return;
              }
              finished = true;
              await reader.cancel();
              controller.enqueue(encoder.encode("data: [DONE]\n\n"));
              controller.close();
              return;
            }
            continue;
          }
          const { done, value } = await reader.read();
          pending += decoder.decode(value, { stream: !done });
          if (!done) continue;
          if (pending.trim()) {
            const frame = pending;
            pending = "";
            if (processFrame(frame, controller)) {
              if (!receivedDone) {
                await fail(controller, diagnostic);
                return;
              }
              if (!emittedText) {
                await fail(controller, "EMPTY_AI_RESPONSE");
                return;
              }
              finished = true;
              controller.enqueue(encoder.encode("data: [DONE]\n\n"));
              controller.close();
              reader.releaseLock();
              return;
            }
          }
          if (!receivedDone && !(allowNaturalEnd && receivedEvent && emittedText)) {
            await fail(
              controller,
              receivedEvent ? diagnostic : "EMPTY_AI_RESPONSE"
            );
            reader.releaseLock();
            return;
          }
          if (!emittedText) {
            await fail(controller, "EMPTY_AI_RESPONSE");
            reader.releaseLock();
            return;
          }
          finished = true;
          controller.enqueue(encoder.encode("data: [DONE]\n\n"));
          controller.close();
          reader.releaseLock();
          return;
        }
      } catch (error) {
        if (!finished) {
          const code = diagnosticCode(error);
          await fail(controller, code === "AI_UPSTREAM_UNAVAILABLE" ? "AI_STREAM_INTERRUPTED" : code);
        }
        try {
          reader.releaseLock();
        } catch {
        }
      }
    },
    async cancel(reason) {
      finished = true;
      await reader.cancel(reason);
    }
  });
}
__name(adaptAIStream, "adaptAIStream");
async function handleChat(request, env, cors) {
  await requireAppCheck(request, env);
  await enforceRateLimit(request, env);
  let input;
  try {
    input = validateChatRequest(
      await readJsonBody(request, CHAT_MAX_REQUEST_BYTES)
    );
  } catch (error) {
    if (error instanceof TypeError || error instanceof RangeError) {
      throw new HttpError(
        error instanceof RangeError ? 413 : 400,
        error instanceof RangeError ? "REQUEST_TOO_LARGE" : "INVALID_REQUEST"
      );
    }
    throw error;
  }
  assertGemini(env);
  const contents = [
    ...input.history.map((message) => ({
      role: message.role,
      parts: message.parts
    })),
    { role: "user", parts: [{ text: input.prompt }] }
  ];
  let geminiResponse;
  try {
    geminiResponse = await callGemini(env, CHAT_MODEL, {
      systemInstruction: { parts: [{ text: SYSTEM_INSTRUCTION }] },
      contents,
      generationConfig: { temperature: 0.7, maxOutputTokens: 1200 }
    }, { streaming: true });
  } catch (error) {
    logAIDiagnostic("chat_generation", CHAT_MODEL, diagnosticCode(error));
    throw error;
  }
  if (!geminiResponse.body || typeof geminiResponse.body.getReader !== "function") {
    throw new HttpError(502, "EMPTY_AI_RESPONSE");
  }
  const aiStream = geminiResponse.body;
  return new Response(adaptAIStream(aiStream, CHAT_MODEL, true), {
    status: 200,
    headers: {
      ...cors,
      "Cache-Control": "no-cache, no-transform",
      "Content-Type": "text/event-stream; charset=utf-8"
    }
  });
}
__name(handleChat, "handleChat");
async function handlePlant(request, env, cors) {
  await requireAppCheck(request, env);
  await enforceRateLimit(request, env);
  let input;
  try {
    input = validatePlantRequest(
      await readJsonBody(request, PLANT_MAX_REQUEST_BYTES)
    );
  } catch (error) {
    if (error instanceof TypeError || error instanceof RangeError) {
      throw new HttpError(
        error instanceof RangeError ? 413 : 400,
        error instanceof RangeError ? "REQUEST_TOO_LARGE" : "INVALID_REQUEST"
      );
    }
    throw error;
  }
  assertGemini(env);
  let aiResult;
  try {
    const geminiResponse = await callGemini(env, PLANT_MODEL, {
      systemInstruction: {
        parts: [{ text: PLANT_SYSTEM_INSTRUCTION }]
      },
      contents: [{
        role: "user",
        parts: [
          { text: PLANT_PROMPT },
          {
            inlineData: { mimeType: input.mimeType, data: input.imageBase64 },
            inline_data: { mime_type: input.mimeType, data: input.imageBase64 }
          }
        ]
      }],
      generationConfig: {
        responseMimeType: "application/json",
        responseSchema: PLANT_RESPONSE_SCHEMA,
        temperature: 0.2,
        maxOutputTokens: 4096
      }
    });
    aiResult = await geminiResponse.json();
  } catch (error) {
    logAIDiagnostic("plant_identification", PLANT_MODEL, diagnosticCode(error));
    throw error;
  }
  const text = aiResult?.candidates?.[0]?.content?.parts?.map((part) => part?.text || "").join("") || "";
  if (!text) throw new HttpError(502, "EMPTY_AI_RESPONSE");
  let result;
  try {
    const jsonText = text.trim().replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/, "");
    result = JSON.parse(jsonText);
  } catch {
    throw new HttpError(502, "INVALID_AI_RESPONSE");
  }
  if (!result || typeof result !== "object" || Array.isArray(result) || typeof result.plantName !== "string" || result.plantName.trim().length === 0) {
    throw new HttpError(502, "INVALID_AI_RESPONSE");
  }
  const validOrganisms = ["plant", "fungus", "non-plant", "uncertain"];
  result.organismType = validOrganisms.includes(result.organismType) ? result.organismType : "uncertain";
  result.confidence = typeof result.confidence === "number" && Number.isFinite(result.confidence) ? Math.max(0, Math.min(1, result.confidence)) : 0;
  result.identification = typeof result.identification === "string" && result.identification.trim().length > 0 ? result.identification.trim() : "Botanical features identified by AI.";
  result.traditionalUses = typeof result.traditionalUses === "string" && result.traditionalUses.trim().length > 0 ? result.traditionalUses.trim() : "Traditional uses are not documented for this identification.";
  result.scientificEvidence = typeof result.scientificEvidence === "string" && result.scientificEvidence.trim().length > 0 ? result.scientificEvidence.trim() : "Scientific evidence is not verified for this identification.";
  result.safetySummary = typeof result.safetySummary === "string" && result.safetySummary.trim().length > 0 ? result.safetySummary.trim() : "Do not consume or apply medicinally based solely on an automated scan.";
  result.precautions = Array.isArray(result.precautions) ? result.precautions.filter((p) => typeof p === "string" && p.trim().length > 0) : [];
  result.sanskritName = typeof result.sanskritName === "string" && result.sanskritName.trim().length > 0 ? result.sanskritName.trim() : null;
  result.hindiName = typeof result.hindiName === "string" && result.hindiName.trim().length > 0 ? result.hindiName.trim() : null;
  result.scientificName = typeof result.scientificName === "string" && result.scientificName.trim().length > 0 ? result.scientificName.trim() : null;
  result.family = typeof result.family === "string" && result.family.trim().length > 0 ? result.family.trim() : null;
  result.plantCategory = typeof result.plantCategory === "string" && result.plantCategory.trim().length > 0 ? result.plantCategory.trim() : null;
  result.growingInformation = typeof result.growingInformation === "string" && result.growingInformation.trim().length > 0 ? result.growingInformation.trim() : null;
  result.toxicityWarning = typeof result.toxicityWarning === "string" && result.toxicityWarning.trim().length > 0 ? result.toxicityWarning.trim() : null;
  result.isToxic = typeof result.isToxic === "boolean" ? result.isToxic : false;
  const validMedicinal = ["medicinal", "non-medicinal", "unknown"];
  result.medicinalClassification = validMedicinal.includes(result.medicinalClassification) ? result.medicinalClassification : "unknown";
  const unidentified = result.organismType === "uncertain" || result.plantName.trim().toLowerCase() === "unidentified botanical" || result.confidence < 0.6;
  if (unidentified) {
    result.organismType = "uncertain";
    result.plantName = "Unidentified Botanical";
    result.confidence = Math.min(result.confidence, 0.59);
    result.sanskritName = null;
    result.hindiName = null;
    result.scientificName = null;
    result.family = null;
    result.plantCategory = null;
    result.medicinalClassification = "unknown";
    result.growingInformation = null;
    result.identification = "The image does not support a reliable plant identification.";
    result.traditionalUses = "Not provided because the plant could not be identified reliably.";
    result.scientificEvidence = "No plant-specific evidence can be provided without a reliable identification.";
    result.safetySummary = "Identification is uncertain. Do not consume or use this plant medicinally.";
    result.precautions = addPrecaution(
      result.precautions,
      "Do not consume or use this organism based on an uncertain image identification."
    );
    result.isToxic = false;
    result.toxicityWarning = "Toxicity is unknown because identification is uncertain.";
  } else if (result.organismType === "fungus") {
    result.plantName = "Fungus detected (not a plant)";
    result.sanskritName = null;
    result.hindiName = null;
    result.scientificName = null;
    result.family = null;
    result.plantCategory = null;
    result.medicinalClassification = "unknown";
    result.growingInformation = null;
    result.traditionalUses = "Not applicable: the image was identified as a fungus, not a plant.";
    result.scientificEvidence = "No plant-specific evidence applies to this image.";
    result.safetySummary = "Do not consume or handle based on an image identification.";
    result.precautions = addPrecaution(
      result.precautions,
      "Do not consume this fungus; image identification cannot establish safety."
    );
    result.toxicityWarning = result.toxicityWarning ?? "Toxicity has not been verified; do not touch or consume.";
  } else if (result.organismType === "non-plant") {
    result.plantName = "No plant detected";
    result.scientificName = null;
    result.family = null;
    result.sanskritName = null;
    result.hindiName = null;
    result.plantCategory = null;
    result.medicinalClassification = "unknown";
    result.growingInformation = null;
    result.traditionalUses = "Not applicable: no plant was identified.";
    result.scientificEvidence = "Not applicable: no plant was identified.";
    result.safetySummary = "No plant was identified. Do not consume the subject.";
    result.precautions = addPrecaution(
      result.precautions,
      "Do not consume the subject based on an image."
    );
    result.isToxic = false;
    result.toxicityWarning = "Toxicity was not assessed because no plant was identified.";
  } else {
    if (!/do not consume/i.test(result.safetySummary)) {
      result.safetySummary = `${result.safetySummary} Do not consume or use medicinally based solely on image identification.`;
    }
    result.precautions = addPrecaution(
      result.precautions,
      "Do not consume or use medicinally based solely on image identification."
    );
    if (result.isToxic) {
      if (!/do not consume/i.test(result.toxicityWarning || "")) {
        result.toxicityWarning = result.toxicityWarning ? `${result.toxicityWarning} Do not consume or use medicinally.` : "Potential toxicity reported; do not consume or use medicinally.";
      }
    } else {
      result.toxicityWarning = result.toxicityWarning ?? "Toxicity was not independently verified; do not consume.";
    }
  }
  return jsonResponse(result, 200, cors);
}
__name(handlePlant, "handlePlant");
function addPrecaution(precautions, message) {
  return precautions.includes(message) ? precautions : [...precautions, message];
}
__name(addPrecaution, "addPrecaution");
var index_default = {
  async fetch(request, env) {
    const corsResult = requestCors(request, env);
    if (corsResult instanceof Response) return corsResult;
    const { headers: cors } = corsResult;
    if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });
    if (request.method !== "POST") {
      return jsonResponse({ error: "METHOD_NOT_ALLOWED" }, 405, {
        ...cors,
        Allow: "POST, OPTIONS"
      });
    }
    const pathname = new URL(request.url).pathname.replace(/\/+$/, "");
    try {
      if (pathname === "/geminiChat") return await handleChat(request, env, cors);
      if (pathname === "/geminiPlant") return await handlePlant(request, env, cors);
      return jsonResponse({ error: "NOT_FOUND" }, 404, cors);
    } catch (error) {
      const result = publicError(error);
      if (result.status >= 500) {
        console.error("Gemini request failed.", result.error);
      }
      return jsonResponse({ error: result.error }, result.status, cors);
    }
  }
};
export {
  index_default as default
};
//# sourceMappingURL=index.js.map

--99c9f51e2351763a329a99a37e7431181fa7662e465fc9bd180c9eaa3725
Content-Disposition: form-data; name="index.js.map"; filename="index.js.map"
Content-Type: application/source-map

{"version":3,"file":"index.js","sources":["ai_backend.js","app_check.js","index.js"],"sourcesContent":["export const GEMINI_MODEL = \"gemini-3.8-flash\";\nexport const CHAT_MODEL = GEMINI_MODEL;\nexport const PLANT_MODEL = GEMINI_MODEL;\nexport const MAX_IMAGE_BYTES = 5 * 1024 * 1024;\nexport const MAX_BASE64_LENGTH = Math.ceil(MAX_IMAGE_BYTES / 3) * 4;\nexport const MAX_HISTORY_MESSAGES = 20;\nexport const MAX_MESSAGE_LENGTH = 4000;\n\nexport const SYSTEM_INSTRUCTION = `You are Jeevan Sutra AI, an educational guide to Indian Knowledge Systems, Ayurveda, wellness and medicinal plants.\n\nExplain traditional knowledge alongside modern scientific understanding. You are not a doctor: never diagnose, prescribe medicines or doses, or advise stopping prescribed treatment. Recommend a qualified healthcare professional for serious or persistent symptoms. Clearly distinguish traditional knowledge from scientific evidence, mention plant safety concerns, and protect user privacy. Be warm, clear, concise, and use Markdown.`;\n\nexport const PLANT_SYSTEM_INSTRUCTION = `You are a careful visual identification assistant for plants and other organisms.\n\nIdentify any plant that can be supported by visible evidence, including trees, flowers, herbs, shrubs, grasses, crops, succulents, cacti, and indoor or outdoor plants. Do not use a fixed species list or guess from location or commonness. Distinguish plants from fungi and other non-plants. Use organismType \"fungus\" for fungi, \"non-plant\" for clearly non-plant objects or animals, \"uncertain\" when the image does not support a reliable classification, and \"plant\" only for plants.\n\nNever invent a common, scientific, family, Hindi, or Sanskrit name, traditional use, toxicity claim, or scientific evidence. Return null for names or family that cannot be verified confidently. State that uses or evidence are not established when you cannot support them. A photograph alone does not establish safety, edibility, or medicinal value. Never recommend consuming or medicinally using an image-identified organism. If toxicity is known or suspected, clearly warn against contact or consumption and state the uncertainty.`;\n\nexport const PLANT_PROMPT = `Analyze the supplied image. Return only a JSON object containing every field in the schema:\norganismType (\"plant\", \"fungus\", \"non-plant\", or \"uncertain\"), plantName (a common name for an identified plant, \"Fungus detected (not a plant)\" for fungi, \"No plant detected\" for a clearly non-plant image, or \"Unidentified Botanical\" when uncertain), scientificName (string or null), family (string or null), hindiName (string or null), sanskritName (string or null), plantCategory (a broad botanical category or null), medicinalClassification (\"medicinal\", \"non-medicinal\", or \"unknown\"), growingInformation (reliable care or habitat information, or null), confidence (number from 0 to 1), identification (a concise description and visible characteristics), traditionalUses, scientificEvidence, safetySummary, precautions (string array), isToxic (boolean), and toxicityWarning (string or null).\n\nUse confidence below 0.6 when identification or plant/non-plant classification is uncertain. Use medicinalClassification \"unknown\" unless an established medicinal classification can be supported. Do not equate traditional use with proven benefit. Leave growingInformation null unless reliable information is known. For fungi, non-plants, and uncertain images, do not provide plant-specific category, uses, evidence, or growing information; use medicinalClassification \"unknown\". Never infer taxonomy or traditional use from appearance alone. Keep traditional uses distinct from scientific evidence; do not invent citations or claims. Always caution that image identification is not a basis for consuming or medicinally using an organism.`;\n\nexport const PLANT_RESPONSE_SCHEMA = {\n  type: \"OBJECT\",\n  properties: {\n    organismType: {\n      type: \"STRING\",\n      enum: [\"plant\", \"fungus\", \"non-plant\", \"uncertain\"],\n    },\n    plantName: {type: \"STRING\"},\n    sanskritName: {type: \"STRING\", nullable: true},\n    hindiName: {type: \"STRING\", nullable: true},\n    scientificName: {type: \"STRING\", nullable: true},\n    family: {type: \"STRING\", nullable: true},\n    plantCategory: {type: \"STRING\", nullable: true},\n    medicinalClassification: {\n      type: \"STRING\",\n      enum: [\"medicinal\", \"non-medicinal\", \"unknown\"],\n    },\n    growingInformation: {type: \"STRING\", nullable: true},\n    confidence: {type: \"NUMBER\"},\n    identification: {type: \"STRING\"},\n    traditionalUses: {type: \"STRING\"},\n    scientificEvidence: {type: \"STRING\"},\n    safetySummary: {type: \"STRING\"},\n    precautions: {type: \"ARRAY\", items: {type: \"STRING\"}},\n    isToxic: {type: \"BOOLEAN\"},\n    toxicityWarning: {type: \"STRING\", nullable: true},\n  },\n  required: [\n    \"organismType\",\n    \"plantName\",\n    \"scientificName\",\n    \"family\",\n    \"plantCategory\",\n    \"medicinalClassification\",\n    \"growingInformation\",\n    \"hindiName\",\n    \"sanskritName\",\n    \"confidence\",\n    \"identification\",\n    \"traditionalUses\",\n    \"scientificEvidence\",\n    \"safetySummary\",\n    \"precautions\",\n    \"isToxic\",\n    \"toxicityWarning\",\n  ],\n};\n\nfunction decodeBase64(value) {\n  return Uint8Array.from(atob(value), (character) =\u003e character.charCodeAt(0));\n}\n\nfunction hasSignature(bytes, signature) {\n  return bytes.length \u003e= signature.length \u0026\u0026\n    signature.every((byte, index) =\u003e bytes[index] === byte);\n}\n\nfunction encodeBase64(bytes) {\n  let binary = \"\";\n  const chunkSize = 0x8000;\n  for (let offset = 0; offset \u003c bytes.length; offset += chunkSize) {\n    binary += String.fromCharCode(...bytes.subarray(offset, offset + chunkSize));\n  }\n  return btoa(binary);\n}\n\nfunction isHeif(bytes) {\n  if (bytes.length \u003c 12 ||\n      String.fromCharCode(...bytes.subarray(4, 8)) !== \"ftyp\") {\n    return false;\n  }\n  return [\"heic\", \"heix\", \"hevc\", \"hevx\", \"mif1\", \"msf1\", \"heif\"].includes(\n      String.fromCharCode(...bytes.subarray(8, 12)),\n  );\n}\n\nexport function validateChatRequest(body) {\n  if (!body || typeof body !== \"object\" || Array.isArray(body)) {\n    throw new TypeError(\"Request body must be an object.\");\n  }\n  if (typeof body.prompt !== \"string\" ||\n      body.prompt.trim().length === 0 ||\n      body.prompt.length \u003e MAX_MESSAGE_LENGTH) {\n    throw new TypeError(`Prompt must contain 1-${MAX_MESSAGE_LENGTH} characters.`);\n  }\n  if (!Array.isArray(body.history) ||\n      body.history.length \u003e MAX_HISTORY_MESSAGES) {\n    throw new TypeError(`History must contain at most ${MAX_HISTORY_MESSAGES} messages.`);\n  }\n\n  const history = body.history.map((message) =\u003e {\n    if (!message || typeof message !== \"object\" ||\n        ![\"user\", \"model\"].includes(message.role) ||\n        typeof message.text !== \"string\" ||\n        message.text.trim().length === 0 ||\n        message.text.length \u003e MAX_MESSAGE_LENGTH) {\n      throw new TypeError(\"Each history message must have a valid role and text.\");\n    }\n    return {\n      role: message.role,\n      parts: [{text: message.text.trim()}],\n    };\n  });\n\n  while (history.length \u003e 0 \u0026\u0026 history[0].role !== \"user\") {\n    history.shift();\n  }\n  return {prompt: body.prompt.trim(), history};\n}\n\nexport function validatePlantRequest(body) {\n  const supportedTypes = [\n    \"image/jpeg\",\n    \"image/png\",\n    \"image/webp\",\n    \"image/heic\",\n    \"image/heif\",\n  ];\n  if (!body || typeof body !== \"object\" || Array.isArray(body)) {\n    throw new TypeError(\"Request body must be an object.\");\n  }\n  if (typeof body.mimeType !== \"string\" ||\n      !supportedTypes.includes(body.mimeType)) {\n    throw new TypeError(\"Image must be JPEG, PNG, WebP, HEIC, or HEIF.\");\n  }\n  if (typeof body.imageBase64 !== \"string\" ||\n      body.imageBase64.length === 0 ||\n      !/^[A-Za-z0-9+/]*={0,2}$/.test(body.imageBase64)) {\n    throw new TypeError(\"Image data is missing or invalid.\");\n  }\n  if (body.imageBase64.length \u003e MAX_BASE64_LENGTH) {\n    throw new RangeError(\"Image must not exceed 5 MiB.\");\n  }\n\n  const image = decodeBase64(body.imageBase64);\n  if (image.length === 0 || image.length \u003e MAX_IMAGE_BYTES) {\n    throw new RangeError(\"Image must not exceed 5 MiB.\");\n  }\n  if (encodeBase64(image) !== body.imageBase64) {\n    throw new TypeError(\"Image data is missing or invalid.\");\n  }\n\n  const isJpeg = hasSignature(image, [0xff, 0xd8, 0xff]);\n  const isPng = hasSignature(\n      image,\n      [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],\n  );\n  const isWebp = image.length \u003e= 12 \u0026\u0026\n    String.fromCharCode(...image.subarray(0, 4)) === \"RIFF\" \u0026\u0026\n    String.fromCharCode(...image.subarray(8, 12)) === \"WEBP\";\n  const isValidImage = {\n    \"image/jpeg\": isJpeg,\n    \"image/png\": isPng,\n    \"image/webp\": isWebp,\n    \"image/heic\": isHeif(image),\n    \"image/heif\": isHeif(image),\n  }[body.mimeType];\n  if (!isValidImage) {\n    throw new TypeError(\"Image bytes do not match the declared format.\");\n  }\n  return {mimeType: body.mimeType, imageBase64: body.imageBase64};\n}\n","const APP_CHECK_ISSUER = \"https://firebaseappcheck.googleapis.com/\";\r\nconst APP_CHECK_JWKS_URL = \"https://firebaseappcheck.googleapis.com/v1/jwks\";\r\nconst CLOCK_SKEW_SECONDS = 60;\r\n\r\nlet jwksCache;\r\nlet jwksCacheExpiresAt = 0;\r\nlet jwksCacheFetcher;\r\n\r\nfunction decodeBase64Url(value) {\r\n  const base64 = value.replace(/-/g, \"+\").replace(/_/g, \"/\");\r\n  return atob(base64.padEnd(Math.ceil(base64.length / 4) * 4, \"=\"));\r\n}\r\n\r\nfunction decodeJsonPart(value) {\r\n  return JSON.parse(decodeBase64Url(value));\r\n}\r\n\r\nasync function getJwks(fetcher, now) {\r\n  const canCache = fetcher === globalThis.fetch;\r\n  if (canCache \u0026\u0026 jwksCache \u0026\u0026 jwksCacheFetcher === fetcher \u0026\u0026\r\n      jwksCacheExpiresAt \u003e now) {\r\n    return jwksCache;\r\n  }\r\n\r\n  let response;\r\n  try {\r\n    response = await fetcher(APP_CHECK_JWKS_URL);\r\n  } catch {\r\n    throw new Error(\"Unable to retrieve Firebase App Check signing keys.\");\r\n  }\r\n  if (!response.ok) {\r\n    throw new Error(\"Unable to retrieve Firebase App Check signing keys.\");\r\n  }\r\n  const jwks = await response.json();\r\n  if (!Array.isArray(jwks.keys)) {\r\n    throw new Error(\"Firebase App Check returned invalid signing keys.\");\r\n  }\r\n  if (canCache) {\r\n    const cacheControl = response.headers.get(\"cache-control\") || \"\";\r\n    const maxAge = Number(cacheControl.match(/max-age=(\\d+)/i)?.[1] || 3600);\r\n    jwksCache = jwks;\r\n    jwksCacheExpiresAt = now + Math.max(60, maxAge) * 1000;\r\n    jwksCacheFetcher = fetcher;\r\n  }\r\n  return jwks;\r\n}\r\n\r\nexport async function verifyAppCheckToken(\r\n    token,\r\n    {\r\n      projectNumber,\r\n      allowedAppIds,\r\n      fetcher = globalThis.fetch,\r\n      now = Date.now(),\r\n    },\r\n) {\r\n  if (typeof token !== \"string\" || token.length === 0 || token.length \u003e 8192) {\r\n    return null;\r\n  }\r\n\r\n  try {\r\n    const parts = token.split(\".\");\r\n    if (parts.length !== 3) return null;\r\n    const header = decodeJsonPart(parts[0]);\r\n    const payload = decodeJsonPart(parts[1]);\r\n    const projectAudience = `projects/${projectNumber}`;\r\n    const audienceIsValid = Array.isArray(payload.aud) \u0026\u0026\r\n      payload.aud.length \u003e 0 \u0026\u0026\r\n      payload.aud.includes(projectAudience);\r\n    const nowSeconds = Math.floor(now / 1000);\r\n\r\n    if (header.alg !== \"RS256\" ||\r\n        typeof header.kid !== \"string\" ||\r\n        !audienceIsValid ||\r\n        payload.iss !== `${APP_CHECK_ISSUER}${projectNumber}` ||\r\n        typeof payload.sub !== \"string\" ||\r\n        !allowedAppIds.includes(payload.sub) ||\r\n        !Number.isInteger(payload.exp) ||\r\n        payload.exp \u003c= nowSeconds ||\r\n        !Number.isInteger(payload.iat) ||\r\n        payload.iat \u003e nowSeconds + CLOCK_SKEW_SECONDS ||\r\n        (payload.nbf !== undefined \u0026\u0026\r\n          (!Number.isInteger(payload.nbf) ||\r\n            payload.nbf \u003e nowSeconds + CLOCK_SKEW_SECONDS))) {\r\n      return null;\r\n    }\r\n\r\n    let jwks;\r\n    try {\r\n      jwks = await getJwks(fetcher, now);\r\n    } catch (error) {\r\n      throw new Error(\"Unable to retrieve Firebase App Check signing keys.\", {\r\n        cause: error,\r\n      });\r\n    }\r\n    const jwk = jwks.keys.find((key) =\u003e key.kid === header.kid);\r\n    if (!jwk || jwk.kty !== \"RSA\" || jwk.alg \u0026\u0026 jwk.alg !== \"RS256\") {\r\n      return null;\r\n    }\r\n\r\n    const key = await crypto.subtle.importKey(\r\n        \"jwk\",\r\n        jwk,\r\n        {name: \"RSASSA-PKCS1-v1_5\", hash: \"SHA-256\"},\r\n        false,\r\n        [\"verify\"],\r\n    );\r\n    const signature = Uint8Array.from(\r\n        decodeBase64Url(parts[2]),\r\n        (character) =\u003e character.charCodeAt(0),\r\n    );\r\n    const signedContent = new TextEncoder().encode(`${parts[0]}.${parts[1]}`);\r\n    const signatureValid = await crypto.subtle.verify(\r\n        \"RSASSA-PKCS1-v1_5\",\r\n        key,\r\n        signature,\r\n        signedContent,\r\n    );\r\n    return signatureValid ? payload : null;\r\n  } catch (error) {\r\n    if (error instanceof TypeError || error instanceof SyntaxError) {\r\n      return null;\r\n    }\r\n    throw error;\r\n  }\r\n}\r\n","import {\n  CHAT_MODEL,\n  PLANT_MODEL,\n  PLANT_PROMPT,\n  PLANT_RESPONSE_SCHEMA,\n  PLANT_SYSTEM_INSTRUCTION,\n  SYSTEM_INSTRUCTION,\n  validateChatRequest,\n  validatePlantRequest,\n} from \"./ai_backend.js\";\nimport {verifyAppCheckToken} from \"./app_check.js\";\n\nconst CHAT_MAX_REQUEST_BYTES = 64 * 1024;\nconst PLANT_MAX_REQUEST_BYTES = 7 * 1024 * 1024;\nconst DEFAULT_CORS_ORIGINS = new Set([\n  \"http://localhost\",\n  \"http://127.0.0.1\",\n  \"https://jeevan-b390e.web.app\",\n  \"https://jeevan-b390e.firebaseapp.com\",\n]);\n\nclass HttpError extends Error {\n  constructor(status, code) {\n    super(code);\n    this.status = status;\n    this.code = code;\n  }\n}\n\nfunction jsonResponse(body, status, headers = {}) {\n  return new Response(JSON.stringify(body), {\n    status,\n    headers: {\"Content-Type\": \"application/json; charset=utf-8\", ...headers},\n  });\n}\n\nfunction allowedOrigins(env) {\n  const configured = env.CORS_ALLOWED_ORIGINS;\n  if (!configured) return DEFAULT_CORS_ORIGINS;\n  return new Set(configured.split(\",\").map((origin) =\u003e origin.trim()).filter(Boolean));\n}\n\nfunction corsHeaders(origin, origins) {\n  const headers = {\"Vary\": \"Origin\"};\n  if (origin \u0026\u0026 origins.has(origin)) {\n    headers[\"Access-Control-Allow-Origin\"] = origin;\n  }\n  return headers;\n}\n\nfunction isLocalDevOrigin(origin) {\n  try {\n    const url = new URL(origin);\n    return url.protocol === \"http:\" \u0026\u0026\n      [\"localhost\", \"127.0.0.1\"].includes(url.hostname);\n  } catch {\n    return false;\n  }\n}\n\nfunction requestCors(request, env) {\n  const origin = request.headers.get(\"Origin\");\n  const origins = allowedOrigins(env);\n  const isAllowed = !origin || origins.has(origin) || isLocalDevOrigin(origin);\n  if (!isAllowed) {\n    return jsonResponse({error: \"ORIGIN_NOT_ALLOWED\"}, 403, corsHeaders(null, origins));\n  }\n  const headers = corsHeaders(origin, origins);\n  if (request.method === \"OPTIONS\") {\n    headers[\"Access-Control-Allow-Methods\"] = \"POST, OPTIONS\";\n    headers[\"Access-Control-Allow-Headers\"] = \"Content-Type, X-Firebase-AppCheck\";\n    headers[\"Access-Control-Max-Age\"] = \"3600\";\n    return new Response(null, {status: 204, headers});\n  }\n  return {headers, origins};\n}\n\nasync function readJsonBody(request, maxBytes) {\n  const declaredLength = request.headers.get(\"Content-Length\");\n  if (declaredLength \u0026\u0026 Number(declaredLength) \u003e maxBytes) {\n    throw new HttpError(413, \"REQUEST_TOO_LARGE\");\n  }\n  if (!request.body) throw new HttpError(400, \"INVALID_REQUEST\");\n\n  const reader = request.body.getReader();\n  const chunks = [];\n  let total = 0;\n  try {\n    while (true) {\n      const {done, value} = await reader.read();\n      if (done) break;\n      total += value.byteLength;\n      if (total \u003e maxBytes) {\n        await reader.cancel();\n        throw new HttpError(413, \"REQUEST_TOO_LARGE\");\n      }\n      chunks.push(value);\n    }\n  } finally {\n    reader.releaseLock();\n  }\n\n  const bodyBytes = new Uint8Array(total);\n  let offset = 0;\n  for (const chunk of chunks) {\n    bodyBytes.set(chunk, offset);\n    offset += chunk.byteLength;\n  }\n  try {\n    return JSON.parse(new TextDecoder().decode(bodyBytes));\n  } catch {\n    throw new HttpError(400, \"INVALID_REQUEST\");\n  }\n}\n\nasync function requireAppCheck(request, env) {\n  const token = request.headers.get(\"X-Firebase-AppCheck\");\n  const appIds = (env.FIREBASE_APP_IDS || \"\")\n      .split(\",\")\n      .map((appId) =\u003e appId.trim())\n      .filter(Boolean);\n  if (!env.FIREBASE_PROJECT_NUMBER || appIds.length === 0) {\n    throw new HttpError(503, \"AUTH_NOT_CONFIGURED\");\n  }\n  try {\n    const claims = await verifyAppCheckToken(token, {\n      projectNumber: env.FIREBASE_PROJECT_NUMBER,\n      allowedAppIds: appIds,\n    });\n    if (!claims) throw new HttpError(401, \"APP_CHECK_REJECTED\");\n  } catch (error) {\n    if (error instanceof HttpError) throw error;\n    console.error(\"Firebase App Check verification unavailable.\");\n    throw new HttpError(503, \"APP_CHECK_UNAVAILABLE\");\n  }\n}\n\nasync function enforceRateLimit(request, env) {\n  if (!env.AI_RATE_LIMITER) {\n    throw new HttpError(503, \"RATE_LIMITER_NOT_CONFIGURED\");\n  }\n  const clientIp = request.headers.get(\"CF-Connecting-IP\") || \"unknown\";\n  const {success} = await env.AI_RATE_LIMITER.limit({key: clientIp});\n  if (!success) throw new HttpError(429, \"RATE_LIMITED\");\n}\n\nfunction publicError(error) {\n  if (error instanceof HttpError) {\n    return {status: error.status, error: error.code};\n  }\n  const status = Number(error?.status || error?.httpStatus);\n  if (status === 429) return {status: 429, error: \"AI_RATE_LIMITED\"};\n  if (status === 401 || status === 403) {\n    return {status: 503, error: \"AI_UPSTREAM_UNAVAILABLE\"};\n  }\n  return {status: 502, error: \"AI_UPSTREAM_UNAVAILABLE\"};\n}\n\nfunction assertGemini(env) {\n  if (typeof env.GEMINI_API_KEY !== \"string\" || env.GEMINI_API_KEY.length \u003c 20) {\n    throw new HttpError(503, \"AI_NOT_CONFIGURED\");\n  }\n}\n\nfunction geminiEndpoint(model, streaming = false) {\n  const action = streaming ? \"streamGenerateContent?alt=sse\" : \"generateContent\";\n  return `https://generativelanguage.googleapis.com/v1beta/models/${model}:${action}`;\n}\n\nasync function callGemini(env, model, payload, {streaming = false} = {}) {\n  const url = geminiEndpoint(model, streaming);\n  const response = await fetch(url, {\n    method: \"POST\",\n    headers: {\n      \"Content-Type\": \"application/json\",\n      \"x-goog-api-key\": env.GEMINI_API_KEY,\n    },\n    body: JSON.stringify(payload),\n    signal: AbortSignal.timeout(45_000),\n  });\n  if (!response.ok) {\n    let errBody = \"\";\n    try {\n      errBody = await response.clone().text();\n      console.error(\"Gemini upstream failed:\", response.status, errBody);\n    } catch (_) {}\n    const status = response.status;\n    if (status === 429) throw Object.assign(new Error(\"Gemini rate limited: \" + errBody), {status});\n    if (status === 400) throw Object.assign(new Error(\"Gemini rejected request: \" + errBody), {status});\n    if (status === 401 || status === 403) throw Object.assign(new Error(\"Gemini auth error: \" + errBody), {status});\n    throw Object.assign(new Error(\"Gemini upstream unavailable: \" + errBody), {status: status \u003e= 500 ? 502 : status});\n  }\n  return response;\n}\n\nfunction diagnosticCode(error) {\n  const status = Number(error?.status || error?.httpStatus || error?.code);\n  if (status === 429) return \"AI_RATE_LIMITED\";\n  if (status === 400) return \"AI_INVALID_INPUT\";\n  if (status === 401 || status === 403) return \"AI_ACCESS_DENIED\";\n  return \"AI_UPSTREAM_UNAVAILABLE\";\n}\n\nfunction logAIDiagnostic(operation, model, code) {\n  console.error(\"Gemini diagnostic.\", {operation, model, code});\n}\n\nfunction extractAIText(result) {\n  const content = result?.choices?.[0]?.message?.content;\n  if (typeof content === \"string\") return content;\n  if (Array.isArray(content)) {\n    return content.map((part) =\u003e part?.text || \"\").join(\"\");\n  }\n  return typeof result?.response === \"string\" ? result.response : \"\";\n}\n\nfunction streamContentText(content) {\n  if (typeof content === \"string\") return content;\n  if (Array.isArray(content)) {\n    return content.map((part) =\u003e typeof part === \"string\" ? part : part?.text || \"\")\n        .join(\"\");\n  }\n  return \"\";\n}\n\nfunction adaptAIStream(source, model, allowNaturalEnd = false) {\n  const reader = source.getReader();\n  const decoder = new TextDecoder();\n  const encoder = new TextEncoder();\n  let pending = \"\";\n  let finished = false;\n  let emittedText = false;\n  let receivedEvent = false;\n  let receivedDone = false;\n  let diagnostic = \"AI_STREAM_INTERRUPTED\";\n\n  function parseEvent(data, controller) {\n    receivedEvent = true;\n    if (data === \"[DONE]\") {\n      receivedDone = true;\n      return true;\n    }\n    let event;\n    try {\n      event = JSON.parse(data);\n    } catch {\n      diagnostic = \"AI_STREAM_MALFORMED\";\n      return true;\n    }\n    if (event?.error) {\n      const code = diagnosticCode(event.error);\n      diagnostic = code === \"AI_UPSTREAM_UNAVAILABLE\"\n        ? \"AI_STREAM_UPSTREAM_ERROR\"\n        : code;\n      return true;\n    }\n\n    const choices = Array.isArray(event.choices)\n      ? event.choices\n      : event.choices ? [event.choices] : [];\n    const geminiParts = event?.candidates?.flatMap(\n        (candidate) =\u003e candidate?.content?.parts || [],\n    ) || [];\n    const text = geminiParts.map((part) =\u003e part?.text || \"\").join(\"\") ||\n      choices.map((choice) =\u003e\n        streamContentText(\n            choice?.delta?.content ??\n            choice?.message?.content ??\n            choice?.text,\n        ),\n      ).join(\"\") || streamContentText(event.response ?? event.text);\n    if (text) {\n      controller.enqueue(encoder.encode(\n          `data: ${JSON.stringify({text})}\\n\\n`,\n      ));\n      emittedText = true;\n    }\n    return false;\n  }\n\n  function processFrame(frame, controller) {\n    const data = frame.split(/\\r?\\n/)\n        .filter((line) =\u003e line.startsWith(\"data:\"))\n        .map((line) =\u003e line.slice(5).replace(/^ /, \"\"))\n        .join(\"\\n\");\n    if (!data) return false;\n    return parseEvent(data, controller);\n  }\n\n  async function fail(controller, code) {\n    finished = true;\n    try {\n      await reader.cancel();\n    } catch {\n      // The upstream stream may already be closed or errored.\n    }\n    controller.enqueue(encoder.encode(\n        `event: error\\ndata: ${JSON.stringify({error: code})}\\n\\n`,\n    ));\n    controller.enqueue(encoder.encode(\"data: [DONE]\\n\\n\"));\n    logAIDiagnostic(\"chat_stream\", model, code);\n    controller.close();\n  }\n\n  return new ReadableStream({\n    async pull(controller) {\n      if (finished) return;\n      try {\n        while (true) {\n          const separator = /\\r?\\n\\r?\\n/.exec(pending);\n          if (separator) {\n            const frame = pending.slice(0, separator.index);\n            pending = pending.slice(separator.index + separator[0].length);\n            if (processFrame(frame, controller)) {\n              if (!receivedDone) {\n                await fail(controller, diagnostic);\n                return;\n              }\n              if (!emittedText) {\n                await fail(controller, \"EMPTY_AI_RESPONSE\");\n                return;\n              }\n              finished = true;\n              await reader.cancel();\n              controller.enqueue(encoder.encode(\"data: [DONE]\\n\\n\"));\n              controller.close();\n              return;\n            }\n            continue;\n          }\n\n          const {done, value} = await reader.read();\n          pending += decoder.decode(value, {stream: !done});\n          if (!done) continue;\n\n          if (pending.trim()) {\n            const frame = pending;\n            pending = \"\";\n            if (processFrame(frame, controller)) {\n              if (!receivedDone) {\n                await fail(controller, diagnostic);\n                return;\n              }\n              if (!emittedText) {\n                await fail(controller, \"EMPTY_AI_RESPONSE\");\n                return;\n              }\n              finished = true;\n              controller.enqueue(encoder.encode(\"data: [DONE]\\n\\n\"));\n              controller.close();\n              reader.releaseLock();\n              return;\n            }\n          }\n          if (!receivedDone \u0026\u0026 !(allowNaturalEnd \u0026\u0026 receivedEvent \u0026\u0026 emittedText)) {\n            await fail(\n                controller,\n                receivedEvent ? diagnostic : \"EMPTY_AI_RESPONSE\",\n            );\n            reader.releaseLock();\n            return;\n          }\n          if (!emittedText) {\n            await fail(controller, \"EMPTY_AI_RESPONSE\");\n            reader.releaseLock();\n            return;\n          }\n          finished = true;\n          controller.enqueue(encoder.encode(\"data: [DONE]\\n\\n\"));\n          controller.close();\n          reader.releaseLock();\n          return;\n        }\n      } catch (error) {\n        if (!finished) {\n          const code = diagnosticCode(error);\n          await fail(controller, code === \"AI_UPSTREAM_UNAVAILABLE\"\n              ? \"AI_STREAM_INTERRUPTED\"\n              : code);\n        }\n        try {\n          reader.releaseLock();\n        } catch {\n          // The stream may have already been cancelled by its consumer.\n        }\n      }\n    },\n    async cancel(reason) {\n      finished = true;\n      await reader.cancel(reason);\n    },\n  });\n}\n\nasync function handleChat(request, env, cors) {\n  await requireAppCheck(request, env);\n  await enforceRateLimit(request, env);\n  let input;\n  try {\n    input = validateChatRequest(\n        await readJsonBody(request, CHAT_MAX_REQUEST_BYTES),\n    );\n  } catch (error) {\n    if (error instanceof TypeError || error instanceof RangeError) {\n      throw new HttpError(\n          error instanceof RangeError ? 413 : 400,\n          error instanceof RangeError ? \"REQUEST_TOO_LARGE\" : \"INVALID_REQUEST\",\n      );\n    }\n    throw error;\n  }\n  assertGemini(env);\n  const contents = [\n    ...input.history.map((message) =\u003e ({\n      role: message.role,\n      parts: message.parts,\n    })),\n    {role: \"user\", parts: [{text: input.prompt}]},\n  ];\n  let geminiResponse;\n  try {\n    geminiResponse = await callGemini(env, CHAT_MODEL, {\n      systemInstruction: {parts: [{text: SYSTEM_INSTRUCTION}]},\n      contents,\n      generationConfig: {temperature: 0.7, maxOutputTokens: 1200},\n    }, {streaming: true});\n  } catch (error) {\n    logAIDiagnostic(\"chat_generation\", CHAT_MODEL, diagnosticCode(error));\n    throw error;\n  }\n  if (!geminiResponse.body || typeof geminiResponse.body.getReader !== \"function\") {\n    throw new HttpError(502, \"EMPTY_AI_RESPONSE\");\n  }\n  const aiStream = geminiResponse.body;\n  return new Response(adaptAIStream(aiStream, CHAT_MODEL, true), {\n    status: 200,\n    headers: {\n      ...cors,\n      \"Cache-Control\": \"no-cache, no-transform\",\n      \"Content-Type\": \"text/event-stream; charset=utf-8\",\n    },\n  });\n}\n\nasync function handlePlant(request, env, cors) {\n  await requireAppCheck(request, env);\n  await enforceRateLimit(request, env);\n  let input;\n  try {\n    input = validatePlantRequest(\n        await readJsonBody(request, PLANT_MAX_REQUEST_BYTES),\n    );\n  } catch (error) {\n    if (error instanceof TypeError || error instanceof RangeError) {\n      throw new HttpError(\n          error instanceof RangeError ? 413 : 400,\n          error instanceof RangeError ? \"REQUEST_TOO_LARGE\" : \"INVALID_REQUEST\",\n      );\n    }\n    throw error;\n  }\n  assertGemini(env);\n  let aiResult;\n  try {\n    const geminiResponse = await callGemini(env, PLANT_MODEL, {\n      systemInstruction: {\n        parts: [{text: PLANT_SYSTEM_INSTRUCTION}],\n      },\n      contents: [{\n        role: \"user\",\n        parts: [\n          {text: PLANT_PROMPT},\n          {\n            inlineData: {mimeType: input.mimeType, data: input.imageBase64},\n            inline_data: {mime_type: input.mimeType, data: input.imageBase64},\n          },\n        ],\n      }],\n      generationConfig: {\n        responseMimeType: \"application/json\",\n        responseSchema: PLANT_RESPONSE_SCHEMA,\n        temperature: 0.2,\n        maxOutputTokens: 4096,\n      },\n    });\n    aiResult = await geminiResponse.json();\n  } catch (error) {\n    logAIDiagnostic(\"plant_identification\", PLANT_MODEL, diagnosticCode(error));\n    throw error;\n  }\n  const text = aiResult?.candidates?.[0]?.content?.parts\n      ?.map((part) =\u003e part?.text || \"\").join(\"\") || \"\";\n  if (!text) throw new HttpError(502, \"EMPTY_AI_RESPONSE\");\n\n  let result;\n  try {\n    const jsonText = text.trim()\n        .replace(/^```(?:json)?\\s*/i, \"\")\n        .replace(/\\s*```$/, \"\");\n    result = JSON.parse(jsonText);\n  } catch {\n    throw new HttpError(502, \"INVALID_AI_RESPONSE\");\n  }\n  if (!result || typeof result !== \"object\" || Array.isArray(result) ||\n      typeof result.plantName !== \"string\" ||\n      result.plantName.trim().length === 0) {\n    throw new HttpError(502, \"INVALID_AI_RESPONSE\");\n  }\n\n  // Safely normalize all fields while maintaining schema invariants\n  const validOrganisms = [\"plant\", \"fungus\", \"non-plant\", \"uncertain\"];\n  result.organismType = validOrganisms.includes(result.organismType)\n      ? result.organismType\n      : \"uncertain\";\n  result.confidence = typeof result.confidence === \"number\" \u0026\u0026 Number.isFinite(result.confidence)\n      ? Math.max(0, Math.min(1, result.confidence))\n      : 0.0;\n  result.identification = typeof result.identification === \"string\" \u0026\u0026 result.identification.trim().length \u003e 0\n      ? result.identification.trim()\n      : \"Botanical features identified by AI.\";\n  result.traditionalUses = typeof result.traditionalUses === \"string\" \u0026\u0026 result.traditionalUses.trim().length \u003e 0\n      ? result.traditionalUses.trim()\n      : \"Traditional uses are not documented for this identification.\";\n  result.scientificEvidence = typeof result.scientificEvidence === \"string\" \u0026\u0026 result.scientificEvidence.trim().length \u003e 0\n      ? result.scientificEvidence.trim()\n      : \"Scientific evidence is not verified for this identification.\";\n  result.safetySummary = typeof result.safetySummary === \"string\" \u0026\u0026 result.safetySummary.trim().length \u003e 0\n      ? result.safetySummary.trim()\n      : \"Do not consume or apply medicinally based solely on an automated scan.\";\n  result.precautions = Array.isArray(result.precautions)\n      ? result.precautions.filter((p) =\u003e typeof p === \"string\" \u0026\u0026 p.trim().length \u003e 0)\n      : [];\n  result.sanskritName = typeof result.sanskritName === \"string\" \u0026\u0026 result.sanskritName.trim().length \u003e 0\n      ? result.sanskritName.trim()\n      : null;\n  result.hindiName = typeof result.hindiName === \"string\" \u0026\u0026 result.hindiName.trim().length \u003e 0\n      ? result.hindiName.trim()\n      : null;\n  result.scientificName = typeof result.scientificName === \"string\" \u0026\u0026 result.scientificName.trim().length \u003e 0\n      ? result.scientificName.trim()\n      : null;\n  result.family = typeof result.family === \"string\" \u0026\u0026 result.family.trim().length \u003e 0\n      ? result.family.trim()\n      : null;\n  result.plantCategory = typeof result.plantCategory === \"string\" \u0026\u0026 result.plantCategory.trim().length \u003e 0\n      ? result.plantCategory.trim()\n      : null;\n  result.growingInformation = typeof result.growingInformation === \"string\" \u0026\u0026 result.growingInformation.trim().length \u003e 0\n      ? result.growingInformation.trim()\n      : null;\n  result.toxicityWarning = typeof result.toxicityWarning === \"string\" \u0026\u0026 result.toxicityWarning.trim().length \u003e 0\n      ? result.toxicityWarning.trim()\n      : null;\n  result.isToxic = typeof result.isToxic === \"boolean\" ? result.isToxic : false;\n  const validMedicinal = [\"medicinal\", \"non-medicinal\", \"unknown\"];\n  result.medicinalClassification = validMedicinal.includes(result.medicinalClassification)\n      ? result.medicinalClassification\n      : \"unknown\";\n\n  const unidentified = result.organismType === \"uncertain\" ||\n    result.plantName.trim().toLowerCase() === \"unidentified botanical\" ||\n    result.confidence \u003c 0.6;\n  if (unidentified) {\n    result.organismType = \"uncertain\";\n    result.plantName = \"Unidentified Botanical\";\n    result.confidence = Math.min(result.confidence, 0.59);\n    result.sanskritName = null;\n    result.hindiName = null;\n    result.scientificName = null;\n    result.family = null;\n    result.plantCategory = null;\n    result.medicinalClassification = \"unknown\";\n    result.growingInformation = null;\n    result.identification =\n      \"The image does not support a reliable plant identification.\";\n    result.traditionalUses =\n      \"Not provided because the plant could not be identified reliably.\";\n    result.scientificEvidence =\n      \"No plant-specific evidence can be provided without a reliable identification.\";\n    result.safetySummary =\n      \"Identification is uncertain. Do not consume or use this plant medicinally.\";\n    result.precautions = addPrecaution(\n        result.precautions,\n        \"Do not consume or use this organism based on an uncertain image identification.\",\n    );\n    result.isToxic = false;\n    result.toxicityWarning = \"Toxicity is unknown because identification is uncertain.\";\n  } else if (result.organismType === \"fungus\") {\n    result.plantName = \"Fungus detected (not a plant)\";\n    result.sanskritName = null;\n    result.hindiName = null;\n    result.scientificName = null;\n    result.family = null;\n    result.plantCategory = null;\n    result.medicinalClassification = \"unknown\";\n    result.growingInformation = null;\n    result.traditionalUses = \"Not applicable: the image was identified as a fungus, not a plant.\";\n    result.scientificEvidence = \"No plant-specific evidence applies to this image.\";\n    result.safetySummary = \"Do not consume or handle based on an image identification.\";\n    result.precautions = addPrecaution(\n        result.precautions,\n        \"Do not consume this fungus; image identification cannot establish safety.\",\n    );\n    result.toxicityWarning = result.toxicityWarning ??\n      \"Toxicity has not been verified; do not touch or consume.\";\n  } else if (result.organismType === \"non-plant\") {\n    result.plantName = \"No plant detected\";\n    result.scientificName = null;\n    result.family = null;\n    result.sanskritName = null;\n    result.hindiName = null;\n    result.plantCategory = null;\n    result.medicinalClassification = \"unknown\";\n    result.growingInformation = null;\n    result.traditionalUses = \"Not applicable: no plant was identified.\";\n    result.scientificEvidence = \"Not applicable: no plant was identified.\";\n    result.safetySummary = \"No plant was identified. Do not consume the subject.\";\n    result.precautions = addPrecaution(\n        result.precautions,\n        \"Do not consume the subject based on an image.\",\n    );\n    result.isToxic = false;\n    result.toxicityWarning = \"Toxicity was not assessed because no plant was identified.\";\n  } else {\n    if (!/do not consume/i.test(result.safetySummary)) {\n      result.safetySummary = `${result.safetySummary} Do not consume or use medicinally based solely on image identification.`;\n    }\n    result.precautions = addPrecaution(\n        result.precautions,\n        \"Do not consume or use medicinally based solely on image identification.\",\n    );\n    if (result.isToxic) {\n      if (!/do not consume/i.test(result.toxicityWarning || \"\")) {\n        result.toxicityWarning = result.toxicityWarning\n          ? `${result.toxicityWarning} Do not consume or use medicinally.`\n          : \"Potential toxicity reported; do not consume or use medicinally.\";\n      }\n    } else {\n      result.toxicityWarning = result.toxicityWarning ??\n        \"Toxicity was not independently verified; do not consume.\";\n    }\n  }\n  return jsonResponse(result, 200, cors);\n}\n\nfunction addPrecaution(precautions, message) {\n  return precautions.includes(message) ? precautions : [...precautions, message];\n}\n\nexport default {\n  async fetch(request, env) {\n    const corsResult = requestCors(request, env);\n    if (corsResult instanceof Response) return corsResult;\n    const {headers: cors} = corsResult;\n    if (request.method === \"OPTIONS\") return new Response(null, {status: 204, headers: cors});\n    if (request.method !== \"POST\") {\n      return jsonResponse({error: \"METHOD_NOT_ALLOWED\"}, 405, {\n        ...cors,\n        Allow: \"POST, OPTIONS\",\n      });\n    }\n\n    const pathname = new URL(request.url).pathname.replace(/\\/+$/, \"\");\n    try {\n      if (pathname === \"/geminiChat\") return await handleChat(request, env, cors);\n      if (pathname === \"/geminiPlant\") return await handlePlant(request, env, cors);\n      return jsonResponse({error: \"NOT_FOUND\"}, 404, cors);\n    } catch (error) {\n      const result = publicError(error);\n      if (result.status \u003e= 500) {\n        console.error(\"Gemini request failed.\", result.error);\n      }\n      return jsonResponse({error: result.error}, result.status, cors);\n    }\n  },\n};\n"],"names":["key"],"mappings":";;;;AAAO,IAAM,eAAe;AACrB,IAAM,aAAa;AACnB,IAAM,cAAc;AACpB,IAAM,kBAAkB,IAAI,OAAO;AACnC,IAAM,oBAAoB,KAAK,KAAK,kBAAkB,CAAC,IAAI;AAC3D,IAAM,uBAAuB;AAC7B,IAAM,qBAAqB;AAE3B,IAAM,qBAAqB;AAAA;AAAA;AAI3B,IAAM,2BAA2B;AAAA;AAAA;AAAA;AAAA;AAMjC,IAAM,eAAe;AAAA;AAAA;AAAA;AAKrB,IAAM,wBAAwB;AAAA,EACnC,MAAM;AAAA,EACN,YAAY;AAAA,IACV,cAAc;AAAA,MACZ,MAAM;AAAA,MACN,MAAM,CAAC,SAAS,UAAU,aAAa,WAAW;AAAA,IACpD;AAAA,IACA,WAAW,EAAC,MAAM,SAAQ;AAAA,IAC1B,cAAc,EAAC,MAAM,UAAU,UAAU,KAAI;AAAA,IAC7C,WAAW,EAAC,MAAM,UAAU,UAAU,KAAI;AAAA,IAC1C,gBAAgB,EAAC,MAAM,UAAU,UAAU,KAAI;AAAA,IAC/C,QAAQ,EAAC,MAAM,UAAU,UAAU,KAAI;AAAA,IACvC,eAAe,EAAC,MAAM,UAAU,UAAU,KAAI;AAAA,IAC9C,yBAAyB;AAAA,MACvB,MAAM;AAAA,MACN,MAAM,CAAC,aAAa,iBAAiB,SAAS;AAAA,IAChD;AAAA,IACA,oBAAoB,EAAC,MAAM,UAAU,UAAU,KAAI;AAAA,IACnD,YAAY,EAAC,MAAM,SAAQ;AAAA,IAC3B,gBAAgB,EAAC,MAAM,SAAQ;AAAA,IAC/B,iBAAiB,EAAC,MAAM,SAAQ;AAAA,IAChC,oBAAoB,EAAC,MAAM,SAAQ;AAAA,IACnC,eAAe,EAAC,MAAM,SAAQ;AAAA,IAC9B,aAAa,EAAC,MAAM,SAAS,OAAO,EAAC,MAAM,SAAQ,EAAC;AAAA,IACpD,SAAS,EAAC,MAAM,UAAS;AAAA,IACzB,iBAAiB,EAAC,MAAM,UAAU,UAAU,KAAI;AAAA,EAClD;AAAA,EACA,UAAU;AAAA,IACR;AAAA,IACA;AAAA,IACA;AAAA,IACA;AAAA,IACA;AAAA,IACA;AAAA,IACA;AAAA,IACA;AAAA,IACA;AAAA,IACA;AAAA,IACA;AAAA,IACA;AAAA,IACA;AAAA,IACA;AAAA,IACA;AAAA,IACA;AAAA,IACA;AAAA,EACF;AACF;AAEA,SAAS,aAAa,OAAO;AAC3B,SAAO,WAAW,KAAK,KAAK,KAAK,GAAG,CAAC,cAAc,UAAU,WAAW,CAAC,CAAC;AAC5E;AAFS;AAIT,SAAS,aAAa,OAAO,WAAW;AACtC,SAAO,MAAM,UAAU,UAAU,UAC/B,UAAU,MAAM,CAAC,MAAM,UAAU,MAAM,KAAK,MAAM,IAAI;AAC1D;AAHS;AAKT,SAAS,aAAa,OAAO;AAC3B,MAAI,SAAS;AACb,QAAM,YAAY;AAClB,WAAS,SAAS,GAAG,SAAS,MAAM,QAAQ,UAAU,WAAW;AAC/D,cAAU,OAAO,aAAa,GAAG,MAAM,SAAS,QAAQ,SAAS,SAAS,CAAC;AAAA,EAC7E;AACA,SAAO,KAAK,MAAM;AACpB;AAPS;AAST,SAAS,OAAO,OAAO;AACrB,MAAI,MAAM,SAAS,MACf,OAAO,aAAa,GAAG,MAAM,SAAS,GAAG,CAAC,CAAC,MAAM,QAAQ;AAC3D,WAAO;AAAA,EACT;AACA,SAAO,CAAC,QAAQ,QAAQ,QAAQ,QAAQ,QAAQ,QAAQ,MAAM,EAAE;AAAA,IAC5D,OAAO,aAAa,GAAG,MAAM,SAAS,GAAG,EAAE,CAAC;AAAA,EAChD;AACF;AARS;AAUF,SAAS,oBAAoB,MAAM;AACxC,MAAI,CAAC,QAAQ,OAAO,SAAS,YAAY,MAAM,QAAQ,IAAI,GAAG;AAC5D,UAAM,IAAI,UAAU,iCAAiC;AAAA,EACvD;AACA,MAAI,OAAO,KAAK,WAAW,YACvB,KAAK,OAAO,KAAK,EAAE,WAAW,KAC9B,KAAK,OAAO,SAAS,oBAAoB;AAC3C,UAAM,IAAI,UAAU,yBAAyB,kBAAkB,cAAc;AAAA,EAC/E;AACA,MAAI,CAAC,MAAM,QAAQ,KAAK,OAAO,KAC3B,KAAK,QAAQ,SAAS,sBAAsB;AAC9C,UAAM,IAAI,UAAU,gCAAgC,oBAAoB,YAAY;AAAA,EACtF;AAEA,QAAM,UAAU,KAAK,QAAQ,IAAI,CAAC,YAAY;AAC5C,QAAI,CAAC,WAAW,OAAO,YAAY,YAC/B,CAAC,CAAC,QAAQ,OAAO,EAAE,SAAS,QAAQ,IAAI,KACxC,OAAO,QAAQ,SAAS,YACxB,QAAQ,KAAK,KAAK,EAAE,WAAW,KAC/B,QAAQ,KAAK,SAAS,oBAAoB;AAC5C,YAAM,IAAI,UAAU,uDAAuD;AAAA,IAC7E;AACA,WAAO;AAAA,MACL,MAAM,QAAQ;AAAA,MACd,OAAO,CAAC,EAAC,MAAM,QAAQ,KAAK,KAAK,EAAC,CAAC;AAAA,IACrC;AAAA,EACF,CAAC;AAED,SAAO,QAAQ,SAAS,KAAK,QAAQ,CAAC,EAAE,SAAS,QAAQ;AACvD,YAAQ,MAAM;AAAA,EAChB;AACA,SAAO,EAAC,QAAQ,KAAK,OAAO,KAAK,GAAG,QAAO;AAC7C;AAhCgB;AAkCT,SAAS,qBAAqB,MAAM;AACzC,QAAM,iBAAiB;AAAA,IACrB;AAAA,IACA;AAAA,IACA;AAAA,IACA;AAAA,IACA;AAAA,EACF;AACA,MAAI,CAAC,QAAQ,OAAO,SAAS,YAAY,MAAM,QAAQ,IAAI,GAAG;AAC5D,UAAM,IAAI,UAAU,iCAAiC;AAAA,EACvD;AACA,MAAI,OAAO,KAAK,aAAa,YACzB,CAAC,eAAe,SAAS,KAAK,QAAQ,GAAG;AAC3C,UAAM,IAAI,UAAU,+CAA+C;AAAA,EACrE;AACA,MAAI,OAAO,KAAK,gBAAgB,YAC5B,KAAK,YAAY,WAAW,KAC5B,CAAC,yBAAyB,KAAK,KAAK,WAAW,GAAG;AACpD,UAAM,IAAI,UAAU,mCAAmC;AAAA,EACzD;AACA,MAAI,KAAK,YAAY,SAAS,mBAAmB;AAC/C,UAAM,IAAI,WAAW,8BAA8B;AAAA,EACrD;AAEA,QAAM,QAAQ,aAAa,KAAK,WAAW;AAC3C,MAAI,MAAM,WAAW,KAAK,MAAM,SAAS,iBAAiB;AACxD,UAAM,IAAI,WAAW,8BAA8B;AAAA,EACrD;AACA,MAAI,aAAa,KAAK,MAAM,KAAK,aAAa;AAC5C,UAAM,IAAI,UAAU,mCAAmC;AAAA,EACzD;AAEA,QAAM,SAAS,aAAa,OAAO,CAAC,KAAM,KAAM,GAAI,CAAC;AACrD,QAAM,QAAQ;AAAA,IACV;AAAA,IACA,CAAC,KAAM,IAAM,IAAM,IAAM,IAAM,IAAM,IAAM,EAAI;AAAA,EACnD;AACA,QAAM,SAAS,MAAM,UAAU,MAC7B,OAAO,aAAa,GAAG,MAAM,SAAS,GAAG,CAAC,CAAC,MAAM,UACjD,OAAO,aAAa,GAAG,MAAM,SAAS,GAAG,EAAE,CAAC,MAAM;AACpD,QAAM,eAAe;AAAA,IACnB,cAAc;AAAA,IACd,aAAa;AAAA,IACb,cAAc;AAAA,IACd,cAAc,OAAO,KAAK;AAAA,IAC1B,cAAc,OAAO,KAAK;AAAA,EAC5B,EAAE,KAAK,QAAQ;AACf,MAAI,CAAC,cAAc;AACjB,UAAM,IAAI,UAAU,+CAA+C;AAAA,EACrE;AACA,SAAO,EAAC,UAAU,KAAK,UAAU,aAAa,KAAK,YAAW;AAChE;AAnDgB;;;ACrIhB,IAAM,mBAAmB;AACzB,IAAM,qBAAqB;AAC3B,IAAM,qBAAqB;AAE3B,IAAI;AACJ,IAAI,qBAAqB;AACzB,IAAI;AAEJ,SAAS,gBAAgB,OAAO;AAC9B,QAAM,SAAS,MAAM,QAAQ,MAAM,GAAG,EAAE,QAAQ,MAAM,GAAG;AACzD,SAAO,KAAK,OAAO,OAAO,KAAK,KAAK,OAAO,SAAS,CAAC,IAAI,GAAG,GAAG,CAAC;AAClE;AAHS;AAKT,SAAS,eAAe,OAAO;AAC7B,SAAO,KAAK,MAAM,gBAAgB,KAAK,CAAC;AAC1C;AAFS;AAIT,eAAe,QAAQ,SAAS,KAAK;AACnC,QAAM,WAAW,YAAY,WAAW;AACxC,MAAI,YAAY,aAAa,qBAAqB,WAC9C,qBAAqB,KAAK;AAC5B,WAAO;AAAA,EACT;AAEA,MAAI;AACJ,MAAI;AACF,eAAW,MAAM,QAAQ,kBAAkB;AAAA,EAC7C,QAAQ;AACN,UAAM,IAAI,MAAM,qDAAqD;AAAA,EACvE;AACA,MAAI,CAAC,SAAS,IAAI;AAChB,UAAM,IAAI,MAAM,qDAAqD;AAAA,EACvE;AACA,QAAM,OAAO,MAAM,SAAS,KAAK;AACjC,MAAI,CAAC,MAAM,QAAQ,KAAK,IAAI,GAAG;AAC7B,UAAM,IAAI,MAAM,mDAAmD;AAAA,EACrE;AACA,MAAI,UAAU;AACZ,UAAM,eAAe,SAAS,QAAQ,IAAI,eAAe,KAAK;AAC9D,UAAM,SAAS,OAAO,aAAa,MAAM,gBAAgB,IAAI,CAAC,KAAK,IAAI;AACvE,gBAAY;AACZ,yBAAqB,MAAM,KAAK,IAAI,IAAI,MAAM,IAAI;AAClD,uBAAmB;AAAA,EACrB;AACA,SAAO;AACT;AA5Be;AA8Bf,eAAsB,oBAClB,OACA;AAAA,EACE;AAAA,EACA;AAAA,EACA,UAAU,WAAW;AAAA,EACrB,MAAM,KAAK,IAAI;AACjB,GACF;AACA,MAAI,OAAO,UAAU,YAAY,MAAM,WAAW,KAAK,MAAM,SAAS,MAAM;AAC1E,WAAO;AAAA,EACT;AAEA,MAAI;AACF,UAAM,QAAQ,MAAM,MAAM,GAAG;AAC7B,QAAI,MAAM,WAAW,EAAG,QAAO;AAC/B,UAAM,SAAS,eAAe,MAAM,CAAC,CAAC;AACtC,UAAM,UAAU,eAAe,MAAM,CAAC,CAAC;AACvC,UAAM,kBAAkB,YAAY,aAAa;AACjD,UAAM,kBAAkB,MAAM,QAAQ,QAAQ,GAAG,KAC/C,QAAQ,IAAI,SAAS,KACrB,QAAQ,IAAI,SAAS,eAAe;AACtC,UAAM,aAAa,KAAK,MAAM,MAAM,GAAI;AAExC,QAAI,OAAO,QAAQ,WACf,OAAO,OAAO,QAAQ,YACtB,CAAC,mBACD,QAAQ,QAAQ,GAAG,gBAAgB,GAAG,aAAa,MACnD,OAAO,QAAQ,QAAQ,YACvB,CAAC,cAAc,SAAS,QAAQ,GAAG,KACnC,CAAC,OAAO,UAAU,QAAQ,GAAG,KAC7B,QAAQ,OAAO,cACf,CAAC,OAAO,UAAU,QAAQ,GAAG,KAC7B,QAAQ,MAAM,aAAa,sBAC1B,QAAQ,QAAQ,WACd,CAAC,OAAO,UAAU,QAAQ,GAAG,KAC5B,QAAQ,MAAM,aAAa,qBAAsB;AACvD,aAAO;AAAA,IACT;AAEA,QAAI;AACJ,QAAI;AACF,aAAO,MAAM,QAAQ,SAAS,GAAG;AAAA,IACnC,SAAS,OAAO;AACd,YAAM,IAAI,MAAM,uDAAuD;AAAA,QACrE,OAAO;AAAA,MACT,CAAC;AAAA,IACH;AACA,UAAM,MAAM,KAAK,KAAK,KAAK,CAACA,SAAQA,KAAI,QAAQ,OAAO,GAAG;AAC1D,QAAI,CAAC,OAAO,IAAI,QAAQ,SAAS,IAAI,OAAO,IAAI,QAAQ,SAAS;AAC/D,aAAO;AAAA,IACT;AAEA,UAAM,MAAM,MAAM,OAAO,OAAO;AAAA,MAC5B;AAAA,MACA;AAAA,MACA,EAAC,MAAM,qBAAqB,MAAM,UAAS;AAAA,MAC3C;AAAA,MACA,CAAC,QAAQ;AAAA,IACb;AACA,UAAM,YAAY,WAAW;AAAA,MACzB,gBAAgB,MAAM,CAAC,CAAC;AAAA,MACxB,CAAC,cAAc,UAAU,WAAW,CAAC;AAAA,IACzC;AACA,UAAM,gBAAgB,IAAI,YAAY,EAAE,OAAO,GAAG,MAAM,CAAC,CAAC,IAAI,MAAM,CAAC,CAAC,EAAE;AACxE,UAAM,iBAAiB,MAAM,OAAO,OAAO;AAAA,MACvC;AAAA,MACA;AAAA,MACA;AAAA,MACA;AAAA,IACJ;AACA,WAAO,iBAAiB,UAAU;AAAA,EACpC,SAAS,OAAO;AACd,QAAI,iBAAiB,aAAa,iBAAiB,aAAa;AAC9D,aAAO;AAAA,IACT;AACA,UAAM;AAAA,EACR;AACF;AA9EsB;;;ACnCtB,IAAM,yBAAyB,KAAK;AACpC,IAAM,0BAA0B,IAAI,OAAO;AAC3C,IAAM,uBAAuB,oBAAI,IAAI;AAAA,EACnC;AAAA,EACA;AAAA,EACA;AAAA,EACA;AACF,CAAC;AAED,IAAM,YAAN,cAAwB,MAAM;AAAA,EArB9B,OAqB8B;AAAA;AAAA;AAAA,EAC5B,YAAY,QAAQ,MAAM;AACxB,UAAM,IAAI;AACV,SAAK,SAAS;AACd,SAAK,OAAO;AAAA,EACd;AACF;AAEA,SAAS,aAAa,MAAM,QAAQ,UAAU,CAAC,GAAG;AAChD,SAAO,IAAI,SAAS,KAAK,UAAU,IAAI,GAAG;AAAA,IACxC;AAAA,IACA,SAAS,EAAC,gBAAgB,mCAAmC,GAAG,QAAO;AAAA,EACzE,CAAC;AACH;AALS;AAOT,SAAS,eAAe,KAAK;AAC3B,QAAM,aAAa,IAAI;AACvB,MAAI,CAAC,WAAY,QAAO;AACxB,SAAO,IAAI,IAAI,WAAW,MAAM,GAAG,EAAE,IAAI,CAAC,WAAW,OAAO,KAAK,CAAC,EAAE,OAAO,OAAO,CAAC;AACrF;AAJS;AAMT,SAAS,YAAY,QAAQ,SAAS;AACpC,QAAM,UAAU,EAAC,QAAQ,SAAQ;AACjC,MAAI,UAAU,QAAQ,IAAI,MAAM,GAAG;AACjC,YAAQ,6BAA6B,IAAI;AAAA,EAC3C;AACA,SAAO;AACT;AANS;AAQT,SAAS,iBAAiB,QAAQ;AAChC,MAAI;AACF,UAAM,MAAM,IAAI,IAAI,MAAM;AAC1B,WAAO,IAAI,aAAa,WACtB,CAAC,aAAa,WAAW,EAAE,SAAS,IAAI,QAAQ;AAAA,EACpD,QAAQ;AACN,WAAO;AAAA,EACT;AACF;AARS;AAUT,SAAS,YAAY,SAAS,KAAK;AACjC,QAAM,SAAS,QAAQ,QAAQ,IAAI,QAAQ;AAC3C,QAAM,UAAU,eAAe,GAAG;AAClC,QAAM,YAAY,CAAC,UAAU,QAAQ,IAAI,MAAM,KAAK,iBAAiB,MAAM;AAC3E,MAAI,CAAC,WAAW;AACd,WAAO,aAAa,EAAC,OAAO,qBAAoB,GAAG,KAAK,YAAY,MAAM,OAAO,CAAC;AAAA,EACpF;AACA,QAAM,UAAU,YAAY,QAAQ,OAAO;AAC3C,MAAI,QAAQ,WAAW,WAAW;AAChC,YAAQ,8BAA8B,IAAI;AAC1C,YAAQ,8BAA8B,IAAI;AAC1C,YAAQ,wBAAwB,IAAI;AACpC,WAAO,IAAI,SAAS,MAAM,EAAC,QAAQ,KAAK,QAAO,CAAC;AAAA,EAClD;AACA,SAAO,EAAC,SAAS,QAAO;AAC1B;AAfS;AAiBT,eAAe,aAAa,SAAS,UAAU;AAC7C,QAAM,iBAAiB,QAAQ,QAAQ,IAAI,gBAAgB;AAC3D,MAAI,kBAAkB,OAAO,cAAc,IAAI,UAAU;AACvD,UAAM,IAAI,UAAU,KAAK,mBAAmB;AAAA,EAC9C;AACA,MAAI,CAAC,QAAQ,KAAM,OAAM,IAAI,UAAU,KAAK,iBAAiB;AAE7D,QAAM,SAAS,QAAQ,KAAK,UAAU;AACtC,QAAM,SAAS,CAAC;AAChB,MAAI,QAAQ;AACZ,MAAI;AACF,WAAO,MAAM;AACX,YAAM,EAAC,MAAM,MAAK,IAAI,MAAM,OAAO,KAAK;AACxC,UAAI,KAAM;AACV,eAAS,MAAM;AACf,UAAI,QAAQ,UAAU;AACpB,cAAM,OAAO,OAAO;AACpB,cAAM,IAAI,UAAU,KAAK,mBAAmB;AAAA,MAC9C;AACA,aAAO,KAAK,KAAK;AAAA,IACnB;AAAA,EACF,UAAE;AACA,WAAO,YAAY;AAAA,EACrB;AAEA,QAAM,YAAY,IAAI,WAAW,KAAK;AACtC,MAAI,SAAS;AACb,aAAW,SAAS,QAAQ;AAC1B,cAAU,IAAI,OAAO,MAAM;AAC3B,cAAU,MAAM;AAAA,EAClB;AACA,MAAI;AACF,WAAO,KAAK,MAAM,IAAI,YAAY,EAAE,OAAO,SAAS,CAAC;AAAA,EACvD,QAAQ;AACN,UAAM,IAAI,UAAU,KAAK,iBAAiB;AAAA,EAC5C;AACF;AApCe;AAsCf,eAAe,gBAAgB,SAAS,KAAK;AAC3C,QAAM,QAAQ,QAAQ,QAAQ,IAAI,qBAAqB;AACvD,QAAM,UAAU,IAAI,oBAAoB,IACnC,MAAM,GAAG,EACT,IAAI,CAAC,UAAU,MAAM,KAAK,CAAC,EAC3B,OAAO,OAAO;AACnB,MAAI,CAAC,IAAI,2BAA2B,OAAO,WAAW,GAAG;AACvD,UAAM,IAAI,UAAU,KAAK,qBAAqB;AAAA,EAChD;AACA,MAAI;AACF,UAAM,SAAS,MAAM,oBAAoB,OAAO;AAAA,MAC9C,eAAe,IAAI;AAAA,MACnB,eAAe;AAAA,IACjB,CAAC;AACD,QAAI,CAAC,OAAQ,OAAM,IAAI,UAAU,KAAK,oBAAoB;AAAA,EAC5D,SAAS,OAAO;AACd,QAAI,iBAAiB,UAAW,OAAM;AACtC,YAAQ,MAAM,8CAA8C;AAC5D,UAAM,IAAI,UAAU,KAAK,uBAAuB;AAAA,EAClD;AACF;AApBe;AAsBf,eAAe,iBAAiB,SAAS,KAAK;AAC5C,MAAI,CAAC,IAAI,iBAAiB;AACxB,UAAM,IAAI,UAAU,KAAK,6BAA6B;AAAA,EACxD;AACA,QAAM,WAAW,QAAQ,QAAQ,IAAI,kBAAkB,KAAK;AAC5D,QAAM,EAAC,QAAO,IAAI,MAAM,IAAI,gBAAgB,MAAM,EAAC,KAAK,SAAQ,CAAC;AACjE,MAAI,CAAC,QAAS,OAAM,IAAI,UAAU,KAAK,cAAc;AACvD;AAPe;AASf,SAAS,YAAY,OAAO;AAC1B,MAAI,iBAAiB,WAAW;AAC9B,WAAO,EAAC,QAAQ,MAAM,QAAQ,OAAO,MAAM,KAAI;AAAA,EACjD;AACA,QAAM,SAAS,OAAO,OAAO,UAAU,OAAO,UAAU;AACxD,MAAI,WAAW,IAAK,QAAO,EAAC,QAAQ,KAAK,OAAO,kBAAiB;AACjE,MAAI,WAAW,OAAO,WAAW,KAAK;AACpC,WAAO,EAAC,QAAQ,KAAK,OAAO,0BAAyB;AAAA,EACvD;AACA,SAAO,EAAC,QAAQ,KAAK,OAAO,0BAAyB;AACvD;AAVS;AAYT,SAAS,aAAa,KAAK;AACzB,MAAI,OAAO,IAAI,mBAAmB,YAAY,IAAI,eAAe,SAAS,IAAI;AAC5E,UAAM,IAAI,UAAU,KAAK,mBAAmB;AAAA,EAC9C;AACF;AAJS;AAMT,SAAS,eAAe,OAAO,YAAY,OAAO;AAChD,QAAM,SAAS,YAAY,kCAAkC;AAC7D,SAAO,2DAA2D,KAAK,IAAI,MAAM;AACnF;AAHS;AAKT,eAAe,WAAW,KAAK,OAAO,SAAS,EAAC,YAAY,MAAK,IAAI,CAAC,GAAG;AACvE,QAAM,MAAM,eAAe,OAAO,SAAS;AAC3C,QAAM,WAAW,MAAM,MAAM,KAAK;AAAA,IAChC,QAAQ;AAAA,IACR,SAAS;AAAA,MACP,gBAAgB;AAAA,MAChB,kBAAkB,IAAI;AAAA,IACxB;AAAA,IACA,MAAM,KAAK,UAAU,OAAO;AAAA,IAC5B,QAAQ,YAAY,QAAQ,IAAM;AAAA,EACpC,CAAC;AACD,MAAI,CAAC,SAAS,IAAI;AAChB,QAAI,UAAU;AACd,QAAI;AACF,gBAAU,MAAM,SAAS,MAAM,EAAE,KAAK;AACtC,cAAQ,MAAM,2BAA2B,SAAS,QAAQ,OAAO;AAAA,IACnE,SAAS,GAAG;AAAA,IAAC;AACb,UAAM,SAAS,SAAS;AACxB,QAAI,WAAW,IAAK,OAAM,OAAO,OAAO,IAAI,MAAM,0BAA0B,OAAO,GAAG,EAAC,OAAM,CAAC;AAC9F,QAAI,WAAW,IAAK,OAAM,OAAO,OAAO,IAAI,MAAM,8BAA8B,OAAO,GAAG,EAAC,OAAM,CAAC;AAClG,QAAI,WAAW,OAAO,WAAW,IAAK,OAAM,OAAO,OAAO,IAAI,MAAM,wBAAwB,OAAO,GAAG,EAAC,OAAM,CAAC;AAC9G,UAAM,OAAO,OAAO,IAAI,MAAM,kCAAkC,OAAO,GAAG,EAAC,QAAQ,UAAU,MAAM,MAAM,OAAM,CAAC;AAAA,EAClH;AACA,SAAO;AACT;AAxBe;AA0Bf,SAAS,eAAe,OAAO;AAC7B,QAAM,SAAS,OAAO,OAAO,UAAU,OAAO,cAAc,OAAO,IAAI;AACvE,MAAI,WAAW,IAAK,QAAO;AAC3B,MAAI,WAAW,IAAK,QAAO;AAC3B,MAAI,WAAW,OAAO,WAAW,IAAK,QAAO;AAC7C,SAAO;AACT;AANS;AAQT,SAAS,gBAAgB,WAAW,OAAO,MAAM;AAC/C,UAAQ,MAAM,sBAAsB,EAAC,WAAW,OAAO,KAAI,CAAC;AAC9D;AAFS;AAaT,SAAS,kBAAkB,SAAS;AAClC,MAAI,OAAO,YAAY,SAAU,QAAO;AACxC,MAAI,MAAM,QAAQ,OAAO,GAAG;AAC1B,WAAO,QAAQ,IAAI,CAAC,SAAS,OAAO,SAAS,WAAW,OAAO,MAAM,QAAQ,EAAE,EAC1E,KAAK,EAAE;AAAA,EACd;AACA,SAAO;AACT;AAPS;AAST,SAAS,cAAc,QAAQ,OAAO,kBAAkB,OAAO;AAC7D,QAAM,SAAS,OAAO,UAAU;AAChC,QAAM,UAAU,IAAI,YAAY;AAChC,QAAM,UAAU,IAAI,YAAY;AAChC,MAAI,UAAU;AACd,MAAI,WAAW;AACf,MAAI,cAAc;AAClB,MAAI,gBAAgB;AACpB,MAAI,eAAe;AACnB,MAAI,aAAa;AAEjB,WAAS,WAAW,MAAM,YAAY;AACpC,oBAAgB;AAChB,QAAI,SAAS,UAAU;AACrB,qBAAe;AACf,aAAO;AAAA,IACT;AACA,QAAI;AACJ,QAAI;AACF,cAAQ,KAAK,MAAM,IAAI;AAAA,IACzB,QAAQ;AACN,mBAAa;AACb,aAAO;AAAA,IACT;AACA,QAAI,OAAO,OAAO;AAChB,YAAM,OAAO,eAAe,MAAM,KAAK;AACvC,mBAAa,SAAS,4BAClB,6BACA;AACJ,aAAO;AAAA,IACT;AAEA,UAAM,UAAU,MAAM,QAAQ,MAAM,OAAO,IACvC,MAAM,UACN,MAAM,UAAU,CAAC,MAAM,OAAO,IAAI,CAAC;AACvC,UAAM,cAAc,OAAO,YAAY;AAAA,MACnC,CAAC,cAAc,WAAW,SAAS,SAAS,CAAC;AAAA,IACjD,KAAK,CAAC;AACN,UAAM,OAAO,YAAY,IAAI,CAAC,SAAS,MAAM,QAAQ,EAAE,EAAE,KAAK,EAAE,KAC9D,QAAQ;AAAA,MAAI,CAAC,WACX;AAAA,QACI,QAAQ,OAAO,WACf,QAAQ,SAAS,WACjB,QAAQ;AAAA,MACZ;AAAA,IACF,EAAE,KAAK,EAAE,KAAK,kBAAkB,MAAM,YAAY,MAAM,IAAI;AAC9D,QAAI,MAAM;AACR,iBAAW,QAAQ,QAAQ;AAAA,QACvB,SAAS,KAAK,UAAU,EAAC,KAAI,CAAC,CAAC;AAAA;AAAA;AAAA,MACnC,CAAC;AACD,oBAAc;AAAA,IAChB;AACA,WAAO;AAAA,EACT;AA1CS;AA4CT,WAAS,aAAa,OAAO,YAAY;AACvC,UAAM,OAAO,MAAM,MAAM,OAAO,EAC3B,OAAO,CAAC,SAAS,KAAK,WAAW,OAAO,CAAC,EACzC,IAAI,CAAC,SAAS,KAAK,MAAM,CAAC,EAAE,QAAQ,MAAM,EAAE,CAAC,EAC7C,KAAK,IAAI;AACd,QAAI,CAAC,KAAM,QAAO;AAClB,WAAO,WAAW,MAAM,UAAU;AAAA,EACpC;AAPS;AAST,iBAAe,KAAK,YAAY,MAAM;AACpC,eAAW;AACX,QAAI;AACF,YAAM,OAAO,OAAO;AAAA,IACtB,QAAQ;AAAA,IAER;AACA,eAAW,QAAQ,QAAQ;AAAA,MACvB;AAAA,QAAuB,KAAK,UAAU,EAAC,OAAO,KAAI,CAAC,CAAC;AAAA;AAAA;AAAA,IACxD,CAAC;AACD,eAAW,QAAQ,QAAQ,OAAO,kBAAkB,CAAC;AACrD,oBAAgB,eAAe,OAAO,IAAI;AAC1C,eAAW,MAAM;AAAA,EACnB;AAbe;AAef,SAAO,IAAI,eAAe;AAAA,IACxB,MAAM,KAAK,YAAY;AACrB,UAAI,SAAU;AACd,UAAI;AACF,eAAO,MAAM;AACX,gBAAM,YAAY,aAAa,KAAK,OAAO;AAC3C,cAAI,WAAW;AACb,kBAAM,QAAQ,QAAQ,MAAM,GAAG,UAAU,KAAK;AAC9C,sBAAU,QAAQ,MAAM,UAAU,QAAQ,UAAU,CAAC,EAAE,MAAM;AAC7D,gBAAI,aAAa,OAAO,UAAU,GAAG;AACnC,kBAAI,CAAC,cAAc;AACjB,sBAAM,KAAK,YAAY,UAAU;AACjC;AAAA,cACF;AACA,kBAAI,CAAC,aAAa;AAChB,sBAAM,KAAK,YAAY,mBAAmB;AAC1C;AAAA,cACF;AACA,yBAAW;AACX,oBAAM,OAAO,OAAO;AACpB,yBAAW,QAAQ,QAAQ,OAAO,kBAAkB,CAAC;AACrD,yBAAW,MAAM;AACjB;AAAA,YACF;AACA;AAAA,UACF;AAEA,gBAAM,EAAC,MAAM,MAAK,IAAI,MAAM,OAAO,KAAK;AACxC,qBAAW,QAAQ,OAAO,OAAO,EAAC,QAAQ,CAAC,KAAI,CAAC;AAChD,cAAI,CAAC,KAAM;AAEX,cAAI,QAAQ,KAAK,GAAG;AAClB,kBAAM,QAAQ;AACd,sBAAU;AACV,gBAAI,aAAa,OAAO,UAAU,GAAG;AACnC,kBAAI,CAAC,cAAc;AACjB,sBAAM,KAAK,YAAY,UAAU;AACjC;AAAA,cACF;AACA,kBAAI,CAAC,aAAa;AAChB,sBAAM,KAAK,YAAY,mBAAmB;AAC1C;AAAA,cACF;AACA,yBAAW;AACX,yBAAW,QAAQ,QAAQ,OAAO,kBAAkB,CAAC;AACrD,yBAAW,MAAM;AACjB,qBAAO,YAAY;AACnB;AAAA,YACF;AAAA,UACF;AACA,cAAI,CAAC,gBAAgB,EAAE,mBAAmB,iBAAiB,cAAc;AACvE,kBAAM;AAAA,cACF;AAAA,cACA,gBAAgB,aAAa;AAAA,YACjC;AACA,mBAAO,YAAY;AACnB;AAAA,UACF;AACA,cAAI,CAAC,aAAa;AAChB,kBAAM,KAAK,YAAY,mBAAmB;AAC1C,mBAAO,YAAY;AACnB;AAAA,UACF;AACA,qBAAW;AACX,qBAAW,QAAQ,QAAQ,OAAO,kBAAkB,CAAC;AACrD,qBAAW,MAAM;AACjB,iBAAO,YAAY;AACnB;AAAA,QACF;AAAA,MACF,SAAS,OAAO;AACd,YAAI,CAAC,UAAU;AACb,gBAAM,OAAO,eAAe,KAAK;AACjC,gBAAM,KAAK,YAAY,SAAS,4BAC1B,0BACA,IAAI;AAAA,QACZ;AACA,YAAI;AACF,iBAAO,YAAY;AAAA,QACrB,QAAQ;AAAA,QAER;AAAA,MACF;AAAA,IACF;AAAA,IACA,MAAM,OAAO,QAAQ;AACnB,iBAAW;AACX,YAAM,OAAO,OAAO,MAAM;AAAA,IAC5B;AAAA,EACF,CAAC;AACH;AAvKS;AAyKT,eAAe,WAAW,SAAS,KAAK,MAAM;AAC5C,QAAM,gBAAgB,SAAS,GAAG;AAClC,QAAM,iBAAiB,SAAS,GAAG;AACnC,MAAI;AACJ,MAAI;AACF,YAAQ;AAAA,MACJ,MAAM,aAAa,SAAS,sBAAsB;AAAA,IACtD;AAAA,EACF,SAAS,OAAO;AACd,QAAI,iBAAiB,aAAa,iBAAiB,YAAY;AAC7D,YAAM,IAAI;AAAA,QACN,iBAAiB,aAAa,MAAM;AAAA,QACpC,iBAAiB,aAAa,sBAAsB;AAAA,MACxD;AAAA,IACF;AACA,UAAM;AAAA,EACR;AACA,eAAa,GAAG;AAChB,QAAM,WAAW;AAAA,IACf,GAAG,MAAM,QAAQ,IAAI,CAAC,aAAa;AAAA,MACjC,MAAM,QAAQ;AAAA,MACd,OAAO,QAAQ;AAAA,IACjB,EAAE;AAAA,IACF,EAAC,MAAM,QAAQ,OAAO,CAAC,EAAC,MAAM,MAAM,OAAM,CAAC,EAAC;AAAA,EAC9C;AACA,MAAI;AACJ,MAAI;AACF,qBAAiB,MAAM,WAAW,KAAK,YAAY;AAAA,MACjD,mBAAmB,EAAC,OAAO,CAAC,EAAC,MAAM,mBAAkB,CAAC,EAAC;AAAA,MACvD;AAAA,MACA,kBAAkB,EAAC,aAAa,KAAK,iBAAiB,KAAI;AAAA,IAC5D,GAAG,EAAC,WAAW,KAAI,CAAC;AAAA,EACtB,SAAS,OAAO;AACd,oBAAgB,mBAAmB,YAAY,eAAe,KAAK,CAAC;AACpE,UAAM;AAAA,EACR;AACA,MAAI,CAAC,eAAe,QAAQ,OAAO,eAAe,KAAK,cAAc,YAAY;AAC/E,UAAM,IAAI,UAAU,KAAK,mBAAmB;AAAA,EAC9C;AACA,QAAM,WAAW,eAAe;AAChC,SAAO,IAAI,SAAS,cAAc,UAAU,YAAY,IAAI,GAAG;AAAA,IAC7D,QAAQ;AAAA,IACR,SAAS;AAAA,MACP,GAAG;AAAA,MACH,iBAAiB;AAAA,MACjB,gBAAgB;AAAA,IAClB;AAAA,EACF,CAAC;AACH;AAhDe;AAkDf,eAAe,YAAY,SAAS,KAAK,MAAM;AAC7C,QAAM,gBAAgB,SAAS,GAAG;AAClC,QAAM,iBAAiB,SAAS,GAAG;AACnC,MAAI;AACJ,MAAI;AACF,YAAQ;AAAA,MACJ,MAAM,aAAa,SAAS,uBAAuB;AAAA,IACvD;AAAA,EACF,SAAS,OAAO;AACd,QAAI,iBAAiB,aAAa,iBAAiB,YAAY;AAC7D,YAAM,IAAI;AAAA,QACN,iBAAiB,aAAa,MAAM;AAAA,QACpC,iBAAiB,aAAa,sBAAsB;AAAA,MACxD;AAAA,IACF;AACA,UAAM;AAAA,EACR;AACA,eAAa,GAAG;AAChB,MAAI;AACJ,MAAI;AACF,UAAM,iBAAiB,MAAM,WAAW,KAAK,aAAa;AAAA,MACxD,mBAAmB;AAAA,QACjB,OAAO,CAAC,EAAC,MAAM,yBAAwB,CAAC;AAAA,MAC1C;AAAA,MACA,UAAU,CAAC;AAAA,QACT,MAAM;AAAA,QACN,OAAO;AAAA,UACL,EAAC,MAAM,aAAY;AAAA,UACnB;AAAA,YACE,YAAY,EAAC,UAAU,MAAM,UAAU,MAAM,MAAM,YAAW;AAAA,YAC9D,aAAa,EAAC,WAAW,MAAM,UAAU,MAAM,MAAM,YAAW;AAAA,UAClE;AAAA,QACF;AAAA,MACF,CAAC;AAAA,MACD,kBAAkB;AAAA,QAChB,kBAAkB;AAAA,QAClB,gBAAgB;AAAA,QAChB,aAAa;AAAA,QACb,iBAAiB;AAAA,MACnB;AAAA,IACF,CAAC;AACD,eAAW,MAAM,eAAe,KAAK;AAAA,EACvC,SAAS,OAAO;AACd,oBAAgB,wBAAwB,aAAa,eAAe,KAAK,CAAC;AAC1E,UAAM;AAAA,EACR;AACA,QAAM,OAAO,UAAU,aAAa,CAAC,GAAG,SAAS,OAC3C,IAAI,CAAC,SAAS,MAAM,QAAQ,EAAE,EAAE,KAAK,EAAE,KAAK;AAClD,MAAI,CAAC,KAAM,OAAM,IAAI,UAAU,KAAK,mBAAmB;AAEvD,MAAI;AACJ,MAAI;AACF,UAAM,WAAW,KAAK,KAAK,EACtB,QAAQ,qBAAqB,EAAE,EAC/B,QAAQ,WAAW,EAAE;AAC1B,aAAS,KAAK,MAAM,QAAQ;AAAA,EAC9B,QAAQ;AACN,UAAM,IAAI,UAAU,KAAK,qBAAqB;AAAA,EAChD;AACA,MAAI,CAAC,UAAU,OAAO,WAAW,YAAY,MAAM,QAAQ,MAAM,KAC7D,OAAO,OAAO,cAAc,YAC5B,OAAO,UAAU,KAAK,EAAE,WAAW,GAAG;AACxC,UAAM,IAAI,UAAU,KAAK,qBAAqB;AAAA,EAChD;AAGA,QAAM,iBAAiB,CAAC,SAAS,UAAU,aAAa,WAAW;AACnE,SAAO,eAAe,eAAe,SAAS,OAAO,YAAY,IAC3D,OAAO,eACP;AACN,SAAO,aAAa,OAAO,OAAO,eAAe,YAAY,OAAO,SAAS,OAAO,UAAU,IACxF,KAAK,IAAI,GAAG,KAAK,IAAI,GAAG,OAAO,UAAU,CAAC,IAC1C;AACN,SAAO,iBAAiB,OAAO,OAAO,mBAAmB,YAAY,OAAO,eAAe,KAAK,EAAE,SAAS,IACrG,OAAO,eAAe,KAAK,IAC3B;AACN,SAAO,kBAAkB,OAAO,OAAO,oBAAoB,YAAY,OAAO,gBAAgB,KAAK,EAAE,SAAS,IACxG,OAAO,gBAAgB,KAAK,IAC5B;AACN,SAAO,qBAAqB,OAAO,OAAO,uBAAuB,YAAY,OAAO,mBAAmB,KAAK,EAAE,SAAS,IACjH,OAAO,mBAAmB,KAAK,IAC/B;AACN,SAAO,gBAAgB,OAAO,OAAO,kBAAkB,YAAY,OAAO,cAAc,KAAK,EAAE,SAAS,IAClG,OAAO,cAAc,KAAK,IAC1B;AACN,SAAO,cAAc,MAAM,QAAQ,OAAO,WAAW,IAC/C,OAAO,YAAY,OAAO,CAAC,MAAM,OAAO,MAAM,YAAY,EAAE,KAAK,EAAE,SAAS,CAAC,IAC7E,CAAC;AACP,SAAO,eAAe,OAAO,OAAO,iBAAiB,YAAY,OAAO,aAAa,KAAK,EAAE,SAAS,IAC/F,OAAO,aAAa,KAAK,IACzB;AACN,SAAO,YAAY,OAAO,OAAO,cAAc,YAAY,OAAO,UAAU,KAAK,EAAE,SAAS,IACtF,OAAO,UAAU,KAAK,IACtB;AACN,SAAO,iBAAiB,OAAO,OAAO,mBAAmB,YAAY,OAAO,eAAe,KAAK,EAAE,SAAS,IACrG,OAAO,eAAe,KAAK,IAC3B;AACN,SAAO,SAAS,OAAO,OAAO,WAAW,YAAY,OAAO,OAAO,KAAK,EAAE,SAAS,IAC7E,OAAO,OAAO,KAAK,IACnB;AACN,SAAO,gBAAgB,OAAO,OAAO,kBAAkB,YAAY,OAAO,cAAc,KAAK,EAAE,SAAS,IAClG,OAAO,cAAc,KAAK,IAC1B;AACN,SAAO,qBAAqB,OAAO,OAAO,uBAAuB,YAAY,OAAO,mBAAmB,KAAK,EAAE,SAAS,IACjH,OAAO,mBAAmB,KAAK,IAC/B;AACN,SAAO,kBAAkB,OAAO,OAAO,oBAAoB,YAAY,OAAO,gBAAgB,KAAK,EAAE,SAAS,IACxG,OAAO,gBAAgB,KAAK,IAC5B;AACN,SAAO,UAAU,OAAO,OAAO,YAAY,YAAY,OAAO,UAAU;AACxE,QAAM,iBAAiB,CAAC,aAAa,iBAAiB,SAAS;AAC/D,SAAO,0BAA0B,eAAe,SAAS,OAAO,uBAAuB,IACjF,OAAO,0BACP;AAEN,QAAM,eAAe,OAAO,iBAAiB,eAC3C,OAAO,UAAU,KAAK,EAAE,YAAY,MAAM,4BAC1C,OAAO,aAAa;AACtB,MAAI,cAAc;AAChB,WAAO,eAAe;AACtB,WAAO,YAAY;AACnB,WAAO,aAAa,KAAK,IAAI,OAAO,YAAY,IAAI;AACpD,WAAO,eAAe;AACtB,WAAO,YAAY;AACnB,WAAO,iBAAiB;AACxB,WAAO,SAAS;AAChB,WAAO,gBAAgB;AACvB,WAAO,0BAA0B;AACjC,WAAO,qBAAqB;AAC5B,WAAO,iBACL;AACF,WAAO,kBACL;AACF,WAAO,qBACL;AACF,WAAO,gBACL;AACF,WAAO,cAAc;AAAA,MACjB,OAAO;AAAA,MACP;AAAA,IACJ;AACA,WAAO,UAAU;AACjB,WAAO,kBAAkB;AAAA,EAC3B,WAAW,OAAO,iBAAiB,UAAU;AAC3C,WAAO,YAAY;AACnB,WAAO,eAAe;AACtB,WAAO,YAAY;AACnB,WAAO,iBAAiB;AACxB,WAAO,SAAS;AAChB,WAAO,gBAAgB;AACvB,WAAO,0BAA0B;AACjC,WAAO,qBAAqB;AAC5B,WAAO,kBAAkB;AACzB,WAAO,qBAAqB;AAC5B,WAAO,gBAAgB;AACvB,WAAO,cAAc;AAAA,MACjB,OAAO;AAAA,MACP;AAAA,IACJ;AACA,WAAO,kBAAkB,OAAO,mBAC9B;AAAA,EACJ,WAAW,OAAO,iBAAiB,aAAa;AAC9C,WAAO,YAAY;AACnB,WAAO,iBAAiB;AACxB,WAAO,SAAS;AAChB,WAAO,eAAe;AACtB,WAAO,YAAY;AACnB,WAAO,gBAAgB;AACvB,WAAO,0BAA0B;AACjC,WAAO,qBAAqB;AAC5B,WAAO,kBAAkB;AACzB,WAAO,qBAAqB;AAC5B,WAAO,gBAAgB;AACvB,WAAO,cAAc;AAAA,MACjB,OAAO;AAAA,MACP;AAAA,IACJ;AACA,WAAO,UAAU;AACjB,WAAO,kBAAkB;AAAA,EAC3B,OAAO;AACL,QAAI,CAAC,kBAAkB,KAAK,OAAO,aAAa,GAAG;AACjD,aAAO,gBAAgB,GAAG,OAAO,aAAa;AAAA,IAChD;AACA,WAAO,cAAc;AAAA,MACjB,OAAO;AAAA,MACP;AAAA,IACJ;AACA,QAAI,OAAO,SAAS;AAClB,UAAI,CAAC,kBAAkB,KAAK,OAAO,mBAAmB,EAAE,GAAG;AACzD,eAAO,kBAAkB,OAAO,kBAC5B,GAAG,OAAO,eAAe,wCACzB;AAAA,MACN;AAAA,IACF,OAAO;AACL,aAAO,kBAAkB,OAAO,mBAC9B;AAAA,IACJ;AAAA,EACF;AACA,SAAO,aAAa,QAAQ,KAAK,IAAI;AACvC;AAvMe;AAyMf,SAAS,cAAc,aAAa,SAAS;AAC3C,SAAO,YAAY,SAAS,OAAO,IAAI,cAAc,CAAC,GAAG,aAAa,OAAO;AAC/E;AAFS;AAIT,IAAO,gBAAQ;AAAA,EACb,MAAM,MAAM,SAAS,KAAK;AACxB,UAAM,aAAa,YAAY,SAAS,GAAG;AAC3C,QAAI,sBAAsB,SAAU,QAAO;AAC3C,UAAM,EAAC,SAAS,KAAI,IAAI;AACxB,QAAI,QAAQ,WAAW,UAAW,QAAO,IAAI,SAAS,MAAM,EAAC,QAAQ,KAAK,SAAS,KAAI,CAAC;AACxF,QAAI,QAAQ,WAAW,QAAQ;AAC7B,aAAO,aAAa,EAAC,OAAO,qBAAoB,GAAG,KAAK;AAAA,QACtD,GAAG;AAAA,QACH,OAAO;AAAA,MACT,CAAC;AAAA,IACH;AAEA,UAAM,WAAW,IAAI,IAAI,QAAQ,GAAG,EAAE,SAAS,QAAQ,QAAQ,EAAE;AACjE,QAAI;AACF,UAAI,aAAa,cAAe,QAAO,MAAM,WAAW,SAAS,KAAK,IAAI;AAC1E,UAAI,aAAa,eAAgB,QAAO,MAAM,YAAY,SAAS,KAAK,IAAI;AAC5E,aAAO,aAAa,EAAC,OAAO,YAAW,GAAG,KAAK,IAAI;AAAA,IACrD,SAAS,OAAO;AACd,YAAM,SAAS,YAAY,KAAK;AAChC,UAAI,OAAO,UAAU,KAAK;AACxB,gBAAQ,MAAM,0BAA0B,OAAO,KAAK;AAAA,MACtD;AACA,aAAO,aAAa,EAAC,OAAO,OAAO,MAAK,GAAG,OAAO,QAAQ,IAAI;AAAA,IAChE;AAAA,EACF;AACF;"}
--99c9f51e2351763a329a99a37e7431181fa7662e465fc9bd180c9eaa3725--
