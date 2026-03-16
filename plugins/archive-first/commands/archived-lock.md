---
description: Enable archive protection (PreToolUse hooks block destructive commands on archived/)
---

# Archive-First: Lock

Enable the PreToolUse hooks that block destructive commands on `archived/` paths.

## Steps

1. Remove the disabled flag:
   ```bash
   rm -f ~/.cache/archive-first/disabled
   ```

2. Confirm to the user that protection is active.
