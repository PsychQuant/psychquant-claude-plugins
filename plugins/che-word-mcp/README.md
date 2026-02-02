# che-word-mcp

**Word MCP Server** - Swift 原生 OOXML 操作，支援完整 Word 文件處理。

## 功能概覽

提供 105 個工具，涵蓋 Word 文件的所有操作需求：

### 文件管理 (6 個)
- `create_document`, `open_document`, `save_document`, `close_document`
- `list_open_documents`, `get_document_info`

### 內容操作 (7 個)
- `get_text`, `get_document_text`, `get_paragraphs`, `insert_paragraph`
- `update_paragraph`, `delete_paragraph`, `replace_text`, `insert_text`, `search_text`

### 格式設定 (9 個)
- `format_text`, `set_paragraph_format`, `apply_style`
- `set_paragraph_border`, `set_paragraph_shading`, `set_character_spacing`, `set_text_effect`
- `get_paragraph_runs`, `get_text_with_formatting`, `search_by_formatting`

### 表格 (6 個)
- `insert_table`, `get_tables`, `update_cell`, `delete_table`
- `merge_cells`, `set_table_style`

### 樣式管理 (4 個)
- `list_styles`, `create_style`, `update_style`, `delete_style`

### 清單 (3 個)
- `insert_bullet_list`, `insert_numbered_list`, `set_list_level`

### 頁面設定 (5 個)
- `set_page_size`, `set_page_margins`, `set_page_orientation`
- `insert_page_break`, `insert_section_break`

### 頁首頁尾 (5 個)
- `add_header`, `update_header`, `add_footer`, `update_footer`, `insert_page_number`

### 圖片 (9 個)
- `insert_image`, `insert_image_from_path`, `insert_floating_image`
- `update_image`, `delete_image`, `list_images`, `set_image_style`
- `export_image`, `export_all_images`

### 匯出 (2 個)
- `export_text`, `export_markdown`

### 超連結與書籤 (8 個)
- `insert_hyperlink`, `insert_internal_link`, `update_hyperlink`, `delete_hyperlink`
- `insert_bookmark`, `delete_bookmark`, `list_hyperlinks`, `list_bookmarks`

### 註解與修訂 (12 個)
- `insert_comment`, `update_comment`, `delete_comment`, `list_comments`
- `reply_to_comment`, `resolve_comment`
- `enable_track_changes`, `disable_track_changes`
- `accept_revision`, `reject_revision`, `get_revisions`
- `accept_all_revisions`, `reject_all_revisions`

### 註腳與尾注 (6 個)
- `insert_footnote`, `delete_footnote`, `list_footnotes`
- `insert_endnote`, `delete_endnote`, `list_endnotes`

### 欄位代碼 (7 個)
- `insert_if_field`, `insert_calculation_field`, `insert_date_field`
- `insert_page_field`, `insert_merge_field`, `insert_sequence_field`
- `insert_content_control`

### 進階功能 (7 個)
- `insert_repeating_section`, `insert_toc`
- `insert_text_field`, `insert_checkbox`, `insert_dropdown`
- `insert_equation`, `get_document_properties`, `set_document_properties`

### 學術文件分析 (3 個) - v1.6.0 新增
- `search_text_with_formatting` - 搜尋文字並顯示格式（粗體、斜體、顏色標記）
- `list_all_formatted_text` - 列出所有特定格式文字（如所有斜體詞彙）
- `get_word_count_by_section` - 按區段統計字數（可排除參考文獻）

### 文件比對 (1 個) - v1.7.0 新增
- `compare_documents` - Server-side 段落層級文件比對（支援 text/formatting/structure/full 四種模式）

## 安裝

### 1. 編譯 Binary

```bash
cd /path/to/che-word-mcp
swift build -c release
cp .build/release/CheWordMCP ~/bin/
```

### 2. 安裝 Plugin

```bash
claude /plugin che-word-mcp
```

## 使用範例

```
# 建立新文件
create_document: { "doc_id": "mydoc" }

# 插入段落
insert_paragraph: { "doc_id": "mydoc", "text": "Hello World", "style": "Heading1" }

# 插入圖片（推薦使用路徑方式）
insert_image_from_path: { "doc_id": "mydoc", "path": "/path/to/image.png", "width": 400, "height": 300 }

# 儲存文件
save_document: { "doc_id": "mydoc", "path": "/path/to/output.docx" }
```

## 技術細節

- **語言**: Swift
- **MCP SDK**: swift-sdk 0.10.2
- **OOXML**: ooxml-swift (Pure Swift)
- **平台**: macOS 13.0+

## 版本

- **當前版本**: 1.7.0
- **專案位置**: `/Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/mcp/che-word-mcp`
- **GitHub**: https://github.com/kiki830621/che-word-mcp
