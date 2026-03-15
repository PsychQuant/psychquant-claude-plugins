---
name: r-docs-guide
description: |
  Query R package documentation across all ecosystems at once (CRAN, tidyverse, Bioconductor).
  Use this skill when:
  - Looking up R package usage, functions, or vignettes
  - Comparing packages for the same task (e.g., data.table vs dplyr)
  - User says "R docs", "how to use this R package", or asks about R functions
  - Need to find the right R package for a task
argument-hint: "[package name or topic to look up]"
allowed-tools: WebFetch
---

# R Docs Guide

Query R package documentation directly via WebFetch across multiple sources.

## When to Use

When the user asks about R packages, functions, or needs help with R programming tasks.

## Execution Steps (IMPORTANT!)

**You MUST WebFetch official documentation - never answer from memory!**

### Step 1: Identify the package or topic

The user's query: $ARGUMENTS

### Step 2: Determine the best documentation source

| Source | URL Pattern | Best For |
|--------|------------|----------|
| CRAN Reference | `https://cran.r-project.org/web/packages/{pkg}/index.html` | Package overview, links |
| CRAN Manual (PDF) | `https://cran.r-project.org/web/packages/{pkg}/{pkg}.pdf` | Full function reference |
| Vignettes | `https://cran.r-project.org/web/packages/{pkg}/vignettes/` | Tutorials, guides |
| RDocumentation | `https://www.rdocumentation.org/packages/{pkg}` | Searchable docs |
| tidyverse pkgdown | `https://{pkg}.tidyverse.org/` | tidyverse packages |
| Shiny | `https://shiny.posit.co/r/reference/` | Shiny framework |
| Bioconductor | `https://bioconductor.org/packages/release/bioc/html/{pkg}.html` | Bioinformatics |
| R Documentation | `https://stat.ethz.ch/R-manual/R-devel/library/{pkg}/html/00Index.html` | Base R packages |
| CRAN Task Views | `https://cran.r-project.org/web/views/{topic}.html` | Find packages by domain |
| rdrr.io | `https://rdrr.io/cran/{pkg}/` | Quick function lookup |

### Step 3: WebFetch the documentation

For a **specific package**, fetch in parallel:
1. CRAN page: `https://cran.r-project.org/web/packages/{pkg}/index.html`
2. RDocumentation: `https://www.rdocumentation.org/packages/{pkg}`
3. If tidyverse: `https://{pkg}.tidyverse.org/reference/index.html`

For a **topic/task** (e.g., "how to do time series in R"):
1. CRAN Task View: `https://cran.r-project.org/web/views/{relevant-view}.html`
2. RDocumentation search: `https://www.rdocumentation.org/search?q={query}`

For a **specific function**:
1. `https://www.rdocumentation.org/packages/{pkg}/topics/{function}`
2. Or `https://rdrr.io/cran/{pkg}/man/{function}.html`

### Step 4: Present findings

```
## {Package Name}

**Version:** x.y.z | **CRAN:** [link] | **Docs:** [link]

### Description
[What the package does]

### Key Functions
| Function | Description |
|----------|-------------|
| `func()` | ... |

### Installation
```r
install.packages("{pkg}")
```

### Quick Example
```r
library({pkg})
# example code
```

### Related Packages
- [alternatives or companions]
```

## Common CRAN Task Views

| Domain | Task View URL |
|--------|--------------|
| Time Series | `https://cran.r-project.org/web/views/TimeSeries.html` |
| Machine Learning | `https://cran.r-project.org/web/views/MachineLearning.html` |
| Bayesian | `https://cran.r-project.org/web/views/Bayesian.html` |
| Spatial | `https://cran.r-project.org/web/views/Spatial.html` |
| Finance | `https://cran.r-project.org/web/views/Finance.html` |
| Clinical Trials | `https://cran.r-project.org/web/views/ClinicalTrials.html` |
| Psychometrics | `https://cran.r-project.org/web/views/Psychometrics.html` |
| Survival | `https://cran.r-project.org/web/views/Survival.html` |
| Web Technologies | `https://cran.r-project.org/web/views/WebTechnologies.html` |
| Reproducible Research | `https://cran.r-project.org/web/views/ReproducibleResearch.html` |

## Important Reminders

- **Always WebFetch** - never answer R package questions from memory
- **Check version** - R packages update frequently, always get current docs
- **Vignettes first** - vignettes are often more useful than function reference
- If a package is not on CRAN, check Bioconductor or GitHub
