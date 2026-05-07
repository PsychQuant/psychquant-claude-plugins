---
description: 對整個目錄的 PDF 跑 OCR pipeline (split → parallel OCR → merge),idempotent + resume-able
argument-hint: <directory-of-pdfs> [--parallel N] [--host kyle] [--model glm-ocr] [--resume]
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/batch-ocr.sh:*, ${CLAUDE_PLUGIN_ROOT}/scripts/ensure-tunnel.sh:*, pdftoppm:*, macdoc:*, find:*, xargs:*, lsof:*, kill:*, ssh:*, curl:*, mkdir:*, cat:*, sort:*, awk:*), Read, Write, Glob
---

# /batch-ocr

對整個目錄的 PDF 跑 OCR pipeline,wrap macdoc CLI 加上 SSH tunnel 管理 + 並行 + idempotency。完整 workflow 見 `skills/batch-ocr/SKILL.md`。

## 使用方式

```
/batch-ocr /path/to/pdfs                          # 全部 default
/batch-ocr /path/to/pdfs --parallel 8             # 並行 8 路
/batch-ocr /path/to/pdfs --host localhost:11434   # 本地 Ollama 不走 SSH
/batch-ocr /path/to/pdfs --resume                 # 只跑失敗 / 缺 .md 的 .png
```

執行 script:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/batch-ocr.sh" $ARGUMENTS
```

完成後跑 `/batch-ocr-status` 看統計,或 `/batch-ocr-resume` 重試 permanent_failures。
