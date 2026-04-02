---
name: grind
description: |
  Lean 4 自動證明磨削。廣度優先掃描所有 sorry，按難度排序，
  逐一嘗試證明，每解一個就 commit。搭配 lean-prover agent 做深度嘗試。
  當用戶說「開始證明」、「grind」、「消除 sorry」、「prove all」時觸發。
argument-hint: "[lean_project_path] [--max-attempts N] [--dry-run]"
---

# Lean 4 Proof Grinder

自動化消除 Lean 4 專案中的 `sorry`，直到 `lake build` 零錯誤或所有可解的 sorry 都已消除。

## Arguments

- `lean_project_path`：Lean 4 專案根目錄（含 `lakefile.toml`），預設為當前目錄
- `--max-attempts N`：每個 sorry 最多嘗試次數（預設 8）
- `--dry-run`：只掃描和分類，不修改檔案

## Execution Steps

### Step 1: Discover Project

```bash
# 找到 lakefile.toml 確認是 Lean 4 專案
# 確認 lake build 可以執行（即使有 sorry，不應有語法錯誤）
cd "$LEAN_PROJECT_PATH"
lake build 2>&1
```

如果有非 sorry 的編譯錯誤，先修那些。sorry 本身不算錯誤（Lean 會 warning）。

### Step 2: Scan All Sorries

掃描所有 `.lean` 檔案，收集每個 sorry 的：

1. **位置**：檔案路徑 + 行號
2. **上下文**：所在的 theorem/lemma 名稱和完整陳述
3. **類型**：
   - `algebraic`：目標是等式/不等式，可能用 `ring`, `field_simp`, `nlinarith`, `linarith`, `norm_num` 解
   - `api-bridge`：需要找到正確的 Mathlib API（如 UI 定義橋接）
   - `structural`：需要構造性證明（歸納、case split）
   - `deep`：需要複雜的數學推理（測度論、拓撲）
   - `placeholder`：結論是 `True` 或 `trivial`，需要重寫定理陳述
4. **依賴**：是否依賴其他 sorry 的結果

```bash
# 掃描 sorry
grep -rn "sorry" --include="*.lean" "$LEAN_PROJECT_PATH" | grep -v "^.*:.*--.*sorry"

# 掃描 axiom（非 Mathlib 的）
grep -rn "^axiom " --include="*.lean" "$LEAN_PROJECT_PATH"

# 掃描 trivial placeholder
grep -rn ": True :=" --include="*.lean" "$LEAN_PROJECT_PATH"
```

### Step 3: Classify and Prioritize

按以下優先級排序（廣度優先）：

| 優先級 | 類型 | 預期策略 |
|--------|------|----------|
| P0 | `placeholder`（`: True`） | 重寫定理陳述為真正的命題 |
| P1 | `algebraic` | `ring`, `field_simp`, `nlinarith`, `norm_num`, `positivity`, `omega` |
| P2 | `structural` | `induction`, `cases`, `simp`, `exact`, `apply` |
| P3 | `api-bridge` | 搜尋 Mathlib，找到對應的 lemma/theorem |
| P4 | `deep` | 需要 lean-prover agent 深度嘗試 |

輸出分類結果到 `PROGRESS.md`。

### Step 4: Grind Loop

對每個 sorry（按優先級順序）：

```
for sorry in sorted_sorries:
    attempt = 0
    while attempt < MAX_ATTEMPTS:
        attempt += 1

        1. 讀取 sorry 所在的完整定理和上下文
        2. 根據類型選擇策略：
           - algebraic → 嘗試 tactic 組合
           - api-bridge → 用 Grep 搜尋 Mathlib 或 `exact?`, `apply?`
           - structural → 分析目標結構，嘗試 induction/cases
           - deep → 啟動 lean-prover agent（subagent）
           - placeholder → 重寫陳述，然後按新類型處理
        3. Edit .lean 檔案，替換 sorry
        4. lake build（hook 會自動觸發，但這裡也要手動確認）
        5. 如果成功：
           - git commit -m "prove: {theorem_name} — eliminate sorry"
           - 更新 PROGRESS.md
           - break
        6. 如果失敗：
           - 讀取 lake build 錯誤訊息
           - 分析錯誤類型（type mismatch, unknown identifier, tactic failed）
           - 調整策略重試

    if all attempts failed:
        記錄到 PROGRESS.md：
        - 定理名稱
        - 嘗試過的策略
        - 最後的錯誤訊息
        - 建議的人工介入方向
        還原 sorry（不要留 broken 的證明）
```

### Step 5: Tactic Strategies（按類型）

#### P1: Algebraic

嘗試順序：
1. `norm_num`
2. `ring`
3. `field_simp; ring`
4. `nlinarith` / `linarith`
5. `positivity`
6. `omega`（自然數/整數）
7. `field_simp; nlinarith`
8. 組合：`simp only [...]; ring`

#### P2: Structural

1. 讀取目標類型
2. 如果是 `∀`：`intro`
3. 如果是 `∃`：`exact ⟨witness, proof⟩` 或 `use witness`
4. 如果是 `A ∧ B`：`constructor`
5. 如果是 `A ∨ B`：`left` 或 `right`
6. 如果假設有 `A ∨ B`：`cases h`
7. 歸納類型：`induction` 或 `cases`
8. 最後嘗試 `simp [relevant_lemmas]`

#### P3: API Bridge

1. 從錯誤訊息或目標中提取關鍵概念
2. 搜尋 Mathlib：
   ```bash
   grep -rn "theorem.*{keyword}" ~/.elan/toolchains/leanprover-lean4-v4.*/lib/lean4/library/
   # 或在 Mathlib source 中搜尋
   ```
3. 嘗試 `exact?`（在本地 Lean LSP 中）
4. 如果找到候選，嘗試 `exact Mathlib.Theorem.name`
5. 如果型別不完全匹配，用 `apply` + 填補 arguments

#### P4: Deep

啟動 `lean-prover` agent（見 agents/lean-prover.md），給它：
- 完整的定理陳述
- 周圍的定義和相關 lemma
- 之前失敗的嘗試和錯誤
- 參考的數學證明（如果在 LaTeX 中有對應的 proof）

### Step 6: Report

完成後輸出：

```markdown
## Grind Report

- 初始 sorry 數：N
- 已消除：M
- 仍然卡住：K（列表 + 原因）
- axiom 數（預期保留）：A
- placeholder 數（需重寫）：P
- lake build 狀態：✓ / ✗

### 卡住的 sorry

| 定理 | 檔案:行 | 類型 | 嘗試次數 | 最後錯誤 | 建議 |
|------|---------|------|----------|----------|------|
| ... | ... | ... | ... | ... | ... |
```

### Step 7: Update PROGRESS.md

在 Lean 專案根目錄維護 `PROGRESS.md`：

```markdown
# Proof Progress

Last grind: {date}
Status: {N}/{Total} sorries eliminated

## Completed
- [x] `rasch_deficiency_neg` — `nlinarith` (2025-04-02)
- [x] `thm3_deficiency_formula` — `field_simp; linarith` (2025-04-02)

## In Progress
- [ ] `thm1_second_order_separation` — needs MLE variance expansion (P4)

## Blocked
- [ ] `hoadley_thm1_consistency` — depends on A.3 + A.4 (P4)

## Intentional Axioms (not sorry)
- `thmA1_sufficient_ui` — Neveu (1965), standard measure theory
- `loeve_markov_wlln` — Loève (1960), p. 275
```

## Integration with Other Tools

- **lean-prover agent**：P4 類型的 sorry 會委派給 agent 做深度嘗試
- **PostToolUse hook**：每次 Edit `.lean` 檔後自動 `lake build`
- **codex:rescue**：如果 agent 也卡住，可以 escalate 給 Codex
- **ralph-loop**：可以用 `/ralph-loop:ralph-loop` 包裝本 skill 做持續運行

## Notes

- 不要刪除有意保留的 `axiom`——它們是文章引用的外部結果
- 結論是 `True` 的定理（placeholder）需要先重寫陳述再證明
- 每次 commit message 格式：`prove: {theorem_name} — eliminate sorry`
- 如果 `lake build` 有非 sorry 的錯誤，優先修那些
