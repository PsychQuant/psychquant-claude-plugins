# 05 Tools

Technical tools and modules for implementing APA 7 style.

## Contents

### [biblatex-apa/](biblatex-apa/)
Official BibLaTeX implementation of APA citation style (git subrepo).

**Provides:**
- APA-compliant citation formatting (`.cbx` files)
- APA-compliant bibliography formatting (`.bbx` files)
- Full support for APA 7th edition requirements
- Integration with LaTeX/BibLaTeX workflow

**Requirements:**
- BibLaTeX ≥ 3.4
- Biber ≥ 2.5 (as backend)
- csquotes ≥ 4.3

**Repository:** https://github.com/plk/biblatex-apa

## Purpose

Provide working tools that implement the axiomatized rules:
1. Production-ready LaTeX packages
2. Integration with standard workflows
3. Automated formatting

## Usage

Include biblatex-apa in your LaTeX documents:

```latex
\usepackage[style=apa]{biblatex}
\addbibresource{references.bib}
```

See `04_citation_system/apa_citation_guide.md` for detailed setup instructions.
