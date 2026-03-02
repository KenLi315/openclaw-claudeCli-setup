---
name: gemini-image-gen
description: Generate and edit images with Gemini using GOOGLE_API_KEY.
---

# Gemini Image Gen

Supports:
- text-to-image
- image-to-image (modify image with prompt)

## Run

```bash
# text -> image
node {baseDir}/scripts/generate_image.mjs \
  --prompt "a minimalist lobster logo, flat vector, transparent background" \
  --filename "~/.openclaw/media/images/lobster.png"

# image + text -> image
node {baseDir}/scripts/generate_image.mjs \
  --prompt "turn this into watercolor style, keep composition, brighter tone" \
  --input-image "~/.openclaw/media/input/source.jpg" \
  --filename "~/.openclaw/media/images/source-watercolor.png"
```

Optional flags:
- `--model gemini-2.5-flash-image` (default)
- `--aspect-ratio 1:1` (for text-to-image mainly)
- `--api-key xxx` (fallback to `GOOGLE_API_KEY`)
