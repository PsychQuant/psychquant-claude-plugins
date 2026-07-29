---
name: person-search
description: 用 Akashic-Library 依人物檢索文獻——找人、消歧、聚合著作與合著者、追關係。當使用者想「找某位作者的所有文章」「這個人跟誰合作過」「某人在某個 library 的著作」時使用。需要 akashic-mcp ≥ v0.2.0（含 akashic_person tool）。
---

# 人物檢索（person-search）

以 person 為中心檢索 Akashic library。核心工具：`akashic_person`。

## Workflow：找人 → 消歧 → 聚合 → 追關係

### 1. 找人（模糊姓名 → 候選）

不確定 person key 時，先用姓名拿候選——**絕不自動選定**，把候選列給使用者挑：

```
akashic_person(name: "cheng")
→ {"candidates": [{"person_key": "cheng-che", "names": ["Che Cheng", "鄭澈"], "publications": 3},
                  {"literal": "Cheng-Hsien Li", "publications": 1}]}
```

- `person_key` 候選＝已解析的人物實體（people/）
- `literal` 候選＝尚未解析的裸字串作者——若確認是同一人，建議走 `akashic_resolve_people` 正式解析（絕不批次自動套用）

### 2. 消歧（literal 候選 → person 實體）

候選裡出現該解析而未解析的 literal 作者時，用 `akashic_resolve_people`（逐候選 accept/skip，
絕不自動合併）把 literal 轉成 person key——人物檢索的品質取決於 people 實體的整理程度。

### 3. 聚合（person key → 全貌）

```
akashic_person(key: "cheng-che")
→ {"person": {"key": "cheng-che", "names": [...]},
   "publications": [...EntrySummary...],
   "co_authors": [{"person_key": "yang-hau-hung", "name": "...", "count": 2},
                  {"name": "Ulf Olsson", "count": 1}]}   # 無 person_key＝literal 合著者
```

限定 library 視角（#13 membership views）：`akashic_person(key: "cheng-che", library: "sinica")`。

### 4. 追關係

拿到 citekey 之後接既有工具：
- `akashic_relations(citekey:, kind: "cites"/"cited-by"/"same-author"/...)` 追引用鏈
- `akashic_graph(focus:, depth:)` 畫鄰域圖（person 節點會出現）
- `akashic_get_entry(citekey:)` 看完整 entry（含 `akashic.libraries` membership）

## 紀律

- 模糊名的選定永遠交給使用者（candidates 不自動挑第一個；上限 50、超出標 truncated）
- key 與 name 互斥（同給會被拒）
- 查無此人（notFound）≠ 資料庫壞——可能是 literal 未解析；退一步用 `name:` 模糊查
- library 過濾只在 key 直查生效；未指定＝全集（阿卡夏＝記錄一切）
