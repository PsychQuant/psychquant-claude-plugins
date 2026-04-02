# Mathlib v4.28.0 常用 API 速查

寫 Lean 證明時先查這裡，不要猜 API 名字。

## Measure Theory (ENNReal)

| 用途 | API | 備註 |
|------|-----|------|
| P(Ω) = 1 | `measure_univ` | for `IsProbabilityMeasure` |
| P(∅) = 0 | `measure_empty` | |
| P(A) ≤ P(B) | `measure_mono (h : A ⊆ B)` | |
| P(A∪B) ≤ P(A)+P(B) | `measure_union_le A B` | subadditivity |
| P(Aᶜ) = P(univ) - P(A) | `measure_compl (hA : MeasurableSet A) (h : P A ≠ ⊤)` | |
| (E∩F)ᶜ = Eᶜ∪Fᶜ | `Set.compl_inter` | De Morgan |
| S∪Sᶜ = univ | `Set.union_compl_self _` | |
| {f ≤ g} measurable | `measurableSet_le (hf : Measurable f) (hg : Measurable g)` | 注意順序 |

## ENNReal 運算

| 用途 | API | 備註 |
|------|-----|------|
| a - (a - b) ≤ b | `tsub_tsub_le` | 截斷減法 |
| a ≤ b → c - b ≤ c - a | `tsub_le_tsub_left` | |
| a - (a - b) = b | `ENNReal.sub_sub_cancel (ha : a ≠ ⊤) (hb : b ≤ a)` | |
| η/2 + η/2 = η | `ENNReal.add_halves η` | |
| Tendsto f → Tendsto (c*f) | `ENNReal.Tendsto.const_mul hm (Or.inr h)` | h : c ≠ ⊤ |
| Tendsto f → Tendsto (f-g) | `ENNReal.Tendsto.sub hf hg (Or.inl h)` | h : a ≠ ⊤ |
| ofReal a ≤ ofReal b ↔ a ≤ b | `ENNReal.ofReal_le_ofReal_iff (hb : 0 ≤ b)` | 條件在 b |
| Tendsto → ∀ε∃N∀n≥N f≤ε | `ENNReal.tendsto_atTop_zero` | iff 版本 |
| ℝ → ENNReal | `ENNReal.ofReal` | 負數映射到 0 |
| ENNReal → ℝ | `.toReal` | ∞ 映射到 0 |
| ℝ 的 Tendsto → ENNReal | `ENNReal.tendsto_ofReal` | |

## Bochner 積分 (ℝ 值)

| 用途 | API | 備註 |
|------|-----|------|
| ∫ c dP = c | `bridge_integral_const P c` | **Ch0 bridge** |
| ∫ (c*f) = c * ∫ f | `bridge_integral_mul_left P c f` | **Ch0 bridge** |
| ∫ (f+g) = ∫f + ∫g | `bridge_integral_add P hf hg` | **Ch0 bridge**, 需要 Integrable |
| 0 ≤ ∫ f | `integral_nonneg (fun ω => h ω)` | 當 f ≥ 0 |
| ∫ f ≤ ∫ g | `integral_mono hf_int hg_int hle` | pointwise f ≤ g |
| ofReal(∫ f) = ∫⁻ ofReal(f) | `bridge_ofReal_integral_eq_lintegral P hint hnn` | **Ch0 bridge** |
| Integrable (c*f) | `hint.const_mul c` | |
| Integrable const | `integrable_const c` | |
| Integrable (f+g) | `hf.add hg` | |

**注意**：`integral_mul_left` 不存在於 Bochner！用 `bridge_integral_mul_left`。
**注意**：`integral_const` 回傳 `P.real Set.univ • c`，不是 `c`！用 `bridge_integral_const`。

## Topology / Filters

| 用途 | API | 備註 |
|------|-----|------|
| squeeze | `tendsto_of_tendsto_of_tendsto_of_le_of_le hg hh hgf hfh` | g ≤ f ≤ h |
| squeeze_zero | `squeeze_zero hnn hle hupper` | 0 ≤ f ≤ g → 0 |
| const → const | `tendsto_const_nhds` | |
| f₁ = f₂ → Tendsto 轉換 | `Filter.Tendsto.congr (h : ∀ x, f₁ x = f₂ x) ht` | 注意參數順序 |
| Eventually ∀ | `Eventually.of_forall` | |
| ContinuousAt 定義 | `ContinuousAt` = `Tendsto f (nhds a) (nhds (f a))` | |
| ContinuousAt ε-δ | `Metric.continuousAt_iff` | |
| dist on ℝ | `Real.dist_eq : dist x y = \|x - y\|` | |
| ContinuousAt (H∘L) → H | `bridge_continuousAt_of_affine_comp hb hcont` | **Ch0 bridge**, L affine |

## 實數 / 絕對值

| 用途 | API | 備註 |
|------|-----|------|
| \|x\| < a ↔ -a < x ∧ x < a | `abs_lt` | **常用！** |
| \|a-b\| < c ↔ a-b < c ∧ b-a < c | `abs_sub_lt_iff` | **注意**：`.1` 是 `a-b<c`，`.2` 是 `b-a<c` |
| \|x\| = \|x\| | `abs_abs` | |
| ‖x‖ = \|x\| | `Real.norm_eq_abs` | |
| 0 ≤ x² | `sq_nonneg x` | |
| \|x*y\| = \|x\|*\|y\| | `abs_mul x y` | |
| a/b * b = a | `mul_div_cancel_left₀ (b) (ha : a ≠ 0) : a * b / a = b` | 注意：b 是第一個顯式參數 |
| x ≠ 0 from 0 < x | `hx.ne'` | 不是 `ne_of_gt` |

## 不存在或改名的 API

| 你可能會猜的名字 | 實際情況 | 替代方案 |
|------------------|---------|---------|
| `abs_add` | **不存在** | 用 `abs_lt` 分解兩邊 |
| `integral_mul_left` (Bochner) | **不存在** | `bridge_integral_mul_left` |
| `ENNReal.one_toReal` | **不存在** | `show (1:ENNReal).toReal = 1 from rfl` |
| `Measurable.abs` | **不存在** | `Measurable.comp measurable_norm` |
| `AEStronglyMeasurable.pow_const` | **不存在** | `bridge_aestronglyMeasurable_sq` |
| `Finset.nonempty_range_succ` | **改名** | `Finset.nonempty_range_add_one` |
| `Finset.sup` on ℝ | **需要 OrderBot** | 用 `⨆ i ∈ range n, ...` |
| `λ` (lambda) | **保留字** | 用 `fun` |

## Ch0 Bridge Lemmas 總覽

```
bridge_norm_eq_abs          : ‖x‖ = |x|
bridge_integral_eq_lintegral : ∫ f = (∫⁻ f).toReal (nonneg)
bridge_ofReal_integral_eq_lintegral : ofReal(∫ f) = ∫⁻ ofReal(f)
bridge_abs_set_eq_enorm_set : {ε ≤ |f|} = {ofReal ε ≤ ‖f‖ₑ}
bridge_integral_const       : ∫ c dP = c
bridge_integral_mul_left    : ∫ (c*f) = c * ∫ f
bridge_integral_add         : ∫ (f+g) = ∫ f + ∫ g
bridge_aestronglyMeasurable_sq : f ASM → f² ASM
bridge_integrable_sq_of_bound : f² ≤ c·g²+d, g² integrable → f² integrable
bridge_continuousAt_of_affine_comp : ContinuousAt (H∘L) x → ContinuousAt H (Lx)
A5_markov_sq                : ε²·P{|f|≥ε} ≤ ∫⁻ f²
A3_compl, A3_union_le, A3_mono, A3_range, A3_compl_tendsto_zero, A3_sub_sub_cancel
```
