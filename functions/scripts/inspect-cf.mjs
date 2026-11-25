import fs from "node:fs";

const toml = fs.readFileSync("C:/Users/dell/AppData/Roaming/xdg.config/.wrangler/config/default.toml", "utf8");
const match = toml.match(/oauth_token\s*=\s*"([^"]+)"/);
if (!match) {
  console.error("No oauth_token");
  process.exit(1);
}
const token = match[1];

async function main() {
  const accRes = await fetch("https://api.cloudflare.com/client/v4/accounts", {
    headers: { Authorization: `Bearer ${token}` },
  });
  const accData = await accRes.json();
  if (!accData.result || !accData.result[0]) {
    console.error("Accounts error:", accData);
    return;
  }
  const accountId = accData.result[0].id;
  console.log("Account ID:", accountId);

  // Get script for jeevan-sutra-gemini-api
  const scriptRes = await fetch(
    `https://api.cloudflare.com/client/v4/accounts/${accountId}/workers/scripts/jeevan-sutra-gemini-api`,
    {
      headers: { Authorization: `Bearer ${token}` },
    }
  );
  console.log("Script HTTP status:", scriptRes.status);
  const scriptText = await scriptRes.text();
  console.log("Script text length:", scriptText.length);
  
  // Search for inline_data vs inlineData
  const hasSnakeCase = scriptText.includes("inline_data");
  const hasCamelCase = scriptText.includes("inlineData");
  console.log("Deployed script has inline_data:", hasSnakeCase);
  console.log("Deployed script has inlineData:", hasCamelCase);

  // Search for maxOutputTokens
  const tokenMatch = scriptText.match(/maxOutputTokens[^\d]*(\d+)/);
  console.log("Deployed script maxOutputTokens:", tokenMatch ? tokenMatch[1] : "not found");

  // Search for upstream error logging
  const hasUpstreamLog = scriptText.includes("Gemini upstream failed");
  console.log("Deployed script has 'Gemini upstream failed' log:", hasUpstreamLog);
}

main().catch(console.error);
