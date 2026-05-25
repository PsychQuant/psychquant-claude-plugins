# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> ⚠ This file was bootstrapped by `changelog-tools:changelog-init` from the
> `plugin.json` description field. Section categorization is best-effort —
> review and refine `Added` / `Changed` / `Fixed` etc. as needed.

## [Unreleased]

## [1.3.2] - 2026-05-22

### Fixed
- `che-telegram-all-mcp-wrapper.sh`: lock-refused branch now emits a JSON-RPC 2.0 error envelope to stdout before exiting, so Claude Code's MCP client parses the human-readable message + structured data instead of seeing only `-32000 Server error`. Envelope carries:
  - `error.code: -32000` (JSON-RPC server-defined errors range)
  - `error.message: "Another instance of CheTelegramAllMCP is already running (lock held by PID NNNN). Use the existing Claude Code window, or kill the previous wrapper first."`
  - `error.data.lockHolderPid: <pid>` (machine-readable lock holder)
  - `error.data.recoveryCommand: "pkill CheTelegramAllMCP 2>/dev/null; rm -rf ~/.cache/che-telegram-all-mcp.lock ~/.cache/che-telegram-all-mcp.lock.flock"` (semicolon, not `&&`, so cleanup runs even when no process exists)
  - `error.data.docsUrl: https://.../README.md#multi-session-limitation`

  The original stderr message is retained for direct-shell debug.

  **PR-1b id matching (added 2026-05-22 after empirical verification)**: wrapper reads the first line of stdin (with 2s timeout) to extract the JSON-RPC `initialize` request's `id` field, then emits the response envelope with **matching id**. This was required because empirical two-session reproduction in Claude Code v2.1.148 showed that `id: null` responses (the v1.3.2 first attempt) are not matched to pending `initialize` requests and don't surface in Claude Code's MCP error state. With matching-id (PR-1b), debug-log capture confirmed Claude Code's MCP client correctly parses the envelope + stores the full `error.message` internally.

  Stdin extraction uses `jq` when available (preferred) and a bash regex fallback for environments without jq. Handles MCP 1.0 spec id forms: integer, quoted string, or null.

  New `test-wrapper-mcp-error.sh` covers 6 cases: happy path / lock refused emits valid JSON / stale-lock self-recovery / recoveryCommand validation / id-matching with initialize request / timeout fallback to null. Resolves [#31](https://github.com/PsychQuant/che-msg/issues/31).

  **Known UX gap** (out of plugin scope): Claude Code's `/mcp` short-list UI may display only `-32000` (truncated form) instead of the full message. The full message IS captured in Claude Code's internal MCP error state (verified via `--debug mcp` debug logs) and is available to downstream tool consumers. The display truncation is a Claude Code UI policy concern, not a plugin issue.

### Documentation
- `README.md`: added `## Multi-session limitation` section explaining the TDLib single-instance constraint, the v1.3.2+ human-readable error message, and a recovery cookbook (`pkill CheTelegramAllMCP 2>/dev/null; rm -rf ~/.cache/che-telegram-all-mcp.lock ~/.cache/che-telegram-all-mcp.lock.flock`). Documents the pre-v1.3.2 generic `-32000` symptom for users upgrading.

## [1.3.1] - 2026-05-07

### Fixed
- `che-telegram-all-mcp-wrapper.sh`: add atomic-claim lock (flock with mkdir fallback) before PID-tracking section. Prevents the multi-window race where window B reads window A's PID, sees an alive `CheTelegramAllMCP` process, sends SIGTERM and unannouncedly kills window A's MCP server. Lock is portable: uses `flock -n` when available (Linux / macOS Sequoia+ if shipped), falls back to atomic `mkdir` directory-claim on systems without flock (verified macOS 26.4.1). Stale-lock cleanup removes orphaned locks whose owner PID is dead. Failure mode is now fail-fast with clear stderr message instead of silent SIGTERM cross-fire. `che-telegram-bot-mcp-wrapper.sh` deliberately unchanged — bot HTTPS API is stateless, multi-instance safe. New regression test (`test-wrapper-pid.sh` test 9) verifies second instance fail-fast + first instance survival. Resolves #10.

## [1.3.0] - (date unknown — please fill in)

### Changed
- Telegram MCP Server Plugin — Bot API + 個人帳號 TDLib 全功能存取，28+ 工具，Keychain 密鑰管理
