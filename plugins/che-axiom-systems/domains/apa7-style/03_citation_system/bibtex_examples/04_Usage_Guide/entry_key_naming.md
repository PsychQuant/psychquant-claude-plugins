# BibTeX Entry Key Naming Convention

## Standard Format: `author_[venue]_topic_year`

### General Principles
- Use lowercase throughout
- Replace spaces with underscores
- Use first author's surname only
- Extract core topic/concept, avoid generic terms
- Venue inclusion is flexible but recommended for conferences

## Journal Articles

### With venue (for important journals or disambiguation)
```bibtex
@ARTICLE{cheng_psychometrika_identifiability_2025,
@ARTICLE{smith_nature_breakthrough_2024,
@ARTICLE{jones_science_discovery_2023,
```

### Without venue (standard practice)
```bibtex
@ARTICLE{cheng_identifiability_2025,
@ARTICLE{smith_breakthrough_2024,
@ARTICLE{jones_discovery_2023,
```

### When to include journal venue:
- Top-tier journals (Nature, Science, Cell, etc.)
- Field-specific prestigious journals (Psychometrika, JASA, etc.)
- When disambiguation is needed
- When journal prestige is academically relevant

## Conference Presentations

### Standard format (venue recommended)
```bibtex
@PRESENTATION{cheng_srcd_qsort_2025,
@PRESENTATION{yang_imps_mle_2024,
@PRESENTATION{smith_icml_neural_2024,
```

### Venue abbreviations for common conferences:
- `srcd` - Society for Research in Child Development
- `imps` - International Meeting of the Psychometric Society
- `tpa` - Taiwanese Psychology Association
- `apa` - American Psychological Association
- `icml` - International Conference on Machine Learning
- `nips` - Neural Information Processing Systems

## Topic Extraction Guidelines

### Focus on core concepts, avoid generic terms:
- "Identifiability of Polychoric Models" → `identifiability` (not "models")
- "Can Likert Scales Predict Choices?" → `likert_choices` (not "predict")
- "A Methodology for Addressing Biases in Q-Sort" → `qsort_biases` (not "methodology")
- "Bootstrap Analysis of Parameter Estimates" → `bootstrap` (not "analysis")

### Multiple concepts:
- Use 2-3 most important terms
- Connect with underscores
- Prioritize uniqueness and clarity

## Special Cases

### Same author, same year, different works:
```bibtex
@ARTICLE{cheng_power_2024a,
@ARTICLE{cheng_bootstrap_2024b,
@PRESENTATION{cheng_srcd_qsort_2024,
```

### Collaborative works (use first author):
```bibtex
@ARTICLE{cheng_identifiability_2025,  # Even if Yang is co-first
```

### Books and chapters:
```bibtex
@BOOK{author_title_year,
@INCOLLECTION{author_handbook_chapter_year,
```

## Benefits of This System

1. **Semantic clarity**: Keys are meaningful and memorable
2. **Natural sorting**: Alphabetical by author, then by content
3. **Flexibility**: Venue inclusion based on need
4. **Standardization**: Consistent across different reference types
5. **Scalability**: Works for large bibliography databases

## Examples by Reference Type

### Complete examples:
```bibtex
@ARTICLE{cheng_psychometrika_identifiability_2025,
@ARTICLE{cheng_methods_likert_2021,
@PRESENTATION{cheng_srcd_methodology_2025,
@PRESENTATION{cheng_imps_existence_2024,
@BOOK{dweck_mindset_2000,
@INCOLLECTION{cheng_handbook_measurement_2024,
@REPORT{cheng_nstc_attribution_2024,
```

This naming convention balances clarity, flexibility, and academic relevance while maintaining consistency across different publication types.