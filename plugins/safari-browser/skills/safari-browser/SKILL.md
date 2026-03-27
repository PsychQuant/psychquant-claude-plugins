---
name: safari-browser
description: >-
  macOS native browser automation via Safari + AppleScript. Use when the user needs to automate
  websites that require login (Plaud, Elementor, banking, social media) — Safari preserves
  localStorage and cookies permanently. Also use when agent-browser fails due to session/auth
  issues, or when the user explicitly asks to use Safari. Triggers on: "login to site",
  "automate with Safari", "use Safari", "session expired with agent-browser", "Plaud upload",
  or any website automation where persistent auth is needed.
allowed-tools:
  - Bash(safari-browser:*)
  - Bash(safari-browser *)
---

# Safari Browser Automation

macOS native browser automation CLI using Safari + AppleScript. **Core advantage: permanent login** — uses the user's existing Safari session directly.

## When to Use safari-browser vs agent-browser

| Condition | Use |
|-----------|-----|
| Website requires login (Plaud, Elementor, banking, etc.) | **safari-browser** |
| Need localStorage/cookies from existing session | **safari-browser** |
| agent-browser `state save/load` fails | **safari-browser** |
| Vue/React sites where `fill` doesn't trigger reactivity | **safari-browser** (JS events dispatched) |
| Headless / CI / public sites | agent-browser |
| Cross-platform needed | agent-browser |
| Sites that block headless browsers (banks, social media) | **safari-browser** (real browser, no bot detection) |
| AI + human collaboration (user watches and takes over) | **safari-browser** (shared Safari window) |
| Need CDP accessibility tree | agent-browser (safari-browser has JS-based snapshot) |

## Core Workflow

```bash
# Navigate
safari-browser open "https://example.com"

# Discover elements (like agent-browser snapshot)
safari-browser snapshot              # @e1 input[type="email"], @e2 button "Submit"
safari-browser snapshot -c           # compact (hide invisible elements)
safari-browser snapshot --json       # structured JSON output

# Interact using @refs or CSS selectors
safari-browser click @e2
safari-browser fill @e1 "user@example.com"
safari-browser press Enter

# Get information
safari-browser get url
safari-browser get text "h1"

# Wait for page changes
safari-browser wait --url "dashboard"
safari-browser wait --js "document.querySelector('.loaded')"
```

## Command Reference

### Navigation
```bash
safari-browser open <url> [--new-tab] [--new-window]
safari-browser back
safari-browser forward
safari-browser reload
safari-browser close
```

### Element Interaction
```bash
safari-browser click <selector>
safari-browser dblclick <selector>
safari-browser fill <selector> <text>       # clear + fill + input/change events
safari-browser type <selector> <text>       # append text + input event
safari-browser select <selector> <value>    # dropdown
safari-browser hover <selector>
safari-browser focus <selector>
safari-browser check <selector>             # checkbox
safari-browser uncheck <selector>
safari-browser scroll <dir> [pixels]        # up/down/left/right, default 500px
safari-browser scrollintoview <selector>
safari-browser highlight <selector>         # red outline for debug
safari-browser drag <src> <dst>            # drag and drop (JS events)
```

### Keyboard
```bash
safari-browser press Enter
safari-browser press Tab
safari-browser press Escape
safari-browser press Control+a              # modifier combos
safari-browser press Shift+Tab
```

### Find Elements (by text/role/label/placeholder)
```bash
safari-browser find text "Submit" click
safari-browser find role "button" click
safari-browser find label "Email" fill "user@example.com"
safari-browser find placeholder "Search" fill "query"
```

### JavaScript
```bash
safari-browser js "document.title"
safari-browser js --file script.js
safari-browser js "JSON.stringify(localStorage)"
safari-browser js --large "document.body.innerText"    # chunked read for large output
safari-browser js --output /tmp/page.txt "document.body.innerText"  # write to file
```

**Large output handling**: Safari's `do JavaScript` silently drops results >~1MB. Use `--large` to force chunked read, or `--output` to write to file. The CLI auto-retries with chunked read when it detects empty output.

### Page & Element Info
```bash
safari-browser get url
safari-browser get title
safari-browser get text [selector]          # full page or element
safari-browser get source
safari-browser get html <selector>
safari-browser get value <selector>         # input value
safari-browser get attr <selector> <name>
safari-browser get count <selector>
safari-browser get box <selector>           # bounding box JSON
```

### State Checks
```bash
safari-browser is visible <selector>        # true/false
safari-browser is exists <selector>
safari-browser is enabled <selector>
safari-browser is checked <selector>
```

### Snapshot (Element Discovery)
```bash
safari-browser snapshot                     # scan interactive elements → @e1, @e2...
safari-browser snapshot -c                  # compact (exclude hidden elements)
safari-browser snapshot -d 3                # limit DOM depth
safari-browser snapshot -s "form.login"     # scope to CSS selector
safari-browser snapshot --json              # JSON array output
```

All selector-accepting commands support `@eN` refs from the last snapshot.

### Screenshot, PDF & Upload
```bash
safari-browser screenshot [path]            # default: screenshot.png
safari-browser screenshot --full path       # full page
safari-browser pdf [path]                   # export as PDF (System Events)
safari-browser upload <selector> <file>     # via System Events file dialog
```

### Tab Management
```bash
safari-browser tabs                         # list all tabs
safari-browser tabs --json                  # JSON array output
safari-browser tab <n>                      # switch to tab n
safari-browser tab new                      # new tab
```

### Wait
```bash
safari-browser wait <ms>                    # wait milliseconds
safari-browser wait --url <pattern>         # wait for URL to contain pattern
safari-browser wait --js <expr>             # wait for JS truthy
safari-browser wait --timeout <ms>          # custom timeout (default 30s)
```

### Storage
```bash
safari-browser cookies get [name]           # get all or by name
safari-browser cookies get --json           # JSON object output
safari-browser cookies set <name> <value>
safari-browser cookies clear
safari-browser storage local get <key>
safari-browser storage local set <key> <value>
safari-browser storage local remove <key>
safari-browser storage local clear
safari-browser storage session get/set/remove/clear
```

### Settings
```bash
safari-browser set media dark               # force dark mode
safari-browser set media light              # force light mode
```

### Debug
```bash
safari-browser console --start              # capture all levels (log/warn/error/info/debug)
safari-browser console                      # read captured messages ([warn], [error] prefixed)
safari-browser console --clear
safari-browser errors --start               # capture JS errors
safari-browser errors
safari-browser mouse move <x> <y>
safari-browser mouse down / up / wheel <dy>
```

## Common Patterns

### Login-Required Site (e.g., Plaud)
```bash
# Safari already has the session — just navigate
safari-browser open "https://web.plaud.ai"
safari-browser wait --js "!document.querySelector('.login-form')"

# Get JWT from localStorage
TOKEN=$(safari-browser js "localStorage.getItem('tokenstr')")

# Use token with curl for API calls
curl -H "Authorization: $TOKEN" https://api.example.com/data
```

### Form Submission
```bash
safari-browser open "https://example.com/form"
safari-browser fill "input#name" "John"
safari-browser fill "input#email" "john@example.com"
safari-browser select "select#country" "TW"
safari-browser check "input#agree"
safari-browser click "button[type='submit']"
safari-browser wait --url "success"
```

### File Upload
```bash
safari-browser open "https://example.com/upload"
safari-browser upload "input[type='file']" "/path/to/document.pdf"
safari-browser wait 5000   # wait for upload to complete
```

## Limitations

- **macOS only** — requires Safari + AppleScript
- **Not headless** — Safari always has a visible window
- **JS returns strings only** — use `JSON.stringify()` for objects
- **No network interception** — Safari has no API for this
- **JS-based snapshot** — `snapshot` uses DOM scanning (not CDP accessibility tree), 90% as effective
- **upload requires Accessibility permission** — System Preferences → Privacy → Accessibility
