---
description: Copy a directory to archived/ with timestamp as a regression baseline
---

# Archive-First: Create Backup

Archive the specified directory (or current project) as a regression baseline before AI-assisted reorganization.

## Steps

1. Determine the target directory:
   - If `$ARGUMENTS` is provided, use it as the target path
   - If no arguments, use the current working directory

2. Create the archived copy:
   ```bash
   mkdir -p ./archived
   cp -r <target> ./archived/<dirname>-$(date +%Y%m%d-%H%M%S)
   ```

3. Confirm to the user:
   - Show the archived path
   - Show the number of files copied
   - Remind them that PreToolUse hooks will block destructive commands on `archived/`
