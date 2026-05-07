# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-05-07

### Added
- Initial release of `batch-ocr` plugin (#6 in `psychquant-claude-plugins`)
- 3 commands: `/batch-ocr <dir>`, `/batch-ocr-resume`, `/batch-ocr-status`
- 1 skill: `batch-ocr` (full pipeline workflow + idempotency rules + migration path)
- 2 scripts:
  - `scripts/batch-ocr.sh` — orchestrator (Phase 1 split → Phase 2 parallel OCR → Phase 3 merge → 1-round retry)
  - `scripts/ensure-tunnel.sh` — SSH tunnel health-check + auto-reconnect
- Idempotency rules:
  - Skip PDF if final `<name>.md` already non-empty
  - Skip page OCR if `page-N.png.md` already exists
  - `--resume` flag forces re-OCR of pages without corresponding `.md`
- Configuration via CLI flags or `BATCH_OCR_*` env vars: `parallel` (4), `host` (localhost:11500), `model` (glm-ocr), `dpi` (200), `remote_host` (kyle)
- Structured logs in `<input-dir>/.batch-ocr/<session-id>/log` with `failures.log` + `permanent_failures.log`

### Notes
- Currently uses `xargs -P` for parallelism. When `macdoc ocr --parallel N` (PsychQuant/macdoc#73) lands, Phase 2 will migrate to use that natively.
- Source 77-PDF transcript OCR campaign (~100 lines of one-off pipeline shell) consolidated into reusable plugin.
