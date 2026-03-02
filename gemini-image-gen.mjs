#!/usr/bin/env node
import { parseArgs } from "node:util";
import { mkdir, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";

const DEFAULT_MODEL = "gemini-2.5-flash-image";
const DEFAULT_API_BASE = "https://generativelanguage.googleapis.com";

function usage() {
  console.error("Usage:");
  console.error('  node gemini-image-gen.mjs --prompt "your prompt" --filename "output.png"');
  console.error("");
  console.error("Optional flags:");
  console.error("  --model <model-id>         default: gemini-2.5-flash-image");
  console.error("  --aspect-ratio <ratio>     e.g. 1:1, 16:9, 9:16");
  console.error("  --api-key <key>            fallback to GOOGLE_API_KEY");
  console.error("  --api-base <url>           default: https://generativelanguage.googleapis.com");
}

function getFirstImageBase64(responseJson) {
  const candidates = responseJson?.candidates;
  if (!Array.isArray(candidates)) return null;

  for (const candidate of candidates) {
    const parts = candidate?.content?.parts;
    if (!Array.isArray(parts)) continue;

    for (const part of parts) {
      // Gemini JS/REST variants
      const inlineData = part?.inlineData || part?.inline_data;
      if (inlineData?.data && typeof inlineData.data === "string") {
        return inlineData.data;
      }

      // Some gateways may return OpenAI-style image payloads
      if (part?.image?.b64_json && typeof part.image.b64_json === "string") {
        return part.image.b64_json;
      }
    }
  }

  return null;
}

const { values } = parseArgs({
  options: {
    prompt: { type: "string", short: "p" },
    filename: { type: "string", short: "f" },
    model: { type: "string", short: "m", default: DEFAULT_MODEL },
    "aspect-ratio": { type: "string", default: "" },
    "api-key": { type: "string", short: "k" },
    "api-base": { type: "string", default: DEFAULT_API_BASE },
  },
  strict: true,
});

if (!values.prompt || !values.filename) {
  usage();
  process.exit(1);
}

const apiKey = values["api-key"] || process.env.GOOGLE_API_KEY;
if (!apiKey) {
  console.error("Error: missing API key.");
  console.error("Set GOOGLE_API_KEY or pass --api-key.");
  process.exit(1);
}

const model = values.model;
const prompt = values.prompt;
const outputPath = resolve(values.filename);
const apiBase = String(values["api-base"]).replace(/\/+$/, "");
const endpoint = `${apiBase}/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${encodeURIComponent(apiKey)}`;

const generationConfig = {
  responseModalities: ["TEXT", "IMAGE"],
};

if (values["aspect-ratio"]) {
  generationConfig.imageConfig = { aspectRatio: values["aspect-ratio"] };
}

const body = {
  contents: [
    {
      role: "user",
      parts: [{ text: prompt }],
    },
  ],
  generationConfig,
};

console.log(`Generating image with ${model}...`);
console.log(`Prompt: ${prompt}`);

const resp = await fetch(endpoint, {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
  },
  body: JSON.stringify(body),
  signal: AbortSignal.timeout(300_000),
});

if (!resp.ok) {
  const errText = await resp.text();
  console.error(`Gemini API failed (${resp.status}): ${errText}`);
  process.exit(1);
}

const json = await resp.json();
const b64 = getFirstImageBase64(json);
if (!b64) {
  console.error("Error: no image found in API response.");
  console.error(`Response preview: ${JSON.stringify(json).slice(0, 800)}`);
  process.exit(1);
}

await mkdir(dirname(outputPath), { recursive: true });
await writeFile(outputPath, Buffer.from(b64, "base64"));

console.log(`Image saved: ${outputPath}`);
console.log(`MEDIA: ${outputPath}`);
