# Axiomatization of Weight Control

**體重控制的公理化系統**

A formal axiomatization system for understanding body weight dynamics, built on the CHONNa framework (Carbon, Hydrogen, Oxygen, Nitrogen, Sodium).

---

## Quick Start

### Core Documents (Read First)

| Document | Purpose |
|----------|---------|
| `README.md` | This file — project overview |
| `weight_dynamics_equation.md` | **核心方程：dW = -VO₂×f(RQ) dt + 跳躍項** |
| `carbon_control_thesis.md` | **核心命題：體重控制 = 碳原子控制** |
| `body_composition_targets.md` | **減重目標：脂肪分類與 CHONNa 對應** |
| `weight_loss_methods_analysis.md` | **方法分析：各種減重策略的效果比較** |
| `chonna_parameters.md` | **參數分類：物理常數 vs 生理參數** |
| `weight_control_axioms.md` | Core axioms and their derivations |
| `weight_control_axioms.yaml` | ASBE format specification |
| `core_problem_observability.md` | The central research question |

### Key Concept

```
Traditional view:    "Weight = Calories In - Calories Out"
                     (Energy balance - abstract, hard to measure)

CHONNa view:         "Weight = Σ (Element_in - Element_out)"
                     where Element ∈ {C, H, O, N, Na}
                     (Mass balance - physical law)

Carbon Control:      "Fat loss ≈ Carbon out (as CO₂)"
                     (Most direct, measurable via VCO₂)
```

> **核心洞見：減脂 = 呼出碳原子**
>
> 84% 的脂肪以 CO₂ 形式從肺部呼出。追蹤 VCO₂ 比追蹤卡路里更直接。

---

## The Axiom Hierarchy

```
Level 0: Physics (Foundational)
├── A0_mass_conservation
│
Level 1: Elements (CHONNa)
├── A1_carbon_conservation
├── A2_hydrogen_conservation
├── A3_oxygen_conservation
├── A4_nitrogen_conservation
└── A5_sodium_conservation
│
Level 2: Molecules (Derived)
├── T1_macronutrient_composition
├── T2_glycogen_water_binding
├── T3_sodium_water_coupling
└── T4_respiratory_exchange
│
Level 3: Compartments (Derived)
├── T5_storage_hierarchy
├── T6_time_scale_separation
├── T7_fat_compartment_hierarchy    ← NEW
└── T8_nitrogen_balance_protection  ← NEW
│
Level 3.5: Definitions
└── D1_weight_loss_target           ← NEW
│
Level 4: Observability (Applied)
├── R1_weight_decomposition
├── R2_trend_separation
└── R3_prediction_from_inputs
```

---

## The 5 Core Axioms

| ID | Name | Statement (Natural) | Statement (Formal) |
|----|------|---------------------|-------------------|
| A0 | Mass Conservation | Atoms cannot be created or destroyed | ∀X, ΔX = X_in - X_out |
| A1 | Carbon Balance | Body carbon changes by intake minus output | ΔC = C_food - (C_CO₂ + C_urea + C_feces) |
| A2 | Hydrogen Balance | Body hydrogen tracks water and macros | ΔH = H_food + H_water - H_output |
| A3 | Oxygen Balance | Body oxygen follows respiration and water | ΔO = O_inhaled + O_food - O_exhaled |
| A4 | Nitrogen Balance | Nitrogen tracks protein synthesis/breakdown | ΔN = N_protein - N_urea |
| A5 | Sodium Balance | Sodium controls water distribution | ΔNa → ΔH₂O (~200g H₂O / g Na) |

---

## Key Theorems

### T1: Macronutrient Carbon Density

| Macronutrient | C | H | O | N |
|---------------|---|---|---|---|
| Carbohydrate | 40% | 7% | 53% | 0% |
| Fat | 77% | 10% | 12% | 0% |
| Protein | 53% | 7% | 22% | 18% |

### T2: Glycogen-Water Binding

```
1g glycogen binds 3-4g water
∴ 500g glycogen depletion → 2kg weight loss
```

### T5: Storage Hierarchy

```
When insulin is elevated:
Glucose → Glycogen (priority) → Fat (overflow)
          ↑ only if glycogen not full
```

### T6: Time Scale Separation

| Compartment | Time Constant τ | Frequency |
|-------------|-----------------|-----------|
| Gut contents | 0.5-2 days | High |
| Glycogen | 1-2 days | High |
| Water/Electrolytes | 1-3 days | Medium |
| Fat | 2-4 weeks | Low |
| Muscle | 2-4 weeks | Low |
| Bone | Months-Years | Very Low |

---

## The Central Research Question

> **Given all available life information, can we infer the state of each body compartment?**

See `core_problem_observability.md` for full analysis.

**Short answer**: Not fully, but combining:
1. Time series structure (different τ)
2. Control inputs (diet, exercise)
3. Physiological constraints
4. Personal history

...enables substantial inference beyond raw weight tracking.

---

## Files in This Directory

```
Axiomatization of Weight Control/
├── README.md                          # This file
├── weight_dynamics_equation.md        # 🔴 核心方程：dW = -VO₂×f(RQ) dt + 跳躍項
├── carbon_control_thesis.md           # 🔴 核心命題：體重控制 = 碳原子控制
├── body_composition_targets.md        # 🔴 減重目標：脂肪分類與元素對應
├── weight_loss_methods_analysis.md    # 🔴 方法分析：各種減重策略效果比較
├── chonna_parameters.md               # 🔴 參數分類：物理常數 vs 生理參數
├── weight_control_axioms.md           # Core axioms (detailed)
├── weight_control_axioms.yaml         # ASBE format specification
├── core_problem_observability.md      # Central research question
├── complete_molecular_tracking.md     # All molecules to track
├── energy_balance_critique.md         # 傳統能量平衡觀點的問題
├── structural_constraints.md          # 結構性約束
├── element_pathways.md                # 元素流動路徑
├── apple_wearable_sensing.md          # Apple 穿戴式裝置代謝感測
│
├── archive/                           # Archived source documents
│   ├── CHONNa_*.md                   # CHONNa framework docs
│   ├── carbon_*.md                   # Carbon balance docs
│   ├── metabolic_*.md                # Metabolic state docs
│   └── ...                           # Other reference docs
│
└── 生化營養學/                        # Biochemistry reference (symlink)
```

---

## ASBE Format

This axiomatization follows [ASBE (Axiomatic Specification by Example)](../Axiomatic%20Specification%20by%20Example/README.md):

- **Dual Expression**: Natural language + Formal notation
- **Example Grounding**: Violations + Compliant examples
- **Hierarchical Derivation**: Axiom → Theorem → Rule

---

## Applications

| Application | Description |
|-------------|-------------|
| **iOS App** | precision-weight — Kalman Filter prediction |
| **Diet Planning** | Nutrient timing based on metabolic state |
| **Research** | Body composition estimation from life data |

---

## Related Work

- **Energy Balance Theory** (Traditional CICO)
- **Set Point Theory** (Metabolic adaptation)
- **Carbohydrate-Insulin Model** (Ludwig et al.)
- **Hall Mathematical Model** (NIH)

---

*Created: 2025 | Maintainer: Che Cheng*
