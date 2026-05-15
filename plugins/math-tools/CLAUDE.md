# math-tools — CLAUDE.md

## Purpose

Academic math article editing — propositions extraction + R1-R8 mechanical validation, JSONL-driven 6-layer proofread workflow, R1-R4 cross-doc audit gate, and 3 frozen sync rules. Dogfood origin: `PsychQuantHsu/psychophysical_representations` #107 proofread workflow experiment (3 pilots, 286-prop full L4 walk demonstrated).

## Skills

| Skill | 用途 |
|-------|------|
| `/math-tools:propositions` | Extract atomic props from .tex → JSONL + run R1-R8 mechanical gate (v0.1.0 scaffolding, scripts in source repo) |
| `/math-tools:proofread` | JSONL-driven 6-layer L1-L5 + location-drift per-prop walk;produces `.proofread/<file>.md` checklist (v0.1.0 scaffolding) |
| `/math-tools:manuscript-audit` | Cross-doc R1-R4 drift detection (working-file path leak, cite drift, code-manuscript symbol drift, prop-iso bijection) (v0.1.0 scaffolding) |

## Rules (auto-injected when `.tex` files present)

| Rule | What it enforces |
|------|------------------|
| `manuscript-jsonl-sync.md` | Prop-level main.tex ↔ JSONL sync HARD RULE (6 scenarios) |
| `manuscript-consistency-audit.md` | Audit-time R1-R4 SOP + PR-side CI gate enforcement |
| `code-and-manuscript-sync.md` | Repo-level cluster PR scope discipline (manuscript submodule + upper repo paired commits) |

## v0.1.0 limitations

Skill execution bodies are SCAFFOLDING ONLY. Source-of-truth lives in `PsychQuantHsu/psychophysical_representations` until iteration extracts:

- `scripts/validate-propositions.py` (R1-R8 mechanical gate)
- `scripts/refresh-prop-locations.py` (location-drift one-shot fix)
- `scripts/audit-symbols.py` / `audit-citations.py` / `audit-code-manuscript.py`
- `scripts/run-audit.sh` (orchestrator)
- `.github/workflows/manuscript-audit.yml` (CI template)

If you install this plugin in another math-article repo today, **most skill commands won't execute** — they describe methodology and point to the source repo. Treat as documentation + rules-loading until v0.2.0.

## Development

- Plugin structure: see [psychquant-claude-plugins doc-tools](../doc-tools/) for layout reference
- Update after changes: `/plugin-tools:plugin-update math-tools`
- Health check: `/plugin-tools:plugin-health`
- First dogfood: this session's `#107` workflow itself (psychophysic_representations was the testbed)

## Roadmap (v0.2.0+ targets)

| Item | Status |
|------|--------|
| Extract `scripts/validate-propositions.py` into plugin | TODO |
| Extract `scripts/refresh-prop-locations.py` into plugin | TODO |
| Extract `scripts/audit-*.py` + `run-audit.sh` into plugin | TODO |
| Per-project config `.claude/math-tools.json` for path parameterization | TODO |
| Generalize rules (remove source-repo-specific refs) | TODO |
| Skill execution bodies (replace SCAFFOLDING with working logic) | TODO |
| First external dogfood (different math article repo) | TODO |

## Cross-link

- Source dogfood: PsychQuantHsu/psychophysical_representations
  - #42 audit SOP
  - #78 CI gate
  - #106 location drift
  - #107 proofread workflow experiment (closing summary contains full methodology annotation)
- Sister plugins:
  - `docflow` for multi-version document semantic synthesis (different concept space — version merge, not single-version audit)
  - `doc-tools` for software-doc lifecycle (CHANGELOG / README — not academic articles)
  - `perspective-writer` for prose voice simulation (not math)
