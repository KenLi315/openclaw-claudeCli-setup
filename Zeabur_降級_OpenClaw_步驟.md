# Zeabur 降級 OpenClaw 至 v2026.2.25 步驟

## 方法一：從 Zeabur 儀表板修改映像（推薦）

1. 登入 [Zeabur](https://zeabur.com) → 選擇你的專案
2. 點選 **OpenClaw 服務**
3. 進入 **Settings（設定）** 或 **Deploy（部署）** 分頁
4. 找到 **Image（映像）** 或 **Docker Image** 欄位
   - 目前應為：`ghcr.io/openclaw/openclaw:2026.2.26`
5. 改為：`ghcr.io/openclaw/openclaw:2026.2.25`
6. 儲存後點 **Redeploy（重新部署）**

---

## 方法二：用 Edit TOML 修改（若方法一找不到 Image 欄位）

1. 在 OpenClaw 服務頁面，點 **Edit TOML** 或 **編輯配置**
2. 找到 `image:` 或 `services.xxx.image` 欄位
3. 將版本改為 `2026.2.25`：

   ```yaml
   image: ghcr.io/openclaw/openclaw:2026.2.25
   ```

4. 儲存並重新部署

---

## 方法三：從頭用正確版本部署（若無法修改既有服務）

1. Zeabur → **Add Service** → **Docker Images**
2. 在 **Image** 欄位輸入：
   ```
   ghcr.io/openclaw/openclaw:2026.2.25
   ```
3. 依 OpenClaw 官方文件設定：
   - **Ports**：18789（TCP）
   - **Volumes**：`~/.openclaw` 等（參考原模板）
   - **Environment**：API keys、Telegram 等
4. 部署完成後，用 **Command** 執行 `openclaw onboard --gateway-bind lan` 完成設定

---

## 驗證

部署完成後，在 Zeabur **Command** 終端執行：

```bash
openclaw --version
```

應顯示 `2026.2.25` 或類似版本號。

---

## 注意

- 降級後需**重新部署**才會生效
- 若使用 Volume 儲存設定，`openclaw.json`、`config.json5` 等會保留，不需重設
- 修復 PR 合併後，可再改回 `2026.2.26` 或更新版本
