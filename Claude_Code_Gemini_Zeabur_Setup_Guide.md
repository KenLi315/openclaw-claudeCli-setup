# Claude Code + Gemini API 於 Zeabur 部署 — 逐步設定指南

> 讓 OpenClaw 透過 Claude Code CLI 使用 Gemini API 進行 AI 編碼，無需 Claude 訂閱。

---

## 架構概覽

```
┌─────────────────────────────────────────────────────────────────────┐
│  Zeabur 專案                                                         │
│                                                                      │
│  ┌─────────────────────────┐      ┌─────────────────────────────┐  │
│  │ claude-code-proxy        │      │ OpenClaw (自訂映像)         │  │
│  │ (Service 1)              │◄─────│                             │  │
│  │                          │      │ • OpenClaw Gateway          │  │
│  │ • 接收 Anthropic 格式    │      │ • Claude Code CLI           │  │
│  │ • 轉成 Gemini API 請求   │      │ • exec 可呼叫 claude -p     │  │
│  │ • GEMINI_API_KEY         │      │ • ANTHROPIC_BASE_URL → proxy│  │
│  │ • Port 8082              │      │ • 模型仍用 Gemini           │  │
│  └─────────────────────────┘      └─────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 前置需求

- [Zeabur](https://zeabur.com) 帳號
- [Google AI Studio](https://aistudio.google.com/apikey) 的 Gemini API Key
- 已有 OpenClaw 部署於 Zeabur（或準備從頭部署）
- GitHub 帳號（若要用自訂 Dockerfile 部署 OpenClaw）

---

## 最簡流程總覽

| 步驟 | 動作 | 預估時間 |
|------|------|----------|
| Part A | 部署 claude-code-proxy（Docker 映像，無需建置） | 約 2 分鐘 |
| Part B | 部署或更新 OpenClaw（含 Claude Code CLI） | 約 5–10 分鐘 |
| Part C | 設定 OpenClaw 連到 proxy | 約 1 分鐘 |
| Part D | 驗證 | 約 2 分鐘 |

---

## Part A：部署 claude-code-proxy

### Step A1：新增 claude-code-proxy 服務

1. 登入 [Zeabur](https://zeabur.com) → 選擇你的專案
2. 點 **Add Service**（新增服務）
3. 選擇 **Docker Images**
4. 在 **Image** 欄位輸入：
   ```
   ghcr.io/1rgs/claude-code-proxy:latest
   ```
5. 將服務命名為 `claude-code-proxy`（之後內部連線會用到此名稱）

### Step A2：設定環境變數

在 claude-code-proxy 服務的 **Variables** 分頁新增：

| 變數名稱 | 值 | 說明 |
|----------|-----|------|
| `PREFERRED_PROVIDER` | `google` | 使用 Gemini 後端 |
| `GEMINI_API_KEY` | `你的 Gemini API Key` | 從 [Google AI Studio](https://aistudio.google.com/apikey) 取得 |
| `OPENAI_API_KEY` | `dummy-key` | 備用，可填任意值 |
| `BIG_MODEL` | `gemini-2.5-pro` | Sonnet 對應的模型（可選） |
| `SMALL_MODEL` | `gemini-2.0-flash` | Haiku 對應的模型（可選） |

### Step A3：設定 Port

1. 進入 **Settings** 或 **Networking**
2. 確認 **Port** 為 `8082`
3. 若 Zeabur 有「對外公開」選項，proxy 可設為**僅內部**（不需對外）

### Step A4：部署並確認

1. 點 **Deploy** 或 **Redeploy**
2. 部署完成後，在 **Networking** 查看 **Private** 區塊的內部 hostname
3. 內部網址格式通常為：`claude-code-proxy.zeabur.internal:8082`

---

## Part B：部署 OpenClaw（含 Claude Code CLI）

你有兩種方式：**方式一** 使用自訂映像（推薦）、**方式二** 沿用既有 OpenClaw 並在啟動時安裝 Claude Code。

---

### 方式一：自訂映像（推薦）

#### Step B1a：準備 Dockerfile

在本專案中已有 `claude-code-proxy-zeabur/Dockerfile`，內容為：

```dockerfile
FROM ghcr.io/openclaw/openclaw:latest
RUN npm install -g @anthropic-ai/claude-code
```

#### Step B1b：建置並推送映像

**選項 1：Zeabur 從 GitHub 建置（推薦）**

1. 將本專案（含 `claude-code-proxy-zeabur/`）推送到 GitHub
2. Zeabur → **Add Service** → **GitHub** → 選擇你的倉庫
3. 在 **Build** 設定中：
   - **Root Directory** 設為 `claude-code-proxy-zeabur`（或 **Dockerfile Path** 設為 `claude-code-proxy-zeabur/Dockerfile`）
   - 若 Zeabur 以專案根目錄建置，請將 `Dockerfile` 放在倉庫根目錄，或依 Zeabur 介面指定路徑
4. **Port** 設為 `18789`
5. 部署後，此服務即為含 Claude Code 的 OpenClaw

**選項 2：本地建置並推送到 Docker Hub**

```bash
cd claude-code-proxy-zeabur
docker build -t 你的帳號/openclaw-claude:latest .
docker push 你的帳號/openclaw-claude:latest
```

然後在 Zeabur 用 **Docker Images** 部署 `你的帳號/openclaw-claude:latest`

#### Step B1c：在 Zeabur 部署 OpenClaw

1. **Add Service** → **Docker Images**
2. **Image** 填寫你建好的映像，例如：
   - `ghcr.io/你的帳號/你的倉庫/openclaw-claude:latest`
   - 或 `你的帳號/openclaw-claude:latest`（Docker Hub）
3. **Port** 設為 `18789`
4. 依 OpenClaw 官方文件設定 **Volumes**、**Environment**（Telegram、模型等）

---

### 方式二：沿用既有 OpenClaw + 啟動時安裝（臨時方案）

若你已有 OpenClaw 且**暫時無法**建置自訂映像，可修改 **Start Command** 在啟動時安裝：

1. 進入 OpenClaw 服務的 **Settings** → **Start Command**
2. 設為（將原本的 `openclaw gateway start` 改為）：
   ```bash
   sh -c "npm install -g @anthropic-ai/claude-code 2>/dev/null; exec openclaw gateway start"
   ```
3. 注意：每次重啟會多花約 1–2 分鐘安裝，建議長期改用方式一

---

## Part C：設定 OpenClaw 連到 proxy

### Step C1：新增環境變數

在 **OpenClaw 服務**的 **Variables** 新增：

| 變數名稱 | 值 | 說明 |
|----------|-----|------|
| `ANTHROPIC_BASE_URL` | `http://claude-code-proxy.zeabur.internal:8082` | 指向 claude-code-proxy 的內部網址 |

> 若你的 proxy 服務名稱不同，請改成 `http://你的服務名稱.zeabur.internal:8082`

### Step C2：確認 agent 有 exec 權限

在 `openclaw.json` 中，需要呼叫 Claude Code 的 agent 必須允許 `exec`，例如：

```json
"tools": { "allow": ["read", "write", "exec", "web_search", "web_fetch"] }
```

### Step C3：重啟 OpenClaw

儲存設定後，點 **Redeploy** 重新部署 OpenClaw。

---

## Part D：驗證

### Step D1：確認 proxy 正常

在 OpenClaw 服務的 **Command** 終端執行：

```bash
curl -s "http://claude-code-proxy.zeabur.internal:8082/health" 2>/dev/null || echo "檢查 proxy 是否在運行"
```

若有回傳，代表 proxy 可連線。

### Step D2：測試 Claude Code

在 OpenClaw 的 **Command** 終端執行：

```bash
# 確認 Claude Code 已安裝
claude --version

# 非互動模式測試（會向 proxy 發送請求）
claude -p "Say hello in one sentence"
```

若回傳正常，代表 Claude Code 已透過 proxy 使用 Gemini。

### Step D3：透過 OpenClaw 測試

透過 Telegram 或其他通道發送：

```
請用 exec 執行：claude -p "寫一個 Python 函數計算費氏數列前 10 項"
```

預期：主代理會呼叫 `exec` 執行 `claude -p "..."`，並回傳結果。

---

## 故障排除

| 問題 | 可能原因 | 解法 |
|------|----------|------|
| `claude: command not found` | Claude Code 未安裝 | 使用自訂映像，或確認啟動腳本有執行 `npm install -g` |
| `Connection refused` 連到 proxy | 服務名稱或 port 錯誤 | 檢查 `ANTHROPIC_BASE_URL` 是否為 `http://claude-code-proxy.zeabur.internal:8082` |
| proxy 回傳 401/500 | GEMINI_API_KEY 錯誤 | 到 Zeabur Variables 確認 `GEMINI_API_KEY` 正確 |
| OpenClaw 未呼叫 claude | agent 沒有 exec 權限 | 在 `openclaw.json` 的 `tools.allow` 加入 `exec` |
| 內部 hostname 找不到 | 服務未同專案或名稱不同 | 在 Zeabur Networking 查看 Private hostname，並更新 `ANTHROPIC_BASE_URL` |

---

## 檔案與路徑總覽

```
openclaw_setup/
├── claude-code-proxy-zeabur/
│   └── Dockerfile          # OpenClaw + Claude Code 自訂映像
└── Claude_Code_Gemini_Zeabur_Setup_Guide.md  # 本指南
```

---

## 快速檢查清單

- [ ] Part A：claude-code-proxy 已部署，`GEMINI_API_KEY` 已設定
- [ ] Part B：OpenClaw 使用自訂映像（或已手動安裝 Claude Code）
- [ ] Part C：OpenClaw 的 `ANTHROPIC_BASE_URL` 指向 proxy
- [ ] Part C：需要編碼的 agent 有 `exec` 權限
- [ ] Part D：`claude -p "..."` 可正常執行

---

## 參考連結

- [claude-code-proxy GitHub](https://github.com/1rgs/claude-code-proxy)
- [Zeabur Private Networking](https://zeabur.com/docs/en-US/networking/private)
- [Google AI Studio API Key](https://aistudio.google.com/apikey)
