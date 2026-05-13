## Context

`/shiny-adaptive-walk` is a Claude Code slash-command skill in `plugins/r-shiny-debugger` that drives the MP165 v1.2 Track B adaptive overlay for the QEF dashboard verification system. It runs a multi-iteration self-converging loop: each iteration walks a Shiny dashboard, classifies defects via an LLM judge, and either files them as bugs (real_bug) or mutates the test infrastructure (test_infra_gap). The loop typically targets 5 companies (QEF_DESIGN / D_RACING / MAMBA / WISER / kitchenMAMA) and can take multiple hours.

The skill's Step 3a (Discovery walk) currently hard-codes `safari-browser` as the browser driver, with `which safari-browser || abort ...` in pre-flight (Step 0). The skill markdown frames this as "real renderer ground truth" and includes an Anti-pattern table entry explicitly forbidding `agent-browser` for discovery.

During a manual execution on 2026-05-13 (kiki830621/ai_martech_global_scripts#665), the safari-only mandate broke for environmental reasons unrelated to the dashboard under test: parallel ChatGPT usage stole tab focus, the user-profile-bound Safari context caused reproducibility drift, and per-iteration Safari startup added latency. The operator switched to `agent-browser` mid-walk to complete the iteration. The `/spectra-discuss` session that followed established that:

- Both `safari-browser` (WebKit) and `agent-browser` (headless Chromium) render real DOM. For Shiny apps using bs4Dash + plotly + DT, engine-level rendering differences are effectively zero.
- The only genuine differentiator is realtime visibility — `safari-browser` shows the loop iterating in a visible window; `agent-browser` is headless.
- Realtime visibility delivers value only when a human is actively watching. For unattended / CI / multi-hour runs, visibility is worth nothing while headlessness is worth latency reduction and reproducibility gains.

The skill's default therefore points at the wrong tool. This design captures the inversion.

## Goals / Non-Goals

**Goals:**

- Make `agent-browser` the default for the discovery walk so unattended and multi-hour invocations are stable + fast by default.
- Provide an explicit opt-in (`--browser safari`) for the live-watch scenario without breaking that path.
- Capture the rationale persistently so future maintainers don't re-instate the safari-mandatory framing.
- Document a single source of truth for browser dispatch (helper function) so future changes to the browser layer touch one spot.

**Non-Goals:**

- Not introducing auto-detection or auto-fallback. Mode is explicit (flag > env > static default). The earlier diagnosis suggested probing Safari window count to decide — rejected because `agent-browser` is no longer a "fallback", it is the default, so there is nothing to probe for.
- Not supporting a third browser (e.g. native Chrome, Firefox). The plugin already chose safari + agent as its supported pair.
- Not unifying the mechanical regression phase (Step 3d safety gate) with the discovery walk's browser choice. Mechanical regression has always used `agent-browser` and continues to — it is not user-facing visibility, so safari was never a valid option there.
- Not making the dispatcher pluggable for arbitrary browser CLIs. The dispatcher knows exactly two backends; extensibility is YAGNI.

## Decisions

### Default browser: agent

`/shiny-adaptive-walk` default browser is `agent-browser` (headless Chromium). `safari-browser` is opt-in via `--browser safari`.

**Rationale**: The `/spectra-discuss` analysis showed `safari-browser`'s "real renderer ground truth" framing was Safari-bias rather than fact. Both engines render real DOM; for the dashboard under test, no engine-specific rendering differences matter. The genuine advantage of safari (realtime visibility) only applies when a human watches the loop iterate, which is not the dominant use case (Phase 5 cross-co rollout is multi-hour and unattended). Defaulting to safari forces every unattended invocation to pay startup latency, fight tab-focus contention, and inherit user-profile state drift, in exchange for visibility that nobody is consuming.

**Alternative considered**: keep `safari-browser` as default and add auto-fallback to `agent-browser` when pre-flight detects multiple Safari windows or missing CLI. Rejected because the "fallback" framing treats agent as inferior, which the analysis rejected. Auto-fallback also introduces a runtime heuristic (window count threshold) whose threshold is arbitrary — `> 1`, `> 2`, or some focus-aware probe each have boundary cases the other misses. Explicit selection removes the entire class of pre-flight ambiguity.

### Dispatcher: helper function (Option A)

A single `browser_cmd()` shell function dispatches discovery primitives. All ~14 `safari-browser X --url "$URL_SUBSTR"` call sites in Step 3a become `browser_cmd X`.

```bash
browser_cmd() {
  local subcmd="$1"; shift
  if [ "$BROWSER" = "safari" ]; then
    safari-browser "$subcmd" "$@" --url "$URL_SUBSTR"
  else
    agent-browser "$subcmd" "$@"
  fi
}
```

**Rationale**: Discovery primitives (open / snapshot / click / fill / screenshot) map 1:1 between the two CLIs by subcommand name. The only meaningful API difference is `--url "$URL_SUBSTR"` for safari tab targeting, which agent doesn't need (single ephemeral context). A 10-line helper consolidates the dispatch logic, replaces 14 call-site rewrites with 14 trivial substitutions, and gives future browser-related changes a single edit point.

**Alternatives considered**:

- **Option B (inline if/else at each call site)**: rejected. Doubles Step 3a from ~60 lines to ~120 lines, repeats the same conditional 14 times, and any future browser-layer change requires touching 14 places. No upside.
- **Option C (function-per-primitive: `discovery_open()` / `discovery_login()` / `discovery_walk_tab()` etc.)**: rejected for over-abstraction. The primitives are thin wrappers around a single CLI invocation each; wrapping them in another function tier adds indirection without behavioral abstraction. Suitable if the discovery layer grew much more complex; YAGNI for the current scope.

### Selection precedence: flag > env > static default

```
1. `--browser=safari|agent` flag (highest)
2. `SHINY_ADAPTIVE_BROWSER` environment variable
3. Static default: `agent`
```

**Rationale**: Standard CLI / 12-factor convention. Flag overrides env (per-invocation override of session-wide setting); env overrides default (lets shells / CI configure once). Unknown values (anything other than `safari` or `agent`) abort with an error in both flag and env path.

**Alternative considered**: a binary `--watch` flag (presence implies safari, absence implies agent). Rejected on naming grounds: `--watch` is commonly understood as file-system watching, would mislead users. `--browser=mechanism` is more explicit and survives future browser additions without rename.

### Pre-flight: mode-specific CLI presence check

Pre-flight (Step 0) checks browser CLI presence for the **selected** browser only:

- `--browser safari` → require `safari-browser` CLI, abort if missing.
- `--browser agent` (default) → require `agent-browser` CLI, abort if missing.

Drop the WIN_COUNT detection and `safari-browser documents` parsing entirely.

**Rationale**: Each mode has exactly one CLI dependency. The WIN_COUNT heuristic was meaningful only when safari was default and agent was fallback (deciding when to fall back). With explicit selection, the heuristic has no decision to inform.

### Audit trail: per-iteration commit body emits `BROWSER=<mode>`

Each per-iteration commit (existing `iter-N: ... (refs #N)` format) gains one line in the commit body: `BROWSER=safari` or `BROWSER=agent`. No fallback-reason logging (no fallback exists). Final report does not duplicate this — commit history is the single source of truth.

**Rationale**: Cheapest possible audit trail. Per-iteration commits already exist for atomic rollback; adding one line is free. Future debugging of "why did iter 3 produce different screenshots than iter 2" can grep commit history. Avoids verbosity in the final report.

### Anti-pattern table entry removed, not qualified

Line 583 of the skill markdown (`Use agent-browser for discovery walk → Use safari-browser`) is removed outright, not softened to "Use agent-browser when safari unavailable". Adding a new "When to opt into `--browser safari`" section in the Configuration area replaces it.

**Rationale**: A qualified anti-pattern entry still implies agent is inferior. The conclusion from `/spectra-discuss` was that agent is the default. Keeping a softened entry would invite future regression toward safari-mandatory behavior.

## Implementation Contract

**Observable behavior after this change ships:**

- Invoking `/shiny-adaptive-walk <COMPANY>` with no `--browser` flag and no `SHINY_ADAPTIVE_BROWSER` env var uses headless `agent-browser` for the discovery walk. The Shiny app being walked sees a Chromium user agent. No Safari window appears on screen.
- Invoking `/shiny-adaptive-walk <COMPANY> --browser safari` uses `safari-browser`. A Safari window becomes visible (or focuses an existing one matching the URL). The skill continues to use `--url "$URL_SUBSTR"` for tab targeting in safari mode.
- Invoking with `SHINY_ADAPTIVE_BROWSER=safari` (no flag) is equivalent to `--browser safari`. Flag overrides env when both are set.
- Invoking `/shiny-adaptive-walk <COMPANY> --browser agent` with `agent-browser` CLI missing aborts pre-flight with a message naming the missing CLI. Same shape of failure as before for safari, just for the other CLI.
- Each per-iteration commit body contains exactly one `BROWSER=<safari|agent>` line. Auditors can grep `git log --grep "BROWSER=" --pretty=fuller` over the loop's branch to see which browser drove which iteration.

**Interface / contracts:**

- `--browser` flag accepts exactly two values: `safari` or `agent`. Any other value (including empty string, mixed case, `chrome`, etc.) aborts with an error naming the accepted values.
- `SHINY_ADAPTIVE_BROWSER` env var has the same value domain and same error shape on invalid input.
- `browser_cmd()` shell helper signature: `browser_cmd <subcmd> [args...]`. Subcommand is forwarded to the chosen CLI verbatim. Caller does not pass `--url` — the helper supplies it for safari mode.
- Anti-pattern table no longer contains an entry for `agent-browser` for discovery walk.
- New section heading "When to opt into `--browser safari`" appears under the Configuration heading in the skill markdown.

**Failure modes:**

- Selected browser CLI missing → abort in Step 0 with `<CLI> required (pass --browser=<other> to switch)`. No silent fallback. No retry.
- Invalid `--browser` value → abort with `--browser must be one of: safari, agent (got: X)`. No silent normalization (no auto-correcting `Safari` → `safari`).
- Invalid `SHINY_ADAPTIVE_BROWSER` value → same shape as above, but error message names the env var.
- `browser_cmd()` invoked with a subcommand that one of the CLIs does not support → the underlying CLI's own error surfaces (e.g. `safari-browser: unknown command 'foo'`). Helper does not pre-validate subcommands. Documentation lists the supported primitive set.

**Acceptance criteria:**

- AC1: `/shiny-adaptive-walk QEF_DESIGN` with no flag and no env var completes a single iteration using headless Chromium. `ps` during execution shows an `agent-browser` process, no Safari process spawn. No window appears.
- AC2: `/shiny-adaptive-walk QEF_DESIGN --browser safari` completes a single iteration with a visible Safari window (or focused existing tab). Same screenshots produced (modulo engine-level pixel-perfect differences). Same commit shape.
- AC3: Each per-iteration commit body contains exactly one `BROWSER=` line, matching the selected mode.
- AC4: Existing Phase 1 unit tests (`98_test/test_contract_primitives.R`) and Phase 2 walker tests (`98_test/test_smoke_lite_walker.R`) continue to pass after the skill markdown change. (These tests do not depend on the skill markdown directly, so this is a regression guard rather than direct coverage.)
- AC5: `grep -n "Use agent-browser for discovery walk" plugins/r-shiny-debugger/commands/shiny-adaptive-walk.md` returns zero hits after the change.
- AC6: `grep -n "When to opt into \`--browser safari\`" plugins/r-shiny-debugger/commands/shiny-adaptive-walk.md` returns one hit.

**Scope boundaries:**

In scope:
- Skill markdown: Step 0 (pre-flight), Step 3a (discovery walk dispatcher), Anti-pattern table, Configuration reference, Troubleshooting, new "When to opt into `--browser safari`" section, frontmatter description if it references "safari-browser".
- README rationale section (optional but recommended for plugin marketplace consumers reading the README first).

Out of scope:
- `kiki830621/ai_martech_global_scripts` `00_principles/.claude/rules/08-shiny-testing.md` narrow exception clause (consistency only — clause stays accurate as written).
- Mechanical regression phase (Step 3d) browser choice.
- `/shiny-debug` sister skill (different lifecycle — single-pass interactive, never adaptive).
- Plugin-marketplace versioning (`plugin.json` bump) — handled by `/plugin-update` separately if needed.

## Risks / Trade-offs

- **[Live-watch users surprised by headless default]** → Mitigation: add prominent "When to opt into `--browser safari`" section near top of skill markdown; mention in release notes for the plugin version bump. Default change is BREAKING and called out explicitly in proposal What Changes.
- **[Per-iteration commit body bloat]** → Mitigation: one `BROWSER=` line is ~15 bytes; over a typical 5-iteration converge that's 75 bytes total. Negligible.
- **[Engine-specific edge cases surface only when running safari]** → Mitigation: when a user explicitly opts into safari, they accept it. Default-agent users get Chromium consistently. If a future bug emerges that only reproduces in WebKit, the opt-in path is available.
- **[Dispatcher leaks `--url` to environments that don't want it]** → Mitigation: helper only appends `--url` in safari mode; agent path never sees it. Single source of truth makes future audit easy.
- **[Migration friction for in-flight `/shiny-adaptive-walk` invocations]** → Mitigation: no in-flight automation calls this skill yet; today's manual invocations all set their own `--browser` if needed. No data migration involved.
