---
name: propositions
description: |
  Extract atomic propositions from a math manuscript .tex file into a JSONL structural
  representation, and run the R1-R13 mechanical validator (validate-propositions.py) that
  checks the prop ↔ tex bijection: text-subset match, cite DAG, UUID v7 uniqueness,
  claim_type / evidence_class enums, and location line-range anchoring. Also fixes
  location-field drift after main.tex line shifts (refresh-prop-locations.py).

  Use when: starting a propositions side-file for a new manuscript, re-extracting after a
  large rewrite, running the mechanical gate before an audit or submission, or when the
  validator's R13 location-drift WARN spikes after editing main.tex. NOT for the L4 semantic
  walk (that is `/math-tools:proofread`) or cross-artifact drift (that is
  `/math-tools:manuscript-audit`).
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - AskUserQuestion
---

# Propositions — Extract + Validate + Refresh

A propositions JSONL is a structural side-file: each declarative unit of `main.tex` becomes
one atomic prop carrying `text` (verbatim), `location` (line range), `cites` (internal UUID
dependency DAG), `asserts` (atomic claims), `claim_type`, and `evidence_class`. This skill
owns the three **mechanical** operations on that file. The semantic question "does each cited
prop actually imply this one" is the sister skill `/math-tools:proofread`.

Full schema contract: [`../../docs/SCHEMA.md`](../../docs/SCHEMA.md).

## Resolve the bundled scripts

Every operation below runs a bundled script. Resolve the plugin root once:

```bash
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(ls -d "$HOME"/.claude/plugins/cache/psychquant-claude-plugins/math-tools/*/ 2>/dev/null | sort -V | tail -1)}"
VALIDATOR="$PLUGIN_ROOT/scripts/validate-propositions.py"
REFRESH="$PLUGIN_ROOT/scripts/refresh-prop-locations.py"
[ -f "$VALIDATOR" ] || { echo "validator not found under $PLUGIN_ROOT/scripts/"; exit 2; }
```

Then resolve the manuscript paths (from args, else the conventional layout — ask if absent):

```bash
JSONL="${1:-manuscript/propositions/main.jsonl}"
TEX="${2:-manuscript/main.tex}"
META="${3:-manuscript/propositions/_meta.json}"   # optional, schema v1.2+
[ -f "$JSONL" ] || { echo "JSONL not found at $JSONL — pass explicit path as arg 1"; exit 2; }
[ -f "$TEX" ]   || { echo "TeX not found at $TEX — pass explicit path as arg 2"; exit 2; }
```

## Operation A — Validate (R1-R13 mechanical gate)

The default operation. Run the validator; it prints per-rule PASS / WARN / FAIL.

```bash
if [ -f "$META" ]; then
  python3 "$VALIDATOR" --jsonl "$JSONL" --meta "$META" --tex "$TEX"
else
  python3 "$VALIDATOR" --jsonl "$JSONL" --tex "$TEX"
fi
```

Report by exit code:

| Validator output | Action |
|------------------|--------|
| `✓ ALL VALIDATION CHECKS PASSED` (exit 0) | report PASS, done |
| `[WARN]` lines only (exit 0) | report PASS with N informational warnings — list them |
| `[FAIL]` line (exit 1) | report FAIL; surface the failing rule + offending prop IDs, then triage below |
| crash / exit 2 | tool error — show stderr |

### R1-R13 coverage (the validator's contract)

| Rule | Invariant |
|------|-----------|
| R1 | `prop.text` ⊆ `main.tex` (normalize-aware substring match) |
| R1.5 | every top-level section has ≥1 prop (informational coverage WARN) |
| R2 | every `cites` UUID resolves to an existing prop |
| R3 | cite graph is a DAG — no cycles + orphan detection (structural leaves exempt) |
| R4 | mechanical-contradiction patterns (boundary-axiom + Track A/B) |
| R7 | every `id` is canonical UUID v7 (RFC 9562 §5.7; schema v1.2+) |
| R8 | `id` unique across the file |
| R9 | `containing_block` env boundaries match `location` line ranges |
| R10 | `connective` / `reference` claim_types have empty `asserts` |
| R11 | `evidence_class` in the 5-element canonical enum (schema v1.2+) |
| R12 | `claim_type` in the 12-element canonical enum (schema v1.2+) |
| R13 | single-line `location` anchors to the text's actual starting line |

`R3` being a DAG is structural, not logical: a valid DAG is not the same as "each edge is a
real implication" — that needs the L4 walk in `/math-tools:proofread`.

### Triage a FAIL → fix route

| Finding | Likely cause | Route |
|---------|--------------|-------|
| R1 fail (text drift) | wording changed in main.tex — update `prop.text` verbatim | inline edit (sync rule scenario 1) |
| R1 PASS but R13 stale | line shift only — run Operation B | refresh script |
| R2 dangling | a cited UUID was deleted — strip the dead cite | inline edit (scenario 4) |
| R3 cycle | circular dependency in a newly added prop | escalate — structural error |
| R4 pattern | boundary-axiom contradiction | escalate to an `audit-finding` issue |
| R7 / R8 / R10-R12 | schema violation | re-extract the affected section (Operation C) |

## Operation B — Refresh location drift

When R1 passes but R13 warns that N props' text sits outside their declared `location`
range (typical after adding/removing lines in main.tex). **Dry-run first — never write blind:**

```bash
python3 "$REFRESH" --jsonl "$JSONL" --tex "$TEX" --dry-run
```

The dry-run lists, per prop, `main.tex:L<old> → L<new>`, plus counts: `updated` (will change),
`R1 match failed` (text not in main.tex at all — refresh cannot help, fix R1 first), and
`anchor failed` (R1 passes but the windowed locator found no unique anchor — left untouched).

Show the dry-run output, then **AskUserQuestion** before writing:

> "Refresh will update M props' `location`. K are R1-fail (unfixable here), J are anchor-fail
> (left as-is). Apply?" → **apply** / **abort**

Only on explicit confirm:

```bash
python3 "$REFRESH" --jsonl "$JSONL" --tex "$TEX"   # idempotent — a second run reports 0 updated
```

Then re-run Operation A to confirm R13 dropped toward 0. The locator is windowed with a
degeneracy guard: if a prop's normalized text is not uniquely anchorable within `MAX_SPAN`, it
returns `anchor_failed` rather than guessing — any uncertainty is a loud failure, never a
silent mis-write. Residual un-anchorable props need to be split, or to use a range-form
`Lx-Ly` location.

## Operation C — Extract a new / re-extracted JSONL

When there is no JSONL yet, or a section was rewritten enough that re-extraction beats
patching. This is an LLM task, not a script: follow the extraction prompt at
[`../../docs/EXTRACTION-PROMPT.md`](../../docs/EXTRACTION-PROMPT.md) against the target
`.tex` (or a single section of it), emit the JSONL per `SCHEMA.md`, then immediately run
Operation A to gate the result. Extraction that has not passed the validator is not done.

## Exit codes (all scripts)

- `0` — all PASS (Operation A may include informational WARN)
- `1` — at least one rule FAILed (A), or at least one prop is R1-unfixable (B)
- `2` — usage / IO error (missing file, bad args)

## Cross-link

- `/math-tools:proofread` — the L4 semantic walk (does each cited prop *imply* this one)
- `/math-tools:manuscript-audit` — cross-artifact drift (R1-R4) across tex / jsonl / code / bib
- Rule [`../../rules/manuscript-jsonl-sync.md`](../../rules/manuscript-jsonl-sync.md) — per-commit sync discipline that prevents most R1/R13 drift
- Schema [`../../docs/SCHEMA.md`](../../docs/SCHEMA.md) · extraction [`../../docs/EXTRACTION-PROMPT.md`](../../docs/EXTRACTION-PROMPT.md)
