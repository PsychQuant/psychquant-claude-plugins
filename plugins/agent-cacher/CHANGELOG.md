# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> ⚠ This file was bootstrapped by `changelog-tools:changelog-init` from the
> `plugin.json` description field. Section categorization is best-effort —
> review and refine `Added` / `Changed` / `Fixed` etc. as needed.

## [Unreleased]

## [0.1.0] - (date unknown — please fill in)

### Changed
- Explicit-lookup cache for AI agent shell calls — records every invocation to SQLite, exposes cache.{lookup,fetch,recent,diff} via MCP so the agent decides when to reuse cached output instead of re-running
