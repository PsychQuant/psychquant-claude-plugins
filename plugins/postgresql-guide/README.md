# postgresql-guide

Auto-triggered Skill for querying PostgreSQL official documentation.

## Problem

Claude's knowledge of PostgreSQL may be outdated or incomplete. This skill forces Claude to WebFetch the official PostgreSQL documentation instead of relying on memory.

## Solution

This Skill:
1. **Auto-triggers** when conversation involves PostgreSQL queries, syntax, configuration, etc.
2. **Forces WebFetch** from https://www.postgresql.org/docs/current/
3. **Direct information** - no sub-agent delegation to avoid information loss

## Documentation Source

| Source | URL |
|--------|-----|
| PostgreSQL Docs | https://www.postgresql.org/docs/current/ |
| SQL Commands | https://www.postgresql.org/docs/current/sql-commands.html |
| Data Types | https://www.postgresql.org/docs/current/datatype.html |
| Functions | https://www.postgresql.org/docs/current/functions.html |

## Installation

```bash
# Add marketplace (if not already added)
/plugin marketplace add PsychQuant/psychquant-claude-plugins

# Install this plugin
/plugin install postgresql-guide@PsychQuant/psychquant-claude-plugins
```

## License

MIT
