# Contributing a Playbook Skill

Playbook skills live next to the main `safari-browser` skill and document how to accomplish a specific operation on a specific website using `safari-browser` commands. Claude Code auto-surfaces them when a user's intent matches a skill's `description`.

This doc is the quick reference for contributors. The authoritative spec is `openspec/specs/playbook-skills/spec.md` in the safari-browser repo.

## Directory naming

```
skills/
  safari-browser/SKILL.md       ← main skill (pre-existing)
  safari-<site>-<action>/SKILL.md   ← playbook skills
```

- Use the pattern `safari-<site>-<action>`.
- `<site>` is a lowercase kebab-case fragment of the domain (`plaud.ai` → `plaud`, `github.com` → `github`, `icloud.com` → `icloud`).
- `<action>` is a lowercase verb describing the operation (`upload`, `star`, `login`).
- Keep the layout flat. `skills/plaud/upload/SKILL.md` (nested) will NOT be discovered by Claude Code's skill loader and is rejected by the convention.
- The `safari-` prefix is required: it prevents collisions with other plugins that might ship skills for the same site (for example, a Chrome-based plaud tool).

## Frontmatter contract

Each `SKILL.md` begins with exactly these three YAML keys:

```yaml
---
name: safari-plaud-upload
description: Upload audio files to Plaud via Safari. Use when the user asks to upload recordings to Plaud, add tracks to a Plaud folder, or transcribe audio with Plaud in Safari.
allowed-tools:
  - Bash(safari-browser:*)
  - Bash(safari-browser *)
---
```

Rules:

- `name` MUST equal the enclosing directory name.
- `description` MUST NOT exceed 200 characters, MUST mention "Safari", and MAY include an action clause followed by trigger phrases (e.g., "Upload audio files to Plaud via Safari. Use when ..."). Without the "Safari" keyword, Claude may auto-surface the playbook when the user is actually using a Chrome-based tool.
- `allowed-tools` MUST include at minimum `Bash(safari-browser:*)` and `Bash(safari-browser *)`. Additional entries (for example, `Bash(curl:*)` or `Bash(jq:*)`) are permitted when the playbook needs them.

## SKILL.md body — six ordered sections

The body MUST contain exactly these six level-2 headings, in this order:

```markdown
## When to use
## Preconditions
## Steps
## Error handling
## Verification
## Gotchas
```

What goes in each:

| Section | Purpose |
|---|---|
| `When to use` | Concrete trigger phrases and situations; narrow enough to avoid false activation. |
| `Preconditions` | Required login state, tab state, input files, permissions. Written so the user can satisfy them without reading the author's mind. |
| `Steps` | Numbered `safari-browser` invocations; each step includes the expected result so failures are diagnosable. |
| `Error handling` | Common failure modes and how to branch. |
| `Verification` | How the agent confirms success (URL change, visible element, response text). |
| `Gotchas` | Site-specific framework quirks, selector traps, anti-bot surprises, reactive-title resets, etc. |

## Generalized seeds, not personal workflows

A playbook MUST work for any user who installs the plugin and satisfies the `Preconditions`. Do NOT hardcode a specific account, plan tier, regional URL, or folder name — surface those in `Preconditions` so users can adapt them.

If your workflow cannot be generalized, keep it as a user-local playbook at `~/.claude/skills/safari-<site>-<action>/SKILL.md` instead of shipping it in the plugin.

## User-local override

Users can override or extend plugin-hosted playbooks by placing their own `SKILL.md` at `~/.claude/skills/safari-<site>-<action>/SKILL.md` using the same naming, frontmatter, and body structure. Claude Code's native skill loading handles discovery — the plugin adds no custom precedence logic.

## Review checklist

Before opening a PR that adds a playbook, verify each item:

- [ ] Directory name matches `safari-<site>-<action>` exactly.
- [ ] `name` in frontmatter matches directory name.
- [ ] `description` is ≤200 characters and mentions "Safari" (single or multiple clauses both fine).
- [ ] `allowed-tools` includes both `Bash(safari-browser:*)` and `Bash(safari-browser *)`.
- [ ] Body contains the six headings in the specified order.
- [ ] Every section is non-empty.
- [ ] `Preconditions` lists every assumed state, not just "user is logged in".
- [ ] `Steps` include expected results, not just commands.
- [ ] `Verification` is concrete (a URL pattern, an element, a response) — not "check that it worked".
- [ ] No hardcoded personal identifiers or account-specific URLs.

A reviewer should walk through each scenario in `openspec/specs/playbook-skills/spec.md` against your SKILL.md before merging.
