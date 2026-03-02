# Claude CLI 與 OpenClaw 監控指南

## 一、Skill 模式（已設定）

主代理使用 **claude-cli-coding** Skill 處理程式碼任務：

- **非阻塞**：`nohup claude -p "..." &` 後立即回覆「已分派，執行中」
- **完成通知**：Claude 的 Stop 或 TaskCompleted Hook 觸發 `openclaw system event`，主代理被喚醒

### 用戶可這樣說

```
請寫一個象棋小遊戲，可以在瀏覽器開啟並遊玩
```

主代理會：調用 Skill → 背景執行 claude → 立即回覆「已分派」→ 被 Hook 喚醒 → 讀取輸出並回覆。

---

## 二、監控 Claude CLI 與 OpenClaw 的溝通

### 方式 1：Zeabur 服務日誌

| 服務 | 查看內容 |
|------|----------|
| **openclaw-claudecli-setup** | Gateway 活動、agent 執行、exec 呼叫 |
| **claude-code-proxy** | API 請求、模型呼叫、錯誤 |

在 Zeabur 點選服務 → **記錄 (Logs)** 即可查看。

### 方式 2：Claude 輸出檔案

Skill 將 claude 的 stdout/stderr 寫入 `/tmp/claude-coding-output.txt`，可手動查看：

```bash
cat /tmp/claude-coding-output.txt
```

### 方式 3：在容器內手動監控

```bash
# 查看 Claude 相關行程
ps aux | grep claude

# 即時執行並看 verbose（手動測試用）
claude -p "你的任務" --verbose
```

---

## 三、架構摘要

```
用戶 (Telegram)
    ↓
主代理 (main) + claude-cli-coding Skill
    ↓ nohup claude -p "..." &
主代理：立即回覆「已分派」
    ↓
claude-code-proxy (OpenRouter/MiniMax)
    ↓
完成 → Stop hook 或 TaskCompleted hook
    → openclaw system event --mode now
    → 主代理喚醒 → 讀取 /tmp/claude-coding-output.txt → 回覆用戶
```

---

## 四、完整設定

請參考 `Claude_CLI_Skill_Setup_Guide.md` 逐步設定。
