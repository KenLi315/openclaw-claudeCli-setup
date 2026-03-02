# Claude CLI Coding Skill — 逐步設定指南

> 將 Claude CLI 整合為 **Skill** 給主代理使用，搭配 **Stop + TaskCompleted** Hook 完成時通知主代理。

---

## 架構概覽

```
用戶：「寫象棋遊戲」
    ↓
主代理：調用 claude-cli-coding Skill
    ↓ nohup claude -p "..." &
主代理：立即回覆「已分派，完成後會通知您」
    ↓
Claude 在背景執行
    ↓
完成 → Stop 或 TaskCompleted Hook → openclaw system event --mode now
    ↓
主代理被喚醒 → 讀取 /tmp/claude-coding-output.txt → 回覆用戶
```

---

## Step 1：安裝 Skill

在 OpenClaw 容器內執行（或 Zeabur 終端）：

```bash
# 建立 skill 目錄
mkdir -p ~/.openclaw/skills/claude-cli-coding

# 複製 SKILL.md（依實際路徑調整；若從 GitHub 部署，專案可能為 /app 或當前目錄）
cp /app/claude-cli-coding-skill/SKILL.md ~/.openclaw/skills/claude-cli-coding/ 2>/dev/null || \
cp claude-cli-coding-skill/SKILL.md ~/.openclaw/skills/claude-cli-coding/ 2>/dev/null || \
cp ./claude-cli-coding-skill/SKILL.md ~/.openclaw/skills/claude-cli-coding/

# 確認
ls -la ~/.openclaw/skills/claude-cli-coding/
```

---

## Step 2：設定 Claude Hooks（Stop + TaskCompleted）

Hooks 需寫入 `~/.claude/settings.json`，讓 Claude 完成時觸發通知。

### 2a. 若 ~/.claude/settings.json 不存在

```bash
mkdir -p ~/.claude
cp /app/claude-cli-coding-skill/claude-hooks-settings.json ~/.claude/settings.json 2>/dev/null || \
cp claude-cli-coding-skill/claude-hooks-settings.json ~/.claude/settings.json
```

### 2b. 若 ~/.claude/settings.json 已存在

需**合併** hooks，不要直接覆蓋。手動編輯：

```bash
# 查看現有內容
cat ~/.claude/settings.json

# 編輯並加入 hooks 區塊（若已有 hooks，在現有 hooks 內加入 Stop 與 TaskCompleted）
nano ~/.claude/settings.json
```

加入或合併以下內容：

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "openclaw system event --text 'Claude CLI 任務已完成' --mode now"
          }
        ]
      }
    ],
    "TaskCompleted": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "openclaw system event --text 'Claude CLI 任務已完成' --mode now"
          }
        ]
      }
    ]
  }
}
```

---

## Step 3：確認 Claude 登入繞過（proxy 模式）

```bash
# 若尚未設定
echo '{"hasCompletedOnboarding": true}' > ~/.claude.json
```

---

## Step 4：確認環境變數

主代理需有：

| 變數 | 值 |
|------|-----|
| `ANTHROPIC_BASE_URL` | `http://ghcrio1rgsclaude-code-proxylatest-pa.zeabur.internal:8082` |

（依實際 claude-code-proxy 內網主機名稱調整）

---

## Step 5：更新主代理 AGENTS.md

使用已更新的 `templates/workspace-main/AGENTS.md`，確保主代理會調用 claude-cli-coding Skill 處理編碼任務。

```bash
cp templates/workspace-main/AGENTS.md ~/.openclaw/workspace-main/
```

---

## Step 6：重新載入 Skills

- 重啟 OpenClaw 服務，或
- 對主代理說：「請 refresh skills」/「重新載入 skills」

---

## 驗證

1. 對主代理說：「請寫一個簡單的 Python 函數計算費氏數列前 5 項」
2. 預期：主代理立即回覆「已分派給 Claude CLI...」
3. 等待數十秒後，主代理應被喚醒並回覆結果

---

## 故障排除

| 問題 | 檢查 |
|------|------|
| 主代理未使用 Skill | 確認 `~/.openclaw/skills/claude-cli-coding/SKILL.md` 存在 |
| Claude 完成後無通知 | 確認 `~/.claude/settings.json` 含 Stop 與 TaskCompleted hooks |
| openclaw system event 找不到 | 確認在 OpenClaw 容器內執行，openclaw CLI 已安裝 |
| 輸出為空 | 檢查 `/tmp/claude-coding-output.txt` 是否存在 |
