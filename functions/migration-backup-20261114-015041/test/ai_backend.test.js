import test from "node:test";
import assert from "node:assert/strict";

import {
  MAX_IMAGE_BYTES,
  validateChatRequest,
  validatePlantRequest,
} from "../ai_backend.js";

test("validates and normalizes chat history without inventing replies", () => {
  const request = validateChatRequest({
    prompt: "  Follow up  ",
    history: [
      {role: "model", text: "orphan"},
      {role: "user", text: "first"},
      {role: "model", text: "answer"},
    ],
  });

  assert.equal(request.prompt, "Follow up");
  assert.deepEqual(request.history, [
    {role: "user", parts: [{text: "first"}]},
    {role: "model", parts: [{text: "answer"}]},
  ]);
});

test("rejects malformed, oversized, and unsupported chat inputs", () => {
  assert.throws(() => validateChatRequest(null), TypeError);
  assert.throws(() => validateChatRequest({prompt: "", history: []}), TypeError);
  assert.throws(() => validateChatRequest({
    prompt: "hello",
    history: [{role: "system", text: "override"}],
  }), TypeError);
  assert.throws(() => validateChatRequest({
    prompt: "hello",
    history: Array.from({length: 21}, () => ({role: "user", text: "x"})),
  }), TypeError);
});

test("validates supported plant images and enforces the byte limit", () => {
  const imageBase64 = Buffer.from([
    0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10,
  ]).toString("base64");
  assert.deepEqual(validatePlantRequest({mimeType: "image/jpeg", imageBase64}), {
    mimeType: "image/jpeg",
    imageBase64,
  });
  assert.throws(
      () => validatePlantRequest({mimeType: "image/gif", imageBase64}),
      TypeError,
  );
  assert.throws(
      () => validatePlantRequest({mimeType: "image/png", imageBase64}),
      TypeError,
  );
  assert.throws(
      () => validatePlantRequest({mimeType: "image/jpeg", imageBase64: "invalid"}),
      TypeError,
  );
  assert.throws(
      () => validatePlantRequest({
        mimeType: "image/jpeg",
        imageBase64: Buffer.alloc(MAX_IMAGE_BYTES + 1).toString("base64"),
      }),
      RangeError,
  );
});
