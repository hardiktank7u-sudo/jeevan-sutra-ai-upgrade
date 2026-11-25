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
  
  const idx = scriptText.indexOf("function diagnosticCode");
  if (idx !== -1) {
    console.log("--- diagnosticCode ---");
    console.log(scriptText.slice(idx, idx + 400));
  }
  const idx2 = scriptText.indexOf("function publicError");
  if (idx2 !== -1) {
    console.log("--- publicError ---");
    console.log(scriptText.slice(idx2, idx2 + 400));
  }
}

main().catch(console.error);
