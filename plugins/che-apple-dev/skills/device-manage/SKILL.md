---
name: device-manage
description: |
  List, manage, and interact with connected Apple devices (iPad, iPhone, Mac).
  Use when user asks "what devices are connected", "list devices",
  "launch app on iPad", "kill app on device", "reset permissions",
  or needs to manage TCC permissions for Screen Recording/Accessibility.
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
---

# Device Management

Manage connected Apple devices and their apps.

## Commands

### List Devices

```bash
xcrun xctrace list devices 2>&1
```

Shows: device name, OS version, UDID, online/offline status.

### Launch App on Device

```bash
xcrun devicectl device process launch \
  --device <udid> \
  --terminate-existing \
  <bundle_id> 2>&1
```

Add `--console` to capture stdout/stderr (see debug-crash skill).

### Kill App on Device

```bash
xcrun devicectl device process launch \
  --device <udid> \
  --terminate-existing \
  <bundle_id> 2>&1
# Then immediately terminate — the --terminate-existing kills the old process
```

### Kill Mac Process

```bash
pkill -9 -f <process_name>
```

### Reset TCC Permissions

```bash
# Reset Screen Recording permission
tccutil reset ScreenCapture <bundle_id>

# Reset Accessibility
tccutil reset Accessibility <bundle_id>

# Reset all for bundle
tccutil reset All <bundle_id>
```

### Check TCC Status

```bash
sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db \
  "SELECT service, auth_value FROM access WHERE client='<bundle_id>'"
```

| auth_value | Meaning |
|-----------|---------|
| 0 | Denied |
| 2 | Allowed |
| 3 | Limited |

## Common Device Issues

| Problem | Solution |
|---------|----------|
| "device was not unlocked" | Unlock iPad/iPhone, then retry |
| "unable to launch" | Check bundle ID is correct, app is installed |
| Screen Recording keeps asking | App binary changed — copy to stable path like /Applications/ |
| No devices shown | Check USB cable, trust dialog on device |
