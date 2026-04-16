# plugin-tools — CLAUDE.md

## Purpose

Claude Code Plugin 完整生命週期工具：建立、更新、健康檢查、除錯。

## 參考資源

Skill 的寫法參考 Anthropic 官方 plugin 開發工具包：

- **GitHub**: https://github.com/anthropics/claude-plugins-official/tree/main/plugins/plugin-dev
- **官方 Skills**（教學型）：`/plugin-dev:plugin-structure`、`/plugin-dev:skill-development` 等
- **本 plugin**（執行型）：直接建好、同步好、開好 issue

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
| `/plugin-tools:plugin-create` | 建立新 plugin（含 marketplace 同步、CLAUDE.md、GitHub Issue） |
| `/plugin-tools:plugin-deploy` | 發布 plugin 到 Anthropic 官方 marketplace（pre-flight check + 開啟提交頁） |
| `/plugin-tools:plugin-health` | 檢查所有 plugin 健康狀態 |
| `/plugin-tools:plugin-debug` | 深度除錯單一 plugin |
| `/plugin-tools:plugin-update` | 更新 plugin 到最新版本 |

## Plugin 生命週期

```
plugin-create → 開發/測試 → plugin-update → plugin-deploy → plugin-health → plugin-debug
    ↑                                              |
    └── 有問題？ ←─────────────────────────────────┘
```

## Rules

| Rule | 何時適用 |
|------|---------|
| [mcp-binary-distribution.md](rules/mcp-binary-distribution.md) | MCP Server 是編譯型 binary（Swift / Rust / Go…）— 必須走 GitHub Release + wrapper 自動下載，否則修 bug 使用者收不到 |
