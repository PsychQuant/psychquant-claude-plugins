---
name: propositions
description: |
  Extract atomic propositions from a math manuscript .tex file into a JSONL structural representation,
  then run R1-R8 mechanical validation. Each prop carries text (verbatim from .tex), location (line range),
  cites (internal UUID dependency DAG), asserts (atomic claims), claim_type, and evidence_class.

  Use when: starting propositions side-file for a new manuscript, re-extracting after large rewrite,
  or running mechanical gate before audit. NOT for L4 semantic walk — that's the /proofread skill.

  v0.1.0 SCAFFOLDING — execution body TODO. Source-of-truth scripts currently in
  PsychQuantHsu/psychophysical_representations/scripts/validate-propositions.py.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - AskUserQuestion
---

# Propositions — Extract + Validate

## Status (v0.1.0)

**Scaffolding only.** Execution body deferred to v0.2.0+. Until then, run the source-of-truth scripts directly:

```bash
# Validate (R1-R8 mechanical gate)
python3 scripts/validate-propositions.py \
  --jsonl manuscript/propositions/main.jsonl \
  --meta manuscript/propositions/_meta.json \
  --tex manuscript/main.tex
# Exit 0 = all pass; exit 1 = at least one rule fail

# Refresh location field after main.tex line shift
python3 scripts/refresh-prop-locations.py --jsonl manuscript/propositions/main.jsonl
```

Both scripts live at `PsychQuantHsu/psychophysical_representations/scripts/` (will be extracted to this plugin in v0.2.0).

## R1-R8 Coverage (frozen contract)

| Rule | What it checks | False-negative pitfall |
|------|----------------|------------------------|
| R1 | prop.text verbatim found in main.tex (via `normalize_for_match`) | substring containment is line-anchor-blind → location-drift silent (use R9-pending or refresh script) |
| R1.5 | surjective coverage — every .tex paragraph covered by ≥1 prop | informational, not blocking; WARN-only |
| R2 | every cite UUID resolves to an existing prop | catches typo / deletion gaps |
| R3 | cite graph is a DAG (no cycles) | structural, not semantic — DAG ≠ logical implication (L4 walk needed) |
| R4 | mechanical-contradiction PATTERN-A/B | catches boundary-axiom violations like #60 #68 |
| R6 | sentence/clause-index v1.1 invariants hold | catches granularity drift |
| R7 | every prop.id is canonical UUID v7 (RFC 9562 §5.7) | gates id-format compliance |
| R8 | unique-ids within file | catches paste-clone errors |

## Execution Steps (v0.2.0 target — TODO)

### Step 0: Bootstrap Stage Task List

```
TaskCreate parse_args / detect_jsonl_path / run_validator / parse_exit_code /
            classify_finding / decide_fix_path (refresh-locations / re-extract /
            split-prop / escalate-issue) / write_audit_summary
```

### Step 1: Resolve manuscript root + JSONL paths

Walk up from `cwd` to find `manuscript/propositions/main.jsonl` (canonical) + optional `_stage2/*.jsonl` (staging area like Theorem 1 in source repo).

### Step 2: Run validator, parse output

(TODO: structured-output mode for validate-propositions.py — feature request once script extracted)

### Step 3: Triage findings → AskUserQuestion routing

| Finding | Likely fix | Route |
|---------|------------|-------|
| R1 fail (text drift) | manuscript-jsonl-sync.md scenario 1 (wording) — update prop.text verbatim | inline edit |
| R1 PASS but location stale | scenario 2 (line shift) — refresh-prop-locations.py | one-shot script |
| R2 dangling | scenario 4 (delete) — strip cites referencing deleted UUIDs | inline edit |
| R3 cycle | structural error — likely circular dependency in newly-added prop | escalate |
| R4 PATTERN-A | boundary-axiom contradiction | escalate to audit-finding issue |
| R6 / R7 / R8 | schema violation — re-run EXTRACTION-PROMPT.md against affected section | re-extract |

## Cross-link

- Source dogfood: PsychQuantHsu/psychophysical_representations #107 (proofread workflow experiment, 3 pilots)
- Rule: [`../../rules/manuscript-jsonl-sync.md`](../../rules/manuscript-jsonl-sync.md) — prop-level sync HARD RULE
- Sister skill: `/math-tools:proofread` for L4 alignment walk (semantic, not mechanical)
- Sister skill: `/math-tools:manuscript-audit` for R1-R4 cross-doc drift detection
