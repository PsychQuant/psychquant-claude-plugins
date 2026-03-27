# APA 7 Block Quote Formatting Guidelines

## When to Use Block Quotes

### Rule 1: Length Threshold
- Use block quote format for quotations of **40 words or more**
- Direct quotations under 40 words should be incorporated into the text with quotation marks

### Rule 2: Word Count
- Count all words in the quotation, including articles (a, an, the)
- Include words in parenthetical citations within the quote in the word count
- Hyphenated words count as one word

## Block Quote Formatting Rules

### Basic Format
1. **Start on a new line**
2. **Indent the entire quote 0.5 inches** from the left margin
3. **Do not use quotation marks** around block quotes
4. **Double-space** the entire quotation
5. **Do not add extra space** before or after the block quote

### LaTeX Implementation

#### Standard Block Quote Environment
```latex
\begin{quote}
This is a block quotation that contains 40 or more words. The entire 
quotation is indented from the left margin, and no quotation marks are 
used. The text is double-spaced just like the rest of the document, and 
there is no extra space added before or after the block quote.
\end{quote}
```

#### Using csquotes Package (Recommended for APA)
```latex
\usepackage[american]{babel}
\usepackage{csquotes}

% In document:
\begin{displayquote}
This is a block quotation using the csquotes package, which provides 
better integration with biblatex-apa and ensures proper formatting 
according to APA guidelines. This method is preferred when using the 
biblatex-apa style.
\end{displayquote}
```

#### Custom APA Block Quote Environment
```latex
% In preamble:
\newenvironment{blockquote}{%
  \begin{quote}
  \setlength{\leftskip}{0.5in}
  \setlength{\rightskip}{0in}
  \noindent
}{%
  \end{quote}
}

% Usage:
\begin{blockquote}
Your block quotation text here...
\end{blockquote}
```

## Citation Placement for Block Quotes

### Rule 1: Narrative Citation Before Quote
When introducing with a narrative citation, place the year after the author:
```latex
According to \textcite{smith2020}:
\begin{quote}
This is the block quotation text that follows the narrative citation. 
The quotation contains at least 40 words and is formatted as a block 
quote according to APA guidelines.
\end{quote}
```

### Rule 2: Parenthetical Citation After Quote
Place the citation after the final punctuation of the block quote:
```latex
\begin{quote}
This is the block quotation text. Note that the period comes at the 
end of the last sentence within the quotation, not after the citation.
\end{quote}
\parencite[p.~25]{smith2020}
```

### Rule 3: Page Numbers
Always include page numbers for direct quotations:
```latex
\begin{quote}
Block quotation text here with specific page reference.
\end{quote}
\parencite[p.~157]{jones2021}

% Or for multiple pages:
\parencite[pp.~157--159]{jones2021}
```

## Special Cases

### Block Quote Within Block Quote
If a block quote contains another quotation:
- Use double quotation marks for the internal quote
- Maintain the same indentation throughout

```latex
\begin{quote}
The researcher noted that "the participants showed remarkable consistency" 
in their responses. This finding was particularly noteworthy given the 
diversity of the sample population and the complexity of the research 
questions being investigated.
\end{quote}
```

### Omitting Material
Use ellipsis (...) to indicate omitted material:
```latex
\begin{quote}
This is the beginning of the quotation . . . and this is the continuation 
after omitted material. Use three spaced periods to indicate the omission.
\end{quote}
```

### Adding Emphasis
Use brackets to indicate added emphasis:
```latex
\begin{quote}
This finding was \emph{particularly significant} [emphasis added] given 
the previous research in this area had shown contradictory results.
\end{quote}
\parencite[p.~45]{brown2019}
```

## Common Errors to Avoid

1. **Do not use quotation marks** around block quotes
2. **Do not indent the first line** extra (only the standard 0.5" for all lines)
3. **Do not single-space** block quotes (maintain double-spacing)
4. **Do not forget page numbers** for direct quotations
5. **Do not place citation before the period** in parenthetical citations

## LaTeX Tips for APA Block Quotes

### Setting Up Proper Spacing
```latex
% Ensure proper spacing around quotes
\setlength{\partopsep}{0pt}
\setlength{\topsep}{0pt}
```

### Using Babel for American Style
```latex
\usepackage[american]{babel}
\usepackage{csquotes}
\DeclareQuoteStyle{american}
  {\textquotedblleft}{\textquotedblright}
  {\textquoteleft}{\textquoteright}
```

### Integration with biblatex-apa
```latex
\usepackage[style=apa]{biblatex}
\usepackage{csquotes}

% Block quote with integrated citation
\begin{displayquote}[\parencite[p.~25]{smith2020}]
Block quotation text here with automatic citation formatting.
\end{displayquote}
```

## Axiomatization Summary

### Formal Rules
1. **Length Rule**: BlockQuote(text) ⟺ WordCount(text) ≥ 40
2. **Format Rule**: BlockQuote(text) → Indent(text, 0.5in) ∧ ¬QuotationMarks(text)
3. **Spacing Rule**: BlockQuote(text) → DoubleSpaced(text) ∧ NoExtraSpace(before, after)
4. **Citation Rule**: BlockQuote(text) → Citation(after_final_punctuation) ∨ NarrativeCitation(before)

### Word Count Function
```
WordCount(text) = |{w : w ∈ tokens(text) ∧ isWord(w)}|
where isWord(w) = true if w is not punctuation
```