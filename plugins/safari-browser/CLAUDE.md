## MCP Server

This plugin includes an MCP server (`safari-browser-channel`) defined in `.mcp.json`.
It provides:
- `safari_action` tool — execute any safari-browser CLI command from within Claude Code
- `safari_monitor_pause/resume/status` tools — control the vision monitor loop
- Channel push events (`page_change`) when `SB_CHANNEL_MONITOR=1` is set

The server runs via Bun: `bun channel/channel.ts`

## Bun

Default to using Bun instead of Node.js.

- Use `bun <file>` instead of `node <file>` or `ts-node <file>`
- Use `bun test` instead of `jest` or `vitest`
- Use `bun install` instead of `npm install` or `yarn install` or `pnpm install`

## Design Principle: Non-Interference

All safari-browser commands default to non-interference — users can do other things simultaneously.

- No mouse/keyboard control unless `--allow-hid` / `--native`
- No system dialogs
- No sounds (`screencapture -x`)
- No window focus stealing

New commands must be classified by interference level before implementation.
Full spec: project repo `openspec/specs/non-interference/spec.md`
