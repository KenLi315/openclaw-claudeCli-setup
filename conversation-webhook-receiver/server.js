/**
 * Conversation Webhook Receiver
 * 接收 OpenClaw Hook 的 POST，寫入 MongoDB
 * 部署到 Zeabur，連結 MongoDB，設定 PORT=8080
 */

import { createServer } from "http";
import { MongoClient } from "mongodb";

const PORT = parseInt(process.env.PORT || "8080", 10);
const MONGO_URI = process.env.MONGO_URI;
const DB_NAME = "openclaw";
const COLLECTION = "conversations";

let mongoClient = null;

async function getDb() {
  if (!MONGO_URI) throw new Error("MONGO_URI not set");
  if (!mongoClient) {
    mongoClient = new MongoClient(MONGO_URI);
    await mongoClient.connect();
  }
  return mongoClient.db(DB_NAME).collection(COLLECTION);
}

const server = createServer(async (req, res) => {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    res.writeHead(204);
    res.end();
    return;
  }

  if (req.method !== "POST" || req.url !== "/log") {
    res.writeHead(404, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ error: "Not found. Use POST /log" }));
    return;
  }

  let body = "";
  for await (const chunk of req) body += chunk;

  try {
    const doc = JSON.parse(body || "{}");
    const col = await getDb();
    await col.insertOne({
      ...doc,
      createdAt: doc.createdAt ? new Date(doc.createdAt) : new Date(),
    });
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ ok: true }));
  } catch (err) {
    console.error("[webhook-receiver] Error:", err);
    res.writeHead(500, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ error: err.message }));
  }
});

server.listen(PORT, () => {
  console.log(`Conversation webhook receiver listening on port ${PORT}`);
  if (!MONGO_URI) console.warn("MONGO_URI not set - will fail on first request");
});
