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

使用 `mcp__plugin_che-apple-mail-mcp_mail__search_emails` 搜尋：

1. **搜尋收到的郵件**（sender 包含 filter）
2. **搜尋寄出的郵件**（在 Sent 信箱搜尋）

需要先用 `mcp__plugin_che-apple-mail-mcp_mail__list_accounts` 取得帳號列表。

對每個帳號執行：
```
mcp__plugin_che-apple-mail-mcp_mail__search_emails(
  account_name: "帳號名稱",
  query: "${filter}",
  field: "sender",
  limit: 100
)
```

> **⚠️ account_name 陷阱（fixes #15）**
> `list_accounts` 對 Exchange 帳號回傳的 `name` 是 `ews://AAMkA...` 形式的內部 URL；`uuid` 也不接受。後續呼叫 `get_email` / `search_emails` 時必須改用 **display name**（email 地址，例如 `d06227105@ntu.edu.tw`），否則會觸發：
>
> ```
> AppleScript error (-1728): Mail got an error: Can't get account "ews://...".
> ```
>
> 若配置 `.claude/emails.md` 的 `accounts` 欄位明列 email 地址，可直接拿來用。否則需要人工比對帳號。

> **Note on tool prefix**
> `mcp__plugin_che-apple-mail-mcp_mail__*` 是 plugin 載入後的正式 prefix。舊版文件的 `mcp__apple-mail__*` 是 plugin 化前的名稱，frontmatter `allowed-tools` 保留兩者作相容。

### Step 4: 過濾新郵件

對每封搜尋到的郵件：
1. 檢查其 Message-ID 是否已在索引中
2. 若已存在 → 跳過
3. 若不存在 → 加入待歸檔清單

### Step 5: 生成 Markdown

對每封新郵件，建立 Markdown 檔案：

**檔名格式**（fixes #16）：`YYYY-MM-DD_{subject-hyphenated}.md`

Subject → filename 轉換規則：
- 空白 / 冒號 / 斜線 / 引號 / 中英標點（`,`、`。`、`、`、`:`、`；`、`(`、`)`、`[`、`]`）→ `-`
- 連續 `-` 合成一個
- 首尾 `-` 去除
- 長度超過 50 字元則截斷
- **保留 Unicode**（中文、日文、韓文 subject 維持原樣）

同日同主旨多封郵件：
- 第一封：無後綴 `2026-04-08_Re--Some-topic.md`
- 第二封起：加 `-1`、`-2`、`-3` 後綴 `2026-04-08_Re--Some-topic-1.md`

範例（來自 `tatsuma/communications/`）：

| Subject | 檔名 |
|---------|------|
| `Re: sabbatical year` | `2023-08-28_Re--sabbatical-year.md` |
| `翻訳のお願い` | `2024-03-26_翻訳のお願い.md` |
| `NTU PSY seminar 2024 final PPT` | `2024-04-04_NTU-PSY-seminar-2024-final-PPT.md` |
| `Re: Poster at 九州心理学会` (第三封) | `2024-11-20_Re--Poster-at-九州心理学会-3.md` |

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
