# che-ical-mcp Plugin

Claude Code plugin for macOS Calendar & Reminders management using native EventKit.

## Features

- **20 MCP Tools**: Complete calendar and reminder management
- **Skills**: Guided calendar management workflow
- **Commands**: Quick shortcuts for common operations
- **Auto-detection**: Automatically finds installed MCP binary
- **Setup check**: Warns if MCP is not installed on session start
- **i18n Week Support**: Configurable week start day (Monday/Sunday/Saturday/System)

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

## Available Tools (20)

### Calendars
- `list_calendars` - List all calendars
- `create_calendar` - Create new calendar
- `delete_calendar` - Delete calendar

### Events
- `list_events` - List events in date range
- `list_events_quick` - Quick range shortcuts
- `create_event` - Create event
- `update_event` - Update event
- `delete_event` - Delete event
- `search_events` - Search by keywords
- `check_conflicts` - Check time conflicts
- `copy_event` - Copy/move event
- `create_events_batch` - Batch create
- `move_events_batch` - Batch move
- `delete_events_batch` - Batch delete
- `find_duplicate_events` - Find duplicates

### Reminders
- `list_reminders` - List reminders
- `create_reminder` - Create reminder
- `update_reminder` - Update reminder
- `complete_reminder` - Mark complete
- `delete_reminder` - Delete reminder

## Permissions

This plugin requires macOS permissions:
- **Calendar**: Read/write access to Calendar.app events
- **Reminders**: Read/write access to Reminders.app tasks

## Version

Plugin version: 0.8.2 (matches MCP server version)

### Changelog

**0.8.2** (2026-01-30)
- Fixed week boundary calculation (no longer depends on system locale)
- Added `week_starts_on` parameter for international week definitions
- Supports: `system`, `monday` (ISO 8601), `sunday` (US/Japan), `saturday` (Middle East)

**0.8.1** (2026-01-25)
- Fixed `update_event` time validation bug
- Added `all_day` parameter to `update_event`

## Author

Created by **Che Cheng** ([@kiki830621](https://github.com/kiki830621))
