# lean-prover — CLAUDE.md

## Purpose

Lean 4 自動證明磨削工具。廣度優先掃描 `.lean` 檔案中的 `sorry`，按難度分類排序，逐一嘗試用 tactic 消除，每成功一個就自動 commit。對於困難的 sorry，委派給 lean-prover agent 或 Codex 做深度嘗試。

## Skills

| Skill | 用途 |
|-------|------|
| `/lean-prover:grind` | 主迴圈：掃描、分類、嘗試證明、commit |
| `/lean-prover:status` | 顯示當前 sorry/axiom 數量和 lake build 狀態 |
| `/lean-prover:codex-prove-assist` | 智慧分配：Claude 分析 + Codex 暴力搜索 |

## Agent

| Agent | 用途 |
|-------|------|
| `lean-prover` | 對單一 sorry 做深度證明嘗試（Mathlib 搜尋、tactic 組合、錯誤分析） |

## Hook

| Hook | 觸發時機 | 行為 |
|------|----------|------|
| `lake-build-on-edit` | Edit/Write `.lean` 檔後 | 自動執行 `lake build`，回報錯誤數和 sorry 數 |

## Rules (from Leanist)

| Rule | 內容 |
|------|------|
| `mathlib-api.md` | Mathlib v4.28.0 常用 API 速查表（Measure Theory、ENNReal、Bochner 積分、Topology） |
| `lean-imports.md` | 定理引用規則（只能引用 Ch0 公理 + 同章前面的定理 + Mathlib 基礎） |
| `lean-references.md` | 引用已證結果必須用 import 不能用 axiom |

## Usage

```bash
# 查看進度
/lean-prover:status

# 開始磨削
/lean-prover:grind /path/to/lean4/project

# 搭配 ralph-loop 持續運行直到全部完成
/ralph-loop:ralph-loop /lean-prover:grind /path/to/lean4/project --completion-promise 'lake build has zero sorry warnings'

# 限制迭代次數
/ralph-loop:ralph-loop /lean-prover:grind /path --max-iterations 20

# 用 Codex 暴力搜索
/lean-prover:codex-prove-assist Hoadley1971.lean --scope sorry
```

## Design Principles

1. **不破壞**：任何 sorry 如果嘗試失敗，還原為 sorry，不留 broken 的證明
2. **不刪弱**：不修改定理陳述來降低難度
3. **不偽裝**：`True := trivial` 不算證明，必須有正確的類型簽名
4. **axiom 紀律**：axiom 只用於尚未形式化的外部結果，帶來源標註
5. **分層**：簡單 tactic → lean-prover agent → Codex 暴力搜索
6. **可追蹤**：`PROGRESS.md` 記錄所有進度和卡住原因
7. **可中斷**：隨時可以停止，已完成的 commit 不受影響

## Mathlib API 速查

寫證明時先查 `rules/mathlib-api.md`，不要猜 API 名字。常見陷阱：

- `integral_mul_left` **不存在**於 Bochner → 用 `bridge_integral_mul_left`
- `abs_add` **不存在** → 用 `abs_lt` 分解
- `Nat.cast`：用 `((n + 1 : ℕ) : ℝ)` 不是 `↑(n + 1)`
- `div_le_iff` → 用 `div_le_iff₀`（v4.28.0 加了 ₀ suffix）
