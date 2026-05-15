---
name: proofread
description: |
  JSONL-driven 6-layer proofread workflow for math manuscript. Each prop in main.jsonl becomes
  a [ ] checklist item in manuscript/.proofread/<file>.md; walk through L1-L5 + location-drift
  per prop; mark [x] (CLEAN) / [~] (finding) / [-] (out of scope).

  L1 = text-claim match (asserts truly atomic + faithful paraphrase)
  L2 = claim_type fit (axiom non-derivable / definition has equality / commentary not derived / etc.)
  L3 = cite completeness (all external refs declared)
  L4 = cite validity (each cited prop logically implies this prop's asserts)
  L5 = evidence_class fit (derived needs cites / axiomatic truly axiom / etc.)
  +location drift (claimed line range matches main.tex actual)

  Use when: pre-submission final polish, post large rewrite, Hsu-approval-pending area,
  validating prop-extraction quality. NOT for daily micro-edit (use sync rule + validator).

  v0.1.0 SCAFFOLDING — execution body TODO. Methodology frozen in
  PsychQuantHsu/psychophysical_representations/manuscript/.proofread/main_jsonl_l4_walk.md.
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
  - AskUserQuestion
---

# Proofread — 6-Layer Walk

## Status (v0.1.0)

**Scaffolding only.** Methodology demonstrated + frozen at:

- `PsychQuantHsu/psychophysical_representations/manuscript/.proofread/main_jsonl.md` (637-line checklist source)
- `manuscript/.proofread/main_jsonl_l4_walk.md` (Pilot 3 full L4 walk ledger, 286-prop coverage)

3 pilots completed (#107):

| Pilot | Scope | Findings | Status |
|-------|-------|----------|--------|
| 1 | `_stage2/theorem1.jsonl` (23 props) | 13 location-drift | escalated → #106 closed |
| 2 | `main.jsonl` thm:eta-s (46 props) | 2 L3 + 2 COMPRESS + 1 mild L3 | all fixed in commit 9e85198 |
| 3 | Full `main.jsonl` (286 props, hybrid 115 deep + 20 sample + 151 heuristic) | 0 additional | ledger frozen |

## The 6 Layers

| Layer | Check | Detection difficulty |
|-------|-------|----------------------|
| L1 | prop.text真的 claim 出 asserts 列項? (atomic + faithful paraphrase) | Mostly mechanical via R1 substring match |
| L2 | claim_type matches text semantic? (axiom non-derivable / definition has equality / commentary not derived / restatement truly re-states / case_split truly partitions) | Semi-mechanical — heuristic on bullet pattern |
| L3 | All external refs in prop.text declared in cites field? | **LLM-required** — load-bearing reference detection is semantic |
| L4 | Does each cited prop logically imply this prop's asserts? (mathematical correctness given cites) | **LLM-required** — derivation chain verification |
| L5 | evidence_class consistent with claim_type? (derived needs cites; axiomatic truly axiom; verified has external proof) | Schema-aware heuristic + LLM judgment |
| location | location.line range matches actual main.tex line range | Mechanical via `scripts/refresh-prop-locations.py` |

## ROI Cliff (from Pilot 3 data)

- Proof body / derivation chain: **~2.6% finding rate** (3/115 deep walk)
- Theorems 2-4 + Synthesis: **0%** (0/20 sampled)
- Commentary / Discussion: **0% mechanical anomalies** (0/151 heuristic)

→ **Hybrid coverage strategy**: deep walk proof body + sample mid-density sections + heuristic scan commentary.

## Execution Steps (v0.2.0 target — TODO)

### Step 0: Bootstrap Stage Task List

```
TaskCreate generate_checklist_md / decide_coverage_strategy /
            per_prop_walk (L1-L5+location) / classify_finding /
            update_ledger / decide_escalation (audit-finding issue / inline note / camera-ready candidate) /
            commit_with_jsonl_sync
```

### Step 1: Generate `.proofread/<file>.md` checklist from JSONL

For each prop, emit:
```markdown
- [ ] **P{seq}** `{uuid_short}` [{claim_type}] @L{start}-L{end} — "{first 80 chars of text}..." (asserts: {N}, cites: {N})
```

Group by `containing_block` field. Add hyperlink to git blame for audit trail.

### Step 2: Coverage decision (AskUserQuestion 4-option)

| Strategy | Use case | Time |
|----------|----------|------|
| By section (e.g. Theorem 1 ~40 props) | Section-cohesive review | 20-30 min |
| By claim_type | Foundational props first | variable |
| By priority area (recent-change cluster) | Post-PR follow-up | 25-40 min |
| Full manuscript (~2-3h) | Pre-submission gate | 2-3h |

### Step 3: Per-prop L4 walk

For each prop, present:
- prop.text (raw)
- prop.asserts (atomic list)
- prop.cites (UUID list — resolve each via main.jsonl lookup)
- prop.claim_type / evidence_class

Ask coordinator to verify:
- L1: do asserts faithfully decompose text?
- L2: does claim_type fit?
- L3: is anything cited in text but not in cites field?
- L4: does each cited prop's asserts logically imply this prop's asserts?
- L5: is evidence_class consistent?
- location: spot-check main.tex line N — does prop.text start there?

Mark `[x]` (CLEAN all 6), `[~]` (finding noted, detail in § Findings), `[-]` (out of scope).

### Step 4: Findings ledger

Hybrid mode: inline § Findings table in `.proofread/*.md` for severity < L3-blocking; escalate severity ≥ L3 cite-completeness OR ≥ 10 props affected to separate `audit-finding` GitHub issue (per `code-and-manuscript-sync.md` cluster discipline).

### Step 5: Fix-shipping (if findings)

Per `manuscript-jsonl-sync.md` scenario routing:
- L1/L3 cite-completeness → scenario 6 (jsonl-only edit, add UUID)
- L2 misclassification → fix prop.claim_type + re-validate R6
- L4 COMPRESS (camera-ready candidate) → scenario 1 (wording expand in main.tex) + scenario 2 (prop.text sync)
- L5 mismatch → fix evidence_class + verify schema

Coordinator commits with cross-link to .proofread ledger entry.

## When NOT to Use

- Daily micro-edit → use R1-R8 validator + sync rule (cheaper)
- Pre-extraction phase (jsonl doesn't exist yet) → run `propositions` skill first
- Commentary-only sections → heuristic scan is enough; deep walk ROI low

## Cross-link

- Source dogfood: PsychQuantHsu/psychophysical_representations #107 (3 pilots done)
- Rule: [`../../rules/manuscript-jsonl-sync.md`](../../rules/manuscript-jsonl-sync.md) — sync discipline after L3/L4 fix
- Sister skill: `/math-tools:propositions` for mechanical R1-R8 gate
- Sister skill: `/math-tools:manuscript-audit` for cross-doc R1-R4 drift
