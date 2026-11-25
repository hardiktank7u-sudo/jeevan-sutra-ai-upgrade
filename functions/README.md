# Jeevan Sutra Gemini backend

The Cloudflare Worker exposes `POST /geminiChat` (SSE) and `POST /geminiPlant` (structured JSON). Both routes verify Firebase App Check, apply the existing Cloudflare rate limiter, and call the Google Gemini Developer API using the `gemini-3.8-flash` model. The Gemini API key is read only from the Worker secret `GEMINI_API_KEY`; it is never included in Flutter source or the APK.

## Configure the secret

From `F:\\Development\\jeevan_sutra\\functions` in PowerShell, after an authorized adult has created/approved the Google AI API key:

```powershell
npx.cmd wrangler secret put GEMINI_API_KEY
```

Paste the key only into Wrangler's secure prompt. Do not put it in `wrangler.toml`, source files, screenshots, or this chat.

## Test and deploy

```powershell
npm.cmd test
npx.cmd wrangler deploy --dry-run
```

Review the dry-run output. Deploy only after explicit approval:

```powershell
npx.cmd wrangler deploy
```

Keep the existing Cloudflare Free plan and do not enable paid overages. The existing Firebase project number, app allowlist, CORS allowlist, and 20-requests-per-minute rate limiter are retained.

The plant endpoint is not limited to a curated species list. Its response
includes the existing identification, safety, and evidence fields plus `family`
and `organismType`. It distinguishes plants, fungi, non-plants, and uncertain
images; uncertain results abstain, and image identification is never a basis
for consuming or medicinally using an organism.

## Flutter build

The app uses the deployed Worker URL and Firebase App Check:

```powershell
flutter build apk --release --dart-define=GEMINI_BACKEND_BASE_URL=https://jeevan-sutra-gemini-api.jeevan-sutra-ai.workers.dev
```

This command only builds locally. It does not deploy the Worker.

## Notes

Automated tests mock the Google API and do not consume Gemini API quota. Live inference must be tested separately after the secret is configured and the Worker is deployed. Plant identification is educational only; uncertain results must abstain and must not be used as medical advice.
