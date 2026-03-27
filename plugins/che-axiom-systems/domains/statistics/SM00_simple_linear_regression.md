# Simple Linear Regression

## Axioms and Principles

### Axiom SLR1: Linear Relationship
The relationship between the predictor variable X and the response variable Y can be modeled by a linear function with additive random noise.

Formally:
- Y = β₀ + β₁X + ε
- Where β₀ is the intercept, β₁ is the slope, and ε is the error term

### Axiom SLR2: Error Term Properties
The error term ε follows these properties:
- E(ε) = 0 (Zero mean)
- Var(ε) = σ² (Constant variance/homoscedasticity)
- Cov(εᵢ, εⱼ) = 0 for i ≠ j (Independence of errors)
- ε ~ N(0, σ²) (Normality of errors)

### Axiom SLR3: Predictor Variable
The predictor variable X is:
- Measured without error
- Either fixed by design or independent of the error term ε

### Principle SLR-P1: Least Squares Estimation
Parameter estimates β̂₀ and β̂₁ are chosen to minimize the sum of squared residuals.

Formally:
- Minimize SSE = Σ(Yᵢ - (β₀ + β₁Xᵢ))²

### Principle SLR-P2: Inferential Framework
Statistical inference about the model parameters depends on the distribution of the error term.

### Principle SLR-P3: Extrapolation Limitation
Predictions beyond the range of observed X values are subject to increased uncertainty.

## Theorems

### Theorem SLR-T1: Unbiased Estimators
Under Axioms SLR1-SLR3, the least squares estimators β̂₀ and β̂₁ are unbiased estimators of β₀ and β₁.

Formally:
- E(β̂₀) = β₀
- E(β̂₁) = β₁

### Theorem SLR-T2: Gauss-Markov
Under Axioms SLR1-SLR3, the least squares estimators have minimum variance among all linear unbiased estimators.

### Theorem SLR-T3: Coefficient of Determination
The proportion of variation in Y explained by X is measured by R², where:

R² = 1 - SSE/SST = SSR/SST

Where:
- SSE = Sum of squared errors = Σ(Yᵢ - Ŷᵢ)²
- SST = Total sum of squares = Σ(Yᵢ - Ȳ)²
- SSR = Regression sum of squares = Σ(Ŷᵢ - Ȳ)²

## Model Diagnostics

### Diagnostic SLR-D1: Residual Analysis
Examination of residuals (εᵢ = Yᵢ - Ŷᵢ) should reveal:
- No systematic patterns when plotted against X or fitted values
- Approximately normal distribution
- Constant variance across the range of X
- No outliers or influential points that unduly affect the regression line

### Diagnostic SLR-D2: Leverage and Influence
Observations with extreme X values have high leverage and potential for high influence on the regression line.

### Diagnostic SLR-D3: Coefficient Significance
Statistical significance of β₁ indicates evidence against the null hypothesis H₀: β₁ = 0.

## Limitations and Extensions

### Limitation SLR-L1: Non-linearity
Simple linear regression cannot capture non-linear relationships without transformation.

### Limitation SLR-L2: Omitted Variables
The model may suffer from omitted variable bias if important predictors are excluded.

### Extension SLR-E1: Multiple Regression
Extension to multiple predictor variables: Y = β₀ + β₁X₁ + β₂X₂ + ... + βₚXₚ + ε

### Extension SLR-E2: Weighted Least Squares
Modified estimation procedure for heteroscedastic errors.

### Extension SLR-E3: Transformation
Application of transformations to achieve linearity or other desirable properties.

## Applications

### Application SLR-A1: Prediction
Using the fitted model to predict Y for new observations of X.

### Application SLR-A2: Parameter Interpretation
- β₀: Expected value of Y when X = 0 (if meaningful)
- β₁: Expected change in Y for a one-unit increase in X

### Application SLR-A3: Correlation Analysis
The relationship between correlation coefficient r and regression slope β₁:
- β₁ = r(s_y/s_x)
- Where s_x and s_y are the sample standard deviations of X and Y