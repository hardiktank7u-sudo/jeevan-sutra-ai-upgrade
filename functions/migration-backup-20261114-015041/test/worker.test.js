import test from "node:test";
import assert from "node:assert/strict";

import worker from "../index.js";

const env = {
  FIREBASE_PROJECT_NUMBER: "311459879132",
  FIREBASE_APP_IDS: "1:311459879132:android:fd34669cd00b4c6cb6fc19",
  AI_RATE_LIMITER: {limit: async () => ({success: true})},
};

test("Worker rejects requests without Firebase App Check", async () => {
  const response = await worker.fetch(new Request(
      "https://example.workers.dev/geminiChat",
      {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({prompt: "hello", history: []}),
      },
  ), env);

  assert.equal(response.status, 401);
  assert.deepEqual(await response.json(), {error: "APP_CHECK_REJECTED"});
});

test("Worker keeps CORS preflight available without a client token", async () => {
  const response = await worker.fetch(new Request(
      "https://example.workers.dev/geminiPlant",
      {
        method: "OPTIONS",
        headers: {
          Origin: "https://jeevan-b390e.web.app",
          "Access-Control-Request-Method": "POST",
        },
      },
  ), env);

  assert.equal(response.status, 204);
  assert.equal(
      response.headers.get("Access-Control-Allow-Origin"),
      "https://jeevan-b390e.web.app",
  );
});
