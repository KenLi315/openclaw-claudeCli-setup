---
name: restore-setting-from-github
description: Restore OpenClaw config from the latest GitHub backup. Use when user says "restore setting from Github", "還原設定", "reset setting", or "從備份還原". Requires GITHUB_TOKEN and GITHUB_BACKUP_REPO.
metadata:
  openclaw:
    requires:
      env: ["GITHUB_TOKEN", "GITHUB_BACKUP_REPO"]
---

# Restore Setting from Github

從 GitHub 下載最新備份並還原 OpenClaw 設定與 skills。

## 還原內容

- **openclaw.json**：主設定檔
- **Workspaces**：AGENTS.md、SOUL.md、MEMORY.md、USER.md、memory/*.md
- **Skills**：所有備份的 skills（來自最新 `skills-backup-*.tar.gz`）

## When to Use

- 用戶說「restore setting from Github」「還原設定」「reset setting」「從備份還原」

## Workflow

1. **執行還原腳本**（使用 `exec` 工具）：
   ```bash
   bash {baseDir}/scripts/restore-from-github.sh
   ```

2. **從輸出取得備份檔名**：
   - `RESTORED_FROM=backup-YYYYMMDD_HHMMSS.tar.gz`（設定）
   - `RESTORED_SKILLS_FROM=skills-backup-YYYYMMDD_HHMMSS.tar.gz`（skills，若有）

3. **通知用戶**（必須包含以下內容）：
   - 設定與 skills 已還原
   - 還原來源檔名
   - 請在 Zeabur 控制台執行 Redeploy 或 Restart 以載入新設定

## 通知範例

成功時回覆：

```
✅ 設定與 skills 已從 GitHub 還原完成。

**設定來源**：backup-20260305_181103.tar.gz
**Skills 來源**：skills-backup-20260305_191500.tar.gz

請在 Zeabur 控制台執行 Redeploy 或 Restart，以載入新設定。
```

失敗時（無 token、無備份、腳本錯誤）：說明原因並建議檢查 `GITHUB_TOKEN`、`GITHUB_BACKUP_REPO` 環境變數。
