# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## 🎯 When to Use This Project

**Trigger conditions** - Use this project when the user:
- Asks to "rewrite to APA style" or "make this APA compliant"
- Wants to check if text follows APA 7 guidelines
- Needs help with academic writing in psychology/social sciences
- Asks about APA formatting, citations, or style rules

**Do NOT use for**: Citation formatting only (use `03_citation_system/` directly)

---

## ⚡ Quick Start: APA Text Rewriting

When user provides text to rewrite, follow this pipeline:

### Step 1: Read the forbidden patterns
```
02_transformation/forbidden_patterns.yaml → quick_scan section
```
Immediately delete: `importantly`, `notably`, `interestingly`, `obviously`, `clearly`

### Step 2: Apply transformations
```
02_transformation/transformation_rules.yaml
```
Key replacements:
- `The study found` → `We found`
- `due to the fact that` → `because`
- `in order to` → `to`
- `influence` → `was associated with` (in correlational studies)
- `significantly` → delete (unless reporting statistics)

### Step 3: Check section-specific rules
- **Method**: Past tense, active voice ("We recruited")
- **Results**: Past tense ("We found")
- **Discussion**: Present tense for implications

### Step 4: Output
Provide rewritten text + list of changes made.

---

## 📋 Complete Processing Checklist

```
□ Delete emphasis words (importantly, clearly, obviously...)
□ Fix anthropomorphism (The study found → We found)
□ Remove redundancy (due to the fact that → because)
□ Check psychology terms (influence → association)
□ Verify tense matches section type
□ Use active voice where appropriate
□ Check number formatting (words < 10, numerals ≥ 10)
```

---

## Project Overview

This repository contains a formal axiomatization of APA 7th edition writing guidelines, designed for both human authors and AI assistants. The project transforms subjective style rules into machine-readable logical axioms and operational transformation rules.

**Primary Purpose**: Enable AI to rewrite text to conform to APA 7th Edition style.

---

## Repository Structure (v4.0)

```
Axiomatization_of_APA7/
├── SYSTEM_PROMPT.md              # AI operational instructions (start here)
├── CLAUDE.md                     # This file
├── README.md
│
├── 01_core_axioms/               # Core writing principles
│   ├── writing_style.yaml        # 9 axioms (clarity, precision, voice)
│   ├── writing_guidelines.yaml   # Practical rules
│   └── jars_standards.yaml       # JARS reporting standards
│
├── 02_transformation/            # AI transformation rules
│   ├── transformation_rules.yaml # Explicit "X → Y" replacements
│   └── forbidden_patterns.yaml   # Words/phrases to avoid
│
├── 03_citation_system/           # BibTeX/BibLaTeX citation system
├── 04_decision_trees/            # Machine-readable decision trees
├── 05_tools/                     # Technical tools (biblatex-apa)
├── 06_reference/                 # APA 7 manual and references
│   ├── APA7manual.md             # Full manual (corrected OCR)
│   └── APA7manual/               # Split by chapter (17 files)
└── archive/                      # Original .md axiom files
```

## For AI Text Rewriting

When asked to rewrite text to APA style:

1. **Read `SYSTEM_PROMPT.md`** - Contains the processing pipeline
2. **Scan `02_transformation/forbidden_patterns.yaml`** - Words to delete/replace
3. **Apply `02_transformation/transformation_rules.yaml`** - Explicit transformations
4. **Reference `01_core_axioms/`** - For underlying principles

### Quick Transformation Reference

| Pattern | Replacement | Category |
|---------|-------------|----------|
| The study found | We found | Anthropomorphism |
| importantly | (delete) | Emphasis word |
| due to the fact that | because | Redundancy |
| in order to | to | Redundancy |
| influence | was associated with | Psychology-specific |

## Common Development Commands

### Working with LaTeX/BibTeX
```bash
# Compile LaTeX documents with BibLaTeX
pdflatex document.tex
biber document
pdflatex document.tex
pdflatex document.tex

# Test biblatex-apa package
cd 05_tools/biblatex-apa
pdflatex biblatex-apa-test.tex
biber biblatex-apa-test
pdflatex biblatex-apa-test.tex
```

### Working with YAML
```python
import yaml

# Load axioms
with open('01_core_axioms/writing_style.yaml') as f:
    style = yaml.safe_load(f)

# Load transformation rules
with open('02_transformation/forbidden_patterns.yaml') as f:
    forbidden = yaml.safe_load(f)
```

## High-Level Architecture

### Axiomatization Structure
1. **Core Axioms** (`01_core_axioms/`): Defines primitive objects and core axioms (clarity, conciseness, coherence)
2. **Transformation Rules** (`02_transformation/`): Operational rules for AI rewriting
3. **Citation System** (`03_citation_system/`): 680+ categorized BibTeX examples
4. **Reference Materials** (`06_reference/`): Official APA 7 manual in Markdown

### ASBE Format
All axioms use **Axiomatic Specification by Example (ASBE)**:
- `statement_natural`: Human-readable explanation
- `statement_formal`: Logical notation
- `violations`: Examples of incorrect usage
- `compliant`: Examples of correct usage

## Key Design Principles

1. **Machine-Readable**: All style rules expressed as formal YAML
2. **Operational**: Transformation rules provide explicit "X → Y" patterns
3. **Comprehensive**: Covers writing style, citations, and reporting standards
4. **Practical**: Includes forbidden word lists and quick scan checklists

---

## Claude Code Skill Design

### Skill Location
```
.claude/skills/apa-rewriter/
├── SKILL.md                   # Main entry point (quick reference)
├── forbidden_patterns.yaml    # 46 patterns to avoid
├── transformation_rules.yaml  # 46 X→Y transformations
├── writing_style.yaml         # 9 core axioms
└── writing_guidelines.yaml    # 14 practical rules
```

### Design Principles

| Principle | Description |
|-----------|-------------|
| **Self-contained** | All reference files included in skill folder |
| **No information loss** | Complete YAML files with all comments and structure |
| **Independent operation** | Skill works when downloaded separately from project |

### Why Include Full YAML Files?

Instead of summarizing rules in SKILL.md (which loses detail), we include complete YAML files:
- AI can parse structured YAML more reliably than Markdown tables
- All metadata, comments, and examples are preserved
- Easier maintenance: just copy files, no manual conversion

### Maintenance Workflow

```bash
# When project YAML files are updated, sync to skill folder:
cp 02_transformation/*.yaml .claude/skills/apa-rewriter/
cp 01_core_axioms/writing_style.yaml .claude/skills/apa-rewriter/
cp 01_core_axioms/writing_guidelines.yaml .claude/skills/apa-rewriter/
```

### File Authority

| Location | Role |
|----------|------|
| `02_transformation/*.yaml` | **Authority source** (edit here) |
| `01_core_axioms/*.yaml` | **Authority source** (edit here) |
| `.claude/skills/apa-rewriter/*.yaml` | **Copies** (sync from authority) |

## Important Notes

- The APA manual PDF in `06_reference/` is for personal study only under fair use
- When modifying axioms, maintain ASBE format consistency
- BibTeX examples follow strict categorization - maintain directory structure
- The project uses CC BY-SA 4.0 license for axiom text and diagrams

## File Locations Changed in v4.0

| Old Location | New Location |
|--------------|--------------|
| `writing_style.yaml` | `01_core_axioms/writing_style.yaml` |
| `writing_guidelines.yaml` | `01_core_axioms/writing_guidelines.yaml` |
| `jars_standards.yaml` | `01_core_axioms/jars_standards.yaml` |
| `04_citation_system/` | `03_citation_system/` |
| `07_decision_trees/` | `04_decision_trees/` |
| (new) | `02_transformation/` |
| (new) | `SYSTEM_PROMPT.md` |
