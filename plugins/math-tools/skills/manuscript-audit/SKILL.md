---
name: manuscript-audit
description: |
  Audit-time cross-doc drift detection for a math manuscript. Runs the bundled orchestrator
  run-audit.sh over four passes: R1 (working-file path leak in \texttt{}), R2 (citation-key
  drift / bib orphan / cite-label leak), R3 (code-symbol drift between analysis/ and
  manuscript/docs/), and R4 (proposition-jsonl iso-bijection, auto-skipped when there is no
  propositions/main.jsonl). It checks the **cross-artifact consistency** among
  manuscript/main.tex + propositions/*.jsonl + analysis/*.py + references/*.tex + refs.bib —
  a different axis from `/math-tools:propositions` (R1-R13 gate on the JSONL alone) and
  `/math-tools:proofread` (per-prop L4 semantic walk).

  Use when: after a large rewrite, before submission, or entering a new stage (initial
  submission / major revision / camera-ready). NOT per-PR — that is a pre-commit hook + CI
  gate in the manuscript repo, per the `code-and-manuscript-sync.md` rule.
allowed-tools:
  - Read
  - Write
  - Bash
  - Grep
  - Glob
  - AskUserQuestion
---

# Manuscript Audit — Cross-Doc Drift Detection

Full SOP (triggers, known patterns, report contract):
[`../../rules/manuscript-consistency-audit.md`](../../rules/manuscript-consistency-audit.md).

## Resolve the bundled orchestrator

```bash
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(ls -d "$HOME"/.claude/plugins/cache/psychquant-claude-plugins/math-tools/*/ 2>/dev/null | sort -V | tail -1)}"
RUNNER="$PLUGIN_ROOT/scripts/run-audit.sh"
[ -f "$RUNNER" ] || { echo "run-audit.sh not found under $PLUGIN_ROOT/scripts/"; exit 2; }

MANUSCRIPT_ROOT="${1:-manuscript/}"      # dir holding main.tex + propositions/, not a single file
[ -d "$MANUSCRIPT_ROOT" ] || { echo "manuscript root not found at $MANUSCRIPT_ROOT — pass as arg 1"; exit 2; }
```

## R1-R4 coverage (frozen contract)

| Rule | Detects | Auto-allowlist |
|------|---------|----------------|
| **R1** symbols | `\texttt{path/to/working/file.ext}` working-file leak in main.tex; `note (<date>).tex` working-note refs | `\bibliography{refs.bib}`, commented `% …` lines |
| **R2** citations | `\cite{X}` where X not in refs.bib; cite-label leak (`\citet[Theorem~\texttt{main_thm_ess}]{Foo2020}` citing an internal LaTeX label as if it were a published theorem number); bib orphans | `@article{X,…}` keys auto-scanned; sibling working notes via `--latex-source-root` |
| **R3** code↔manuscript | backtick code refs `` `foo_func` `` in `manuscript/docs/*.md` not found in `analysis/*.py` AST | LaTeX `\label{}` / `\cite{}` keys, `@article` bib keys, sibling `references/**/*.tex` |
| **R4** proposition-iso | prop-jsonl bijection failure (feeds the R1-R13 validator; PATTERN-A boundary-axiom contradiction) | active only when `propositions/main.jsonl` exists; legacy `main.json` accepted as fallback |

R1/R2/R4 are blocking (they gate the PR CI in the manuscript repo); R3 is informational.

## Excluded paths (frozen audit trail — never modified retroactively)

- `manuscript/docs/rounds/` — review-round audit log
- `manuscript/docs/legacy/` — retired drafts
- `correspondence/` — email archive
- `references/*.tex` — historical reference papers
- `archive/` / `archived/` (also guarded by the archive-first plugin)

## Procedure

### Step 1: Pre-flight — clean working tree

Concurrent editing races produce phantom drift. Confirm the tree is clean first:

```bash
( cd "$MANUSCRIPT_ROOT" && git status --short )     # expect empty
( cd "$MANUSCRIPT_ROOT" && git submodule status )   # manuscript pointer correct
```

If dirty, ask whether to commit/stash before running.

### Step 2: Run the orchestrator

```bash
bash "$RUNNER" "$MANUSCRIPT_ROOT"                  # R3 defaults --code-root to analysis/
# If code lives elsewhere:   bash "$RUNNER" "$MANUSCRIPT_ROOT" --code-root path/to/code
```

`run-audit.sh` runs R1+R2+R3+R4 in order, writes a merged report to
`$MANUSCRIPT_ROOT/docs/audit/audit-YYYY-MM-DD.md`, and exits `0` clean / `1` ≥1 finding /
`2` tool error. Note: R3 requires the `--code-root` directory to exist (default `analysis/`);
a manuscript with no code should point `--code-root` at an existing dir or expect exit 2 from
that pass.

### Step 3: Review findings

Read `$MANUSCRIPT_ROOT/docs/audit/audit-YYYY-MM-DD.md`:

- **Definite / Likely** → must fix, or make a conscious decision not to and record why
- **Suspicious / FYI** → review; most are ignorable

### Step 4: Per-finding triage (AskUserQuestion when the batch ≥ 10)

| Severity | Action |
|----------|--------|
| Definite + Likely | file an `audit-finding` issue (`scope:manuscript` label) in the manuscript repo |
| Suspicious | audit report only, no issue |
| FYI | audit report only |

False-positive suppression (per the SOP): LaTeX `\label{}` / `\cite{}` / bib keys and sibling
`references/*.tex` are auto-allowlisted; add more dirs with `--latex-source-root <path>`.

## Report format (frozen, per SOP §7)

The orchestrator emits a dated report headed by the manuscript git snapshot and per-pass exit
codes, a Summary table (Definite / Likely / Suspicious / FYI counts across R1-R3, plus R4
error/warning counts), then the full per-pass findings. Each Definite/Likely finding carries
Rule, `file:line` location, ±2 lines of context, a proposed fix, and a tracking-issue number
if filed.

## Trigger cadence

| Stage | Trigger | Frequency |
|-------|---------|-----------|
| after a large rewrite | manual `bash run-audit.sh manuscript/` | episode-based |
| before submission | manual | episode-based |
| per-PR touching main.tex / analysis / refs.bib | pre-commit hook (manuscript repo) | per-commit |
| per-PR, any change | GitHub Actions CI (manuscript repo) | per-PR |

The hook and CI layers live in the manuscript repo (not this plugin); this skill is the
manual full-audit entry point that the same `run-audit.sh` backs.

## When NOT to use

- Per-line edit → the `/math-tools:propositions` R1-R13 validator + sync rule is faster
- Pure code-only change (no manuscript edit) → CI auto-skips via a paths filter
- Pre-extraction phase (no `propositions/main.jsonl`) → R4 auto-skips, but R1/R2/R3 still useful

## Cross-link

- `/math-tools:propositions` — in-file JSONL R1-R13 validation (R4 here reuses that validator)
- `/math-tools:proofread` — per-prop L4 semantic walk
- Rule [`../../rules/manuscript-consistency-audit.md`](../../rules/manuscript-consistency-audit.md) — full SOP
- Rule [`../../rules/code-and-manuscript-sync.md`](../../rules/code-and-manuscript-sync.md) — the per-PR hook/CI discipline this complements
