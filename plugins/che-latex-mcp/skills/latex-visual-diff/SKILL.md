---
name: latex-visual-diff
description: 改動 LaTeX source 後做視覺 diff，知道改動影響哪幾頁 — 用 compile_diff(git_ref) 自動 checkout + compile + compare，或用 compare_pdfs 比兩個既存 PDF。當用戶說「視覺 diff」「比較改動前後」「我改了 X 影響哪幾頁」「跟上一版比」「visual regression」時使用。也適用於 batch 修完想驗證、release 前 ripple 檢查。
---

# LaTeX Visual Diff

「改完不知道影響哪幾頁」是 LaTeX batch 修最大的 friction。這個 skill 把「改動 → 視覺 attribution」壓縮成單一 tool call。

## Trigger

用戶說：
- 「視覺 diff」「visual diff」「跟上版比」
- 「我改了 X 影響哪幾頁」「ripple 檢查」
- 「比較 PDF」「compare pdfs」
- 直接 `/latex-visual-diff`

或 implicit 場景：
- 用戶剛 batch Edit 多處 .tex
- 用戶說「不確定改動範圍」
- commit / push 前驗證沒 collateral damage

## 兩種模式

### 模式 A：git ref 對照（最常用）

用戶想看「跟某個 commit 比改了什麼」。

```
compile_diff(
  project_path,
  main_file?,    # 預設 main
  engine?,       # 預設 xelatex
  git_ref,       # HEAD~1（預設）/ HEAD~3 / branch-name / commit-sha
  page_range?,
  output_dir?    # 預設 /tmp/latex_diff
)
```

工具會：
1. `git worktree add` 把 ref checkout 到暫存目錄
2. 在那邊跑 latexmk 編出 baseline PDF
3. 跟當前 PDF 做 pixel-level diff（紅色高亮變動區）
4. 回傳影響 page list + 每頁 diff PNG path
5. 自動清掉 worktree

**前置條件**：當前 PDF 必須已編譯（current branch 的 main.pdf 存在）。如果還沒，先跑 `compile_latex` 再 call 這個。

### 模式 B：兩個既存 PDF 直接比（手動 baseline）

用戶手動保存 baseline PDF，或要比兩個 release 版本。

```
compare_pdfs(
  before_pdf,      # baseline PDF path
  after_pdf,       # current PDF path
  page_range?,
  output_dir?,
  save_diff_images?  # 預設 true
)
```

## Workflow

### Step 1: 判斷模式

問用戶或從 context 推斷：
- 有 git ref → 模式 A
- 有兩個 PDF path → 模式 B
- 都沒有 → 預設模式 A，git_ref = HEAD~1

### Step 2: 跑 diff

call 對應的 tool。等 30 秒 - 2 分鐘（baseline 編譯需要時間）。

### Step 3: 結果整理

工具回傳的是「哪幾頁變了 + diff PNG path」。**不要直接 dump 整 list 給用戶**，而是：

1. **分群**：把連續頁面 group（p.78-82 是同一段改動的 ripple；p.187 是另一處）
2. **attribute**：根據改動的 .tex source（從 git diff 推），猜每群對應哪個改動
3. **flag 意外**：如果 user 只改了 ch04 但 ch07 也有頁面變了，highlight 為「意外 ripple」要 user 注意

範例輸出：

```
## 視覺 diff: HEAD~1 → 當前

改動的 .tex 檔案（從 git diff）：
- 02_暑期班/part1_心理測驗/ch04_信度/ch04.tex
- 02_暑期班/00_common/commands.tex

### 影響頁面（共 6 頁）

**Group 1 — ch04 信度（4 頁，預期內）**
- p.66, 67, 69, 71: 2-15% 像素改變
- 對應改動：ch04 Cohen κ vocabbox + ICC vocabbox
- diff PNG: /tmp/latex_diff/diff_p66.png ⋯⋯

**Group 2 — ch10（2 頁，⚠️ 意外 ripple）**
- p.185, 186: 0.5% 像素改變
- 對應改動：commands.tex examitem env 改了 → 影響所有 examitem 渲染
- diff PNG: /tmp/latex_diff/diff_p185.png
- 建議：抽一頁 visual check 確認 examitem 改動 OK
```

## 注意事項

- **`compile_diff` 需要 git repo**：如果 project 不在 git 內，會 error，改用 `compare_pdfs` + 手動 baseline
- **git_ref 必須能編譯**：如果該 ref 的 source 本身有編譯錯誤，baseline 跑不出來。換 ref 或先修 source
- **巨大 ripple 警訊**：如果 100+ 頁都改了，通常是改了 commands.tex / preamble.tex 這類底層檔案，視覺改變是 expected 但量大要花時間 review
- **diff PNG 不要全載入 context**：選 2-3 個代表性頁面 Read PNG，其他列 path 不載入
