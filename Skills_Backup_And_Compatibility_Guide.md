# Skills 備份與路徑相容性檢查指南

> 重裝前備份所有自訂 skills，並確認路徑符合 OpenClaw 官方規範

---

## 一、OpenClaw 官方 Skills 路徑（不可變更）

| 類型 | 路徑 | 說明 |
|------|------|------|
| Managed skills | `~/.openclaw/skills/` | 本機/Zeabur 自訂 skill 存放處 |
| Workspace skills | `~/.openclaw/workspace/skills/` | 單一 workspace 專用 |
| Extra dirs | `skills.load.extraDirs` | openclaw.json 額外指定 |

**Zeabur 常見絕對路徑**：`/home/node/.openclaw/skills/`

---

## 二、備份步驟（Zeabur 終端執行）

### 2.1 列出目前 skills

```bash
ls -la ~/.openclaw/skills/
# 或 Zeabur: ls -la /home/node/.openclaw/skills/
```

### 2.2 建立備份（打包整個 skills 目錄）

```bash
# 建立備份目錄
mkdir -p /tmp/openclaw-backup

# 打包 skills（含所有子目錄）
tar -czvf /tmp/openclaw-backup/skills-$(date +%Y%m%d).tar.gz -C ~/.openclaw skills

# 確認備份內容
tar -tzvf /tmp/openclaw-backup/skills-$(date +%Y%m%d).tar.gz | head -30
```

### 2.3 下載備份到本機（Zeabur）

Zeabur 的 `/tmp` 在重啟後會清除，建議：

**方式 A：複製到 Volume 掛載目錄**（若有持久化儲存）

```bash
cp /tmp/openclaw-backup/skills-*.tar.gz ~/.openclaw/
# 然後從 Zeabur 檔案管理或 Volume 下載
```

**方式 B：用 base64 輸出到終端，本機貼上還原**

```bash
base64 /tmp/openclaw-backup/skills-*.tar.gz | head -c 50000
# 若檔案過大，分段執行或改用方式 A
```

**方式 C：上傳到本機專案**

若本機有 `openclaw_setup` 專案，可將 `zeabur-gemini-image-skill` 視為已備份（與 Zeabur 上傳的內容相同）。其他自訂 skills 需從 Zeabur 複製下來。

---

## 三、路徑相容性檢查

### 3.1 官方 message 工具允許路徑

發送附件時，`filePath` **僅允許**：

- `/tmp/`
- `~/.openclaw/media/`
- `~/.openclaw/workspace/`

**`workspace-shared` 不在清單內**，需先複製到 `/tmp/` 再發送。

### 3.2 本專案 skills 檢查結果

| Skill | 位置 | 路徑相容性 | 說明 |
|-------|------|------------|------|
| zeabur-gemini-image-skill (gemini-image-gen) | `zeabur-gemini-image-skill/` | ✅ 相容 | 腳本接受任意 `--filename`，範例用 `workspace/images/`；多代理時改為 `workspace-shared/images/`，主代理需複製到 `/tmp` 再發送 |

### 3.3 需檢查的檔案

對每個 skill，檢查：

1. **SKILL.md**：範例中的 `--filename`、`--input-image` 路徑
2. **scripts/*.mjs、*.js**：是否有硬編碼路徑

**官方建議路徑**：

- 單一 agent：`~/.openclaw/workspace/images/`、`~/.openclaw/workspace/input/`
- 多 agent（image_creator）：`~/.openclaw/workspace-shared/images/`、`~/.openclaw/workspace-shared/input/`
- 發送前：複製到 `/tmp/<檔名>` 再用 message 發送

### 3.4 zeabur-gemini-image-skill 路徑修正建議

**SKILL.md 目前範例**（單一 workspace）：

```
--filename "/home/node/.openclaw/workspace/images/lobster.png"
--input-image "/home/node/.openclaw/workspace/input/source.jpg"
```

**多代理架構**（對應 workspace-shared）：

```
--filename "~/.openclaw/workspace-shared/images/輸出檔名.png"
--input-image "~/.openclaw/workspace-shared/input/原圖.png"
```

腳本本身不需修改，僅調整 AGENTS.md 中的呼叫範例即可。

---

## 四、還原步驟（重裝後）

```bash
# 解壓到 skills 目錄
tar -xzvf skills-YYYYMMDD.tar.gz -C ~/.openclaw/

# 確認
ls -la ~/.openclaw/skills/
```

---

## 五、本機專案中的 skill 備份

本專案已包含：

```
openclaw_setup/
└── zeabur-gemini-image-skill/
    ├── SKILL.md
    ├── scripts/
    │   └── generate_image.mjs
    └── README-ZEABUR-SETUP.md
```

此即 `gemini-image-gen` skill 的完整備份。重裝後上傳至 `/home/node/.openclaw/skills/gemini-image-gen/` 即可。

---

## 六、檢查清單（備份前）

- [ ] 執行 `ls ~/.openclaw/skills/` 列出所有 skills
- [ ] 執行 `tar` 建立備份檔
- [ ] 將備份下載或複製到安全位置
- [ ] 檢查每個 skill 的 SKILL.md 與 scripts 路徑
- [ ] 確認無使用 `media/outbound` 等非官方路徑
