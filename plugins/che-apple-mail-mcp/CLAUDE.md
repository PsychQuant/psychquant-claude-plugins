# che-apple-mail-mcp

Apple Mail MCP server for macOS,加上 NSQL-derived confirmation protocol。

## Components

### MCP Server
- **mail** ← `bin/che-apple-mail-mcp-wrapper.sh`(Swift binary)
- 提供 44+ tools 操作 Apple Mail.app:list/search/get/compose/move/delete/attachment

### Commands
- `/archive-mail` — 歸檔指定聯絡人的郵件到 Markdown(v2.7.0+ 加入 confirmation phases)
- `/archive-mail-view` — 從 `.threads.json` 生成 thread 聚合視圖
- `/archive-mail-rebuild-threads` — 從 per-email md 重建 thread index

### Skills(v2.7.0+ 新增)
- `confirmation-protocol` — NSQL-style confirmation workflow,在執行前 show preview 讓 user confirm/correct
- `email-search-disambiguation` — 處理模糊 filter(中文人名、相對時間、通用 scope)
- `bulk-operation-preview` — ≥ 5 封 emails 的 preview format,含 false-positive flagging

### Rules(v2.7.0+ 新增)
- `confirmation-triggers.md` — 何時必 confirm、何時可 skip
- `false-positive-detection.md` — Search 結果中偵測 sibling activity / CC pollution / subject collision

## 設計哲學

### NSQL Confirmation Protocol

借鑑 [`/Users/che/Developer/nsql`](file:///Users/che/Developer/nsql) 的核心 insight:

> AI 不直接執行,先 show 結構化的「我理解你要的是這樣」讓 user confirm/correct/reject,achieve consensus 後才執行。

原始 nsql 設計給 SQL/data query;這裡 adapt 到 Apple Mail。觸發 confirmation 的 4 個常見情境:

1. **Filter 模糊**:「陳老師」、「最近的信」、「VIP 寄來的」 → disambiguation
2. **Bulk operation**:search 結果 ≥ 5 封 → preview + false-positive flagging
3. **Destructive**:delete_email、empty Trash → operation confirmation
4. **Compose 寄出**:compose_email、reply_email → 信件 preview

### 為什麼這個 protocol 重要(real case)

2026-05-01 archive 陳老師信件時,直接 search → fetch 19 封 → 寫 markdown,事後發現 265250 是 false positive(寄給 scchen 不是 cchen),又走一輪 rm + index 修復。

如果有 confirmation skill,Phase 2 (search preview) 會 flag 這封並讓 user 排除,完全 prevent false-positive round trip。從 v2.7.0 開始,archive-mail 預設套用這個 protocol。

## 4-Phase Confirmation Workflow

```
user request
  │
  ▼
Phase 1: Disambiguation
  └─ 模糊 filter → 列出候選讓 user 選
  └─ 由 email-search-disambiguation skill 負責
  │
  ▼
Phase 2: Search Preview
  └─ 展示 search 結果(thread 分布)
  └─ Flag false-positive 候選
  └─ 由 bulk-operation-preview skill 負責
  │
  ▼
Phase 3: Operation Confirmation
  └─ 展示 side-effect scope(N files written, K attachments, etc.)
  └─ Destructive op 加警告
  │
  ▼
Phase 4: Execute or Iterate
  └─ User 確認 → 執行
  └─ User 修改 → 回 Phase 1/2/3
  └─ User 拒絕 → abort
```

## Skip confirmation 的條件

可以直接執行(skip protocol):

- 明確 Message-ID 的 read-only 操作
- 單封 mark_read / unflag
- 純 search/list(沒 side effect)
- User 說「直接做,不要問」

詳見 `rules/confirmation-triggers.md`。

## Use Cases

### Case 1: 完整流程(filter 模糊 + bulk + read-only)

```
user: 把陳老師有關的信都歸檔

AI [Phase 1]: 「陳老師」可能對應到 cchen / scchen / 其他?
user: cchen
AI [Phase 2]: 找到 19 封,7 個 threads。⚠ 1 個是 sibling activity 不該歸入。要排除嗎?
user: 排除
AI [Phase 3]: 我將寫 18 個 markdown + 下載 1 個附件 + 寫 2 個 index。確認?
user: 對
AI [Phase 4]: [執行]
```

### Case 2: 明確 filter(skip Phase 1)

```
user: archive cchen@stat.sinica.edu.tw 過去一週

AI [skip Phase 1]: filter 明確,跳過 disambiguation
AI [Phase 2]: 找到 3 封,沒 false positive。
AI [Phase 3]: 寫 3 個 markdown。確認?
user: 對
AI [Phase 4]: [執行]
```

### Case 3: Destructive(必 Phase 3)

```
user: 把 spam@example.com 的信全部刪掉

AI [Phase 2]: 找到 247 封 spam emails。沒 false positive。
AI [Phase 3]:
   DELETE on Mail
   with sender = "spam@example.com"
   affecting 247 emails
   ⚠ 進 Trash 後 30 天清除,可在那之前 undo
   確認?
user: 確認
AI [Phase 4]: [執行]
```

### Case 4: Read-only single op(完全 skip)

```
user: get_email id=12345

AI: [直接執行,沒 confirmation]
```

## Configuration

`.claude/emails.md` frontmatter 可以調整 plugin 行為:

```yaml
---
filters:
  - cchen
  - coco891017
participant_aliases:
  "陳老師": cchen@stat.sinica.edu.tw
  "林助理": coco891017@webmail.stat.sinica.edu.tw
subject_keywords_strict: true   # 不允許單純 subject match 算 hit
attachment_routing:
  data_extensions: [csv, sav, xlsx]
  data_dir: data/raw
  documents_dir: communications/attachments
---
```

## Version History

- **v2.7.0**(2026-05-01)— **NSQL confirmation protocol**:加 3 skills + 2 rules + CLAUDE.md。archive-mail 預設套用 4-phase confirmation workflow。Backward compatible:精確 filter 仍可直接執行
- v2.6.0 — archive-mail YAML frontmatter + .threads.json + view/rebuild commands
- v2.5.0 — composing tools format 參數
- v2.4.0 — search expansion + Coverage Audit
- v2.3.0 — attachment auto-download + 分流

## 相關

- `/Users/che/Developer/nsql/protocol.yaml` — 原始 NSQL Confirmation Protocol spec
- `/Users/che/Developer/nsql/docs/concept.md` — NSQL whitepaper
- `commands/archive-mail.md` — Archive workflow(含 confirmation phases)
