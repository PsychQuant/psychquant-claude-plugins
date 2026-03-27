# Weight Control Core Axioms

**體重控制核心公理**

This document defines the foundational axioms of the CHONNa weight control theory — a rigorous framework for understanding body weight dynamics through elemental mass balance.

---

## Meta-Language Declaration

This document uses **semi-formal mathematical notation**:

| Component | Description |
|-----------|-------------|
| **First-order logic** | ∀ (for all), ∃ (exists), → (implies), ∧ (and) |
| **Differential calculus** | d/dt (time derivative), Δ (discrete change), ∫ (integral) |
| **Set notation** | ∈ (element of), Σ (sum over set) |
| **Units** | SI units (kg, g, L, mol) with explicit annotation |

---

## Primitive Terms

| Term | Intuition |
|------|-----------|
| `Body` | The human organism as a thermodynamic system |
| `Mass` | Quantity of matter (kg or g) |
| `Element` | Atomic species (C, H, O, N, Na, etc.) |
| `Compartment` | Functional storage pool (glycogen, fat, muscle, etc.) |
| `Flux` | Rate of mass transfer (g/day) |

---

## Level 0: Physics Axioms

### A0. Conservation of Mass (質量守恆公理)

```
Natural Language:
  Mass cannot be created or destroyed in ordinary chemical reactions.
  All body weight changes result from matter entering or leaving the body.

Formal:
  ∀ system S, dM_S/dt = Σ(ṁ_in) - Σ(ṁ_out)
  where ṁ = mass flow rate (g/s)

Rationale:
  This is the fundamental physics that all subsequent axioms derive from.
  Unlike "calories," mass is directly measurable and conserved.
```

**Violation Example**:
> "I gained 2 kg overnight from eating one slice of cake (50g)."
>
> *Why it violates*: Mass in = mass gain is impossible. The 50g cake cannot produce 2000g body mass. The weight gain must include water retention.

**Compliant Example**:
> "I ate 300g of food and drank 500mL water. My weight increased ~800g."
>
> *Why it complies*: Input mass ≈ weight change (minus small losses).

---

## Level 1: Element Axioms (CHONNa)

### A1. Carbon Conservation (碳守恆公理)

```
Natural Language:
  Body carbon changes equal carbon consumed minus carbon excreted.
  Carbon leaves primarily through breath (CO₂) and excretion.

Formal:
  ΔC_body = C_food - (C_CO₂ + C_urea + C_feces + C_other)

  where:
    C_food = Σ(m_i × ρ_C,i)  for each food item i
    C_CO₂ = V_CO₂ × 0.536 g C/L
    ρ_C = {carb: 0.40, fat: 0.77, protein: 0.53}

Rationale:
  Carbon is the primary structural element of organic molecules.
  Fat is 77% carbon; losing fat means exhaling carbon as CO₂.
```

**Violation Example**:
> "I'm not losing weight because I'm not sweating enough."
>
> *Why it violates*: Fat loss occurs through CO₂ exhalation, not sweat. Sweat is mostly water.

**Compliant Example**:
> "I lost 1 kg of fat, which means I exhaled about 2.8 kg of CO₂ (770g C × 44/12)."
>
> *Why it complies*: Correctly traces carbon from fat to breath.

---

### A2. Hydrogen Conservation (氫守恆公理)

```
Natural Language:
  Body hydrogen changes through water and macronutrient metabolism.
  Hydrogen is gained from food and water; lost through all water outputs.

Formal:
  ΔH_body = H_food + H_water - (H_urine + H_sweat + H_breath + H_feces)

  where:
    H_water = m_water × 0.111
    H from macros = {carb: 0.067, fat: 0.103, protein: 0.07}

Rationale:
  Hydrogen is primarily in water (11.1% by mass).
  Water balance is the main driver of short-term weight fluctuations.
```

**Violation Example**:
> "I lost 3 kg in 3 days on keto — that's 3 kg of fat!"
>
> *Why it violates*: 3 kg fat loss requires ~21,000 kcal deficit. Impossible in 3 days. Most loss is water (H₂O from glycogen depletion).

**Compliant Example**:
> "I lost 2 kg in the first week of low-carb. About 0.5 kg was fat, 1.5 kg was glycogen-bound water."
>
> *Why it complies*: Correctly partitions hydrogen loss between fat oxidation and water release.

---

### A3. Oxygen Conservation (氧守恆公理)

```
Natural Language:
  Body oxygen flows through respiration and water metabolism.
  Oxygen is inhaled, consumed in oxidation, and exhaled as CO₂ and H₂O.

Formal:
  ΔO_body = O_food + O_inhaled - (O_CO₂ + O_H₂O + O_urine)

  where:
    O_CO₂ = V_CO₂ × 1.429 g O/L (two O atoms per CO₂)
    O from macros = {carb: 0.533, fat: 0.124, protein: 0.22}

Rationale:
  Oxygen participates in all aerobic metabolism.
  Carbohydrates are oxygen-rich (53%); fats are oxygen-poor (12%).
```

**Violation Example**:
> "Burning fat produces no water — it all comes out as CO₂."
>
> *Why it violates*: Fat oxidation (C₁₆H₃₂O₂ + 23O₂ → 16CO₂ + 16H₂O) produces significant water.

**Compliant Example**:
> "Oxidizing 100g fat produces ~107g water (metabolic water) plus 280g CO₂."
>
> *Why it complies*: Correctly applies stoichiometry.

---

### A4. Nitrogen Conservation (氮守恆公理)

```
Natural Language:
  Body nitrogen tracks protein synthesis and breakdown.
  Positive nitrogen balance indicates muscle gain; negative indicates loss.

Formal:
  ΔN_body = N_protein_intake - (N_urea + N_ammonia + N_creatinine + N_feces)

  where:
    N_protein = m_protein × 0.16 (protein is ~16% nitrogen)
    N_urea = m_urea × 0.467

Rationale:
  Nitrogen is exclusive to proteins among macronutrients.
  Nitrogen balance is the gold standard for assessing muscle gain/loss.
```

**Violation Example**:
> "I'm in a caloric deficit but gaining muscle because I'm eating high protein."
>
> *Why it violates*: Muscle synthesis requires both nitrogen AND energy. Significant muscle gain in deficit is rare (except in beginners or those with high body fat).

**Compliant Example**:
> "I'm eating 150g protein (24g N). Excreting 20g N in urine. Net +4g N → ~25g muscle protein gained."
>
> *Why it complies*: Tracks nitrogen through the system.

---

### A5. Sodium Conservation (鈉守恆公理)

```
Natural Language:
  Sodium balance controls water distribution between compartments.
  Sodium retention causes water retention; sodium loss causes water loss.

Formal:
  ΔNa_body = Na_food - (Na_urine + Na_sweat + Na_feces)
  ΔH₂O_ECF ≈ 200 × ΔNa (g water per g sodium retained)

Rationale:
  Sodium is the primary determinant of extracellular fluid volume.
  This explains rapid weight changes after salty meals.
```

**Violation Example**:
> "I gained 2 kg from eating pizza. I need to eat less tomorrow to lose it."
>
> *Why it violates*: The 2 kg is primarily sodium-induced water retention. It will resolve as sodium is excreted, regardless of next-day eating.

**Compliant Example**:
> "I ate 5g extra sodium. Over 1-2 days I retained ~1 kg water. As I returned to normal sodium intake, the water was excreted."
>
> *Why it complies*: Correctly identifies sodium as the cause and predicts resolution.

---

## Level 2: Molecular Theorems

### T1. Macronutrient Composition Theorem

```
Derives from: A1, A2, A3, A4

Statement:
  Each macronutrient has a fixed elemental composition that determines
  its contribution to body weight change per gram consumed.

Formal:
  For macronutrient M with composition (C_M, H_M, O_M, N_M):

  | Macro        | C     | H     | O     | N     | Energy |
  |--------------|-------|-------|-------|-------|--------|
  | Carbohydrate | 0.400 | 0.067 | 0.533 | 0.000 | 4 kcal |
  | Fat          | 0.770 | 0.103 | 0.124 | 0.000 | 9 kcal |
  | Protein      | 0.530 | 0.070 | 0.220 | 0.160 | 4 kcal |
  | Alcohol      | 0.520 | 0.130 | 0.350 | 0.000 | 7 kcal |
```

---

### T2. Glycogen-Water Binding Theorem

```
Derives from: A2, A3

Statement:
  Glycogen storage requires water binding at a ratio of approximately 3-4g water per gram glycogen.

Formal:
  ΔM_glycogen_total = ΔM_glycogen × (1 + k_water)
  where k_water ≈ 3-4

Implication:
  Total glycogen capacity ≈ 500g
  Total weight swing from glycogen ≈ 500 × 4 = 2000g = 2 kg
```

**Violation Example**:
> "I lost 2 kg in 3 days of fasting — I burned 2 kg of fat."
>
> *Why it violates*: 2 kg fat = 18,000 kcal. Daily expenditure ~2000 kcal. 3 days = 6000 kcal = ~0.7 kg fat. Rest is glycogen + water.

**Compliant Example**:
> "In 3 days of fasting, I lost 0.7 kg fat, 0.4 kg glycogen, and 1.2 kg glycogen-bound water."
>
> *Why it complies*: Correctly partitions the weight loss.

---

### T3. Sodium-Water Coupling Theorem

```
Derives from: A2, A5

Statement:
  Extracellular water volume is coupled to total body sodium through osmotic equilibrium.

Formal:
  [Na⁺]_ECF ≈ constant (140 mEq/L)
  ∴ V_ECF ∝ Na_total
  ΔV_ECF ≈ ΔNa × (1000 mL / 140 mEq) ≈ ΔNa × 7 mL/mEq

  In mass terms:
  Δm_water ≈ 200 × Δm_Na (g/g)
```

---

### T4. Respiratory Exchange Theorem

```
Derives from: A1, A3

Statement:
  The respiratory quotient (RQ = VCO₂/VO₂) indicates substrate utilization.

Formal:
  RQ = 1.0  →  Pure carbohydrate oxidation
  RQ = 0.7  →  Pure fat oxidation
  RQ = 0.82 →  Pure protein oxidation (with urea production)

  Mixed diet RQ ≈ 0.85
```

---

## Level 3: Compartment Theorems

### T5. Storage Hierarchy Theorem

```
Derives from: T1, insulin physiology

Statement:
  When insulin is elevated, nutrients are stored in a priority order:
  Glycogen (if not full) → Fat (overflow)

Formal:
  IF Glycogen < Glycogen_max THEN
    Glucose → Glycogen (high priority)
  ELSE
    Glucose → De Novo Lipogenesis (low efficiency, ~75%)
```

---

### T6. Time Scale Separation Theorem

```
Derives from: Compartment dynamics

Statement:
  Different body compartments change at different characteristic time scales,
  allowing frequency-domain separation of weight signal components.

Formal:
  | Compartment | Time Constant τ | Frequency Domain |
  |-------------|-----------------|------------------|
  | Gut contents | 0.5-2 days | High frequency |
  | Glycogen | 1-2 days | High frequency |
  | ECF water | 1-3 days | Medium frequency |
  | Fat | 14-30 days | Low frequency |
  | Muscle | 14-30 days | Low frequency |
  | Bone | 60-365 days | Very low frequency |

Implication:
  Daily weight fluctuations are dominated by water/glycogen.
  Fat trends emerge only over 2+ weeks of data.
```

---

### T7. Fat Compartment Hierarchy Theorem (脂肪區隔層次定理)

```
Derives from: A1, A0

Statement:
  Body fat exists in distinct compartments with different metabolic
  properties and health implications. All compartments share the same
  elemental composition (~77% carbon).

Formal:
  Fat_total = Fat_subcutaneous + Fat_visceral + Fat_IMAT + Fat_ectopic

  Compartment properties:
  | Compartment    | % of Total | Health Risk | Mobilization |
  |----------------|------------|-------------|--------------|
  | Subcutaneous   | 80-90%     | Low         | Slow         |
  | Visceral       | 10-20%     | Very High   | Fast         |
  | IMAT           | Variable   | Medium      | Medium       |
  | Ectopic        | Variable   | Very High   | Fast         |

Carbon perspective:
  ∀ compartment ∈ {subcutaneous, visceral, IMAT, ectopic}:
    composition(compartment) ≈ C₅₅H₁₀₄O₆ (triglyceride)
    ρ_C(compartment) = 0.77

  ∴ ΔFat_any → ΔC_out (as CO₂)
  ∴ VCO₂ captures all fat compartment losses
```

**Violation Example**:
> "I'm losing belly fat but not visceral fat."
>
> *Why it violates*: Belly fat includes both subcutaneous and visceral. Visceral fat is actually preferentially mobilized during caloric deficit.

**Compliant Example**:
> "My waist circumference decreased by 5cm, indicating visceral fat reduction, while subcutaneous fat is reducing more slowly."
>
> *Why it complies*: Correctly distinguishes compartments and their different response rates.

---

### T8. Nitrogen Balance Protection Theorem (氮平衡保護定理)

```
Derives from: A4

Statement:
  During weight loss, nitrogen balance should be maintained near zero
  or positive to preserve muscle mass. Muscle is a protection target,
  not a reduction target.

Formal:
  Weight loss goal:
    ΔC < 0 (reduce carbon/fat)
    ΔN ≈ 0 (maintain nitrogen/muscle)

  If ΔN < 0:
    Muscle_loss = |ΔN| × 6.25 g protein
    This is undesirable.

  Strategies to maintain ΔN ≥ 0:
  ├── Protein intake: 1.6-2.2 g/kg/day during deficit
  ├── Resistance training: stimulates protein synthesis
  └── Moderate deficit: extreme deficits increase muscle loss
```

**Violation Example**:
> "I lost 10 kg in 2 weeks on a 500 kcal/day diet!"
>
> *Why it violates*: Extreme deficit + likely low protein → significant nitrogen loss → muscle wasting. Much of the "weight loss" is water and muscle, not fat.

**Compliant Example**:
> "I'm eating 1.8g protein/kg while in a 500 kcal deficit, and doing resistance training 3x/week to preserve muscle."
>
> *Why it complies*: Appropriate strategies to maintain ΔN ≈ 0 while achieving ΔC < 0.

---

## Level 3.5: Definitions

### D1. Weight Loss Target Definition (減重目標定義)

```
Definition:
  Body components are classified by their role in weight management:

  Primary targets (to be reduced):
    T_primary = {Fat_visceral, Fat_ectopic, Fat_subcutaneous, Fat_IMAT}

  Protection targets (to be preserved):
    T_protect = {Muscle, Bone, Essential_fat}

  Fluctuation components (not targets):
    T_fluctuation = {Water, Glycogen, Gut_content}

Carbon-centric simplification:
  T_primary ≡ {Carbon stored as fat}

  Since all fat compartments are ~77% carbon:
    Tracking ΔC_out (via VCO₂) captures all primary targets

  Successful weight loss:
    ΔC < 0 (carbon leaving)
    ΔN ≈ 0 (nitrogen maintained)
    ΔNa → stable (no chronic water retention)
```

---

## Level 4: Observability Rules

### R1. Weight Decomposition Rule

```
Derives from: T6

Statement:
  Given sufficient time series data, weight can be decomposed into:
  W(t) = W_slow(t) + W_fast(t) + ε(t)

  where:
  W_slow = fat + muscle (τ > 2 weeks)
  W_fast = glycogen + water (τ < 1 week)
  ε = measurement noise
```

---

### R2. Control Input Inference Rule

```
Derives from: A1-A5, T1-T4

Statement:
  Known dietary and activity inputs enable inference of compartment states.

Formal:
  P(x(t) | y(1:t), u(1:t))

  where:
  x = hidden state vector (fat, glycogen, water, ...)
  y = observations (weight, BIA, ...)
  u = control inputs (diet, exercise, ...)
```

---

## Revision History

| Date | Change |
|------|--------|
| 2026-01-01 | Initial axiom set (A0-A5, T1-T6, R1-R2) |
| 2026-01-01 | Added T7 (Fat Compartment Hierarchy), T8 (Nitrogen Balance Protection), D1 (Weight Loss Target Definition) |

---

*Weight Control Core Axioms*
*Version 1.0*
*CHONNa Framework*
