---
name: axiom-create
description: 建立新的公理化領域或在既有領域新增公理/定理。載入 ASBE 方法論引導結構化建立。
user_invocable: true
---

# axiom-create

建立或擴充公理化系統。

## 流程

### Step 1: 確認操作

問使用者要做什麼：
- **建立新領域** — 從零開始一個新的公理化領域
- **擴充既有領域** — 在已有的領域中新增公理或定理

### Step 2: 如果是新領域

1. 詢問領域名稱和範圍描述
2. 讀取 `foundations/asbe-methodology.md` 載入 ASBE 方法論
3. 讀取 `templates/domain-template.yaml` 作為起點
4. 引導使用者定義：
   - **Primitive terms** — 此領域的基本未定義概念
   - **第一批公理** — 遵循 ASBE A1-A5：
     - 每條公理要有 `statement_natural` + `statement_formal` (A1)
     - 每條公理要有 `violations` + `compliant` 範例 (A2)
     - 公理之間要獨立、一致、充分 (A4)
5. 在 `domains/<domain-name>/` 建立檔案
6. 讀取 `foundations/cross-domain-principles.md`，檢查新公理是否與其他領域矛盾

### Step 3: 如果是擴充既有領域

1. 列出 `domains/` 中的所有領域讓使用者選擇
2. 讀取該領域的現有公理
3. 引導使用者新增：
   - **新公理** — 必須與既有公理獨立（A4）
   - **新定理** — 必須標明 `derives_from` 指向父公理（A3）
   - **新範例** — 可以為既有公理補充 violations/compliant
4. 遵循 SCD2 原則：只新增，不修改既有公理
5. 檢查跨域一致性

### Step 4: 品質檢查

建立完成後，自動執行快速驗證：
- 每條新公理/定理是否有雙層表達？
- 每條是否有至少一個 violation 和一個 compliant 範例？
- ID 命名是否遵循慣例（A/T/C/R prefix）？
- 是否有與其他領域的潛在矛盾？

如果有問題，提示使用者修正。

## 完成後提示

> 新增完成。建議執行 `/axiom-validate` 做完整驗證。
