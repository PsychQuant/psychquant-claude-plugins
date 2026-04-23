# che-word-mcp

**Word MCP Server** — Swift 原生 OOXML 操作，171+ 個工具，支援 Dual-Mode 存取 + preserve-by-default round-trip fidelity。

當前版本：**v3.5.0**（v3.0.0+ session state API、v3.1.0+ 9 個 readback CRUD 工具、v3.2.0+ 完整 LaTeX 子集、v3.3.0+ Phase 2A theme/header/footer/watermark 工具、v3.4.0+ Phase 2B+2C comment-thread/people/notes/web-settings 工具、v3.5.0+ true byte-preservation via dirty tracking）。

## 兩種操作模式

### Direct Mode（`source_path`）— 唯讀，免開啟

傳入檔案路徑直接使用，不需要先 `open_document`。適合快速檢視。

```
list_images: { "source_path": "/path/to/file.docx" }
search_text: { "source_path": "/path/to/file.docx", "query": "keyword" }
get_paragraphs: { "source_path": "/path/to/file.docx" }
```

### Session Mode（`doc_id`）— 完整讀寫生命週期

先 `open_document` 取得 `doc_id`，再進行編輯操作。

```
open_document: { "path": "/path/to/file.docx", "doc_id": "mydoc" }
insert_paragraph: { "doc_id": "mydoc", "text": "Hello World" }
save_document: { "doc_id": "mydoc", "path": "/path/to/output.docx" }
close_document: { "doc_id": "mydoc" }
```

v3.0.0+ 加入 session state 追蹤：dirty tracking、autosave、`finalize_document`、disk drift 偵測。

## Round-trip fidelity (v3.3.0+ → v3.5.0 true byte-preservation)

底層 `ooxml-swift v0.13.0+` 採用 **preserve-by-default + dirty tracking** 架構：`open_document` 保留原始 archive tempDir；`save_document` overlay 模式透過 `WordDocument.modifiedParts: Set<String>` 精確判斷哪些 part 真正被改動，**未改動的 typed-managed part 完全不重寫**——byte-for-byte 保留 `word/theme/`、`webSettings.xml`、`people.xml`、`commentsExtended/Extensible/Ids`、`glossary/`、`customXml/`、**以及 `word/document.xml`、`styles.xml`、`fontTable.xml`、`header*.xml`、`footer*.xml`、`comments.xml`、`footnotes.xml`、`endnotes.xml`** 等所有 typed parts。

**v3.2.0–v3.4.0 修復進程**：
- v3.2.0 之前 `save_document` 會把 6 個 header / 4 個 footer / theme / fontTable 等全部 strip → NTPU 學位論文模板的中文字體（DFKai-SB / 華康中楷體）會 fallback 到 Times New Roman。
- v3.3.0+ preserve-by-default 修復了**未知 part**（theme / customXml / glossary）的保留。
- v3.4.0+ 仍有 round-2 bug：**typed-managed parts**（fontTable、styles、header/footer）每次 save 都被重寫，13 個自訂字體仍會被收斂成 hardcoded 3-entry default。
- **v3.5.0 終結**：dirty tracking 確保未改動的 typed parts 也跳過重寫。Reader-loaded NTPU 論文 no-op `save_document` 後 13 fontTable + 6 distinct headers + 4 footers + three-segment PAGE field + `<w15:presenceInfo>` identity 全部完整保留。Closes [#23 round-2](https://github.com/PsychQuant/che-word-mcp/issues/23) + [#32](https://github.com/PsychQuant/che-word-mcp/issues/32) + [#33](https://github.com/PsychQuant/che-word-mcp/issues/33) + [#34](https://github.com/PsychQuant/che-word-mcp/issues/34)。

## Direct Mode 支援的工具

| 類別 | 工具 |
|------|------|
| 讀取內容 | `get_text`, `get_document_text`, `get_paragraphs`, `get_document_info`, `search_text` |
| 列出元素 | `list_images`, `list_styles`, `get_tables`, `list_comments`, `list_hyperlinks`, `list_bookmarks`, `list_footnotes`, `list_endnotes`, `get_revisions` |
| 屬性 | `get_document_properties`, `get_section_properties`, `get_word_count_by_section` |
| 匯出 | `export_markdown` |

## 工具總覽

### 文件管理 + Session 生命週期（v3.0.0+）
- `create_document`, `open_document`, `save_document`, `close_document`, `finalize_document`
- `list_open_documents`, `get_document_info` ⚡, `get_document_session_state`, `get_session_state`
- `check_disk_drift`, `revert_to_disk`, `reload_from_disk`

### 內容操作
- `get_text` ⚡, `get_document_text` ⚡, `get_paragraphs` ⚡, `search_text` ⚡, `search_text_batch` (v2.2+)
- `insert_paragraph`, `update_paragraph`, `delete_paragraph`
- `replace_text`, `replace_text_batch` (v2.2+), `insert_text`

### 格式設定
- `format_text`, `set_paragraph_format`, `apply_style`
- `set_paragraph_border`, `set_paragraph_shading`, `set_character_spacing`, `set_text_effect`
- `get_paragraph_runs`, `get_text_with_formatting`, `search_by_formatting`

### 表格
- `insert_table`, `get_tables` ⚡, `update_cell`, `delete_table`
- `merge_cells`, `set_table_style`, `set_table_alignment`
- `add_row_to_table`, `add_column_to_table`, `delete_row_from_table`, `delete_column_from_table`
- `set_cell_width`, `set_row_height`, `set_cell_vertical_alignment`, `set_header_row`

### 樣式管理
- `list_styles` ⚡, `create_style`, `update_style`, `delete_style`

### 清單
- `insert_bullet_list`, `insert_numbered_list`, `set_list_level`

### 頁面設定 + 區段
- `set_page_size`, `set_page_margins`, `set_page_orientation`
- `set_page_borders`, `set_columns`, `set_line_numbers`, `set_text_direction`
- `insert_page_break`, `insert_section_break`, `insert_continuous_section_break`

### 頁首頁尾 + 浮水印（v3.3.0+ 補完）
- 寫入：`add_header`, `update_header`, `add_footer`, `update_footer`, `insert_page_number`
- 列舉與讀取（v3.3.0+）：`list_headers`, `get_header`, `list_footers`, `get_footer`
- 刪除（v3.3.0+）：`delete_header`, `delete_footer`
- 浮水印：`insert_watermark`, `insert_image_watermark`, `remove_watermark`, `list_watermarks` (v3.3.0+), `get_watermark` (v3.3.0+)

### 主題編輯（v3.3.0+，#28）
- `get_theme` — 讀 major/minor 字體 + 色盤
- `update_theme_fonts` — 部分更新字體 slot（latin/ea/cs）。**用於 NTPU 論文中文字體修復**：`update_theme_fonts({ minor: { ea: "DFKai-SB" }})`
- `update_theme_color` — slot-named hex color 更新（accent1-6 / hyperlink / followedHyperlink）
- `set_theme` — 完整 theme XML 覆寫 escape hatch

### 圖片
- `insert_image`, `insert_image_from_path`, `insert_floating_image`
- `update_image`, `delete_image`, `list_images` ⚡, `set_image_style`
- `export_image`, `export_all_images`

### 數學公式（v3.2.0+ 完整 LaTeX 子集）
- `insert_equation` — 接受完整 LaTeX 子集（透過 [`latex-math-swift`](https://github.com/PsychQuant/latex-math-swift)）：`\frac`, `\sqrt`, `\hat`/`\bar`/`\tilde`, `\left/\right`, `\sum`/`\int`/`\prod` (with bounds), `\ln`/`\sin`/`\cos`/`\tan`/`\log`/`\exp`/`\max`/`\min`/`\det`, `\sup`/`\inf`/`\lim`, `\text{}`, 全部希臘字母（含 `\varepsilon` 變體）+ 常用運算子
- `list_equations`, `get_equation`, `update_equation`, `delete_equation` (v3.1.0+ readback)

### 匯出
- `export_text`, `export_markdown` ⚡, `export_revision_summary_markdown`, `export_comment_threads_markdown`

### 超連結與書籤
- `insert_hyperlink`, `insert_internal_link`, `update_hyperlink`, `delete_hyperlink`
- `insert_bookmark`, `delete_bookmark`, `list_hyperlinks` ⚡, `list_bookmarks` ⚡

### 註解（v3.4.0+ 補完 thread 管理）
- 寫入：`insert_comment`, `update_comment`, `delete_comment`, `reply_to_comment`, `resolve_comment`
- 讀取：`list_comments` ⚡
- Thread 管理（v3.4.0+，#29）：`list_comment_threads`, `get_comment_thread`, `sync_extended_comments`

### People (comment authors，v3.4.0+，#30 → v3.5.0 dual identity #34)
- `list_people` — v3.5.0 解析完整 `<w15:presenceInfo>` 子元素，回傳 dual identity：
  - `person_id` (GUID, 來自 `userId="S::email::guid"` 第三段)，rename 跨版本穩定
  - `display_name_id` (= author，v3.4.0 legacy id)
  - `display_name`, `email`, `color`, `provider_id`
- `add_person`, `update_person`, `delete_person` — v3.5.0 update/delete 接受 GUID **或** legacy author 任一形式（向後相容 v3.4.0）

### 修訂
- `enable_track_changes`, `disable_track_changes`
- `accept_revision`, `reject_revision`, `get_revisions` ⚡
- `accept_all_revisions`, `reject_all_revisions`
- `compare_documents`, `compare_documents_markdown`

### 註腳與尾注（v3.4.0+ 補完 update）
- 寫入：`insert_footnote`, `delete_footnote`, `insert_endnote`, `delete_endnote`
- 讀取：`list_footnotes` ⚡, `list_endnotes` ⚡
- v3.4.0+（#24 #25）：`get_footnote`, `update_footnote`, `get_endnote`, `update_endnote`（in-place 替換、保留 ID）

### 標號與目錄
- `insert_caption`, `list_captions`, `get_caption`, `update_caption`, `delete_caption` (v3.1.0+，#17)
- `insert_table_of_figures`, `insert_index`, `insert_index_entry`
- `update_all_fields` (v3.1.0+，#19) — F9 等價，全文 SEQ 重算
- `insert_cross_reference`

### Web Settings（v3.4.0+，#31）
- `get_web_settings`, `update_web_settings` — `relyOnVML` / `optimizeForBrowser` / `allowPNG` / `doNotSaveAsSingleFile`

### 屬性與保護
- `get_document_properties` ⚡, `set_document_properties`
- `get_section_properties` ⚡, `get_word_count_by_section` ⚡
- `protect_document`, `unprotect_document`, `set_document_password`, `remove_document_password`
- `restrict_editing_region`

### 欄位代碼
- `insert_date_field`, `insert_page_field`, `insert_sequence_field`, `insert_merge_field`
- `insert_calculation_field`, `insert_if_field`, `insert_text_field`

### 進階格式
- 表單控件（`insert_checkbox`, `insert_dropdown`, `insert_content_control`, `insert_repeating_section`）
- 分欄、tab stops、drop cap、horizontal line、symbol
- `insert_horizontal_line`, `insert_drop_cap`, `insert_symbol`, `insert_column_break`
- `insert_tab_stop`, `clear_tab_stops`
- `set_keep_lines`, `set_keep_with_next`, `set_widow_orphan`, `set_outline_level`, `set_page_break_before`
- 字體和語言：`set_language`

⚡ = 支援 Direct Mode

## 技術細節

- **語言**: Swift（macOS 13.0+）
- **MCP SDK**: swift-sdk 0.12+
- **OOXML 引擎**: [`ooxml-swift v0.13.0+`](https://github.com/PsychQuant/ooxml-swift)（preserve-by-default + dirty tracking 架構）
- **LaTeX parser**: [`latex-math-swift v0.1.0+`](https://github.com/PsychQuant/latex-math-swift)（v3.2.0+）
- **Markdown export**: [`word-to-md-swift`](https://github.com/PsychQuant/word-to-md-swift) + [`markdown-swift`](https://github.com/PsychQuant/markdown-swift)

## 版本

- **當前版本**: v3.5.0
- **GitHub**: https://github.com/PsychQuant/che-word-mcp
- **完整 CHANGELOG**: https://github.com/PsychQuant/che-word-mcp/blob/main/CHANGELOG.md
- **專案位置**（開發者）: `/Users/che/Developer/macdoc/mcp/che-word-mcp`

### 重要 milestones

- **v3.0.0** — Session state API（dirty tracking, autosave, finalize_document, disk drift detection）— closes #12 #13 #15
- **v3.1.0** — 9 個 readback tools（Caption CRUD, update_all_fields, Equation CRUD）— closes #17 #19 #21
- **v3.2.0** — `insert_equation` LaTeX parser delegated to `latex-math-swift`，支援完整 LaTeX 子集 — closes #22
- **v3.3.0** — Phase 2A: 12 個 theme/header/footer/watermark 工具 — closes #26 #27 #28
- **v3.4.0** — Phase 2B+2C: 13 個 comment-thread/people/notes-update/web-settings 工具 — closes #24 #25 #29 #30 #31
- **v3.5.0** — true byte-preservation via dirty tracking — Reader-loaded 文件 no-op save 後完整保留 13 fontTable + 6 distinct headers + 4 footers + three-segment PAGE field + `<w15:presenceInfo>` identity；Server.swift archive-write helpers 全面 wire `markPartDirty`；`extractPeople` 多行 regex 支援 GUID dual identity — closes #23 round-2 + #32 #33 #34

### 底層架構里程碑

- **`ooxml-swift v0.13.0`** — true byte-preservation via dirty tracking（`modifiedParts: Set<String>` + `Header.originalFileName` + overlay-mode skip-when-not-dirty），closes #23 round-2
- **`ooxml-swift v0.12.0`** — preserve-by-default 架構（PreservedArchive + RelationshipIdAllocator + ContentTypesOverlay），closes #23 P0 round-trip fidelity bug
- **`ooxml-swift v0.11.0`** — `MathAccent` for OMML accent decorators
- **`ooxml-swift v0.10.0`** — `FieldParser` + `OMMLParser` readback primitives
