---
name: tidyverse-guide
description: |
  Query tidyverse package documentation (dplyr, ggplot2, tidyr, purrr, readr, stringr, forcats, tibble, lubridate).
  Use this skill proactively when the conversation involves:
  - tidyverse packages or pipe workflows (%>%, |>)
  - dplyr verbs (filter, mutate, summarise, group_by, join)
  - ggplot2 plotting (geom_, aes, theme, scale_)
  - tidyr reshaping (pivot_longer, pivot_wider, nest, unnest)
  - purrr functional programming (map, walk, reduce)
  - readr/readxl data import
  - stringr string manipulation
  - lubridate date/time handling
argument-hint: "[tidyverse package or function to look up]"
allowed-tools: WebFetch
---

# Tidyverse Docs Guide

Query tidyverse package documentation directly via WebFetch.

## When to Use

When the user works with any tidyverse package or asks about tidy data workflows.

## Execution Steps (IMPORTANT!)

**You MUST WebFetch official documentation - never answer from memory!**

### Step 1: Identify the package and function

The user's query: $ARGUMENTS

### Step 2: WebFetch from the correct pkgdown site

**Tidyverse package sites:**

| Package | Reference URL | Cheatsheet |
|---------|--------------|------------|
| dplyr | `https://dplyr.tidyverse.org/reference/index.html` | `https://dplyr.tidyverse.org/articles/dplyr.html` |
| ggplot2 | `https://ggplot2.tidyverse.org/reference/index.html` | `https://ggplot2.tidyverse.org/articles/ggplot2.html` |
| tidyr | `https://tidyr.tidyverse.org/reference/index.html` | `https://tidyr.tidyverse.org/articles/tidy-data.html` |
| purrr | `https://purrr.tidyverse.org/reference/index.html` | `https://purrr.tidyverse.org/articles/base.html` |
| readr | `https://readr.tidyverse.org/reference/index.html` | — |
| stringr | `https://stringr.tidyverse.org/reference/index.html` | — |
| forcats | `https://forcats.tidyverse.org/reference/index.html` | — |
| tibble | `https://tibble.tidyverse.org/reference/index.html` | — |
| lubridate | `https://lubridate.tidyverse.org/reference/index.html` | — |
| readxl | `https://readxl.tidyverse.org/reference/index.html` | — |
| haven | `https://haven.tidyverse.org/reference/index.html` | — |
| glue | `https://glue.tidyverse.org/reference/index.html` | — |

**For a specific function:**
`https://{pkg}.tidyverse.org/reference/{function}.html`

**For articles/vignettes:**
`https://{pkg}.tidyverse.org/articles/`

### Step 3: Present findings

Include: function signature, parameters, return value, and a working example from the docs.

## Important Reminders

- **Always WebFetch** the pkgdown site - never answer from memory
- tidyverse functions are well-documented with examples; always include them
- If a function doesn't exist on the pkgdown site, fall back to `https://www.rdocumentation.org/packages/{pkg}/topics/{function}`
