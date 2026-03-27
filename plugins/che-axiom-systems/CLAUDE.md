# che-axiom-systems

跨領域形式化公理體系。目標：將所有知識領域公理化。

## 結構

- `foundations/` — 元層級：跨領域原則 + ASBE 方法論
- `domains/` — 各知識領域的公理化系統
- `templates/` — 建立新領域的模板
- `skills/` — 三個操作 skill

## Skills

| Skill | 用途 |
|-------|------|
| `axiom-create` | 建立新領域或在既有領域新增公理 |
| `axiom-validate` | 驗證結構完整性 + 跨域一致性 |
| `axiom-lookup` | 全域搜尋公理 |

## 核心原則

1. **SCD2 (Add Only)** — 公理只能新增，不能修改或刪除
2. **Domain Independence** — 各領域自成體系
3. **Consistency Requirement** — 跨領域不得矛盾
4. **ASBE Compliance** — 每條公理需雙層表達 + 範例錨定

## 領域清單

掃描 `domains/` 目錄取得最新清單。
