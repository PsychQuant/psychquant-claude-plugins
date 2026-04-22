# plugin-tools

Claude Code Plugin 完整生命週期工具。

## vs Anthropic 官方 plugin-dev

|  | 官方 plugin-dev | plugin-tools |
|--|----------------|--------------|
| 定位 | **教學型** — 教你 plugin 結構怎麼寫 | **執行型** — 直接幫你建好、同步好、開好 issue |
| 建立 plugin | 提供結構指南，你自己建 | 一個指令建完：目錄、manifest、CLAUDE.md、marketplace.json |
| marketplace | 不處理 | 自動更新 marketplace.json + commit + push |
| Issue 追蹤 | 不處理 | 自動在 GitHub 開 issue 追蹤開發進度 |
| 維運 | 不處理 | health check、debug、update 三件套 |
| 轉換 | 提供遷移指南 | 一個指令把 `.claude/skills/` 轉成 plugin |

兩者互補：官方教原理，這個做執行。

## Skills

| Skill | 用途 |
|-------|------|
| `plugin-create` | 建立新 plugin 或從現有 skill 轉換（含 marketplace 同步、CLAUDE.md、GitHub Issue） |
| `plugin-upgrade` | 改善現有 plugin 的能力（匯入 rules/skills、補 hooks 格式、重生 CLAUDE.md）|
| `plugin-deploy` | 發布到 Anthropic 官方 marketplace（pre-flight check + 開啟提交頁） |
| `plugin-update` | 修改 plugin 後同步到 marketplace + 更新安裝 |
| `plugin-health` | 檢查所有已安裝 plugin 的健康狀態 |
| `plugin-debug` | 深度除錯單一 plugin 的問題 |

### README Freshness Gate（v1.13.0）

`plugin-update` 和 `plugin-deploy` 都會檢查 `README.md` 是否跟上 `plugin.json` 版本 / 新工具 / CHANGELOG：

| Skill | Stale 時行為 | 理由 |
|-------|-----------|------|
| `plugin-update` Phase 2.5 | **ASK**（三選項：更新 / 已 OK / 稍後）| 日常同步常有 README 暫時落後 |
| `plugin-deploy` Step 2.6 | minor/major bump → **BLOCK**；patch → warn | 正式發布 = 文件必須對齊版本號 |

偵測信號：README 沒提到新版本字串、README mtime 早於 code 改動、CHANGELOG 最新 entry 版本沒進 README。

## Plugin Lifecycle

```
plugin-create → 開發/測試 → plugin-update → plugin-deploy → plugin-health → plugin-debug
    ↑                                              |
    └── 有問題？ ←─────────────────────────────────┘
```

## Usage

```bash
# 從零建立新 plugin
/plugin-tools:plugin-create my-plugin

# 從現有 skill 轉換（合併多個 skill）
/plugin-tools:plugin-create convert codex-review issue

# 修改後同步
/plugin-tools:plugin-update my-plugin

# 健康檢查
/plugin-tools:plugin-health

# 除錯
/plugin-tools:plugin-debug my-plugin
```

## Install

透過 PsychQuant marketplace：

```bash
/plugin marketplace add https://github.com/PsychQuant/psychquant-claude-plugins
/plugin install plugin-tools
```
