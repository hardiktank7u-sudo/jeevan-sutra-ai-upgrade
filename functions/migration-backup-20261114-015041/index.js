import {
  CHAT_MODEL,
  PLANT_PROMPT,
  PLANT_RESPONSE_SCHEMA,
  SYSTEM_INSTRUCTION,
  validateChatRequest,
  validatePlantRequest,
} from "./ai_backend.js";
import {verifyAppCheckToken} from "./app_check.js";

const CHAT_MAX_REQUEST_BYTES = 64 * 1024;
const PLANT_MAX_REQUEST_BYTES = 7 * 1024 * 1024;
const GEMINI_API_BASE_URL = "https://generativelanguage.googleapis.com/v1beta";
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

async function logGeminiError(operation, response) {
  let details = {};

  try {
    const body = await response.clone().json();
    details = {
      status: body?.error?.status || "UNKNOWN",
      message: String(body?.error?.message || "No error message").slice(0, 300),
    };
  } catch {
    details = {message: "Could not parse Gemini error response."};
  }

  console.error("Gemini upstream diagnostic:", {
    operation,
    httpStatus: response.status,
    ...details,
  });
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

function geminiHeaders(apiKey) {
  return {
    "Content-Type": "application/json",
    "x-goog-api-key": apiKey,
  };
}

function assertApiKey(env) {
  if (!env.GEMINI_API_KEY) throw new HttpError(503, "AI_NOT_CONFIGURED");
}

async function* parseServerSentEvents(stream) {
  const reader = stream.getReader();
  const decoder = new TextDecoder();
  let pending = "";
  try {
    while (true) {
      const {done, value} = await reader.read();
      pending += decoder.decode(value, {stream: !done});
      let newline;
      while ((newline = pending.indexOf("\n")) !== -1) {
        const line = pending.slice(0, newline).replace(/\r$/, "");
        pending = pending.slice(newline + 1);
        if (line.startsWith("data:")) yield line.slice(5).trim();
      }
      if (done) break;
    }
    if (pending.startsWith("data:")) yield pending.slice(5).trim();
  } finally {
    reader.releaseLock();
  }
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
  assertApiKey(env);

  const abortController = new AbortController();
  const upstream = await fetch(
      `${GEMINI_API_BASE_URL}/models/${CHAT_MODEL}:streamGenerateContent?alt=sse`,
      {
        method: "POST",
        headers: geminiHeaders(env.GEMINI_API_KEY),
        signal: abortController.signal,
        body: JSON.stringify({
          systemInstruction: {parts: [{text: SYSTEM_INSTRUCTION}]},
          contents: [
            ...input.history,
            {role: "user", parts: [{text: input.prompt}]},
          ],
          generationConfig: {temperature: 0.7, maxOutputTokens: 1200},
        }),
      },
  );
  if (!upstream.ok || !upstream.body) {
    await logGeminiError("geminiChat", upstream);
    throw {status: upstream.status};
  }

  let cancelled = false;
  const stream = new ReadableStream({
    start(controller) {
      (async () => {
        try {
          for await (const event of parseServerSentEvents(upstream.body)) {
            if (cancelled) return;
            if (!event || event === "[DONE]") continue;
            const result = JSON.parse(event);
            if (result.error) {
              const error = publicError({status: result.error.code});
              controller.enqueue(
                  new TextEncoder().encode(
                      `event: error\ndata: ${JSON.stringify({error: error.error})}\n\n`,
                  ),
              );
              if (cancelled) return;
              controller.close();
              return;
            }
            const text = result.candidates?.[0]?.content?.parts
                ?.map((part) => part.text || "")
                .join("") || "";
            if (text) {
              controller.enqueue(
                  new TextEncoder().encode(`data: ${JSON.stringify({text})}\n\n`),
              );
            }
          }
          if (cancelled) return;
          controller.enqueue(new TextEncoder().encode("data: [DONE]\n\n"));
          controller.close();
        } catch (error) {
          if (cancelled) return;
          console.error("Gemini chat stream failed.", error?.name || "UNKNOWN");
          controller.enqueue(
              new TextEncoder().encode(
                  `event: error\ndata: ${JSON.stringify({error: "AI_UPSTREAM_UNAVAILABLE"})}\n\n`,
              ),
          );
          controller.close();
        }
      })();
    },
    cancel() {
      cancelled = true;
      abortController.abort();
    },
  });
  return new Response(stream, {
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
  assertApiKey(env);

  const upstream = await fetch(
      `${GEMINI_API_BASE_URL}/models/${CHAT_MODEL}:generateContent`,
      {
        method: "POST",
        headers: geminiHeaders(env.GEMINI_API_KEY),
        body: JSON.stringify({
          contents: [{
            role: "user",
            parts: [
              {text: PLANT_PROMPT},
              {
                inlineData: {
                  mimeType: input.mimeType,
                  data: input.imageBase64,
                },
              },
            ],
          }],
          generationConfig: {
            responseMimeType: "application/json",
            responseSchema: PLANT_RESPONSE_SCHEMA,
            temperature: 0.2,
            maxOutputTokens: 1200,
          },
        }),
      },
  );
  if (!upstream.ok) {
    await logGeminiError("geminiPlant", upstream);
    throw {status: upstream.status};
  }

  const response = await upstream.json();
  const text = response.candidates?.[0]?.content?.parts
      ?.map((part) => part.text || "")
      .join("");
  if (!text) throw new HttpError(502, "EMPTY_AI_RESPONSE");

  let result;
  try {
    result = JSON.parse(text);
  } catch {
    throw new HttpError(502, "INVALID_AI_RESPONSE");
  }
  if (typeof result.plantName !== "string" ||
      typeof result.confidence !== "number" ||
      !Number.isFinite(result.confidence) ||
      result.confidence < 0 ||
      result.confidence > 1 ||
      typeof result.identification !== "string" ||
      typeof result.traditionalUses !== "string" ||
      typeof result.scientificEvidence !== "string" ||
      typeof result.safetySummary !== "string" ||
      !Array.isArray(result.precautions) ||
      typeof result.isToxic !== "boolean") {
    throw new HttpError(502, "INVALID_AI_RESPONSE");
  }
  return jsonResponse(result, 200, cors);
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
        console.error("Gemini Worker request failed.", result.error);
      }
      return jsonResponse({error: result.error}, result.status, cors);
    }
  },
};
