# Markdown 筆記撰寫的公理化系統

## 📚 概述

本目錄收錄 Markdown 格式規範的權威來源，用於建立筆記撰寫的標準化系統。

---

## 🎯 Markdown 規範來源

### 1. CommonMark 規範

**CommonMark** 是 Markdown 的正式規格說明，定義了標準的 Markdown 語法。

- 官方網站：https://spec.commonmark.org/
- 當前版本：0.31.2
- 這是所有 Markdown 實作的基礎規範

### 2. Markdownlint 規則

所有 **Markdown 格式規則** 都在 [markdownlint](git/markdownlint/) 專案中定義。

#### 📁 重要檔案位置

- **完整規則列表**：[git/markdownlint/doc/Rules.md](git/markdownlint/doc/Rules.md)
  - 包含所有規則的總覽和說明

- **個別規則詳細說明**：[git/markdownlint/doc/](git/markdownlint/doc/)
  - md001.md - md059.md
  - 每個規則都有獨立的說明文件

#### 🔑 關鍵規則（與筆記格式最相關）

| 規則編號 | 規則名稱 | 說明 | 檔案連結 |
|---------|---------|------|---------|
| **MD001** | Heading levels should only increment by one level at a time | 標題層級應該逐級遞增 | [md001.md](git/markdownlint/doc/md001.md) |
| **MD003** | Heading style | 標題樣式一致性 | [md003.md](git/markdownlint/doc/md003.md) |
| **MD004** | Unordered list style | 無序列表樣式一致性 | [md004.md](git/markdownlint/doc/md004.md) |
| **MD005** | Inconsistent indentation for list items | 列表項目縮排一致性 | [md005.md](git/markdownlint/doc/md005.md) |
| **MD007** | Unordered list indentation | 無序列表縮排 | [md007.md](git/markdownlint/doc/md007.md) |
| **MD009** | Trailing spaces | 行尾空格 | [md009.md](git/markdownlint/doc/md009.md) |
| **MD010** | Hard tabs | 禁用 Tab 字元 | [md010.md](git/markdownlint/doc/md010.md) |
| **MD012** | Multiple consecutive blank lines | 多個連續空行 | [md012.md](git/markdownlint/doc/md012.md) |
| **MD022** | Headings should be surrounded by blank lines | 標題周圍要有空行 ⭐ | [md022.md](git/markdownlint/doc/md022.md) |
| **MD025** | Multiple top-level headings | 單一頂級標題 | [md025.md](git/markdownlint/doc/md025.md) |
| **MD030** | Spaces after list markers | 列表標記後的空格 | [md030.md](git/markdownlint/doc/md030.md) |
| **MD031** | Fenced code blocks should be surrounded by blank lines | 程式碼區塊周圍要有空行 | [md031.md](git/markdownlint/doc/md031.md) |
| **MD032** | Lists should be surrounded by blank lines | 列表周圍要有空行 ⭐ | [md032.md](git/markdownlint/doc/md032.md) |
| **MD033** | Inline HTML | 內嵌 HTML 使用 | [md033.md](git/markdownlint/doc/md033.md) |

⭐ 標記的是對筆記格式最重要的規則

### 3. VSCode Markdown 擴充套件

**vscode-markdown** 提供了 Markdown 語法的實作參考。

- 位置：[git/vscode-markdown/](git/vscode-markdown/)
- 核心規範定義：[git/vscode-markdown/src/contract/MarkdownSpec.ts](git/vscode-markdown/src/contract/MarkdownSpec.ts)

---

## 📋 筆記格式檢查清單

基於 markdownlint 規則，撰寫筆記時應遵循：

### 標題格式
- [ ] 標題層級逐級遞增（不跳級）- MD001
- [ ] 標題前後有空行 - MD022
- [ ] 標題樣式一致（都用 `#` ATX 樣式）- MD003
- [ ] 整個文件只有一個 `#` 頂級標題 - MD025

### 列表格式
- [ ] 列表前後有空行 - MD032
- [ ] 無序列表標記一致（統一用 `-`）- MD004
- [ ] 列表項目縮排一致 - MD005, MD007
- [ ] 列表標記後有一個空格 - MD030

### 空行和空格
- [ ] 沒有行尾空格 - MD009
- [ ] 不使用 Tab 字元（統一用空格）- MD010
- [ ] 不超過一個連續空行 - MD012
- [ ] 程式碼區塊前後有空行 - MD031

### 其他格式
- [ ] 粗體使用 `**文字**` 格式
- [ ] 引用區塊格式正確
- [ ] 數學公式使用 `$...$` 或 `$$...$$`

---

## 🔗 相關資源

### 線上工具
- [CommonMark Spec](https://spec.commonmark.org/) - 官方規範
- [CommonMark Dingus](https://spec.commonmark.org/dingus/) - 線上測試工具
- [Markdownlint GitHub](https://github.com/DavidAnson/markdownlint) - 規則檢查工具

### VSCode 擴充套件
- [Markdown All in One](https://marketplace.visualstudio.com/items?itemName=yzhang.markdown-all-in-one) - Markdown 編輯增強
- [markdownlint](https://marketplace.visualstudio.com/items?itemName=DavidAnson.vscode-markdownlint) - 即時格式檢查

---

## 📝 應用於教學筆記

這些規則已整合到 [筆記格式規範.md](../../筆記格式規範.md) 中，確保所有教學筆記：

1. 符合 CommonMark 標準規範
2. 通過 markdownlint 規則檢查
3. 可正確轉換為 PDF 格式

---

**最後更新：2025-10-08**
