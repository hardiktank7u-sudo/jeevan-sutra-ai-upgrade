export const CHAT_MODEL = "gemini-3.8-flash";
export const WORKERS_AI_CHAT_MODEL = "@cf/zai-org/glm-4.7-flash";
export const WORKERS_AI_PLANT_MODEL = "@cf/google/gemma-4-26b-a4b-it";
export const MAX_IMAGE_BYTES = 5 * 1024 * 1024;
export const MAX_BASE64_LENGTH = Math.ceil(MAX_IMAGE_BYTES / 3) * 4;
export const MAX_HISTORY_MESSAGES = 20;
export const MAX_MESSAGE_LENGTH = 4000;

export const SYSTEM_INSTRUCTION = `You are Jeevan Sutra AI, an educational guide to Indian Knowledge Systems, Ayurveda, wellness and medicinal plants.

Explain traditional knowledge alongside modern scientific understanding. You are not a doctor: never diagnose, prescribe medicines or doses, or advise stopping prescribed treatment. Recommend a qualified healthcare professional for serious or persistent symptoms. Clearly distinguish traditional knowledge from scientific evidence, mention plant safety concerns, and protect user privacy. Be warm, clear, concise, and use Markdown.`;

export const PLANT_PROMPT = `Analyze the supplied plant photograph and return only a JSON object with these fields:
plantName (common name, or "Unidentified Botanical"), sanskritName (string or null), hindiName (string or null), scientificName (string or null), confidence (number from 0 to 1), identification (visible characteristics), traditionalUses (clearly identified traditional uses), scientificEvidence (evidence without unsupported claims), safetySummary, precautions (string array), isToxic (boolean), and toxicityWarning (string or null).

Do not invent certainty. Never diagnose, prescribe, or claim a plant cures disease. If identification is unreliable, use "Unidentified Botanical" and low confidence.`;

export const PLANT_RESPONSE_SCHEMA = {
  type: "OBJECT",
  properties: {
    plantName: {type: "STRING"},
    sanskritName: {type: "STRING", nullable: true},
    hindiName: {type: "STRING", nullable: true},
    scientificName: {type: "STRING", nullable: true},
    confidence: {type: "NUMBER"},
    identification: {type: "STRING"},
    traditionalUses: {type: "STRING"},
    scientificEvidence: {type: "STRING"},
    safetySummary: {type: "STRING"},
    precautions: {type: "ARRAY", items: {type: "STRING"}},
    isToxic: {type: "BOOLEAN"},
    toxicityWarning: {type: "STRING", nullable: true},
  },
  required: [
    "plantName",
    "confidence",
    "identification",
    "traditionalUses",
    "scientificEvidence",
    "safetySummary",
    "precautions",
    "isToxic",
  ],
};

function decodeBase64(value) {
  return Uint8Array.from(atob(value), (character) => character.charCodeAt(0));
}

function hasSignature(bytes, signature) {
  return bytes.length >= signature.length &&
    signature.every((byte, index) => bytes[index] === byte);
}

function encodeBase64(bytes) {
  let binary = "";
  const chunkSize = 0x8000;
  for (let offset = 0; offset < bytes.length; offset += chunkSize) {
    binary += String.fromCharCode(...bytes.subarray(offset, offset + chunkSize));
  }
  return btoa(binary);
}

function isHeif(bytes) {
  if (bytes.length < 12 ||
      String.fromCharCode(...bytes.subarray(4, 8)) !== "ftyp") {
    return false;
  }
  return ["heic", "heix", "hevc", "hevx", "mif1", "msf1", "heif"].includes(
      String.fromCharCode(...bytes.subarray(8, 12)),
  );
}

export function validateChatRequest(body) {
  if (!body || typeof body !== "object" || Array.isArray(body)) {
    throw new TypeError("Request body must be an object.");
  }
  if (typeof body.prompt !== "string" ||
      body.prompt.trim().length === 0 ||
      body.prompt.length > MAX_MESSAGE_LENGTH) {
    throw new TypeError(`Prompt must contain 1-${MAX_MESSAGE_LENGTH} characters.`);
  }
  if (!Array.isArray(body.history) ||
      body.history.length > MAX_HISTORY_MESSAGES) {
    throw new TypeError(`History must contain at most ${MAX_HISTORY_MESSAGES} messages.`);
  }

  const history = body.history.map((message) => {
    if (!message || typeof message !== "object" ||
        !["user", "model"].includes(message.role) ||
        typeof message.text !== "string" ||
        message.text.trim().length === 0 ||
        message.text.length > MAX_MESSAGE_LENGTH) {
      throw new TypeError("Each history message must have a valid role and text.");
    }
    return {
      role: message.role,
      parts: [{text: message.text.trim()}],
    };
  });

  while (history.length > 0 && history[0].role !== "user") {
    history.shift();
  }
  return {prompt: body.prompt.trim(), history};
}

export function validatePlantRequest(body) {
  const supportedTypes = [
    "image/jpeg",
    "image/png",
    "image/webp",
    "image/heic",
    "image/heif",
  ];
  if (!body || typeof body !== "object" || Array.isArray(body)) {
    throw new TypeError("Request body must be an object.");
  }
  if (typeof body.mimeType !== "string" ||
      !supportedTypes.includes(body.mimeType)) {
    throw new TypeError("Image must be JPEG, PNG, WebP, HEIC, or HEIF.");
  }
  if (typeof body.imageBase64 !== "string" ||
      body.imageBase64.length === 0 ||
      body.imageBase64.length > MAX_BASE64_LENGTH ||
      !/^[A-Za-z0-9+/]*={0,2}$/.test(body.imageBase64)) {
    throw new TypeError("Image data is missing or invalid.");
  }

  const image = decodeBase64(body.imageBase64);
  if (image.length === 0 || image.length > MAX_IMAGE_BYTES) {
    throw new RangeError("Image must not exceed 5 MiB.");
  }
  if (encodeBase64(image) !== body.imageBase64) {
    throw new TypeError("Image data is missing or invalid.");
  }

  const isJpeg = hasSignature(image, [0xff, 0xd8, 0xff]);
  const isPng = hasSignature(
      image,
      [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],
  );
  const isWebp = image.length >= 12 &&
    String.fromCharCode(...image.subarray(0, 4)) === "RIFF" &&
    String.fromCharCode(...image.subarray(8, 12)) === "WEBP";
  const isValidImage = {
    "image/jpeg": isJpeg,
    "image/png": isPng,
    "image/webp": isWebp,
    "image/heic": isHeif(image),
    "image/heif": isHeif(image),
  }[body.mimeType];
  if (!isValidImage) {
    throw new TypeError("Image bytes do not match the declared format.");
  }
  return {mimeType: body.mimeType, imageBase64: body.imageBase64};
}
