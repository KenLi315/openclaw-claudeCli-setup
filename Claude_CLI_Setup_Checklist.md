# OpenClaw + Claude CLI 設定檢查清單

> 讓主代理透過 Claude Code CLI 使用 Gemini API 進行 AI 編碼。完整指南見 `Claude_Code_Gemini_Zeabur_Setup_Guide.md`。

---

## 快速檢查清單

| 步驟 | 動作 | 狀態 |
|------|------|------|
| **Part A** | 部署 claude-code-proxy，設定 `GEMINI_API_KEY` | ☐ |
| **Part B** | OpenClaw 使用自訂映像（含 Claude Code）或啟動時安裝 | ☐ |
| **Part C** | OpenClaw 設定 `ANTHROPIC_BASE_URL` 指向 proxy | ☐ |
| **Part C** | main agent 的 `tools.allow` 含 `exec`（已完成） | ☑ |
| **Part D** | 驗證 `claude -p "..."` 可正常執行 | ☐ |

---

## Part A：claude-code-proxy（約 2 分鐘）

1. Zeabur → **Add Service** → **Docker Images**
2. **Image**：`ghcr.io/1rgs/claude-code-proxy:latest`
3. **Variables**：
   - `PREFERRED_PROVIDER` = `google`
   - `GEMINI_API_KEY` = 你的 Gemini API Key
   - `OPENAI_API_KEY` = `dummy-key`
4. **Port**：`8082`
5. 內部網址：`claude-code-proxy.zeabur.internal:8082`

---

## Part B：OpenClaw 含 Claude Code（約 5–10 分鐘）

**方式一（推薦）**：自訂映像

- 使用 `claude-code-proxy-zeabur/Dockerfile` 建置
- Zeabur 從 GitHub 建置，或本地 `docker build` 後推送
- **Root Directory** 設為 `claude-code-proxy-zeabur`
- **Port**：`18789`

**方式二（臨時）**：啟動時安裝

- OpenClaw **Start Command** 設為：
  ```bash
  sh -c "npm install -g @anthropic-ai/claude-code 2>/dev/null; exec openclaw gateway start"
  ```

---

## Part C：OpenClaw 連到 proxy（約 1 分鐘）

在 **OpenClaw 服務**的 **Variables** 新增：

| 變數 | 值 |
|------|-----|
| `ANTHROPIC_BASE_URL` | `http://claude-code-proxy.zeabur.internal:8082` |

> `templates/openclaw.json` 已為 main agent 加入 `exec`、`read`、`write`，部署時請使用此設定檔。

---

## Part D：驗證（約 2 分鐘）

在 OpenClaw 的 **Command** 終端執行：

```bash
# 確認 Claude Code 已安裝
claude --version

# 測試 proxy 連線
curl -s "http://claude-code-proxy.zeabur.internal:8082/health"

# 測試 Claude Code（會向 proxy 發送請求）
claude -p "Say hello in one sentence"
```

透過 Telegram 測試：

```
請用 exec 執行：claude -p "寫一個 Python 函數計算費氏數列前 10 項"
```

---

## 故障排除

| 問題 | 解法 |
|------|------|
| `claude: command not found` | 確認使用自訂映像或啟動腳本有執行 `npm install -g @anthropic-ai/claude-code` |
| Connection refused 連到 proxy | 檢查 `ANTHROPIC_BASE_URL` 是否正確 |
| proxy 回傳 401/500 | 確認 `GEMINI_API_KEY` 正確 |
| OpenClaw 未呼叫 claude | 確認 main agent 的 `tools.allow` 含 `exec` |
