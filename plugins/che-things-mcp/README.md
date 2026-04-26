# che-things-mcp Plugin

Claude Code plugin for Things 3 task management via AppleScript.

## Features

- **47 MCP Tools**: Complete task, project, area, and tag management
- **Skills**: Comprehensive task management workflow guide
- **Commands**: Quick shortcuts for common operations
- **Auto-detection**: Automatically finds installed MCP binary
- **Setup check**: Warns if MCP is not installed on session start

## Installation

### Step 1: Install MCP Server (if not already installed)

```bash
# Download the binary
mkdir -p ~/bin
curl -L https://github.com/kiki830621/che-things-mcp/releases/latest/download/CheThingsMCP -o ~/bin/CheThingsMCP
chmod +x ~/bin/CheThingsMCP
```

Or download `.mcpb` from [Releases](https://github.com/kiki830621/che-things-mcp/releases) for one-click install.

On first use, macOS will prompt for **Accessibility** permission for AppleScript - click "Allow".

### Step 2: Install Plugin

#### Method A: Plugin Directory (Development)

```bash
claude --plugin-dir /path/to/che-things-mcp/plugin
```

#### Method B: Add to Settings

Add to `~/.claude/settings.json`:

```json
{
  "plugins": [
    "/path/to/che-things-mcp/plugin"
  ]
}
```

## How It Works

The plugin automatically detects your MCP installation from these locations:
- `~/bin/CheThingsMCP`
- `/usr/local/bin/che-things-mcp`
- `~/Library/Application Support/Claude/mcp-servers/che-things-mcp/` (MCPB)

A **SessionStart hook** checks if the MCP is properly installed and shows setup instructions if needed.

## Included Components

### MCP Server

| Server | Description |
|--------|-------------|
| `che-things-mcp` | Things 3 task management via AppleScript |

### Skills

| Skill | Description |
|-------|-------------|
| `task-management` | Comprehensive guide for Things 3 operations |

### Commands

| Command | Description |
|---------|-------------|
| `/today` | Show today's tasks |
| `/inbox` | Show inbox items |
| `/quick-task` | Create task from natural language |
| `/projects` | List all projects with task counts |
| `/upcoming` | Show upcoming scheduled tasks |

## Usage Examples

```
/today                        → See today's tasks
/inbox                        → View unprocessed items
/quick-task Buy groceries     → Quick task creation
/projects                     → Project overview
/upcoming                     → Future schedule
```

Or just ask naturally:
- "What's on my todo list today?"
- "Add a task to buy milk tomorrow"
- "Show my work projects"
- "Complete the task about meeting notes"

## Available Tools (47)

### List Access
- `get_inbox` - Inbox items
- `get_today` - Today's tasks
- `get_upcoming` - Scheduled tasks
- `get_anytime` - Anytime tasks
- `get_someday` - Someday tasks
- `get_logbook` - Completed tasks

### Task CRUD
- `add_todo` - Create task
- `update_todo` - Update task
- `complete_todo` - Complete task
- `delete_todo` - Delete task
- `search_todos` - Search tasks
- `cancel_todo` - Cancel task

### Project Management
- `get_projects` - List projects
- `add_project` - Create project
- `update_project` - Update project
- `delete_project` - Delete project
- `cancel_project` - Cancel project

### Area & Tag Management
- `get_areas` / `add_area` / `update_area` / `delete_area`
- `get_tags` / `add_tag` / `update_tag` / `delete_tag`

### Batch Operations
- `create_todos_batch` - Create multiple tasks
- `complete_todos_batch` - Complete multiple tasks
- `delete_todos_batch` - Delete multiple tasks
- `move_todos_batch` - Move multiple tasks
- `update_todos_batch` - Update multiple tasks

### Move Operations
- `move_todo` - Move task to list/project
- `move_project` - Move project to area

### UI Control
- `show_todo` - Show task in Things 3
- `show_project` - Show project in Things 3
- `show_list` - Show list in Things 3
- `show_quick_entry` - Open Quick Entry panel
- `edit_todo` - Edit task in Things 3
- `edit_project` - Edit project in Things 3

### Checklist Management
- `add_checklist_items` - Add checklist items
- `set_checklist_items` - Replace checklist items

### Advanced Queries
- `get_todos_in_project` - Tasks in specific project
- `get_todos_in_area` - Tasks in specific area
- `get_projects_in_area` - Projects in specific area
- `get_selected_todos` - Currently selected tasks

### Utility
- `empty_trash` - Empty Things 3 trash
- `log_completed_now` - Move completed to Logbook
- `set_auth_token` - Set auth token for URL Scheme
- `check_auth_status` - Check auth token status

## Permissions

This plugin requires macOS permissions:
- **Accessibility**: Required for AppleScript to control Things 3

## Version

Plugin version: 1.6.2 (matches MCP server version)

### Changelog

- **1.6.2** (2026-04-22) — Wrapper auto-download now version-aware (re-downloads when `~/bin/CheThingsMCP` lags upstream)
- **1.6.1** — Earlier patch releases tracked in [upstream CHANGELOG](https://github.com/PsychQuant/che-things-mcp/blob/main/CHANGELOG.md)

## Author

Created by **Che Cheng** ([@kiki830621](https://github.com/kiki830621))
