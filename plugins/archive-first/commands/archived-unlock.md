---
description: Disable archive protection (allow destructive commands on archived/ temporarily)
---

# Archive-First: Unlock

Disable the PreToolUse hooks to temporarily allow operations on `archived/` paths. Re-enable with `/archive-first:archived-lock` when done.

## Steps

1. Disable the archive-first plugin:
   ```bash
   claude plugin disable archive-first@psychquant-claude-plugins
   ```

2. Confirm to the user that protection is disabled.

3. Remind them to re-enable with `/archive-first:archived-lock` when done.
