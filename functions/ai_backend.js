export const GEMINI_MODEL = "gemini-3.8-flash";
export const CHAT_MODEL = GEMINI_MODEL;
export const PLANT_MODEL = GEMINI_MODEL;
export const MAX_IMAGE_BYTES = 5 * 1024 * 1024;
export const MAX_BASE64_LENGTH = Math.ceil(MAX_IMAGE_BYTES / 3) * 4;
export const MAX_HISTORY_MESSAGES = 20;
export const MAX_MESSAGE_LENGTH = 4000;

export const SYSTEM_INSTRUCTION = `You are Jeevan Sutra AI, an educational guide to Indian Knowledge Systems, Ayurveda, wellness and medicinal plants.

Explain traditional knowledge alongside modern scientific understanding. You are not a doctor: never diagnose, prescribe medicines or doses, or advise stopping prescribed treatment. Recommend a qualified healthcare professional for serious or persistent symptoms. Clearly distinguish traditional knowledge from scientific evidence, mention plant safety concerns, and protect user privacy. Be warm, clear, concise, and use Markdown.`;

export const PLANT_SYSTEM_INSTRUCTION = `You are a careful visual identification assistant for plants and other organisms.

Identify any plant that can be supported by visible evidence, including trees, flowers, herbs, shrubs, grasses, crops, succulents, cacti, and indoor or outdoor plants. Do not use a fixed species list or guess from location or commonness. Distinguish plants from fungi and other non-plants. Use organismType "fungus" for fungi, "non-plant" for clearly non-plant objects or animals, "uncertain" when the image does not support a reliable classification, and "plant" only for plants.

Never invent a common, scientific, family, Hindi, or Sanskrit name, traditional use, toxicity claim, or scientific evidence. Return null for names or family that cannot be verified confidently. State that uses or evidence are not established when you cannot support them. A photograph alone does not establish safety, edibility, or medicinal value. Never recommend consuming or medicinally using an image-identified organism. If toxicity is known or suspected, clearly warn against contact or consumption and state the uncertainty.`;

export const PLANT_PROMPT = `Analyze the supplied image. Return only a JSON object containing every field in the schema:
organismType ("plant", "fungus", "non-plant", or "uncertain"), plantName (a common name for an identified plant, "Fungus detected (not a plant)" for fungi, "No plant detected" for a clearly non-plant image, or "Unidentified Botanical" when uncertain), scientificName (string or null), family (string or null), hindiName (string or null), sanskritName (string or null), plantCategory (a broad botanical category or null), medicinalClassification ("medicinal", "non-medicinal", or "unknown"), growingInformation (reliable care or habitat information, or null), confidence (number from 0 to 1), identification (a concise description and visible characteristics), traditionalUses, scientificEvidence, safetySummary, precautions (string array), isToxic (boolean), and toxicityWarning (string or null).

Use confidence below 0.6 when identification or plant/non-plant classification is uncertain. Use medicinalClassification "unknown" unless an established medicinal classification can be supported. Do not equate traditional use with proven benefit. Leave growingInformation null unless reliable information is known. For fungi, non-plants, and uncertain images, do not provide plant-specific category, uses, evidence, or growing information; use medicinalClassification "unknown". Never infer taxonomy or traditional use from appearance alone. Keep traditional uses distinct from scientific evidence; do not invent citations or claims. Always caution that image identification is not a basis for consuming or medicinally using an organism.`;

export const PLANT_RESPONSE_SCHEMA = {
  type: "OBJECT",
  properties: {
    organismType: {
      type: "STRING",
      enum: ["plant", "fungus", "non-plant", "uncertain"],
    },
    plantName: {type: "STRING"},
    sanskritName: {type: "STRING", nullable: true},
    hindiName: {type: "STRING", nullable: true},
    scientificName: {type: "STRING", nullable: true},
    family: {type: "STRING", nullable: true},
    plantCategory: {type: "STRING", nullable: true},
    medicinalClassification: {
      type: "STRING",
      enum: ["medicinal", "non-medicinal", "unknown"],
    },
    growingInformation: {type: "STRING", nullable: true},
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
    "toxicityWarning",
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
      !/^[A-Za-z0-9+/]*={0,2}$/.test(body.imageBase64)) {
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
