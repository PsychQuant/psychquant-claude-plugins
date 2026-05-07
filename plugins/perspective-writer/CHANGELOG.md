# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> ⚠ This file was bootstrapped by `changelog-tools:changelog-init` from the
> `plugin.json` description field. Section categorization is best-effort —
> review and refine `Added` / `Changed` / `Fixed` etc. as needed.

## [Unreleased]

## [2.6.0] - 2026-05-07

### Added
- New `save-feedback` skill (#28): captures **conversational feedback** that user gives mid-draft into reusable rules. Complements `draft-learner` (which only triggers on file-modification system-reminders). Real-world gap: when user gives verbal tone/style/relationship/structure feedback in conversation and agent rewrites the file each round, no file diff is produced → draft-learner never fires → feedback evaporates at session end. `save-feedback` fills that gap with explicit invocation (`/perspective-writer:save-feedback`) or proactive trigger phrases ("存 feedback" / "把這些建議記下來"). 6-step workflow (scan conversation → classify → extract concrete rules with **Why** field → locate `.claude/rules/` file → write → confirm). Distinct from draft-learner per a side-by-side comparison table in the SKILL.md.

## [2.5.0] - (date unknown — please fill in)

### Changed
- Write letters, emails, autobiographies, and formal documents by simulating the writer's authentic voice.
- Uses Tarski's T-Schema to ensure every sentence has a concrete referent, and a 6-phase process (understand writer, understand recipient, simulate, write, anti-pattern check, iterate) to produce writing that sounds like a real person, not AI
