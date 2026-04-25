# che-word-mcp

**Word MCP Server** — Swift 原生 OOXML 操作，**233 個工具**，支援 Dual-Mode 存取 + preserve-by-default round-trip fidelity + programmatic Track Changes 生成 + `document.xml` lossless round-trip。

當前版本：**v3.13.2**（Plugin shell + Binary 同步）

Office.js OOXML Roadmap **P0 100% 完成**（Umbrella issue [#43](https://github.com/PsychQuant/che-word-mcp/issues/43)）。Latest milestone v3.13.2 bumps `ooxml-swift` to v0.19.2，修正 [#56](https://github.com/PsychQuant/che-word-mcp/issues/56) verification 找到的 4 個 blocking findings（F1 Hyperlink.toXML 真正 emit Reader 解出的 runs/rawAttributes/rawChildren、F2 addBookmark/deleteBookmark 同步 bookmarkMarkers、F3 ins/del/moveFrom/moveTo round-trip 保留 position+revisionId 與 wrapper、F4 namespace 保留從 document.xml 擴展到 header/footer/footnote/endnote）— 無 source 變更。v3.13.0 ship `document.xml` lossless round-trip + tool-mediated wrapper edits 主架構（closes #56 P0），v3.13.1 是 pPr double-emission hot-fix — 詳見 [CHANGELOG](https://github.com/PsychQuant/che-word-mcp/blob/main/CHANGELOG.md)。v3.12.0 ship programmatic Track Changes 寫側（[#45](https://github.com/PsychQuant/che-word-mcp/issues/45)）。

## 兩種操作模式

### Direct Mode（`source_path`）— 唯讀，免開啟

傳入檔案路徑直接使用，不需要先 `open_document`。適合快速檢視。

```
list_images:    { "source_path": "/path/to/file.docx" }
search_text:    { "source_path": "/path/to/file.docx", "query": "keyword" }
get_paragraphs: { "source_path": "/path/to/file.docx" }
```

### Session Mode（`doc_id`）— 完整讀寫生命週期

先 `open_document` 取得 `doc_id`，再進行編輯操作。

```
open_document:    { "path": "/path/to/file.docx", "doc_id": "mydoc" }
insert_paragraph: { "doc_id": "mydoc", "text": "Hello World" }
save_document:    { "doc_id": "mydoc", "path": "/path/to/output.docx" }
close_document:   { "doc_id": "mydoc" }
```

v3.0.0+ session state 追蹤：dirty tracking、autosave、`finalize_document`、disk drift 偵測。

## Round-trip Fidelity（v3.5.0 true byte-preservation）

底層 `ooxml-swift v0.19.2` 採用 **preserve-by-default + dirty tracking** 架構：`open_document` 保留原始 archive tempDir；`save_document` overlay 模式透過 `WordDocument.modifiedParts: Set<String>` 精確判斷哪些 part 真正被改動，**未改動的 typed-managed part 完全不重寫**——byte-for-byte 保留 `word/theme/`、`webSettings.xml`、`people.xml`、`commentsExtended/Extensible/Ids`、`glossary/`、`customXml/`、**以及 `word/document.xml`、`styles.xml`、`fontTable.xml`、`header*.xml`、`footer*.xml`、`comments.xml`、`footnotes.xml`、`endnotes.xml`** 等所有 typed parts。v0.19.x 額外解決 #56 P0：`<w:document>` root 34 個 `xmlns:*` declarations 完整保留，`<w:bookmarkStart>` / `<w:hyperlink>` / `<w:fldSimple>` / `<mc:AlternateContent>` 結構化 wrapper 全程 round-trip（pre-v0.19.0 會 silently 丟掉 wrapper 內 354 個 `<w:t>` text nodes）。

NTPU 學位論文模板的中文字體（DFKai-SB / 華康中楷體）no-op `save_document` 後完整保留 13 fontTable + 6 distinct headers + 4 footers + three-segment PAGE field + `<w15:presenceInfo>` identity。

## Track Changes 寫側合約（v3.12.0+）

兩條路徑：**accept/reject 既有修訂** OR **程式化生成新修訂**。

### 程式化生成（v3.12.0 新增）

```
1. enable_track_changes(doc_id, author: "Reviewer A")
2. insert_text_as_revision(doc_id, paragraph_index, position, text)
   delete_text_as_revision(doc_id, paragraph_index, start, end)
   move_text_as_revision(doc_id, source/dest)
   format_text(doc_id, paragraph_index, bold: true, as_revision: true)
   set_paragraph_format(doc_id, paragraph_index, alignment: "center", as_revision: true)
3. save_document(...)
```

**Author resolution 三層 fallback**：explicit `author` arg → `revisions.settings.author`（在 `enable_track_changes` 時設定）→ `"Unknown"`。

**Side-effect 合約**（重要）：`as_revision: true` 要求 track changes 已開啟。Disabled 時呼叫**會拋 `track_changes_not_enabled`**，不會偷偷 auto-enable。設計理由：避免 hidden state mutation。

### Accept / Reject 既有修訂

```
get_revisions / accept_revision / reject_revision / accept_all_revisions / reject_all_revisions
```

## Direct Mode 支援的工具

| 類別 | 工具 |
|------|------|
| 讀取內容 | `get_text`, `get_document_text`, `get_paragraphs`, `get_document_info`, `search_text` |
| 列出元素 | `list_images`, `list_styles`, `get_tables`, `list_comments`, `list_hyperlinks`, `list_bookmarks`, `list_footnotes`, `list_endnotes`, `get_revisions`, `list_content_controls` |
| 屬性 | `get_document_properties`, `get_section_properties`, `get_word_count_by_section` |
| 匯出 | `export_markdown` |

## 工具總覽

### 文件管理 + Session 生命週期（v3.0.0+）

- `create_document`, `open_document`, `save_document`, `close_document`, `finalize_document`
- `list_open_documents`, `get_document_info` ⚡, `get_document_session_state`, `get_session_state`
- `check_disk_drift`, `revert_to_disk`, `reload_from_disk`, `recover_from_autosave`, `checkpoint`

### 內容操作

- `get_text` ⚡, `get_document_text` ⚡, `get_paragraphs` ⚡, `search_text` ⚡, `search_text_batch`
- `insert_paragraph`, `update_paragraph`, `delete_paragraph`
- `replace_text`, `replace_text_batch`, `insert_text`

### 格式設定

- `format_text`（**v3.12.0+ `as_revision: bool`**）, `set_paragraph_format`（**v3.12.0+ `as_revision: bool`**）, `apply_style`
- `set_paragraph_border`, `set_paragraph_shading`, `set_character_spacing`, `set_text_effect`
- `get_paragraph_runs`, `get_text_with_formatting`, `search_by_formatting`, `search_text_with_formatting`, `list_all_formatted_text`

### 樣式管理（v3.10.0+ 強化，#48）

- `list_styles` ⚡, `apply_style`, `create_style`, `update_style`, `delete_style`
- v3.10.0 新增：`get_style_inheritance_chain`（含 cycle detection）, `link_styles`（`<w:link>` 段落+字元 pair）, `set_latent_styles`, `add_style_name_alias`（BCP 47 多語）
- `create_style` / `update_style` 新增 6 個 args：`based_on`, `linked_style_id`, `next_style_id`, `q_format`, `hidden`, `semi_hidden`

### Numbering / 編號清單（v3.10.0+ 完整補完，#46）

- 入門：`insert_bullet_list`, `insert_numbered_list`, `set_list_level`, `set_outline_level`
- 定義管理（v3.10.0 新增 8 個）：`list_numbering_definitions`, `get_numbering_definition`, `create_numbering_definition`（max 9 levels）, `override_numbering_level`, `assign_numbering_to_paragraph`, `continue_list`, `start_new_list`, `gc_orphan_numbering`

### 區段 / 頁面設定（v3.10.0+ 強化，#47）

- 基礎：`set_page_size`, `set_page_margins`, `set_page_orientation`, `set_page_borders`, `set_columns`, `set_line_numbers`, `set_text_direction`
- 區段斷點：`insert_page_break`, `insert_section_break`, `insert_continuous_section_break`, `insert_column_break`
- v3.10.0 新增 7 個：`set_line_numbers_for_section`（legal docs `<w:lnNumType>`）, `set_section_vertical_alignment`（封面置中）, `set_page_number_format`（羅馬數字等）, `set_section_break_type`, `set_title_page_distinct`, `set_section_header_footer_references`, `get_all_sections`

### 表格（v3.11.0+ 強化，#49）

- 基礎：`insert_table`, `get_tables` ⚡, `update_cell`, `delete_table`
- 結構：`merge_cells`, `set_table_style`, `set_table_alignment`
- 行列：`add_row_to_table`, `add_column_to_table`, `delete_row_from_table`, `delete_column_from_table`
- 尺寸：`set_cell_width`, `set_row_height`, `set_cell_vertical_alignment`, `set_header_row`
- v3.11.0 新增 5 個：`set_table_conditional_style`（10 種 region：firstRow / lastRow / bandedRows…），`insert_nested_table`（最深 5 層，超過拋 `nested_too_deep`），`set_table_layout`（fixed/autofit），`set_table_indent`（`<w:tblInd>`）

### 超連結（v3.11.0+ 三種 typed，#50）

- 基礎：`insert_hyperlink`, `update_hyperlink`, `delete_hyperlink`, `list_hyperlinks` ⚡
- 內部連結：`insert_internal_link`, `insert_cross_reference`
- v3.11.0 新增 3 個 typed：`insert_url_hyperlink`（外部 URL + tooltip + history flag），`insert_bookmark_hyperlink`（`w:anchor`，無 rId），`insert_email_hyperlink`（`mailto:` + URL-encoded subject）— 三者自動建 Hyperlink character style

### 頁首頁尾 + 浮水印（v3.3.0+ → v3.11.0+ 強化，#51）

- 寫入：`add_header`, `update_header`, `add_footer`, `update_footer`, `insert_page_number`
- 列舉與讀取：`list_headers`, `get_header`, `list_footers`, `get_footer`
- 刪除：`delete_header`, `delete_footer`
- v3.11.0 新增 4 個：`enable_even_odd_headers`（`<w:evenAndOddHeaders/>`），`link_section_header_to_previous` / `unlink_section_header_from_previous`（Word-compat clone），`get_section_header_map`
- 浮水印：`insert_watermark`, `insert_image_watermark`, `remove_watermark`, `list_watermarks`, `get_watermark`

### Content Controls / SDT（v3.9.0+ 完整 read/write，#44）

- 寫入：`insert_content_control`（12 type discrimination：richText / plainText / picture / date / dropDownList / comboBox / checkBox / bibliography / citation / group / repeatingSection / repeatingSectionItem）
- 讀取：`list_content_controls` ⚡（flat 或 nested tree mode），`get_content_control`（by id / tag / alias，回 metadata + `<w:sdtContent>` XML）
- 修改：`update_content_control_text`（preserves `<w:sdtPr>` byte-identical），`replace_content_control_content`（whitelist validation，拒絕含 `<w:sdt>` / `<w:body>` / `<w:sectPr>` 的 input）
- 刪除：`delete_content_control`（`keep_content: true` 預設 unwrap children）
- Repeating sections：`insert_repeating_section`, `list_repeating_section_items`, `update_repeating_section_item`
- 表單便利：`insert_checkbox`, `insert_dropdown`, `insert_text_field`
- v0.15.0 SDT id allocator 改 max+1 deterministic（取代 random）

### 主題編輯（v3.3.0+，#28）

- `get_theme` — 讀 major/minor 字體 + 色盤
- `update_theme_fonts` — 部分更新字體 slot（latin/ea/cs）。**用於 NTPU 論文中文字體修復**：`update_theme_fonts({ minor: { ea: "DFKai-SB" }})`
- `update_theme_color` — slot-named hex color 更新（accent1-6 / hyperlink / followedHyperlink）
- `set_theme` — 完整 theme XML 覆寫 escape hatch

### 圖片

- `insert_image`, `insert_image_from_path`, `insert_floating_image`
- `update_image`, `delete_image`, `list_images` ⚡, `set_image_style`
- `export_image`, `export_all_images`, `insert_drop_cap`

### 數學公式（v3.2.0+ 完整 LaTeX 子集）

- `insert_equation` — 透過 [`latex-math-swift`](https://github.com/PsychQuant/latex-math-swift)：`\frac`, `\sqrt`, `\hat`/`\bar`/`\tilde`, `\left/\right`, `\sum`/`\int`/`\prod`（with bounds），`\ln`/`\sin`/`\cos`/`\tan`/`\log`/`\exp`/`\max`/`\min`/`\det`，`\sup`/`\inf`/`\lim`，`\text{}`，全部希臘字母（含 `\varepsilon` 變體）+ 常用運算子
- `list_equations`, `get_equation`, `update_equation`, `delete_equation`

### 匯出

- `export_text`, `export_markdown` ⚡, `export_revision_summary_markdown`, `export_comment_threads_markdown`

### 註解（v3.4.0+ thread 管理）

- 寫入：`insert_comment`, `update_comment`, `delete_comment`, `reply_to_comment`, `resolve_comment`
- 讀取：`list_comments` ⚡
- Thread 管理：`list_comment_threads`, `get_comment_thread`, `sync_extended_comments`

### People / Comment Authors（v3.4.0+，v3.5.0 dual identity #34）

- `list_people` — 解析完整 `<w15:presenceInfo>`，回 dual identity：
  - `person_id` (GUID, 來自 `userId="S::email::guid"` 第三段)，rename 跨版本穩定
  - `display_name_id` (= author，v3.4.0 legacy id)
  - `display_name`, `email`, `color`, `provider_id`
- `add_person`, `update_person`, `delete_person` — 接受 GUID **或** legacy author 任一形式

### Track Changes / Revisions（v3.12.0 寫側 #45）

- 既有修訂處理：`enable_track_changes`, `disable_track_changes`, `get_revisions` ⚡, `accept_revision`, `reject_revision`, `accept_all_revisions`, `reject_all_revisions`
- **v3.12.0 程式化生成（NEW）**：
  - `insert_text_as_revision(doc_id, paragraph_index, position, text, author?, date?)` — `<w:ins>` 包覆，跨 run split 處理
  - `delete_text_as_revision(doc_id, paragraph_index, start, end, author?, date?)` — `<w:del>` 標記 + `<w:t>` → `<w:delText>` substitution（單段內，跨段 OOS）
  - `move_text_as_revision(doc_id, from_paragraph_index, from_start, from_end, to_paragraph_index, to_position, author?, date?)` — paired `<w:moveFrom>` / `<w:moveTo>` with adjacent revision ids
  - `format_text` 加 `as_revision: bool` → `<w:rPrChange>`
  - `set_paragraph_format` 加 `as_revision: bool` → `<w:pPrChange>`
- 比對：`compare_documents`, `compare_documents_markdown`

### 註腳與尾注（v3.4.0+ 補完 update）

- 寫入：`insert_footnote`, `delete_footnote`, `insert_endnote`, `delete_endnote`
- 讀取：`list_footnotes` ⚡, `list_endnotes` ⚡
- v3.4.0+：`get_footnote`, `update_footnote`, `get_endnote`, `update_endnote`（in-place 替換、保留 ID）

### 標號與目錄

- `insert_caption`, `list_captions`, `get_caption`, `update_caption`, `delete_caption`（v3.1.0+）
- `insert_table_of_figures`, `insert_index`, `insert_index_entry`, `insert_toc`
- `update_all_fields`（v3.1.0+，#19）— F9 等價，全文 SEQ 重算
- `insert_cross_reference`

### Custom XML / Web Settings

- `list_custom_xml_parts`（v3.9.0+ stub，real impl 待 Change B）
- `get_web_settings`, `update_web_settings`（v3.4.0+，#31）— `relyOnVML` / `optimizeForBrowser` / `allowPNG` / `doNotSaveAsSingleFile`

### 屬性與保護

- `get_document_properties` ⚡, `set_document_properties`
- `get_section_properties` ⚡, `get_word_count_by_section` ⚡
- `protect_document`, `unprotect_document`, `set_document_password`, `remove_document_password`
- `restrict_editing_region`

### 欄位代碼

- `insert_date_field`, `insert_page_field`, `insert_sequence_field`, `insert_merge_field`
- `insert_calculation_field`, `insert_if_field`, `insert_text_field`

### 進階格式 / 排版

- 分欄、tab stops、drop cap、horizontal line、symbol
- `insert_horizontal_line`, `insert_drop_cap`, `insert_symbol`, `insert_column_break`
- `insert_tab_stop`, `clear_tab_stops`
- `set_keep_lines`, `set_keep_with_next`, `set_widow_orphan`, `set_outline_level`, `set_page_break_before`
- 字體和語言：`set_language`

⚡ = 支援 Direct Mode

## 技術細節

- **語言**: Swift（macOS 13.0+）
- **MCP SDK**: swift-sdk 0.12+
- **OOXML 引擎**: [`ooxml-swift v0.19.2`](https://github.com/PsychQuant/ooxml-swift)（preserve-by-default + dirty tracking + revision generation + `document.xml` lossless round-trip）
- **LaTeX parser**: [`latex-math-swift v0.1.0+`](https://github.com/PsychQuant/latex-math-swift)（v3.2.0+）
- **Markdown export**: [`word-to-md-swift`](https://github.com/PsychQuant/word-to-md-swift) + [`markdown-swift`](https://github.com/PsychQuant/markdown-swift)

## 版本

- **Plugin shell**: v3.13.2
- **Binary**: v3.13.2（`CheWordMCP`）
- **GitHub**: https://github.com/PsychQuant/che-word-mcp
- **完整 CHANGELOG**: https://github.com/PsychQuant/che-word-mcp/blob/main/CHANGELOG.md

### Plugin Shell vs Binary 版本

兩者獨立但本次 v3.13.2 同步。Plugin shell（marketplace 端，含 SKILL.md / CLAUDE.md / `.mcp.json` / wrapper）有自己的 minor，反映文件 / skill 變動；Binary（GitHub release 端）有自己的 minor，反映 MCP server 內部新增 tool 或修 bug。Wrapper auto-download 從 release fetch binary 到 `~/bin/CheWordMCP`。

### 重要 milestones

- **v3.13.2** — bump ooxml-swift v0.19.1→v0.19.2，修正 v3.13.1 的 6-AI verification 找到的 4 個 blocking findings（無 source 變更）：F1 `Hyperlink.toXML()` 真正 emit Reader 解出的 runs/rawAttributes/rawChildren（pre-fix 把所有 inner runs 攤平成單一 hardcoded 藍底線 styled run）、F2 `addBookmark`/`deleteBookmark` 同步 `bookmarkMarkers`（pre-fix source-loaded paragraph 的新 bookmark 在 save 時被靜默丟掉、刪除留下 zombie `name=""` markers）、F3 `<w:ins>`/`<w:del>`/`<w:moveFrom>`/`<w:moveTo>` Reader 為 inner runs 設 `position`+`revisionId` + Writer sort path 重新 group runs by revisionId 包回 wrapper（pre-fix wrapper 在 source-load round-trip 後完全消失）、F4 namespace 保留從 `document.xml` 擴展到 header/footer/footnote/endnote 各自的 root（pre-fix NTPU thesis VML watermark headers declaring mc/wp/w14/w15 silently 退化到 hardcoded 5-namespace template）
- **v3.13.1** — `pPr` double-emission silent regression hot-fix（bump ooxml-swift v0.19.0→v0.19.1，無 source 變更）。NTPU thesis 驗證時抓到：v3.13.0 round-trip 後 `<w:pPr>` 被雙重 emit，unrecognized children 從 799→1333（+67%）。1-line `case "pPr": break` 修正
- **v3.13.0** — `document.xml` lossless round-trip + tool-mediated wrapper edits（closes [#56](https://github.com/PsychQuant/che-word-mcp/issues/56) P0）— 完整保留 `<w:document>` root 34 個 `xmlns:*` declarations、`<w:bookmarkStart>` / `<w:hyperlink>` / `<w:fldSimple>` / `<mc:AlternateContent>` 全程 round-trip（pre-v3.13.0 silently 丟掉 32 namespaces / 100% bookmarks / 354 個 `<w:t>` text nodes 在 wrapper 內），`replace_text` 走 wrapper-internal runs（無 silent failure）。Built on ooxml-swift v0.19.x
- **v3.12.0** — Programmatic Track Changes 生成 — 3 新 MCP 工具（insert_text_as_revision / delete_text_as_revision / move_text_as_revision）+ 2 擴充 args（format_text / set_paragraph_format 加 `as_revision: bool`）— closes [#45](https://github.com/PsychQuant/che-word-mcp/issues/45)，**Office.js OOXML Roadmap P0 100% 完成**
- **v3.11.0** — Tables / Hyperlinks / Headers extensions（16 新工具：5 table conditional/nested/layout + 3 typed hyperlinks + 4 header even/odd/link/section-map）— closes [#49](https://github.com/PsychQuant/che-word-mcp/issues/49) [#50](https://github.com/PsychQuant/che-word-mcp/issues/50) [#51](https://github.com/PsychQuant/che-word-mcp/issues/51)
- **v3.10.0** — Styles + Numbering + Sections foundation（19 新工具 + 6 擴充 args：4 style inheritance/link/latent/alias + 8 numbering definition lifecycle + 7 section vertical/break/title-page）— closes [#46](https://github.com/PsychQuant/che-word-mcp/issues/46) [#47](https://github.com/PsychQuant/che-word-mcp/issues/47) [#48](https://github.com/PsychQuant/che-word-mcp/issues/48)
- **v3.9.0** — Content Controls (SDT) 完整 read/write（7 新工具 + 12-type discrimination + nested SDT tree）— closes [#44](https://github.com/PsychQuant/che-word-mcp/issues/44)
- **v3.8.0** — Header/footer raw-element preservation + counter-isolation flag — closes [#52](https://github.com/PsychQuant/che-word-mcp/issues/52)
- **v3.7.0–v3.7.2** — Save durability cycle: path-traversal 修正 / hdr-ftr auto-suffix / `updateAllFields`（#53–#55, #54）
- **v3.6.0** — Save durability + autosave Design B + serial-only OOXML IO — closes #40 #41
- **v3.5.0** — true byte-preservation via dirty tracking — closes #23 round-2 + #32 #33 #34
- **v3.4.0** — Phase 2B+2C: 13 個 comment-thread/people/notes-update/web-settings 工具 — closes #24 #25 #29 #30 #31
- **v3.3.0** — Phase 2A: 12 個 theme/header/footer/watermark 工具 — closes #26 #27 #28
- **v3.2.0** — `insert_equation` LaTeX parser delegated to `latex-math-swift` — closes #22
- **v3.1.0** — 9 個 readback tools（Caption CRUD, update_all_fields, Equation CRUD）— closes #17 #19 #21
- **v3.0.0** — Session state API（dirty tracking, autosave, finalize_document, disk drift detection）— closes #12 #13 #15

### 底層架構里程碑

- **`ooxml-swift v0.19.0–0.19.2`** — `document.xml` lossless round-trip：root namespace preservation（34 `xmlns:*` + `mc:Ignorable`）+ Bookmark Reader parsing + Wrapper hybrid model（`Hyperlink` / `FieldSimple` / `AlternateContent` typed editable surface + raw passthrough）+ sort-by-position Writer emit + 6 raw-carrier types for `<w:p>` schema completeness。v0.19.1 修正 v0.19.0 的 pPr double-emission silent regression。v0.19.2 修正 6-AI verification 找到的 4 個 blocking findings：Hyperlink writer 真正 iterate runs+rawAttributes+rawChildren、bookmark mutation API 同步 markers、ins/del/moveFrom/moveTo wrapper round-trip（Reader 設 position+revisionId、Writer sort path 重新 group by revisionId）、namespace 保留擴展到 header/footer/footnote/endnote（新 `ContainerRootTag` helper）
- **`ooxml-swift v0.18.0`** — Revision generation primitives（6 new WordDocument methods + writer-side `Paragraph.toXML()` revision wrapping + `<w:t>` → `<w:delText>` substitution）
- **`ooxml-swift v0.16.0–0.17.0`** — Styles inheritance / Numbering lifecycle / Section vertical alignment / Table conditional+nested+indent / Typed hyperlinks / Even-odd headers
- **`ooxml-swift v0.15.0–0.15.1`** — `SDTParser` first-class `<w:sdt>` model + `BodyChild.contentControl` + max+1 SDT id allocator
- **`ooxml-swift v0.13.0–0.14.0`** — true byte-preservation via dirty tracking + raw-element preservation
- **`ooxml-swift v0.12.0`** — preserve-by-default 架構（PreservedArchive + RelationshipIdAllocator + ContentTypesOverlay）
- **`ooxml-swift v0.10.0–0.11.0`** — `FieldParser` + `OMMLParser` readback primitives + `MathAccent`

## Office.js OOXML Roadmap P0 Closure Map

| § | Sub-issue | che-word-mcp 版本 |
|---|-----------|-------------------|
| §1 Content Controls (SDT) | [#44](https://github.com/PsychQuant/che-word-mcp/issues/44) | v3.9.0 |
| §2 Track Changes 寫側 | [#45](https://github.com/PsychQuant/che-word-mcp/issues/45) | v3.12.0 |
| §3 Numbering | [#46](https://github.com/PsychQuant/che-word-mcp/issues/46) | v3.10.0 |
| §4 Sections | [#47](https://github.com/PsychQuant/che-word-mcp/issues/47) | v3.10.0 |
| §8 Styles | [#48](https://github.com/PsychQuant/che-word-mcp/issues/48) | v3.10.0 |
| §9 Tables | [#49](https://github.com/PsychQuant/che-word-mcp/issues/49) | v3.11.0 |
| §14 Hyperlinks | [#50](https://github.com/PsychQuant/che-word-mcp/issues/50) | v3.11.0 |
| §16 Headers / Footers | [#51](https://github.com/PsychQuant/che-word-mcp/issues/51) | v3.11.0 |

Umbrella [#43](https://github.com/PsychQuant/che-word-mcp/issues/43) — closed 2026-04-25。
