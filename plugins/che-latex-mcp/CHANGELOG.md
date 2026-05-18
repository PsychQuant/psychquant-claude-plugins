# Changelog

All notable changes to che-latex-mcp will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0] - 2026-05-18

### Added — Pillar 5: Annotation-driven workflow

通用的 PDF review 工作流支援。MCP 從 18 → 20 tools。

- `extract_annotations(pdf_path)` — 從 reviewed PDF 抽出所有 annotations（FreeText / Text / Note / Highlight），含 page + bbox + comment + surrounding text，JSON 結構化回傳
- `annotation_to_source(surrounding_text, source_dir)` — 給 annotation surrounding text，grep source 找對應 file:line 候選，支援 `exclude_dirs` / `file_extensions` caller-supplied 參數

設計原則：MCP 只做 **generic primitive**（抽 raw annotation + grep source），**不做 classification / verification**。專案特有的分類規則由 caller skill / script 處理。

### Fixed

- **Server `waitUntilCompleted()` 缺失（CRITICAL）**：v0.4.0 起 `LatexMCPApp.main()` 缺 `await server.waitUntilCompleted()`，導致 stdio MCP server 在 `server.start()` 後立刻 return，process 收到第一個 request 就 exit。Plugin 連線 fragile。v0.5.0 修正
- Plugin description 改為強調 **通用 LaTeX 工具**（不綁定特定領域）

### Internal

- 新增 `Sources/che-latex-mcp/Pillar5Tools.swift` — Pillar 5 tool 實作
- 擴充 `Helpers.swift` — `PDFAnnotationData` / `AnnotationExtractor` / `SourceLine` / `SourceIndex`（全 generic，無 project-specific 假設）
- `SourceIndex.load()` 接 caller-supplied `excludeDirs` + `fileExtensions`，default 不排除任何 dir

## [0.4.0] - 2026-05-18

### Added

- 初版 plugin（wrap che-latex-mcp v0.4.0 binary）
- MCP server 含 18 個 tool（8 既有 + 10 新增）
- 4 個 LaTeX-specific skill：
  - `latex-validate` — 編譯後 layout audit pipeline
  - `latex-visual-diff` — git ref 對照視覺 diff
  - `latex-precompile` — source-level static check（標點/缺字/box）
  - `latex-preview-chunk` — 片段預覽不必編整本
- Wrapper script 從 GitHub Release auto-download binary
- 偏好 `~/Developer/che-mcps/che-latex-mcp` 下的 source build（手動 build 不會被 auto-replace）

### MCP server 新增 tools (v0.3.0 → v0.4.0)

- `compile_diff(git_ref)` — git worktree checkout + 編譯 + 跟當前 PDF 視覺 diff
- `compare_pdfs` — 兩 PDF 像素級 diff
- `compile_chunk` — standalone 編譯片段
- `preview_range` — 批次截多頁
- `get_page_metrics` — 單頁 layout 數據
- `extract_blocks` — block bbox + text
- `find_overlaps` — bbox 重疊偵測
- `detect_layout_issues` — 綜合 audit
- `fonts_check` — `.log` 缺字
- `box_warnings` — `.log` overfull/underfull
- `punct_check` — source 半形標點偵測
