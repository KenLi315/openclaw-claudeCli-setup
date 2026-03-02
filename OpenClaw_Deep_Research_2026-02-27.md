# OpenClaw 深度研究報告（2026-02-27）

## 0) 研究範圍與方法

- 主題：`OpenClaw` 的 AI 模型支援、Agent 架構、可做的事、設定方式與近期動態（news/release）。
- 方法：
  - 本地資料夾遞迴檢索（含子資料夾）：目前工作目錄無可用文件（0 檔案）。
  - 網路研究：以官方來源為主（GitHub、官方 docs），第三方媒體只作補充並註記可信度。
- 時間基準：2026-02-27。

---

## 1) OpenClaw 是什麼（定位）

OpenClaw 是一個可自行託管（self-hosted）的個人 AI 助理平台。它的核心是一個長駐的 `Gateway`（控制平面），把多個聊天通道、工具系統、模型供應商、Web UI、CLI、行動節點（iOS/Android/macOS）串接在一起。

重點特性：

- 多通道訊息入口：WhatsApp、Telegram、Discord、Slack、Signal、iMessage、Microsoft Teams、WebChat 等。
- 多模型供應商：OpenAI、Anthropic、Google、OpenRouter、Ollama、vLLM、以及多種 gateway/provider。
- 工具驅動型 Agent：檔案、執行、瀏覽器、自動化、節點控制、session/subagent。
- 多 Agent 隔離：可做不同人格/用途/workspace，並以 routing 規則分流訊息。

---

## 2) 架構與系統設計（Structure）

### 2.1 核心元件

- `Gateway`：
  - 唯一長駐核心，維護通道連線、WS API、事件流與安全控制。
  - 預設綁定 `127.0.0.1:18789`，控制平面客戶端透過 WebSocket 存取。
- `Agent Runtime`：
  - 內嵌 runtime（衍生自 pi-mono），處理推理、工具調用、回覆與記憶注入。
- `Clients`：
  - CLI、Web 控制台、macOS App 等。
- `Nodes`：
  - iOS/Android/macOS/headless，透過同一 WS 協定掛入能力（camera/screen/location/run...）。

### 2.2 訊息與控制流程（概念）

1. 使用者從任一通道送入訊息。  
2. Gateway 做授權/路由，對應到目標 Agent 與 Session。  
3. Agent Runtime 執行模型推理與工具調用。  
4. 回覆經 Gateway 發送回原通道，並同步事件到 UI/CLI。  

### 2.3 多 Agent 路由邏輯

- `agents.list[]` 定義多個隔離 Agent（不同 workspace、agentDir、session store）。
- `bindings[]` 依 `channel/accountId/peer/guild/team` 等條件分流。
- 「最具體匹配優先」：peer > guild/team > account > channel > default agent。

---

## 3) AI 模型層（Model Layer）

### 3.1 模型引用與切換

- 基本格式：`provider/model`（例如 `openai/gpt-5.1-codex`、`anthropic/claude-opus-4-6`）。
- 可於 `agents.defaults.model.primary` 設主模型，並設定 `fallbacks` 做容錯。
- `agents.defaults.models` 可同時當「模型目錄」與 allowlist。

### 3.2 常見供應商（官方文件可見）

- OpenAI / OpenAI Codex（含 OAuth 模式）
- Anthropic
- Google（Gemini API key / 其他模式）
- OpenRouter / Vercel AI Gateway / 多種相容 provider
- Ollama（本地模型）
- vLLM（本地或自建相容 API）

### 3.3 供應商與金鑰策略

- 支援多把 key 輪替（遇 rate limit 類錯誤才切下一把）。
- 支援環境變數與 `${VAR_NAME}` 方式注入 config。
- 可設定 provider/model 層級參數（temperature、maxTokens、thinking、transport 等）。

---

## 4) Agent 與 Sub-Agents（Agents setup）

### 4.1 Agent workspace 與注入檔

OpenClaw 會把工作區內關鍵檔內容注入 Agent context（新 session 首輪）：

- `AGENTS.md`：操作規則/長期指令
- `SOUL.md`：人格與邊界
- `TOOLS.md`：工具使用偏好與規範
- `BOOTSTRAP.md`、`IDENTITY.md`、`USER.md` 等

### 4.2 Sub-agent 機制

- 可用 `sessions_spawn` 背景啟動子任務。
- 子代理在獨立 session 執行，完成後回報主對話。
- 可設定：
  - 預設模型/思考等級
  - 超時 `runTimeoutSeconds`
  - 並行上限 `maxConcurrent`
  - 最大嵌套深度 `maxSpawnDepth`
  - 每個 agent 可同時子任務數 `maxChildrenPerAgent`

### 4.3 何時用 Sub-agent

- 長任務平行處理（研究、爬資料、重度工具流程）
- 主對話不阻塞
- 以較便宜模型跑子任務，控制成本

---

## 5) 工具系統（What it could do）

OpenClaw 的工具不是「技能腳本拼接」，而是 typed tool（有 schema）的第一級能力。常見群組：

- `group:fs`：`read/write/edit/apply_patch`
- `group:runtime`：`exec/bash/process`
- `group:sessions`：`sessions_*`
- `group:web`：`web_search/web_fetch`
- `group:ui`：`browser/canvas`
- `group:automation`：`cron/gateway`
- `group:messaging`：`message`
- `group:nodes`：節點能力（相機/錄影/位置/通知/本地執行）

實際可做：

- 自動網頁操作與擷取（browser）
- 計畫性任務（cron/heartbeat/hooks）
- 跨 session 協作（subagents）
- 多平台消息互動（message tool）
- 與行動裝置/桌面節點整合（nodes/canvas）

---

## 6) 設定與部署（How to config）

### 6.1 最小可用配置（JSON5）

```json5
{
  agents: { defaults: { workspace: "~/.openclaw/workspace" } },
  channels: { whatsapp: { allowFrom: ["+15555550123"] } }
}
```

### 6.2 常用設定入口

- `openclaw onboard`：一站式 onboarding（推薦）
- `openclaw configure`：設定精靈
- `openclaw config get/set/unset ...`：逐鍵設定
- Web Control UI Config 分頁

### 6.3 安全與存取控制重點

- `dmPolicy`：`pairing | allowlist | open | disabled`
- `allowFrom`：允許名單
- `groupPolicy` / `groupAllowFrom`：群組存取
- `tools.allow/deny`、`tools.profile`：工具表面最小化
- `agents.defaults.sandbox`：非主 session 或全 session 沙箱化
- `gateway.auth` + pairing：裝置層與連線層雙重防護

### 6.4 Windows 10/11 建議部署

官方建議在 Windows 上用 **WSL2（Ubuntu）** 執行 CLI+Gateway（比原生穩定）。

關鍵步驟：

1. `wsl --install`  
2. 在 WSL 啟用 `systemd=true`  
3. 於 WSL 內安裝與執行 `openclaw onboard --install-daemon`  
4. 用 `openclaw gateway status`、`openclaw dashboard` 驗證  

---

## 7) 近期動態 / News（網路資料）

### 7.1 官方可驗證動態（高可信）

- GitHub Release 頻繁（例如 `v2026.2.23`、`v2026.2.25`、API 顯示到 `v2026.2.26`）。
- 近期更新主軸：
  - Android 互動與效能改進
  - Subagent 遞送/狀態機修正
  - 多通道穩定性與路由修補
  - 大量安全修補（auth、path、SSRF、webhook、approval 綁定等）
- 專案規模訊號：GitHub 約 233K stars（檢索當下）。

### 7.2 生態與作者消息（中高可信）

- 作者 Peter Steinberger 在個人站文章（2026-02-14）提到加入 OpenAI，並表示 OpenClaw 會朝 foundation、開源且獨立方向發展。

### 7.3 第三方媒體消息（需保留）

- 關於收購、投資與資金數字的新聞，來源分散、口徑可能不一致。
- 建議只把第三方內容視為「市場傳聞/觀察」，決策前回到官方公告與 repo release 驗證。

---

## 8) 企業/家辦視角評估（投資與導入）

### 8.1 優勢

- 開源且可自託管：資料主權與客製彈性高。
- 模型供應商中立：可按成本/法遵/延遲切換。
- 多通道與多 Agent：可覆蓋客服、內部協作、家辦流程分工。
- 工具與自動化完整：可做半自主流程（research、報告、通知、排程）。

### 8.2 風險

- 功能更新極快，設定複雜度提升。
- 錯誤配置（dmPolicy、allowFrom、gateway exposure）有資安外溢風險。
- 多通道 API 政策差異大，運維成本高。

### 8.3 導入建議（分階段）

1. **PoC（2-4 週）**：單通道 + 單 Agent + 嚴格 allowlist。  
2. **Pilot（4-8 週）**：加入第二通道與一個 subagent 流程。  
3. **Production**：多 Agent 路由、沙箱策略、監控與回溯、變更治理。  

---

## 9) 建議的初始配置藍圖（可直接改）

```json5
{
  gateway: {
    bind: "loopback",
    port: 18789
  },
  agents: {
    defaults: {
      workspace: "~/.openclaw/workspace",
      model: {
        primary: "anthropic/claude-sonnet-4-5",
        fallbacks: ["openai/gpt-5.2"]
      },
      sandbox: {
        mode: "non-main",
        scope: "agent"
      },
      subagents: {
        maxConcurrent: 4,
        maxSpawnDepth: 2,
        runTimeoutSeconds: 900
      }
    },
    list: [
      { id: "main", default: true, workspace: "~/.openclaw/workspace-main" },
      { id: "research", workspace: "~/.openclaw/workspace-research" }
    ]
  },
  tools: {
    profile: "coding",
    deny: ["gateway"],
    subagents: {
      tools: { deny: ["gateway", "cron"] }
    }
  },
  channels: {
    telegram: {
      enabled: true,
      dmPolicy: "pairing"
    }
  }
}
```

---

## 10) 結論（Executive Takeaway）

- OpenClaw 已具備「可自託管、多模型、多通道、可自動化」的完整 Agent 平台雛形，且 release 節奏快、功能面廣。
- 若你的目標是建立可控且可擴展的 AI 助理基礎設施，OpenClaw 有高可行性；但成功關鍵不在模型本身，而在：
  1) 存取控制設計  
  2) 沙箱/工具權限分層  
  3) 多 Agent 路由治理  
  4) 變更與安全運維機制  

---

## 11) 來源清單（本次研究使用）

### 官方 / 高可信

- GitHub Repo: https://github.com/openclaw/openclaw
- GitHub Releases:
  - https://github.com/openclaw/openclaw/releases/tag/v2026.2.23
  - https://github.com/openclaw/openclaw/releases/tag/v2026.2.25
  - https://api.github.com/repos/openclaw/openclaw/releases?per_page=5
- 官方文件入口: https://docs.openclaw.ai/llms.txt
- 主要文件頁：
  - https://docs.openclaw.ai/start/getting-started.md
  - https://docs.openclaw.ai/gateway/configuration.md
  - https://docs.openclaw.ai/gateway/configuration-reference.md
  - https://docs.openclaw.ai/concepts/architecture.md
  - https://docs.openclaw.ai/concepts/agent.md
  - https://docs.openclaw.ai/concepts/model-providers
  - https://docs.openclaw.ai/concepts/multi-agent.md
  - https://docs.openclaw.ai/tools/index.md
  - https://docs.openclaw.ai/tools/subagents.md
  - https://docs.openclaw.ai/platforms/windows.md

### 作者消息 / 中高可信

- https://steipete.me/posts/2026/openclaw

### 第三方新聞（僅補充觀察）

- https://decrypt.co/358129/openclaw-creator-offers-acquire-ai-sensation-stay-open-source
- https://finance.yahoo.com/news/openclaw-creator-gets-big-offers-200103606.html
- https://www.ainvest.com/news/openclaw-financial-fork-billion-dollar-offers-1m-community-funding-2602/

