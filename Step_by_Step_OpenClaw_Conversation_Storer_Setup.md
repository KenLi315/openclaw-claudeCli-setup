# OpenClaw Conversation Storer — 逐步設定指南

**單一 Zeabur 服務** 接收 User 訊息（即時）與 Assistant 訊息（/new 時），寫入 MongoDB。

---

## 架構

```
Telegram → OpenClaw
              ├─ conversation-logger-webhook (User 即時) ──┐
              │                                            │ POST /log
              └─ conversation-session-sync (Assistant) ────┼────────────→ openclaw-conversation-storer
                 （/new 或 /reset 時從 transcript 同步）     │                    ↓
                                                          │              MongoDB
                                                          └──────────────────→
```

---

## 步驟一：在 Zeabur 建立 MongoDB

1. Zeabur → **Deploy New Service** → **Databases** → **MongoDB**
2. 等待部署完成

---

## 步驟二：部署 openclaw-conversation-storer 服務

### 方式 A：從 GitHub

1. 確認 `openclaw-conversation-storer/` 已推送到 GitHub
2. Zeabur → **Deploy New Service** → **GitHub**
3. 選擇 `openclaw_setup` repo
4. **Root Directory** 設為 `openclaw-conversation-storer`
5. 部署完成後，**Networking** → **Generate Domain** 取得網域（例如 `openclaw-conversation-storer-xxx.zeabur.app`）

### 方式 B：從本機上傳

1. Zeabur → **Deploy New Service** → **Local Project**
2. 選擇專案中的 `openclaw-conversation-storer` 資料夾
3. 上傳並部署
4. **Networking** → **Generate Domain** 取得網域

---

## 步驟三：連結 MongoDB 到 openclaw-conversation-storer

1. 點選 **openclaw-conversation-storer** 服務
2. **Variables** → 連結 MongoDB 服務，或手動新增：
   - **Name**：`MONGO_URI`
   - **Value**：MongoDB 的 **Internal** 連線字串

---

## 步驟四：設定 OpenClaw 的 CONVERSATION_WEBHOOK_URL

1. 取得 openclaw-conversation-storer 網域，例如：`openclaw-conversation-storer-xxx.zeabur.app`
2. Webhook URL = `https://openclaw-conversation-storer-xxx.zeabur.app/log`
3. 點選 **OpenClaw** 服務 → **Variables**
4. 新增：
   - **Name**：`CONVERSATION_WEBHOOK_URL`
   - **Value**：`https://你的網域.zeabur.app/log`
5. 儲存

---

## 步驟五：在 OpenClaw 安裝 Hooks（一鍵）

1. Zeabur → **OpenClaw** 服務 → **指令（Commands）**
2. 開啟 Terminal
3. 複製 `scripts/Zeabur_OpenClaw_Conversation_Storer_Setup.sh` 的**整份內容**
4. 貼到 Terminal 並執行

此腳本會安裝並啟用：
- **conversation-logger-webhook**：User 訊息即時 POST
- **conversation-session-sync**：/new 或 /reset 時同步 Assistant 訊息

---

## 步驟六：Redeploy OpenClaw

在 Zeabur 對 **OpenClaw** 服務執行 **Redeploy** 或 **Restart**。

---

## 步驟七：驗證

1. 在 Telegram 與 OpenClaw 對話幾輪
2. 發送 `/new` 或 `/reset`
3. 在 **MongoDB Compass** 中：
   - 連線到 Zeabur MongoDB（**Public** 連線字串）
   - 開啟 `openclaw` 資料庫 → `conversations` collection
   - 應能看到 `role: "user"`（即時）與 `role: "assistant"`（source: "session-sync"）

### 依時間排序對話

```javascript
db.conversations.find({ conversationId: "telegram:715656210" }).sort({ createdAt: 1 })
```

---

## 檢查清單

| 步驟 | 項目 |
|------|------|
| 1 | MongoDB 已部署 |
| 2 | openclaw-conversation-storer 已部署並有網域 |
| 3 | openclaw-conversation-storer 的 MONGO_URI 已設定 |
| 4 | OpenClaw 的 CONVERSATION_WEBHOOK_URL 已設定 |
| 5 | Zeabur_OpenClaw_Conversation_Storer_Setup.sh 已執行 |
| 6 | OpenClaw 已 Redeploy |

---

## 疑難排解

| 問題 | 檢查 |
|------|------|
| User 訊息未寫入 | CONVERSATION_WEBHOOK_URL 正確、conversation-logger-webhook 已啟用 |
| Assistant 訊息未寫入 | 發送 /new 或 /reset 後才會同步；確認 conversation-session-sync 已啟用 |
| 接收端 500 | openclaw-conversation-storer 的 MONGO_URI 正確 |
| 查不到紀錄 | MongoDB Compass 使用 **Public** 連線字串（非 Internal） |
