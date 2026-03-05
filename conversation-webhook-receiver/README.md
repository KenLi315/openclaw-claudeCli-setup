# Conversation Webhook Receiver

接收 OpenClaw `conversation-logger-webhook` 的 POST，寫入 MongoDB。

## 部署到 Zeabur

### 1. 部署服務

**方式 A：從 GitHub**
1. 將此資料夾推送到 GitHub（可放在 openclaw_setup 的 `conversation-webhook-receiver/` 子目錄）
2. Zeabur → **Deploy New Service** → **GitHub**
3. 選擇包含此專案的 repo，指定 **Root Directory** 為 `conversation-webhook-receiver`

**方式 B：從本機上傳**
1. Zeabur → **Deploy New Service** → **Local Project**
2. 選擇 `conversation-webhook-receiver` 資料夾上傳

### 2. 連結 MongoDB

1. 在 Zeabur 專案中，將 **MongoDB** 服務連結到 **conversation-webhook-receiver**
2. 或手動在 conversation-webhook-receiver 的 **環境變數** 新增：
   - `MONGO_URI` = MongoDB 的 **Internal** 連線字串

### 3. 設定 Port

Zeabur 通常自動偵測。若需手動設定：
- `PORT` = `8080`

### 4. 取得 Webhook URL

1. 點選 **conversation-webhook-receiver** 服務
2. 進入 **Networking** → **Generate Domain** 或查看既有網域
3. Webhook URL = `https://你的網域.zeabur.app/log`

### 5. 設定 OpenClaw

在 **OpenClaw** 服務的環境變數新增：
- `CONVERSATION_WEBHOOK_URL` = `https://你的網域.zeabur.app/log`

完成後 Redeploy OpenClaw。
