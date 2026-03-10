---
description: Set up Archive-First auto-lock hooks in the current project
---

# Archive-First: Configure Hooks

Set up the PreToolUse and PostToolUse hooks that automatically protect `archived/` directories in this project.

## Steps

1. Check if `.claude/settings.json` exists in the current project. If not, create it.

2. Read the current settings file to preserve existing configuration.

3. Merge the following hooks into the settings (do not overwrite existing hooks — append to the arrays):

   **PreToolUse** — Block destructive commands on archived paths:
   ```json
   {
     "matcher": "Bash",
     "hooks": [
       {
         "type": "command",
         "command": "COMMAND=$(jq -r '.tool_input.command // empty'); if echo \"$COMMAND\" | grep -qE '(rm|rmdir|unlink).*archived'; then jq -n '{hookSpecificOutput:{hookEventName:\"PreToolUse\",permissionDecision:\"deny\",permissionDecisionReason:\"Blocked: destructive command targeting archived/ directory. Use /archive-first:unlock to remove protection first.\"}}'; else exit 0; fi"
       }
     ]
   }
   ```

   **PostToolUse** — Auto-lock archived directories:
   ```json
   {
     "matcher": "Bash",
     "hooks": [
       {
         "type": "command",
         "command": "for dir in $(find . -maxdepth 3 -type d -name 'archived' 2>/dev/null); do chflags -R uchg \"$dir\" 2>/dev/null; done; exit 0"
       }
     ]
   }
   ```

4. Also add `.claude/rules/archived-protection.md` if it doesn't exist:
   ```markdown
   # Archived Directory Protection
   NEVER use `rm`, `rm -rf`, `unlink`, or any destructive file operation on any path containing `archived`.
   Any file or directory under an `archived/` folder is a protected backup.
   Do not delete, move, overwrite, or modify anything in an `archived/` path.
   ```

5. Confirm to the user what was configured and remind them to restart Claude Code to activate the hooks.
