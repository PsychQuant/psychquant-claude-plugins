---
name: gemini-cli-guide
description: |
  Query Google Gemini CLI configuration, features, and documentation.
  Use this skill proactively when the conversation involves:
  - Gemini CLI installation, setup, or authentication
  - Gemini CLI configuration (GEMINI.md, settings, themes)
  - Gemini CLI commands, flags, slash commands
  - Gemini CLI features (sandbox, plan mode, yolo, skills, hooks)
  - Gemini CLI model routing, model steering
  - Gemini CLI extensions, MCP, ACP mode
  - Gemini CLI headless/non-interactive mode
  - Gemini CLI policy engine, trusted folders
  - Gemini CLI session management, checkpointing, rewind
allowed-tools: Bash, WebFetch
---

# Gemini CLI Docs Guide

Query Gemini CLI source code and official documentation for accurate, up-to-date information.

## When to Use

When the user asks about or the conversation involves:
- Gemini CLI setup, configuration, or commands
- Gemini CLI model selection, routing, or steering
- Gemini CLI sandbox, approval modes, policy engine
- GEMINI.md, skills, hooks, extensions
- Gemini CLI headless mode, ACP, automation
- Any Google Gemini CLI product or feature

## Strategy: Source Code First, Docs Second

**Primary source**: [`google-gemini/gemini-cli`](https://github.com/google-gemini/gemini-cli) GitHub repo.

**Secondary source**: WebFetch from `https://geminicli.com/docs/` — for conceptual guides and tutorials.

## Execution Steps (IMPORTANT!)

**You MUST query the source — never answer from memory!**

### Step 1: Determine query type and choose method

| Query Type | Method | Example |
|-----------|--------|---------|
| Config options, settings | Repo: docs/reference/configuration.md | "What settings can I configure?" |
| CLI flags, options | Repo: docs/cli/cli-reference.md | "What flags does `gemini` accept?" |
| Model routing, steering | Repo: docs/cli/model-routing.md | "How to route models?" |
| Policy engine | Repo: docs/reference/policy-engine.md | "How does policy engine work?" |
| Skills, hooks | Repo: docs/cli/skills.md, hooks/ | "How to create skills?" |
| Extensions, MCP | Repo: docs/extensions/ | "How to add MCP servers?" |
| Conceptual guides | WebFetch docs site | "How does sandboxing work?" |

### Step 2a: Query GitHub Repo (primary)

**Search for keywords across the repo:**
```bash
gh search code "keyword" --repo google-gemini/gemini-cli --limit 20
```

**Read specific key files via raw URL:**
```bash
# CLI reference (flags, arguments)
curl -sL https://raw.githubusercontent.com/google-gemini/gemini-cli/main/docs/cli/cli-reference.md

# Configuration reference
curl -sL https://raw.githubusercontent.com/google-gemini/gemini-cli/main/docs/reference/configuration.md

# Model routing
curl -sL https://raw.githubusercontent.com/google-gemini/gemini-cli/main/docs/cli/model-routing.md

# Skills
curl -sL https://raw.githubusercontent.com/google-gemini/gemini-cli/main/docs/cli/skills.md

# Policy engine
curl -sL https://raw.githubusercontent.com/google-gemini/gemini-cli/main/docs/reference/policy-engine.md

# List all docs
gh api repos/google-gemini/gemini-cli/contents/docs/cli -q '.[].name'
gh api repos/google-gemini/gemini-cli/contents/docs/reference -q '.[].name'
```

> **IMPORTANT**: Always use `curl -sL` with raw.githubusercontent.com for reading files.
> Do NOT use `gh api contents -q '.content' | base64 -d` — it fails for files > 100KB.

**Key docs in `google-gemini/gemini-cli` repo:**

| File | Contains |
|------|----------|
| `docs/cli/cli-reference.md` | CLI flags, arguments |
| `docs/reference/configuration.md` | All config options |
| `docs/reference/commands.md` | Slash commands reference |
| `docs/reference/keyboard-shortcuts.md` | Keyboard shortcuts |
| `docs/reference/tools.md` | Available tools |
| `docs/reference/policy-engine.md` | Policy engine rules |
| `docs/cli/model.md` | Model selection |
| `docs/cli/model-routing.md` | Model routing |
| `docs/cli/model-steering.md` | Model steering |
| `docs/cli/sandbox.md` | Sandbox modes |
| `docs/cli/skills.md` | Skills system |
| `docs/cli/creating-skills.md` | How to create skills |
| `docs/cli/custom-commands.md` | Custom slash commands |
| `docs/cli/gemini-md.md` | GEMINI.md instructions file |
| `docs/cli/headless.md` | Non-interactive mode |
| `docs/cli/plan-mode.md` | Plan mode |
| `docs/cli/settings.md` | Settings UI |
| `docs/cli/session-management.md` | Session management |
| `docs/cli/checkpointing.md` | Checkpointing |
| `docs/cli/rewind.md` | Rewind feature |
| `docs/cli/acp-mode.md` | Agent Communication Protocol |
| `docs/cli/gemini-ignore.md` | .geminiignore file |
| `docs/cli/trusted-folders.md` | Trusted folders |
| `docs/extensions/` | Extension system |
| `docs/hooks/` | Hooks system |

### Step 2b: Query Docs Site (secondary)

Prepend `https://geminicli.com` to paths:

| Topic | URL Path |
|-------|----------|
| Overview | /docs/ |
| Get started | /docs/get-started/ |
| CLI reference | /docs/cli/cli-reference |
| Configuration | /docs/reference/configuration |
| Commands | /docs/reference/commands |
| Model routing | /docs/cli/model-routing |
| Skills | /docs/cli/skills |
| Hooks | /docs/hooks/ |
| Extensions | /docs/extensions/ |
| Sandbox | /docs/cli/sandbox |
| Policy engine | /docs/reference/policy-engine |
| Headless mode | /docs/cli/headless |

```
WebFetch("https://geminicli.com/docs/cli/cli-reference", "Extract documentation about...")
```

### Step 3: Parse and respond

Extract relevant information and answer the user directly.

## Quick Reference

### Installation
```bash
npm install -g @google/gemini-cli   # npm
```

### Package
`@google/gemini-cli` — GitHub: `google-gemini/gemini-cli`

### Config file
`GEMINI.md` — project-level instructions (like Claude's CLAUDE.md)

### Key CLI flags
| Flag | Purpose |
|------|---------|
| `-m, --model` | Override model |
| `-p, --prompt` | Non-interactive (headless) mode |
| `-i, --prompt-interactive` | Execute prompt then continue interactive |
| `-s, --sandbox` | Enable sandbox |
| `-y, --yolo` | Auto-approve all actions |
| `--approval-mode` | `default` / `auto_edit` / `yolo` / `plan` |
| `--policy` | Additional policy files |
| `-e, --extensions` | Specify extensions |
| `--acp` | Agent Communication Protocol mode |

### Key paths
| Path | Purpose |
|------|---------|
| `GEMINI.md` | Project instructions |
| `.gemini/settings.json` | Project settings |
| `~/.gemini/settings.json` | Global settings |
| `.gemini/skills/` | Project skills |
| `.geminiignore` | Ignore file |

## Fallback

If topic is not covered above:
1. `gh search code "topic" --repo google-gemini/gemini-cli`
2. WebSearch for `site:geminicli.com <topic>`
3. WebFetch `https://geminicli.com/docs/` for the main index

## Important Reminders

- **Source code is authoritative** for valid values, schemas, and types
- **Docs site is authoritative** for guides, tutorials, and conceptual explanations
- Config uses `GEMINI.md` (Markdown) and `settings.json` — different from Claude Code
- Gemini CLI uses extensions (not plugins) and has a policy engine (not hooks for permissions)
