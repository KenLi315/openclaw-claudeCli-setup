# image_creator 子代理 — OpenClaw 官方路徑設定指南

> 嚴格遵循 [OpenClaw 官方文件](https://docs.openclaw.ai)，避免路徑衝突導致 crash

---

## 一、官方路徑依據

### 1.1 官方預設與多代理 workspace

| 來源 | 路徑 | 說明 |
|------|------|------|
| [Agent Workspace](https://docs.openclaw.ai/concepts/agent-workspace) | `~/.openclaw/workspace` | 預設單一 workspace |
| [Multi-Agent Sandbox](https://docs.openclaw.ai/tools/multi-agent-sandbox-tools) | `~/.openclaw/workspace-{name}` | 每 agent 獨立 workspace 的官方範例 |
| [Configuration Reference](https://docs.openclaw.ai/gateway/configuration-reference) | `agents.defaults.workspace` | 預設 `~/.openclaw/workspace` |

### 1.2 Message 工具允許路徑（重要）

根據 [GitHub #16595](https://github.com/openclaw/openclaw/issues/16595)，message 工具的 `filePath` **僅允許**：

- `os.tmpdir()`（通常為 `/tmp/`）
- `~/.openclaw/media/`
- `~/.openclaw/agents/`

**Agent workspace 目錄（如 workspace-shared）不在預設允許清單內**，直接從 workspace 發送附件會失敗。

---

## 二、路徑衝突說明（先前設定問題）

| 衝突點 | 先前用法 | 問題 |
|--------|----------|------|
| 輸出目錄 | `workspace-shared/images/` | 不在 message 允許清單，發送前需額外複製 |
| 輸入目錄 | `workspace-shared/input/` | 與單一 workspace 範例混用 |
| 腳本預設 | `generate_image.mjs` 硬編碼 `/home/node/.openclaw/workspace/images` | Zeabur 專用、單一 workspace，與多代理不符 |
| 混用符號 | `~` 與 `/home/node/` 混用 | 不同環境展開不一致 |

---

## 三、官方對齊的推薦設定

### 3.1 使用 `~/.openclaw/media/` 作為共享目錄

`media/` 在 message 允許清單內，可直接發送，無需複製到 `/tmp/`。

| 用途 | 官方對齊路徑 | 說明 |
|------|--------------|------|
| 圖片輸入（主→子） | `~/.openclaw/media/input/` | 主代理複製待處理圖到此 |
| 圖片輸出（子→主） | `~/.openclaw/media/images/` | image_creator 輸出，主代理可直接發送 |
| image_creator workspace | `~/.openclaw/workspace-image-creator` | 遵循 `workspace-{agentId}` 官方範例 |

### 3.2 openclaw.json 設定

```json
{
  "agents": {
    "list": [
      {
        "id": "image_creator",
        "name": "圖片生成子代理",
        "workspace": "~/.openclaw/workspace-image-creator",
        "sandbox": { "mode": "non-main" }
      }
    ]
  }
}
```

---

## 四、逐步設定步驟

### Step 1：建立目錄（僅用官方路徑）

```bash
# 主代理與子代理 workspace（官方範例格式）
mkdir -p ~/.openclaw/workspace-main
mkdir -p ~/.openclaw/workspace-research
mkdir -p ~/.openclaw/workspace-image-creator

# 共享目錄：使用 media/（在 message 允許清單內）
mkdir -p ~/.openclaw/media/input
mkdir -p ~/.openclaw/media/images
```

**Zeabur**：若 `~` 為 `/home/node`，則實際路徑為 `/home/node/.openclaw/...`。建議在 `openclaw.json` 中統一使用 `~/.openclaw/`，由 OpenClaw 解析。

### Step 2：設定環境變數

```bash
# 圖片輸出目錄（供 generate_image.mjs 使用）
export IMAGE_OUTPUT_DIR="$HOME/.openclaw/media/images"
export IMAGE_INPUT_DIR="$HOME/.openclaw/media/input"

# 或 Zeabur 環境變數：
# IMAGE_OUTPUT_DIR=/home/node/.openclaw/media/images
# IMAGE_INPUT_DIR=/home/node/.openclaw/media/input
```

### Step 3：複製 AGENTS.md 到 image_creator workspace

```bash
# 使用官方對齊的 AGENTS.md（見下方範本）
cp templates/workspace-image-creator/AGENTS.md ~/.openclaw/workspace-image-creator/
```

### Step 4：安裝 gemini-image-gen skill

將 skill 放到 `~/.openclaw/skills/gemini-image-gen/`，並設定 `GOOGLE_API_KEY`。

### Step 5：更新主代理 AGENTS.md

主代理需：

1. 將待處理圖片複製到 `~/.openclaw/media/input/`
2. 在 `sessions_spawn` 的 task 中指定該路徑
3. 收到 announce 後，從 `~/.openclaw/media/images/` 直接以 message 發送（無需再複製到 `/tmp/`）

---

## 五、image_creator AGENTS.md 範本（官方路徑）

```markdown
# 圖片子代理 — 操作規範

你是專職圖片生成與修改的子代理。你的 workspace 為 `~/.openclaw/workspace-image-creator`。

## 路徑規範（OpenClaw 官方）

- **輸入**：`~/.openclaw/media/input/`（主代理會先將待處理圖片放於此）
- **輸出**：`~/.openclaw/media/images/`（此路徑在 message 工具允許清單內，主代理可直接發送）

## 圖片生成（text-to-image）

node ~/.openclaw/skills/gemini-image-gen/scripts/generate_image.mjs \
  --prompt "你的提示詞" \
  --filename "~/.openclaw/media/images/輸出檔名.png"

## 圖片修改（image-to-image）

node ~/.openclaw/skills/gemini-image-gen/scripts/generate_image.mjs \
  --prompt "修改描述，保留主體" \
  --input-image "~/.openclaw/media/input/原圖.png" \
  --filename "~/.openclaw/media/images/輸出.png"

## 關鍵原則

- **保留主體**：若主代理要求保留特定主體或元素，修改時不可簡化或刪減
- **產出路徑**：務必回傳完整的輸出檔案路徑，供主代理驗收

## 禁止

- 呼叫 `sessions_spawn`
- 將輸出寫入主代理的 workspace（`workspace-main`）
```

---

## 六、主代理 AGENTS.md 檔案傳遞區段（官方路徑）

```markdown
## 三、檔案傳遞（圖片修改任務）

子代理無法存取主代理 workspace。若任務需「修改既有圖片」：

1. 先將原圖複製到官方 media 目錄：
   cp <原圖路徑> ~/.openclaw/media/input/

2. 在 sessions_spawn 的 task 中明確指定：
   請修改圖片：~/.openclaw/media/input/<檔名>
   要求：保留原有主體，僅替換背景為 XXX
   輸出至：~/.openclaw/media/images/

## 五、發送圖片（message 工具）

~/.openclaw/media/images/ 在 message 工具允許清單內，可直接使用：
message 工具的 filePath: "~/.openclaw/media/images/<檔名>"

若環境中 ~ 未正確展開，可使用絕對路徑，例如：
/home/node/.openclaw/media/images/<檔名>
```

---

## 七、generate_image.mjs 路徑處理

腳本應支援 `IMAGE_OUTPUT_DIR` 環境變數，預設使用官方 media 路徑：

```javascript
// 建議：使用環境變數，預設為官方 media 路徑
const stateDir = process.env.OPENCLAW_STATE_DIR || 
  (process.env.HOME ? `${process.env.HOME}/.openclaw` : '/home/node/.openclaw');
const DEFAULT_DIR = process.env.IMAGE_OUTPUT_DIR || `${stateDir}/media/images`;
```

或由呼叫端一律傳入 `--filename`，不依賴腳本預設路徑。

---

## 八、驗證

```bash
# 檢查 agent 列表
openclaw agents list --bindings

# 檢查目錄
ls -la ~/.openclaw/media/input/
ls -la ~/.openclaw/media/images/
ls -la ~/.openclaw/workspace-image-creator/
```

---

## 九、路徑對照總表

| 項目 | 官方對齊路徑 |
|------|--------------|
| image_creator workspace | `~/.openclaw/workspace-image-creator` |
| 圖片輸入 | `~/.openclaw/media/input/` |
| 圖片輸出 | `~/.openclaw/media/images/` |
| message 發送 | 直接使用 `~/.openclaw/media/images/<檔名>` |
| skills 目錄 | `~/.openclaw/skills/gemini-image-gen/` |

---

## 十、參考

- [Agent Workspace](https://docs.openclaw.ai/concepts/agent-workspace)
- [Multi-Agent Sandbox & Tools](https://docs.openclaw.ai/tools/multi-agent-sandbox-tools)
- [Sub-Agents](https://docs.openclaw.ai/tools/subagents)
- [Message tool media paths (GitHub #16595)](https://github.com/openclaw/openclaw/issues/16595)
