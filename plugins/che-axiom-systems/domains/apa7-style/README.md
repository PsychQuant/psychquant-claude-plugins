# Axiomatization of APA 7 Style

> **For AI Assistants**: See [CLAUDE.md](CLAUDE.md) for usage instructions. When user asks to rewrite text to APA style, follow the Quick Start pipeline there.

## Overview

This repository formalizes the American Psychological Association (APA) 7th-edition writing guidelines as a **machine-readable axiom system**.

**Primary Use Case**: AI-assisted rewriting of academic text to conform to APA 7th Edition style.

---

## 🚀 Quick Start for AI

### When to Use
- User asks to "rewrite to APA style" or "check APA compliance"
- User needs help with psychology/social science academic writing

### Immediate Actions
1. **Delete these words**: `importantly`, `notably`, `interestingly`, `obviously`, `clearly`, `significantly` (non-statistical)
2. **Replace**: `The study found` → `We found`, `due to the fact that` → `because`
3. **Check**: `influence` → `was associated with` (correlational studies only)

### Full Pipeline
See [CLAUDE.md](CLAUDE.md) for complete processing checklist.

### Key Files
| Priority | File | Purpose |
|----------|------|---------|
| 1 | `02_transformation/forbidden_patterns.yaml` | Words to delete/replace |
| 2 | `02_transformation/transformation_rules.yaml` | Explicit X→Y rules |
| 3 | `01_core_axioms/*.yaml` | Underlying principles |

### Claude Code Skill

This project includes a **self-contained** Claude Code Skill at `.claude/skills/apa-rewriter/`.

#### Skill Structure
```
.claude/skills/apa-rewriter/
├── SKILL.md                   # Main entry point
├── forbidden_patterns.yaml    # 46 patterns to avoid
├── transformation_rules.yaml  # 46 X→Y transformations
├── writing_style.yaml         # 9 core axioms
└── writing_guidelines.yaml    # 14 practical rules
```

#### Design Principles
1. **Self-contained** - All reference files included in skill folder
2. **No information loss** - Complete YAML files, not summarized
3. **Independent operation** - Works when downloaded separately

#### Install in Any Project

Download the skill to your project with one command:

```bash
mkdir -p .claude/skills && cd .claude/skills && \
git clone --depth 1 --filter=blob:none --sparse \
  https://github.com/kiki830621/axiomatization-apa7-style.git temp && \
cd temp && git sparse-checkout set .claude/skills/apa-rewriter && \
mv .claude/skills/apa-rewriter ../ && cd .. && rm -rf temp
```

Or step by step:
```bash
# 1. Create skills directory
mkdir -p .claude/skills
cd .claude/skills

# 2. Sparse clone (downloads only the skill folder)
git clone --depth 1 --filter=blob:none --sparse \
  https://github.com/kiki830621/axiomatization-apa7-style.git temp
cd temp
git sparse-checkout set .claude/skills/apa-rewriter

# 3. Move skill to your project and cleanup
mv .claude/skills/apa-rewriter ../
cd ..
rm -rf temp
```

#### Usage
After installation, the skill is automatically available in Claude Code. Just ask:
- "Rewrite this to APA style"
- "Make this paragraph APA compliant"
- "Check this text for APA issues"

#### Maintenance
- **Authority source**: `02_transformation/*.yaml` and `01_core_axioms/*.yaml`
- **Skill copies**: `.claude/skills/apa-rewriter/*.yaml`
- When project YAML files are updated, run `./sync_skill.sh`

---

## Repository Structure (v4.0)

```
Axiomatization_of_APA7/
├── SYSTEM_PROMPT.md              # AI operational instructions
├── CLAUDE.md                     # Claude Code development guide
├── README.md                     # This file
│
├── 01_core_axioms/               # Core writing principles
│   ├── writing_style.yaml        # 9 axioms (clarity, precision, voice, etc.)
│   ├── writing_guidelines.yaml   # Practical rules (tense, pronouns, etc.)
│   └── jars_standards.yaml       # JARS reporting standards
│
├── 02_transformation/            # AI transformation rules
│   ├── transformation_rules.yaml # Explicit X → Y replacements
│   └── forbidden_patterns.yaml   # Words/phrases to avoid
│
├── 03_citation_system/           # BibTeX/BibLaTeX citation system
│   ├── apa_citation_guide.md
│   └── bibtex_examples/          # 680+ citation examples
│
├── 04_decision_trees/            # Machine-readable decision trees
│   ├── trees/                    # YAML decision trees
│   └── tools/                    # Python validation tools
│
├── 05_tools/                     # Technical tools
│   └── biblatex-apa/             # Official BibLaTeX APA style
│
├── 06_reference/                 # APA 7 manual and references
│   ├── APA7manual.md             # Full manual (Markdown, corrected)
│   ├── APA7manual/               # Split by chapter (17 files)
│   └── apastyle_mirror/          # Partial website mirror
│
└── archive/                      # Original .md axiom files (backup)
    └── original_md_axioms/
```

### File Priority for AI

| Priority | Files | Purpose |
|----------|-------|---------|
| 1 (Must) | `SYSTEM_PROMPT.md` | Operational instructions |
| 2 (Must) | `02_transformation/*.yaml` | What to change |
| 3 (Need) | `01_core_axioms/*.yaml` | Why to change |
| 4 (Ref)  | `06_reference/APA7manual/` | Official guidance |

---

## ASBE Format

This project uses **Axiomatic Specification by Example (ASBE)**, a YAML-based format that combines:

1. **Dual Expression** – Each axiom has both natural language and formal notation
2. **Example Grounding** – Every rule includes concrete violations and compliant examples
3. **Hierarchical Derivation** – Theorems derive from axioms, rules derive from theorems

### Quick Example

```yaml
axioms:
  - id: "A1_clarity"
    name: "Clarity Axiom"
    one_liner: "Scholarly writing must be clear"

    statement_natural: |
      All scholarly text must be clear to facilitate understanding.

    statement_formal: |
      ∀t ∈ Text, Scholarly(t) → Clear(t)

    violations:
      - description: "Jargon-heavy prose"
        content: |
          The epistemological ramifications of the paradigmatic shift...

    compliant:
      - description: "Clear statement"
        content: |
          This study examines how theoretical changes affect research.
```

---

## Core Files Summary

### 01_core_axioms/

| File | Content | Count |
|------|---------|-------|
| `writing_style.yaml` | Core writing principles | 9 axioms, 3 theorems |
| `writing_guidelines.yaml` | Practical rules | 14 rules (T, V, P, C, B, A) |
| `jars_standards.yaml` | Reporting standards | 6 axioms, 3 theorems |

**Axiom Categories:**
- **A1-A3**: Clarity, Precision, Economy
- **A4-A6**: Active Voice, Tense Consistency, Tense Selection
- **A7-A9**: Paragraph Unity, Transitions, Parallel Structure

### 02_transformation/

| File | Content |
|------|---------|
| `transformation_rules.yaml` | Explicit "X → Y" replacements |
| `forbidden_patterns.yaml` | Words to delete or replace |

**Key Categories:**
- Redundancy elimination
- Anthropomorphism correction
- Empty phrase deletion
- Psychology-specific terms
- Gender-inclusive language

---

## Use Cases

- **Authors** – Self-audit manuscripts using violation/compliant examples
- **AI Assistants** – Parse YAML for automated style checking and rewriting
- **Reviewers** – Reference formal axioms when giving feedback
- **Educators** – Teach academic writing with structured examples
- **Tool Developers** – Build linters using formal rule definitions

---

## Quick Navigation

| Task | File | Section |
|------|------|---------|
| Rewrite to APA style | `SYSTEM_PROMPT.md` | Full file |
| Find forbidden words | `02_transformation/forbidden_patterns.yaml` | quick_scan |
| Fix verb tense | `01_core_axioms/writing_guidelines.yaml` | R_T1-R_T4 |
| Choose active/passive | `01_core_axioms/writing_guidelines.yaml` | R_V1-R_V2 |
| Check JARS compliance | `01_core_axioms/jars_standards.yaml` | All axioms |
| Format citations | `03_citation_system/` | bibtex_examples/ |
| Look up APA rules | `06_reference/APA7manual/` | By chapter |

---

## Example Transformation

**Input:**
> The study importantly found that cognitive load significantly influences performance.

**Output (APA-compliant):**
> We found that cognitive load was associated with performance.

**Changes applied:**
1. `importantly` → deleted (emphasis word)
2. `The study found` → `We found` (anthropomorphism)
3. `significantly` → deleted (non-statistical context)
4. `influences` → `was associated with` (psychology-specific)

---

## Version History

- **v4.0** (2025-12-30) - Added SYSTEM_PROMPT.md, transformation rules, renumbered folders
- **v3.0** (2024-12-30) - Converted to ASBE YAML format; archived original .md files
- **v2.0** (2025-10-01) - Six-layer architecture with comprehensive documentation
- **v1.0** (2025) - Initial release with core axioms and BibTeX examples

---

## License

- Axiom definitions and examples: **CC BY-SA 4.0**
- APA manual PDF: Personal study only (fair use)

---

## Citation

```bibtex
@misc{cheng2025apa7axioms,
  author = {Cheng, Che},
  title = {Axiomatization of APA 7 Style: ASBE Format},
  year = {2025},
  version = {4.0},
  url = {https://github.com/kiki830621/axiomatization-apa7-style}
}
```

---

**Happy writing!**
