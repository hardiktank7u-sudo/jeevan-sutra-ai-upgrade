import test from "node:test";
import assert from "node:assert/strict";

import {verifyAppCheckToken} from "../app_check.js";

const PROJECT_NUMBER = "311459879132";
const APP_ID = "1:311459879132:android:fd34669cd00b4c6cb6fc19";

function base64Url(bytes) {
  return Buffer.from(bytes).toString("base64url");
}

test("verifies App Check JWT signature, issuer, audience, expiry, and app ID", async () => {
  const {privateKey, publicKey} = await crypto.subtle.generateKey(
      {
        name: "RSASSA-PKCS1-v1_5",
        modulusLength: 2048,
        publicExponent: new Uint8Array([1, 0, 1]),
        hash: "SHA-256",
      },
      true,
      ["sign", "verify"],
  );
  const jwk = await crypto.subtle.exportKey("jwk", publicKey);
  jwk.kid = "test-key";
  jwk.alg = "RS256";

  const nowSeconds = Math.floor(Date.now() / 1000);
  const header = base64Url(JSON.stringify({alg: "RS256", kid: jwk.kid, typ: "JWT"}));
  const payload = base64Url(JSON.stringify({
    aud: [`projects/${PROJECT_NUMBER}`],
    exp: nowSeconds + 300,
    iat: nowSeconds,
    iss: `https://firebaseappcheck.googleapis.com/${PROJECT_NUMBER}`,
    sub: APP_ID,
  }));
  const unsignedToken = `${header}.${payload}`;
  const signature = await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5",
      privateKey,
      new TextEncoder().encode(unsignedToken),
  );
  const token = `${unsignedToken}.${base64Url(signature)}`;
  const fetcher = async () => new Response(JSON.stringify({keys: [jwk]}), {
    headers: {"Cache-Control": "public, max-age=3600"},
  });
  const options = {
    projectNumber: PROJECT_NUMBER,
    allowedAppIds: [APP_ID],
    fetcher,
  };

  const claims = await verifyAppCheckToken(token, options);
  assert.equal(claims.sub, APP_ID);

  const tampered = `${header}.${base64Url(JSON.stringify({
    aud: ["projects/wrong-project"],
    exp: nowSeconds + 300,
    iat: nowSeconds,
    iss: `https://firebaseappcheck.googleapis.com/${PROJECT_NUMBER}`,
    sub: APP_ID,
  }))}.${base64Url(signature)}`;
  assert.equal(await verifyAppCheckToken(tampered, options), null);
});

test("rejects malformed, expired, and untrusted app tokens", async () => {
  assert.equal(await verifyAppCheckToken("not-a-token", {
    projectNumber: PROJECT_NUMBER,
    allowedAppIds: [APP_ID],
  }), null);

  const header = base64Url(JSON.stringify({alg: "none", kid: "bad"}));
  const nowSeconds = Math.floor(Date.now() / 1000);
  const payload = base64Url(JSON.stringify({
    aud: [`projects/${PROJECT_NUMBER}`],
    exp: nowSeconds - 1,
    iat: nowSeconds - 300,
    iss: `https://firebaseappcheck.googleapis.com/${PROJECT_NUMBER}`,
    sub: APP_ID,
  }));
  assert.equal(await verifyAppCheckToken(`${header}.${payload}.`, {
    projectNumber: PROJECT_NUMBER,
    allowedAppIds: [APP_ID],
  }), null);
});
