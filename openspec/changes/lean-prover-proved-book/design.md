## Context

The `lean-prover` plugin has a `status` skill that reports proof progress by grepping for `sorry`. It does not know theorem cards. Leanist-projects provides `card-graph --lean`, which prints JSON with keys `check`, `nodes`, `edges` and `frontier`: `check` is `lean` when the statuses were decided by building the library and collecting each declaration's axioms, and `text` otherwise. A node has `id`, `lean_name`, `shape` (theorem or definition), `status` (`unformalized`, `open`, `proved`, `defined`) and `title`. An edge has a `conclusion`, its `premises` (card ids) and the `proof_module`. A card YAML has `natural`, `lean`, and `expressions.manuscript` with `block` (a label) and `props` (ledger sentence ids). A prototype of the per-section view exists as `progress_view.py` in the fixed-points repository; this change generalises its reading of the graph and the manuscript's `\input` tree.

The author's decisions (kiki830621/iterated-correlation-fixed-points#24): only proved propositions, generated, added as proofs finish, in a plugin skill, showing the frontier.

## Goals / Non-Goals

**Goals:**

- A document that is exactly the Lean-proved part of a project, in dependency order, in the author's own wording.
- A frontier report that separates "stated but unproved" from "not yet stated".
- Output that is a pure function of its inputs, so it can be checked for staleness.

**Non-Goals:**

- No change to the card tooling in Leanist-projects.
- No proof text; no re-judging of proofs.
- No fix to the over-reporting frontier definition; the report states the caveat.

## Decisions

### Generator is a Python script bundled in the plugin

A single script `plugins/lean-prover/scripts/proved_manuscript.py`, standard library plus PyYAML (already required by the prototype), testable without Lean. Alternative: a `card-graph` subcommand in Swift inside Leanist-projects, which would keep the consumer next to the format. Rejected for now because it needs a Swift release and cannot be tested without building the Swift package; the script reads only the graph JSON, so moving it later is cheap.

### The Lean-checked graph is the only source of status

The script reads `check` and refuses `text`. It never scans `.lean` files itself. The skill produces the graph with `card-graph <root> --library <Prefix> --lean`, or accepts `--graph <file>` for a saved one.

### Inclusion rule and order

Included: theorem cards with `status = proved` for which at least one edge with that card as conclusion has every premise either `defined` or itself included (computed to a fixed point, so a theorem resting on a held-back theorem is held back too; the same "at least one proof module" reading the graph's own frontier uses). Excluded proved cards are kept for the report with the blocking premise. Order: a topological order of the included theorems over the edges, with ties broken by the position of the card's block label in the manuscript source read through `\input`, then by card id. A cycle cannot occur (the graph refuses cycles), and the script fails loudly if one is present.

### Statement extraction from the manuscript

The manuscript's main file is read with its `\input` files inlined (as the prototype does). For a card's `block`, find `\label{block}`, take the enclosing environment among `theorem`, `lemma`, `proposition`, `corollary`, `definition`, and cut at the first `\begin{proof}` if one is nested. If the label is absent or not inside such an environment, fall back to the card's `natural` text, escaped, and mark the entry `statement from card text`. Definitions use `natural` text always, because the ledger sentences of a definition can be fragments that do not stand alone (a sentence can end inside an `align`).

### Reading the manuscript

Comments are masked (blanked, offsets preserved) before any command is searched, so labels, environments, proofs and inputs are found only where they are active, and the statement text is cut from the original source at those offsets. The preamble is taken from the flattened source (inputs inlined), so a preamble supplied through an input is copied rather than re-referenced. A missing input file and an edge that names an unknown card are errors, not silent gaps.

### Output shape

- `PROVED_MANUSCRIPT.tex`: the source's preamble (everything before `\begin{document}`) copied unchanged so macros resolve, then a header with the counts and a pointer to the frontier report, a Definitions section, and one section per theorem with a provenance line (Lean name, card id, block label) and the statement.
- `FRONTIER.md`: sections "Stated in Lean, not yet proved" (the graph's `frontier` plus other open cards), "Not yet stated in Lean" (unformalized theorem cards, grouped by manuscript section), "Proved but held back" (with the blocking premise), and a note when a frontier card has no proof module.
- References inside a statement to labels that are not in the document print the label itself rather than `??`. `hyperref` redefines `\ref` when the document begins, so the wrapper is installed with `\AtBeginDocument` after the copied preamble; `\eqref` goes through it. Theorem and reference numbers are those of the generated document, and the header says so; each entry gives its manuscript label.
- Characters that common text fonts lack (double-struck letters, the transpose sign, superscript and subscript digits, the succeeds-or-equals signs) are set in math mode; blackboard letters become bold letters so that no extra package is needed.

### Check mode

`--check` regenerates in memory and compares with the files on disk; it exits 1 and names the stale file on a difference. No timestamps or absolute paths go into the output.

### Skill wrapper

`skills/proved-manuscript/SKILL.md` locates the Lake package root (directory with `lakefile.toml` and a `cards/` directory), derives the library prefix from the lakefile, runs `card-graph --lean` unless `--graph` is given, runs the script, and reports counts and paths. It states that a cold `--lean` run builds the whole library and can take a long time. If `card-graph` is missing it stops, and it never falls back to a text-level graph.

## Implementation Contract

- **Behavior:** `/lean-prover:proved-manuscript [package-root] [--graph file] [--out dir]` writes `PROVED_MANUSCRIPT.tex` and `FRONTIER.md` into the output directory (default: the package root) and prints the number of included theorems, of all theorem cards, and the two file paths.
- **Interface:** script `proved_manuscript.py --graph <file> --cards <dir> --manuscript <main.tex> --out <dir> [--check]`; graph JSON as printed by `card-graph`; card YAML as in Leanist-projects.
- **Failure modes:** `check` not `lean` → exit 2, nothing written. A card listed in the graph but missing on disk → exit 1 with the card id. Missing label → fallback entry, marked, not an error. Dependency cycle → exit 1 naming the cards. Stale output in `--check` → exit 1 naming the file.
- **Acceptance criteria:** the test suite in `tests/lean-prover/` passes on a fixture project that covers every scenario of the spec; a real run on the fixed-points repository produces a document that compiles with `xelatex` and contains exactly the graph's proved theorem cards (4 at the time of writing).
- **Scope boundaries:** in scope: the script, its tests and fixture, the skill, plugin docs, changelog and version. Out of scope: Leanist-projects, the fixed-points repository (the first committed run is a separate change there), publishing the plugin update after merge.

## Risks / Trade-offs

- With no theorem-to-theorem edges yet, the first document is a few unrelated results; the header says so.
- The graph's frontier over-reports while proof edges are absent; the report says so rather than hiding it.
- Copying the whole preamble brings in packages the extract does not need; harmless, but the compile time of a big preamble is paid for a small document.
- Redefining `\ref` interacts with `hyperref`; a compile test on the fixture pins the behavior (outside references print their label, no undefined-reference warning).
