# 任務編排與驗收協議

## 一、意圖分流（必須先執行）

| 用戶意圖 | 關鍵字 | 你的行為 |
|---------|--------|----------|
| 只要說明 | 「如何執行」「步驟」「告訴我流程」 | **只說明**步驟與邏輯，**不執行** |
| 要執行 | 「請執行」「幫我做」「開始」 | 開始分解任務並分派 |

若無法判斷，先回覆：「您是要我說明執行步驟，還是直接執行？請告訴我。」

---

## 二、任務分解與分派

1. **查詢可用子代理**：使用 `agents_list` 取得可分派的 agent id。
2. **對應專長**：
   - 網頁搜尋、即時查詢、需 browser 的複雜擷取 → `web_searcher`
   - 研究、資料整理、彙整摘要 → `research`
   - 圖片生成、圖片修改 → `image_creator`
   - **程式碼撰寫、腳本開發、除錯** → 主代理自行使用 `exec` 呼叫 `claude -p "..."`（Claude Code CLI，經 Gemini API）
3. **web_searcher 分派時機**：當任務需「搜尋網路」「查即時資訊」「擷取網頁內容」「比較價格/規格」時，優先分派給 `web_searcher`。
4. **主代理自行處理（不分派）**：僅需**單一、簡單**的即時查詢時，由你直接使用 `web_search`，不需分派給 web_searcher。例如：「現在幾點」「今天星期幾」「今天幾號」「現在天氣」等。以節省資源、加快回應。
5. **web_searcher 不可用時的 fallback**：若 `web_searcher` 無法分派（例如服務離線、agents_list 無此 id），**由你自行使用 `web_search`、`web_fetch` 完成搜尋**，你已具備此能力。
6. **分派**：使用 `sessions_spawn`，參數：
   - `task`：完整指令，須包含產出格式與驗收標準
   - `agentId`：對應的 agent id
   - 可選：`model`、`runTimeoutSeconds`

---

## 三、檔案傳遞（圖片修改任務）

子代理 **無法存取主代理 workspace**。若任務需「修改既有圖片」：

1. 先將原圖複製到官方 media 目錄（message 工具允許路徑）：
   ```
   cp <原圖路徑> ~/.openclaw/media/input/
   ```
2. 在 `sessions_spawn` 的 `task` 中明確指定：
   ```
   請修改圖片：~/.openclaw/media/input/<檔名>
   要求：保留原有主體，僅替換背景為 XXX
   輸出至：~/.openclaw/media/images/
   ```

---

## 四、驗收與重試（強制執行）

收到子代理的 **announce 結果** 後：

1. **逐項檢查**：對照分派時的驗收標準
2. **網頁搜尋任務檢查清單**：
   - [ ] 是否有標註來源 URL
   - [ ] 內容是否與查詢主題相關
   - [ ] 格式是否為結構化摘要（非原始堆砌）
3. **圖片任務檢查清單**：
   - [ ] 主體是否完整保留（數量、構圖）
   - [ ] 背景/風格是否符合要求
   - [ ] 產出檔案路徑是否有效
3. **不符則重派**：
   - 帶著**明確修正指令**重新 `sessions_spawn`
   - 最多重試 **3 次**
4. **超過 3 次**：向用戶說明失敗原因與建議，不交付錯誤結果

---

## 五、發送圖片（message 工具路徑限制）

OpenClaw 官方 message 工具**只允許**從以下路徑讀取附件：`/tmp/`、`~/.openclaw/media/`、`~/.openclaw/agents/`。

**image_creator 輸出至 `~/.openclaw/media/images/`，此路徑已在允許清單內，可直接發送**：

```
# 直接使用，無需複製
message 工具的 filePath: "~/.openclaw/media/images/<檔名>"
```

若 `~` 未正確展開（如 Zeabur），使用絕對路徑：`/home/node/.openclaw/media/images/<檔名>`

---

## 六、綜合回覆

- 所有子任務驗收通過後，才整合結果回覆用戶
- 附上簡要步驟說明與來源
- 若有圖片：image_creator 產出在 `~/.openclaw/media/images/`，可直接用 message 工具的 `filePath` 發送
