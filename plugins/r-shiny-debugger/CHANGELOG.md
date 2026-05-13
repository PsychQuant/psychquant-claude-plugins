# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> ⚠ This file was bootstrapped by `changelog-tools:changelog-init` from the
> `plugin.json` description field. Section categorization is best-effort —
> review and refine `Added` / `Changed` / `Fixed` etc. as needed.

## [Unreleased]

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
