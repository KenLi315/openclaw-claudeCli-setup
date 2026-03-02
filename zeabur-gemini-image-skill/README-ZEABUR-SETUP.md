# Zeabur Setup (No Copy-Paste)

## 1) Upload files in Zeabur

Upload this whole folder to:

`/home/node/.openclaw/skills/gemini-image-gen/`

Final structure on Zeabur should be:

- `/home/node/.openclaw/skills/gemini-image-gen/SKILL.md`
- `/home/node/.openclaw/skills/gemini-image-gen/scripts/generate_image.mjs`

## 2) Set environment variable

In Zeabur -> OpenClaw service -> Variables, add:

`GOOGLE_API_KEY=<your key>`

Then restart service.

## 3) Run tests in Zeabur Command

Text to image:

```bash
# 多代理：使用 media/（message 工具允許）
node /home/node/.openclaw/skills/gemini-image-gen/scripts/generate_image.mjs --prompt "a minimalist lobster logo, flat vector, transparent background" --filename "/home/node/.openclaw/media/images/lobster.png" --aspect-ratio "1:1"
```

Image to image (modify):

```bash
node /home/node/.openclaw/skills/gemini-image-gen/scripts/generate_image.mjs --prompt "convert to watercolor style, keep composition and object shape" --input-image "/home/node/.openclaw/media/input/source.jpg" --filename "/home/node/.openclaw/media/images/source-watercolor.png"
```

## 4) Output location

**多代理架構（image_creator）**：輸出至 `~/.openclaw/media/images/`（message 工具允許路徑）

**單一 agent**：可輸出至 `~/.openclaw/workspace/images/` 或 `~/.openclaw/media/images/`

設定環境變數 `IMAGE_OUTPUT_DIR` 可覆寫預設輸出目錄。
