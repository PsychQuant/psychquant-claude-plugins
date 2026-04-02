# Lean 定理引用規則

證明定理時，只能引用以下來源：

1. **Ch0_Foundations.lean** 的公理（A1–A6）和定義
2. **同一章前面已經證明的定理**（不能引用後面的）
3. **Mathlib** — 僅限 Ch0 層級的基礎結構（ℝ 的性質、測度空間定義、基本分析）。如果證明過程中發現需要新的 Mathlib 模組，可以加到 Ch0 的 import 作為新的公理層依賴

禁止：
- 直接從 Mathlib 引用一個跟當前定理等價的結果（那只是索引，不是推導）
- 跨章往後引用（Ch2 不能引用 Ch3 的東西）
- 引用未證明的 sorry 定理
- **Tautological 定理**：假設和結論形式相同（`:= hclt`、`:= hcons`）不算證明。定理的假設必須比結論更弱（更基本的條件），結論是從假設推導出來的。寧可留 sorry 也不要用 tautological 偽裝完成
- **`True := trivial` stub**：結論型別為 `True` 的定理不算形式化。必須給出正確的 Lean 4 類型簽名（即使 proof body 是 sorry）

# 章節內檔案結構

每章的 `.lean` 檔按以下順序排列：

1. **前置定義**（Preliminary definitions）
   - 跨小節使用的定義（如 `ConvergesInProb`、`BoundedInProb`、`IsLittleOP`）
   - 集中在檔案最前面，不依附於特定小節

2. **前置引理**（Preliminary lemmas）
   - 跨小節依賴的輔助引理（如 `conv_prob_scalar`、`conv_prob_bounded`）
   - 在書中屬於較後的小節，但被較前的定理引用
   - 例如：Lemma 2.3.1 (`bounded_times_op1`) 被 Thm 2.1.3 (`conv_prob_mul`) 使用，所以提前放置

3. **各小節定理**（§2.1, §2.2, ...）
   - 按書的順序排列
   - 可以引用前置區和同節前面的定理

書中跳過的證明（如 "see Problem X.Y"）表示存在隱含的依賴。在 Lean 裡必須讓被依賴的引理先出現。

Lean 4 從上到下編譯，不允許前向引用。一個定理壞掉 → 之後所有定理都「找不到」。
