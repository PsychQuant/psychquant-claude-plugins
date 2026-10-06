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
- **Behavior change:** `commands/archive-lines.md` is now `skills/archive-lines/SKILL.md`, invoked as `/che-archive-lines:archive-lines`. It sets `disable-model-invocation: true`, so Claude no longer starts this GUI automation on its own; scheduled tasks whose prompt is this skill, and subagent skill preloads, no longer run it either.
- **Behavior change:** `calibrate` is no longer run by Claude. Calibration waits for the user to press Enter in a terminal, and the Bash tool has none: running it there exits at that prompt, and piping a newline in would record wherever the mouse happens to be, overwriting a good calibration ([#145](https://github.com/PsychQuant/psychquant-claude-plugins/issues/145)). The skill now shows the full command for the user to run in their own terminal.
- The skill only ever passes one of the four literal verbs (`calibrate`, `save`, `test`, `help`) to the script; any other argument is answered with the list of verbs, and an empty one means `help`.

### Fixed
- The script path is now `${CLAUDE_PLUGIN_ROOT}/scripts/line-save-chat.sh`, which Claude Code substitutes with the installed plugin location. Before, the command derived it with `$(dirname "$(dirname "$0")")`, but in command and skill content `$0` is the first argument (`save`, `test`, …), so this resolved to `.`, the user's working directory. It also listed a fixed install location under `~/.claude/plugins/` (marketplace installs live in the plugin cache instead) and ran `./scripts/line-save-chat.sh` relative to the user's project directory.
- The bare `/archive-lines` now works while no other command uses the name: the skill sets `name: archive-lines`, and a plugin skill gets its bare alias only from that field. In 1.0.0 only the namespaced form worked, although the repository's CLAUDE.md documented the bare one.
- README install instructions use the marketplace name (`che-archive-lines@psychquant-claude-plugins`) and no longer describe copying the plugin into `~/.claude/plugins/`.

### Security
- `allowed-tools` narrowed from `Bash(*), Read, Write, Glob` to `Bash(${CLAUDE_PLUGIN_ROOT}/scripts/line-save-chat.sh *)`. Before, any shell command and any file write ran without a prompt in the turn the command was invoked. Now only the bundled script does: Claude Code substitutes the installed path into the rule, so it matches only commands that start with that script. `bash -c '…' …` and a command chained after the script (`…; other`) do not match; both were checked with `claude -p --plugin-dir` on Claude Code 2.1.291, together with a control skill without the rule, whose script was denied. The grant clears when the user sends the next message. `Read`, `Write` and `Glob` are no longer pre-approved.

### Removed
- A hard-coded absolute path to one machine's cloud-sync folder in the command file (this repository is public).

### Docs
- README notes that LINE's local message database (`.edb`) is encrypted; the readable source is the "Save chat" `.txt` export. A LINE MCP that reads those exports is tracked in PsychQuant/che-msg#41.

## [1.0.0] - (date unknown — please fill in)

### Changed
- 歸檔 LINE macOS 聊天記錄到文字檔
