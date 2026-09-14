# Read every command result before continuing

Read stderr's first line first, then retain and inspect the complete stderr. A `--tab` notice or another diagnostic can precede the blocking warning. Keep stdout separate; parse JSON only from stdout. A nonzero exit stops the sequence. A `⚠ BLOCKING DIALOG` warning also stops the next action even when a read-only command returned exit zero.

Do not use `2>&1 | tail -1`, discard stderr, or use `head -1` on a live combined stream. They hide evidence, and an early-closing pipe can interrupt the producer. Read a first line from output already captured to completion.

This Python example keeps both streams in memory. It forwards all diagnostics, returns the first line for inspection, preserves a failed command's exit status (including signal status), and never retries:

```python
import subprocess
import sys


def checked(*arguments):
    result = subprocess.run(["safari-browser", *arguments], capture_output=True, text=True, check=False)
    lines = result.stderr.splitlines()
    first_stderr_line = lines[0] if lines else ""
    if result.stderr:
        sys.stderr.write(result.stderr)
    if result.returncode:
        code = result.returncode if result.returncode > 0 else 128 - result.returncode
        raise SystemExit(code)
    if any(line.startswith("⚠ BLOCKING DIALOG") for line in lines):
        raise RuntimeError("Stop before the next action: inspect the dialog; do not replay the previous command.")
    return result.stdout, first_stderr_line
```

Call `checked("click", observed_ref, "--url", target_url)` only for an action already authorized by the user, then observe the intended page state before another action. A timeout or failure can occur after part of an action ran; inspect first rather than automatically replaying it. For other warnings, including an unavailable/incomplete probe, read the full explanation and resolve the uncertainty before relying on it to approve a later action.

When a blocking dialog is reported, run `safari-browser dialog list`. Read the message and all named choices. Use `safari-browser dialog dismiss --button "<exact observed title>"` only when that choice follows the user's existing authorization. Never choose a default, infer permission from the warning, or replay a potentially completed submission. If list cannot inspect the dialog, keep the state unknown; do not treat it as no dialog.

For shell pipelines, enable `set -o pipefail` and check every pipeline's result. Keep stderr visible and consume the producer's complete stdout:

```bash
set -o pipefail
if safari-browser history --search agent --limit 50 --json \
    | python3 -c 'import json,sys; print(json.dumps({"returned_rows": len(json.load(sys.stdin))}))'; then
    : # inspect stderr and the result before the next step
else
    code=$?
    exit "$code"
fi
```

`pipefail` preserves a failure, not necessarily the first command's numeric exit code when multiple commands fail. Use separate capture when that code matters. A successful command or pipeline still does not prove the page reached the intended state; apply Observe After Acting too.
