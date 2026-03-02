# 修復：圖片未送達、主代理一直「等待中」

## 根本原因

**OpenClaw v2026.2.26 有已知 Bug（Issue #28490）**：

- 子代理（image_creator）完成任務後，**announce 流程會崩潰**
- 錯誤：`TypeError: Cannot read properties of undefined (reading 'filter')`
- 結果：主代理**永遠收不到**子代理的完成結果
- 因此主代理會一直說「等待圖像生成子代理完成」，但實際上圖片已生成在 `media/outbound/`

---

## 解決方案：降級至 v2026.2.25

v2026.2.25 沒有此 bug，建議**立即降級**。

### Zeabur 部署

1. 開啟 Zeabur 專案 → 選擇 OpenClaw 服務
2. 檢查 **Dockerfile** 或 **package.json** 中的 OpenClaw 版本
3. 將版本改為 `v2026.2.25` 或 `2026.2.25`：

   **若用 npm 安裝：**
   ```json
   "openclaw": "2026.2.25"
   ```

   **若用 Docker 映像：**
   ```dockerfile
   FROM ghcr.io/openclaw/openclaw:2026.2.25
   ```

4. 重新部署（Redeploy）

### 本機安裝

```bash
npm install -g openclaw@2026.2.25
# 或
pnpm add -g openclaw@2026.2.25
```

### 驗證版本

```bash
openclaw --version
# 應顯示 2026.2.25 或類似
```

---

## 修復後預期行為

1. 主代理分派給 image_creator
2. image_creator 執行 `generate_image.mjs`，產生圖片
3. announce 成功將路徑回傳給主代理
4. 主代理收到路徑後，用 `message` 發送圖片給用戶

---

## 後續（等官方修復）

- 修復 PR：[#28517](https://github.com/openclaw/openclaw/pull/28517)（尚未合併）
- 合併後可升級回 v2026.2.27 或更新版本

---

## 相關連結

- [Issue #28490](https://github.com/openclaw/openclaw/issues/28490)
- [PR #28517](https://github.com/openclaw/openclaw/pull/28517)
