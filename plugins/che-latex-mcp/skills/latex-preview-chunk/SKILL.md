---
name: latex-preview-chunk
description: 預覽單一 LaTeX 片段（vocabbox / tikz 圖 / 數學公式）不必編整本 PDF — 用 compile_chunk 把片段包進 standalone class 編譯 → 單頁 PNG。當用戶說「預覽這個 vocabbox」「看一下這個 tikz 長怎樣」「試試這個公式」「快速看片段」「不要編整本」時使用。
---

# LaTeX Preview Chunk

「我改了一個 vocabbox 但不想等 30 秒編整本」這種場景的快速預覽工具。把片段 wrap 進 `standalone` document class 編出單頁 PDF + PNG。

## Trigger

用戶說：
- 「預覽這個 vocabbox」「看 tikz 圖長怎樣」「試試這個公式」
- 「不要編整本」「快速看一下」「render 這段」
- 直接 `/latex-preview-chunk`

或 implicit：
- 用戶 draft 一段新 vocabbox / tikz / 公式還沒 insert 到主文件
- 用戶想 iterate tikz layout，每次改完都要立即看結果
- 用戶問「這個 LaTeX 寫對了嗎」搭配 source 片段

## Workflow

### Step 1: 確認片段內容

如果用戶貼了 LaTeX 片段 → 直接拿來用。
如果用戶指向 file:line range（如「ch04.tex line 100-120 的 vocabbox」）→ Read 該段 source。

### Step 2: 找對應 preamble

關鍵問題：**這個 chunk 用了哪些 custom command / environment**？

- vocabbox / examitem / tipbox 等 → 需要 commands.tex preamble
- tikz 用了 custom style → 需要 preamble.tex 或對應設定
- 純數學 / 純文字 → 不需要 preamble（內建 amsmath 即可）

如果片段引用 custom env，必須給 `preamble_path` 指向 project 的 `commands.tex` 或 `preamble.tex`。沒給 preamble 編 vocabbox 會炸（環境未定義）。

### Step 3: call compile_chunk

```
compile_chunk(
  tex_fragment,         # 不含 \documentclass、\begin{document}
  preamble_path?,       # commands.tex / preamble.tex 路徑（含 custom env 時必填）
  output_dir?,          # 預設 /tmp/latex_chunk
  engine?               # 預設 xelatex
)
```

工具會：
1. 把片段 wrap 進 `\documentclass[border=10pt]{standalone}` + `\input{preamble}` + `\begin{document}`
2. 跑 xelatex 編一次
3. 產出 PDF + 3x 高解析 PNG

### Step 4: Read 結果 PNG 給用戶看

工具回傳 path，主動 Read PNG 載入視覺結果，給用戶評估。如果 user 看了不滿意要 iterate，回 Step 1。

## 用法範例

### 預覽 vocabbox（最常見）

```
compile_chunk(
  tex_fragment: """
    \\begin{vocabbox}{Cohen's $\\kappa$ 係數}
    \\begin{vocabdesc}
      \\item[\\uline{公式}] 校正純機率後的吻合率:
      $$\\kappa = \\frac{p_o - p_e}{1 - p_e}$$
    \\end{vocabdesc}
    \\end{vocabbox}
  """,
  preamble_path: "/path/to/project/00_common/commands.tex"
)
```

### 預覽 tikz

```
compile_chunk(
  tex_fragment: """
    \\begin{tikzpicture}
      \\node[draw, rounded corners=8pt] (a) at (0,0) {根節點};
      ...
    \\end{tikzpicture}
  """,
  preamble_path: "/path/to/project/00_common/preamble.tex"
)
```

### 純公式（不需 preamble）

```
compile_chunk(
  tex_fragment: """
    $$\\text{AVE} = \\frac{\\sum_{i=1}^{k} \\lambda_i^2}{k}$$
  """
)
```

## 注意事項

- **standalone class 會把 page 裁切到內容大小**：所以「跨頁切斷」「page break」這類 issue 在 chunk preview 看不出來。要看那種 issue 必須編整本 PDF
- **preamble.tex 內如果有 `\input{commands}` 之類**：直接 pass preamble.tex 即可，會 cascade load 進來
- **commands.tex 內含 `\input` 相對路徑** → 可能 work dir 不同會找不到。改 pass 絕對路徑或先 wrap 進臨時 preamble
- **產出的 PNG 解析度 3x**：適合載入 Read tool 看細節（vocabbox label 跟內容是否對齊、tikz box 是否重疊）
- **編完不自動刪檔**：output_dir 內留 PDF + PNG + .aux/.log/.tex，下次 call 會覆蓋（同 output_dir）
