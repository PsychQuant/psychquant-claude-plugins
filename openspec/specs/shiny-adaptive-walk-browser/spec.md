# shiny-adaptive-walk-browser Specification

## Purpose

TBD - created by archiving change 'adaptive-walk-agent-browser-default'. Update Purpose after archive.

## Requirements

### Requirement: Default Browser SHALL Be agent-browser

The `/shiny-adaptive-walk` skill SHALL use `agent-browser` (headless Chromium) for the discovery walk phase when no explicit browser is specified via flag or environment variable. The skill SHALL NOT use `safari-browser` as the default.

#### Scenario: Default invocation with no overrides

- **WHEN** the user invokes `/shiny-adaptive-walk <COMPANY>` with no `--browser` flag and no `SHINY_ADAPTIVE_BROWSER` environment variable set
- **THEN** the skill SHALL invoke `agent-browser` for all discovery walk primitives (open, snapshot, click, fill, screenshot)
- **AND** the skill SHALL NOT spawn or focus a `safari-browser` window
- **AND** the per-iteration commit body SHALL contain the line `BROWSER=agent`

---
### Requirement: Browser Selection Flag SHALL Accept Two Values

The skill SHALL accept a `--browser` flag with exactly two valid values: `safari` and `agent`. The flag SHALL be parsed alongside existing flags (`--budget`, `--max-iter`, `--no-pr`) in the Step 0 pre-flight phase.

#### Scenario: Explicit safari selection via flag

- **WHEN** the user invokes `/shiny-adaptive-walk <COMPANY> --browser safari`
- **THEN** the skill SHALL invoke `safari-browser` for the discovery walk
- **AND** the skill SHALL pass `--url "$URL_SUBSTR"` to every safari-browser subcommand for tab targeting
- **AND** the per-iteration commit body SHALL contain the line `BROWSER=safari`

#### Scenario: Explicit agent selection via flag

- **WHEN** the user invokes `/shiny-adaptive-walk <COMPANY> --browser agent`
- **THEN** the skill SHALL invoke `agent-browser` for the discovery walk
- **AND** the per-iteration commit body SHALL contain the line `BROWSER=agent`

#### Scenario: Invalid --browser value

- **WHEN** the user invokes `/shiny-adaptive-walk <COMPANY> --browser chrome`
- **THEN** the skill SHALL abort in Step 0 pre-flight with an error message naming the accepted values
- **AND** no app launch SHALL occur

##### Example: Invalid value error

- **GIVEN** invocation `/shiny-adaptive-walk QEF_DESIGN --browser firefox`
- **WHEN** Step 0 pre-flight parses the flag
- **THEN** the skill exits non-zero with a message containing `--browser must be one of: safari, agent (got: firefox)`

---
### Requirement: Browser Selection Environment Variable SHALL Accept Same Values

The skill SHALL accept a `SHINY_ADAPTIVE_BROWSER` environment variable with the same value domain as the `--browser` flag (`safari` or `agent`). The flag SHALL take precedence over the environment variable when both are set.

#### Scenario: Environment variable sets safari mode

- **WHEN** the user invokes `SHINY_ADAPTIVE_BROWSER=safari /shiny-adaptive-walk <COMPANY>` with no `--browser` flag
- **THEN** the skill SHALL invoke `safari-browser` for the discovery walk

#### Scenario: Flag overrides environment variable

- **WHEN** the user invokes `SHINY_ADAPTIVE_BROWSER=safari /shiny-adaptive-walk <COMPANY> --browser agent`
- **THEN** the skill SHALL invoke `agent-browser` for the discovery walk

##### Example: Precedence table

| Flag        | Env var                      | Effective browser |
| ----------- | ---------------------------- | ----------------- |
| (unset)     | (unset)                      | agent (default)   |
| (unset)     | SHINY_ADAPTIVE_BROWSER=safari| safari            |
| (unset)     | SHINY_ADAPTIVE_BROWSER=agent | agent             |
| --browser=safari | (unset)                 | safari            |
| --browser=agent  | SHINY_ADAPTIVE_BROWSER=safari | agent (flag wins) |
| --browser=safari | SHINY_ADAPTIVE_BROWSER=agent  | safari (flag wins) |

---
### Requirement: Pre-flight SHALL Check Only Selected Browser CLI

Step 0 pre-flight SHALL verify the presence of the CLI for the selected browser. The skill SHALL NOT require both CLIs to be present.

#### Scenario: agent-browser CLI missing while safari is selected

- **WHEN** the user invokes `/shiny-adaptive-walk <COMPANY> --browser safari` on a system where `agent-browser` is missing but `safari-browser` is present
- **THEN** the skill SHALL proceed past pre-flight (because `agent-browser` is not needed for this invocation)
- **AND** the discovery walk SHALL succeed using `safari-browser`

#### Scenario: safari-browser CLI missing while default is in effect

- **WHEN** the user invokes `/shiny-adaptive-walk <COMPANY>` with no overrides on a system where `safari-browser` is missing but `agent-browser` is present (e.g. Linux CI)
- **THEN** the skill SHALL proceed past pre-flight (because `safari-browser` is not needed for the default agent path)
- **AND** the discovery walk SHALL succeed using `agent-browser`

#### Scenario: Selected browser CLI missing

- **WHEN** the user invokes `/shiny-adaptive-walk <COMPANY> --browser safari` on a system where `safari-browser` is missing
- **THEN** the skill SHALL abort in Step 0 pre-flight with an error naming the missing CLI

---
### Requirement: Single Dispatcher Helper SHALL Route Discovery Primitives

The skill SHALL define a single shell helper function (`browser_cmd`) before Step 3a that routes the discovery primitives to the selected browser CLI. All call sites within Step 3a SHALL invoke primitives through this helper, not by direct `safari-browser` or `agent-browser` invocation.

#### Scenario: Helper dispatches to safari with --url flag

- **WHEN** the helper is invoked as `browser_cmd open "$URL"` and the selected browser is safari
- **THEN** the helper SHALL execute `safari-browser open "$URL" --url "$URL_SUBSTR"`

#### Scenario: Helper dispatches to agent without --url flag

- **WHEN** the helper is invoked as `browser_cmd open "$URL"` and the selected browser is agent
- **THEN** the helper SHALL execute `agent-browser open "$URL"`
- **AND** the helper SHALL NOT pass any `--url` argument to `agent-browser`

##### Example: Dispatch table

| Helper call                    | safari mode resolves to                                                | agent mode resolves to                |
| ------------------------------ | ---------------------------------------------------------------------- | ------------------------------------- |
| `browser_cmd open "$URL"`      | `safari-browser open "$URL" --url "$URL_SUBSTR"`                       | `agent-browser open "$URL"`           |
| `browser_cmd snapshot -i`      | `safari-browser snapshot -i --url "$URL_SUBSTR"`                       | `agent-browser snapshot -i`           |
| `browser_cmd click @e2`        | `safari-browser click @e2 --url "$URL_SUBSTR"`                         | `agent-browser click @e2`             |
| `browser_cmd fill @e1 VIBE`    | `safari-browser fill @e1 VIBE --url "$URL_SUBSTR"`                     | `agent-browser fill @e1 VIBE`         |
| `browser_cmd screenshot file`  | `safari-browser screenshot file --url "$URL_SUBSTR"`                   | `agent-browser screenshot file`       |

---
### Requirement: Per-Iteration Commit Body SHALL Record Browser Mode

Each per-iteration commit produced by the skill (matching the existing `iter-N: <summary> (refs #<parent>)` title format) SHALL contain exactly one `BROWSER=<safari|agent>` line in the commit message body.

#### Scenario: Default agent invocation records BROWSER=agent

- **WHEN** the skill completes iteration N with default browser selection (no flag, no env var)
- **THEN** `git log --pretty=fuller -1 HEAD` body SHALL contain a line equal to `BROWSER=agent`

#### Scenario: Explicit safari invocation records BROWSER=safari

- **WHEN** the skill completes iteration N with `--browser safari`
- **THEN** `git log --pretty=fuller -1 HEAD` body SHALL contain a line equal to `BROWSER=safari`

---
### Requirement: Anti-Pattern Table SHALL NOT Forbid agent-browser for Discovery

The skill markdown's Anti-Patterns table SHALL NOT contain an entry forbidding the use of `agent-browser` for the discovery walk phase.

#### Scenario: Anti-pattern entry removed

- **WHEN** a reader greps the skill markdown for the prior anti-pattern text `Use agent-browser for discovery walk`
- **THEN** the search SHALL return zero matches

---
### Requirement: Documentation SHALL Explain When to Opt Into safari

The skill markdown SHALL include a section explaining the scenarios in which `--browser safari` is the appropriate choice (live demo / teaching / in-the-moment debugging / watching the loop iterate). The section SHALL be placed within or adjacent to the Configuration reference section.

#### Scenario: Section exists

- **WHEN** a reader greps the skill markdown for the heading `When to opt into`
- **THEN** the search SHALL return at least one match within the Configuration area
