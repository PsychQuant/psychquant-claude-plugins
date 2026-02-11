---
name: inbox-pipeline
description: |
  監控 Telegram 群組訊息，分析是否需要建立 GitHub Issue。
  支援多人消歧義、觀點衝突解決、polling 等待回覆。
  當用戶提到「檢查訊息」「inbox」「Telegram」「新 issue」「收件匣」時使用。
tools:
  - mcp__che-telegram-bot-mcp__get_updates
  - mcp__che-telegram-bot-mcp__send_message
  - Bash
  - AskUserQuestion
---

# Inbox Pipeline — Telegram → GitHub Issue

## 使用前設定

此 skill 需要專案提供設定檔 `.bot-inbox-config.json`：

```json
{
  "telegram_group_id": "-5042817596",
  "github_repo": "kiki830621/martingale",
  "members": [
    { "name": "Hardy", "user_id": 8555072302 },
    { "name": "Che", "user_id": 7039911891 }
  ],
  "bot_user_id": 7712962679,
  "offset_file": ".bot-inbox-offset",
  "pending_file": ".bot-inbox-pending.json"
}
```

如果沒有設定檔，詢問用戶提供 group ID 和 repo 資訊。

## Workflow

### Step 1: 讀取設定和新訊息

```
1. 讀取 `.bot-inbox-config.json` 取得設定
2. 讀取 offset 檔案取得上次的 update_id（沒有就用 0）
3. 呼叫 get_updates(offset=last_id+1, limit=100, timeout=0)
4. 篩選來自目標群組的訊息
5. 讀取「所有人」的訊息，只忽略 bot 自己的訊息
6. 如果沒有新訊息，回報「沒有新訊息」並結束
```

### Step 2: 分析訊息內容

對群組中每則**非 bot** 的訊息，判斷類型：

| 類型 | 判斷依據 | 動作 |
|------|----------|------|
| **Feature Request** | 提到新功能、「能不能」「可以加」「想要」 | 提議建 issue |
| **Bug Report** | 提到錯誤、「壞了」「不能用」「有問題」 | 提議建 issue |
| **Data Request** | 提到新資料來源、爬蟲、API | 提議建 issue |
| **Question** | 問句、需要回答 | 提議用 bot 回覆 |
| **Reply/Answer** | 回覆 bot 的消歧義問題 | 整合到對應的 issue 提案 |
| **Chit-chat** | 閒聊、無明確 action item | 跳過 |

### Step 3: 檢查是否已有相關 Issue

```bash
gh api "repos/{GITHUB_REPO}/issues?state=open" --jq '.[].title'
```

比對現有 issue 標題，如果已有類似的就標注「可能重複」或「可合併到 #XX」。

### Step 4: 消歧義 + 衝突解決循環

**這是一個迴圈**，持續與群組成員互動直到：
- 需求完全明確（無歧義）
- 所有成員的觀點衝突已解決（有共識）

```
WHILE 仍有歧義 OR 仍有觀點衝突:
  1. 用 bot 發送問題
  2. Polling 等待回覆
  3. 分析「所有人」的回覆
  4. 偵測觀點衝突
  5. 如果有衝突 → 整理雙方觀點，請群組討論
  6. 如果還有不清楚的 → 繼續問下一輪
  7. 如果全部清楚且有共識 → 跳出迴圈
```

#### 4a. 發送問題

```
mcp__che-telegram-bot-mcp__send_message(
  chat_id="{TELEGRAM_GROUP_ID}",
  text="關於「{訊息摘要}」，想確認幾個問題：\n1. {問題1}\n2. {問題2}",
  reply_to_message_id={原訊息ID}
)
```

#### 4b. Polling 等待回覆

1. 每 30 秒呼叫 `get_updates` 檢查新訊息
2. 篩選群組中的新訊息（**所有人**都可能回覆）
3. 忽略 bot 自己的訊息
4. 最多等 15 分鐘。超時則用 AskUserQuestion 詢問用戶

#### 4c. 多人觀點整合

| 情況 | 處理方式 |
|------|----------|
| **全員一致** | 確認結論，跳出迴圈 |
| **觀點衝突** | 整理雙方觀點 + 提出折衷方案，請群組達成共識 |
| **部分人未表態** | @ 未表態的人詢問意見 |
| **有人說「就這樣」「OK」** | 確認其他人也同意後跳出 |

#### 4d. 衝突解決

```
mcp__che-telegram-bot-mcp__send_message(
  chat_id="{TELEGRAM_GROUP_ID}",
  text="關於 {議題}，目前有兩種看法：\n\n
    {人A}：{觀點A}\n
    {人B}：{觀點B}\n\n
    技術上的分析：{技術說明}\n
    1. {方案1}\n2. {方案2}\n3. 其他想法？"
)
```

### Step 5: 整理 Issue 提案

將消歧義結果整理成 issue 提案：
- 比對現有 open issues
- 準備好 issue title、body、labels

### Step 6: 呈現給用戶做最終審核

用 AskUserQuestion 列出所有提議的 issue/更新，讓用戶做最終審核。

### Step 7: 建立/更新 Issue（需用戶授權）

**只有用戶明確同意後才執行。**

### Step 8: 更新 Offset

只在流程完成時寫入 offset 檔案。消歧義等待中不更新。

### Step 9: 回報結果

- 用 bot 在群組通知：「已建立 Issue #{number}: {title}」
- 向用戶顯示結果

## Important Rules

1. **絕對不自動建 issue** — 必須經過用戶 AskUserQuestion 授權
2. **不刪除或修改訊息** — 只讀取和回覆
3. **offset 持久化** — 只在流程完成時寫入，消歧義等待中不更新
4. **bot 回覆要簡潔** — 群組裡不要發太長的訊息
5. **重複檢測** — 建 issue 前一定先比對現有 open issues
6. **讀所有人的訊息** — 不只看特定人，只忽略 bot 自己的訊息
7. **等待回覆** — 發出消歧義問題後必須等回覆，不可跳過
8. **衝突解決** — 不偏袒任一方，客觀呈現觀點，提出折衷方案
