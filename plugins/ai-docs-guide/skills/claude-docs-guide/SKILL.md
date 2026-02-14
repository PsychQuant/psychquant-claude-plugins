---
name: claude-docs-guide
description: |
  Query Claude Code configuration, file locations, MCP settings, and official documentation.
  Use this skill proactively when the conversation involves:
  - Claude Code settings, configuration, config, settings
  - MCP server setup, mcp.json, mcpServers
  - ~/.claude.json, .mcp.json, settings.json locations
  - hooks, slash commands, skills configuration
  - Claude Code features, API, SDK questions
allowed-tools: WebFetch
---

# Claude Docs Guide

Query Claude Code official documentation directly via WebFetch.

## When to Use

When the user asks about or the conversation involves:
- Claude Code config file locations
- MCP server configuration
- Hooks setup
- Skills/Commands creation
- Claude Code features

## Execution Steps (IMPORTANT!)

**You MUST WebFetch official documentation - never answer from memory!**

### Step 1: Documentation Sources

**Two primary documentation sources:**

| Source | URL | Purpose |
|--------|-----|---------|
| Claude Code CLI docs | https://code.claude.com/docs/en/claude_code_docs_map.md | CLI config, MCP, hooks, skills |
| Claude API/SDK docs | https://platform.claude.com/llms.txt | API reference, Agent SDK, platform features |

### Step 2: WebFetch the corresponding doc based on question type

**Claude Code CLI documentation:**

| Question Type | Documentation URL |
|---------------|-------------------|
| MCP config | https://code.claude.com/docs/en/mcp.md |
| Settings | https://code.claude.com/docs/en/settings.md |
| Hooks | https://code.claude.com/docs/en/hooks.md |
| Skills | https://code.claude.com/docs/en/skills.md |
| Commands | https://code.claude.com/docs/en/slash-commands.md |
| IAM/Permissions | https://code.claude.com/docs/en/iam.md |
| Plugins | https://code.claude.com/docs/en/plugins.md |
| Sub-agents | https://code.claude.com/docs/en/sub-agents.md |
| Agent teams | https://code.claude.com/docs/en/agent-teams.md |
| Memory/CLAUDE.md | https://code.claude.com/docs/en/memory.md |

**Claude API/SDK documentation:**

| Question Type | Documentation URL |
|---------------|-------------------|
| Agent SDK | https://platform.claude.com/docs/en/agent-sdk/overview.md |
| Claude API | https://platform.claude.com/llms.txt (index) |
| MCP connector (API) | https://platform.claude.com/docs/en/agents-and-tools/mcp-connector.md |

### Step 3: Parse and respond

Extract relevant information from WebFetch results and answer the user directly.

## Important Reminder

**Never answer Claude Code configuration questions from memory!**

### Common Mistakes

| Wrong | Correct |
|-------|---------|
| `~/.claude/settings.json` | `~/.claude.json` (user scope MCP config) |
| | `.mcp.json` (project scope MCP config) |

### Config File Precedence

1. Managed (system-wide)
2. Command line arguments
3. Local project settings `.claude/settings.local.json`
4. Shared project settings `.claude/settings.json`, `.mcp.json`
5. User global settings `~/.claude.json`, `~/.claude/settings.json`

## Why not use a sub-agent?

Sub-agent responses require paraphrasing, which may cause information loss.
**Fetch the docs yourself for more direct and accurate information.**
