# math-tools

> Academic math article editing — propositions extraction & validation, JSONL-driven proofread walk, cross-doc audit gates, free-form clarity audit, and sync rules.

## What it does (v0.4.0)

Four skills + three frozen baseline rules + a bundled toolchain (scripts & docs), covering a math manuscript along four axes:

| Skill | Axis | What it does |
|-------|------|--------------|
| `/math-tools:propositions` | mechanical | Run the **R1-R13** validator (`validate-propositions.py`) on `manuscript/propositions/main.jsonl` — prop↔tex subset match, cite DAG, UUID v7 uniqueness, claim_type / evidence_class enums, location anchoring. Also **refresh location drift** (`refresh-prop-locations.py`, dry-run gated) and **extract** a new JSONL (via `docs/EXTRACTION-PROMPT.md`). |
| `/math-tools:proofread` | semantic | 6-layer **L1-L5 + location** per-proposition walk (faithful decomposition, claim_type fit, cite completeness, cite validity, evidence_class), with a hybrid coverage strategy — deep-walk proof bodies, sample mid-density sections, heuristic-scan commentary. |
| `/math-tools:manuscript-audit` | cross-artifact | **R1-R4** SOP (`run-audit.sh`) catching working-file path leaks, cite / bib drift, code↔manuscript symbol drift, and prop-iso bijection failures across `main.tex` + `propositions/*.jsonl` + `analysis/*.py` + `refs.bib`. |
| `/math-tools:clarity-audit` | readability | Free-form: find where a **human reader stalls** in a passage (unanchored term / missing bridge, definition-away-from-use, claim-without-reason, notation collision, non-standard terminology) and rewrite it self-contained. Works at any scale, from a single quoted sentence up to a section. |

The correctness axes (propositions / proofread / manuscript-audit) answer "is it right / consistent"; clarity-audit answers "can a reader follow it" — a passage can pass proofread and still be unreadable.

**Three rules** auto-load to enforce edit-time + audit-time + repo-level sync discipline: `manuscript-jsonl-sync`, `manuscript-consistency-audit`, `code-and-manuscript-sync`.

## Bundled toolchain (self-contained since v0.3.0)

The scripts and schema live inside the plugin — no external source-repo dependency. Skills resolve them via `${CLAUDE_PLUGIN_ROOT}`.

```
scripts/  validate-propositions.py (R1-R13)   refresh-prop-locations.py
          audit-symbols.py  audit-citations.py  audit-code-manuscript.py
          run-audit.sh (R1-R4 orchestrator)     _lib/latex_env_parser.py
docs/     SCHEMA.md            (the propositions JSONL schema contract)
          EXTRACTION-PROMPT.md (the extraction flow for a new JSONL)
```

## Install

```bash
claude plugin marketplace add PsychQuant/psychquant-claude-plugins
claude plugin install math-tools@psychquant-claude-plugins
```

Restart Claude Code (or start a new session) after install so the skills load.

## Version history

- **v0.4.0** — sharpen the `clarity-audit` trigger description (explicit single-sentence scope + anti-under-trigger nudge).
- **v0.3.0** — flesh out the `propositions` / `proofread` / `manuscript-audit` skeletons into self-contained execution bodies; bundle the toolchain (scripts + docs) into the plugin, dropping the source-repo dependency.
- **v0.2.0** — add the `clarity-audit` skill (the readability axis).
- **v0.1.0** — scaffolding release: 3 skeleton skills + 3 frozen baseline rules + methodology docs; skill bodies and scripts still lived in the source repo. Origin: the proofread workflow demonstrated in `PsychQuantHsu/psychophysical_representations` #107 (3 pilots, 286-prop full L4 walk).

## Sister plugins

- `docflow` — multi-version document semantic synthesis (different concept space)
- `doc-tools` — software-doc lifecycle (CHANGELOG / README)
- `perspective-writer` — prose voice simulation
- `lean-prover` — Lean 4 automated proof grinding (different math area)

None of these cover **academic math article editing + audit** as a coherent workflow — that's the gap `math-tools` fills.

## License

See [LICENSE](LICENSE) (TBD — match parent marketplace).
