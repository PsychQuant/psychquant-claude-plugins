---
name: status
description: |
  顯示 Lean 4 專案的證明進度：sorry/axiom 數量、已證明定理、lake build 狀態。
  當用戶說「proof status」、「進度」、「還剩多少 sorry」時觸發。
argument-hint: "[lean_project_path]"
---

# Lean 4 Proof Status

快速掃描 Lean 4 專案，回報證明完成度。

## Execution Steps

### Step 1: Locate Project

找到 `lakefile.toml` 所在的目錄。如果引數為空，從當前目錄向上搜尋。

### Step 2: Scan

用 Grep 掃描所有 `.lean` 檔案（排除 `.lake/` 目錄）：

```bash
# sorry 數量（排除註解中的）
grep -rn "sorry" --include="*.lean" . | grep -v "\.lake/" | grep -v "^.*:.*--.*sorry"

# axiom 數量（自定義的，非 Mathlib）
grep -rn "^axiom " --include="*.lean" . | grep -v "\.lake/"

# placeholder（結論是 True）
grep -rn ": True :=" --include="*.lean" . | grep -v "\.lake/"

# 已完成的 theorem（有 := by ... 且沒有 sorry）
# 這個比較複雜，用多行 grep 或讀取每個檔案分析
```

### Step 3: Build Check

```bash
lake build 2>&1 | tail -20
```

回報：
- 是否有非 sorry 的錯誤
- warning 數量（sorry 會產生 warning）

### Step 4: Report

```markdown
## Proof Status — {project_name}

| 指標 | 數量 |
|------|------|
| sorry | N |
| axiom（預期保留） | A |
| placeholder（`: True`） | P |
| 已證明定理 | T |
| lake build | ✓ / ✗ |

### sorry 位置

| 檔案 | 行 | 定理 | 類型 |
|------|-----|------|------|
| Article.lean | 112 | thm1_second_order_separation | deep |
| ... | ... | ... | ... |

### axiom 位置（預期保留）

| 檔案 | 行 | 名稱 | 來源 |
|------|-----|------|------|
| Hoadley1971.lean | 236 | thmA1_sufficient_ui | Neveu (1965) |
| ... | ... | ... | ... |
```

### Step 5: PROGRESS.md

如果專案根目錄有 `PROGRESS.md`，讀取並顯示最近的 grind 記錄。
