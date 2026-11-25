import fs from "node:fs/promises";

async function main() {
  const firebaseKey = "AIzaSyB859NQM-cSs3X9jJmOluy_2556aI0a_WA";
  const debugToken = "6053158d-2c84-4803-a004-cdb32eaec9f1";
  const appId = "1:311459879132:android:fd34669cd00b4c6cb6fc19";
  
  console.log("1. Exchanging debug token for App Check JWT...");
  const exchangeRes = await fetch(
    `https://firebaseappcheck.googleapis.com/v1/projects/311459879132/apps/${appId}:exchangeDebugToken?key=${firebaseKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ debugToken }),
    }
  );
  const exchangeData = await exchangeRes.json();
  if (!exchangeData.token) {
    console.error("Failed to get App Check token:", exchangeData);
    return;
  }
  const appCheckJwt = exchangeData.token;
  console.log("App Check JWT obtained! Length:", appCheckJwt.length);

  const targets = [
    { name: "Local Wrangler (http://127.0.0.1:8787)", url: "http://127.0.0.1:8787" },
    { name: "Deployed Worker (https://jeevan-sutra-gemini-api.jeevan-sutra-ai.workers.dev)", url: "https://jeevan-sutra-gemini-api.jeevan-sutra-ai.workers.dev" },
  ];

  for (const target of targets) {
    console.log(`\n======================================================`);
    console.log(`Testing Target: ${target.name}`);
    console.log(`======================================================`);

    // Test 1: Chat
    console.log(`--- Testing ${target.name}/geminiChat ---`);
    try {
      const chatRes = await fetch(`${target.url}/geminiChat`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Firebase-AppCheck": appCheckJwt,
        },
        body: JSON.stringify({
          prompt: "Say 'Namaste Tulsi' in 3 words.",
          history: [],
        }),
      });
      console.log(`Chat HTTP Status: ${chatRes.status}`);
      const chatBody = await chatRes.text();
      console.log(`Chat Response:\n${chatBody.slice(0, 500)}`);
    } catch (e) {
      console.error("Chat error:", e.message);
    }

    // Test 2: Plant
    console.log(`\n--- Testing ${target.name}/geminiPlant ---`);
    try {
      const imageBytes = await fs.readFile("F:/Development/jeevan_sutra/assets/branding/test_plant.jpg");
      const plantRes = await fetch(`${target.url}/geminiPlant`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Firebase-AppCheck": appCheckJwt,
        },
        body: JSON.stringify({
          mimeType: "image/jpeg",
          imageBase64: imageBytes.toString("base64"),
        }),
      });
      console.log(`Plant HTTP Status: ${plantRes.status}`);
      const plantBody = await plantRes.text();
      console.log(`Plant Response:\n${plantBody.slice(0, 1000)}`);
    } catch (e) {
      console.error("Plant error:", e.message);
    }
  }
}

main();
