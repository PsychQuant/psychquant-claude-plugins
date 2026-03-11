# che-svg-mcp

**SVG MCP Server** — Swift 原生 XML 操作，33 個工具，Session-based 向量圖形編輯。

## Session 生命週期

```
create_document / open_document → 取得 doc_id
add_rect / add_circle / ... → 編輯
save_document → 寫入檔案
close_document → 釋放記憶體
```

## 工具一覽（33 個）

### 文件管理 (5)
`create_document`, `open_document`, `save_document`, `close_document`, `list_documents`

### 元素建立 (10)
`add_rect`, `add_circle`, `add_ellipse`, `add_line`, `add_polyline`, `add_polygon`, `add_path`, `add_text`, `add_image`, `add_group`

### 元素操作 (6)
`list_elements`, `get_element`, `modify_element`, `delete_element`, `move_element`, `duplicate_element`

### 變形 (1)
`transform_element` — translate, rotate, scale, skewX, skewY

### 樣式 (1)
`set_style` — fill, stroke, opacity, font 等

### 漸層 (2)
`add_linear_gradient`, `add_radial_gradient`

### 匯出 (2)
`export_png`, `export_pdf`

### 預覽與資訊 (2)
`get_preview`, `get_svg_info`

### 批次操作 (2)
`batch_set_style`, `batch_transform`

### 工具 (2)
`get_svg_source`, `get_document_stats`

## 技術細節

- **語言**: Swift
- **XML**: Foundation XMLDocument/XMLElement
- **匯出**: AppKit (NSImage → PNG, CGContext → PDF)
- **平台**: macOS 13.0+
- **GitHub**: https://github.com/PsychQuant/che-svg-mcp
