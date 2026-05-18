# che-latex-mcp

> **Mission：讓 AI 完全清楚 LaTeX 修正的結果。**
>
> 改了一行 source，AI 必須知道：PDF 第幾頁變了、變成什麼樣、有沒有副作用、有沒有新 bug。不是「我改完了你自己編譯看看」，是 AI 自己看到結果、自己 attribute 影響、自己抓 bug。
>
> 通用 LaTeX 工具 — 任何 LaTeX 專案（論文、CV、書、講義、簡報）都可以用，**不綁定特定領域**。

## 為什麼這個 mission 重要

AI 改 LaTeX 一直有個 fundamental 問題：**source 跟 output 中間隔著 xelatex 這個黑盒**。

傳統 loop：

```
AI 改 source → 跟人說「請編譯看看」→ 人編譯 → 截圖貼回來 → AI 看圖
                                  ↑ 人卡在這裡，每次 ~30 秒
```

或自動化但很重的 loop：

```
AI 改 source → bash xelatex → python render PNG → Read PNG → 視覺判斷
              ~4 個 tool call、~15 秒、且無 attribution（改了 X 影響到哪幾頁？不知道）
```

這兩條 loop 的後果：

- **不敢小步改**：每次改都要 ~15 秒驗證，AI 偏向「一次改一大段然後祈禱」，喪失 TDD 紀律
- **不知道副作用**：改 ch01 line 100，page 187 變空城了 — AI 不會知道，要等人翻 PDF 才發現
- **看不到細節 bug**：字疊到 box、tikz 跑到頁外、字型缺字成 □ — 這些 PDF 上一眼可見的問題，AI 從 source 完全推不出來
- **chunk preview 沒人做**：想預覽單一片段，得編整本 PDF，30 秒起跳
- **PDF review/校稿 對不上 source**：reviewer 在 PDF 畫紅圈寫 comment，AI 不知道怎麼把那些 comment 對到 source code

## 這個 plugin 如何達成 mission

把「看到結果 + attribute 變化 + 抓 bug + 預覽片段 + 對應 review」五件事壓進 single tool call，讓 AI 在改 source 的同時就完全掌握結果。

### 五個 mission pillar

| Pillar | 對應問題 | 解法 | 工具 |
|---|---|---|---|
| **1. 看到結果** | 改完不知道長怎樣 | source → PDF → PNG → AI 直接 Read，一個 call 完成 | `compile_latex` + `preview_page` / `preview_range` |
| **2. Attribute 變化** | 改 X 影響到哪幾頁？不知道 | git ref 對照視覺 diff，紅色高亮所有變動 region | `compile_diff(git_ref)` + `compare_pdfs` |
| **3. 抓 bug** | 字疊、缺字、跑頁外 — source 看不出 | explicit detector：bbox 重疊、log 缺字、box 警告、CJK 半形標點 | `detect_layout_issues` + `find_overlaps` + `fonts_check` + `box_warnings` + `punct_check` |
| **4. 預覽片段** | 編整本 30 秒太重 | standalone class wrap → 單頁 PDF → 3x PNG，~3 秒 | `compile_chunk` |
| **5. 對應 review** | PDF 紅圈 → source 位置斷層 | PDF annotation 抽出 + grep source 反查 | `extract_annotations` + `annotation_to_source` |

### 結果：AI 改 LaTeX 的新 loop

```
AI 改 source → call compile_diff(HEAD~1) → 拿到 ripple page list + 視覺 diff PNG
            → call detect_layout_issues  → 拿到所有 overlap / widow / 缺字 warning
            → AI 直接 Read PNG，知道現在長怎樣、影響到誰、有沒有新 bug
            → 全 in single AI turn，~5 秒
```

不必跟人說「請編譯看看」，不必猜「我改的東西會不會影響別處」，不必擔心字型缺字編出來才發現。

收到 PDF review/校稿時：

```
AI call extract_annotations(pdf) → 拿到所有 reviewer comment + 位置 + surrounding text
   → 對每條 annotation call annotation_to_source(text, src_dir) → 拿到 file:line 候選
   → AI 直接編輯對應 source，不必人手動標 location
```

## 結構

- **MCP server**（20 tools）：編譯、視覺驗證、layout 偵測、字型/標點/box overflow 檢查、PDF annotation 抽取
- **4 個 skills**：把 tools 串成完整工作流，trigger keywords 自動 invoke

## Tools 一覽（20 個）

### Pillar 1：看到結果（編譯與單頁／批次預覽）
- `compile_latex` — 編譯（xelatex / pdflatex / lualatex）
- `preview_page` — 單頁 PDF → PNG（3x 高解析）
- `preview_range` — 批次截多頁
- `get_page_content` — 抽頁面文字
- `find_pagebreaks` / `analyze_pages` — 章節對應頁碼
- `get_document_info` — 文件 metadata
- `check_errors` — `.log` 錯誤警告

### Pillar 2：Attribute 變化（git ref 對照）
- `compile_diff(git_ref)` — git worktree checkout → compile → 跟當前 PDF 視覺 diff，**一次 call 完成 baseline + compare**
- `compare_pdfs` — 兩 PDF 像素級 diff，紅色高亮變動 region

### Pillar 3：抓 bug（explicit detector）
- `detect_layout_issues` — 綜合 audit：widow / empty page / overlap
- `find_overlaps` — block 重疊（字疊／box 重疊 bug）
- `get_page_metrics` — 單頁 layout 數據（留白比例、block 數、widow 風險）
- `extract_blocks` — 抽頁面所有 text block（bbox + text + 字數）
- `fonts_check` — `.log` 字型缺字（U+22EF ⋯ / U+2192 → 等 fallback 成 □）
- `box_warnings` — `.log` overfull / underfull box
- `punct_check` — 半形標點夾在 CJK 中間（CJK 上下文偵測）

### Pillar 4：預覽片段（不必編整本）
- `compile_chunk` — standalone class 編譯片段 → 單頁預覽

### Pillar 5：對應 review（PDF annotation → source）
- `extract_annotations` — PDF annotation 全抽出（page + bbox + type + comment + surrounding text），JSON 結構化
- `annotation_to_source` — surrounding text → grep source 找 file:line 候選

Pillar 5 是 **generic primitive**：MCP 只負責「抽出 raw annotation」+「反查 source 位置」，**不做分類 / 驗證**。專案特有的分類規則（哪些 comment 是「字型缺字」、哪些是「跨頁」）由 caller 自己處理（skill / script layer）。

## Skills 一覽（4 個）

| Skill | Trigger | 對應 Pillar | 串接 tools |
|-------|---------|----------|-----------|
| `latex-validate` | 「驗證 LaTeX」「audit」「commit 前檢查」 | Pillar 3 | fonts_check → box_warnings → detect_layout_issues → find_overlaps |
| `latex-visual-diff` | 「視覺 diff」「跟上版比」「我改了 X 影響哪幾頁」 | Pillar 2 | compile_diff(git_ref) 或 compare_pdfs |
| `latex-precompile` | 「precompile check」「source audit」「掃半形/缺字」 | Pillar 3（source-level） | punct_check + fonts_check + box_warnings |
| `latex-preview-chunk` | 「預覽這個片段」「不要編整本」 | Pillar 4 | compile_chunk + Read PNG |

## 安裝

```bash
claude plugin marketplace add PsychQuant/psychquant-claude-plugins
claude plugin install che-latex-mcp@psychquant-claude-plugins
```

首次使用會自動從 GitHub Release 下載 binary 到 `~/bin/che-latex-mcp`。

## 系統需求

- macOS 14+
- TeX Live 或 MacTeX（編譯功能需要）
- git（`compile_diff(git_ref)` 需要）

## 從 source build

```bash
git clone https://github.com/kiki830621/che-latex-mcp.git ~/Developer/che-mcps/che-latex-mcp
cd ~/Developer/che-mcps/che-latex-mcp
swift build -c release
```

Wrapper script 會優先用 `~/Developer/che-mcps/che-latex-mcp/.build/release/che-latex-mcp`（從 source build 永遠不會被 auto-replace）。

## License

MIT
