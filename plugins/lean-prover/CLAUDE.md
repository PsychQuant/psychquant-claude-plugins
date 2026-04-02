# lean-prover — CLAUDE.md

## Purpose

Lean 4 自動證明磨削工具。廣度優先掃描 `.lean` 檔案中的 `sorry`，按難度分類排序，逐一嘗試用 tactic 消除，每成功一個就自動 commit。對於困難的 sorry，委派給專門的 lean-prover agent 做深度嘗試。

## Skills

| Skill | 用途 |
|-------|------|
| `/lean-prover:grind` | 主迴圈：掃描、分類、嘗試證明、commit |
| `/lean-prover:status` | 顯示當前 sorry/axiom 數量和 lake build 狀態 |

## Agent

| Agent | 用途 |
|-------|------|
| `lean-prover` | 對單一 sorry 做深度證明嘗試（Mathlib 搜尋、tactic 組合、錯誤分析） |

## Hook

| Hook | 觸發時機 | 行為 |
|------|----------|------|
| `lake-build-on-edit` | Edit/Write `.lean` 檔後 | 自動執行 `lake build`，回報錯誤數和 sorry 數 |

## Usage

```bash
# 查看進度
/lean-prover:status

# 開始磨削
/lean-prover:grind /path/to/lean4/project

# 限制每個 sorry 最多嘗試 5 次
/lean-prover:grind /path/to/lean4/project --max-attempts 5

# 只掃描不修改
/lean-prover:grind /path/to/lean4/project --dry-run

# 搭配 ralph-loop 持續運行
/ralph-loop:ralph-loop 15m /lean-prover:grind /path/to/lean4/project
```

## Design Principles

1. **不破壞**：任何 sorry 如果嘗試失敗，還原為 sorry，不留 broken 的證明
2. **不刪弱**：不修改定理陳述來降低難度
3. **分層**：簡單的 tactic 先掃一輪，困難的委派給 agent
4. **可追蹤**：`PROGRESS.md` 記錄所有進度和卡住原因
5. **可中斷**：隨時可以停止，已完成的 commit 不受影響
