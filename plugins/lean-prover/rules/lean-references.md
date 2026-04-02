# Lean 4 引用規則

## 引用已證結果必須用 import，不能用 axiom

如果一個結果已經在別的 Lean 4 專案裡證明過了，引用它的方式是：

1. **用 `lake` dependency** 把那個專案加進 `lakefile.toml`
2. **用 `import`** 在 `.lean` 檔裡引入
3. **直接使用** 已證明的 theorem/lemma

禁止：
- 把已證結果重新聲明為 `axiom` — 這不是引用，是偷懶
- 把已證結果的結論寫成 `True` 然後 `trivial` — 這是假裝
- 複製貼上別的專案的證明 — 應該用 dependency

## 可引用的專案

| 專案 | 路徑 | 內容 |
|------|------|------|
| Leanist | `~/Academic/projects/active/formal_verification/Leanist` | Lehmann (1999) 大樣本理論 |
| Mathlib | lake dependency | 數學庫 |

## 加入 lake dependency 的方式

```toml
# lakefile.toml
[[require]]
name = "leanist"
path = "../../../formal_verification/Leanist"
```

然後在 `.lean` 檔裡：
```lean
import Leanist.LargeSampleTheory.Ch0_Foundations
```

## axiom 的正確使用時機

- 結果尚未在任何 Lean 4 專案中證明
- 結果來自教科書/論文，且標註來源（作者、年份、頁碼）
- 結果是深層的數學事實（如 Neveu 的 UI 定理），不是已有形式化的重複

## 來源標註格式

```lean
/-- [Neveu (1965) p.54, Thm A.1]
    [Hoadley (1971) Appendix, p. 1988]
    [Lehmann (1999) Ch2 Thm 2.7.1 — formalized in Leanist] -/
axiom some_result ...
```
