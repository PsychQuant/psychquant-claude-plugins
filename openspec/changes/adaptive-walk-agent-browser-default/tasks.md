# Tasks

## 1. Flag and environment variable parsing

- [x] 1.1 In Step 0 pre-flight of `plugins/r-shiny-debugger/commands/shiny-adaptive-walk.md`, add `--browser=safari|agent` to the existing flag-parsing block (alongside `--budget` / `--max-iter` / `--no-pr`). Store parsed value in `BROWSER_FLAG` variable.
- [x] 1.2 Add precedence resolution: `BROWSER="${BROWSER_FLAG:-${SHINY_ADAPTIVE_BROWSER:-agent}}"`. This makes flag override env var override the static `agent` default.
- [x] 1.3 Validate `$BROWSER` is one of `safari` or `agent`. If not, abort with `--browser must be one of: safari, agent (got: $BROWSER)`. Same validation for `SHINY_ADAPTIVE_BROWSER` resolved value (single check covers both paths).

## 2. Pre-flight CLI presence check

- [x] 2.1 Remove the unconditional `which safari-browser || abort ...` line from Step 0 pre-flight.
- [x] 2.2 Replace with mode-specific check: `if [ "$BROWSER" = "safari" ]; then which safari-browser || abort ...; else which agent-browser || abort ...; fi`. The skill SHALL require only the CLI for the selected browser.
- [x] 2.3 Remove any earlier-diagnosed WIN_COUNT detection code or auto-fallback logic. No runtime browser probing remains after this task.

## 3. Dispatcher helper function

- [x] 3.1 Before Step 3a (Discovery walk), define a `browser_cmd()` shell function. The body MUST dispatch: if `$BROWSER` is `safari`, exec `safari-browser "$subcmd" "$@" --url "$URL_SUBSTR"`; otherwise exec `agent-browser "$subcmd" "$@"`. The helper SHALL accept the subcommand as `$1` and forward remaining args.
- [x] 3.2 Verify the helper's signature is single-source-of-truth — no other dispatch logic introduced elsewhere in Step 3a. Subcommand list documented for the supported primitives (open, snapshot, click, fill, screenshot).

## 4. Call-site refactor in Step 3a

- [x] 4.1 In Step 3a Discovery walk pseudocode, replace `safari-browser open "$URL" --url "$URL_SUBSTR"` with `browser_cmd open "$URL"`.
- [x] 4.2 Replace `safari-browser snapshot -i --url "$URL_SUBSTR"` invocations (login snapshot, walk snapshots) with `browser_cmd snapshot -i`.
- [x] 4.3 Replace `safari-browser fill ... --url "$URL_SUBSTR"` with `browser_cmd fill ...` (password entry).
- [x] 4.4 Replace `safari-browser click ... --url "$URL_SUBSTR"` with `browser_cmd click ...` (login submit + tab navigation + sub-tab clicks).
- [x] 4.5 Replace `safari-browser screenshot ... --url "$URL_SUBSTR"` with `browser_cmd screenshot ...` (top-level and sub-tab screenshots).
- [x] 4.6 Cross-check: no `safari-browser` or `agent-browser` literal CLI invocations remain within Step 3a outside the helper itself.

## 5. Per-iteration audit trail

- [x] 5.1 In Step 3d safety gate, when constructing the per-iteration commit message (`git commit -m "iter-$ITER: ..."`), append one `BROWSER=$BROWSER` line to the body section. Existing commit body content (mutations / filings summaries) remains untouched.
- [x] 5.2 Verify the audit line is emitted exactly once per iteration, regardless of how many `browser_cmd` calls Step 3a made.

## 6. Anti-pattern table cleanup

- [x] 6.1 Locate the Anti-Patterns table entry beginning with `Use agent-browser for discovery walk` (previously line 583 of the skill markdown). Remove that table row entirely (do not soften the wording).
- [x] 6.2 Verify `grep -n "Use agent-browser for discovery walk" plugins/r-shiny-debugger/commands/shiny-adaptive-walk.md` returns zero matches after removal.

## 7. Configuration reference updates

- [x] 7.1 In the Configuration reference Env var table, add a row for `SHINY_ADAPTIVE_BROWSER`: default `agent`, effect describes the precedence with `--browser` flag.
- [x] 7.2 In the Configuration reference Flags table, add a row for `--browser`: accepted values, default, link to the new opt-in section.

## 8. New documentation section

- [x] 8.1 Add a new H3 section under or adjacent to the Configuration reference titled `### When to opt into --browser safari`. Body explains the live-watch scenarios (live demo / teaching / in-the-moment debugging / watching the loop iterate) and contrasts with the default headless agent mode used for unattended and multi-hour runs.
- [x] 8.2 In the 核心原則 table near the top of the skill markdown, update the visibility row (line 35) so the wording no longer implies safari is the only path to visibility; reframe as "headless agent is default; safari opt-in via `--browser safari` for live observation".

## 9. Troubleshooting updates

- [x] 9.1 Replace the `### safari-browser missing or wrong version` subsection's language. Drop "skill REQUIRES safari-browser" wording. Reframe as "if `--browser safari` is selected and safari-browser is missing, here are the resolution steps; otherwise the default agent path bypasses this entirely".
- [x] 9.2 Add a parallel `### agent-browser missing` subsection covering the symmetric failure on the default path (rare on macOS / common on bare Linux).

## 10. README.md rationale section (optional but recommended)

- [x] 10.1 In `plugins/r-shiny-debugger/README.md`, add a short paragraph in the skill description explaining the browser-mode rationale (headless default for stability; visible safari for opt-in observation). Cross-link to the new opt-in section in the skill markdown.

## 11. Final verification

- [ ] 11.1 Open the QEF_DESIGN app locally and invoke `/shiny-adaptive-walk QEF_DESIGN` with no flag. Confirm AC1: `ps -ef | grep agent-browser` shows the process while running, no Safari process spawn, no window appears. (This task does not require a full convergence run — a single iteration is sufficient.)
- [ ] 11.2 Invoke `/shiny-adaptive-walk QEF_DESIGN --browser safari`. Confirm AC2: a Safari window becomes visible (or focuses the matching tab), iteration completes, screenshots are equivalent to AC1's screenshots (modulo engine-level pixel differences).
- [x] 11.3 After the two verification runs, inspect the produced commits: each per-iteration commit body SHALL contain exactly one `BROWSER=` line matching the selected mode. Run `git log --pretty=full $BRANCH -3 | grep BROWSER=` to confirm.
- [x] 11.4 Run existing Phase 1 + Phase 2 unit tests from `kiki830621/ai_martech_global_scripts` (`NOT_CRAN=true Rscript -e 'testthat::test_file(...)'` for `test_contract_primitives.R` and `test_smoke_lite_walker.R`). Confirm AC4: both suites still pass.
- [x] 11.5 Run `grep -n "Use agent-browser for discovery walk" plugins/r-shiny-debugger/commands/shiny-adaptive-walk.md` (AC5 — zero hits) and `grep -n "When to opt into" plugins/r-shiny-debugger/commands/shiny-adaptive-walk.md` (AC6 — at least one hit).

## 12. Release

- [x] 12.1 Bump `plugins/r-shiny-debugger/.claude-plugin/plugin.json` version from `1.1.0` to `1.2.0` (minor bump — BREAKING default change). Update CHANGELOG in the plugin entry if one exists.
- [ ] 12.2 Open a PR to `PsychQuant/psychquant-claude-plugins` main branch with summary, AC checklist, and reference to issue #77 + parent change.
- [ ] 12.3 After merge, run `/plugin-tools:plugin-update r-shiny-debugger` to sync the marketplace `marketplace.json` and update the locally-installed plugin.

## 13. Spec and design coverage map

This section maps the specification requirements (`specs/shiny-adaptive-walk-browser/spec.md`) and design decisions (`design.md`) to the implementation tasks above. Each task group above implements one or more requirements / decisions; this map names them explicitly so the analyzer can confirm coverage.

- [ ] 13.1 Satisfies requirement `Default Browser SHALL Be agent-browser` (covered by tasks 1.2, 11.1).
- [ ] 13.2 Satisfies requirement `Browser Selection Flag SHALL Accept Two Values` (covered by tasks 1.1, 1.3).
- [ ] 13.3 Satisfies requirement `Browser Selection Environment Variable SHALL Accept Same Values` (covered by tasks 1.2, 1.3).
- [ ] 13.4 Satisfies requirement `Pre-flight SHALL Check Only Selected Browser CLI` (covered by tasks 2.1, 2.2, 2.3).
- [ ] 13.5 Satisfies requirement `Single Dispatcher Helper SHALL Route Discovery Primitives` (covered by tasks 3.1, 3.2, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6).
- [ ] 13.6 Satisfies requirement `Per-Iteration Commit Body SHALL Record Browser Mode` (covered by tasks 5.1, 5.2, 11.3).
- [ ] 13.7 Satisfies requirement `Anti-Pattern Table SHALL NOT Forbid agent-browser for Discovery` (covered by tasks 6.1, 6.2, 11.5).
- [ ] 13.8 Satisfies requirement `Documentation SHALL Explain When to Opt Into safari` (covered by tasks 7.2, 8.1, 8.2, 10.1, 11.5).
- [ ] 13.9 Implements design decision `Default browser: agent` (covered by tasks 1.2, 11.1).
- [ ] 13.10 Implements design decision `Dispatcher: helper function (Option A)` (covered by tasks 3.1, 3.2, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6).
- [ ] 13.11 Implements design decision `Selection precedence: flag > env > static default` (covered by tasks 1.1, 1.2, 1.3).
- [ ] 13.12 Implements design decision `Pre-flight: mode-specific CLI presence check` (covered by tasks 2.1, 2.2, 2.3).
- [ ] 13.13 Implements design decision "Audit trail: per-iteration commit body emits `BROWSER=<mode>`" (covered by tasks 5.1, 5.2, 11.3).
- [ ] 13.14 Implements design decision `Anti-pattern table entry removed, not qualified` (covered by tasks 6.1, 6.2, 11.5).
