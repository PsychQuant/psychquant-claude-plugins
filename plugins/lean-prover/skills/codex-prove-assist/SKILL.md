---
name: codex-prove-assist
description: |
  智慧分配 Lean 4 定理證明工作給 Codex。
  我（Claude）先分析 sorry/stub，判斷 Codex 適合做什麼，
  只把「Codex 擅長」的部分派給他，其餘自己處理。
  Use when: 有 sorry 或 True := trivial 需要處理、想利用 Codex 的暴力搜索能力。
argument-hint: "FILE [--scope all|sorry|stubs] e.g. 'Ch4_Estimation.lean', 'Ch3:145', 'all --scope stubs'"
allowed-tools:
  - Bash(codex:*)
  - Bash(lake:*)
  - Bash(grep:*)
  - Bash(sed:*)
  - Bash(cat:*)
  - Bash(mktemp:*)
  - Bash(rm:*)
  - Bash(wc:*)
  - Bash(head:*)
  - Bash(tail:*)
  - Bash(git:*)
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
---

# /codex-prove-assist — 智慧分配 Lean 4 證明工作

我先分析，判斷什麼該派給 Codex、什麼該自己做，然後協調執行。

## 核心原則

> **我是 orchestrator，Codex 是 worker。** 我負責架構決策、bridge 設計、axiom 紀律；Codex 負責 tactic 暴力搜索和 statement 生成。

### 分工矩陣

| 任務類型 | 誰做 | 原因 |
|---------|------|------|
| `True := trivial` → 正式 theorem statement | **Codex** | 擅長從書的描述生成 Lean 4 類型 |
| 純 tactic 證明（`simp`/`linarith`/`omega` 組合） | **Codex** | xhigh 深度推理 + 暴力搜索 |
| CDF set equality 類型的代數證明 | **Codex** | 機械性 `ring`/`field_simp` 操作 |
| 需要新 Ch0 bridge 的證明 | **我** | 需要架構判斷 |
| 涉及 `IsProbabilityMeasure` instance 的 | **我** | Codex 不理解 Lean 4 type class |
| `Nat.cast` / coercion 問題 | **我** | Lean 4 特有的 elaboration 問題 |
| axiom 設計和放置 | **我** | axiom 只能在 Ch0 |
| 跨章節依賴分析 | **我** | 需要全局視野 |

### 公理紀律（CRITICAL）

> **axiom 只能放在 Ch0_Foundations.lean。** Codex 的 prompt 必須明確禁止在其他檔案新增 axiom。

- Codex 回傳的結果如果包含 `axiom`（在非 Ch0 檔案）→ **立即拒絕**
- 證不出來 → **留 sorry**，我來分析需要什麼 Ch0 bridge
- 需要新 bridge → **我在 Ch0 加 bridge，然後重新派 Codex**

## 執行流程

### Phase 0: 掃描與分類

```
1. 讀取目標檔案
2. 找出所有 sorry 和 True := trivial
3. 對每個目標分類：
   - STUB: True := trivial → 需要生成 theorem statement
   - TACTIC: 有完整 signature，缺 proof body → 需要 tactic 證明
   - BRIDGE: 需要新 Ch0 infrastructure → 我先處理
4. 輸出分類表給用戶確認
```

### Phase 1: Codex 生成 Theorem Statements（STUB 類型）

適用：`True := trivial` 需要變成正式 Lean 4 theorem。

**Prompt 構成**：
- 書的對應章節描述（從 docstring `/-- ... -/` 提取）
- Ch0 已有的定義和類型（ConvergesInProb, ConvergesInLaw, etc.）
- 同章前面已有的 theorem signatures（作為風格參考）
- **明確指示**：只生成 signature + sorry body，不要嘗試證明

```bash
OUTPUT_FILE=$(mktemp /tmp/codex_stmt_XXXXX)

codex exec \
  -c 'model="gpt-5.4"' \
  -c 'model_reasoning_effort="xhigh"' \
  -c 'service_tier="fast"' \
  -s read-only \
  -o "$OUTPUT_FILE" \
  --ephemeral \
  "$(cat $CONTEXT_FILE)"
```

**驗證**：`lake env lean $FILE` 確認 signature 類型正確（sorry 警告 OK）。

### Phase 2: 我分析 Bridge 需求

對每個 TACTIC 目標：
1. 讀取 theorem signature
2. 分析需要什麼 Mathlib/Ch0 工具
3. 檢查 `.claude/rules/mathlib-api.md` 是否有對應 API
4. 判斷：
   - 現有 bridge 足夠 → 標記為 CODEX_READY
   - 需要新 bridge → 我自己加到 Ch0，然後標記為 CODEX_READY
   - 需要改 theorem statement（加假設）→ 我修改後標記為 CODEX_READY
   - 本質上太難（需要深層 Mathlib 構造）→ 標記為 MANUAL

### Phase 3: Codex 證明（CODEX_READY 類型）

**Prompt 構成**：
```
=== TASK ===
Replace the 'sorry' with a complete proof.
The proof MUST compile with Lean 4 v4.28.0 + Mathlib v4.28.0.
Return ONLY the proof body (after ':= by'), no markdown, no explanation.

CRITICAL RULES:
- Do NOT add axiom, sorry, or admit anywhere
- Do NOT modify the theorem signature
- Use ONLY the API names listed in the reference below
- If you cannot prove it, return exactly: CANNOT_PROVE

=== THEOREM ===
{theorem with sorry}

=== AVAILABLE BRIDGES (Ch0) ===
{bridge lemma list from Ch0}

=== MATHLIB API REFERENCE ===
{from mathlib-api.md}

=== PRECEDING DECLARATIONS ===
{last 10 declarations before the theorem}

=== FILE HEADER ===
{first 30 lines: imports, namespace, variables}
```

如果是 loop 模式，加上：
```
=== PREVIOUS ATTEMPT FAILED ===
{build errors from last round}

Common Lean 4 / Mathlib v4.28.0 issues:
- ₀ suffix: div_le_iff₀, pow_le_pow_left₀
- Nat.cast: use ((n + 1 : ℕ) : ℝ) not ↑(n + 1)
- field_simp needs non-zero hypotheses
- abs_neg : |-(x)| = |x|
- nlinarith can't handle division — use explicit mul_div_cancel₀
```

### Phase 4: 驗證與修復迴圈

```
FOR round = 1 to MAX_ROUNDS (default 3):
  1. Codex 執行 → 取得 proof
  2. 檢查 proof 是否含 axiom/sorry/admit → 拒絕
  3. 檢查 proof 是否為 CANNOT_PROVE → 標記為 MANUAL，跳過
  4. 插入到檔案（先 git stash 備份）
  5. lake env lean $FILE 驗證

  IF 通過且無 sorry:
    → 成功！
    → BREAK

  IF 失敗:
    → 提取 build errors
    → 我先看錯誤：
      - Nat.cast 問題 → 我自己修
      - IsProbabilityMeasure 問題 → 我自己修
      - API 名字錯 → 附錯誤給 Codex 再試
      - 邏輯錯誤 → 附錯誤給 Codex 再試
    → 還原檔案
    → 繼續下一輪
```

### Phase 5: 收尾

```
FOR each MANUAL target:
  → 我自己嘗試證明
  → 如果需要新 bridge，加到 Ch0
  → 如果證不出，留 sorry + 報告缺什麼

最後輸出 summary table
```

## 輸出格式

```markdown
## codex-prove-assist: {file}

### Scan Results
| # | Theorem | Type | Assignment | Status |
|---|---------|------|------------|--------|
| 1 | thm_xyz | STUB | Codex | ✅ statement generated |
| 2 | lemma_abc | TACTIC | Codex | ✅ proved (round 2) |
| 3 | thm_def | BRIDGE | Me+Codex | ✅ added Ch0 bridge, Codex proved |
| 4 | thm_ghi | MANUAL | Me | ⏳ needs bridge_xxx |

### Ch0 Changes
- Added: bridge_foo, bridge_bar

### Sorry Remaining
{count and list}

### Codex Stats
- Statements generated: N
- Proofs attempted: M
- Proofs succeeded: K (round avg: X.Y)
- CANNOT_PROVE: J
```

## Codex CLI 參考

```bash
# 非互動模式（用於 STUB 和 TACTIC）
codex exec \
  -c 'model="gpt-5.4"' \
  -c 'model_reasoning_effort="xhigh"' \
  -c 'service_tier="fast"' \
  -s read-only \
  -o "$OUTPUT_FILE" \
  --ephemeral \
  "prompt text here"
```

- `-c` 值是 TOML 格式：字串要 `"quoted"`
- `-s read-only` 只讀沙盒
- `-o` 將回覆寫入檔案
- `--ephemeral` 不保存 session
- 如需讀 repo 檔案：`-s workspace-write`

## 安全設計

- **每輪都還原**：`git stash` 或 `git checkout -- $FILE`
- **axiom 檢查**：Codex 輸出經過 `grep -c "axiom"` 過濾
- **不動其他檔案**：只修改目標 .lean 檔
- **Build 驗證**：`lake env lean` 是唯一的成功標準
- **我先看錯誤**：Lean 4 type system 問題由我修，不浪費 Codex round

## 鐵律

- **Codex 產出 ≠ 證明**。只有 Lean type checker 通過才算。
- **axiom 只在 Ch0**。Codex 回傳的 axiom 一律拒絕。
- **我是 gatekeeper**。Codex 的每個 output 都由我審查。
- **分工要明確**。不要把需要架構判斷的工作丟給 Codex。
- **錯誤是資訊**。build error 是下一輪最重要的 context。
- **Codex 說 CANNOT_PROVE → 我接手**，不是放棄。
