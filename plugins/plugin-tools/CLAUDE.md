# plugin-tools — CLAUDE.md

## Purpose

Plugin 維運工具：健康檢查、除錯、更新同步。

## 建立新 Plugin 的流程

本 plugin 專注於**維運**（health, debug, update），**不包含**建立新 plugin 的流程。

建立新 plugin 請參考 Anthropic 官方的 plugin 開發工具包：

- **GitHub**: https://github.com/anthropics/claude-plugins-official/tree/main/plugins/plugin-dev
- **安裝**: 已透過 `claude-plugins-official` marketplace 安裝
- **Skills**:
  - `/plugin-dev:create-plugin` — 引導式建立完整 plugin
  - `/plugin-dev:plugin-structure` — plugin 目錄結構和 manifest 規範
  - `/plugin-dev:skill-development` — skill 撰寫指南
  - `/plugin-dev:agent-development` — agent 撰寫指南
  - `/plugin-dev:hook-development` — hook 撰寫指南
  - `/plugin-dev:command-development` — command 撰寫指南
  - `/plugin-dev:mcp-integration` — MCP server 整合
  - `/plugin-dev:plugin-settings` — `.local.md` 設定模式

## Plugin 標準結構（快速參考）

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json          ← 唯一必要檔案
├── skills/                  ← SKILL.md files
├── commands/                ← slash commands
├── agents/                  ← agent definitions
├── hooks/                   ← hooks.json
├── .mcp.json                ← MCP servers
├── settings.json            ← default settings
└── README.md                ← 建議加（分享前）
```

## 本 plugin 的 Skills

| Skill | 用途 |
|-------|------|
| `/plugin-tools:create-plugin` | 建立新 plugin（含 marketplace 同步、CLAUDE.md、GitHub Issue） |
| `/plugin-tools:plugin-health` | 檢查所有 plugin 健康狀態 |
| `/plugin-tools:plugin-debug` | 深度除錯單一 plugin |
| `/plugin-tools:plugin-update` | 更新 plugin 到最新版本 |

## Plugin 生命週期

```
create-plugin → 開發/測試 → plugin-update → plugin-health → plugin-debug
    ↑                                              |
    └── 有問題？ ←─────────────────────────────────┘
```
