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
| Need accessibility tree / snapshot refs | agent-browser |

## Core Workflow

```bash
# Navigate
safari-browser open "https://example.com"

# Interact with elements using CSS selectors
safari-browser click "button.submit"
safari-browser fill "input#email" "user@example.com"
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
```

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

### Screenshot & Upload
```bash
safari-browser screenshot [path]            # default: screenshot.png
safari-browser screenshot --full path       # full page
safari-browser upload <selector> <file>     # via System Events file dialog
```

### Tab Management
```bash
safari-browser tabs                         # list all tabs
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
safari-browser cookies get [name]
safari-browser cookies set <name> <value>
safari-browser cookies clear
safari-browser storage local get <key>
safari-browser storage local set <key> <value>
safari-browser storage local remove <key>
safari-browser storage local clear
safari-browser storage session get/set/remove/clear
```

### Debug
```bash
safari-browser console --start              # start capturing console.log
safari-browser console                      # read captured messages
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
- **No accessibility tree** — no `snapshot` / `@ref` system, use CSS selectors directly
- **upload requires Accessibility permission** — System Preferences → Privacy → Accessibility
