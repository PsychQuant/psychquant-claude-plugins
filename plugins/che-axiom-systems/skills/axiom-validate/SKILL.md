---
name: axiom-validate
description: 驗證公理化系統的結構完整性（ASBE 合規）和跨領域一致性（無矛盾）。
user_invocable: true
---

# axiom-validate

驗證公理化系統品質。兩個層級的檢查。

## 流程

### Step 1: 選擇驗證範圍

問使用者：
- **單一領域** — 驗證某個 domain 的結構完整性
- **跨領域一致性** — 檢查所有 domain 之間是否有矛盾
- **全部** — 兩者都做

### Step 2: 結構驗證（Domain 內）

讀取 `foundations/asbe-methodology.md` 中的 ASBE 5 條公理作為檢查標準。

對目標 domain 中的每條公理/定理，檢查：

| ASBE 公理 | 檢查項目 | 嚴重度 |
|-----------|----------|--------|
| A1 雙層表達 | 有 `statement_natural` 和 `statement_formal`？ | ERROR |
| A2 範例錨定 | 有至少 1 個 `violations` 和 1 個 `compliant`？ | ERROR |
| A3 層級推導 | 非公理的項目有 `derives_from`？DAG 無環？ | ERROR |
| A4 最小公理集 | 公理之間是否獨立？有無冗餘？ | WARNING |
| A5 語意等價 | natural 和 formal 表達同一件事？ | WARNING |

另外檢查：
- ID 命名慣例（A/T/C/R prefix）
- `meta` 欄位完整性（domain, version, author）
- SCD2 合規：與上一版本相比，有無修改或刪除既有公理

輸出格式：
```
📋 Domain: statistics
   ✅ A1 Dual Expression: 12/12 pass
   ❌ A2 Example Grounding: 10/12 pass — A7, T3 missing violations
   ✅ A3 Hierarchical Derivation: OK
   ⚠️  A4 Minimal Axiom Set: A3 may be derivable from A1+A2
   ✅ A5 Semantic Equivalence: OK
```

### Step 3: 跨領域一致性檢查

1. 讀取 `foundations/cross-domain-principles.md`
2. 掃描所有 `domains/` 中每個領域的公理摘要
3. 識別**重疊概念** — 不同領域涉及相同概念的公理（例如 statistics 和 decision-making 都涉及 probability）
4. 對重疊的公理對，分析是否存在矛盾
5. Flag 潛在衝突，附上理由，讓使用者 review

輸出格式：
```
🔗 Cross-Domain Consistency Check
   Scanned: 12 domains, 87 axioms total

   ⚠️  Potential overlap:
   - statistics/A3 (probability interpretation) ↔ decision-making/A2 (subjective probability)
     Analysis: Compatible — statistics uses frequentist framing,
     decision-making uses Bayesian framing. No contradiction,
     but consider adding cross-reference annotation.

   ✅ No contradictions detected.
```

### Step 4: 報告

彙總所有發現：
- ERROR: 必須修正
- WARNING: 建議修正
- INFO: 跨域觀察

提示使用者是否要立即修正（遵循 SCD2 — 修正方式是新增澄清，不是修改原文）。
