# Manuscript ↔ JSONL Sync — 改一邊必改另一邊（prop-level）

## 規則 (HARD RULE)

本專案的 `manuscript/main.tex` 與 `manuscript/propositions/main.jsonl` (+ `_stage2/*.jsonl` + `_pilot/*.jsonl`) 是**單一 source of truth 的兩面**，不是兩個獨立 deliverable。

任何 `main.tex` 內容改動（rewording / restructure / 加減 sentence / line shift）都**必須**在同一個 commit / change cluster 內審視並更新對應的 propositions JSONL props。**禁止**「先改 main.tex 等之後再 sync jsonl」— 那等於把 R1 drift 變成 latent debt。

對應的 macro-level rule 是 [`code-and-manuscript-sync.md`](code-and-manuscript-sync.md)（manuscript ↔ code 跨 repo PR scope）。本 rule 是 **finer-grained**：manuscript 內部 main.tex ↔ JSONL sync。兩條 rule 互補不重疊。

## 為什麼

JSONL 結構是 **manuscript 的 structural representation** — 每個 prop 對應 main.tex 一句 / 一段論述，攜帶 `text`（verbatim from .tex）+ `location`（line range）+ `cites`（內部依賴 UUID）+ `asserts`（原子化 claim）+ `claim_type` + `evidence_class`。下游消費者包括：

- `validate-propositions.py` R1-R8 audit gate（驗 verbatim match / DAG / 唯一性）
- `manuscript-consistency-audit.md` SOP 的 R3 code-↔-manuscript drift detection
- 校稿 workflow（per `#107` proofread experiment）— 利用 jsonl 結構做 per-prop 檢核
- 未來 `idd-verify` 可能讀 jsonl 做 propositional verification

若 main.tex 改了但 jsonl 沒同步：

| 漂移類型 | 後果 |
|---------|------|
| **prop.text drift** | R1 prop-subset-check FAIL（validator gate 紅燈） |
| **location drift** | R1 substring match 可能仍 PASS，但 `location` field 失準 → human-navigate-by-line 跳到錯誤行 → 重新 audit / proofread 時 false location reports（per #106 / pilot 1 + 2） |
| **新增 sentence 沒對應 prop** | R1.5 surjective coverage WARN（某些 main.tex 段落沒 prop 覆蓋） |
| **刪除 sentence 但 prop 留著** | R1 FAIL（prop.text 找不到） |
| **cite chain 對應錯誤** | R3 DAG check 可能仍 PASS（內部 UUID 引用），但語意上 prop A 不再 derive 自 prop B（main.tex 已 restructure 依賴關係） |

## Sync 範圍 — 改動類型 × 對應 jsonl action

### 1. Wording change（micro-edit，不動結構）

例：typo fix、`\sigma$ continuous` → `\sigma$ continuous and nonzero`。

| Action | Required |
|--------|----------|
| 找出包含該段的 prop（grep `prop.text` 與更新前段落首句相符） | ✓ |
| Update prop.text to new wording verbatim | ✓ |
| Re-run `python3 scripts/validate-propositions.py --jsonl ... --tex ...` 確認 R1 PASS | ✓ |
| Update asserts if semantic changed | conditional |

### 2. Line shift（contents 不變但 line range 改變）

例：在 L100 area 加 5 行，後面所有 line 都 +5。

| Action | Required |
|--------|----------|
| Run `scripts/refresh-prop-locations.py --jsonl <file>` to refresh `location` fields | ✓ |
| Validate R1 still PASS post-refresh | ✓ |
| Update `_meta.json` line ranges if sections shifted | conditional |

### 3. Add sentence / paragraph

例：新增 footnote 補強說明。

| Action | Required |
|--------|----------|
| 對新增內容寫 1+ 新 prop（依 granularity convention） | ✓ |
| 新 prop 用 UUID v7（per `EXTRACTION-PROMPT.md` + SCHEMA v1.2+） | ✓ |
| 設適當 cites field（內部 dependency UUID）+ claim_type + evidence_class | ✓ |
| Append to appropriate JSONL file (`main.jsonl` for paper body / `_stage2/*.jsonl` for Theorem 1 staging) | ✓ |
| Re-validate R1-R8 | ✓ |

### 4. Delete sentence / paragraph

例：撤回一段 commentary。

| Action | Required |
|--------|----------|
| 找對應 prop（grep main.jsonl + _stage2/*.jsonl） | ✓ |
| 刪除該 prop | ✓ |
| Grep `cites` field of remaining props for the deleted UUID — strip if any | ✓ |
| Re-validate R3 (no dangling cite reference) | ✓ |

### 5. Restructure（reorder sentences / split paragraph / merge sentences）

例：把 Cases A/B/C/D 的 γ formulas 從 inline 改成 align*。

| Action | Required |
|--------|----------|
| Read affected prop range; reassess granularity（new structure 可能需要 prop split or merge） | ✓ |
| Update prop.text + location + sentence_index/clause_index | ✓ |
| Cite chain may need re-anchoring（restructured dependencies） | ✓ |
| Re-validate R1+R3+R6 | ✓ |

### 6. Cite chain modification (jsonl only, no main.tex change)

例：本 rule 範例 #1 — proofread workflow 發現 P91 漏 cite Iverson similarity equation 的 Setup prop。

| Action | Required |
|--------|----------|
| Update prop.cites field with missing UUID | ✓ |
| Re-validate R2 cite-resolve + R3 DAG | ✓ |
| **No main.tex change** required（cite is jsonl metadata，不出現在 paper body） | — |

## Diagnosis 階段必檢

`/idd-diagnose` 對任何 `manuscript/main.tex` 改動 (`scope:manuscript` label) **必須**在 Strategy 段顯式回答：

1. 此 main.tex 改動會 invalidate 哪些 `manuscript/propositions/*.jsonl` 的 props？(grep prop.text 對應段落)
2. 此改動屬於上方哪種 sync 範圍類型（wording / line shift / add / delete / restructure / cite-only）？
3. 對應的 sync action 是否在本 cluster 的 implementation plan 內？如否，**升級** scope 或 abort 重新 diagnose。

回答「**N/A — 純 cite-chain edit，不動 main.tex**」是合法答案（情境 6），但必須明示寫出該判斷。

## Implementation 階段必檢

`/idd-implement` 對 manuscript edit + propositions edit 的 cluster：

1. 在 staging（pre-commit）先跑 `python3 scripts/validate-propositions.py --jsonl ... --tex ...` 確認 R1 PASS
2. 若 location shifted → 跑 `scripts/refresh-prop-locations.py --jsonl ...`（per #106 fix）
3. Commit 同時納入 main.tex changes + jsonl changes，**不**拆 2 commits（intermediate state validator FAIL）

## Verification 階段必檢

`/idd-verify` 的 Regression Reviewer **必須**額外驗證：

- diff 中 main.tex 的改動 line range，grep `manuscript/propositions/*.jsonl` 的 `location` field 看是否有對應 prop
- 若 main.tex shifted N lines (insert/delete) — 確認 jsonl 內後段 props 的 `location` 已對應 shift
- R1 prop-subset-check：所有 props 仍 verbatim found in updated main.tex
- 若 manuscript edit cluster 沒有 jsonl 對應 commit → **blocking finding**，verify FAIL

## 自動化（partial）

`scripts/validate-propositions.py` 提供 mechanical-level enforcement:

- R1 catches text drift
- R3 catches dangling cite from deleted props
- R6 catches sentence/clause-index invariant violation
- R8 catches duplicate UUID after add/delete

但**不**catch：

- semantic drift（main.tex reworded but jsonl still semantically valid — only human review catches this）
- line-anchor drift（R1 使用 substring containment over whole file，不檢查 location 字面）— per #106, 需要 `scripts/refresh-prop-locations.py` 或 future R9
- claim_type / evidence_class 漂移 — schema-aware heuristics 需要 calibration（per #107 proofread experiment）

## 例外

容許 main.tex edit 不立即 sync jsonl 的唯一情境：

- **Pre-extraction phase**: manuscript 剛起草，尚未開始任何 propositions extraction（pre-#69 / pre-#77 state）。此情境下 jsonl 不存在或非 active artifact，不適用 sync rule。
- **Author works in Overleaf concurrently**: 若 author 在 Overleaf 改稿，AI 本機 session 看到 working tree 仍 stale。此情境下 AI **必須**在 diagnose 階段 explicit 註記「Overleaf-side 改動可能 in-flight」+ `OVERLEAF-WAIT` 標籤，per `code-and-manuscript-sync.md` § Overleaf 衝突 in-flight 例外。

## 歷史成因

本 rule 2026-05-15 加入，起因：

1. **#60 Path C revert (commit `35c964a`)** main.tex 改 75 行，propositions sync 需要刪 6 + 7 props + update 3 props + strip 5 dangling cites — 過程中 R-3 risk (high) 已 mitigated 在 plan，但實作中差點漏掉。
2. **#106 location drift audit-finding**：13 props 在 `_stage2/theorem1.jsonl` `location` field 與實際 main.tex 不對應，因 Path C content edits 後沒 refresh location。屬於 line-shift sync 缺口的 latent debt。
3. **#107 proofread workflow pilot**：將 jsonl 升格為 校稿 checklist source 後，prop-level 對應到 main.tex 的精確性變成 first-class 需求 — R1 substring match 不夠。
4. **Pilot 2 L4 alignment walk (Step 1, 7 props)**：surface 2 個 L3 cite-completeness gap (P91 漏 Iverson eq cite, P94 漏 Setup interval cite) — 屬於情境 6 (cite-only edit) 但前一輪 extraction 沒抓到，需要 prop-level discipline 而非整段 audit。

## 與其他 rules 的關係

| Rule | Scope | When fires |
|------|-------|-----------|
| [`code-and-manuscript-sync.md`](code-and-manuscript-sync.md) | repo-level（upper repo ↔ manuscript submodule cross-repo PR） | macro: cluster PR cross-link discipline |
| [`manuscript-consistency-audit.md`](manuscript-consistency-audit.md) | audit-time（drift detection across long timespan） | post-hoc: 大改稿 / 投稿前掃描 R1-R4 |
| **本 rule** `manuscript-jsonl-sync.md` | edit-time（每次 main.tex edit 同時 jsonl sync） | per-commit: 每個 manuscript change |

三者互補:
- 本 rule 是 **prevention** at edit time
- consistency-audit 是 **detection** post-hoc
- code-and-manuscript-sync 是 **cluster PR scope** discipline

## See also

- [`code-and-manuscript-sync.md`](code-and-manuscript-sync.md) — macro-level cross-repo sync
- [`manuscript-consistency-audit.md`](manuscript-consistency-audit.md) — audit-time detection SOP
- `manuscript/propositions/SCHEMA.md` — JSONL schema reference
- `manuscript/propositions/EXTRACTION-PROMPT.md` — prop extraction discipline
- `scripts/validate-propositions.py` — R1-R8 mechanical gate
- `scripts/refresh-prop-locations.py` (#106) — one-shot location refresh
- #107 — proofread workflow experiment (this rule's first concrete consumer beyond IDD)
