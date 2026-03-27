---
name: axiom-lookup
description: 搜尋公理化系統中的公理、定理和概念。支援跨領域全文搜尋和特定領域查詢。
user_invocable: true
---

# axiom-lookup

在所有公理化領域中搜尋。

## 觸發方式

- `/axiom-lookup [query]` — 搜尋關鍵字
- `/axiom-lookup --domain statistics [query]` — 限定領域搜尋
- `/axiom-lookup --list` — 列出所有領域及其公理數量

## 流程

### Step 1: 解析查詢

從使用者輸入判斷：
- **有指定 domain** → 只搜尋該 domain
- **沒有指定 domain** → 搜尋所有 `domains/` 下的領域
- **`--list`** → 掃描 `domains/` 列出總覽

### Step 2: 搜尋

使用 Grep 在 `domains/` 目錄中搜尋匹配的內容：
- 搜尋 axiom/theorem 的 `id`、`name`、`one_liner`
- 搜尋 `statement_natural` 和 `statement_formal` 的內容
- 搜尋 Markdown 檔案中的標題和內文

### Step 3: 呈現結果

對每個匹配，顯示：
```
📍 Domain: weight-control
   A5_mass_conservation — Mass Conservation Axiom
   "Body mass change equals net mass flux"
   ΔM = Σ(mass_in) - Σ(mass_out)
   File: domains/weight-control/weight_control_axioms.md:42
```

如果結果跨多個領域，按 domain 分組顯示。

### Step 4: 深入查看

問使用者是否要：
- 展開某條公理的完整內容（含 violations/compliant 範例）
- 查看該公理的推導鏈（derives_from 向上追溯）
- 查看相關的跨域公理

## 特殊查詢

### `--list` 模式

掃描所有 `domains/` 子目錄，對每個領域顯示：
```
📚 Axiomatization Systems — 12 domains

   statistics          — 統計與資料科學 (7 files)
   decision-making     — 決策理論 (2 files)
   weight-control      — 體重控制 (18 files)
   japanese-narrative   — 日本文學敘事 (10+ files)
   musical-composition — 音樂作曲理論 (4 files)
   asbe                — 元方法論 (3 files)
   ...
```
