#!/bin/bash
# 在 Zeabur Terminal 執行此腳本，修復 restore-setting-from-github Skill
# 用法：若專案在 /app，執行：bash /app/scripts/fix_restore_skill_in_zeabur.sh
# 或複製整段到 Zeabur Terminal 貼上執行

set -e

SKILL_DIR="${1:-$HOME/.openclaw/skills/restore-setting-from-github}"
mkdir -p "$SKILL_DIR/scripts"

# 寫入 SKILL.md（從 restore-setting-from-github/SKILL.md 同步）
cp "$(dirname "$0")/../restore-setting-from-github/SKILL.md" "$SKILL_DIR/SKILL.md" 2>/dev/null || true
if [ ! -s "$SKILL_DIR/SKILL.md" ]; then
  cat > "$SKILL_DIR/SKILL.md" << 'SKILLEOF'
---
name: restore-setting-from-github
description: Restore OpenClaw config and skills from the latest GitHub backup.
metadata:
  openclaw:
    requires:
      env: ["GITHUB_TOKEN", "GITHUB_BACKUP_REPO"]
---

# Restore Setting from Github

從 GitHub 下載最新備份並還原 OpenClaw 設定與 skills。還原：openclaw.json、workspaces（AGENTS.md、SOUL.md、MEMORY.md、USER.md）、skills。
SKILLEOF
fi

# 寫入 restore-from-github.sh（從 restore-setting-from-github/scripts/ 同步）
cp "$(dirname "$0")/../restore-setting-from-github/scripts/restore-from-github.sh" "$SKILL_DIR/scripts/restore-from-github.sh" 2>/dev/null || true
if [ ! -s "$SKILL_DIR/scripts/restore-from-github.sh" ]; then
  cat > "$SKILL_DIR/scripts/restore-from-github.sh" << 'SCRIPTEOF'
#!/bin/bash
# 從 GitHub 還原 OpenClaw 最新備份（設定 + skills）
set -e
REPO="${GITHUB_BACKUP_REPO:-}"
TOKEN="${GITHUB_TOKEN:-}"
OPENCLAW_ROOT="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
BACKUP_DIR="/app/backup"
[ -z "$TOKEN" ] || [ -z "$REPO" ] && { echo "[restore] GITHUB_TOKEN 或 GITHUB_BACKUP_REPO 未設定"; exit 1; }
mkdir -p "$BACKUP_DIR"
LATEST=$(curl -s -H "Authorization: token $TOKEN" "https://api.github.com/repos/$REPO/contents/backup" | grep -oE 'backup-[0-9]{8}_[0-9]{6}\.tar\.gz' | sort -r | head -1)
[ -z "$LATEST" ] && { echo "[restore] 找不到備份檔"; exit 1; }
echo "[restore] 下載 $LATEST ..."
curl -sL -H "Authorization: token $TOKEN" -H "Accept: application/vnd.github.v3.raw" "https://api.github.com/repos/$REPO/contents/backup/$LATEST" | tar -xzv -C "$BACKUP_DIR"
[ -f "$BACKUP_DIR/openclaw.json" ] && cp "$BACKUP_DIR/openclaw.json" "$OPENCLAW_ROOT/openclaw.json" && echo "[restore] ✓ openclaw.json"
for ws_dir in "$BACKUP_DIR/workspaces"/*; do
  [ -d "$ws_dir" ] || continue
  ws_name=$(basename "$ws_dir"); ws_dest="$OPENCLAW_ROOT/$ws_name"
  mkdir -p "$ws_dest" "$ws_dest/memory"
  for f in AGENTS.md SOUL.md MEMORY.md USER.md; do [ -f "$ws_dir/$f" ] && cp "$ws_dir/$f" "$ws_dest/$f" && echo "[restore] ✓ $ws_name/$f"; done
  [ -d "$ws_dir/memory" ] && cp "$ws_dir"/memory/*.md "$ws_dest/memory/" 2>/dev/null && echo "[restore] ✓ $ws_name/memory/*"
done
LATEST_SKILLS=$(curl -s -H "Authorization: token $TOKEN" "https://api.github.com/repos/$REPO/contents/backup" | grep -oE 'skills-backup-[0-9]{8}_[0-9]{6}\.tar\.gz' | sort -r | head -1)
if [ -n "$LATEST_SKILLS" ]; then
  echo "[restore] 下載 skills $LATEST_SKILLS ..."
  mkdir -p "$OPENCLAW_ROOT"
  curl -sL -H "Authorization: token $TOKEN" -H "Accept: application/vnd.github.v3.raw" "https://api.github.com/repos/$REPO/contents/backup/$LATEST_SKILLS" | tar -xzv -C "$OPENCLAW_ROOT"
  echo "[restore] ✓ skills"; echo "RESTORED_SKILLS_FROM=$LATEST_SKILLS"
fi
echo "[restore] 完成"; echo "RESTORED_FROM=$LATEST"
SCRIPTEOF
fi

chmod +x "$SKILL_DIR/scripts/restore-from-github.sh"

echo "✓ SKILL.md: $(wc -c < "$SKILL_DIR/SKILL.md") bytes"
echo "✓ restore-from-github.sh: $(wc -c < "$SKILL_DIR/scripts/restore-from-github.sh") bytes"
echo "Done. Skill 已修復。"
ls -la "$SKILL_DIR/"
ls -la "$SKILL_DIR/scripts/"
