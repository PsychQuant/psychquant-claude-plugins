---
name: codex-docs-guide
description: |
  Query OpenAI Codex CLI official documentation with accurate, up-to-date information.
  Use this skill proactively when the conversation involves:
  - Codex CLI installation, setup, or authentication
  - Codex CLI configuration (config.toml, AGENTS.md, profiles)
  - Codex models (GPT-5.4, GPT-5.3-Codex, Codex-Spark)
  - Codex CLI commands, flags, slash commands
  - Codex features (fast mode, web search, multi-agent, MCP, skills)
  - Codex speed/reasoning settings
  - Codex SDK, non-interactive mode, automation
  - Codex security, sandboxing, approval modes
  - Codex IDE extension or app configuration
  - Codex integrations (GitHub, Slack, Linear)
allowed-tools: WebFetch
---

# Codex Docs Guide

Query OpenAI Codex official documentation directly via WebFetch.

## When to Use

When the user asks about or the conversation involves:
- Codex CLI setup, configuration, or commands
- Codex model selection or switching
- Codex speed, fast mode, or reasoning levels
- Codex AGENTS.md, skills, MCP, rules
- Codex SDK, automation, or non-interactive mode
- Codex app, IDE extension, or cloud
- Any OpenAI Codex product or feature

## Execution Steps (IMPORTANT!)

**You MUST WebFetch official documentation - never answer from memory!**

### Step 1: Identify the topic and WebFetch the corresponding URL

Base URL: `https://developers.openai.com/codex`

**Getting Started:**

| Topic | URL |
|-------|-----|
| Codex overview | /codex/ |
| Quickstart | /codex/quickstart/ |
| Pricing | /codex/pricing/ |
| Models | /codex/models/ |
| Changelog | /codex/changelog/ |

**CLI:**

| Topic | URL |
|-------|-----|
| CLI overview | /codex/cli/ |
| CLI features | /codex/cli/features/ |
| Command line options | /codex/cli/reference |
| CLI slash commands | /codex/cli/slash-commands/ |

**App & IDE:**

| Topic | URL |
|-------|-----|
| App overview | /codex/app/ |
| App features | /codex/app/features/ |
| App settings | /codex/app/settings/ |
| IDE extension overview | /codex/ide/ |
| IDE features | /codex/ide/features/ |
| IDE settings | /codex/ide/settings/ |

**Configuration:**

| Topic | URL |
|-------|-----|
| Config basics | /codex/config/basics/ |
| Config advanced | /codex/config/advanced/ |
| Config reference | /codex/config/reference/ |
| Config sample | /codex/config/sample/ |
| Speed & fast mode | /codex/speed/ |
| Rules | /codex/rules/ |
| AGENTS.md | /codex/agents-md/ |
| MCP setup | /codex/mcp/ |
| Skills | /codex/skills/ |
| Multi-agents | /codex/multi-agents/ |

**Concepts:**

| Topic | URL |
|-------|-----|
| Prompting | /codex/concepts/prompting/ |
| Customization | /codex/concepts/customization/ |
| Sandboxing | /codex/concepts/sandboxing/ |
| Multi-agents | /codex/concepts/multi-agents/ |
| Workflows | /codex/concepts/workflows/ |
| Models | /codex/concepts/models/ |

**Automation:**

| Topic | URL |
|-------|-----|
| Non-interactive mode | /codex/non-interactive/ |
| Codex SDK | /codex/sdk/ |
| App server | /codex/app-server/ |
| MCP server | /codex/mcp-server/ |
| GitHub Action | /codex/github-action/ |

**Integrations:**

| Topic | URL |
|-------|-----|
| GitHub | /codex/integrations/github/ |
| Slack | /codex/integrations/slack/ |
| Linear | /codex/integrations/linear/ |

**Security:**

| Topic | URL |
|-------|-----|
| Security overview | /codex/security/ |
| Security setup | /codex/security/setup/ |
| Threat model | /codex/security/threat-model/ |

**Administration:**

| Topic | URL |
|-------|-----|
| Authentication | /codex/authentication/ |
| Enterprise setup | /codex/enterprise/ |

**Learn:**

| Topic | URL |
|-------|-----|
| Best practices | /codex/learn/best-practices/ |

### Step 2: WebFetch with full URL

Prepend `https://developers.openai.com` to the path:

```
WebFetch("https://developers.openai.com/codex/cli/reference", "Extract the documentation content about...")
```

### Step 3: Parse and respond

Extract relevant information from WebFetch results and answer the user directly.

## Quick Reference

### Installation
```bash
npm install -g @openai/codex    # npm
brew install codex              # Homebrew
```

### Config file
`~/.codex/config.toml` — primary config (TOML format, supports profiles)

### Key CLI flags
| Flag | Purpose |
|------|---------|
| `-m, --model` | Override model (e.g. `gpt-5.4`) |
| `-a, --ask-for-approval` | `untrusted` / `on-request` / `never` |
| `-s, --sandbox` | `read-only` / `workspace-write` / `danger-full-access` |
| `-i, --image` | Attach image files |
| `-p, --profile` | Load named config profile |
| `--full-auto` | Low-friction auto mode |
| `--search` | Enable web search |
| `--oss` | Use local OSS model (Ollama) |

### Models
| Model | Use case |
|-------|----------|
| `gpt-5.4` | Flagship, recommended for most tasks |
| `gpt-5.3-codex` | Best for complex software engineering |
| `gpt-5.3-codex-spark` | Near-instant iteration (Pro only) |

### Speed
- `/fast` — Toggle fast mode (1.5x speed, 2x credits, GPT-5.4 only)
- `codex-spark` — Separate lightweight model for instant responses

### Key paths
| Path | Purpose |
|------|---------|
| `~/.codex/config.toml` | User config |
| `~/.codex/AGENTS.md` | Global agent instructions |
| `AGENTS.md` | Repo-level instructions |
| `.agents/skills/` | Repo skills |
| `$HOME/.agents/skills` | Global skills |

## If topic is not in the table

1. Try WebSearch for `site:developers.openai.com/codex <topic>`
2. Use the URL from search results with WebFetch
3. Fall back to `WebFetch("https://developers.openai.com/codex/", "...")` for the main index

## Important Reminders

- **Never answer Codex configuration questions from memory** — always WebFetch first
- Codex docs are at `developers.openai.com/codex/`, NOT under `/docs/`
- Some URL paths may 404 — if so, try the parent path or use WebSearch
- Config is TOML (`config.toml`), not JSON — different from Claude Code
