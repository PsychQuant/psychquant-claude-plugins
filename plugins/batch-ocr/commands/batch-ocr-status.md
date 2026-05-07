---
description: 顯示最近一次或指定 batch-ocr session 的進度統計 (success/failure/skip/ETA)
argument-hint: "[session-id]  # 留白 = 最近一次 session"
allowed-tools: Bash(ls:*, sort:*, head:*, wc:*, awk:*, find:*, cat:*, date:*), Read, Glob
---

# /batch-ocr-status

顯示 batch-ocr session 的進度統計。

## 使用方式

```
/batch-ocr-status                # 最近 session
/batch-ocr-status 20260507-1430  # 指定 session
```

## 報表內容

```
Session: 20260507-1430
─────────────────────
Input directory: /path/to/pdfs
PDFs total:      77
PDFs done:       62  (80.5%)
PDFs failed:     3
PDFs skipped:    0   (already had final .md)

Pages total:     1240
Pages done:      1023 (82.5%)
Pages failed:    8
Pages pending:   209

Started:         2026-05-07 14:30:12
Last activity:   2026-05-07 15:45:33
Elapsed:         1h 15m
ETA:             ~18 min (linear extrapolation)
```

執行 logic:scan `.batch-ocr/<session>/log` 統計 success / failure / skip lines,計算 ETA = elapsed / done × pending。
