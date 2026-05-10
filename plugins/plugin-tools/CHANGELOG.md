# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> ⚠ This file was bootstrapped by `changelog-tools:changelog-init` from the
> `plugin.json` description field. Section categorization is best-effort —
> review and refine `Added` / `Changed` / `Fixed` etc. as needed.

## [Unreleased]

## [1.16.0] - 2026-05-10

### Added
- **`plugin-update` Phase 0.5 git-state confirmation gate (#60)**:在 Phase 0(detect marketplace)與 Phase 1(detect changes)之間插入新 phase。讀 only preview block 顯示 `git status --short` + `git log origin..HEAD` + divergence count,接 5-case AskUserQuestion dispatch:
  - **Case A** clean + 0 unpushed → abort with "nothing to push"(trivially correct)
  - **Case B** clean + N unpushed → default `push N as-is`(unambiguous happy path)
  - **Case C** dirty + 0 unpushed → default `abort`(skill 不擅自決定要 commit 什麼);options: stage-all / manual-stage-subset / abort
  - **Case D** dirty + N unpushed → default `abort`(4 種 sensible 動作對應不同意圖,user 必須明確選);options: push-N-leave-dirty / amend-into-HEAD / commit-as-new-commit / abort
  - **Case E** origin diverged → default `abort`(conflict resolution 是 user 的工作);options: fetch+rebase+push / fetch+merge+push / abort
- **idd-all unattended mode handler**:env var detect → auto-abort with structured error,return non-zero exit。idd-all 在 final report 標 "plugin-update skipped under unattended mode"。同 idd-diagnose Step 3.4 F unattended pattern。
- **Cross-plugin commits warn-only**(Tier A scope):若 unpushed commits touch 多個 plugin,heads-up print only(不 refuse)。Active scope guard 留給 follow-up issue #65。
- **Edge case abort handling**:detached HEAD / no upstream tracking / incomplete rebase-merge state → 各自 abort with structured error,don't try to handle。

### Changed
- **`plugin-update` Phase 1 Step 2 deprecated → reference**:既有 lines 93-106 的 narrative advisory「請先 commit + push」(沒實際 gate)替換為 one-liner 指向 Phase 0.5。Pre-v1.16.0 此 step 印 `git status` 後接 reminder text,AI executor 可以 print 後繼續;v1.16.0 升格為 explicit AskUserQuestion 5-case dispatch。
- **Step 0 stage TaskList** 新增 `git_state_gate` 條目,排在 `detect_marketplace` 之後、`detect_changes` 之前。

### Notes
- Plugin minor bump 1.15.0 → 1.16.0(new feature surface,additive,backward compat — explicit-pin user 行為不變)。Plan 走 IDD `/idd-plan #60` approval gate,EnterPlanMode 已 user-approved 後才 chain to implement。
- **Tier A only** scope:Tier B(commit message auto-draft + dialog)+ Tier C(active cross-plugin scope guard with `marketplace.json` allowlist)deferred until Tier A UX validated。
- **Relationship to IDD `pr_policy`**:orthogonal axes — `pr_policy` 控制 development-time PR-vs-direct-commit 決定(during `idd-implement`);Phase 0.5 控制 release-time push-or-abort 決定(during `plugin-update`)。Phase 0.5 不 consult / 不 override `pr_policy`,documented 在 phase intro。
- Out-of-scope follow-ups already filed:**#63** (apply pattern to plugin-deploy / plugin-create — same plugin-tools family);**#65** (apply pattern to mcp-tools:mcp-deploy / cli-tools:cli-deploy — cross-marketplace);**#64** (CHANGELOG `[1.15.0]` placeholder date drift,pre-existing,unrelated);**#58** (post-marketplace-sync stale-MCP-PID warning,complementary lifecycle-end angle)。

## [1.15.0] - 2026-04-26

### Added
- **README Freshness Gate v2** — 從 3 信號擴展到 6,新增 3 偵測 + 2 suppressions,從跨 28 plugin 大規模 audit 萃取的盲點(commit `60f8cab`):
  - **s4 Component inventory drift**:每個 `skills/` / `agents/` / `commands/` 下的 component 必須在 README 被 reference(backtick / slash / namespaced slash / agent at-form / bold list 任一)。Catches issue-driven-dev 5 listed vs 10 actual + mcp-tools 漏列 mcp-issue/mcp-publish/mcp-to-plugin。
  - **s5 Tool count drift**:parse `(N tools)` / `(N MCP tools)` / `Available Tools (N)` / `N 個工具` from README header,對比 plugin.json description 的 tool count 宣稱。Catches che-ical-mcp(README 說 20、description 說 28)。
  - **s6 Version history multi-version gap**:scan git log 找最近 90 天 same-major versions,對比 README Version History table。容忍 1 個 missing(可能 patch / internal),2+ 同 major missing 觸發 gate。Catches che-duckdb-mcp(v2.0 → v2.2.1 中 v2.1.0/v2.1.1/v2.2.0 漏列)。
- **2 suppressions**:
  - `no-version-section` — plugin 刻意不維護 Version History section 時 suppress version-related signals
  - `wrapper-only commits` — commits 只動 `bin/*-wrapper.sh` 視為 binary version sync,不觸發 README staleness gate

### Notes
- Backfilled per **#64** (sister concern from #60) — original v1.15.0 release on 2026-04-26 used `changelog-tools:changelog-init` placeholder `(date unknown — please fill in)` 而沒填入。Date verified via `git show -s 60f8cab`;description detail backfilled from commit body + original `marketplace.json` description。
