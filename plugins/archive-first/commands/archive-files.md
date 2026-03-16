---
description: Copy a directory to archived/ with timestamp and lock it with immutable flag
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

3. Lock files (not directories) with the immutable flag:
   ```bash
   find ./archived/<dirname>-* -type f -exec chflags uchg {} +
   ```
   This protects existing files from modification while still allowing new files to be copied into the directories.

4. Confirm to the user:
   - Show the archived path
   - Show the number of files protected
   - Remind them they can use `/archive-first:unlock` to remove protection later
