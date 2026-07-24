---
name: proofread
description: >-
  JSONL-driven 6-layer per-proposition walk (L1-L5 + location): faithful decomposition, claim_type fit, cite completeness, cite validity, evidence_class consistency. Use for pre-submission polish, after a large rewrite, or to validate prop-extraction quality. The semantic-correctness axis (does each cited prop actually imply this one) — distinct from /math-tools:propositions (mechanical R1-R13 gate) and /math-tools:manuscript-audit (cross-artifact drift). Not for daily micro-edits (use the validator + sync rule).
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

Where `/math-tools:propositions` asks "is the JSONL mechanically well-formed", this skill asks
the semantic question a machine cannot: **is each claim true, faithfully stated, and actually
implied by what it cites.** It is a guided per-proposition walk, not a script — the value is
the human/LLM judgment at each layer.

## The 6 layers

| Layer | Check | Difficulty |
|-------|-------|------------|
| L1 | Does `prop.text` truly claim the listed `asserts`? (atomic + faithful paraphrase) | mostly mechanical (the R1 substring match backs it) |
| L2 | Does `claim_type` match the text's semantics? (axiom non-derivable / definition has equality / commentary not derived / restatement truly re-states / case_split truly partitions) | semi-mechanical heuristic |
| L3 | Is everything cited in `prop.text` declared in the `cites` field? | **LLM-required** — load-bearing reference detection is semantic |
| L4 | Does each cited prop's asserts *logically imply* this prop's asserts? | **LLM-required** — derivation-chain verification |
| L5 | Is `evidence_class` consistent with `claim_type`? (derived needs cites; axiomatic truly an axiom; verified has an external proof) | schema-aware heuristic + judgment |
| location | Does `location.line` match the actual main.tex line range? | mechanical — the R13 check in the validator |

L1, L2, and location are backed by the bundled `/math-tools:propositions` validator (R1-R13);
run it first so this walk can focus on L3/L4/L5, which no script can decide.

## ROI: where findings actually hide

From the dogfood pilots (below), finding density is very uneven, so coverage should be uneven too:

- Proof bodies / derivation chains: **~2.6%** finding rate (3 / 115 deep-walked props) — deep-walk these.
- Theorems 2-4 + Synthesis: **0%** (0 / 20 sampled) — sample.
- Commentary / Discussion: **0%** mechanical anomalies (0 / 151 heuristic) — heuristic scan only.

→ **Hybrid coverage**: deep-walk proof bodies, sample mid-density sections, heuristic-scan commentary. A uniform full walk spends most of its time at 0% yield.

## Procedure

### Step 0: Prerequisite — pass the mechanical gate first

```
/math-tools:propositions   # R1-R13 must be green (or WARN-only) before walking
```

A walk on a JSONL that fails R1/R7/R8 wastes effort — fix mechanical drift first.

### Step 1: Generate the `.proofread/<file>.md` checklist from the JSONL

For each prop in `manuscript/propositions/main.jsonl`, emit one line, grouped by
`containing_block`:

```markdown
- [ ] **P{seq}** `{uuid_short}` [{claim_type}] @L{start}-L{end} — "{first 80 chars of text}…" (asserts: {N}, cites: {N})
```

Add a git-blame hyperlink per line for the audit trail.

### Step 2: Decide coverage (AskUserQuestion, 4 options)

| Strategy | Use case | Time |
|----------|----------|------|
| By section (e.g. Theorem 1, ~40 props) | section-cohesive review | 20-30 min |
| By claim_type | foundational props first | variable |
| By priority area (recent-change cluster) | post-PR follow-up | 25-40 min |
| Full manuscript | pre-submission gate | 2-3 h |

Default toward the hybrid ROI strategy above rather than a flat full walk.

### Step 3: Per-prop walk

For each prop, present `prop.text` (raw), `prop.asserts` (atomic list), `prop.cites` (resolve
each UUID via a main.jsonl lookup), and `claim_type` / `evidence_class`. Verify:

- L1 — do the asserts faithfully decompose the text?
- L2 — does claim_type fit?
- L3 — is anything cited *in the text* but missing from the `cites` field?
- L4 — does each cited prop's asserts logically imply this prop's asserts?
- L5 — is evidence_class consistent?
- location — spot-check main.tex line N: does prop.text start there?

Mark `[x]` (CLEAN on all six), `[~]` (finding — detail in the § Findings ledger), or `[-]`
(out of scope).

### Step 4: Findings ledger

Keep an inline § Findings table in `.proofread/<file>.md` for anything below L3-blocking
severity. Escalate to a separate `audit-finding` GitHub issue when severity ≥ L3
cite-completeness OR ≥ 10 props are affected (per the `code-and-manuscript-sync.md` cluster
discipline).

### Step 5: Ship fixes

Route each finding through `manuscript-jsonl-sync.md`:

- L1 / L3 cite-completeness → jsonl-only edit (add the missing UUID)
- L2 misclassification → fix `prop.claim_type`, then re-validate
- L4 "COMPRESS" (a camera-ready candidate: the prose is terser than the claim) → expand wording in main.tex, then sync `prop.text`
- L5 mismatch → fix `evidence_class`, verify against the schema

Commit with a cross-link to the `.proofread` ledger entry.

## When NOT to use

- Daily micro-edit → the R1-R13 validator + sync rule is cheaper
- Pre-extraction phase (no JSONL yet) → run `/math-tools:propositions` (Operation C) first
- Commentary-only sections → a heuristic scan suffices; deep-walk ROI is ~0%

## Provenance

Methodology validated on `psychophysical_representations` #107 — 3 pilots: (1) a 23-prop
theorem file surfaced 13 location-drift findings (escalated + closed); (2) a 46-prop theorem
surfaced 2 cite-completeness + 2 compress findings (all fixed); (3) a full 286-prop walk
(hybrid: 115 deep + 20 sample + 151 heuristic) surfaced 0 additional — the ledger that froze
the ROI numbers above.

## Cross-link

- `/math-tools:propositions` — the mechanical R1-R13 gate this walk assumes has passed
- `/math-tools:manuscript-audit` — cross-doc R1-R4 drift
- Rule [`../../rules/manuscript-jsonl-sync.md`](../../rules/manuscript-jsonl-sync.md) — sync discipline for L1/L3/L4 fixes
