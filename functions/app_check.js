const APP_CHECK_ISSUER = "https://firebaseappcheck.googleapis.com/";
const APP_CHECK_JWKS_URL = "https://firebaseappcheck.googleapis.com/v1/jwks";
const CLOCK_SKEW_SECONDS = 60;

let jwksCache;
let jwksCacheExpiresAt = 0;
let jwksCacheFetcher;

function decodeBase64Url(value) {
  const base64 = value.replace(/-/g, "+").replace(/_/g, "/");
  return atob(base64.padEnd(Math.ceil(base64.length / 4) * 4, "="));
}

function decodeJsonPart(value) {
  return JSON.parse(decodeBase64Url(value));
}

async function getJwks(fetcher, now) {
  const canCache = fetcher === globalThis.fetch;
  if (canCache && jwksCache && jwksCacheFetcher === fetcher &&
      jwksCacheExpiresAt > now) {
    return jwksCache;
  }

  let response;
  try {
    response = await fetcher(APP_CHECK_JWKS_URL);
  } catch {
    throw new Error("Unable to retrieve Firebase App Check signing keys.");
  }
  if (!response.ok) {
    throw new Error("Unable to retrieve Firebase App Check signing keys.");
  }
  const jwks = await response.json();
  if (!Array.isArray(jwks.keys)) {
    throw new Error("Firebase App Check returned invalid signing keys.");
  }
  if (canCache) {
    const cacheControl = response.headers.get("cache-control") || "";
    const maxAge = Number(cacheControl.match(/max-age=(\d+)/i)?.[1] || 3600);
    jwksCache = jwks;
    jwksCacheExpiresAt = now + Math.max(60, maxAge) * 1000;
    jwksCacheFetcher = fetcher;
  }
  return jwks;
}

export async function verifyAppCheckToken(
    token,
    {
      projectNumber,
      allowedAppIds,
      fetcher = globalThis.fetch,
      now = Date.now(),
    },
) {
  if (typeof token !== "string" || token.length === 0 || token.length > 8192) {
    return null;
  }

  try {
    const parts = token.split(".");
    if (parts.length !== 3) return null;
    const header = decodeJsonPart(parts[0]);
    const payload = decodeJsonPart(parts[1]);
    const projectAudience = `projects/${projectNumber}`;
    const audienceIsValid = Array.isArray(payload.aud) &&
      payload.aud.length > 0 &&
      payload.aud.includes(projectAudience);
    const nowSeconds = Math.floor(now / 1000);

    if (header.alg !== "RS256" ||
        typeof header.kid !== "string" ||
        !audienceIsValid ||
        payload.iss !== `${APP_CHECK_ISSUER}${projectNumber}` ||
        typeof payload.sub !== "string" ||
        !allowedAppIds.includes(payload.sub) ||
        !Number.isInteger(payload.exp) ||
        payload.exp <= nowSeconds ||
        !Number.isInteger(payload.iat) ||
        payload.iat > nowSeconds + CLOCK_SKEW_SECONDS ||
        (payload.nbf !== undefined &&
          (!Number.isInteger(payload.nbf) ||
            payload.nbf > nowSeconds + CLOCK_SKEW_SECONDS))) {
      return null;
    }

    let jwks;
    try {
      jwks = await getJwks(fetcher, now);
    } catch (error) {
      throw new Error("Unable to retrieve Firebase App Check signing keys.", {
        cause: error,
      });
    }
    const jwk = jwks.keys.find((key) => key.kid === header.kid);
    if (!jwk || jwk.kty !== "RSA" || jwk.alg && jwk.alg !== "RS256") {
      return null;
    }

    const key = await crypto.subtle.importKey(
        "jwk",
        jwk,
        {name: "RSASSA-PKCS1-v1_5", hash: "SHA-256"},
        false,
        ["verify"],
    );
    const signature = Uint8Array.from(
        decodeBase64Url(parts[2]),
        (character) => character.charCodeAt(0),
    );
    const signedContent = new TextEncoder().encode(`${parts[0]}.${parts[1]}`);
    const signatureValid = await crypto.subtle.verify(
        "RSASSA-PKCS1-v1_5",
        key,
        signature,
        signedContent,
    );
    return signatureValid ? payload : null;
  } catch (error) {
    if (error instanceof TypeError || error instanceof SyntaxError) {
      return null;
    }
    throw error;
  }
}
