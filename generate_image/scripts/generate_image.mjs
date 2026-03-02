#!/usr/bin/env node
import { parseArgs } from "node:util";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, extname, resolve, join } from "node:path";

const DEFAULT_MODEL = process.env.GEMINI_IMAGE_MODEL || "gemini-3.1-flash-image-preview";
const stateDir = process.env.OPENCLAW_STATE_DIR || (process.env.HOME ? `${process.env.HOME}/.openclaw` : "/home/node/.openclaw");
const DEFAULT_DIR = process.env.IMAGE_OUTPUT_DIR || `${stateDir}/media/images`;
const API_BASE = "https://generativelanguage.googleapis.com";

const { values } = parseArgs({
  options: {
    prompt: { type: "string", short: "p" },
    filename: { type: "string", short: "f", default: "" },
    "input-image": { type: "string", short: "i", default: "" },
    model: { type: "string", short: "m", default: DEFAULT_MODEL },
  },
  strict: true,
});

if (!values.prompt) {
  console.error('Usage: node gemini-image-gen.mjs --prompt "..." [--filename "/path/out.png"] [--input-image "/path/or/url"] [--model "..."]');
  process.exit(1);
}
const apiKey = process.env.GOOGLE_API_KEY;
if (!apiKey) {
  console.error("Missing GOOGLE_API_KEY");
  process.exit(1);
}

function stamp() {
  const d = new Date();
  const z = (n) => String(n).padStart(2, "0");
  return `${d.getFullYear()}${z(d.getMonth()+1)}${z(d.getDate())}-${z(d.getHours())}${z(d.getMinutes())}${z(d.getSeconds())}`;
}
function mimeFromExt(path) {
  const e = extname(path).toLowerCase();
  if (e === ".jpg" || e === ".jpeg") return "image/jpeg";
  if (e === ".png") return "image/png";
  if (e === ".webp") return "image/webp";
  if (e === ".gif") return "image/gif";
  return "application/octet-stream";
}
async function loadImageAsBase64(input) {
  if (/^https?:\/\//i.test(input)) {
    const r = await fetch(input, { signal: AbortSignal.timeout(120000) });
    if (!r.ok) throw new Error(`Fetch input image failed: ${r.status}`);
    const b = Buffer.from(await r.arrayBuffer());
    const ct = (r.headers.get("content-type") || "image/png").split(";")[0].trim();
    return { data: b.toString("base64"), mimeType: ct };
  }
  const abs = resolve(input);
  const b = await readFile(abs);
  return { data: b.toString("base64"), mimeType: mimeFromExt(abs) };
}
function pickImageB64(json) {
  for (const c of (json?.candidates || [])) {
    for (const p of (c?.content?.parts || [])) {
      const b64 = p?.inline_data?.data || p?.inlineData?.data;
      if (b64) return b64;
    }
  }
  return null;
}

let outputPath = values.filename ? resolve(values.filename) : join(DEFAULT_DIR, `auto-${stamp()}.png`);
// 強制落在共享可傳送目錄，避免 message tool path 被拒
if (!outputPath.startsWith(DEFAULT_DIR + "/") && outputPath !== DEFAULT_DIR) {
  const base = outputPath.split("/").pop() || `auto-${stamp()}.png`;
  outputPath = join(DEFAULT_DIR, base);
}

const parts = [{ text: values.prompt }];
if (values["input-image"]) {
  const img = await loadImageAsBase64(values["input-image"]);
  parts.push({ inline_data: { mime_type: img.mimeType, data: img.data } });
}

const endpoint = `${API_BASE}/v1beta/models/${encodeURIComponent(values.model)}:generateContent?key=${encodeURIComponent(apiKey)}`;
const body = {
  contents: [{ role: "user", parts }],
  generationConfig: { responseModalities: ["TEXT", "IMAGE"] },
};

const r = await fetch(endpoint, {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify(body),
  signal: AbortSignal.timeout(300000),
});
if (!r.ok) {
  console.error(`Gemini API error (${r.status}): ${await r.text()}`);
  process.exit(1);
}
const j = await r.json();
const b64 = pickImageB64(j);
if (!b64) {
  console.error("No image found in response");
  console.error(JSON.stringify(j).slice(0, 1000));
  process.exit(1);
}

await mkdir(dirname(outputPath), { recursive: true });
await writeFile(outputPath, Buffer.from(b64, "base64"));
console.log(`Image saved: ${outputPath}`);
console.log(`MEDIA: ${outputPath}`);
