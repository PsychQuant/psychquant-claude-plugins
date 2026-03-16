---
name: debug-crash
description: |
  Debug iPad/iPhone app crashes by deploying with console capture.
  Use when user says "app crashed", "debug crash", "why did it crash",
  "閃退", "當掉", or after a deploy-and-test cycle where the app dies.
  Uses xcrun devicectl --console to capture stdout/stderr including
  Swift fatal errors, then analyzes the output.
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - AskUserQuestion
---

# Debug Crash

Deploy iOS app with console capture to diagnose crashes.

## When to Use

- App crashes/閃退 on device
- Need to see print() output from device
- Swift fatal errors (misaligned pointer, force unwrap, etc.)
- Need crash backtrace without full Xcode debugger

## Execution Steps

### Step 1: Build Debug

```bash
xcodebuild build -project <proj> -scheme <scheme> -configuration Debug -destination 'generic/platform=iOS' 2>&1 | grep -E '(error:|BUILD)'
```

### Step 2: Install on Device

```bash
xcrun devicectl device install app --device <udid> "<app_path>" 2>&1
```

### Step 3: Launch with Console Capture

This is the key step — `--console` captures all stdout/stderr:

```bash
xcrun devicectl device process launch \
  --device <udid> \
  --terminate-existing \
  --console \
  <bundle_id> 2>&1
```

The command blocks until the app exits. If the app crashes, the output includes:
- `Fatal error: <message>` — Swift runtime errors
- `App terminated due to signal N` — crash signals (6=SIGABRT, 11=SIGSEGV, 15=SIGTERM)
- All `print()` output from the app

### Step 4: Analyze Output

Common crash patterns:

| Output | Cause | Fix |
|--------|-------|-----|
| `load from misaligned raw pointer` | UnsafeRawPointer.load with unaligned offset | Use byte-by-byte read |
| `Thread 1: EXC_BAD_ACCESS` | Use-after-free or null pointer | Check object lifetime |
| `signal 9` (SIGKILL) | OOM — system killed for memory | Reduce allocations, check for leaks |
| `signal 6` (SIGABRT) | Assertion failed | Check guard/precondition |
| No crash output, app just dies | Jetsam (memory) | Check GPU texture allocation |

### Step 5: Check Crash Logs (if console doesn't show enough)

```bash
# Local crash reports
find ~/Library/Logs/DiagnosticReports -name "*<app>*" -type f | xargs ls -t | head -3

# Read latest
head -100 "<latest_crash_log>"
```

### Step 6: Report

Show:
- Crash message (if any)
- Signal number and meaning
- Relevant print() output before crash
- Suggested fix
