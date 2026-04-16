---
description: 歸檔指定聯絡人的 Apple Mail 郵件到 Markdown 檔案
argument-hint: <email-filter> [output-dir]
allowed-tools: mcp__plugin_che-apple-mail-mcp_mail__*, Bash(mkdir:*), Read, Write, Glob
---

# Archive Mail

歸檔指定聯絡人的郵件到 Markdown 檔案。

## 使用方式

```
/archive-mail user@example.com
/archive-mail user@example.com communication/emails
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

**讀取附件設定**（可選）：檢查 `.claude/emails.md` 是否有 `attachment_routing` YAML front matter 區塊。
若有，載入自訂規則（all-or-nothing 取代，不做 merge）。若無，使用以下內建預設：

```yaml
attachment_routing:
  data_extensions: [csv, tsv, sav, dta, parquet, feather, xlsx, sas7bdat]
  document_extensions: [pdf, docx, doc, txt, md, rtf, odt]
  data_keywords: [data, raw, indicators, codebook, dataset]          # 大小寫不敏感子字串匹配
  document_keywords: [Submission, Figures, Tables, Manuscript, draft, Revision, v1, v2, v3]
  data_dir: data/raw
  documents_dir: correspondence/attachments
```

**分類優先序**（config > keyword > extension）：
1. YAML config 明確指定 → 最高
2. 檔名 keyword 子字串匹配（先比 `data_keywords`，再比 `document_keywords`）→ 中
3. 副檔名匹配（先比 `data_extensions`，再比 `document_extensions`）→ 最低
4. 全部未命中 → 保守預設：歸類為 document

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

> **⚠️ account_name 陷阱（fixes #15）— 全域適用，`search_emails` 與 `get_email` 皆然**
> `list_accounts` 對 Exchange 帳號回傳的 `name` 是 `ews://AAMkA...` 形式的內部 URL；`uuid` 也不接受。後續呼叫 `get_email` / `search_emails` 時必須改用 **display name**（email 地址，例如 `user@example.com`），否則會觸發：
>
> ```
> AppleScript error (-1728): Mail got an error: Can't get account "ews://...".
> ```
>
> 若配置 `.claude/emails.md` 的 `accounts` 欄位明列 email 地址，可直接拿來用。否則需要人工比對帳號。
> **此陷阱對 Step 5 讀取郵件內文同樣適用**，不要假設搜尋階段記的 `account_name` 可以直接沿用——若那是 EWS URL，到 `get_email` 會重現 -1728。

### Step 4: 過濾新郵件

對每封搜尋到的郵件：
1. 檢查其 Message-ID 是否已在索引中
2. 若已存在 → 跳過
3. 若不存在 → 加入待歸檔清單

### Step 5: 生成 Markdown

對每封新郵件，建立 Markdown 檔案。

> **⚠️ 再次提醒（來自 Step 3）**：在 Step 5 呼叫 `mcp__plugin_che-apple-mail-mcp_mail__get_email` 讀取內文時，同樣要用 **display name（email 地址）**作為 `account_name`，不可用 `list_accounts` 回的 `ews://` URL 或 UUID——否則 AppleScript error -1728。

`search_emails` 回傳**不含**完整內容（僅 subject / sender / date / mailbox / account），因此對每封新郵件先呼叫：

```
mcp__plugin_che-apple-mail-mcp_mail__get_email(
  id: "<id from search>",
  mailbox: "<mailbox from search>",
  account_name: "<display name / email 地址>",
  format: "text"
)
```


**檔名格式**（fixes #16）：`YYYY-MM-DD_{subject-hyphenated}.md`

Subject → filename 轉換規則（依此順序執行）：
1. **標點轉 `-`**：空白、冒號、斜線、反斜線、引號、問號、驚嘆號、中英標點（`,`、`。`、`、`、`:`、`；`、`(`、`)`、`[`、`]`、`?`、`!`）→ `-`
2. **路徑字元移除**：`.` 開頭的檔名加底線前綴 `_`；`..` 保留為字面（標點轉換已把 `/` 變 `-`，不會路徑越界）
3. **連續 dash 保留**：**不**合併連續 `-`（實務上 `Re:` + 空白 = `Re--`，符合 50 個歷史歸檔慣例）
4. **截斷至 50 個字元**（extended grapheme clusters，即 Swift `String.count` 的語意；非 Unicode code points、非 UTF-8 byte。`é` / `🇹🇼` / 中日韓字各算 1）
5. **首尾 `-` 去除**（截斷後若尾部是 `-`，再次去除；最終檔名不應以 `-` 結尾）
6. **空字串 fallback**：若步驟 1–5 後為空（空白 subject 或全標點 subject），使用 `no-subject`
7. **保留 Unicode**（中文、日文、韓文、emoji 維持原樣）

同日同主旨多封郵件：
- 第 1 封：**無後綴** → `2026-04-08_Re--Some-topic.md`
- 第 2 封：`-1` → `2026-04-08_Re--Some-topic-1.md`
- 第 3 封：`-2` → `2026-04-08_Re--Some-topic-2.md`
- 第 N 封（N ≥ 2）：`-{N-1}`

偵測後綴編號：用 `Glob` 列出 `YYYY-MM-DD_{subject}*.md`，取現有最大 `-N` +1（若無匹配則第 1 封無後綴；有 1 個匹配則 `-1`）。

範例（來自 `tatsuma/communications/`）：

| Subject | 順序 | 檔名 |
|---------|------|------|
| `Re: sabbatical year` | 第 1 封 | `2023-08-28_Re--sabbatical-year.md` |
| `翻訳のお願い` | 第 1 封 | `2024-03-26_翻訳のお願い.md` |
| `NTU PSY seminar 2024 final PPT` | 第 1 封 | `2024-04-04_NTU-PSY-seminar-2024-final-PPT.md` |
| `Re: Poster at 九州心理学会` | 第 4 封 | `2024-11-20_Re--Poster-at-九州心理学会-3.md` |
| `(空白 subject)` | 第 1 封 | `2026-04-08_no-subject.md` |

> **歷史相容 note**：`communications/` 有少量 `-a` / `-b` 字母後綴（如 `2024-07-14_...-a.md`）。新規不遷移舊檔，但新檔**一律用 `-1` `-2` `-3` 數字後綴**。若混用造成困擾，另開 follow-up issue。

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

### Step 5.5: 下載並分流附件

對每封已歸檔的新郵件：

1. **列出附件**：呼叫 `mcp__plugin_che-apple-mail-mcp_mail__list_attachments`（或 `list_attachments_batch`）取得附件清單。若為空 → 跳到下一封。

2. **分類每個附件**：用 Step 2 載入的分類規則判斷 `data` 或 `document`：

   ```
   classify(filename):
     lowercase_name = filename.lowercased()
     ext = filename 的副檔名（去掉 `.`）

     # Tier 1: keyword match（先比 data_keywords）
     for kw in data_keywords:
       if lowercase_name contains kw → return "data"
     for kw in document_keywords:
       if lowercase_name contains kw → return "document"

     # Tier 2: extension match
     if ext in data_extensions → return "data"
     if ext in document_extensions → return "document"

     # Tier 3: fallback
     return "document"
   ```

3. **決定目標路徑**：
   - `"data"` → `{data_dir}/{original_filename}`
   - `"document"` → `{documents_dir}/{email_md_stem}/{original_filename}`
   
   其中 `email_md_stem` 是該封信的 Markdown 檔名去掉 `.md`（例如 `2026-04-08_Re--Taxometric-Analysis`）。

4. **下載**：呼叫 `mcp__plugin_che-apple-mail-mcp_mail__save_attachment` 將附件存到目標路徑。
   - 檔名保留原始 bytes（空白、`&`、中日文、emoji 不改）
   - 目標目錄若不存在，先 `mkdir -p`
   - 若 `save_attachment` 失敗，log warning 繼續下一個（不中斷歸檔）

5. **更新 Markdown**：在該封信的 Markdown 中插入 `Attachments:` 區塊。

   **放置位置**：簽名（signature）之後、thread quote 之前。
   Thread quote 的辨識 pattern：第一個匹配 `差出人:` / `寄件者:` / `From:` / `On .* wrote:` 的行。
   若沒有 thread quote（原始信件，非回覆），`Attachments:` 接在 body 最後。

   **連結格式**：
   ```markdown
   Attachments:
   - [原始檔名](相對路徑URL編碼) (大小 KB)
   ```

   URL 編碼規則（僅用於 Markdown link URL，display text 保留原始）：
   - 空白 → `%20`
   - `&` → `%26`
   - 其餘（含中日文）→ 保留原字元

   範例：
   ```markdown
   Attachments:
   - [Figures & Tables20260408.docx](attachments/2026-04-08_Re--Taxometric-Analysis/Figures%20%26%20Tables20260408.docx) (93 KB)
   - [raw_indicators.csv](../../data/raw/raw_indicators.csv) (12 KB)
   ```

6. **回覆信無附件但引用原信附件時**：若 `list_attachments` 為空，但 body 中出現 `<filename.ext>` 形式的引用標記（Mail.app 的 quote-time marker），插入 cross-reference：

   ```markdown
   Attachments:
   (Attachments on the original email from {original_sender} — see `{original_stem}.md`)
   ```

   若無法推斷原始 stem（原信未歸檔），改為：
   ```markdown
   (Attachments referenced in thread quote — original not yet archived)
   ```

7. **累計計數**：記錄 `data_count` 和 `document_count`，供 Step 7 報告用。

### Step 6: 更新索引

將新歸檔的郵件加入索引：

```json
{
  "version": "1.0",
  "last_updated": "YYYY-MM-DD",
  "emails": {
    "message-id@example.com": {
      "file": "2026-01-13_Meeting-notes.md",
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

過濾條件: user@example.com
輸出目錄: communication/emails

新歸檔: 5 封
  - 2026-01-13_Meeting-request.md
  - 2026-01-12_Report-feedback.md
  - ...

跳過（已歸檔）: 12 封

附件: 15 個下載
  → 4 to data/raw
  → 11 to correspondence/attachments

═══════════════════════════════════════════
```

若無附件：`附件: 0 個下載`（不顯示分類明細）。

## 注意事項

- 使用 apple-mail MCP，需確保 MCP server 已連接
- Message-ID 用於去重，確保不會重複歸檔
- 寄出的郵件不產生「重點摘要」和「待辦事項」
- **附件自動下載**（v2.3.0+）：每封歸檔信件的附件會自動下載到分類目錄。研究資料檔（csv / sav / xlsx 等）放到 `data/raw/`；文件附件（pdf / docx 等）放到 `correspondence/attachments/{email_stem}/`。可透過 `.claude/emails.md` 的 `attachment_routing` 區塊自訂規則。

## 附件分類設定範例

在 `.claude/emails.md` front matter 加入 `attachment_routing` 覆寫預設規則。**注意：partial override 取代所有預設**——省略的欄位會變成空列表，不會自動使用內建預設。

完整預設值（供 copy-paste）：

```yaml
---
filters:
  - tatsuma
attachment_routing:
  data_extensions: [csv, tsv, sav, dta, parquet, feather, xlsx, sas7bdat]
  document_extensions: [pdf, docx, doc, txt, md, rtf, odt]
  data_keywords: [data, raw, indicators, codebook, dataset]
  document_keywords: [Submission, Figures, Tables, Manuscript, draft, Revision, v1, v2, v3]
  data_dir: data/raw
  documents_dir: correspondence/attachments
---
```

只需列出想改的部分（但理解：列出即取代整組預設）：

```yaml
---
attachment_routing:
  data_extensions: [csv, sav]            # 只認這兩種為 data
  data_keywords: [raw, indicators]       # 窄化 keyword
  data_dir: research/raw-data            # 自訂 data 目標路徑
  documents_dir: correspondence/attachments  # 保留預設
---
```
