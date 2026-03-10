# che-word-mcp

**Word MCP Server** - Swift 原生 OOXML 操作，146 個工具，支援 Dual-Mode 存取。

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

## Direct Mode 支援的工具（18 個）

| 類別 | 工具 |
|------|------|
| 讀取內容 | `get_text`, `get_document_text`, `get_paragraphs`, `get_document_info`, `search_text` |
| 列出元素 | `list_images`, `list_styles`, `get_tables`, `list_comments`, `list_hyperlinks`, `list_bookmarks`, `list_footnotes`, `list_endnotes`, `get_revisions` |
| 屬性 | `get_document_properties`, `get_section_properties`, `get_word_count_by_section` |
| 匯出 | `export_markdown` |

## 功能概覽（146 個工具）

### 文件管理 (6 個)
- `create_document`, `open_document`, `save_document`, `close_document`
- `list_open_documents`, `get_document_info` ⚡

### 內容操作 (9 個)
- `get_text` ⚡, `get_document_text` ⚡, `get_paragraphs` ⚡, `search_text` ⚡
- `insert_paragraph`, `update_paragraph`, `delete_paragraph`, `replace_text`, `insert_text`

### 格式設定 (9 個)
- `format_text`, `set_paragraph_format`, `apply_style`
- `set_paragraph_border`, `set_paragraph_shading`, `set_character_spacing`, `set_text_effect`
- `get_paragraph_runs`, `get_text_with_formatting`, `search_by_formatting`

### 表格 (11 個)
- `insert_table`, `get_tables` ⚡, `update_cell`, `delete_table`
- `merge_cells`, `set_table_style`, `set_table_alignment`
- `add_row_to_table`, `add_column_to_table`, `delete_row_from_table`, `delete_column_from_table`
- `set_cell_width`, `set_row_height`, `set_cell_vertical_alignment`, `set_header_row`

### 樣式管理 (4 個)
- `list_styles` ⚡, `create_style`, `update_style`, `delete_style`

### 清單 (3 個)
- `insert_bullet_list`, `insert_numbered_list`, `set_list_level`

### 頁面設定 (5 個)
- `set_page_size`, `set_page_margins`, `set_page_orientation`
- `insert_page_break`, `insert_section_break`

### 頁首頁尾 (5 個)
- `add_header`, `update_header`, `add_footer`, `update_footer`, `insert_page_number`

### 圖片 (9 個)
- `insert_image`, `insert_image_from_path`, `insert_floating_image`
- `update_image`, `delete_image`, `list_images` ⚡, `set_image_style`
- `export_image`, `export_all_images`

### 匯出 (2 個)
- `export_text`, `export_markdown` ⚡

### 超連結與書籤 (8 個)
- `insert_hyperlink`, `insert_internal_link`, `update_hyperlink`, `delete_hyperlink`
- `insert_bookmark`, `delete_bookmark`, `list_hyperlinks` ⚡, `list_bookmarks` ⚡

### 註解與修訂 (13 個)
- `insert_comment`, `update_comment`, `delete_comment`, `list_comments` ⚡
- `reply_to_comment`, `resolve_comment`
- `enable_track_changes`, `disable_track_changes`
- `accept_revision`, `reject_revision`, `get_revisions` ⚡
- `accept_all_revisions`, `reject_all_revisions`

### 註腳與尾注 (6 個)
- `insert_footnote`, `delete_footnote`, `list_footnotes` ⚡
- `insert_endnote`, `delete_endnote`, `list_endnotes` ⚡

### 屬性與區段 (3 個)
- `get_document_properties` ⚡, `set_document_properties`
- `get_section_properties` ⚡, `get_word_count_by_section` ⚡

### 進階功能
- 欄位代碼、表單控件、目錄、浮水印、文件保護、索引、方程式等

⚡ = 支援 Direct Mode

## 技術細節

- **語言**: Swift
- **MCP SDK**: swift-sdk 0.11.0
- **OOXML**: ooxml-swift 0.5.2 (Pure Swift)
- **平台**: macOS 13.0+

## 版本

- **當前版本**: 1.16.0
- **專案位置**: `/Users/che/Developer/macdoc/mcp/che-word-mcp`
- **GitHub**: https://github.com/kiki830621/che-word-mcp
