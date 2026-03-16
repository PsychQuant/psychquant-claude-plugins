---
description: Enable archive protection (PreToolUse hooks block destructive commands on archived/)
---

# Archive-First: Lock

Enable the PreToolUse hooks that block destructive commands (`rm`, `rmdir`, `unlink`) and write/edit operations on `archived/` paths.

## Steps

1. Enable the archive-first plugin:
   ```bash
   claude plugin enable archive-first@psychquant-claude-plugins
   ```

2. Confirm to the user that protection is active.
