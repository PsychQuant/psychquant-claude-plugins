---
name: latex-precompile
description: LaTeX source 編譯前的 static check — punct_check（半形/全形標點）+ fonts_check（字型缺字，需既有 .log）+ source-level pattern audit。當用戶說「precompile check」「編譯前檢查」「跑 make check」「source audit」「掃半形標點」「掃缺字」時使用。對應暑期班 typesetting-checklist 的 #A1 字型缺字 + #A5 標點規則。
---

# LaTeX Precompile Check

編譯之前先跑 source-level static check，把「編譯出來才會發現」的 bug 提前抓出來。比 `make check` 工作流更省事的單一 skill。

## Trigger

用戶說：
- 「precompile check」「編譯前檢查」「source audit」
- 「跑 make check」「掃 LaTeX source」
- 「掃半形標點」「掃缺字」「punct check」「fonts check」
- 直接 `/latex-precompile`

或 implicit：
- 用戶 batch Edit 多處 .tex 後（commit 前）
- 用戶 import 外部 source（如從 Word 轉的 .tex）

## Workflow

### Step 1: punct_check — 半形標點偵測

```
punct_check(source_path)
```

- `source_path` 可以是單一 .tex 或目錄（會遞迴掃所有 .tex，自動跳 `_archive`）
- 偵測 CJK 中間夾雜的半形 `,;:?!()`
- 智能判斷：括號只在「前後都是 CJK」時才報警，避免誤報 `\foo(x)` 這類 LaTeX 語法
- 跳過 `$...$` math mode
- 跳過 `%` 開頭整行 comment

### Step 2: fonts_check — 字型缺字（需要 .log）

```
fonts_check(project_path, main_file?)
```

- 從 `.log` 抽 `Missing character: There is no X in font Y!` warnings
- 自動 dedup（同一字元 + 同一字型只報一次）
- 回傳 unicode 表 + 字型對照

**前置條件**：必須已編譯過一次（`.log` 存在）。如果沒，先 call `compile_latex` 跑一次（缺字字型 fallback 不會 abort 編譯）。

### Step 3: box_warnings — overfull/underfull box

```
box_warnings(project_path, main_file?, severity_min?)
```

- 從 `.log` 抽 box warnings
- `severity_min` 過濾低分（如「10000」只看 badness ≥ 10000）

### Step 4: 整理回報

整理三個 check 結果成 audit 報告：

```
## LaTeX precompile check 報告

### ⚠️ 標點符號（punct_check）
共 N 處：
- 02_暑期班/.../ch04.tex:L432:C18  ',' → '，'  「⋯⋯」
- ...
建議：batch 修這 N 處或跑 autofix_punct.py

### ⚠️ 字型缺字（fonts_check）
共 M 個 unique：
| 字元 | Unicode | 字型 |
|------|---------|------|
| ⋯   | U+22EF  | Times New Roman |
建議：⋯ → \dots / \cdots，→ → $\to$

### ⚠️ box 警告（box_warnings, badness ≥ 10000）
共 K 個：
- Overfull \hbox (15.23pt too wide) at line N
- ⋯
建議：手動檢查指定行，調整 \hyphenpenalty 或加 \\\\ break
```

## 跟既有 make check 的關係

如果 project 已有 `Makefile` 含 `check`/`check-punct`/`check-fonts` target（如 educator 暑期班的 setup），這 skill 提供更 unified 的 audit — 結果可以 cross-reference 既有 script，但不取代它們（script 跑得快，CI 用 script；互動 audit 用 skill）。

## 注意事項

- **fonts_check 需要 `.log`**：如果 `.log` 不存在會 error。提示用戶先 compile_latex 一次
- **punct_check 對 _archive 目錄會自動跳過**：但 `99_archive` 之類不會。如果 user 專案用不同 archive 命名，要明說
- **不要對 ground truth 章節改 source**：如 educator 春季班 ch01-03 是 baseline，即使 punct_check 報半形也不該動（typesetting-checklist 規則：春季班源檔不改）
