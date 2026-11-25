import fs from "node:fs";

const toml = fs.readFileSync("C:/Users/dell/AppData/Roaming/xdg.config/.wrangler/config/default.toml", "utf8");
const match = toml.match(/oauth_token\s*=\s*"([^"]+)"/);
const token = match[1];

async function main() {
  const accountId = "ca994d48d49aaedc76500b3f281d3fc6";
  const scriptRes = await fetch(
    `https://api.cloudflare.com/client/v4/accounts/${accountId}/workers/scripts/jeevan-sutra-gemini-api`,
    {
      headers: { Authorization: `Bearer ${token}` },
    }
  );
  const scriptText = await scriptRes.text();
  
  // Find handleChat and handlePlant
  const idxChat = scriptText.indexOf("function handleChat");
  if (idxChat !== -1) {
    console.log("--- handleChat ---");
    console.log(scriptText.slice(idxChat, idxChat + 1200));
  }
  const idxPlant = scriptText.indexOf("function handlePlant");
  if (idxPlant !== -1) {
    console.log("--- handlePlant ---");
    console.log(scriptText.slice(idxPlant, idxPlant + 1200));
  }
}

main().catch(console.error);
