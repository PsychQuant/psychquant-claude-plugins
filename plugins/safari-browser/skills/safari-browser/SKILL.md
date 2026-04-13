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

### Snapshot (Element Discovery + Page State)
```bash
safari-browser snapshot                     # scan interactive elements → @e1, @e2...
safari-browser snapshot -c                  # compact (exclude hidden elements)
safari-browser snapshot -d 3                # limit DOM depth
safari-browser snapshot --page              # full page state: accessibility tree + metadata + alerts + dialogs
safari-browser snapshot --page --json       # full page state as JSON
safari-browser snapshot --page -s "main"    # scoped to <main> element
safari-browser snapshot -s "form.login"     # scope to CSS selector
safari-browser snapshot --json              # JSON array output
```

All selector-accepting commands support `@eN` refs from the last snapshot.

### Screenshot, PDF & Upload
```bash
safari-browser screenshot [path]            # default: screenshot.png [non-interfering]
safari-browser screenshot --full path       # full page [non-interfering]
safari-browser pdf --allow-hid [path]       # export as PDF [actively interfering — requires --allow-hid]
safari-browser upload <selector> <file>     # smart default: native dialog if Accessibility permitted, else JS fallback
safari-browser upload --js <sel> <file>    # force JS DataTransfer injection [non-interfering]
safari-browser upload --native <sel> <file> # force native file dialog [requires Accessibility permission]
```

**Upload behavior**: With Accessibility permission granted, `upload` uses the native file dialog by default (clipboard paste for path input — fast, supports all characters including CJK and spaces). Without permission, it automatically falls back to JS DataTransfer injection and prints a hint to stderr. Use `--js` to force JS mode, or `--native`/`--allow-hid` to force native mode (backward compatible).

**PDF export**: Uses clipboard paste for path input (instead of keystroke), precise waits (`repeat until exists`) instead of blind delays, and AXDefault button click (locale-independent) for the Save button. Still requires `--allow-hid`.

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

# Multi-window: per-origin storage requires --url targeting (#23)
safari-browser storage local get token --url plaud   # Plaud's token
safari-browser storage local get token --url oauth   # different OAuth provider's token
```

### Multi-Window Targeting (#17 #18 #21 #23)

When Safari has more than one window open, every command that reads from
or drives a document accepts global targeting flags:

```bash
safari-browser documents                                # discover available windows
safari-browser get url --url plaud                      # target by URL substring
safari-browser get title --window 2                     # target by window index (1-based)
safari-browser snapshot --url plaud                     # snapshot specific document
safari-browser wait --for-url "/dashboard" --url plaud  # wait on specific document

# Window-scoped commands (close/screenshot/pdf/upload --native) only accept --window
safari-browser screenshot --window 2 out.png
safari-browser pdf --window 2 --allow-hid out.pdf
safari-browser upload --native "input[type=file]" file.mp3 --window 2
```

**Default `screenshot` behavior** (#23 R7): when AX permission is granted, default `screenshot` (no flag) uses AX SPI for reliable identity (no title/bounds heuristic). Without AX permission, falls back to legacy CG name match.

**`screenshot --window N`** (#23 R6 C1): requires Accessibility permission. Uses `_AXUIElementGetWindow` private SPI for reliable AS↔CG mapping. Eliminates the wrong-window failure modes that bedevil bounds-/title-based matching. Strict fail-closed: throws `windowIdentityAmbiguous` when multiple visible windows can't be uniquely identified, instead of silently picking one.

**Wait command rename** (#23 BREAKING): `wait --url <pattern>` → `wait --for-url <pattern>`. The old `--url` flag is now a global targeting flag.

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
safari-browser upload "input[type='file']" "/path/to/document.pdf"         # smart default (native if permitted, else JS)
safari-browser upload --js "input[type='file']" "/path/to/document.pdf"   # force JS injection (no permissions needed)
safari-browser upload --native "input[type='file']" "/path/to/document.pdf" # force native dialog
safari-browser wait 5000   # wait for upload to complete
```

### Human-like Delays (Anti-Bot)

When automating sites that detect bots (banks, hospital EMR, social media), use Cauchy-distributed random delays instead of fixed `sleep`:

```bash
# Cauchy delay: median ~3s, occasionally 5-10s (simulates human rhythm)
sleep $(python3 -c "import random, math; print(max(2, round(3 + math.tan(math.pi * (random.random() - 0.5)) * 0.8, 1)))")
```

Use between every `safari-browser` command when operating sensitive sites. Never use fixed intervals — that's how bots get detected.

## Troubleshooting

- **Binary killed (exit 137 / SIGKILL)** — macOS Sequoia kills unsigned binaries that call osascript. Fix: `codesign --force --sign - ~/bin/safari-browser`. This is done automatically by `make install`.
- **Large JS output returns empty** — Safari `do JavaScript` silently drops results >~1MB. Use `safari-browser js --large "..."` or `--output /tmp/result.txt` for chunked read.

## Limitations

- **macOS only** — requires Safari + AppleScript
- **Not headless** — Safari always has a visible window
- **JS returns strings only** — use `JSON.stringify()` for objects
- **JS output ~1MB limit** — use `--large` flag for bigger results (auto-retries with chunked read)
- **No network interception** — Safari has no API for this
- **JS-based snapshot** — `snapshot` uses DOM scanning (not CDP accessibility tree), 90% as effective
- **Automation permission required** — first run prompts for Terminal → Safari access (System Settings → Privacy & Security → Automation)
- **upload smart default** — uses native file dialog when Accessibility permission is granted; auto-falls back to JS DataTransfer otherwise. Force with `--js` or `--native`
- **pdf requires Accessibility permission** — System Settings → Privacy & Security → Accessibility (uses clipboard paste + AXDefault button click)
