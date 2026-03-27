# BibTeX to APA 7th Edition Conversion Guide

This guide explains how to use the provided BibTeX examples to generate proper APA 7th edition citations and references.

## Required Setup

### LaTeX Packages
```latex
\documentclass{article}
\usepackage[style=apa,backend=biber]{biblatex}
\DeclareLanguageMapping{american}{american-apa}
\addbibresource{your-bibliography.bib}
```

### Biber Configuration
APA style requires Biber as the backend (not BibTeX). Ensure your LaTeX editor is configured to use Biber.

## Step-by-Step Process

### 1. Choose Your Examples
Navigate to the appropriate folder:
- **Citations**: Use `01_Citation_Examples/` for in-text citation formats
- **References**: Use `02_Reference_Types/` for reference list entries
- **Formatting**: Use `03_Formatting_Rules/` for special formatting cases

### 2. Copy Relevant Entries
Copy BibTeX entries from the example files to your `.bib` file. For example:

```bibtex
@ARTICLE{mccauley2019,
  AUTHOR         = {S. M. McCauley and M. H. Christiansen},
  TITLE          = {Language Learning as Language Use},
  SUBTITLE       = {A Cross-linguistic Model of Child Language Development},
  JOURNALTITLE   = {Psychological Review},
  VOLUME         = {126},
  NUMBER         = {1},
  PAGES          = {1--51},
  DATE           = {2019},
  DOI            = {10.1037/rev0000126}
}
```

### 3. Modify for Your Sources
Adapt the fields to match your actual sources:
- Change the `citation key` (e.g., `mccauley2019`)
- Update `AUTHOR`, `TITLE`, `JOURNALTITLE`, etc.
- Ensure `DATE` format matches your source
- Include `DOI` or `URL` as appropriate

### 4. Cite in Your Document
Use standard LaTeX citation commands:

```latex
\documentclass{article}
\usepackage[style=apa,backend=biber]{biblatex}
\DeclareLanguageMapping{american}{american-apa}
\addbibresource{bibliography.bib}

\begin{document}

% In-text citations
Language learning follows usage patterns \parencite{mccauley2019}.
According to \textcite{mccauley2019}, children learn through use.

% Reference list
\printbibliography

\end{document}
```

### 5. Compile Your Document
Use the correct compilation sequence:
```bash
pdflatex document.tex
biber document
pdflatex document.tex
pdflatex document.tex
```

## Field Reference Guide

### Essential Fields by Type

#### Journal Articles (@ARTICLE)
```bibtex
@ARTICLE{key,
  AUTHOR         = {Last, First and Last, First},
  TITLE          = {Article Title},
  SUBTITLE       = {Article Subtitle},  % optional
  JOURNALTITLE   = {Journal Name},
  VOLUME         = {12},
  NUMBER         = {3},                 % optional
  PAGES          = {123--145},
  DATE           = {2020},
  DOI            = {10.1000/example}    % preferred over URL
}
```

#### Books (@BOOK)
```bibtex
@BOOK{key,
  AUTHOR         = {Last, First},
  TITLE          = {Book Title},
  SUBTITLE       = {Book Subtitle},     % optional
  EDITION        = {2},                 % if not first edition
  PUBLISHER      = {Publisher Name},
  DATE           = {2020},
  DOI            = {10.1000/example}    % for ebooks
}
```

#### Online Sources (@ONLINE)
```bibtex
@ONLINE{key,
  AUTHOR         = {Last, First},
  TITLE          = {Web Page Title},
  URL            = {https://example.com},
  DATE           = {2020-03-15},        % publication date
  URLDATE        = {2020-04-01}         % access date if needed
}
```

### Special Field Usage

#### Author Roles and Annotations
```bibtex
% For media with specific roles
@VIDEO{key,
  AUTHOR         = {Director Name},
  AUTHOR+an:role = {1=director},
  TITLE          = {Film Title},
  PUBLISHER      = {Studio},
  DATE           = {2020}
}

% For social media with usernames
@ONLINE{key,
  AUTHOR             = {Real Name},
  AUTHOR+an:username = {1="@username"},
  TITLE              = {Tweet content},
  EPRINT             = {Twitter},
  DATE               = {2020-03-15}
}
```

#### Corporate Authors
```bibtex
% Use double braces to prevent name parsing
@REPORT{key,
  AUTHOR         = {{Department of Health}},
  SHORTAUTHOR    = {DOH},               % for subsequent citations
  TITLE          = {Report Title},
  DATE           = {2020}
}
```

#### Date Variations
```bibtex
% Standard formats
DATE = {2020}                    % year only
DATE = {2020-03}                 % month and year  
DATE = {2020-03-15}              % specific date
DATE = {2020-03-15/2020-03-20}   % date range

% Special cases
PUBSTATE = {inpress}             % for in-press works
% No DATE field for undated works

% Seasons (21=Spring, 22=Summer, 23=Fall, 24=Winter)
DATE = {2020-21}                 % Spring 2020

% Original publication dates
ORIGDATE = {1925}                % original publication
DATE = {2020}                    % current edition
```

## Common Citation Patterns

### Multiple Authors
```latex
% 1 author: (Smith, 2020)
% 2 authors: (Smith & Jones, 2020)  
% 3+ authors: (Smith et al., 2020)
```

### Same Author, Multiple Works
```bibtex
@BOOK{smith2020a,
  AUTHOR = {Smith, J.},
  DATE   = {2020a}              % automatic letter assignment
}

@BOOK{smith2020b,
  AUTHOR = {Smith, J.},
  DATE   = {2020b}
}
```

### Corporate Authors with Abbreviations
```bibtex
@REPORT{apa2020,
  AUTHOR         = {{American Psychological Association}},
  SHORTAUTHOR    = {APA},
  TITLE          = {Publication Manual},
  DATE           = {2020}
}
```
First citation: (American Psychological Association [APA], 2020)
Subsequent: (APA, 2020)

## Troubleshooting

### Common Issues

1. **Wrong backend**: Ensure you're using `backend=biber`, not `bibtex`
2. **Missing letters**: For same author/year, add letters manually: `DATE = {2020a}`
3. **Corporate names parsed**: Use double braces: `{{Corporation Name}}`
4. **DOI formatting**: Use DOI field, not URL for DOIs
5. **Date formatting**: Use ISO format: `2020-03-15`

### Compilation Problems
```bash
# Clean auxiliary files and recompile
rm *.aux *.bbl *.bcf *.blg *.run.xml
pdflatex document.tex
biber document
pdflatex document.tex
```

## Advanced Features

### Entry Subtypes for Media
```bibtex
@VIDEO{film,
  ENTRYSUBTYPE = {film},
  % ... other fields
}

@ONLINE{tweet,
  ENTRYSUBTYPE = {Tweet},
  % ... other fields  
}
```

### Related Entries
```bibtex
@ARTICLE{original,
  % ... fields
  RELATED     = {commentary},
  RELATEDTYPE = {commenton}
}

@ARTICLE{commentary,
  % ... commentary fields
}
```

### Custom Entry Types
The examples include specialized types like:
- `@DATASET` for research data
- `@SOFTWARE` for computer programs  
- `@JURISDICTION` for court cases
- `@LEGISLATION` for laws and statutes

## Resources

- **APA Style website**: https://apastyle.apa.org/
- **biblatex-apa documentation**: CTAN package documentation
- **Original test files**: See `05_Original_Files/` for complete examples
- **APA manual sections**: Comments in .bib files reference specific APA sections