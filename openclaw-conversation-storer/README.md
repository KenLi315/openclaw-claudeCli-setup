# OpenClaw Conversation Storer

單一 Zeabur 服務，接收 OpenClaw 的 User 訊息（即時）與 Assistant 訊息（session-sync），寫入 MongoDB。

## 資料來源

| 來源 | Hook | 時機 |
|------|------|------|
| User | conversation-logger-webhook | message:received 即時 |
| Assistant | conversation-session-sync | /new 或 /reset 時從 transcript 同步 |

## 部署

見專案根目錄 `Step_by_Step_OpenClaw_Conversation_Storer_Setup.md`。
