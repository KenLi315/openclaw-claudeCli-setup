# Web Searcher 子代理 — 完整設定指南

> 建立 `web_searcher` 子代理，使用 openclaw-sandbox-browser 進行網頁搜尋；主代理具備 fallback 能力。

---

## 架構概覽

| 角色 | 職責 | 工具 |
|------|------|------|
| **main** | 協調、分派、驗收；web_searcher 不可用時自行搜尋 | web_search, web_fetch |
| **web_searcher** | 專職網頁搜尋與擷取 | web_search, web_fetch, browser |
| **openclaw-sandbox-browser** | 遠端 Chromium（CDP） | 供 browser 工具連線 |

---

## 前置需求

- OpenClaw 已部署於 Zeabur
- **openclaw-sandbox-browser** 已部署於**同一 Zeabur 專案**
- 兩服務可透過內網互通（`http://openclaw-sandbox-browser:9222`）
- **GOOGLE_API_KEY** 或 **GEMINI_API_KEY** 已設定（web_search 使用 Gemini Google Search grounding，不需 Brave API）

---

## Step 1：建立 workspace 目錄

在 Zeabur **Command** 執行：

```bash
mkdir -p ~/.openclaw/workspace-web-searcher
```

---

## Step 2：上傳並套用設定檔

### 2.1 openclaw.json

將本專案 `templates/openclaw.json` 的內容合併到 Zeabur 的 `~/.openclaw/openclaw.json`，或直接覆蓋。重點區塊：

**browser 設定**（連線至 sandbox-browser）：

```json
"browser": {
  "enabled": true,
  "attachOnly": true,
  "defaultProfile": "remote",
  "profiles": {
    "remote": {
      "cdpUrl": "http://openclaw-sandbox-browser:9222",
      "color": "#FF4500"
    }
  }
}
```

**agents.list 新增 web_searcher**：

```json
{
  "id": "web_searcher",
  "name": "網頁搜尋子代理",
  "workspace": "~/.openclaw/workspace-web-searcher",
  "sandbox": {"mode": "off"},  // 必須 off：browser 工具才能使用 host 的 remote CDP（openclaw-sandbox-browser）
  "tools": {"allow": ["web_search", "web_fetch", "browser"]}
}
```

**main agent 新增 tools.allow**（fallback 用）：

```json
{"id": "main", ..., "tools": {"allow": ["web_search", "web_fetch"]}}
```

**tools.web.search 使用 Gemini**（Google API，不需 Brave）：

```json
"tools": {
  "web": {
    "search": {
      "provider": "gemini",
      "gemini": {
        "model": "gemini-2.5-flash"
      }
    }
  }
}
```

API key 來自環境變數 `GOOGLE_API_KEY` 或 `GEMINI_API_KEY`（兩者皆可，通常為同一把 Google AI Studio key）。

### 2.2 web_searcher AGENTS.md

將 `templates/workspace-web-searcher/AGENTS.md` 複製到 `~/.openclaw/workspace-web-searcher/AGENTS.md`。

### 2.3 main AGENTS.md

將 `templates/workspace-main/AGENTS.md` 複製到 `~/.openclaw/workspace-main/AGENTS.md`（已含 web_searcher 分派與 fallback 規則）。

---

## Step 3：確認 sandbox-browser 服務名稱

Zeabur 內網 hostname 通常為**服務名稱**。若你的 sandbox-browser 服務名稱不同，請修改 `browser.profiles.remote.cdpUrl`：

| 服務名稱 | cdpUrl |
|----------|--------|
| openclaw-sandbox-browser | `http://openclaw-sandbox-browser:9222` |
| 自訂名稱 | `http://<你的服務名稱>:9222` |

---

## Step 4：驗證連線（可選）

在 Zeabur OpenClaw 服務的 **Command** 執行：

```bash
curl http://openclaw-sandbox-browser:9222/json/version
```

若成功，會回傳 JSON（含 Browser、Protocol-Version 等）。

---

## Step 5：重啟服務

在 Zeabur 點 **Restart** 或 **Redeploy**。

---

## Step 6：驗證設定

```bash
openclaw agents list --bindings
```

應看到 `main`、`research`、`image_creator`、`web_searcher`。

---

## 主代理行為摘要

1. **分派給 web_searcher**：當任務需「搜尋網路」「查即時資訊」「擷取網頁」時，使用 `sessions_spawn` 分派給 `web_searcher`。
2. **Fallback**：若 `web_searcher` 無法分派（服務離線、agents_list 無此 id），主代理自行使用 `web_search`、`web_fetch` 完成搜尋。
3. **驗收**：收到 announce 後，檢查來源 URL、相關性、格式是否符合要求；不符則重派，最多 3 次。

---

## 檔案清單

```
~/.openclaw/
├── openclaw.json              # 含 browser、web_searcher、main tools
├── workspace-main/
│   └── AGENTS.md              # 含 web_searcher 分派與 fallback 規則
└── workspace-web-searcher/
    └── AGENTS.md              # web_searcher 操作規範
```

---

## 故障排除

| 問題 | 可能原因 | 解法 |
|------|----------|------|
| **No connected browser-capable nodes** | web_searcher 為 sandbox 會話，browser 工具預設 `target=sandbox`，會尋找 OpenClaw 的 sandbox browser 容器；Zeabur 上無此容器 | 將 web_searcher 設為 `sandbox: {"mode": "off"}`，使 browser 使用 `target=host` 並連線至 remote CDP |
| browser 工具無法連線 | sandbox-browser 未啟動或名稱錯誤 | 檢查服務名稱、`curl` 測試 |
| web_searcher 未出現在 agents_list | 未加入 agents.list 或未重啟 | 確認 openclaw.json、重啟 |
| 主代理無法 fallback 搜尋 | main 未設定 tools.allow | 確認 main 有 `web_search`、`web_fetch` |
| web_search 要求 Brave API key | 未設定 provider 為 gemini | 確認 `tools.web.search.provider: "gemini"` |
| web_search 無 API key | 未設定 GOOGLE_API_KEY / GEMINI_API_KEY | 在 Zeabur Variables 設定 |

---

## 參考

- [OpenClaw Browser Sandbox (Zeabur)](https://zeabur.com/templates/H8L4G1)
- [OpenClaw Browser Tool](https://docs.openclaw.ai/tools/browser)
- [Sub-Agents](https://docs.openclaw.ai/tools/subagents)
