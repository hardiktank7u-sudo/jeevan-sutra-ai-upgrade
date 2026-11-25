import fs from "node:fs/promises";
import path from "node:path";
import {StringDecoder} from "node:string_decoder";

const baseUrl = process.env.WORKER_BASE_URL;
const appCheckToken = process.env.FIREBASE_APP_CHECK_TOKEN;
const imagePath = process.env.PLANT_IMAGE_PATH;

if (!baseUrl || !appCheckToken || !imagePath) {
  console.error(
      "Set WORKER_BASE_URL, FIREBASE_APP_CHECK_TOKEN, and PLANT_IMAGE_PATH to run live endpoint checks.",
  );
  process.exitCode = 2;
} else {
  const headers = {
    "Content-Type": "application/json",
    "X-Firebase-AppCheck": appCheckToken,
  };

  async function checkChat() {
    const response = await fetch(new URL("/geminiChat", baseUrl), {
      method: "POST",
      headers,
      body: JSON.stringify({
        prompt: "Reply in one sentence: what is Tulsi traditionally known as?",
        history: [],
      }),
    });
    if (!response.ok || !response.headers.get("content-type")?.includes("text/event-stream")) {
      throw new Error(`Chat endpoint returned HTTP ${response.status}.`);
    }

    let text = "";
    let pending = "";
    let eventCount = 0;
    let doneReceived = false;
    const decoder = new StringDecoder("utf8");
    for await (const chunk of response.body) {
      pending += decoder.write(chunk);
      let newline;
      while ((newline = pending.indexOf("\n")) !== -1) {
        const line = pending.slice(0, newline).replace(/\r$/, "");
        pending = pending.slice(newline + 1);
        if (!line.startsWith("data: ")) continue;
        const data = line.slice(6);
        if (data === "[DONE]") {
          doneReceived = true;
          continue;
        }
        const event = JSON.parse(data);
        if (event.error) throw new Error(`Chat endpoint returned ${event.error}.`);
        eventCount += 1;
        text += event.text || "";
      }
    }
    pending += decoder.end();
    if (pending.startsWith("data: ")) {
      const data = pending.slice(6).trim();
      if (data === "[DONE]") {
        doneReceived = true;
      } else {
        const event = JSON.parse(data);
        if (event.error) throw new Error(`Chat endpoint returned ${event.error}.`);
        eventCount += 1;
        text += event.text || "";
      }
    }
    if (!text.trim() || eventCount === 0 || !doneReceived) {
      throw new Error("Chat endpoint returned an incomplete generated stream.");
    }
    console.log(`Live chat streaming PASS (${text.length} response characters).`);
    return text;
  }

  async function checkPlant() {
    const imageBytes = await fs.readFile(path.resolve(imagePath));
    const imageTypes = {
      ".jpg": "image/jpeg",
      ".jpeg": "image/jpeg",
      ".png": "image/png",
      ".webp": "image/webp",
      ".heic": "image/heic",
      ".heif": "image/heif",
    };
    const mimeType = imageTypes[path.extname(imagePath).toLowerCase()];
    if (!mimeType) throw new Error("Plant image must use a supported image format.");
    const response = await fetch(new URL("/geminiPlant", baseUrl), {
      method: "POST",
      headers,
      body: JSON.stringify({
        mimeType,
        imageBase64: imageBytes.toString("base64"),
      }),
    });
    const result = await response.json();
    const optionalString = (value) => value == null || typeof value === "string";
    if (!response.ok ||
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
        typeof result.isToxic !== "boolean" ||
        !optionalString(result.sanskritName) ||
        !optionalString(result.hindiName) ||
        !optionalString(result.scientificName) ||
        !optionalString(result.toxicityWarning)) {
      throw new Error(`Plant endpoint returned HTTP ${response.status}.`);
    }
    console.log(`Live plant analysis PASS (${result.plantName}; confidence ${result.confidence}).`);
  }

  Promise.resolve()
      .then(checkChat)
      .then(checkPlant)
      .catch((error) => {
        console.error(`Live Workers AI endpoint check failed: ${error.message}`);
        process.exitCode = 1;
      });
}
