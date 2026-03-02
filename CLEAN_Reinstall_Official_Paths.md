# OpenClaw 完整重裝 — 僅用官方路徑

> 所有 subagent 輸入/輸出路徑**嚴格遵循 OpenClaw 官方文件**，不新增、不修改。

---

## 一、完整清除（Zeabur）

在 Zeabur 終端執行，或刪除服務後重新部署：

```bash
# 若需保留設定，先備份
cp ~/.openclaw/openclaw.json /tmp/openclaw.json.bak 2>/dev/null || true

# 清除 workspace 與舊設定（可選，重裝時建議清空）
rm -rf ~/.openclaw/workspace-main ~/.openclaw/workspace-research ~/.openclaw/workspace-image-creator
```

或：在 Zeabur 刪除 OpenClaw 服務，重新從模板部署。

---

## 二、建立目錄（官方結構）

```bash
mkdir -p ~/.openclaw/workspace-main
mkdir -p ~/.openclaw/workspace-research
mkdir -p ~/.openclaw/workspace-image-creator
mkdir -p ~/.openclaw/media/input
mkdir -p ~/.openclaw/media/images
```

**官方路徑對照**（符合 OpenClaw 官方文件與 message 工具允許清單）：

| 用途 | 官方路徑 | 說明 |
|------|----------|------|
| 主代理 workspace | `~/.openclaw/workspace-main` | openclaw.json 設定 |
| 研究子代理 workspace | `~/.openclaw/workspace-research` | openclaw.json 設定 |
| 圖片子代理 workspace | `~/.openclaw/workspace-image-creator` | openclaw.json 設定 |
| 圖片輸入（主→子） | `~/.openclaw/media/input/` | message 工具允許路徑 |
| 圖片輸出（子→主） | `~/.openclaw/media/images/` | message 工具允許路徑 |

---

## 三、寫入設定與模板

### 3.1 openclaw.json

使用 `templates/openclaw.json`，勿修改 agents 的 workspace 路徑。

### 3.2 主代理（workspace-main）

```bash
cp templates/workspace-main/SOUL.md ~/.openclaw/workspace-main/
cp templates/workspace-main/AGENTS.md ~/.openclaw/workspace-main/
cp templates/workspace-main/USER.md ~/.openclaw/workspace-main/
```

### 3.3 子代理（workspace-research、workspace-shared）

```bash
cp templates/workspace-research/AGENTS.md ~/.openclaw/workspace-research/
cp templates/workspace-image-creator/AGENTS.md ~/.openclaw/workspace-image-creator/
```

**重要**：使用 `templates/workspace-image-creator/AGENTS.md`，路徑為 `~/.openclaw/media/`（message 工具允許）。

---

## 四、官方路徑摘要（不可變更）

| 項目 | 官方路徑 |
|------|----------|
| image_creator 輸入 | `~/.openclaw/media/input/` |
| image_creator 輸出 | `~/.openclaw/media/images/` |
| message 工具允許 | `/tmp/`、`~/.openclaw/media/`、`~/.openclaw/agents/` |
| 發送 | 直接使用 `~/.openclaw/media/images/`（已在允許清單內） |

---

## 五、發送流程（主代理 AGENTS.md 已規範）

1. image_creator 產出至 `~/.openclaw/media/images/<檔名>.png`
2. 主代理收到 announce 後，直接使用 message 工具：`filePath: "~/.openclaw/media/images/<檔名>"`（無需複製，media 已在允許清單內）

---

## 六、重啟與驗證

```bash
# Zeabur：重新部署
# 本機：
openclaw gateway restart

# 驗證
openclaw agents list --bindings
ls -la ~/.openclaw/media/input/
ls -la ~/.openclaw/media/images/
```

---

## 七、禁止事項

- ❌ 不要新增自訂 workspace 或共享目錄
- ❌ 不要修改 `templates/` 中的路徑
- ✅ 僅使用本文件與 `templates/` 中的官方路徑（`media/input`、`media/images`）
