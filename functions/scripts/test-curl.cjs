const fs = require('fs');
const https = require('https');

const jwt = fs.readFileSync('C:/Users/dell/jwt.txt', 'utf8').trim();
const imageBytes = fs.readFileSync('F:/Development/jeevan_sutra/assets/branding/test_plant.jpg');

const postData = JSON.stringify({
  mimeType: "image/jpeg",
  imageBase64: imageBytes.toString("base64")
});

console.log('Sending geminiPlant request, bytes:', postData.length);
const startTime = Date.now();

const req = https.request('https://jeevan-sutra-gemini-api.jeevan-sutra-ai.workers.dev/geminiPlant', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Firebase-AppCheck': jwt,
    'Content-Length': Buffer.byteLength(postData)
  }
}, (res) => {
  console.log('ELAPSED:', (Date.now() - startTime) + 'ms');
  console.log('STATUS:', res.statusCode);
  console.log('HEADERS:', res.headers);
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => console.log('BODY:', data));
});

req.on('error', (e) => console.error('REQUEST ERROR:', e));
req.write(postData);
req.end();
