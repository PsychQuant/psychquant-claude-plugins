---
name: shiny-guide
description: |
  Query Shiny framework documentation for building interactive web applications in R.
  Use this skill proactively when the conversation involves:
  - Shiny app development (ui, server, reactive)
  - Shiny UI components (fluidPage, navbarPage, tabsetPanel)
  - Reactive programming (reactive, observe, eventReactive, reactiveVal)
  - Shiny modules (moduleServer, NS)
  - shinydashboard, bslib, shinyWidgets
  - Deploying Shiny apps (shinyapps.io, Posit Connect)
  - R Shiny debugging, testing (shinytest2)
argument-hint: "[Shiny topic or function to look up]"
allowed-tools: WebFetch
---

# Shiny Docs Guide

Query Shiny framework documentation directly via WebFetch.

## When to Use

When the user builds or debugs Shiny applications.

## Execution Steps (IMPORTANT!)

**You MUST WebFetch official documentation - never answer from memory!**

### Step 1: Identify the topic

The user's query: $ARGUMENTS

### Step 2: WebFetch from the correct source

**Shiny documentation sources:**

| Topic | URL |
|-------|-----|
| Shiny R Reference | `https://shiny.posit.co/r/reference/shiny/latest/` |
| Shiny R Articles | `https://shiny.posit.co/r/articles/` |
| Shiny R Gallery | `https://shiny.posit.co/r/gallery/` |
| bslib (Bootstrap) | `https://rstudio.github.io/bslib/reference/index.html` |
| shinydashboard | `https://rstudio.github.io/shinydashboard/` |
| shinyWidgets | `https://dreamrs.github.io/shinyWidgets/reference/index.html` |
| shinytest2 | `https://rstudio.github.io/shinytest2/reference/index.html` |
| Mastering Shiny (book) | `https://mastering-shiny.org/` |
| DT (DataTables) | `https://rstudio.github.io/DT/` |
| plotly for R | `https://plotly-r.com/` |

**By topic:**

| Topic | URL |
|-------|-----|
| Reactivity | `https://shiny.posit.co/r/articles/build/reactivity-overview/` |
| Modules | `https://shiny.posit.co/r/articles/improve/modules/` |
| Layout Guide | `https://shiny.posit.co/r/articles/build/layout-guide/` |
| Dynamic UI | `https://shiny.posit.co/r/articles/build/dynamic-ui/` |
| Deployment | `https://shiny.posit.co/r/articles/share/` |
| Performance | `https://shiny.posit.co/r/articles/improve/performance/` |
| Testing | `https://rstudio.github.io/shinytest2/articles/shinytest2.html` |

### Step 3: Present findings

Include working code examples with both ui and server components.

## Important Reminders

- **Always WebFetch** - Shiny API changes between versions
- Always show both `ui` and `server` parts in examples
- For deployment questions, check `https://shiny.posit.co/r/articles/share/`
