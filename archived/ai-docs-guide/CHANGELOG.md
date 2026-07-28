# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> ⚠ This file was bootstrapped by `changelog-tools:changelog-init` from the
> `plugin.json` description field. Section categorization is best-effort —
> review and refine `Added` / `Changed` / `Fixed` etc. as needed.

## [Unreleased]

## [1.5.0] - 2026-07-29

### Deprecated

- **整個 plugin 退役，由 `livedocs`（livedocs-marketplace）取代**。livedocs 的
  `look-up` skill 以 primary-source 路由（llms.txt / registry / repo / OpenAPI /
  CLI introspection）覆蓋本 plugin 全部場景（Claude Code / OpenAI / Codex /
  Gemini 文檔查詢），且不需維護 curated URL 對照表。原始碼移至
  `archived/ai-docs-guide/`，marketplace 移除 entry。全域 CLAUDE.md 的
  「Claude Code 設定查詢規則」同步改指向 livedocs。

### Changed
- Auto-triggered Skills for querying Claude Code, OpenAI, Codex CLI, Gemini API, and Gemini CLI official documentation.
- Source-code-first strategy for CLI tools. /ai-docs-guide for cross-platform comparison
