# APA Citation Guide: Practical Implementation with BibLaTeX

## Overview

This guide provides practical instructions for implementing APA 7th edition citations using the `biblatex-apa` package. It complements our axiomatization system by showing how to apply the formal rules in actual LaTeX documents.

## Setup Requirements

### Prerequisites
- BibLaTeX ≥ 3.14
- Biber ≥ 2.14 (backend)
- csquotes ≥ 4.3
- LuaLaTeX or XeLaTeX (recommended for better Unicode support)

### Basic Document Setup

```latex
\usepackage[american]{babel}
\usepackage{csquotes}
\usepackage[style=apa]{biblatex}
\addbibresource{references.bib}
```

Or with polyglossia:

```latex
\usepackage{polyglossia}
\setdefaultlanguage[variant=american]{english}
\usepackage{csquotes}
\usepackage[style=apa]{biblatex}
```

## Citation Commands

### Basic Citation Types

| Command | Output Format | Example | Use Case |
|---------|--------------|---------|----------|
| `\parencite{key}` | (Author, Year) | (Smith, 2020) | Standard parenthetical citation |
| `\textcite{key}` | Author (Year) | Smith (2020) | Narrative citation |
| `\citeauthor{key}` | Author | Smith | Author only |
| `\citeyear{key}` | Year | 2020 | Year only |
| `\citetitle{key}` | Title | *Book Title* | Title only |

### Special Citation Commands

#### Citations Within Parentheses
When citing within parentheses, use `\nptextcite` to avoid double parentheses:

```latex
% Instead of: (see (Smith, 2020))
(see \nptextcite{smith2020})  % Output: (see Smith, 2020)
```

**Note**: With LuaLaTeX, this is handled automatically when using `\textcite`.

#### Multiple Citations
```latex
\parencite{smith2020,jones2021,brown2019}
% Output: (Brown, 2019; Jones, 2021; Smith, 2020)
```

#### Citations with Page Numbers
```latex
\parencite[p.~25]{smith2020}
\parencite[pp.~25--30]{smith2020}
\textcite[Chapter 3]{jones2021}
```

### Advanced Citation Features

#### Pre/Post Notes
```latex
\parencite[see][for more details]{smith2020}
% Output: (see Smith, 2020, for more details)
```

#### Full Citations
```latex
\fullcite{smith2020}     % Full citation inline
\fullcitebib{smith2020}  % Full citation with bibliography formatting
```

## Entry Types and Fields

### Common Entry Types

| Entry Type | Use For | Required Fields |
|------------|---------|-----------------|
| `@article` | Journal articles | author, title, journaltitle, year |
| `@book` | Books | author/editor, title, publisher, year |
| `@incollection` | Book chapters | author, title, booktitle, publisher, year |
| `@inproceedings` | Conference papers | author, title, booktitle, year |
| `@online` | Web resources | author/title, url, year |
| `@report` | Technical reports | author, title, institution, year |
| `@thesis` | Dissertations | author, title, institution, year, type |

### Special Fields for APA

#### Entry Subtypes
Use `entrysubtype` to specify document types:
```bibtex
@article{...,
  entrysubtype = {nonacademic},  % For newspaper articles
}
```

#### Publication States
```bibtex
@article{...,
  pubstate = {inpress},      % "in press"
  howpublished = {mansub},   % "Manuscript submitted for publication"
}
```

Available publication states:
- `inpress` - In press
- `manunpub` - Unpublished manuscript
- `maninprep` - Manuscript in preparation
- `mansub` - Manuscript submitted for publication

#### Author Annotations
Use Biber's annotation feature for special roles:

```bibtex
@book{example2020,
  author = {Smith, John[role=editor] and Jones, Mary[username=@mjones]},
}
```

Common annotations:
- `role` - Special role (Editor, Translator, Narrator)
- `username` - Social media username

## Date Formatting

### Standard Dates
```bibtex
date = {2020-03-15},      % ISO format preferred
date = {2020-03/2020-05}, % Date ranges
date = {2020-21},         % Winter season
date = {2020},            % Year only
```

### No Date
```bibtex
date = {},          % Will display as "n.d."
```

## DOI and URL Formatting

### DOI Preferred
```bibtex
doi = {10.1037/xxxxx},  % Automatically formatted as URL
```

### URLs When No DOI
```bibtex
url = {https://example.com},
urldate = {2020-03-15},  % Access date
```

## Group Authors

### With Abbreviation
```bibtex
@report{apa2020,
  author = {{American Psychological Association} {[APA]}},
  shortauthor = {APA},
}
```

First citation: (American Psychological Association [APA], 2020)  
Subsequent: (APA, 2020)

### Without Abbreviation
```bibtex
@report{who2020,
  author = {{World Health Organization}},
}
```

## Special Cases

### Anonymous Works
```bibtex
@book{anon2020,
  author = {Anonymous},  % Literally "Anonymous"
  % or
  author = {},          % No author given
}
```

### Classical Works
```bibtex
@book{aristotle,
  author = {Aristotle},
  title = {Poetics},
  translator = {Butcher, S. H.},
  year = {1907},
  origdate = {-0350},  % circa 350 BCE
}
```

### Legal References
See APA manual section 11 for detailed legal citation formats. Use specialized entry types:
- `@legislation`
- `@legal`
- `@jurisdiction`

## Common Issues and Solutions

### Issue: Double Parentheses
**Problem**: `(see \parencite{smith2020})` produces `(see (Smith, 2020))`  
**Solution**: Use `\nptextcite` or switch to LuaLaTeX

### Issue: Corporate Author Sorting
**Problem**: "The Corporation" sorts under "T"  
**Solution**: Use `sortname` field:
```bibtex
author = {{The Corporation}},
sortname = {Corporation},
```

### Issue: Title Capitalization
**Problem**: Titles need sentence case in references  
**Solution**: BibLaTeX handles this automatically. Use normal title case in .bib file:
```bibtex
title = {The Great Book of Examples},  % Correct
% NOT: title = {The great book of examples},
```

## Package Options

```latex
\usepackage[style=apa,apamaxprtauth=20]{biblatex}
```

- `apamaxprtauth` - Maximum authors to print (default: 20)

## Compilation Workflow

1. Compile with LuaLaTeX/XeLaTeX: `lualatex document.tex`
2. Run Biber: `biber document`
3. Compile again: `lualatex document.tex`
4. Compile once more: `lualatex document.tex`

## Integration with Our Axiomatization

This practical guide implements the formal rules defined in our axiomatization system:

- **Tense Rules** (Chapter 4): Applied automatically in citations
- **Voice Rules** (Chapter 4): Narrative vs parenthetical citations
- **JARS Requirements**: Entry types and fields map to JARS axioms
- **Formatting Axioms**: Implemented by biblatex-apa style files

For the theoretical foundation, see:
- `chapter4_writing_style_axiomatization.md`
- `jars_axiomatization.md`
- `jars_detailed_requirements.md` 