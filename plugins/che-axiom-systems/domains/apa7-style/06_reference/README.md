# 06 Reference Materials

Official APA 7 manual and related reference materials.

## Contents

### APA7manual.md ⭐ (Corrected)
**Markdown version** converted using [marker](https://github.com/VikParuchuri/marker), with OCR errors corrected.

- Full text with proper headings and structure
- Tables preserved as Markdown tables
- UTF-8 encoding (no garbled characters)
- Best for searching and LLM consumption
- **Corrections applied** (2025-12-30):
  - `Off-ice` → `Office`
  - `selfregulation` → `self-regulation`
  - `psycho-pathology` → `psychopathology`
  - `Asso-ciation`, `Ex-pert`, `Out-comes`, `Psycholo-gy` → fixed hyphenation
  - `chapterby-chapter` → `chapter-by-chapter`
  - `pro-gram` → `program`
  - `\_` → `_` (17 escaped underscores fixed)

### APA7manual_ocr.md
Original marker conversion output (before corrections). Kept for reference.

### APA7manual/ ⭐ (Split by Chapter)
**Chapter-split version** for easier reading (each file < 2000 lines).

| File | Content |
|------|---------|
| `00_front_matter.md` | Tables, Figures, Editorial Staff |
| `00_introduction.md` | Introduction |
| `01_scholarly_writing.md` | Ch 1: Scholarly Writing |
| `02_paper_format.md` | Ch 2: Paper Format |
| `03_jars.md` | Ch 3: JARS Reporting Standards |
| `04_writing_style.md` | Ch 4: Writing Style |
| `05_bias_free_language.md` | Ch 5: Bias-Free Language |
| `06_mechanics.md` | Ch 6: Mechanics of Style |
| `07_tables_figures.md` | Ch 7: Tables and Figures |
| `08_in_text_citations.md` | Ch 8: In-Text Citations |
| `09_reference_list.md` | Ch 9: Reference List |
| `10_reference_examples.md` | Ch 10: Reference Examples |
| `11_legal_references.md` | Ch 11: Legal References |
| `12_publication_process.md` | Ch 12: Publication Process |
| `13_credits.md` | Credits |
| `14_references.md` | References |
| `15_index.md` | Index |

### apa7_images/
Images extracted from the manual during conversion (58 figures).

### APA7manual.pdf
Original APA 7th edition Publication Manual.

**Warning:** Copyright material. Personal study only - do not distribute.

### APA7manual_scan.pdf
Scanned version of the manual (backup/OCR reference).

### apastyle_mirror/ (Partial)
Partial mirror of https://apastyle.apa.org/ via Wayback Machine.

**Available pages (7 files):**
- `index.md` - Homepage
- `style-grammar-guidelines.md` - Style guidelines overview
- `style-grammar-guidelines_citations.md` - In-text citations
- `style-grammar-guidelines_citations_plagiarism.md` - Plagiarism guidelines
- `style-grammar-guidelines_paper-format_font.md` - Font guidelines
- `style-grammar-guidelines_paper-format_paragraph-format.md` - Paragraph format
- `style-grammar-guidelines_paper-format_title-page.md` - Title page setup

**Note:** Full mirror blocked by Imperva security. Use `download_apastyle.py` to retry later.

## Archived Files

Located in `archive/old_reference/`:

- `APA7manual.txt` - Old plain-text extraction (had encoding issues)
- `APA Style.html` + `APA Style_files/` - Old HTML web mirror

## Purpose

Provide authoritative source materials for:
1. Verifying axiom accuracy against official text
2. Resolving ambiguous cases
3. Understanding official APA interpretations
4. Semantic search and analysis

## Usage

```python
# Read markdown for analysis
with open('APA7manual.md', 'r', encoding='utf-8') as f:
    content = f.read()

# Search for specific topics
import re
chapters = re.split(r'^# ', content, flags=re.MULTILINE)
```

## Conversion Details

- **Tool**: marker v0.4.x
- **Date**: 2025-12-30
- **Processing time**: ~16 minutes
- **Output**: 1.9MB Markdown + 58 JPEG images
