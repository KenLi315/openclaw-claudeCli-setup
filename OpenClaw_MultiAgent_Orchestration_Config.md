# OpenClaw 多代理編排架構配置指南

> 對應目標：主 agent 定義步驟 → 分派 subagent → 驗收與重試（最多 3 次）→ 綜合回覆

---

## 一、架構對照表

| 您的步驟 | OpenClaw 對應機制 | 配置/實作方式 |
|---------|------------------|---------------|
| 1. 主 agent 定義工作步驟 | 主 agent 推理 + 指令 | 透過 SOUL.md / AGENTS.md 規範行為 |
| 2. 依 subagent 專長分派任務 | `sessions_spawn` + `agents_list` | 配置 `agents.list[]`，每 agent 有獨立 workspace、model、tools |
| 3. Sub agent 自行思考與執行 | 獨立 session (`agent::subagent:`) | 預設行為，可設 `thinking`、`model` |
| 4. 任務結果發給主 agent | **Announce 機制** | 子代理完成後自動回報到主對話 |
| 5. 主 agent 驗收、重試（最多 3 次） | **無內建迴圈** | 需在主 agent 的 AGENTS.md 中明訂驗收邏輯與重試規則 |
| 6. 主 agent 綜合回覆用戶 | 主 agent 彙整 announce 結果 | 需在 AGENTS.md 中規範「收到結果後再回覆」流程 |

---

## 二、核心配置（openclaw.json / config.json5）

### 2.1 多 Agent 定義（agents.list）

每個 agent 可擁有：
- **獨立 workspace**：檔案隔離
- **專用 model**：可覆寫 `agents.defaults.model`
- **專屬工具權限**：`tools.allow` / `tools.deny`
- **沙箱設定**：`sandbox.mode`（`off` | `non-main` | `all`）

```json5
{
  agents: {
    defaults: {
      workspace: "~/.openclaw/workspace",
      model: {
        primary: "anthropic/claude-sonnet-4-5",
        fallbacks: ["anthropic/claude-opus-4-6"]
      },
      subagents: {
        maxSpawnDepth: 2,        // 允許 orchestrator → worker 兩層（預設 1）
        maxChildrenPerAgent: 5,  // 每 session 最多 5 個子任務
        maxConcurrent: 8,        // 全域 subagent 並行上限
        runTimeoutSeconds: 900, // 子任務超時（秒）
        archiveAfterMinutes: 60 // 完成後多久歸檔
      }
    },
    list: [
      {
        id: "main",
        default: true,
        name: "主代理（協調者）",
        workspace: "~/.openclaw/workspace-main",
        sandbox: { mode: "off" }
      },
      {
        id: "research",
        name: "研究子代理",
        workspace: "~/.openclaw/workspace-research",
        model: { primary: "anthropic/claude-sonnet-4-5" },
        tools: { allow: ["read", "web_search", "web_fetch"], deny: ["exec", "gateway"] }
      },
      {
        id: "image_creator",
        name: "圖片生成子代理",
        workspace: "~/.openclaw/workspace-images",
        model: { primary: "openai/gpt-4o" },
        tools: { allow: ["read", "write", "exec"], deny: ["gateway", "cron"] }
      }
    ]
  }
}
```

### 2.2 Subagent 專用設定（agents.defaults.subagents）

| 參數 | 說明 | 建議值 |
|------|------|--------|
| `maxSpawnDepth` | 嵌套深度（1=僅主→子，2=主→協調→工人） | `2` 若需 orchestrator 模式 |
| `maxChildrenPerAgent` | 每 session 同時子任務數 | `5`（範圍 1–20） |
| `maxConcurrent` | 全域 subagent 並行數 | `8` |
| `runTimeoutSeconds` | 子任務超時 | `900`（15 分鐘） |
| `archiveAfterMinutes` | 完成後歸檔時間 | `60` |

### 2.3 子代理模型與成本優化

主代理用高階模型，子代理可用較便宜模型：

```json5
{
  agents: {
    defaults: {
      subagents: {
        model: "anthropic/claude-sonnet-4-5",  // 子代理預設模型
        thinking: "low"
      }
    }
  }
}
```

或 per-agent 覆寫：

```json5
{
  agents: {
    list: [
      { id: "research", subagents: { model: "openai/gpt-4o-mini" } },
      { id: "image_creator", subagents: { model: "openai/gpt-4o" } }
    ]
  }
}
```

---

## 三、sessions_spawn 工具參數

| 參數 | 必填 | 說明 |
|------|------|------|
| `task` | ✅ | 給子代理的指令（等同 `instruction`） |
| `model` | ❌ | 覆寫此次子任務的模型 |
| `thinking` | ❌ | 覆寫思考等級 |
| `agentId` | ❌ | 指定目標 agent（需在 `allowAgents` 內） |
| `runTimeoutSeconds` | ❌ | 此次任務超時 |
| `cleanup` | ❌ | `delete` \| `keep`（預設 `keep`） |
| `mode` | ❌ | `run`（單次）\| `session`（持久，需 `thread: true`） |
| `thread` | ❌ | 是否綁定 thread（Discord 等支援） |
| `label` | ❌ | 日誌/UI 標籤 |

**重要**：`sessions_spawn` 為 **非阻塞**，立即回傳 `{ status: "accepted", runId, childSessionKey }`，子代理完成後透過 **announce** 將結果送回主對話。

---

## 四、agents_list 工具

用於查詢可被 `sessions_spawn` 分派的 agent id 清單：

- 主代理呼叫 `agents_list` 取得可用 agent
- 依任務類型選擇對應 agent，再呼叫 `sessions_spawn` 並指定 `agentId`

---

## 五、驗收與重試（需在 AGENTS.md 中實作）

OpenClaw **沒有內建**「驗收失敗則重試最多 3 次」的迴圈，需在主代理的指令中明確規範。

### 5.1 建議的 AGENTS.md 片段

```markdown
## 任務編排與驗收流程

1. **意圖確認**：若用戶問「如何執行」或「步驟」，只說明流程，不執行；若明確要求執行，才開始。
2. **任務分解**：將複雜任務拆成子任務，對應到合適的 subagent（使用 agents_list 查詢可用 agent）。
3. **分派**：使用 sessions_spawn 將每個子任務分派給對應 agent，指令需包含：
   - 明確產出格式
   - 驗收標準（例如：圖片須包含指定主體、背景須符合要求）
4. **驗收**：收到子代理的 announce 結果後，必須逐項檢查是否符合驗收標準。
5. **重試**：若不符合，帶著修正指令重新分派，最多重試 3 次；超過 3 次則向用戶說明失敗原因。
6. **綜合回覆**：所有子任務驗收通過後，再整合結果回覆用戶。
```

### 5.2 驗收檢查清單範例（圖片修改任務）

- [ ] 主體是否保留（數量、構圖）
- [ ] 背景是否正確替換（例如：巴黎鐵塔）
- [ ] 產出檔案路徑是否可存取

---

## 六、Workspace 隔離與檔案傳遞

**重要**：每個 agent 有獨立 workspace，子代理 **無法直接存取主代理 workspace 的檔案**。

您遇到的 `ENOENT: no such file or directory, open '/home/node/.openclaw/workspace-main/french_bulldogs_hong_kong_coliseum.png'` 即因此產生。

### 6.1 解決方案

1. **共用目錄**：將需傳遞的檔案放在子代理 workspace 可讀取的路徑，或在主代理指令中明確寫入子代理 workspace 的路徑。
2. **在指令中嵌入內容**：若為圖片，可考慮 base64 或 URL；若為文字，直接寫在 `task` 內。
3. **掛載共享 volume**：若使用 Docker 沙箱，可設定 `sandbox.docker` 的 volume 掛載，讓主/子 workspace 共享某目錄。

範例（共享目錄思路）：

```json5
{
  agents: {
    list: [
      { id: "main", workspace: "~/.openclaw/workspace-main" },
      { id: "image_creator", workspace: "~/.openclaw/workspace-shared" }
    ]
  }
}
```

或使用符號連結 / 複製到共享目錄後再分派。

---

## 七、完整配置範例（對應您的六步架構）

```json5
{
  gateway: { bind: "loopback", port: 18789 },
  agents: {
    defaults: {
      workspace: "~/.openclaw/workspace",
      model: {
        primary: "anthropic/claude-sonnet-4-5",
        fallbacks: ["anthropic/claude-opus-4-6"]
      },
      subagents: {
        maxSpawnDepth: 2,
        maxChildrenPerAgent: 5,
        maxConcurrent: 8,
        runTimeoutSeconds: 900,
        archiveAfterMinutes: 60,
        model: "anthropic/claude-sonnet-4-5",
        thinking: "low"
      },
      sandbox: { mode: "non-main", scope: "agent" }
    },
    list: [
      {
        id: "main",
        default: true,
        name: "主代理",
        workspace: "~/.openclaw/workspace-main",
        sandbox: { mode: "off" }
      },
      {
        id: "research",
        name: "研究子代理",
        workspace: "~/.openclaw/workspace-research",
        subagents: { allowAgents: ["main"] }
      },
      {
        id: "image_creator",
        name: "圖片子代理",
        workspace: "~/.openclaw/workspace-images",
        subagents: { allowAgents: ["main"] }
      }
    ]
  },
  tools: {
    profile: "coding",
    subagents: {
      tools: {
        deny: ["gateway", "cron"]
      }
    }
  }
}
```

---

## 八、主代理 SOUL.md / AGENTS.md 建議內容

在 `~/.openclaw/workspace-main/` 或主 agent 的 workspace 中建立：

### AGENTS.md（任務編排規則）

```markdown
# 任務編排與驗收協議

## 意圖分流
- 用戶問「如何執行」「步驟是什麼」→ 只說明流程，不執行
- 用戶明確說「請執行」「幫我做」→ 開始執行

## 分派前
1. 使用 agents_list 確認可用 subagent
2. 依任務類型選擇 agent（研究→research，圖片→image_creator）
3. 指令須包含：產出格式、驗收標準、必要時包含檔案路徑（須為該 agent workspace 內可存取路徑）

## 驗收與重試
1. 收到 announce 後，依驗收標準逐項檢查
2. 不符則重派，附上明確修正指令，最多 3 次
3. 超過 3 次則向用戶說明失敗原因與建議

## 檔案傳遞
- 子代理無法存取主代理 workspace
- 需修改的圖片/檔案：先複製到共享路徑或子代理 workspace，再在 task 中指定該路徑
```

---

## 九、參考來源

| 主題 | 連結 |
|------|------|
| Sub-Agents 官方文件 | https://docs.openclaw.ai/tools/subagents |
| Multi-Agent Sandbox & Tools | https://docs.openclaw.ai/tools/multi-agent-sandbox-tools |
| Session Tools | https://docs.openclaw.ai/concepts/session-tool |
| Multi-Agent 架構最佳實踐 | https://www.getopenclaw.ai/help/multi-agent-architecture |
| Configuration Examples | https://docs.openclaw.ai/gateway/configuration-examples |
| Learn OpenClaw Sub-Agents | https://learnopenclaw.com/advanced/sub-agents |

---

## 十、總結

| 項目 | 狀態 |
|------|------|
| 主 agent 定義步驟 | ✅ 透過 SOUL/AGENTS 規範 |
| 依專長分派 subagent | ✅ agents.list + sessions_spawn + agents_list |
| 獨立 workspace / model / 上下文 | ✅ 每 agent 獨立配置 |
| 結果回報主 agent | ✅ 內建 announce 機制 |
| 驗收與重試（最多 3 次） | ⚠️ 需在 AGENTS.md 中明訂，無內建迴圈 |
| 跨 workspace 檔案存取 | ⚠️ 需自行設計共享路徑或複製策略 |
