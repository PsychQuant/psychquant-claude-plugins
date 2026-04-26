# che-ical-mcp Plugin

Claude Code plugin for macOS Calendar & Reminders management using native EventKit.

## Features

- **28 MCP Tools**: Complete calendar and reminder management with attendees / organizer support, batch operations, and undo/redo
- **Skills**: Guided calendar management workflow
- **Commands**: Quick shortcuts for common operations
- **Auto-detection**: Automatically finds installed MCP binary
- **Setup check**: Warns if MCP is not installed on session start (version-aware auto-download since v1.7.2)
- **i18n Week Support**: Configurable week start day (Monday/Sunday/Saturday/System)
- **Per-event timezone**: Each event can carry its own timezone instead of relying on the system default
- **Day-of-week verification hook** (PreToolUse): catches "Friday 2026-04-26" mismatches before they reach Calendar.app
- **Flexible date parsing + fuzzy matching**: natural-language date strings + close-match suggestions when calendar / event names don't exactly match

## Installation

### Step 1: Install MCP Server (if not already installed)

```bash
# Download the binary
mkdir -p ~/bin
curl -L https://github.com/PsychQuant/che-ical-mcp/releases/latest/download/CheICalMCP -o ~/bin/CheICalMCP
chmod +x ~/bin/CheICalMCP
```

Or download `.mcpb` from [Releases](https://github.com/PsychQuant/che-ical-mcp/releases) for one-click install.

On first use, macOS will prompt for **Calendar** and **Reminders** access - click "Allow".

### Step 2: Install Plugin

#### Method A: Plugin Directory (Development)

```bash
claude --plugin-dir /path/to/che-ical-mcp/plugin
```

#### Method B: Add to Settings

Add to `~/.claude/settings.json`:

```json
{
  "plugins": [
    "/path/to/che-ical-mcp/plugin"
  ]
}
```

## How It Works

The plugin automatically detects your MCP installation from these locations:
- `~/bin/CheICalMCP`
- `/usr/local/bin/che-ical-mcp`
- `~/Library/Application Support/Claude/mcp-servers/che-ical-mcp/` (MCPB)

A **SessionStart hook** checks if the MCP is properly installed and shows setup instructions if needed.

## Included Components

### MCP Server

| Server | Description |
|--------|-------------|
| `che-ical-mcp` | macOS Calendar & Reminders via EventKit |

### Skills

| Skill | Description |
|-------|-------------|
| `calendar-management` | Comprehensive guide for calendar operations |

### Commands

| Command | Description |
|---------|-------------|
| `/today` | Show today's events and pending tasks |
| `/week` | Show this week's calendar overview |
| `/quick-event` | Create event from natural language |
| `/remind` | Create reminder from natural language |

## Usage Examples

```
/today                           → See today's schedule
/week                            → Weekly overview
/quick-event Meeting at 2pm      → Create event quickly
/remind Buy groceries tomorrow   → Create reminder
```

Or just ask naturally:
- "What's on my calendar next week?"
- "Create a meeting with John tomorrow at 3pm"
- "Show my pending reminders"
- "Add a reminder to call mom"

## Available Tools (28)

### Calendars (4)
- `list_calendars` - List all calendars
- `create_calendar` - Create new calendar
- `update_calendar` - Update calendar metadata
- `delete_calendar` - Delete calendar

### Events (12)
- `list_events` / `list_events_quick` — list by range or shortcut
- `search_events` — keyword search
- `create_event` / `update_event` / `delete_event` — single ops
- `copy_event` — copy or move event across calendars
- `check_conflicts` — time-overlap detection
- `create_events_batch` / `move_events_batch` / `delete_events_batch` — batch ops
- `find_duplicate_events` — surface duplicates for cleanup

### Reminders (9)
- `list_reminders` / `search_reminders` / `list_reminder_tags`
- `create_reminder` / `update_reminder` / `complete_reminder` / `delete_reminder`
- `create_reminders_batch` / `delete_reminders_batch` — batch ops

### Undo / Redo (3, process-local)
- `undo` / `redo` / `undo_history`

## Permissions

This plugin requires macOS permissions:
- **Calendar**: Read/write access to Calendar.app events
- **Reminders**: Read/write access to Reminders.app tasks

## Version

Plugin version: 1.7.2 (matches MCP server version)

### Changelog

**1.7.2** (2026-04-22)
- Plugin wrapper now version-aware: re-downloads `~/bin/CheICalMCP` when binary lags upstream Release

**1.7.1** (2026-04-20)
- Repo URL migration: kiki830621 → PsychQuant org (no behavior change)

**1.7.0** (2026-04-01)
- Attendee + organizer info exposed on read paths
- Tool count reaches 28 (added `find_duplicate_events`, batch operations, etc.)

**1.6.0** (2026-03-30)
- Tool surface broadened to cover full reminders CRUD + tag listing

**1.5.0** (2026-03-29)
- Per-event timezone support (no longer pinned to system locale)
- Undo / redo on calendar mutations
- 28 tools total

**1.3.x – 1.4.x** (2026-02-22 – 2026-03-23)
- Day-of-week verification PreToolUse hook (catches "Friday 2026-04-26" mismatches)
- i18n SessionStart / current-time helper
- Alarms support on `update_event`

**1.0.0 – 1.2.x** (2026-02-06 – 2026-02-23)
- Initial stable release; iCal binary auto-install + update check

**0.8.x – 0.9.x** (2026-01-30)
- Week boundary calculation fix; `week_starts_on` parameter (`system` / `monday` / `sunday` / `saturday`)
- `update_event` time validation fix; `all_day` parameter

## Author

Created by **Che Cheng** ([@kiki830621](https://github.com/kiki830621))
