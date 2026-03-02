# OpenClaw + Claude Code CLI

此 Dockerfile 在 OpenClaw 官方映像上額外安裝 Claude Code CLI，供 OpenClaw 透過 `exec` 呼叫 `claude -p "..."` 使用 Gemini API（經由 claude-code-proxy）。

## 使用方式

1. 在 Zeabur 先部署 **claude-code-proxy** 服務（見主指南 Part A）
2. 建置此映像並部署為 OpenClaw 服務
3. 設定 `ANTHROPIC_BASE_URL=http://claude-code-proxy.zeabur.internal:8082`

完整步驟請參考：`../Claude_Code_Gemini_Zeabur_Setup_Guide.md`
