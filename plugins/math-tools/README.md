# math-tools

> Academic math article editing — propositions extraction, JSONL-driven proofread workflow, cross-doc audit gates, sync rules.

## What it does (v0.1.0)

Bundles 3 skills + 3 frozen baseline rules for the workflow demonstrated in `PsychQuantHsu/psychophysical_representations` issue #107:

- **Mechanical gate** (`/math-tools:propositions`) — R1-R8 on `manuscript/propositions/main.jsonl` (verbatim, cite DAG, UUID v7, unique IDs, sentence/clause index)
- **Semantic walk** (`/math-tools:proofread`) — 6-layer L1-L5 + location-drift per-prop checklist with hybrid coverage strategy (deep walk proof body + sample mid-density + heuristic scan commentary)
- **Cross-doc audit** (`/math-tools:manuscript-audit`) — R1-R4 SOP catching working-file path leaks, cite drift, code-manuscript symbol drift, prop-iso bijection failures
- **3 rules** — auto-loaded to enforce edit-time + audit-time + repo-level sync discipline

## v0.1.0 scope

**Scaffolding release.** Skill bodies + scripts live in the source repo until iteration extracts. Install today to get rules + methodology docs; expect v0.2.0 for working skill execution.

## Why ship it now

Per closing summary of #107:

> 3 pilots 累積足夠 UX data,下次值得 build skill。已標 [-] deferred。

This release captures the working methodology while fresh. Generalization (path parameterization, script extraction, external repo dogfood) comes after.

## Install

```bash
claude plugin marketplace add PsychQuant/psychquant-claude-plugins
claude plugin install math-tools@psychquant-claude-plugins
```

## Sister plugins

- `docflow` — multi-version document semantic synthesis (different concept space)
- `doc-tools` — software-doc lifecycle (CHANGELOG / README)
- `perspective-writer` — prose voice simulation
- `lean-prover` — Lean 4 automated proof grinding (different math area)

None of these cover **academic math article editing + audit** as a coherent workflow — that's the gap `math-tools` fills.

## License

See [LICENSE](LICENSE) (TBD — match parent marketplace).
