# LaTeX Formatting Guidelines for APA 7 Style Thesis

## Forbidden Commands

### 1. Vertical Spacing Commands
- **NEVER use `\vfill`**: This command adds flexible vertical space and disrupts proper document flow
- **Reason**: Academic papers should maintain consistent, natural spacing determined by the document class
- **Alternative**: Let LaTeX handle spacing automatically through proper sectioning and paragraph breaks

### 2. Manual Spacing to Avoid
- Avoid `\vspace{}` unless absolutely necessary
- Avoid `\bigskip`, `\medskip`, `\smallskip` 
- Let the document class handle proper spacing

## Preferred Table Formatting

### Tables
```latex
\begin{table}[H]
\centering
\caption{Table Title}
\label{tab:label}
% Table content here
\end{table}
```

**Note**: No `\vfill` before or after tables. The `[H]` placement is sufficient for positioning.

## Section Structure
- Use proper sectioning hierarchy: `\chapter{}`, `\section{}`, `\subsection{}`, `\subsubsection{}`
- Allow natural spacing between sections
- Do not force page breaks unless specifically required

## Rationale
- APA 7 style emphasizes clean, readable formatting
- Manual spacing adjustments can cause inconsistencies across the document
- Professional academic writing relies on consistent, automatic formatting
- Thesis templates are designed to handle spacing appropriately

## Implementation
- When editing LaTeX files, remove all instances of `\vfill`
- Replace with natural paragraph breaks or section transitions
- Trust the document class to handle proper spacing