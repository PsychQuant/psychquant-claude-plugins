## Why

Research repositories that use theorem cards (a YAML card per formal statement, Leanist-projects) can already say which statements Lean has proved (`card-graph --lean`), but nothing reads that verified part as one document. A reader has to open cards or a progress table and cross-reference the manuscript by hand. The author decided (2026-09-30, kiki830621/iterated-correlation-fixed-points#24) that the integrated document contains only propositions whose Lean proof is complete, is generated rather than written, is added to as proofs finish, and shows where the proof frontier is.

## What Changes

- New skill `/lean-prover:proved-manuscript` in the `lean-prover` plugin. It runs `card-graph --lean` (or takes a saved graph), then a generator script builds two files: a LaTeX document of the proved propositions and a frontier report.
- New script `plugins/lean-prover/scripts/proved_manuscript.py`, a pure function of the graph JSON, the cards and the manuscript source, with a test suite on a small fixture project.
- The document contains exactly the theorem cards whose status is `proved` in a Lean-checked graph and whose premises are all defined or proved, plus the definitions they use, in dependency order. Each statement is the manuscript's own theorem environment, found by the card's `block` label.
- The frontier report is a separate file linked from the document header. It lists two layers: statements that exist in Lean but are not proved, and statements that have no Lean statement yet.
- `lean-prover` plugin docs, changelog and version are updated (1.1.0 to 1.2.0).

## Non-Goals

- No change to the card format, `card-graph`, `card-gen` or `card-validate` (Leanist-projects).
- No proof text in the document: each statement points to its Lean declaration.
- No judgment about proofs: status comes from the Lean-checked graph as it is.
- No fix to `card-graph`'s frontier definition, which over-reports while there are no theorem-to-theorem proof edges; the report states this instead.
- No committing of generated output in this change; the first run on the fixed-points repository is a separate change there.

## Capabilities

### New Capabilities

- `proved-manuscript-generation`: builds the proved-only document and the frontier report from a Lean-checked card graph, and the skill that drives it.

### Modified Capabilities

(none)

## Impact

- Affected specs: `proved-manuscript-generation` (new).
- Affected code:
  - New: `plugins/lean-prover/skills/proved-manuscript/SKILL.md`
  - New: `plugins/lean-prover/scripts/proved_manuscript.py`
  - New: `tests/lean-prover/test_proved_manuscript.py`
  - New: `tests/lean-prover/fixtures/` (graph JSON, cards, a small manuscript)
  - Modified: `plugins/lean-prover/CLAUDE.md`
  - Modified: `plugins/lean-prover/CHANGELOG.md`
  - Modified: `plugins/lean-prover/.claude-plugin/plugin.json`
  - Modified: `.claude-plugin/marketplace.json`
