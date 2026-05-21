# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> ⚠ This file was bootstrapped by `changelog-tools:changelog-init` from the
> `plugin.json` description field. Section categorization is best-effort —
> review and refine `Added` / `Changed` / `Fixed` etc. as needed.

## [Unreleased]

## [1.3.2] - 2026-05-21

### Fixed
- `che-telegram-all-mcp-wrapper.sh`: lock-refused branch now emits a JSON-RPC 2.0 error envelope to stdout before exiting, so Claude Code's MCP client surfaces a human-readable error message (e.g. `"Another instance of CheTelegramAllMCP is already running (lock held by PID 11252). Use the existing Claude Code window, or kill the previous wrapper first."`) instead of generic `-32000 Server error`. The envelope's `error.data` carries `lockHolderPid`, `recoveryCommand`, and `docsUrl`. Stderr message retained for direct-shell debug. Uses `id: null` per JSON-RPC 2.0 spec — manual two-session reproduction (idd-verify step) will confirm Claude Code's MCP client surfaces null-id error responses. New `test-wrapper-mcp-error.sh` covers 4 cases (happy path, lock refused, stale lock self-recovery, recoveryCommand validation). Resolves [#31](https://github.com/PsychQuant/che-msg/issues/31).

### Documentation
- `README.md`: added `## Multi-session limitation` section explaining the TDLib single-instance constraint, the v1.3.2+ human-readable error message, and a recovery cookbook (`pkill CheTelegramAllMCP && rm -rf ~/.cache/che-telegram-all-mcp.lock`). Documents the pre-v1.3.2 generic `-32000` symptom for users upgrading.

## [1.3.1] - 2026-05-07

### Fixed
- `che-telegram-all-mcp-wrapper.sh`: add atomic-claim lock (flock with mkdir fallback) before PID-tracking section. Prevents the multi-window race where window B reads window A's PID, sees an alive `CheTelegramAllMCP` process, sends SIGTERM and unannouncedly kills window A's MCP server. Lock is portable: uses `flock -n` when available (Linux / macOS Sequoia+ if shipped), falls back to atomic `mkdir` directory-claim on systems without flock (verified macOS 26.4.1). Stale-lock cleanup removes orphaned locks whose owner PID is dead. Failure mode is now fail-fast with clear stderr message instead of silent SIGTERM cross-fire. `che-telegram-bot-mcp-wrapper.sh` deliberately unchanged — bot HTTPS API is stateless, multi-instance safe. New regression test (`test-wrapper-pid.sh` test 9) verifies second instance fail-fast + first instance survival. Resolves #10.

## [1.3.0] - (date unknown — please fill in)

### Changed
- Telegram MCP Server Plugin — Bot API + 個人帳號 TDLib 全功能存取，28+ 工具，Keychain 密鑰管理
