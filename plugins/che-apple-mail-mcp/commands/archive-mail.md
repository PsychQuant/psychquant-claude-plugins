---
description: 歸檔指定聯絡人的 Apple Mail 郵件到 Markdown 檔案
argument-hint: <email-filter> [output-dir]
allowed-tools: mcp__apple-mail__*, mcp__che-apple-mail-mcp__*, mcp__plugin_che-apple-mail-mcp_mail__*, Bash(mkdir:*), Read, Write, Glob
---

# Archive Mail

歸檔指定聯絡人的郵件到 Markdown 檔案。

## 使用方式

```
/archive-mail d06227105@ntu.edu.tw
/archive-mail d06227105@ntu.edu.tw communication/emails
```

- 第一個參數：Email 過濾條件（寄件人或收件人包含此字串）
- 第二個參數（可選）：輸出目錄，預設 `communication/emails`

## 執行步驟

### Step 1: 解析參數

從 `$ARGUMENTS` 取得：
- `filter`: 第一個參數（必填）
- `output_dir`: 第二個參數，預設 `communication/emails`

如果沒有提供 filter，詢問用戶。

### Step 2: 建立目錄和索引

```bash
mkdir -p "${output_dir}"
```

讀取索引檔 `${output_dir}/.email_index.json`：
- 若存在，載入已歸檔的 Message-ID
- 若不存在，建立空索引 `{"version": "1.0", "emails": {}}`

### Step 3: 搜尋郵件（使用 apple-mail MCP）

使用 `mcp__apple-mail__search_emails` 搜尋：

1. **搜尋收到的郵件**（sender 包含 filter）
2. **搜尋寄出的郵件**（在 Sent 信箱搜尋）

需要先用 `mcp__apple-mail__list_accounts` 取得帳號列表。

對每個帳號執行：
```
mcp__apple-mail__search_emails(
  account: "帳號名稱",
  sender: "${filter}",
  include_content: true,
  max_results: 100
)
```

### Step 4: 過濾新郵件

對每封搜尋到的郵件：
1. 檢查其 Message-ID 是否已在索引中
2. 若已存在 → 跳過
3. 若不存在 → 加入待歸檔清單

### Step 5: 生成 Markdown

對每封新郵件，建立 Markdown 檔案：

**檔名格式**：`YYYYMMDD_brief_description.md`

**內容格式**：
```markdown
# [主題] - YYYY-MM-DD HH:MM

## 元數據

| 項目 | 內容 |
|------|------|
| **日期** | YYYY-MM-DD HH:MM |
| **類型** | 收到 / 寄出 |
| **寄件人** | xxx |
| **收件人** | xxx |

---

## 信件內容

[完整郵件內容]

---

## 重點摘要

- [AI 提取的重點]

## 待辦事項

- [ ] [AI 提取的待辦]

---

*歸檔日期：YYYY-MM-DD*
```

### Step 6: 更新索引

將新歸檔的郵件加入索引：

```json
{
  "version": "1.0",
  "last_updated": "YYYY-MM-DD",
  "emails": {
    "message-id@example.com": {
      "file": "20260113_topic.md",
      "date": "2026-01-13 14:30",
      "subject": "郵件主旨"
    }
  }
}
```

### Step 7: 輸出報告

```
═══════════════════════════════════════════
Archive Mail 完成
═══════════════════════════════════════════

過濾條件: d06227105@ntu.edu.tw
輸出目錄: communication/emails

新歸檔: 5 封
  - 20260113_meeting_request.md
  - 20260112_report_feedback.md
  - ...

跳過（已歸檔）: 12 封

═══════════════════════════════════════════
```

## 注意事項

- 使用 apple-mail MCP，需確保 MCP server 已連接
- Message-ID 用於去重，確保不會重複歸檔
- 寄出的郵件不產生「重點摘要」和「待辦事項」
