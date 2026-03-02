# OpenClaw 多代理架構 — 逐步設定指南

> 從零開始建立主代理 + 子代理，含驗收與重試流程

---

## 前置需求

- OpenClaw 已安裝（`openclaw --version` 可執行）
- Gateway 可啟動（`openclaw gateway status`）
- 至少一個模型供應商已設定（Anthropic / OpenAI / 其他）
- 至少一個通道已設定（Telegram / Discord / WhatsApp 等）

---

## Step 1：備份現有設定（若有）

```bash
# 備份 config
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak 2>/dev/null || true

# 備份 workspace（若有）
cp -r ~/.openclaw/workspace ~/.openclaw/workspace.bak 2>/dev/null || true
```

---

## Step 2：建立目錄結構

在 **Gateway 所在機器**（例如 Zeabur 為 `/home/node/`）執行：

```bash
# 建立各 agent workspace（OpenClaw 官方路徑）
mkdir -p ~/.openclaw/workspace-main
mkdir -p ~/.openclaw/workspace-research
mkdir -p ~/.openclaw/workspace-image-creator
mkdir -p ~/.openclaw/media/input
mkdir -p ~/.openclaw/media/images
```

**目錄用途**（對應 openclaw.json agents.list）：

| 目錄 | 用途 |
|------|------|
| `workspace-main` | 主代理（協調者）的 workspace |
| `workspace-research` | 研究子代理的 workspace |
| `workspace-image-creator` | 圖片子代理 workspace |
| `media/input` | 圖片輸入（主→子），message 工具允許路徑 |
| `media/images` | 圖片輸出（子→主），message 工具允許路徑 |

---

## Step 3：寫入 OpenClaw 設定檔

將 `templates/openclaw.json` 複製到 `~/.openclaw/openclaw.json`，或**合併** `agents` 與 `tools` 區塊到您現有設定。

**重要**：請依您的環境調整：
- `workspace` 路徑（Zeabur 可能為 `/home/node/.openclaw/...`）
- `model.primary` 與 `fallbacks`（依您有的 API key）
- `channels`：若您已有通道設定，請保留並合併，勿覆蓋

---

## Step 4：建立主代理 workspace 檔案

將以下檔案放入 `~/.openclaw/workspace-main/`：

| 檔案 | 用途 |
|------|------|
| `SOUL.md` | 人格、語氣、邊界 |
| `AGENTS.md` | 任務編排、驗收、重試規則 |
| `USER.md` | 用戶資訊（可選） |

模板已放在 `templates/workspace-main/`，複製過去即可：

```bash
cp templates/workspace-main/SOUL.md ~/.openclaw/workspace-main/
cp templates/workspace-main/AGENTS.md ~/.openclaw/workspace-main/
cp templates/workspace-main/USER.md ~/.openclaw/workspace-main/
```

---

## Step 5：建立子代理 workspace 檔案

子代理只會注入 `AGENTS.md` 與 `TOOLS.md`（無 SOUL.md）。

### 5a. 研究子代理

```bash
cp templates/workspace-research/AGENTS.md ~/.openclaw/workspace-research/
```

### 5b. 圖片子代理（使用 workspace-image-creator + media）

```bash
cp templates/workspace-image-creator/AGENTS.md ~/.openclaw/workspace-image-creator/
```

圖片子代理的 workspace 為 `workspace-image-creator`。圖片傳遞使用 `~/.openclaw/media/`（message 工具允許路徑）。

若您使用 gemini-image-gen skill，請確認 skill 已安裝於 `~/.openclaw/skills/gemini-image-gen/`，並設定 `GOOGLE_API_KEY`。

---

## Step 6：設定共享目錄（檔案傳遞）

當主代理需要「修改既有圖片」時，流程為：

1. 主代理將原圖複製到 `~/.openclaw/media/input/`（message 工具允許路徑）
2. 主代理在 `sessions_spawn` 的 `task` 中指定該路徑
3. image_creator 讀取並輸出至 `~/.openclaw/media/images/`，主代理可直接發送

**config 中已將 image_creator 的 workspace 設為 `workspace-image-creator`**，主代理需在分派前執行：

```bash
cp /path/to/original.png ~/.openclaw/media/input/
```

（主代理可透過 `exec` 或 `write` 完成，AGENTS.md 已規範此流程。）

---

## Step 7：重啟 Gateway

```bash
openclaw gateway restart
```

或於 Zeabur 上重新部署服務。

---

## Step 8：驗證設定

### 8.1 檢查 agent 列表

```bash
openclaw agents list --bindings
```

應看到 `main`、`research`、`image_creator`。

### 8.2 測試主代理

透過您設定的通道（如 Telegram）發送：

```
你好，請說明你會如何執行「搜尋今天重點新聞並製作一張圖文並茂的圖片」？
```

預期：主代理只說明步驟，**不執行**（意圖分流測試）。

### 8.3 測試執行流程

發送：

```
請執行：搜尋某主題並製作一張相關圖片。
```

預期：主代理分派給 research 與 image_creator，收到結果後驗收並回覆。

---

## Step 9：故障排除

| 問題 | 可能原因 | 解法 |
|------|----------|------|
| 子代理找不到檔案 | workspace 隔離 | 確認檔案已複製到 `media/input/`，且 task 中路徑正確 |
| 主代理直接執行不說明 | AGENTS.md 未生效 | 確認 `workspace-main/AGENTS.md` 存在且 Gateway 已重啟 |
| 驗收未觸發重試 | 主代理未檢查結果 | 強化 AGENTS.md 中的驗收檢查清單 |
| `agents_list` 回傳空 | 未設定 `agents.list` | 檢查 `openclaw.json` 的 `agents.list` |

---

## 檔案清單總覽

```
~/.openclaw/
├── openclaw.json              # 主設定（Step 3）
├── workspace-main/            # 主代理
│   ├── SOUL.md
│   ├── AGENTS.md
│   └── USER.md
├── workspace-research/        # 研究子代理
│   └── AGENTS.md
├── workspace-image-creator/   # 圖片子代理 workspace
│   └── AGENTS.md
└── media/                     # message 工具允許路徑
    ├── input/                 # 主代理放入待處理圖片
    └── images/                # 圖片子代理輸出
```

---

## 下一步

- 依需求調整 `AGENTS.md` 的驗收標準
- 新增更多子代理（如 `writing`、`code_review`）於 `agents.list`
- 設定 `memory/` 與 `MEMORY.md` 以強化長期記憶

---

## 附錄：Zeabur / 遠端部署

若 OpenClaw 運行於 Zeabur 或遠端主機：

1. 將本專案 `templates/` 與 `openclaw_setup/` 上傳至伺服器，或透過 Git 拉取
2. 在伺服器上執行 Step 2 的 `mkdir` 指令
3. 使用**絕對路徑**複製模板，例如：
   ```bash
   # 假設專案在 /app/openclaw_setup
   cp /app/openclaw_setup/templates/openclaw.json /home/node/.openclaw/openclaw.json
   cp /app/openclaw_setup/templates/workspace-main/* /home/node/.openclaw/workspace-main/
   cp /app/openclaw_setup/templates/workspace-research/AGENTS.md /home/node/.openclaw/workspace-research/
   cp /app/openclaw_setup/templates/workspace-image-creator/AGENTS.md /home/node/.openclaw/workspace-image-creator/
   mkdir -p /home/node/.openclaw/media/input /home/node/.openclaw/media/images
   ```
4. 確認 `openclaw.json` 中的路徑為 `/home/node/.openclaw/...`（Zeabur 常見）
