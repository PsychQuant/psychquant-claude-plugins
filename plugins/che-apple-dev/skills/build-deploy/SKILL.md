---
name: build-deploy
description: |
  Build and deploy Xcode projects to Mac or iOS devices in one step.
  Use when user says "build and deploy", "deploy to iPad", "rebuild server",
  "install on device", or wants to test changes on a physical device.
  Handles xcodegen → xcodebuild → install → launch automatically.
allowed-tools:
  - Bash
  - Read
  - Glob
  - AskUserQuestion
---

# Build & Deploy

One-step build and deploy for Xcode projects.

## Execution Steps

### Step 1: Detect Project

```bash
# Find project.yml (xcodegen) or .xcodeproj
ls project.yml *.xcodeproj 2>/dev/null
```

If `project.yml` exists, run `xcodegen generate` first.

### Step 2: Determine Target

Ask if ambiguous:
- **macOS app**: build Release → copy to /Applications/ → restart
- **iOS device**: build Debug → install via devicectl → launch

### Step 3: Build

```bash
# macOS
xcodebuild build -project <proj> -scheme <scheme> -configuration Release -destination 'platform=macOS' 2>&1 | grep -E '(error:|warning:|BUILD)'

# iOS device
xcodebuild build -project <proj> -scheme <scheme> -configuration Debug -destination 'generic/platform=iOS' 2>&1 | grep -E '(error:|warning:|BUILD)'
```

If build fails, show errors and stop.

### Step 4: Deploy

#### macOS
```bash
pkill -9 -f <process_name> 2>/dev/null
sleep 1
cp -R "<built_products_dir>/<app>.app" /Applications/
nohup /Applications/<app>.app/Contents/MacOS/<binary> > /dev/null 2>&1 &
```

#### iOS Device
```bash
# Get device UDID
xcrun xctrace list devices 2>&1 | grep -E 'iPad|iPhone'

# Install + launch
xcrun devicectl device install app --device <udid> "<app_path>" 2>&1
xcrun devicectl device process launch --device <udid> --terminate-existing <bundle_id> 2>&1
```

### Step 5: Verify

Confirm process is running:
```bash
ps aux | grep <app_name> | grep -v grep
```

Report: build time, deploy target, status.
