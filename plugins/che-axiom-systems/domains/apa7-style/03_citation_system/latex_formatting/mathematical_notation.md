# Mathematical Notation in LaTeX for APA 7th Edition

## General Principle

**All mathematical content must be typeset in mathematical mode using `$...$` or `$$...$$`**

This includes:
- Single variables and parameters
- Greek letters
- Numbers in mathematical contexts
- Percentages when used mathematically
- Mathematical expressions and equations
- Statistical notation

## Examples

### ✅ Correct Usage

```latex
% Single variables and parameters
We set $\rho = 0.3$ for medium effect sizes.
The sample size $N$ was determined using the formula.
Cohen's criteria: small $r = .10$, medium $r = .30$, large $r = .50$.

% Greek letters
The correlation coefficient $\rho$ represents the population parameter.
We used $\alpha = .05$ as the significance level.

% Percentages in mathematical contexts
The $95\%$ confidence interval excludes zero.
Approximately $54.5\%$ of participants completed the task.

% Mathematical expressions
$N = \left\lceil 3 + \frac{Z_{0.025}^2}{[\tanh^{-1}(\rho) - \tanh^{-1}(\rho/2)]^2} \right\rceil$

% Statistical notation
The Fisher $z$-transformation was applied.
We calculated $Z_{0.025} = 1.96$ for the critical value.

% Numbers in mathematical contexts
A total of $726$ participants were included.
The analysis included $396$ success and $330$ failure cases.
```

### ❌ Incorrect Usage

```latex
% Variables not in math mode
We set rho = 0.3 for medium effect sizes.
The sample size N was determined using the formula.

% Greek letters not in math mode
The correlation coefficient ρ represents the population parameter.

% Percentages as plain text when used mathematically
The 95% confidence interval excludes zero.
Approximately 54.5% of participants completed the task.

% Mathematical expressions in text mode
N = ceiling(3 + Z^2 / [tanh^-1(rho) - tanh^-1(rho/2)]^2)
```

## Specific Guidelines

### 1. Variables and Parameters
- Always use math mode: `$N$`, `$\rho$`, `$r$`, `$p$`
- Use consistent notation throughout the document

### 2. Greek Letters
- Always in math mode: `$\alpha$`, `$\beta$`, `$\rho$`, `$\sigma$`, `$\mu$`
- Use proper LaTeX commands, not Unicode symbols

### 3. Percentages
- When used mathematically: `$95\%$`, `$54.5\%$`
- When used descriptively in text: may use plain text format

### 4. Numbers in Mathematical Context
- Sample sizes: `$N = 726$`, `$n_1 = 396$`
- Statistical values: `$t = 2.45$`, `$F(2, 150) = 12.34$`
- Effect sizes: `$d = 0.65$`, `$\eta^2 = .12$`

### 5. Equations and Formulas
- Use equation environment for numbered equations:
```latex
\begin{equation}
N = \left\lceil 3 + \frac{Z_{0.025}^2}{[\tanh^{-1}(\rho) - \tanh^{-1}(\rho/2)]^2} \right\rceil
\end{equation}
```

- Use `$$...$$` for unnumbered display equations:
```latex
$$z = \tanh^{-1}(r) \sim N\left(\tanh^{-1}(\rho), \frac{1}{N-3}\right)$$
```

### 6. Inline Mathematical Expressions
- Use `$...$` for inline math: `The correlation $r = .45$ was significant.`
- Maintain consistent spacing and formatting

## Benefits of This Approach

1. **Consistency**: All mathematical content follows the same formatting rules
2. **Readability**: Mathematical notation is clearly distinguished from regular text
3. **Professional Appearance**: Proper mathematical typesetting enhances document quality
4. **LaTeX Optimization**: Takes advantage of LaTeX's superior mathematical typesetting capabilities
5. **APA Compliance**: Ensures clear distinction between mathematical and textual content

## Implementation Notes

- This principle applies to ALL mathematical content, regardless of complexity
- When in doubt, use math mode - it's better to be consistent than to mix formats
- Check that all Greek letters, variables, and mathematical expressions are in math mode
- Ensure percentages used in statistical contexts are formatted as `$...\%$`
- Sample size calculations should always use proper mathematical notation: `$N = 1,538$`
- Probability statements should be in math mode: `$\geq 97.5\%$ probability`

## Common Mistakes to Avoid

1. Mixing math mode and text mode for similar content
2. Using Unicode Greek letters instead of LaTeX commands
3. Formatting simple numbers or percentages as plain text when they're part of mathematical expressions
4. Inconsistent spacing around mathematical operators
5. Using text mode for variable names or statistical notation

This principle ensures consistent, professional mathematical notation throughout academic documents while maintaining APA 7th edition standards.