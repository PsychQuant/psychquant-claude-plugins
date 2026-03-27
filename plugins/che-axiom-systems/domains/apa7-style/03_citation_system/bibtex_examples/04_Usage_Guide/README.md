# BibTeX Citation Examples for APA 7th Edition

This collection provides organized BibTeX examples for generating proper APA 7th edition citations and references. The examples are based on the official `biblatex-apa` package test cases and cover all major citation scenarios.

## Folder Structure

### 01_Citation_Examples/
Examples for **in-text citations** (APA Chapter 8):
- `basic_author_date.bib` - Basic citation formats (8.6-8.11)
- `multiple_authors.bib` - Multiple author handling (8.12, 8.18)
- `corporate_institutional.bib` - Corporate authors (8.13, 8.17, 8.21)
- `disambiguation_cases.bib` - Same author/year disambiguation (8.19-8.20)
- `special_formatting.bib` - Special cases (8.14-8.16)
- `name_formatting.bib` - International names and special characters

### 02_Reference_Types/
Examples for **reference list entries** (APA Chapter 10):
- `journal_articles.bib` - Academic journal articles (10.1)
- `books_chapters.bib` - Books and book chapters (10.2-10.3)
- `reports_theses.bib` - Reports and dissertations (10.4, 10.6)
- `web_online_sources.bib` - Online sources and social media (10.10-10.16)
- `audiovisual_media.bib` - Films, videos, podcasts (10.12-10.13)
- `software_datasets.bib` - Software and research data (10.9-10.10)
- `legal_references.bib` - Legal citations (APA Chapter 11)

### 03_Formatting_Rules/
Examples for **formatting and ordering** (APA Chapter 9):
- `author_name_formats.bib` - Name formatting and alphabetization
- `date_formatting.bib` - Date handling and seasons
- `special_characters.bib` - International characters and symbols

### 04_Usage_Guide/
- `README.md` - This file
- `apa_conversion_guide.md` - How to convert BibTeX to APA format

### 05_Original_Files/
- Complete original test files from biblatex-apa package

## Quick Start

1. **For basic citations**: Start with `01_Citation_Examples/basic_author_date.bib`
2. **For journal articles**: Use `02_Reference_Types/journal_articles.bib`
3. **For online sources**: Check `02_Reference_Types/web_online_sources.bib`
4. **For legal citations**: See `02_Reference_Types/legal_references.bib`

## Key Features

- **289 total examples** covering all APA 7 reference types
- **Organized by use case** for easy navigation
- **Complete field examples** showing proper BibTeX syntax
- **Special handling** for international names, dates, and media types
- **Cross-referenced** to specific APA manual sections

## Common Entry Types

| BibTeX Type | APA Use | Example File |
|-------------|---------|--------------|
| `@ARTICLE` | Journal articles | `journal_articles.bib` |
| `@BOOK` | Books, monographs | `books_chapters.bib` |
| `@INCOLLECTION` | Book chapters | `books_chapters.bib` |
| `@ONLINE` | Web sources, blogs | `web_online_sources.bib` |
| `@VIDEO` | Films, YouTube | `audiovisual_media.bib` |
| `@AUDIO` | Podcasts, music | `audiovisual_media.bib` |
| `@REPORT` | Technical reports | `reports_theses.bib` |
| `@DATASET` | Research data | `software_datasets.bib` |
| `@SOFTWARE` | Computer programs | `software_datasets.bib` |
| `@JURISDICTION` | Court cases | `legal_references.bib` |
| `@LEGISLATION` | Laws, statutes | `legal_references.bib` |

## Special Fields

- **DOI**: Always include when available
- **URL**: For online sources without DOI
- **ENTRYSUBTYPE**: Specify media type (tweet, podcast, etc.)
- **AUTHOR+an:role**: Specify roles (director, editor, etc.)
- **AUTHOR+an:username**: For social media usernames
- **ORIGDATE**: For reprinted/translated works
- **PUBSTATE**: For in-press publications

## Usage Notes

1. **Entry keys**: Use `author_[venue]_topic_year` format
   - Journal articles: `cheng_[psychometrika]_identifiability_2025` (venue optional)
   - Conference papers: `cheng_srcd_qsort_2025` (venue recommended)
   - Focus on core concept/topic, avoid generic words (methodology, analysis, study)
   - Use lowercase, underscores for spaces, meaningful keywords only
2. **Author names**: **ALWAYS use full names** in BibTeX files
   - Store complete names: `{Cheng, Che and Yang, Hau-Hung}`
   - Let biblatex handle abbreviations automatically based on citation style
   - Preserves accuracy, prevents ambiguity, and supports internationalization
   - One file works for CVs, papers, and all citation formats
3. **Corporate authors**: Use double braces `{{Corporation Name}}`
4. **Special characters**: Most Unicode characters work directly
5. **Capitalization**: Protect proper nouns with braces `{United States}`
6. **Date ranges**: Use slash separator `2020-01/2020-03`
7. **Seasons**: Use codes 21=Spring, 22=Summer, 23=Fall, 24=Winter
8. **⚠️ Escape characters**: **Avoid backslashes before braces** in BibTeX entries
   - **Wrong**: `\{brms\}`, `\{{R}\}`, `\{mirt\}` (causes LaTeX compilation errors)
   - **Correct**: `{brms}`, `{R}`, `{mirt}` (proper BibTeX syntax)
   - Common issue with R packages and software names
   - Use simple braces for protection, not escaped braces

## Next Steps

See `apa_conversion_guide.md` for detailed instructions on using these examples with LaTeX and biblatex-apa to generate proper APA-formatted citations and references.