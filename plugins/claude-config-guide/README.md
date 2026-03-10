# claude-config-guide

Auto-triggered Skill that forces Claude to WebFetch official documentation before answering Claude Code configuration questions.

## Problem

Claude often provides **incorrect file paths** when asked about Claude Code configuration because it relies on memory instead of current documentation.

Example:
- ❌ Wrong: `~/.claude/settings.json`
- ✅ Correct: `~/.claude.json` (user scope MCP config)

## Solution

This Skill:
1. **Auto-triggers** when conversation mentions Claude Code config, MCP, settings, hooks, etc.
2. **Forces Claude to WebFetch** official documentation instead of answering from memory
3. **No sub-agent delegation** - main Claude reads docs directly to avoid information loss

## Why Skill instead of Agent?

| Aspect | Agent | Skill |
|--------|-------|-------|
| Triggering | Must be explicitly called | **Auto-triggered** by keywords |
| Information flow | Delegated → summarized → returned | **Direct injection** |
| Accuracy | May lose details in transfer | **No information loss** |

## Documentation Sources

| Source | URL |
|--------|-----|
| Claude Code CLI | https://code.claude.com/docs/en/ |
| Claude API/SDK | https://platform.claude.com/llms.txt |

## Installation

```bash
# Add marketplace
/plugin marketplace add PsychQuant/psychquant-claude-plugins

# Install this plugin
/plugin install claude-config-guide@PsychQuant/psychquant-claude-plugins
```

## Related

- GitHub Issue: https://github.com/anthropics/claude-code/issues/18332

## License

MIT
