# R Shiny Debugger

R Shiny App debug + adaptive testing tools。

## 命令

| 命令 | 用途 |
|------|------|
| `/shiny-debug` | 單次互動式功能測試 + debug,Log-First 原則 |
| `/shiny-adaptive-walk` | 自我收斂 adaptive testing loop — discover + classify + mutate test infra,real bug 開 `/idd-issue`(MP165 v1.2 Track B) |
| `/connect-cloud-logs` | **部署後** Posit Connect Cloud runtime log 診斷(lag/crash) — `/shiny-debug` 的 remote 版,雙路徑 safari-browser(主)+ agent-browser(network 進階) |

## 特色

- **功能測試導向** — 測試「做 A 應該發生 B」,不只是看 app 能不能跑
- **前後端整合** — 同時觀察 UI 變化和 R console 輸出
- **自然語言測試** — 用口語描述測試目標
- **Adaptive convergence** — 新 `shiny-adaptive-walk` 採 self-converging loop pattern(沿用 `/glue-bridge` MP102 v1.3),iter 直到 CONVERGED / PLATEAUED / DIMINISHING
- **Real bug vs test gap 分流** — adaptive-walk 自動判別 user-visible defect(file `/idd-issue`)vs test infra coverage gap(skill 自動修)
- **Mutation boundary** — adaptive-walk 限定只動 `98_test/e2e/**` + `dashboard_presence_gate.R`,production code 一律走 issue
- **E2E 腳本生成** — `/shiny-debug` 完成後可自動產生 shinytest2 E2E 測試腳本

## 前置需求

```bash
# agent-browser (default for both /shiny-debug and /shiny-adaptive-walk discovery)
npm install -g agent-browser
agent-browser install

# safari-browser (opt-in for /shiny-adaptive-walk --browser safari, macOS only)
# 安裝路徑見 https://github.com/...
# 平常不需要;只在想看 adaptive-walk loop 即時跑(教學 / live demo / 視覺 debug)時才裝。

# R + Shiny
# 確保已安裝 R 和 shiny 套件
```

## 使用

```bash
# 互動 debug 模式
/shiny-debug

# 指定測試目標
/shiny-debug 上傳 CSV 後圖表會更新

# Adaptive testing loop(需要 spectra change adaptive-dashboard-test-loop merged)
/shiny-adaptive-walk QEF_DESIGN                  # default: agent-browser (headless)
/shiny-adaptive-walk QEF_DESIGN --browser safari # opt-in: visible Safari for live watch
/shiny-adaptive-walk D_RACING --budget 50 --max-iter 3

# 部署後 Connect Cloud runtime log 診斷(lag/crash)
/connect-cloud-logs                              # 互動式,問你要看哪個 content
/connect-cloud-logs MAMBA                        # 直接指定公司

# Browser mode rationale: default is headless agent-browser (faster, reproducible,
# no macOS Safari tab-focus contention). --browser safari is opt-in for live demo /
# teaching / in-the-moment visual debugging. See shiny-adaptive-walk.md
# "When to opt into --browser safari" for details.
```

## Tool 對比

| 情境 | 工具 |
|------|------|
| Local dev 單次 debug,知道要測什麼 | `/shiny-debug` |
| Live remote URL verification(Posit Connect)| `safari-browser` CLI 直接調用 |
| **部署後 Connect Cloud runtime log(lag/crash 診斷)** | **`/connect-cloud-logs`** |
| 不知道有什麼 bug,讓 skill 主動探索 + 補 test | `/shiny-adaptive-walk` |
| CI 自動化迴歸 | `shinytest2` test files in `98_test/e2e/` |

## 相關 spectra changes

- `adaptive-dashboard-test-loop`(issue #653)— `/shiny-adaptive-walk` 的 design / spec / tasks source
- `dashboard-presence-verification`(issue #599)— MP165 framework Track A declarative baseline

## 相關 principles

- **MP165** Dashboard Presence as Pipeline Acceptance(v1.2 後含 Track A + Track B 雙軌制)
- **MP102 v1.3** Self-Converging Review pattern(`/glue-bridge` 同源)
- **IC_R011** Commercial Low-Bar Issue Filing(`/shiny-adaptive-walk` 對 real bug 的處理依據)
- `00_principles/.claude/rules/08-shiny-testing.md` 含 default browser rule(local = agent-browser; remote = safari-browser narrow scope;adaptive-walk discovery 是 narrow exception)
