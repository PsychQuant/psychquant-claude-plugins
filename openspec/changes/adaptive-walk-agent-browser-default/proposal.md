## Why

The `/shiny-adaptive-walk` skill (in `plugins/r-shiny-debugger`) currently mandates `safari-browser` for the discovery walk phase and hard-aborts if it is missing. The original rationale framed `safari-browser` as "real renderer ground truth", positioning `agent-browser` as a lesser substitute. Field experience (kiki830621/ai_martech_global_scripts#665 walker run on 2026-05-13) showed this framing is inaccurate: both `safari-browser` (WebKit) and `agent-browser` (headless Chromium) render real DOM and produce equally valid screenshots for LLM-judge classification. The genuine differences are:

- `agent-browser`: headless, faster, reproducible (ephemeral context, no user profile contamination), immune to macOS Safari tab-focus contention.
- `safari-browser`: provides realtime visibility for a human watching the loop iterate.

Realtime visibility only matters when a user is present. For unattended, multi-hour, or cross-company runs (Phase 5 cross-co rollout target: QEF_DESIGN / D_RACING / MAMBA / WISER / kitchenMAMA), visibility delivers zero value while focus-stealing and per-iteration Safari startup overhead degrade reliability. The default therefore points at the wrong tool, forcing every user (including the AI itself during manual orchestration) to work around an opinion that does not survive scrutiny.

## What Changes

- **BREAKING**: Default browser for `/shiny-adaptive-walk` discovery walk changes from `safari-browser` to `agent-browser`. Invocations that previously implicitly relied on `safari-browser` continue to work but now use `agent-browser` unless explicitly overridden.
- Introduce `--browser=safari|agent` flag for explicit selection. `agent` is the default; `safari` is opt-in for "I want to watch the loop iterate" scenarios (live demo, teaching, in-the-moment debugging).
- Introduce `SHINY_ADAPTIVE_BROWSER` environment variable accepting the same values (`safari` / `agent`). Precedence: `--browser` flag > `SHINY_ADAPTIVE_BROWSER` env var > default (`agent`).
- Introduce `browser_cmd()` shell helper that dispatches one set of discovery primitives (open / snapshot / click / fill / screenshot) to either `safari-browser` (with `--url "$URL_SUBSTR"` flag for tab targeting) or `agent-browser` (headless, single context).
- Replace `which safari-browser || abort ...` pre-flight check (Step 0) with two-mode logic: if `--browser safari` is selected, fail loudly when `safari-browser` CLI is absent; if `--browser agent` (default), only verify `agent-browser` CLI presence.
- Remove the WIN_COUNT detection / auto-fallback logic suggested in earlier diagnoses of this issue (no longer needed once `agent-browser` is the default — there is nothing to fall back to).
- Anti-pattern table entry "Use `agent-browser` for discovery walk → Use `safari-browser`" (line 583 of the skill markdown) is removed. Using `agent-browser` for discovery is no longer an anti-pattern; it is the recommended default.
- Add a new "When to opt into `--browser safari`" section to the skill markdown documenting when realtime visibility justifies the trade-off.
- Update the Configuration reference table to add `--browser` flag and `SHINY_ADAPTIVE_BROWSER` env var rows.
- Update Troubleshooting to remove "skill REQUIRES safari-browser" language; replace with guidance on each browser mode's failure surfaces.
- Per-iteration commit message body emits one `BROWSER=<safari|agent>` line for audit-trail traceability (which browser produced the iteration's evidence).

## Non-Goals

- This change does NOT modify the mechanical regression phase (Step 3d safety gate); it has always used `agent-browser` and continues to.
- This change does NOT introduce any browser other than `safari-browser` or `agent-browser`. Future support for additional browsers (e.g. native Chrome / Firefox) is explicitly out of scope.
- This change does NOT introduce auto-detection or auto-fallback between modes. Mode is determined explicitly by `--browser` flag, then `SHINY_ADAPTIVE_BROWSER` env, then the static default (`agent`). No runtime environment probing.
- This change does NOT modify the LLM-judge classification logic, the dedup/sister-bug filing logic, or the convergence model. Browser selection is orthogonal to all downstream phases.
- This change does NOT alter the cross-reference in `kiki830621/ai_martech_global_scripts` `00_principles/.claude/rules/08-shiny-testing.md` narrow exception clause. That clause says "safari-browser is permitted on local for adaptive-walker discovery"; it remains accurate (safari is still permitted, just no longer the default).

## Capabilities

### New Capabilities

- `shiny-adaptive-walk-browser`: Browser selection contract for the shiny-adaptive-walk skill's discovery walk phase. Defines the `--browser` flag, `SHINY_ADAPTIVE_BROWSER` env var, the default (`agent`), the dispatcher helper, and the audit-trail emission per iteration.

### Modified Capabilities

(none — the shiny-adaptive-walk skill does not yet have an explicit spec in the openspec specs directory; this change creates the first formal contract for one aspect of the skill)

## Impact

- Affected specs:
  - New: `openspec/specs/shiny-adaptive-walk-browser/spec.md`
- Affected code:
  - Modified: `plugins/r-shiny-debugger/commands/shiny-adaptive-walk.md` (Step 0 pre-flight, Step 3a discovery walk dispatcher, Anti-pattern table, Configuration reference, Troubleshooting)
  - Modified: `plugins/r-shiny-debugger/README.md` (optional — add browser-mode rationale section near skill description)
  - New: (none — single-file refactor)
  - Removed: (none)
- Downstream behavior:
  - Manual or AI-driven `/shiny-adaptive-walk QEF_DESIGN` invocations now headless-by-default. Live observation requires explicit `--browser safari`.
  - Existing local CI invocations remain functional; they previously failed if `safari-browser` was missing, now succeed (the abort path is gone for the default mode).
