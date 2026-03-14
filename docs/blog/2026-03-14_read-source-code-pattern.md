# Read Source Code at Runtime, Not Cache It

> 2026-03-14 | Pattern: Live Source Code Reading

## The Problem

AI agents constantly face outdated knowledge. Training data has a cutoff, documentation lags behind releases, and cached reference files go stale the moment a package updates.

The typical workaround — saving documentation or API specs locally — creates a maintenance burden: you have to remember to update your cached copy every time the upstream changes. You won't remember. The cache will drift.

## The Pattern: Read Source Code Live

Instead of caching documentation, **read the actual source code at runtime** when you need authoritative answers.

This pattern is already built into several of our plugins:

### 1. ai-docs-guide / claude-config-guide — WebFetch official docs

```
# SKILL.md instruction:
"You MUST WebFetch official documentation - never answer from memory!"

# Example:
WebFetch("https://developers.openai.com/docs/api-reference/responses")
```

The skill forces the AI to fetch the latest documentation every time, rather than relying on training data that may be months old. No local cache to maintain.

### 2. Plotly + Shiny Module — Read R package source code

This is the case that made the pattern click.

**The problem**: We needed plotly click events to work inside a Shiny module for map drill-down. The plotly documentation doesn't explain how `event_data()` interacts with Shiny module namespacing. Stack Overflow answers were contradictory. AI models hallucinated plausible-but-wrong solutions.

**What we did**: Read the actual plotly R package source code at runtime.

```bash
# Find the source file
find /Library/Frameworks/R.framework -name "*.R" -path "*/plotly/*" \
  -exec grep -l "event_data" {} \;

# Read event_data() implementation
Rscript -e "body(plotly::event_data)"

# Read the JavaScript event handler
cat /Library/Frameworks/R.framework/.../plotly/htmlwidgets/plotly.js | \
  grep -A 50 "eventDataWithKey"
```

**What we found** (none of this is in the docs):

1. **Source IDs use root session input** — `Shiny.setInputValue(event + "-" + source, ...)` bypasses module namespace. Fix: `source = session$ns("worldmap")`

2. **Choropleth click events don't include `$location`** — The JS `eventDataWithKey()` function only extracts `curveNumber`, `pointNumber`, `x`, `y`, `z`, `customdata`, `key`. Location codes must be passed via `customdata`.

3. **Default priority deduplicates clicks** — `priority = "input"` means clicking the same country twice won't fire the second time. Fix: `priority = "event"`

**Three bugs, zero documentation, solved by reading ~100 lines of source code.**

## Why Not Cache the Source Code?

You might think: "Let's save these findings in a reference file so we don't have to read the source again."

Don't.

1. **plotly updates** — The next version might change `eventDataWithKey()` to include `location`. Your cached reference would tell you it doesn't, leading you to add unnecessary `customdata` workarounds.

2. **R version changes** — Package installation paths change between R versions. A hardcoded path in your cache breaks silently.

3. **The read is fast** — `Rscript -e "body(plotly::event_data)"` takes 200ms. There's no performance reason to cache.

4. **The source is the truth** — Documentation describes intent. Source code describes reality. When they disagree, source wins.

## When to Use This Pattern

| Situation | Approach |
|-----------|----------|
| "How does this API work?" | WebFetch official docs (ai-docs-guide) |
| "How does this package handle X internally?" | Read installed package source code |
| "What fields does this event return?" | Read the JS/R source that constructs the event |
| "Does this function support parameter Y?" | `Rscript -e "formals(package::function)"` |
| "What's the default behavior of Z?" | `Rscript -e "body(package::function)"` |

## What to Cache vs What to Read Live

| Cache (save locally) | Read live (never cache) |
|----------------------|------------------------|
| Your own principles and rules | Package source code |
| Project-specific conventions | API documentation |
| Architectural decisions (ADRs) | Function signatures |
| Domain knowledge that doesn't change | Dependency behavior |

The dividing line: **cache what you control, read live what others control.**

## Implementation in Claude Code Plugins

The pattern maps naturally to plugin skills:

```yaml
# SKILL.md frontmatter
allowed-tools: WebFetch, Read, Glob, Grep, Bash
```

- **WebFetch**: Official documentation URLs
- **Read + Glob + Grep**: Local package source files
- **Bash**: `Rscript -e "..."` for R introspection, `node -e "..."` for JS

The skill instruction forces the behavior:
```
"You MUST read the source — never answer from memory!"
```

This single line prevents the most common AI failure mode: confidently wrong answers based on stale training data.

## Real-World Impact

| Metric | Without pattern | With pattern |
|--------|----------------|--------------|
| Iterations to fix plotly click | Would have been 10+ (trial and error) | 3 (read source, found 3 bugs, fixed) |
| Time to understand event_data | Hours of Stack Overflow + guessing | 2 minutes reading ~100 lines |
| Confidence in fix | Low (works but don't know why) | High (understand the mechanism) |
| Future maintenance | Fragile (might break on update) | Robust (can re-read source) |

## Related

- [ai-docs-guide plugin](../plugins/ai-docs-guide/) — WebFetch official docs pattern
- [claude-config-guide plugin](../plugins/claude-config-guide/) — Read + WebFetch hybrid pattern
- [Issue #352](https://github.com/kiki830621/ai_martech_global_scripts/issues/352) — Plotly + Shiny Module knowledge document
- [Discussion #353](https://github.com/kiki830621/ai_martech_global_scripts/discussions/353) — Full drill-down implementation record
