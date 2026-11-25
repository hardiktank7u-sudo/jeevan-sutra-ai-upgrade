import fs from "node:fs";

const indexPath = "index.js";
const backendPath = "ai_backend.js";

function replaceBetween(source, startMarker, endMarker, replacement) {
  const start = source.indexOf(startMarker);
  const end = source.indexOf(endMarker, start);
  if (start < 0 || end < 0) {
    throw new Error("Could not locate code section: " + startMarker);
  }
  return source.slice(0, start) + replacement + "\n" + source.slice(end);
}

let index = fs.readFileSync(indexPath, "utf8").replace(/\r\n/g, "\n");
let backend = fs.readFileSync(backendPath, "utf8").replace(/\r\n/g, "\n");

const oldImport = `import {
  CHAT_MODEL,
  PLANT_PROMPT,
  PLANT_RESPONSE_SCHEMA,
  SYSTEM_INSTRUCTION,
  validateChatRequest,
  validatePlantRequest,
} from "./ai_backend.js";`;

const newImport = `import {
  CHAT_MODEL,
  PLANT_MODEL,
  PLANT_PROMPT,
  SYSTEM_INSTRUCTION,
  validateChatRequest,
  validatePlantRequest,
} from "./ai_backend.js";`;

if (!index.includes(oldImport)) throw new Error("Unexpected index.js imports.");
if (!backend.includes('export const CHAT_MODEL = "gemini-3.8-flash";')) {
  throw new Error("Unexpected ai_backend.js model configuration.");
}

backend = backend.replace(
  'export const CHAT_MODEL = "gemini-3.8-flash";',
  'export const CHAT_MODEL = "@cf/zai-org/glm-4.7-flash";\nexport const PLANT_MODEL = "@cf/google/gemma-4-26b-a4b-it";'
);

index = index.replace(oldImport, newImport);
index = index.replace('const GEMINI_API_BASE_URL = "https://generativelanguage.googleapis.com/v1beta";\n', "");

index = replaceBetween(
  index,
  "async function logGeminiError",
  "function publicError",
  ""
);

const helpers = `
function assertAI(env) {
  if (!env.AI || typeof env.AI.run !== "function") {
    throw new HttpError(503, "AI_NOT_CONFIGURED");
  }
}

function extractAIText(result) {
  const content = result?.choices?.[0]?.message?.content;
  if (typeof content === "string") return content;
  if (Array.isArray(content)) {
    return content.map((part) => part?.text || "").join("");
  }
  if (typeof result?.response === "string") return result.response;
  return "";
}

function transformWorkersAIStream(source) {
  const decoder = new TextDecoder();
  const encoder = new TextEncoder();
  let pending = "";
  let sentDone = false;

  function emitLine(line, controller) {
    if (!line.startsWith("data:")) return;
    const data = line.slice(5).trim();
    if (!data) return;

    if (data === "[DONE]") {
      if (!sentDone) {
        controller.enqueue(encoder.encode("data: [DONE]\\\n\\\n"));
        sentDone = true;
      }
      return;
    }

    let event;
    try {
      event = JSON.parse(data);
    } catch {
      return;
    }

    if (event?.error) {
      controller.enqueue(encoder.encode(
        "event: error\\\ndata: " +
        JSON.stringify({error: "AI_UPSTREAM_UNAVAILABLE"}) + "\\\n\\\n"
      ));
      return;
    }

    const raw = event.choices?.[0]?.delta?.content ??
      event.choices?.[0]?.message?.content ??
      event.response ?? "";

    const text = typeof raw === "string"
      ? raw
      : Array.isArray(raw)
        ? raw.map((part) => part?.text || "").join("")
        : "";

    if (text) {
      controller.enqueue(encoder.encode(
        "data: " + JSON.stringify({text}) + "\\\n\\\n"
      ));
    }
  }

  return source.pipeThrough(new TransformStream({
    transform(chunk, controller) {
      pending += decoder.decode(chunk, {stream: true});
      let newline;
      while ((newline = pending.indexOf("\\\n")) !== -1) {
        const line = pending.slice(0, newline).replace(/\\\r$/, "");
        pending = pending.slice(newline + 1);
        emitLine(line, controller);
      }
    },
    flush(controller) {
      pending += decoder.decode();
      if (pending.trim()) emitLine(pending.replace(/\\\r$/, ""), controller);
      if (!sentDone) {
        controller.enqueue(encoder.encode("data: [DONE]\\\n\\\n"));
      }
    },
  }));
}
`;

index = replaceBetween(
  index,
  "function geminiHeaders",
  "async function handleChat",
  helpers
);

const chatHandler = `
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

  assertAI(env);

  const messages = [
    {role: "system", content: SYSTEM_INSTRUCTION},
    ...input.history.map((message) => ({
      role: message.role === "model" ? "assistant" : "user",
      content: message.parts.map((part) => part.text || "").join(""),
    })),
    {role: "user", content: input.prompt},
  ];

  const aiStream = await env.AI.run(CHAT_MODEL, {
    messages,
    stream: true,
    temperature: 0.7,
    max_tokens: 1200,
  });

  if (!aiStream || typeof aiStream.pipeThrough !== "function") {
    throw new HttpError(502, "EMPTY_AI_RESPONSE");
  }

  return new Response(transformWorkersAIStream(aiStream), {
    status: 200,
    headers: {
      ...cors,
      "Cache-Control": "no-cache, no-transform",
      "Content-Type": "text/event-stream; charset=utf-8",
    },
  });
}
`;

index = replaceBetween(
  index,
  "async function handleChat",
  "async function handlePlant",
  chatHandler
);

const plantHandler = `
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

  assertAI(env);

  const imageDataUri =
    "data:" + input.mimeType + ";base64," + input.imageBase64;

  const aiResult = await env.AI.run(PLANT_MODEL, {
    messages: [
      {
        role: "system",
        content: "You are a careful botanical identification assistant. Return only valid JSON matching the requested fields. Never invent certainty or medical claims.",
      },
      {
        role: "user",
        content: [
          {type: "text", text: PLANT_PROMPT},
          {
            type: "image_url",
            image_url: {url: imageDataUri},
          },
        ],
      },
    ],
    temperature: 0.2,
    max_tokens: 1200,
  });

  const text = extractAIText(aiResult);
  if (!text) throw new HttpError(502, "EMPTY_AI_RESPONSE");

  let result;
  try {
    const clean = text.trim()
      .replace(/^\\x60\\x60\\x60(?:json)?\\\s*/i, "")
      .replace(/\\\s*\\x60\\x60\\x60$/, "");
    result = JSON.parse(clean);
  } catch {
    throw new HttpError(502, "INVALID_AI_RESPONSE");
  }

  if (
    typeof result.plantName !== "string" ||
    typeof result.confidence !== "number" ||
    !Number.isFinite(result.confidence) ||
    result.confidence < 0 ||
    result.confidence > 1 ||
    typeof result.identification !== "string" ||
    typeof result.traditionalUses !== "string" ||
    typeof result.scientificEvidence !== "string" ||
    typeof result.safetySummary !== "string" ||
    !Array.isArray(result.precautions) ||
    typeof result.isToxic !== "boolean"
  ) {
    throw new HttpError(502, "INVALID_AI_RESPONSE");
  }

  return jsonResponse(result, 200, cors);
}
`;

index = replaceBetween(
  index,
  "async function handlePlant",
  "export default",
  plantHandler
);

index = index.replace(
  'console.error("Gemini Worker request failed.", result.error);',
  'console.error("Workers AI request failed.", result.error);'
);

if (index.includes("GEMINI_API_BASE_URL") ||
    index.includes("assertApiKey") ||
    index.includes("geminiHeaders")) {
  throw new Error("Old Gemini backend references remain. No files written.");
}

const stamp = new Date().toISOString().replace(/[:.]/g, "-");
fs.copyFileSync(indexPath, indexPath + ".backup-" + stamp);
fs.copyFileSync(backendPath, backendPath + ".backup-" + stamp);

fs.writeFileSync(indexPath, index);
fs.writeFileSync(backendPath, backend);

console.log("Workers AI migration written.");
console.log("Backups created for both backend files.");
console.log("Chat model: " + "@cf/zai-org/glm-4.7-flash");
console.log("Plant model: " + "@cf/google/gemma-4-26b-a4b-it");

