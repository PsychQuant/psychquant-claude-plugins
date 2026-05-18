---
name: latex-validate
description: 編譯 LaTeX 專案後跑完整 layout 驗證流程 — detect_layout_issues + find_overlaps + fonts_check + box_warnings。當用戶說「驗證 LaTeX」「檢查排版」「掃 layout 問題」「LaTeX 編完看看有沒有 bug」「latex audit」或在 LaTeX 專案目錄編譯後想自動 audit 時使用。也適用於 commit 前驗證、release 前 audit、暑校稿 batch 修完想知道剩餘 issue。
---

# LaTeX Validate

編譯後完整 layout 驗證流程：把 6 個 detector tool 串成一條 audit pipeline，產生整理過的 issue 報告。

## Trigger

用戶說：
- 「驗證 LaTeX」「LaTeX audit」「掃排版問題」
- 「編完看看有沒有 bug」「commit 前檢查」
- 「跑完整檢查」
- 直接 `/latex-validate`

或 implicit 場景：
- 剛跑完 compile_latex / latexmk make
- batch 修了多處 .tex 後（多輪 Edit）
- release / publish 前

## Workflow

依序執行（用 `mcp__plugin_che-latex-mcp_che-latex-mcp__<tool>` 命名空間）：

### Step 1: 確認 PDF 存在

如果用戶沒指定 `project_path` + `main_file`，問清楚或從 cwd 推斷。確認 PDF 已編譯出來，沒有的話先 `compile_latex` 一次。

### Step 2: source-level 預檢查

```
fonts_check(project_path, main_file)     # .log 字型缺字
box_warnings(project_path, main_file)    # overfull/underfull box
```

這兩個從 `.log` 抓，速度極快（< 100ms），先跑。

### Step 3: PDF-level 視覺檢查

```
detect_layout_issues(pdf_path, page_range?)
# → widow heading / empty page / bottom gap / overlap 一次抓完
```

這是主力 detector。報告會分四類列出問題 page 跟原因。

### Step 4: 重疊細查（如果 detect 報告 overlap）

```
find_overlaps(pdf_path, problematic_pages, threshold=4.0)
# → 對問題頁面逐 block 列出重疊位置 + 文字 excerpt
```

只對 Step 3 報的 overlap pages 跑，不必整本。

### Step 5: 整理 + 提出修法建議

收到 4 個 tool report 後，**不要直接 dump 給用戶**。整理成：

```
## LaTeX 排版 audit 報告（main.pdf，N 頁）

### ⚠️ Critical（必須修）
- p.X: widow heading「⋯⋯」← 加 \needspace 或 \clearpage
- p.Y: block overlap 12.4 pt² ← tikz layout 衝突或字型 ghost

### ⚠️ Warning（建議修）
- p.Z: 留白 65% ← 可能過度 \clearpage，檢查 line N
- 字型缺字 ⋯ 3 個（U+22EF / Times New Roman）← 改 \dots

### ✅ Pass
- 標點符號（如果跑了 punct_check）
- overfull box（如果 box_warnings 通過）
```

對每個 issue 給 **具體** 修法建議（哪個 LaTeX 指令 / 哪行加 needspace），不要泛泛說「請調整」。

## 注意事項

- **不要對 reading section / appendix 過度報警**：那些 section 通常排版較鬆，留白比例高是正常。可以在報告中標明「（reading section）」加註。
- **widow heading 誤報**：tikz 流程圖、章標題前後常有短 block 但不是真的 widow heading。看 Step 4 找 block 文字確認。
- **threshold 調整**：`find_overlaps` 預設 threshold=4 pt²，數學環境會有偽陽性。如果偽陽性多，調 threshold=50 只看明顯重疊。
