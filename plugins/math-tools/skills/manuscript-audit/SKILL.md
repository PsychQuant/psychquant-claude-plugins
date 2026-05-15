---
name: manuscript-audit
description: |
  Audit-time cross-doc drift detection for math manuscript. Runs R1 (working-file path leak in \texttt{}),
  R2 (citation key drift / bib orphan), R3 (code symbol drift between analysis/ and manuscript/docs/),
  R4 (proposition-jsonl iso-bijection check, optional when manuscript has propositions/main.jsonl).

  Different from `propositions` skill (R1-R8 mechanical gate on JSONL alone) and `proofread` skill
  (L4 semantic walk per-prop). This skill checks the **cross-artifact consistency** between
  manuscript/main.tex + propositions/*.jsonl + analysis/*.py + references/*.tex + refs.bib.

  Use when: 大改稿後 / 投稿前 / 新階段 (initial submission / major revision / camera-ready).
  NOT for per-PR (use `code-and-manuscript-sync.md` rule + pre-commit hook).

  v0.1.0 SCAFFOLDING — execution body TODO. Source scripts currently at
  PsychQuantHsu/psychophysical_representations/scripts/audit-*.py + run-audit.sh.
allowed-tools:
  - Read
  - Write
  - Bash
  - Grep
  - Glob
  - AskUserQuestion
---

# Manuscript Audit — Cross-Doc Drift Detection

## Status (v0.1.0)

**Scaffolding only.** Source-of-truth orchestrator + scripts at:

```
PsychQuantHsu/psychophysical_representations/
├── scripts/
│   ├── run-audit.sh                  # Orchestrator (R1+R2+R3+R4 in order)
│   ├── audit-symbols.py              # R1: working-file path leak in \texttt{}
│   ├── audit-citations.py            # R2: cite-key drift, bib orphan
│   ├── audit-code-manuscript.py      # R3: code <-> manuscript symbol drift
│   └── validate-propositions.py      # R4: prop-subset-check + R1-R8 (re-used)
└── .github/workflows/manuscript-audit.yml   # PR-side CI gate (#78)
```

3-layer enforcement (per `manuscript-consistency-audit.md` §8):

| Layer | Enforcement | Failure mode |
|-------|-------------|--------------|
| `.githooks/pre-commit` (author-side) | Fast R1+R2+R4 on staged paths | Commit aborts (--no-verify bypass for emergency) |
| `./scripts/run-audit.sh manuscript/` (manual) | Full R1+R2+R3+R4 | Author decides whether to fix |
| `.github/workflows/manuscript-audit.yml` (PR-side CI) | Full audit on every PR + push to main | PR red light, blocks merge for R1/R2/R4; R3 informational |

## R1-R4 Coverage (frozen contract)

| Rule | Detects | Allowlist (auto) |
|------|---------|------------------|
| **R1** | `\texttt{path/to/working/file.ext}` working-file leak in main.tex | `\bibliography{refs.bib}` (whitelisted), commented `% ...` |
| **R2** | `\cite{X}` where X not in refs.bib; cite-label leak (`\citet[Theorem~\texttt{main_thm_ess}]{Foo2020}` referring to source label not published thm number) | bib entries (`@article{X,...}` keys auto-scanned + `--latex-source-root` for sibling working notes) |
| **R3** | Backtick code refs `` `foo_func` `` in `manuscript/docs/*.md` not found in `analysis/*.py` AST | LaTeX `\label{}` + `\cite{}` keys + `@article` BibTeX keys + sibling `references/**/*.tex` |
| **R4** | Proposition-jsonl iso-bijection failure (PATTERN-A boundary-axiom contradiction) | Only when `manuscript/propositions/main.jsonl` exists; legacy `main.json` accepted as fallback |

## Excluded Paths (frozen historical record)

These are **frozen audit trail**, never modified retroactively:

- `manuscript/docs/rounds/` — Review round audit log
- `manuscript/docs/legacy/` — Retired drafts
- `correspondence/` — Email archive
- `references/*.tex` — Historical reference papers
- `archive/` / `archived/` (archive-first plugin守護)

## Execution Steps (v0.2.0 target — TODO)

### Step 0: Bootstrap Stage Task List

```
TaskCreate parse_args / pre_flight_clean_check / pull_latest /
            run_audit / parse_findings / classify (definite/likely/suspicious/FYI) /
            decide_per_finding_action (file audit-finding issue / fix inline / mark intentional / suppress) /
            generate_report_md
```

### Step 1: Pre-flight

```bash
git status --short          # MUST be empty (avoid concurrent-editing race)
git pull --rebase
cd manuscript && git pull --rebase && cd ..
```

### Step 2: Run orchestrator

```bash
./scripts/run-audit.sh manuscript/
# Produces manuscript/docs/audit/audit-$(date +%F).md
```

Exit codes: `0` clean / `1` ≥1 finding / `2` tool error.

### Step 3: Report format spec

Frozen per `manuscript-consistency-audit.md` §7:

```markdown
# Manuscript Consistency Audit — YYYY-MM-DD

**Manuscript snapshot**: <git rev-parse HEAD>
**Audit tool versions**: ...

## Summary
- Definite: N
- Likely: M
- Suspicious: K
- FYI: J

## Findings
### Definite
#### F1: <one-line>
- **Rule**: R1 / R2 / R3 / R4
- **Location**: `file:line`
- **Context**: ±2 lines
- **Proposed fix**: <suggestion>
- **Tracking issue**: #NNN (if filed)
```

### Step 4: Per-finding triage (AskUserQuestion when batch ≥ 10)

| Severity | Auto-action |
|----------|-------------|
| Definite + Likely | File `audit-finding` issue with `scope:manuscript` label (per `issue-routing.md`) |
| Suspicious | Audit report only, no issue |
| FYI | Audit report only |

**False-positive suppression** (per Pattern 7/8 in audit SOP):
- LaTeX `\label{}` / `\cite{}` / bib keys → auto-allowlist (v0.2 calibration: definite drops 86→18 after fix)
- Sibling `references/*.tex` → auto-discover
- Use `--latex-source-root <path>` for additional dirs

## Trigger Cadence

Per `manuscript-consistency-audit.md` §5:

| Stage | Trigger | Frequency |
|-------|---------|-----------|
| 大改稿後 | manual `./scripts/run-audit.sh manuscript/` | episode-based |
| 投稿前 | manual | episode-based |
| Per-PR (touches main.tex / analysis / refs.bib) | pre-commit hook | per-commit |
| Per-PR (any change) | GitHub Actions CI | per-PR |

## When NOT to Use

- Per-line edit → hook + R1-R8 validator faster
- Pure code-only PR (no manuscript change) → CI auto-skip via paths filter
- Pre-extraction phase (no propositions/main.jsonl) → R4 inactive but R1/R2/R3 still useful

## Cross-link

- Source: PsychQuantHsu/psychophysical_representations #42 (audit SOP), #78 (CI gate)
- Rule: [`../../rules/manuscript-consistency-audit.md`](../../rules/manuscript-consistency-audit.md) — full SOP
- Sister skill: `/math-tools:propositions` for in-file JSONL validation
- Sister skill: `/math-tools:proofread` for L4 semantic walk
