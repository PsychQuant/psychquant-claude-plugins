# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> ⚠ This file was bootstrapped by `changelog-tools:changelog-init` from the
> `plugin.json` description field. Section categorization is best-effort —
> review and refine `Added` / `Changed` / `Fixed` etc. as needed.

## [Unreleased]

## [1.2.0] - 2026-09-30

### Added
- `/lean-prover:proved-manuscript` skill and `scripts/proved_manuscript.py`: from a Lean-checked theorem-card graph (`card-graph --lean`), build a LaTeX document that contains only the proved theorems and the definitions they use, in dependency order and in the manuscript's own wording, plus a `FRONTIER.md` report (statements not yet proved, statements not yet stated in Lean, proved statements held back). Output is reproducible and has a `--check` mode. Tests in `tests/lean-prover/`.

## [1.1.0] - (date unknown — please fill in)

### Changed
- Lean 4 automated proof grinding — breadth-first sorry elimination with Mathlib API rules, codex-prove-assist, lean-prover agent, and auto-commit
