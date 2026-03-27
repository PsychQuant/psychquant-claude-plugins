# Rescaling in Simple Linear Regression

This document formalizes the effects of various rescaling transformations on simple linear regression parameters and properties.

## Core Principles

### Principle R1: Invariance of Fit Quality
The quality of fit measures (R², correlation coefficient, etc.) remain invariant under linear transformations of X and Y.

### Principle R2: Predictive Equivalence
Rescaled models have equivalent predictive power when their predictions are transformed back to the original scale.

### Principle R3: Parameter Transformation
Regression parameters transform in a deterministic manner according to the specific rescaling applied.

## Linear Transformations and Their Effects

### Theorem RT1: General Linear Transformation

If we have the original model:
- Y = β₀ + β₁X + ε

And apply linear transformations:
- X* = aX + b
- Y* = cY + d

Then the new model becomes:
- Y* = β₀* + β₁*X* + ε*

Where:
- β₁* = (c/a)β₁
- β₀* = c·β₀ + d - (c·β₁·b/a)
- ε* = c·ε

### Corollary RT1.1: Scale-Only Transformation

If we only scale X and Y (no shift):
- X* = aX
- Y* = cY

Then:
- β₁* = (c/a)β₁
- β₀* = c·β₀
- ε* = c·ε

### Principle of Structural Invariance Under Rescaling

When X and Y undergo proportional transformation (rescaling), we can understand the effects through the principle of **structural invariance** of the regression equation. The fundamental relationship being modeled remains unchanged; only the coefficients adjust to accommodate the new scales.

#### Derivation Through Equation Structure

Starting with the original simple linear regression model:

Y = β₀ + β₁X + ε

Applying the proportional transformations:
- X* = aX
- Y* = bY

We can rewrite the original model as:

Y*/b = β₀ + β₁(X*/a) + ε

Multiplying both sides by b:

Y* = bβ₀ + (b/a)β₁X* + bε

#### Key Conclusions:
- The intercept becomes β₀* = bβ₀
- The slope becomes β₁* = (b/a)β₁
- The error term becomes ε* = bε

This shows that:
- If only X is rescaled (multiplied by a), the slope becomes β₁/a
- If only Y is rescaled (multiplied by b), the slope becomes bβ₁

#### Alternate Perspective: Factor Extraction

When X is transformed to X* = aX, we can view this as:

Y = β₀ + β₁(X*/a) + ε = β₀ + (β₁/a)X* + ε

This demonstrates that we're merely extracting the factor 1/a from the original relationship. The fundamental "shape" or "essence" of the model remains unchanged; only the units have changed, with coefficients adjusting to compensate.

#### Summary
- Regression models describe relationships between changes in variables, not their absolute values
- Rescaling variables (multiplying by constants) changes the coefficients but not the predictive relationship
- Changes to regression coefficients can be viewed as "compensatory adjustments" to the units of measurement

### Corollary RT1.2: Shift-Only Transformation

If we only shift X and Y (no scaling):
- X* = X + b
- Y* = Y + d

Then:
- β₁* = β₁
- β₀* = β₀ + d - β₁·b
- ε* = ε

## Common Rescaling Scenarios

### Scenario RS1: Unit Rescaling

When variables are converted to different units:
- X* = aX (a = conversion factor)
- Y* = cY (c = conversion factor)

Example:
- Converting height from inches to centimeters (a = 2.54)
- Converting weight from pounds to kilograms (c = 0.453592)

Effects:
- Slope changes by factor c/a
- Intercept changes by factor c
- Interpretation changes to reflect new units

### Scenario RS2: Standardization

Standardizing transforms variables to have mean 0 and standard deviation 1:
- X* = (X - X̄)/s_x
- Y* = (Y - Ȳ)/s_y

Where X̄, Ȳ are means and s_x, s_y are standard deviations.

Effects:
- New slope β₁* = β₁·(s_x/s_y) = r (correlation coefficient)
- New intercept β₀* = 0
- Standardized model: Y* = r·X* + ε*

### Scenario RS3: Min-Max Scaling

Scaling variables to range [0,1]:
- X* = (X - min(X))/(max(X) - min(X))
- Y* = (Y - min(Y))/(max(Y) - min(Y))

Effects:
- Slope changes by factor (max(Y) - min(Y))/(max(X) - min(X))
- Transformed variables bounded between 0 and 1
- Preserves the shape of the relationship

## Inferential Implications

### Theorem RI1: Statistical Significance

The statistical significance (p-value) of the slope coefficient remains unchanged under linear transformations of X and Y.

Formally:
- t-statistic for β₁* equals t-statistic for β₁

### Theorem RI2: Confidence Intervals

Confidence intervals transform according to the rescaling applied:
- CI(β₁*) = (c/a)·CI(β₁)
- CI(β₀*) transforms in a more complex manner due to the dependence on both β₀ and β₁

### Theorem RI3: Prediction Intervals

Prediction intervals for Y* given X* transform according to the scaling factor c:
- PI(Y*|X*) = c·PI(Y|X) + d

## Practical Applications

### Application RA1: Interpretability Enhancement

Rescaling to meaningful units can improve the interpretability of regression coefficients.

Example:
- Original: Weight(g) = β₀ + β₁·Height(cm) + ε
- Rescaled: Weight(kg) = β₀* + β₁*·Height(m) + ε*
- Interpretation of β₁* becomes "expected weight change in kg per meter of height"

### Application RA2: Numerical Stability

Rescaling can improve numerical stability in computation.

Example:
- When X values are very large, rescaling can prevent numerical overflow/underflow
- When X values have different scales, standardization helps in comparing their effects

### Application RA3: Comparative Analysis

Standardization enables direct comparison of effects across different variables and studies.

Example:
- Standardized coefficients allow comparison of the relative importance of predictors
- Meta-analysis can compare standardized effects across different studies

## Cautions and Limitations

### Caution RC1: Intercept Interpretation

After rescaling, the intercept may lose its original interpretation, especially if the rescaled X=0 point falls outside the data range.

### Caution RC2: Non-Linear Transformations

This framework applies only to linear transformations. Non-linear transformations (log, square root, etc.) fundamentally change the model structure.

### Caution RC3: Reporting

When reporting results from rescaled regression, always clearly specify:
- The transformation applied
- The units of the transformed variables
- How to convert results back to the original scale