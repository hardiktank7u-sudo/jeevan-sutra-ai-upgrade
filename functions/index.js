import {
  CHAT_MODEL,
  PLANT_MODEL,
  PLANT_PROMPT,
  PLANT_RESPONSE_SCHEMA,
  PLANT_SYSTEM_INSTRUCTION,
  SYSTEM_INSTRUCTION,
  validateChatRequest,
  validatePlantRequest,
} from "./ai_backend.js";
import {verifyAppCheckToken} from "./app_check.js";

const CHAT_MAX_REQUEST_BYTES = 64 * 1024;
const PLANT_MAX_REQUEST_BYTES = 7 * 1024 * 1024;
const DEFAULT_CORS_ORIGINS = new Set([
  "http://localhost",
  "http://127.0.0.1",
  "https://jeevan-b390e.web.app",
  "https://jeevan-b390e.firebaseapp.com",
]);

class HttpError extends Error {
  constructor(status, code) {
    super(code);
    this.status = status;
    this.code = code;
  }
}

function jsonResponse(body, status, headers = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {"Content-Type": "application/json; charset=utf-8", ...headers},
  });
}

function allowedOrigins(env) {
  const configured = env.CORS_ALLOWED_ORIGINS;
  if (!configured) return DEFAULT_CORS_ORIGINS;
  return new Set(configured.split(",").map((origin) => origin.trim()).filter(Boolean));
}

function corsHeaders(origin, origins) {
  const headers = {"Vary": "Origin"};
  if (origin && origins.has(origin)) {
    headers["Access-Control-Allow-Origin"] = origin;
  }
  return headers;
}

function isLocalDevOrigin(origin) {
  try {
    const url = new URL(origin);
    return url.protocol === "http:" &&
      ["localhost", "127.0.0.1"].includes(url.hostname);
  } catch {
    return false;
  }
}

function requestCors(request, env) {
  const origin = request.headers.get("Origin");
  const origins = allowedOrigins(env);
  const isAllowed = !origin || origins.has(origin) || isLocalDevOrigin(origin);
  if (!isAllowed) {
    return jsonResponse({error: "ORIGIN_NOT_ALLOWED"}, 403, corsHeaders(null, origins));
  }
  const headers = corsHeaders(origin, origins);
  if (request.method === "OPTIONS") {
    headers["Access-Control-Allow-Methods"] = "POST, OPTIONS";
    headers["Access-Control-Allow-Headers"] = "Content-Type, X-Firebase-AppCheck";
    headers["Access-Control-Max-Age"] = "3600";
    return new Response(null, {status: 204, headers});
  }
  return {headers, origins};
}

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
      const {done, value} = await reader.read();
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

async function requireAppCheck(request, env) {
  const token = request.headers.get("X-Firebase-AppCheck");
  const appIds = (env.FIREBASE_APP_IDS || "")
      .split(",")
      .map((appId) => appId.trim())
      .filter(Boolean);
  if (!env.FIREBASE_PROJECT_NUMBER || appIds.length === 0) {
    throw new HttpError(503, "AUTH_NOT_CONFIGURED");
  }
  try {
    const claims = await verifyAppCheckToken(token, {
      projectNumber: env.FIREBASE_PROJECT_NUMBER,
      allowedAppIds: appIds,
    });
    if (!claims) throw new HttpError(401, "APP_CHECK_REJECTED");
  } catch (error) {
    if (error instanceof HttpError) throw error;
    console.error("Firebase App Check verification unavailable.");
    throw new HttpError(503, "APP_CHECK_UNAVAILABLE");
  }
}

async function enforceRateLimit(request, env) {
  if (!env.AI_RATE_LIMITER) {
    throw new HttpError(503, "RATE_LIMITER_NOT_CONFIGURED");
  }
  const clientIp = request.headers.get("CF-Connecting-IP") || "unknown";
  const {success} = await env.AI_RATE_LIMITER.limit({key: clientIp});
  if (!success) throw new HttpError(429, "RATE_LIMITED");
}

function publicError(error) {
  if (error instanceof HttpError) {
    return {status: error.status, error: error.code};
  }
  const status = Number(error?.status || error?.httpStatus);
  if (status === 429) return {status: 429, error: "AI_RATE_LIMITED"};
  if (status === 401 || status === 403) {
    return {status: 503, error: "AI_UPSTREAM_UNAVAILABLE"};
  }
  return {status: 502, error: "AI_UPSTREAM_UNAVAILABLE"};
}

function assertGemini(env) {
  if (typeof env.GEMINI_API_KEY !== "string" || env.GEMINI_API_KEY.length < 20) {
    throw new HttpError(503, "AI_NOT_CONFIGURED");
  }
}

function geminiEndpoint(model, streaming = false) {
  const action = streaming ? "streamGenerateContent?alt=sse" : "generateContent";
  return `https://generativelanguage.googleapis.com/v1beta/models/${model}:${action}`;
}

async function callGemini(env, model, payload, {streaming = false} = {}) {
  const url = geminiEndpoint(model, streaming);
  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-goog-api-key": env.GEMINI_API_KEY,
    },
    body: JSON.stringify(payload),
    signal: AbortSignal.timeout(45_000),
  });
  if (!response.ok) {
    const status = response.status;
    let errBody = "";
    try {
      errBody = await response.text();
    } catch (readError) {
      errBody = `[Unable to read response body: ${readError?.message || readError}]`;
    }
    console.error("Gemini upstream failed:", status, errBody);
    if (status === 429) throw Object.assign(new Error("Gemini rate limited: " + errBody), {status});
    if (status === 400) throw Object.assign(new Error("Gemini rejected request: " + errBody), {status});
    if (status === 401 || status === 403) throw Object.assign(new Error("Gemini auth error: " + errBody), {status});
    throw Object.assign(new Error("Gemini upstream unavailable: " + errBody), {status: status >= 500 ? 502 : status});
  }
  return response;
}

function diagnosticCode(error) {
  const status = Number(error?.status || error?.httpStatus || error?.code);
  if (status === 429) return "AI_RATE_LIMITED";
  if (status === 400) return "AI_INVALID_INPUT";
  if (status === 401 || status === 403) return "AI_ACCESS_DENIED";
  return "AI_UPSTREAM_UNAVAILABLE";
}

function logAIDiagnostic(operation, model, code) {
  console.error("Gemini diagnostic.", {operation, model, code});
}

function extractAIText(result) {
  const content = result?.choices?.[0]?.message?.content;
  if (typeof content === "string") return content;
  if (Array.isArray(content)) {
    return content.map((part) => part?.text || "").join("");
  }
  return typeof result?.response === "string" ? result.response : "";
}

function streamContentText(content) {
  if (typeof content === "string") return content;
  if (Array.isArray(content)) {
    return content.map((part) => typeof part === "string" ? part : part?.text || "")
        .join("");
  }
  return "";
}

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
      diagnostic = code === "AI_UPSTREAM_UNAVAILABLE"
        ? "AI_STREAM_UPSTREAM_ERROR"
        : code;
      return true;
    }

    const choices = Array.isArray(event.choices)
      ? event.choices
      : event.choices ? [event.choices] : [];
    const geminiParts = event?.candidates?.flatMap(
        (candidate) => candidate?.content?.parts || [],
    ) || [];
    const text = geminiParts.map((part) => part?.text || "").join("") ||
      choices.map((choice) =>
        streamContentText(
            choice?.delta?.content ??
            choice?.message?.content ??
            choice?.text,
        ),
      ).join("") || streamContentText(event.response ?? event.text);
    if (text) {
      controller.enqueue(encoder.encode(
          `data: ${JSON.stringify({text})}\n\n`,
      ));
      emittedText = true;
    }
    return false;
  }

  function processFrame(frame, controller) {
    const data = frame.split(/\r?\n/)
        .filter((line) => line.startsWith("data:"))
        .map((line) => line.slice(5).replace(/^ /, ""))
        .join("\n");
    if (!data) return false;
    return parseEvent(data, controller);
  }

  async function fail(controller, code) {
    finished = true;
    try {
      await reader.cancel();
    } catch {
      // The upstream stream may already be closed or errored.
    }
    controller.enqueue(encoder.encode(
        `event: error\ndata: ${JSON.stringify({error: code})}\n\n`,
    ));
    controller.enqueue(encoder.encode("data: [DONE]\n\n"));
    logAIDiagnostic("chat_stream", model, code);
    controller.close();
  }

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

          const {done, value} = await reader.read();
          pending += decoder.decode(value, {stream: !done});
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
                receivedEvent ? diagnostic : "EMPTY_AI_RESPONSE",
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
          await fail(controller, code === "AI_UPSTREAM_UNAVAILABLE"
              ? "AI_STREAM_INTERRUPTED"
              : code);
        }
        try {
          reader.releaseLock();
        } catch {
          // The stream may have already been cancelled by its consumer.
        }
      }
    },
    async cancel(reason) {
      finished = true;
      await reader.cancel(reason);
    },
  });
}

async function handleChat(request, env, cors) {
  await requireAppCheck(request, env);
  await enforceRateLimit(request, env);
  let input;
  try {
    input = validateChatRequest(
        await readJsonBody(request, CHAT_MAX_REQUEST_BYTES),
    );
  } catch (error) {
    if (error instanceof TypeError || error instanceof RangeError) {
      throw new HttpError(
          error instanceof RangeError ? 413 : 400,
          error instanceof RangeError ? "REQUEST_TOO_LARGE" : "INVALID_REQUEST",
      );
    }
    throw error;
  }
  assertGemini(env);
  const contents = [
    ...input.history.map((message) => ({
      role: message.role,
      parts: message.parts,
    })),
    {role: "user", parts: [{text: input.prompt}]},
  ];
  let geminiResponse;
  try {
    geminiResponse = await callGemini(env, CHAT_MODEL, {
      systemInstruction: {parts: [{text: SYSTEM_INSTRUCTION}]},
      contents,
      generationConfig: {temperature: 0.7, maxOutputTokens: 4096},
    }, {streaming: true});
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
      "Content-Type": "text/event-stream; charset=utf-8",
    },
  });
}

async function handlePlant(request, env, cors) {
  await requireAppCheck(request, env);
  await enforceRateLimit(request, env);
  let input;
  try {
    input = validatePlantRequest(
        await readJsonBody(request, PLANT_MAX_REQUEST_BYTES),
    );
  } catch (error) {
    if (error instanceof TypeError || error instanceof RangeError) {
      throw new HttpError(
          error instanceof RangeError ? 413 : 400,
          error instanceof RangeError ? "REQUEST_TOO_LARGE" : "INVALID_REQUEST",
      );
    }
    throw error;
  }
  assertGemini(env);
  let aiResult;
  try {
    const geminiResponse = await callGemini(env, PLANT_MODEL, {
      systemInstruction: {
        parts: [{text: PLANT_SYSTEM_INSTRUCTION}],
      },
      contents: [{
        role: "user",
        parts: [
          {text: PLANT_PROMPT},
          {
            inlineData: {mimeType: input.mimeType, data: input.imageBase64},
          },
        ],
      }],
      generationConfig: {
        responseMimeType: "application/json",
        responseSchema: PLANT_RESPONSE_SCHEMA,
        temperature: 0.2,
        maxOutputTokens: 4096,
      },
    });
    aiResult = await geminiResponse.json();
  } catch (error) {
    logAIDiagnostic("plant_identification", PLANT_MODEL, diagnosticCode(error));
    throw error;
  }
  const text = aiResult?.candidates?.[0]?.content?.parts
      ?.map((part) => part?.text || "").join("") || "";
  if (!text) throw new HttpError(502, "EMPTY_AI_RESPONSE");

  let result;
  try {
    const jsonText = text.trim()
        .replace(/^```(?:json)?\s*/i, "")
        .replace(/\s*```$/, "");
    result = JSON.parse(jsonText);
  } catch {
    throw new HttpError(502, "INVALID_AI_RESPONSE");
  }
  if (!result || typeof result !== "object" || Array.isArray(result) ||
      typeof result.plantName !== "string" ||
      result.plantName.trim().length === 0) {
    throw new HttpError(502, "INVALID_AI_RESPONSE");
  }

  // Safely normalize all fields while maintaining schema invariants
  const validOrganisms = ["plant", "fungus", "non-plant", "uncertain"];
  result.organismType = validOrganisms.includes(result.organismType)
      ? result.organismType
      : "uncertain";
  result.confidence = typeof result.confidence === "number" && Number.isFinite(result.confidence)
      ? Math.max(0, Math.min(1, result.confidence))
      : 0.0;
  result.identification = typeof result.identification === "string" && result.identification.trim().length > 0
      ? result.identification.trim()
      : "Botanical features identified by AI.";
  result.traditionalUses = typeof result.traditionalUses === "string" && result.traditionalUses.trim().length > 0
      ? result.traditionalUses.trim()
      : "Traditional uses are not documented for this identification.";
  result.scientificEvidence = typeof result.scientificEvidence === "string" && result.scientificEvidence.trim().length > 0
      ? result.scientificEvidence.trim()
      : "Scientific evidence is not verified for this identification.";
  result.safetySummary = typeof result.safetySummary === "string" && result.safetySummary.trim().length > 0
      ? result.safetySummary.trim()
      : "Do not consume or apply medicinally based solely on an automated scan.";
  result.precautions = Array.isArray(result.precautions)
      ? result.precautions.filter((p) => typeof p === "string" && p.trim().length > 0)
      : [];
  result.sanskritName = typeof result.sanskritName === "string" && result.sanskritName.trim().length > 0
      ? result.sanskritName.trim()
      : null;
  result.hindiName = typeof result.hindiName === "string" && result.hindiName.trim().length > 0
      ? result.hindiName.trim()
      : null;
  result.scientificName = typeof result.scientificName === "string" && result.scientificName.trim().length > 0
      ? result.scientificName.trim()
      : null;
  result.family = typeof result.family === "string" && result.family.trim().length > 0
      ? result.family.trim()
      : null;
  result.plantCategory = typeof result.plantCategory === "string" && result.plantCategory.trim().length > 0
      ? result.plantCategory.trim()
      : null;
  result.growingInformation = typeof result.growingInformation === "string" && result.growingInformation.trim().length > 0
      ? result.growingInformation.trim()
      : null;
  result.toxicityWarning = typeof result.toxicityWarning === "string" && result.toxicityWarning.trim().length > 0
      ? result.toxicityWarning.trim()
      : null;
  result.isToxic = typeof result.isToxic === "boolean" ? result.isToxic : false;
  const validMedicinal = ["medicinal", "non-medicinal", "unknown"];
  result.medicinalClassification = validMedicinal.includes(result.medicinalClassification)
      ? result.medicinalClassification
      : "unknown";

  const unidentified = result.organismType === "uncertain" ||
    result.plantName.trim().toLowerCase() === "unidentified botanical" ||
    result.confidence < 0.6;
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
    result.identification =
      "The image does not support a reliable plant identification.";
    result.traditionalUses =
      "Not provided because the plant could not be identified reliably.";
    result.scientificEvidence =
      "No plant-specific evidence can be provided without a reliable identification.";
    result.safetySummary =
      "Identification is uncertain. Do not consume or use this plant medicinally.";
    result.precautions = addPrecaution(
        result.precautions,
        "Do not consume or use this organism based on an uncertain image identification.",
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
        "Do not consume this fungus; image identification cannot establish safety.",
    );
    result.toxicityWarning = result.toxicityWarning ??
      "Toxicity has not been verified; do not touch or consume.";
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
        "Do not consume the subject based on an image.",
    );
    result.isToxic = false;
    result.toxicityWarning = "Toxicity was not assessed because no plant was identified.";
  } else {
    if (!/do not consume/i.test(result.safetySummary)) {
      result.safetySummary = `${result.safetySummary} Do not consume or use medicinally based solely on image identification.`;
    }
    result.precautions = addPrecaution(
        result.precautions,
        "Do not consume or use medicinally based solely on image identification.",
    );
    if (result.isToxic) {
      if (!/do not consume/i.test(result.toxicityWarning || "")) {
        result.toxicityWarning = result.toxicityWarning
          ? `${result.toxicityWarning} Do not consume or use medicinally.`
          : "Potential toxicity reported; do not consume or use medicinally.";
      }
    } else {
      result.toxicityWarning = result.toxicityWarning ??
        "Toxicity was not independently verified; do not consume.";
    }
  }
  return jsonResponse(result, 200, cors);
}

function addPrecaution(precautions, message) {
  return precautions.includes(message) ? precautions : [...precautions, message];
}

export default {
  async fetch(request, env) {
    const corsResult = requestCors(request, env);
    if (corsResult instanceof Response) return corsResult;
    const {headers: cors} = corsResult;
    if (request.method === "OPTIONS") return new Response(null, {status: 204, headers: cors});
    if (request.method !== "POST") {
      return jsonResponse({error: "METHOD_NOT_ALLOWED"}, 405, {
        ...cors,
        Allow: "POST, OPTIONS",
      });
    }

    const pathname = new URL(request.url).pathname.replace(/\/+$/, "");
    try {
      if (pathname === "/geminiChat") return await handleChat(request, env, cors);
      if (pathname === "/geminiPlant") return await handlePlant(request, env, cors);
      return jsonResponse({error: "NOT_FOUND"}, 404, cors);
    } catch (error) {
      const result = publicError(error);
      if (result.status >= 500) {
        console.error("Gemini request failed.", result.error);
      }
      return jsonResponse({error: result.error}, result.status, cors);
    }
  },
};
