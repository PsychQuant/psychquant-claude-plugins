# The Full Name Principle in BibTeX Files

## Core Principle

**ALWAYS store complete author names in BibTeX files, never abbreviations.**

## Rationale

### 1. Accuracy and Completeness
- Preserves the original, complete information
- Prevents loss of data during format conversions
- Avoids ambiguity when multiple authors share similar abbreviated names
- Maintains scholarly integrity by fully crediting all contributors

### 2. Flexibility and Reusability
- One BibTeX file serves multiple purposes (CVs, academic papers, presentations)
- Citation styles can automatically format names as needed
- No need to maintain separate files for different formats
- Easy to switch between different citation requirements

### 3. Technical Advantages
- Modern biblatex systems handle name formatting intelligently
- Automatic abbreviation based on citation style requirements
- Consistent handling across different document types
- Reduces manual formatting errors

### 4. International and Cultural Considerations
- Proper handling of non-Western naming conventions
- Accurate representation of compound names and titles
- Prevents transcription errors in name abbreviation
- Supports multilingual bibliography requirements

### 5. Academic Best Practices
- Facilitates proper attribution and citation tracking
- Supports academic networking and collaboration identification
- Enables accurate bibliometric analysis
- Promotes transparency in scholarly communication

## Implementation Examples

### Correct Format (Full Names)
```bibtex
@ARTICLE{sample_2024,
  AUTHOR = {Cheng, Che and Yang, Hau-Hung and Hsu, Yung-Fong},
  TITLE = {Sample Article Title},
  JOURNALTITLE = {Journal Name},
  DATE = {2024}
}
```

### What to Avoid (Abbreviated Names)
```bibtex
@ARTICLE{sample_2024,
  AUTHOR = {C. Cheng and H. H. Yang and Y. F. Hsu},  % DON'T DO THIS
  TITLE = {Sample Article Title},
  JOURNALTITLE = {Journal Name},
  DATE = {2024}
}
```

## Style Processing

Let the citation style handle formatting:
- APA style: (Cheng et al., 2024) → Cheng, C., Yang, H. H., & Hsu, Y. F. (2024).
- Nature style: Cheng, C., Yang, H.-H. & Hsu, Y.-F. (2024).
- CV format: Cheng, Che, Yang, Hau-Hung, & Hsu, Yung-Fong (2024).

## Conclusion

The full name principle ensures maximum flexibility, accuracy, and compatibility across all academic citation needs. Store complete information and let the formatting tools do their job.