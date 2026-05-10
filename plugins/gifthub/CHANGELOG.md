# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> ⚠ This file was bootstrapped by `changelog-tools:changelog-init` from the
> `plugin.json` description field. Section categorization is best-effort —
> review and refine `Added` / `Changed` / `Fixed` etc. as needed.

## [Unreleased]

## [1.2.0] - 2026-05-10

### Changed
- **Detect v2 config layout `.claude/.gfs/config.json` first，fallback v1 `.gfh.json`**（與 [`PsychQuant/GiftHub#17`](https://github.com/PsychQuant/GiftHub/issues/17) 配對）
  - `hooks/session-start.sh`：改 detection logic，inject context 含 `Layout: v1|v2 (path)` 標示
  - `skills/gfh-import/SKILL.md`：Prerequisites + Step 1 read config 用 v2 priority chain
  - `plugin.json` description 同步描述

### Coordinated upstream
- 對應 GiftHub CLI v0.4.0+ 把 default config 寫到 `.claude/.gfs/`。Plugin v1.2 backward-compat 兩 layout，consumer 升 gfh 與 plugin 不需特定順序。

## [1.1.0] - (date unknown — please fill in)

### Changed
- GiftHub CLI integration — auto-detect .gfh.json, inject usage context, auto-install after build
