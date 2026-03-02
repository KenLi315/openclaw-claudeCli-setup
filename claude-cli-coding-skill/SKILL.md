---
name: claude-cli-coding
description: Delegate coding tasks to Claude Code CLI. Run claude -p in background; Claude's Stop/TaskCompleted hook notifies OpenClaw when done. Use for app development, scripts, debugging, or when user asks to write/build code.
user-invocable: true
metadata:
  {"openclaw":{"requires":{"env":["ANTHROPIC_BASE_URL"]}}}
---

# Claude CLI Coding Skill

Delegate coding tasks to Claude Code CLI. Run in background so you return to user immediately; Claude notifies you when done via `openclaw system event`.

## When to Use

- User asks to write/build an app, script, or fix code
- Task is complex (e.g. chess game, full app) and would block for minutes
- You have `exec` permission and `ANTHROPIC_BASE_URL` is set

## Workflow

1. **Tell user**: "我已分派給 Claude CLI 執行，完成後會主動通知您。"
2. **Run in background**:
   ```bash
   nohup claude -p "用戶的完整任務描述，含產出格式與路徑要求" --verbose > /tmp/claude-coding-output.txt 2>&1 &
   ```
3. **Return immediately** — do not wait. Continue chatting with user.
4. **When notified** (via `openclaw system event`): Read `/tmp/claude-coding-output.txt`, summarize, and report to user. If output files were created, share paths.

## Output Paths

- Claude's stdout/stderr: `/tmp/claude-coding-output.txt`
- If task specifies output dir (e.g. `~/.openclaw/workspace-main/`), Claude will write there. Tell user the path in your report.

## Prerequisites

- `ANTHROPIC_BASE_URL` must point to claude-code-proxy (e.g. `http://ghcrio1rgsclaude-code-proxylatest-pa.zeabur.internal:8082`)
- `~/.claude.json` with `hasCompletedOnboarding: true` (for proxy mode)
- Claude hooks configured: `~/.claude/settings.json` with Stop and TaskCompleted calling `openclaw system event --text 'Claude CLI 任務已完成' --mode now`
