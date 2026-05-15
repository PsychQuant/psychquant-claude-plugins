# Manuscript Consistency Audit SOP

> Audit-time detection of inconsistencies that accumulate in the manuscript over multi-author / multi-iteration editing.

## §1 Scope & purpose

本 SOP 是 audit-time detection 工具，互補於 `code-and-manuscript-sync.md`(PR-time prevention)。前者防止單一 PR 內 code/manuscript drift；本 SOP 處理「歷史 drift 已累積後」的補救。

**何時跑本 SOP**

- 大改稿後(例如某次大幅 rewrite section、新增 theorem、整體 reorganize)
- 投稿前最後一輪檢查
- Manuscript 進新階段(initial submission、major revision、camera-ready)前

**何時不跑**

- 每個 PR 都跑 → 太重(60K manuscript full audit 估 30-60s)。Pre-PR lightweight diff 是 #44 範圍
- Minor commit 後(typo、單詞替換)→ 不必

## §2 Inconsistency types & detection coverage

| Type | 例子 | 自動偵測 | 覆蓋 rule |
|------|------|----------|-----------|
| 符號 / 變數命名 drift | 第 2 節用 $\theta$ 第 4 節變 $\beta$;`analysis/` 用 `mse_diff` 但 manuscript 寫 `MSE_d` | 部分(R1 抓 `\texttt{}` working-file leak;R3 抓 code/manuscript symbol drift) | R1, R3 |
| 定義 / 假設邏輯矛盾 | 某處定義 $X$ 為連續變數,另一處推導當作離散 | 不(語意層必人工) | 無 |
| code/manuscript drift | `analysis/` 改了但 `manuscript/docs/` 未同步 | 是(R3) | R3 |
| Citation / reference drift | `\cite{Smith2020}` 但 `refs.bib` 是 `Smith2021`;漏 bib 條目;LaTeX label 當 published reference | 是(R2 + R2-bis) | R2, R2-bis |
| Narrative / wording 跳接 | 段落間邏輯接不上;術語在不同章節用不同中譯 | 不(語意層必人工) | 無 |
| Working-file path leak | `main.tex` 引用 `\texttt{analysis/foo.py}` 或 `\texttt{manuscript/docs/note.md}` | 是(R1) | R1 |
| Proposition ↔ tex drift | `.tex` 新增 prop 對應段落但 `propositions/main.jsonl` 沒同步;mechanical contradiction (e.g. boundary axiom 違反 — see #60 / #68) | 是(R4 — Phase 1 prop-subset-check + PATTERN-A/B mechanical-contradiction) | R4 |

自動覆蓋率約 60-70%(types 1, 3, 4, 6 子集 + type 7)。語意層 inconsistency(types 2, 5)必人工處理,本 SOP 不取代但提供 symbol table 索引輔助快速定位。R4 是 Locke-project 衍生 — 僅當 manuscript 有 `propositions/main.jsonl`(或 legacy `main.json`)才跑。

## §3 Excluded paths

以下路徑屬 frozen historical record，audit 不掃:

- `manuscript/docs/rounds/` — Review round audit log,frozen at the time of review
- `manuscript/docs/legacy/` — 已 retire 的 working drafts
- `correspondence/` — Email archive,frozen at receipt time
- `references/*.tex` — 歷史 reference papers,frozen
- 任何 `archive/` / `archived/` 目錄(已由 archive-first plugin 守護)

理由與 `code-and-manuscript-sync.md` Frozen historical record exception 一致:這些路徑的 value 是 audit trail,retroactive editing 會 destroy 該 value。詳見 [code-and-manuscript-sync.md](code-and-manuscript-sync.md) Frozen exception 段落。

## §4 Pass-level vs Finding-level task model

Audit 採 **hybrid two-layer task** model:

### Pass-level(per inconsistency type，掃全文建索引)

固定 small N(~3 pass)。每 pass 對應一條 rule:

1. **Pass R1**: 掃 `main.tex` 所有 `\texttt{}` token,抓 working-file path leak
2. **Pass R2**: 掃 `\cite*{}` keys + parse `refs.bib`,做 label leak detection + bib cross-check
3. **Pass R3**(Phase 2): 比對 `analysis/*.py` AST vs `manuscript/docs/*.md` backtick code

Pass 之間 independent,可 parallel 跑(`run-audit.sh` 預設 serial,簡化 output ordering)。

### Finding-level(per detected conflict，deep dive)

Variable N(典型 5-30)。Pass 跑完後,**每個 definite + likely finding 開一個 task** 處理:

- 確認是真衝突還是 false positive
- 決定 fix 方向(改 manuscript / 改 code / mark white-list)
- 若 critical(影響 published claim 的正確性)→ 開 `audit-finding` issue 走 IDD 流程

純 per-paragraph(每段一個 task)**不採用** — 不一致性本質是「A 段 vs B 段」cross-reference 關係,單看一段抓不到。

## §5 Trigger 時機

| 階段 | Trigger | Audit 範圍 | 處理 |
|------|---------|------------|------|
| 大改稿後 | 手動 `./scripts/run-audit.sh manuscript/` | Full(R1 + R2 + R3) | 產生 `manuscript/docs/audit/audit-YYYY-MM-DD.md`;critical findings 開 issue |
| 投稿前 | 手動同上 | Full | 同上,要求 zero definite finding 才送投 |
| 每個 PR(touching `main.tex`/`analysis/`/`refs.bib`) | pre-commit hook(由 #44 實作) | Lightweight diff(only changed symbol cross-check) | 阻擋 commit if definite finding |

**Precondition(SOP §8)**: audit 前必確認 working tree state,避免 concurrent editing race。

## §6 Output 形式

### Audit report

- 落地路徑:`manuscript/docs/audit/audit-YYYY-MM-DD.md`
- 在 manuscript submodule 內(報告 reference manuscript 內容 → 跟 manuscript 一起 frozen 在歷史)
- `.gitignore` 排除自動產出檔(`audit-20[2-9][0-9]-[0-1][0-9]-[0-3][0-9].md` ISO date pattern),只保留目錄結構(`.gitkeep`)
- Severity 分級:
  - **definite**: 確定違例,必修(e.g. working-file path leak、citation key 不在 bib)
  - **likely**: 80%+ 機率違例(e.g. citation label leak、symbol drift candidate)
  - **suspicious**: 50-80%(e.g. 不在 white-list 的少見 `\texttt{}` 用法)
  - **FYI**: < 50%(e.g. bib orphan、code-only symbol 未在 manuscript 提)

### Critical finding → GitHub issue

- definite + likely 開 issue,label `audit-finding` + `scope:manuscript`
- 走 IDD 流程修復(`/idd-diagnose` → `/idd-implement`)
- suspicious + FYI 只進 audit report 不發 issue,避免 noise

### 不自動 PATCH manuscript

- audit 是 read-only。Findings 的 fix 決定權在 author(可能不同 finding 用不同策略,e.g. 改 manuscript / 改 code / mark intentional)

## §7 Audit report 格式 spec

```markdown
# Manuscript Consistency Audit — YYYY-MM-DD

**Manuscript snapshot**: <git rev-parse HEAD of manuscript repo>
**Audit tool versions**: audit-symbols.py vX.Y / audit-citations.py vX.Y / audit-code-manuscript.py vX.Y

## Summary

- Definite: N findings
- Likely: M findings
- Suspicious: K findings
- FYI: J findings
- Total: N+M+K+J

## Findings

### Definite

#### F1: <one-line description>
- **Rule**: R1 / R2 / R2-bis / R3
- **Location**: `<file>:<line>`
- **Context**: <surrounding ±2 lines>
- **Proposed fix**: <suggestion>
- **Tracking issue**: #NNN (if opened)

(repeat per finding)

### Likely

(same format)

### Suspicious / FYI

(condensed table format)
```

## §8 Run instructions

### Pre-flight

```bash
# 1. Ensure working tree clean (avoid concurrent-editing race)
cd /path/to/psychophysic_representations
git status --short  # must be empty
git submodule status  # ensure manuscript pointer matches expected

# 2. Pull latest (avoid auditing stale state)
git pull --rebase
cd manuscript && git pull --rebase && cd ..
```

### Run

```bash
# Phase 1 only (Rule R1 + R2):
python3 scripts/audit-symbols.py --manuscript-root manuscript/ --report-format md
python3 scripts/audit-citations.py --manuscript-root manuscript/ --report-format md

# Phase 2 full audit (adds R3 + R4 + orchestration):
./scripts/run-audit.sh manuscript/
# → 產生 manuscript/docs/audit/audit-$(date +%F).md
# R4 (proposition-iso) 只在 manuscript 有 propositions/main.jsonl 時才跑
# (legacy single-file propositions/main.json 仍接受作為 fallback)

# 單跑 R4 (proposition-iso bijection check, Locke project):
python3 scripts/validate-propositions.py \
  --jsonl manuscript/propositions/main.jsonl \
  --meta manuscript/propositions/_meta.json \
  --tex manuscript/main.tex

# Legacy fallback (mid-migration repos still on single-file JSON):
python3 scripts/validate-propositions.py \
  --json manuscript/propositions/main.json \
  --tex manuscript/main.tex
```

### Three enforcement layers (#78)

| Layer | When | What |
|-------|------|------|
| `.githooks/pre-commit` (author-side) | Per-commit, when staged paths match audit-relevant globs | Fast R1+R2+R4 (R3 too slow per-commit) |
| `./scripts/run-audit.sh manuscript/` (manual full) | Per SOP §5 trigger (大改稿 / 投稿前 / 新階段) | Full R1+R2+R3+R4 |
| `.github/workflows/manuscript-audit.yml` (PR-side, GitHub Actions) | Every PR + push to main, paths-filtered | Full R1+R2+R3+R4; fails on R1/R2/R4 blocking, R3 informational |

CI gate (third layer) catches external contributors / forgotten pre-commit hook. After first green run, mark `manuscript-audit / run` as required status check on `main` branch (Settings → Branches → Branch protection rule).

### Exit codes

- `0`: clean (zero findings of any severity)
- `1`: at least one finding (any severity)
- `2`: tool error (script crash, missing file, etc.)

### Post-flight

- Review report,definite + likely findings 開 `audit-finding` issue 走 IDD
- 把 `.claude/.idd/audit-history.log` 加一行(或類似 trail)記錄 audit datestamp、commit hash、finding counts(方便 trend tracking,未實作)

## §9 Examples / known patterns

### Pattern 1: working-file path leak in `\texttt{}` (Rule R1)

**Bad** (caught by R1):
```latex
Sympy substitution verifications are provided in
\texttt{analysis/verify\_eta\_fs.py} (companion derivation
in \texttt{manuscript/docs/gc\_iverson\_eta\_fs.md}).
```

**Fix**: delete the sentence(formal manuscript 不該引用內部 working scripts)

**Good**(white-listed):
```latex
\bibliography{refs.bib}  % whitelisted: bibliography reference
% \texttt{old_var}      % comment, not rendered
```

### Pattern 2: citation label leak (Rule R2)

**Bad** (caught by R2):
```latex
\citet[Theorem~\texttt{main\_thm\_ess}]{DobleHsu2020}
```

(`main_thm_ess` 是 DobleHsu 2020 source 的 LaTeX `\label{}` ID,不是 published theorem 編號)

**Fix**: 改成 content-based description:
```latex
\citet[Theorem on $\eta = f(s)$ case]{DobleHsu2020}
```

或直接刪除 parenthetical(如果 surrounding sentence 已說明 theorem context)。

### Pattern 3: working-note file reference (Rule R1)

**Bad** (caught by R1):
```latex
\item ... (working note, file
\texttt{note (Hsu 2024-02).tex}, line $\sim$173). The note isolates ...
```

**Fix**: 刪 parenthetical,保留 sub-section 標籤(若 label 仍有 trace 價值):
```latex
\item ... The note isolates ...
```

### Pattern 4: companion working doc reference (Rule R1)

**Bad** (caught by R1, 2026-05-13 example):
```latex
... \texttt{manuscript/docs/note-2024-02-audit.md}.
```

**Fix**: 改成 content-based description:
```latex
... as catalogued in our companion working documentation.
```

或刪除(若 context 已足夠)。

### Pattern 5: bib orphan (Rule R2-bis)

**Bad**(caught by R2-bis):
```latex
\cite{Missing2020}  % but Missing2020 not in refs.bib
```

**Fix**: 加 bib 條目,或修正 cite key typo。

### Pattern 6: code symbol drift (Rule R3, Phase 2)

**Bad**(caught by R3):
```latex
% manuscript/docs/foo.md:
... computed via `mse_diff` ...

% but analysis/foo.py defines `mse_difference`, not `mse_diff`
```

**Fix**: 對齊命名,改 code 或改 manuscript(端視哪邊已 published)。

### Pattern 7: False positive suppression / calibration

**症狀**: R3 對 real manuscript 跑出大量 `definite` findings,點開看全是 LaTeX `\label{}` ID、`\cite{}` key、bib entry key。

**根因**: backtick code refs `` `X` `` 在 manuscript context 不僅可能是 Python symbol,也常是:
- LaTeX label(`\label{thm:foo}` → `` `thm:foo` ``)
- Citation key(`\cite{Smith2020}` → `` `Smith2020` ``)
- Bibliography entry(`@article{Smith2020, ...}`)
- Filename(`` `note.tex` ``)

R3 預設只比對 Python AST symbol,不認識這些 LaTeX-domain 名稱。

**解法**(已 implement,自 v0.2):

`audit-code-manuscript.py` 內建 `collect_latex_allowlist()` 自動 scan:
- `<manuscript-root>/**/*.tex` 的 `\label{}` 與 `\cite{}` keys
- `<manuscript-root>/**/*.bib` 的 entry keys(只認可 BibTeX 標準 type,不抓 `@string`/`@comment`/`@preamble`)
- Sibling `<manuscript-root>/../references/**/*.tex`(working note .tex,自動發現)

可額外用 `--latex-source-root <path>` 加入其他 directory(例如 Overleaf 共筆夾)。

**Allowlist hit 處理**: severity 從 `definite` demoted 到 `FYI`,不開 issue,只 informational。`audit-code-manuscript.py:179-200` 內 `in_latex_domain` 判斷邏輯。

**Calibration baseline**: `psychophysic_representations` repo first audit 2026-05-13 在 v0.1 報 86 definite + 25 FYI;v0.2 fix 後降到 18 definite(全部都是 real drift:hallucinated label `basic_fe_phil`、stale check function references)+ 93 FYI。

**仍 leak 通常代表 real drift**:
- 引用 `lem_Foo` 但任何 `.tex` / `.bib` 都沒有此 label → 可能是 hallucinated reference
- 引用 `check_bar` 但 `analysis/*.py` 沒此 function → 可能是 stale doc 引用已移除的 helper

不要把 v0.2 後仍 leak 的 finding 當 noise — review-summary.md 內已有先例(`basic_fe_phil` hallucinated)。

### Pattern 8: First-audit calibration workflow

新 manuscript 第一次跑 audit 預期 noise > 0,即使本 SOP fix 後:

1. 跑 `./scripts/run-audit.sh manuscript/`
2. Definite 數量看 R1 + R2 + R3:
   - R1 (working-file leak):應 ≤ 2(若 > 5,review baseline manual audit)
   - R2 (label leak):應 ≤ 1(同上)
   - R3 (code drift):依 codebase 複雜度,2-20 為 healthy range;> 30 仍 noisy → 可能需要 extra `--latex-source-root`
3. 對每個 definite finding,先判 category:
   - **真 drift**(symbol typo / rename / removed)→ 開 `audit-finding` issue
   - **R3 allowlist miss**(label/cite/bib 在 import 之外的 file)→ 加 `--latex-source-root` 涵蓋,或 file enhancement issue
   - **R3 真陽性 但 manuscript-side 是 deliberate 內部 reference**(罕見)→ 加 `audit-ignore` 機制(目前 v0.2 未實作,屬 future enhancement)
4. SOP §9 Pattern 7 + 8 是首跑教學;熟練後跳過

## §10 Relationship to other rules / skills

- [`code-and-manuscript-sync.md`](code-and-manuscript-sync.md) — PR-time prevention,本 SOP audit-time detection,互補
- [`issue-routing.md`](issue-routing.md) — `audit-finding` issue 一律開上層 repo,加 `scope:manuscript` label
- `/spectra-verify` — spec-driven verify 不取代本 SOP;前者驗 spec contract,後者驗內部一致性
- Pre-commit hook integration + skill orchestration — 由 #44 (sister concern of #42) 追蹤

## Changelog

- 2026-05-13: initial version,covers Phase 1 (R1 + R2 + R2-bis);R3 + orchestration 在 Phase 2 補
- 2026-05-13 (v0.2): R3 calibration hot-patch — LaTeX label / cite / bib entry allowlist,
  auto-discover sibling `references/`,severity demoted from `definite` → `FYI` for allowlist hits.
  Also: BibTeX `@string`/`@comment`/`@preamble` no longer mis-classified as bib entries.
  `ast.parse` failure now warns instead of silent empty set. §9 Pattern 7/8 added.
  Addresses verify findings F-R3-Cal, F-Logic-C2, F-Codex-F6. See #42 PR #49 verify comment.
