---
name: cran-guide
description: |
  Search and discover R packages on CRAN by topic or task.
  Use this skill when:
  - User needs to find R packages for a specific task
  - Looking up CRAN Task Views for a domain
  - Checking package dependencies or reverse dependencies
  - Comparing packages for the same purpose
  - User says "what R package for...", "find an R package", "CRAN search"
argument-hint: "[task or domain to find packages for]"
allowed-tools: WebFetch
---

# CRAN Package Discovery Guide

Find and compare R packages via WebFetch.

## When to Use

When the user needs to find the right R package for a task, or wants to explore what's available.

## Execution Steps (IMPORTANT!)

**You MUST WebFetch official sources - never recommend packages from memory alone!**

### Step 1: Identify the domain or task

The user's query: $ARGUMENTS

### Step 2: WebFetch relevant sources

**For domain exploration — CRAN Task Views:**

| Domain | URL |
|--------|-----|
| Bayesian | `https://cran.r-project.org/web/views/Bayesian.html` |
| ClinicalTrials | `https://cran.r-project.org/web/views/ClinicalTrials.html` |
| Cluster | `https://cran.r-project.org/web/views/Cluster.html` |
| Databases | `https://cran.r-project.org/web/views/Databases.html` |
| Econometrics | `https://cran.r-project.org/web/views/Econometrics.html` |
| ExperimentalDesign | `https://cran.r-project.org/web/views/ExperimentalDesign.html` |
| Finance | `https://cran.r-project.org/web/views/Finance.html` |
| HighPerformanceComputing | `https://cran.r-project.org/web/views/HighPerformanceComputing.html` |
| MachineLearning | `https://cran.r-project.org/web/views/MachineLearning.html` |
| MetaAnalysis | `https://cran.r-project.org/web/views/MetaAnalysis.html` |
| MixedModels | `https://cran.r-project.org/web/views/MixedModels.html` |
| NaturalLanguageProcessing | `https://cran.r-project.org/web/views/NaturalLanguageProcessing.html` |
| Psychometrics | `https://cran.r-project.org/web/views/Psychometrics.html` |
| ReproducibleResearch | `https://cran.r-project.org/web/views/ReproducibleResearch.html` |
| Spatial | `https://cran.r-project.org/web/views/Spatial.html` |
| Survival | `https://cran.r-project.org/web/views/Survival.html` |
| TimeSeries | `https://cran.r-project.org/web/views/TimeSeries.html` |
| WebTechnologies | `https://cran.r-project.org/web/views/WebTechnologies.html` |

**Full list of Task Views:**
`https://cran.r-project.org/web/views/`

**For a specific package:**
`https://cran.r-project.org/web/packages/{pkg}/index.html`

**For package search:**
- `https://www.rdocumentation.org/search?q={query}`
- `https://rdrr.io/search?q={query}`

### Step 3: Present recommendations

```
## Recommended Packages for {Task}

| Package | Description | Downloads | Maintained |
|---------|-------------|-----------|------------|
| {pkg1} | ... | ... | ... |
| {pkg2} | ... | ... | ... |

### Recommendation
[Which package to use and why]

### Installation
```r
install.packages(c("{pkg1}", "{pkg2}"))
```
```

## Important Reminders

- **Always WebFetch** CRAN or Task Views - don't recommend packages from memory
- Check if packages are actively maintained (last update date)
- Mention if a package is part of tidyverse or has known alternatives
