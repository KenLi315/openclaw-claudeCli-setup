#!/bin/bash
# 一鍵安裝：conversation-logger-webhook + conversation-session-sync
# 搭配 openclaw-conversation-storer 服務，將 User（即時）與 Assistant（/new 時）對話寫入 MongoDB
# 在 Zeabur OpenClaw Terminal 執行

set -e

echo "=== OpenClaw Conversation Storer — 安裝 Hooks ==="

# --- 1. conversation-logger-webhook (User 即時) ---
HOOK1="/home/node/.openclaw/hooks/conversation-logger-webhook"
mkdir -p "$HOOK1"
cd "$HOOK1"

cat > package.json << 'PKG1'
{"name":"conversation-logger-webhook","version":"1.0.0","type":"module"}
PKG1

cat > HOOK.md << 'HOOK1'
---
name: conversation-logger-webhook
description: "將對話 POST 到 Webhook URL（User 即時）"
metadata:
  openclaw:
    emoji: "🔗"
    events: ["message:received", "message:sent"]
    env: ["CONVERSATION_WEBHOOK_URL"]
---
HOOK1

cat > handler.ts << 'HANDLER1'
const WEBHOOK_URL = process.env.CONVERSATION_WEBHOOK_URL;
async function sendToWebhook(payload) {
  if (!WEBHOOK_URL) return;
  try {
    const res = await fetch(WEBHOOK_URL, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(payload) });
    if (!res.ok) console.error("[conversation-logger-webhook] Error:", res.status);
  } catch (e) { console.error("[conversation-logger-webhook]", e?.message || e); }
}
const handler = async (event) => {
  if (event.type !== "message") return;
  const ctx = event.context || {};
  const ch = ctx.channelId || "unknown";
  if (event.action === "received") void sendToWebhook({ role: "user", content: ctx.content ?? "", channelId: ch, sessionKey: event.sessionKey, senderId: ctx.from, conversationId: ctx.conversationId, messageId: ctx.messageId, createdAt: new Date().toISOString() });
  else if (event.action === "sent") void sendToWebhook({ role: "assistant", content: ctx.content ?? "", channelId: ch, sessionKey: event.sessionKey, senderId: ctx.to, conversationId: ctx.conversationId, messageId: ctx.messageId, createdAt: new Date().toISOString() });
};
export default handler;
HANDLER1

openclaw hooks disable conversation-logger-mongo 2>/dev/null || true
openclaw hooks enable conversation-logger-webhook
echo "✓ conversation-logger-webhook 已啟用"

# --- 2. conversation-session-sync (Assistant 於 /new 時) ---
HOOK2="/home/node/.openclaw/hooks/conversation-session-sync"
mkdir -p "$HOOK2"
cd "$HOOK2"

cat > package.json << 'PKG2'
{"name":"conversation-session-sync","version":"1.0.0","type":"module"}
PKG2

cat > HOOK.md << 'HOOK2'
---
name: conversation-session-sync
description: "在 /new 或 /reset 時，將 session transcript 中的助理訊息同步至 Webhook"
metadata:
  openclaw:
    emoji: "📤"
    events: ["command:new", "command:reset"]
    env: ["CONVERSATION_WEBHOOK_URL"]
---
HOOK2

cat > handler.ts << 'HANDLER2'
import { readFile } from "fs/promises";
import { existsSync } from "fs";
import { join } from "path";

const WEBHOOK_URL = process.env.CONVERSATION_WEBHOOK_URL;

async function postToWebhook(payload) {
  if (!WEBHOOK_URL) return;
  try {
    await fetch(WEBHOOK_URL, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(payload) });
  } catch (e) { console.error("[conversation-session-sync]", e?.message); }
}

function extractContent(obj) {
  if (typeof obj.content === "string" && obj.content) return obj.content;
  const blocks = obj.message?.content ?? obj.content;
  if (Array.isArray(blocks)) {
    const text = blocks.filter((b) => b?.type === "text").map((b) => b?.text ?? "").join("");
    return text || null;
  }
  return null;
}

function parseLine(line) {
  try {
    const obj = JSON.parse(line);
    if (obj.type !== "message" || (obj.role ?? obj.message?.role) !== "assistant") return null;
    const content = extractContent(obj);
    if (!content) return null;
    return { role: "assistant", content, transcriptId: obj.id, timestamp: obj.timestamp };
  } catch {}
  return null;
}

const handler = async (event) => {
  if (event.type !== "command" || (event.action !== "new" && event.action !== "reset")) return;
  if (!WEBHOOK_URL) return;

  const ctx = event.context || {};
  const sessionFile = ctx.sessionEntry?.sessionFile || ctx.sessionFile;
  if (!sessionFile) { console.warn("[conversation-session-sync] No sessionFile"); return; }

  const sessionKey = event.sessionKey || "";
  const channelId = ctx.commandSource || "unknown";
  const parts = sessionKey.split(":");
  const conversationId = parts.length >= 5 ? parts[2] + ":" + parts[4] : sessionKey;

  const baseDir = join(process.env.HOME || "/home/node", ".openclaw", "agents", "main", "sessions");
  let path = sessionFile.startsWith("/") ? sessionFile : join(baseDir, sessionFile.endsWith(".jsonl") ? sessionFile : sessionFile + ".jsonl");

  if (!existsSync(path)) { console.warn("[conversation-session-sync] Not found:", path); return; }

  try {
    const content = await readFile(path, "utf-8");
    for (const line of content.split("\n").filter(Boolean)) {
      const p = parseLine(line);
      if (p) void postToWebhook({ role: "assistant", content: p.content, channelId, sessionKey, conversationId, senderId: ctx.senderId, transcriptId: p.transcriptId, createdAt: p.timestamp ?? new Date().toISOString(), source: "session-sync" });
    }
  } catch (err) { console.error("[conversation-session-sync]", err?.message); }
};

export default handler;
HANDLER2

openclaw hooks enable conversation-session-sync
echo "✓ conversation-session-sync 已啟用"

echo ""
echo "=== 完成 ==="
echo "請確認："
echo "1. Zeabur 已部署 openclaw-conversation-storer 服務"
echo "2. OpenClaw 環境變數 CONVERSATION_WEBHOOK_URL = https://openclaw-conversation-storer-xxx.zeabur.app/log"
echo "3. Redeploy OpenClaw"
openclaw hooks list
