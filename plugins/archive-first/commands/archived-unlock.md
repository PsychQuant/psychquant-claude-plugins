---
description: Disable archive protection (allow operations on archived/ temporarily)
---

# Archive-First: Unlock

Temporarily disable the PreToolUse hooks to allow operations on `archived/` paths.

## Steps

1. Create the disabled flag:
   ```bash
   mkdir -p ~/.cache/archive-first && touch ~/.cache/archive-first/disabled
   ```

2. Confirm to the user that protection is disabled.

3. Remind them to re-enable with `/archive-first:archived-lock` when done.
