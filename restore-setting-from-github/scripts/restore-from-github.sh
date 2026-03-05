#!/bin/bash
# 從 GitHub 還原 OpenClaw 最新備份（設定 + skills）
# 需設定 GITHUB_TOKEN、GITHUB_BACKUP_REPO
# 由 restore-setting-from-github Skill 呼叫

set -e

REPO="${GITHUB_BACKUP_REPO:-}"
TOKEN="${GITHUB_TOKEN:-}"
OPENCLAW_ROOT="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
BACKUP_DIR="/app/backup"

if [ -z "$TOKEN" ] || [ -z "$REPO" ]; then
  echo "[restore] GITHUB_TOKEN 或 GITHUB_BACKUP_REPO 未設定，跳過還原"
  exit 1
fi

mkdir -p "$BACKUP_DIR"

# 取得最新設定備份檔名（backup-YYYYMMDD_HHMMSS.tar.gz）
LATEST=$(curl -s -H "Authorization: token $TOKEN" "https://api.github.com/repos/$REPO/contents/backup" | grep -oE 'backup-[0-9]{8}_[0-9]{6}\.tar\.gz' | sort -r | head -1)

if [ -z "$LATEST" ]; then
  echo "[restore] 找不到備份檔，跳過"
  exit 1
fi

echo "[restore] 下載設定備份 $LATEST ..."
curl -sL -H "Authorization: token $TOKEN" -H "Accept: application/vnd.github.v3.raw" \
  "https://api.github.com/repos/$REPO/contents/backup/$LATEST" | tar -xzv -C "$BACKUP_DIR"

# 還原 openclaw.json
if [ -f "$BACKUP_DIR/openclaw.json" ]; then
  cp "$BACKUP_DIR/openclaw.json" "$OPENCLAW_ROOT/openclaw.json"
  echo "[restore] ✓ openclaw.json"
fi

# 還原 workspaces（AGENTS.md, SOUL.md, MEMORY.md, USER.md, memory/*.md）
for ws_dir in "$BACKUP_DIR/workspaces"/*; do
  [ -d "$ws_dir" ] || continue
  ws_name=$(basename "$ws_dir")
  ws_dest="$OPENCLAW_ROOT/$ws_name"
  mkdir -p "$ws_dest" "$ws_dest/memory"
  for f in AGENTS.md SOUL.md MEMORY.md USER.md; do
    [ -f "$ws_dir/$f" ] && cp "$ws_dir/$f" "$ws_dest/$f" && echo "[restore] ✓ $ws_name/$f"
  done
  [ -d "$ws_dir/memory" ] && cp "$ws_dir"/memory/*.md "$ws_dest/memory/" 2>/dev/null && echo "[restore] ✓ $ws_name/memory/*"
done

# 還原 skills（取得最新 skills-backup-YYYYMMDD_HHMMSS.tar.gz）
LATEST_SKILLS=$(curl -s -H "Authorization: token $TOKEN" "https://api.github.com/repos/$REPO/contents/backup" | grep -oE 'skills-backup-[0-9]{8}_[0-9]{6}\.tar\.gz' | sort -r | head -1)

if [ -n "$LATEST_SKILLS" ]; then
  echo "[restore] 下載 skills 備份 $LATEST_SKILLS ..."
  mkdir -p "$OPENCLAW_ROOT"
  curl -sL -H "Authorization: token $TOKEN" -H "Accept: application/vnd.github.v3.raw" \
    "https://api.github.com/repos/$REPO/contents/backup/$LATEST_SKILLS" | tar -xzv -C "$OPENCLAW_ROOT"
  echo "[restore] ✓ skills（$LATEST_SKILLS）"
  echo "RESTORED_SKILLS_FROM=$LATEST_SKILLS"
else
  echo "[restore] 找不到 skills 備份，略過"
fi

echo "[restore] 完成：$LATEST"
echo "RESTORED_FROM=$LATEST"
