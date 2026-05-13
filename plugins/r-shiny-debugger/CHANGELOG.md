# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> ⚠ This file was bootstrapped by `changelog-tools:changelog-init` from the
> `plugin.json` description field. Section categorization is best-effort —
> review and refine `Added` / `Changed` / `Fixed` etc. as needed.

## [Unreleased]

## [1.2.0] - 2026-05-13

### Changed
- **BREAKING**: Default discovery browser for `/shiny-adaptive-walk` is now `agent-browser` (headless Chromium) instead of `safari-browser`. Existing invocations without `--browser` flag now run headless. Pass `--browser safari` (or set `SHINY_ADAPTIVE_BROWSER=safari`) to preserve the previous visible-Safari behavior. Rationale: both engines render real DOM; safari's only unique value is live visibility, which costs nothing to opt into when needed and saves multi-hour unattended runs from per-iter Safari startup, user-profile drift, and tab-focus contention. Refs PsychQuant/psychquant-claude-plugins#77 + spectra change `adaptive-walk-agent-browser-default`.
- Anti-pattern table entry `Use agent-browser for discovery walk → wrong` removed. Using `agent-browser` for discovery is now the recommended default; using `safari-browser` is the opt-in path.
- Troubleshooting section restructured: separate `safari-browser missing` (only matters when `--browser safari` is opted into) and `agent-browser missing` (default-path failure mode) subsections.
- `08-shiny-testing.md` narrow exception clause cross-reference updated to note safari is opt-in via `--browser safari`; clause text itself remains accurate.

### Added
- `--browser=safari|agent` flag and `SHINY_ADAPTIVE_BROWSER` env var. Precedence: flag > env var > static default (`agent`). Invalid values abort Step 0 pre-flight with a message naming the accepted set.
- `browser_cmd()` shell helper dispatching the five discovery primitives (open / snapshot / click / fill / screenshot) to the selected CLI. Single source of truth — Step 3a contains no direct `safari-browser` / `agent-browser` invocations.
- Per-iteration commit body now records `BROWSER=<safari|agent>` audit-trail line for traceability.
- New documentation section `### When to opt into --browser safari` covering live-demo / teaching / in-the-moment debugging scenarios.

### Verified (per spectra change ACs)
- Phase 1 contract primitive tests (`test_contract_primitives.R`) pass.
- Phase 2 walker tests (`test_smoke_lite_walker.R`) pass.
- `grep "Use agent-browser for discovery walk"` against the skill markdown returns 0 hits (AC5).
- `grep "When to opt into"` returns multiple hits (AC6).

## [1.1.0] - 2026-05-13

### Added
- New skill `/shiny-adaptive-walk <COMPANY>` — self-converging adaptive testing loop. Each iter:
  - Discovery via safari-browser (real macOS Safari renderer, visible to user)
  - LLM judge classifies defects: `real_bug` → `/idd-issue` / `test_infra_gap` → skill mutates yaml/contracts.R
  - Per-iter safety gate (`testthat::test_dir` + mechanical gate) + auto-rollback on regression
  - Convergence: CONVERGED / PLATEAUED / DIMINISHING (mirrors `/glue-bridge` MP102 v1.3 pattern)
  - Branch isolation (`idd/<N>-adaptive-test-loop`), no auto-push during loop
  - LLM budget cap via `MP165_ADAPTIVE_BUDGET=100` env var
- Mutation boundary spec — skill CAN edit `98_test/e2e/**`, `23_deployment/dashboard_presence_gate.R`, `04_utils/fn_debug_mode.R`; skill MUST NOT touch production UI components, derivations, analysis functions, or ETL/DRV scripts (files `/idd-issue` instead)
- Issue dedup via composite signature `<company>:<module>:<sub_tab>:<defect_class>:<key_phrase>` + `gh issue list --search` before filing

### Changed
- README.md restructured to clearly distinguish `/shiny-debug` (single-pass interactive) vs `/shiny-adaptive-walk` (self-converging loop)
- Plugin description expanded to mention adaptive testing
- Keywords added: `safari-browser`, `adaptive-testing`, `mp165`

### Refs
- Spectra change: `adaptive-dashboard-test-loop` in `kiki830621/ai_martech_global_scripts` repo
- Parent issue: kiki830621/ai_martech_global_scripts#653
- MP165 v1.2 amendment (Track A + Track B dual architecture)

## [1.0.0] - 2026-01-13

### Added
- 功能測試導向的 R Shiny App Debug 工具，整合 agent-browser（前端）與 R console（後端）
- `/shiny-debug` command with Log-First discipline
- E2E 腳本生成功能（shinytest2 format）
