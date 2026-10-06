# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> ⚠ This file was bootstrapped by `changelog-tools:changelog-init` from the
> `plugin.json` description field. Section categorization is best-effort —
> review and refine `Added` / `Changed` / `Fixed` etc. as needed.

## [Unreleased]

## [1.1.0] - 2026-10-06

Plugin-shell upgrade to the current `harness-devtools:plugin-upgrade` baseline and the official plugin reference ([#139](https://github.com/PsychQuant/psychquant-claude-plugins/issues/139), parent PsychQuant/che-msg#39). `scripts/line-save-chat.sh` is unchanged.

### Changed
- **Behavior change:** `commands/archive-lines.md` is now `skills/archive-lines/SKILL.md`, invoked as `/che-archive-lines:archive-lines` (the bare `/archive-lines` still works while no other command uses the name). It sets `disable-model-invocation: true`, so Claude no longer starts this GUI automation on its own; scheduled tasks whose prompt is this skill, and subagent skill preloads, no longer run it either.

### Fixed
- The script path is now `${CLAUDE_PLUGIN_ROOT}/scripts/line-save-chat.sh`, which Claude Code substitutes with the installed plugin location. Before, the command derived it with `$(dirname "$0")` (a command has no `$0`), listed a fixed install location under `~/.claude/plugins/` (marketplace installs live in the plugin cache instead), and ran `./scripts/line-save-chat.sh` relative to the user's project directory.
- README install instructions use the marketplace name (`che-archive-lines@psychquant-claude-plugins`) and no longer describe copying the plugin into `~/.claude/plugins/`.

### Security
- `allowed-tools` narrowed from `Bash(*), Read, Write, Glob` to `Read`. Before, any shell command and any file write ran without a prompt in the turn the command was invoked. Running the script now goes through the user's normal permission settings: in the default mode Claude Code asks first; in `bypassPermissions` or auto mode it does not.

### Removed
- A hard-coded absolute path to one machine's cloud-sync folder in the command file (this repository is public).

### Docs
- README notes that LINE's local message database (`.edb`) is encrypted; the readable source is the "Save chat" `.txt` export. A LINE MCP that reads those exports is tracked in PsychQuant/che-msg#41.

## [1.0.0] - (date unknown — please fill in)

### Changed
- 歸檔 LINE macOS 聊天記錄到文字檔
