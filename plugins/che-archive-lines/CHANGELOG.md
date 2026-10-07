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
- **Behavior change:** `calibrate` is no longer run by Claude. Calibration waits for the user to press Enter in a terminal, and the Bash tool has none: running it there exits at that prompt, and piping two or more lines in would record wherever the mouse happens to be and store the second line as the menu offset, overwriting a good calibration ([#145](https://github.com/PsychQuant/psychquant-claude-plugins/issues/145)). The skill now shows the full command for the user to run in their own terminal. Because the script first brings LINE to the front, keystrokes then go to LINE — pressing Enter there can send a draft — so the README and the skill say to switch back to the terminal with Cmd-Tab before pressing Enter.
- The skill only ever passes one of the four literal verbs (`calibrate`, `save`, `test`, `help`) to the script; any other argument is answered with the list of verbs, and an empty one means `help`.

### Fixed
- The script path is now `${CLAUDE_PLUGIN_ROOT}/scripts/line-save-chat.sh`, which Claude Code substitutes with the installed plugin location. Before, the command derived it with `$(dirname "$(dirname "$0")")`, but in command and skill content `$0` is the first argument (`save`, `test`, …), so this resolved to `.`, the user's working directory. It also listed a fixed install location under `~/.claude/plugins/` (marketplace installs live in the plugin cache instead) and ran `./scripts/line-save-chat.sh` relative to the user's project directory.
- The bare `/archive-lines` now works while no other command uses the name: the skill sets `name: archive-lines`, and a plugin skill gets its bare alias only from that field. In 1.0.0 only the namespaced form worked, although the repository's CLAUDE.md documented the bare one.
- README install instructions use the marketplace name (`che-archive-lines@psychquant-claude-plugins`) and no longer describe copying the plugin into `~/.claude/plugins/`.

### Security
- `allowed-tools` narrowed from `Bash(*), Read, Write, Glob` to three exact rules: `Bash(${CLAUDE_PLUGIN_ROOT}/scripts/line-save-chat.sh save)`, `… test)` and `… help)`. Before, any shell command and any file write ran without a prompt in the turn the command was invoked. Now only those three commands do, unless the user's own deny or ask rules or managed settings say otherwise; `calibrate`, any other argument and any other command go through the user's normal permission settings. The grant clears when the user sends the next message. `Read`, `Write` and `Glob` are no longer pre-approved.
- A wildcard rule (`Bash(${CLAUDE_PLUGIN_ROOT}/scripts/line-save-chat.sh *)`) was tried first and dropped. Claude Code matches a rule against each subcommand of a pipeline or chain, and read-only commands such as `printf` need no approval, so the wildcard also pre-approved `calibrate`, including `printf '\n\n' | … calibrate`. That writes the second line into the config file, which `save` later evaluates in shell arithmetic ([#149](https://github.com/PsychQuant/psychquant-claude-plugins/issues/149)), so two calls without a prompt could have run any command.
- Checked with `claude -p --plugin-dir` probes on Claude Code 2.1.291 (`--permission-mode default --setting-sources project`, execution detected by marker files written by a stand-in script, with this skill's `allowed-tools` block copied verbatim): `"…" help` ran; `"…" calibrate`, `printf '\n\n' | "…" calibrate`, `"…" save; touch …` and `"…" calibrate2` were denied and nothing ran. `printf 'x\n' | "…" save` ran — piped input does reach the script — but only `calibrate` reads stdin, and it is not pre-approved.

### Removed
- A hard-coded absolute path to one machine's cloud-sync folder in the command file (this repository is public).

### Docs
- README notes that LINE's local message database (`.edb`) is encrypted; the readable source is the "Save chat" `.txt` export. A LINE MCP that reads those exports is tracked in PsychQuant/che-msg#41.

## [1.0.0] - (date unknown — please fill in)

### Changed
- 歸檔 LINE macOS 聊天記錄到文字檔
