---
description: 重跑最近一次 batch-ocr session 的 permanent_failures (尚未成功的 PDF)
argument-hint: "[session-id]  # 留白 = 最近一次 session"
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/batch-ocr.sh:*, ls:*, sort:*, head:*, find:*, xargs:*, macdoc:*, curl:*, mkdir:*, cat:*), Read, Glob
---

# /batch-ocr-resume

重跑最近一次 batch-ocr session 的 permanent_failures。

## 使用方式

```
/batch-ocr-resume                # 自動找最近 session
/batch-ocr-resume 20260507-1430  # 指定 session-id
```

執行 script:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/batch-ocr.sh" --resume $ARGUMENTS
```

## 行為

- 找 `.batch-ocr/<session>/permanent_failures.log`
- 對每個失敗 PDF 重跑 Phase 1 / 2 / 3 (skip 已成功的 page)
- 結果寫入新的 `.batch-ocr/<new-session>/log`
