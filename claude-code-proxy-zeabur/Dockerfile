# OpenClaw + Claude Code CLI
# 基於 OpenClaw 官方映像，額外安裝 Claude Code CLI 供 exec 呼叫
FROM ghcr.io/openclaw/openclaw:latest

# 安裝 Claude Code CLI（全域）
RUN npm install -g @anthropic-ai/claude-code

# 注意：ANTHROPIC_BASE_URL 與 proxy 連線需在 Zeabur 環境變數設定
# 例如：ANTHROPIC_BASE_URL=http://claude-code-proxy.zeabur.internal:8082
