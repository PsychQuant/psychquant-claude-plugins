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

3. Remove the immutable flag:
   ```bash
   chflags -R nouchg <target>
   ```

4. Confirm the unlock was successful.
