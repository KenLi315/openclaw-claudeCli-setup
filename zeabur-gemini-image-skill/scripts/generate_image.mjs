#!/usr/bin/env node
import { parseArgs } from "node:util";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, extname, resolve } from "node:path";

const DEFAULT_MODEL = "gemini-2.5-flash-image";
const DEFAULT_API_BASE = "https://generativelanguage.googleapis.com";

function mimeFromExt(path) {
  const ext = extname(path).toLowerCase();
  if (ext === ".jpg" || ext === ".jpeg") return "image/jpeg";
  if (ext === ".png") return "image/png";
  if (ext === ".webp") return "image/webp";
  if (ext === ".gif") return "image/gif";
  return "application/octet-stream";
}

async function loadImageAsBase64(input) {
  if (/^https?:\/\//i.test(input)) {
    const r = await fetch(input, { signal: AbortSignal.timeout(120_000) });
    if (!r.ok) throw new Error(`Failed to fetch input image URL: ${r.status}`);
    const buf = Buffer.from(await r.arrayBuffer());
    const ct = r.headers.get("content-type") || "image/png";
    return { data: buf.toString("base64"), mimeType: ct.split(";")[0].trim() };
  }
  const abs = resolve(input);
  const buf = await readFile(abs);
  return { data: buf.toString("base64"), mimeType: mimeFromExt(abs) };
}

function extractFirstImageBase64(json) {
  const candidates = json?.candidates;
  if (!Array.isArray(candidates)) return null;
  for (const c of candidates) {
    const parts = c?.content?.parts;
    if (!Array.isArray(parts)) continue;
    for (const p of parts) {
      const d1 = p?.inline_data?.data;
      const d2 = p?.inlineData?.data;
      if (typeof d1 === "string" && d1.length > 0) return d1;
      if (typeof d2 === "string" && d2.length > 0) return d2;
    }
  }
  return null;
}

const { values } = parseArgs({
  options: {
    prompt: { type: "string", short: "p" },
    filename: { type: "string", short: "f" },
    "input-image": { type: "string", short: "i", default: "" },
    model: { type: "string", short: "m", default: DEFAULT_MODEL },
    "aspect-ratio": { type: "string", default: "" },
    "api-key": { type: "string", short: "k" },
    "api-base": { type: "string", default: DEFAULT_API_BASE },
  },
  strict: true,
});

if (!values.prompt || !values.filename) {
  console.error("Usage:");
  console.error('  node generate_image.mjs --prompt "..." --filename "/path/out.png" [--input-image "/path/or/url"]');
  process.exit(1);
}

const apiKey = values["api-key"] || process.env.GOOGLE_API_KEY;
if (!apiKey) {
  console.error("Missing API key. Set GOOGLE_API_KEY or use --api-key.");
  process.exit(1);
}

const model = values.model;
const prompt = values.prompt;
const outputPath = resolve(values.filename);
const apiBase = String(values["api-base"]).replace(/\/+$/, "");
const endpoint = `${apiBase}/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${encodeURIComponent(apiKey)}`;

const parts = [{ text: prompt }];

if (values["input-image"]) {
  const img = await loadImageAsBase64(values["input-image"]);
  parts.push({
    inline_data: {
      mime_type: img.mimeType,
      data: img.data,
    },
  });
}

const generationConfig = {
  responseModalities: ["TEXT", "IMAGE"],
};

if (values["aspect-ratio"] && !values["input-image"]) {
  generationConfig.imageConfig = { aspectRatio: values["aspect-ratio"] };
}

const body = {
  contents: [{ role: "user", parts }],
  generationConfig,
};

console.log(`Generating with model: ${model}`);
console.log(`Prompt: ${prompt}`);
if (values["input-image"]) console.log(`Input image: ${values["input-image"]}`);

const resp = await fetch(endpoint, {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify(body),
  signal: AbortSignal.timeout(300_000),
});

if (!resp.ok) {
  const t = await resp.text();
  console.error(`Gemini API error (${resp.status}): ${t}`);
  process.exit(1);
}

const json = await resp.json();
const b64 = extractFirstImageBase64(json);
if (!b64) {
  console.error("No image found in response.");
  console.error(JSON.stringify(json).slice(0, 1200));
  process.exit(1);
}

await mkdir(dirname(outputPath), { recursive: true });
await writeFile(outputPath, Buffer.from(b64, "base64"));

console.log(`Image saved: ${outputPath}`);
console.log(`MEDIA: ${outputPath}`);
