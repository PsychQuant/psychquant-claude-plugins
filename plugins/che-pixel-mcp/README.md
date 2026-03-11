# che-pixel-mcp

**Pixel MCP Server** — Swift 原生 Core Image 操作，36 個工具，200+ 濾鏡，Session-based 點陣圖形編輯。

## Session 生命週期

```
create_document / open_document → 取得 doc_id
adjust_colors / gaussian_blur / crop / ... → 編輯
save_document → 寫入檔案（PNG, JPEG, TIFF, HEIC）
close_document → 釋放記憶體
```

## 工具一覽（36 個）

### 文件管理 (7)
`create_document`, `open_document`, `save_document`, `close_document`, `list_documents`, `get_image_info`, `get_document_info`

### 色彩調整 (2)
`adjust_colors` — brightness, contrast, saturation, hue, exposure, gamma, vibrance, highlights, shadows, temperature, tint
`auto_enhance` — Core Image 自動增強

### 濾鏡 (5)
`apply_filter`, `apply_filter_chain`, `gaussian_blur`, `sharpen`, `unsharp_mask`

### 風格化 (10)
`vignette`, `sepia_tone`, `monochrome`, `noise_reduction`, `pixellate`, `bloom`, `edges`, `comic_effect`, `crystallize`, `pointillize`

### 區域操作 (4)
`crop`, `resize`, `rotate`, `flip`

### 合成 (1)
`composite` — 16 種混合模式（normal, multiply, screen, overlay, ...）

### 變形 (2)
`bump_distortion`, `twirl_distortion`

### 批次與工具 (5)
`batch_process`, `undo`, `get_preview`, `list_filters`, `filter_info`

## 架構

```
PixelDocument     ← CIImage lazy pipeline（不到 export 不運算）
├── FilterChain   ← 200+ Core Image filters
├── RegionOps     ← crop, resize, rotate, flip
├── ColorOps      ← levels, curves, HSB, white balance
├── Composite     ← 16 blend modes
└── ExportEngine  ← CGImage → PNG, JPEG, TIFF, HEIC
```

## 技術細節

- **語言**: Swift
- **影像引擎**: Core Image (lazy CIImage pipeline)
- **匯出**: AppKit + CGImageDestination
- **平台**: macOS 13.0+
- **GitHub**: https://github.com/PsychQuant/che-pixel-mcp
