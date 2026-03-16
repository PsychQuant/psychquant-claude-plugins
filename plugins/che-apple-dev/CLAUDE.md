# che-apple-dev

Apple platform development toolkit for Claude Code.

## Skills

| Skill | 用途 | 觸發詞 |
|-------|------|--------|
| `build-deploy` | Build + deploy 到 Mac 或 iPad | "build", "deploy", "install on device" |
| `debug-crash` | Console capture 診斷 crash | "crashed", "閃退", "debug crash" |
| `device-manage` | 裝置管理、TCC 權限 | "list devices", "reset permissions" |

## MCP Integration

Works with `che-xcode-mcp` MCP server (130 tools) for low-level operations.
Skills in this plugin orchestrate multiple MCP calls into high-level workflows.
