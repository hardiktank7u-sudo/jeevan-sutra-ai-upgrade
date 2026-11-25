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
  await fs.promises.writeFile("F:/Development/jeevan_sutra/functions/scripts/deployed-worker.js", scriptText);
  console.log("Saved deployed-worker.js! Length:", scriptText.length);
}

main().catch(console.error);
