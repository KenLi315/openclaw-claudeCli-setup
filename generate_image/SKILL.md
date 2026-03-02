---
name: generate_image
description: Generate/edit images with Gemini. Prefer image_creator sub-agent, fallback self.
user-invocable: true
metadata:
  {"openclaw":{"primaryEnv":"GOOGLE_API_KEY","requires":{"env":["GOOGLE_API_KEY"]}}}
---

Use image_creator sub-agent first for image tasks.
If sub-agent fails/unavailable, run:
node {baseDir}/scripts/generate_image.mjs --prompt "<PROMPT>" --filename "~/.openclaw/media/images/out.png"

## Runtime requirement

When delegating to image_creator, call sessions_spawn with runtime "subagent".
Do not use ACP runtime.
