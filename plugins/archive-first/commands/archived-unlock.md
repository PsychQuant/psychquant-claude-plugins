---
description: Remove immutable flag from archived files so they can be modified or deleted
---

# Archive-First: Unlock

Remove the immutable flag from archived files to allow cleanup or modification.

## Steps

1. Determine the target:
   - If `$ARGUMENTS` is provided, use it as the specific archived path to unlock
   - If no arguments, list all locked archived directories and ask the user which to unlock

2. Ask for explicit confirmation before unlocking:
   - Show the path and number of files that will be unlocked
   - Warn that unlocked files can be deleted by AI agents

3. Disable the archive-first plugin to prevent the PostToolUse hook from re-locking files:
   ```bash
   claude plugin disable archive-first@psychquant-claude-plugins
   ```

4. Remove the immutable flag from files:
   ```bash
   find <target> -type f -print0 | xargs -0 -n 200 chflags nouchg
   ```

5. Re-enable the archive-first plugin:
   ```bash
   claude plugin enable archive-first@psychquant-claude-plugins
   ```

6. Confirm the unlock was successful (verify 0 locked files remain in target).
