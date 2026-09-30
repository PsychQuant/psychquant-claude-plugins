## 1. Fixture and tests first

- [x] 1.1 Build the fixture project under `tests/lean-prover/fixtures/`: a graph JSON with `check: lean`, cards for one definition, three proved theorems (one whose premise is open), one open theorem and one unformalized theorem, and a small manuscript main file with an `\input` file containing the theorem environments. Verified by loading it in the tests.
- [x] 1.2 Write `tests/lean-prover/test_proved_manuscript.py` with one test per spec scenario (text graph refused; open and unformalized absent; newly proved card added; held-back card listed with its blocking premise; premise theorem first; label found gives the environment without proof; label missing gives the marked fallback; shared definition once; provenance line; two frontier layers separate; stale output detected). All fail at first (no script yet). Verified by running `python3 -m unittest` and seeing failures for every test.

## 2. Generator

- [x] 2.1 Implement graph loading, the `check == lean` gate and the inclusion and dependency-closure rules in `plugins/lean-prover/scripts/proved_manuscript.py`. Covers the requirements Graph edges name known cards, Only Lean-checked statuses count, Inclusion equals proved and Inclusion is dependency-closed. Verified by the tests for the gate, inclusion, closure and held-back reporting.
- [x] 2.2 Implement the manuscript reader (inline `\input`, find a label's enclosing environment, cut at the first proof) and the card-text fallback with escaping. Covers the requirements Statement source and Manuscript reading ignores comments. Verified by the label-found and label-missing tests.
- [x] 2.3 Implement ordering (topological with reading-order and id tie-breaks), the definitions section (each once) and the provenance lines. Covers the requirements Dependency order, Definitions used and Provenance per statement. Verified by the order, shared-definition and provenance tests.
- [x] 2.4 Implement the output shape from the design: the LaTeX writer (copied preamble, header with counts and the frontier pointer, reference handling) and the `FRONTIER.md` writer (two layers, held-back section, over-report note) and `--check`. Covers the requirements Frontier report, Reproducible output and check mode, and Symbols the text font lacks. Verified by the frontier and stale-output tests, and by compiling the fixture document with `xelatex` without errors.

## 3. Skill and plugin housekeeping

- [x] 3.1 Write the skill wrapper `plugins/lean-prover/skills/proved-manuscript/SKILL.md` covering package-root detection, library prefix from the lakefile, running `card-graph --lean` unless `--graph` is given, running the script, the cold-build warning, and the stop when `card-graph` is missing. Covers the requirement Skill drives the whole run. Verified by reading it against that requirement.
- [x] 3.2 Add the skill to the table in `plugins/lean-prover/CLAUDE.md`, add a `[1.2.0]` entry to `plugins/lean-prover/CHANGELOG.md`, and bump the version to 1.2.0 in `plugins/lean-prover/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`. Verified by comparing the three version strings.

## 4. Real run and review

- [x] 4.1 Run the generator on the fixed-points repository from a temporary output directory and compile the result with `xelatex`. Verified by the document containing exactly the proved theorem cards of that graph and compiling with no errors.
- [x] 4.2 Run the full test suite and `spectra validate`. Verified by both passing.
- [x] 4.3 Have a different model family review the script, the tests and the skill blind, and fix what it finds. Verified by a review record with no open blocking finding.
