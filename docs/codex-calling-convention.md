# Codex 呼叫原則

Plugin 中呼叫 Codex CLI 的標準做法。

## 一次性任務（預設選擇）

```bash
codex exec --full-auto \
  -c 'model_reasoning_effort="xhigh"' \
  -o output.md \
  "prompt"
```

- `--full-auto`：workspace-write sandbox + auto approval
- `-c 'model_reasoning_effort="..."'`：`none | minimal | low | medium | high | xhigh`
- `-o FILE`：最後一條 message 直接寫入檔案（不怕 stdout 截斷）
- `-C DIR`：指定工作目錄
- `--add-dir DIR`：額外可寫目錄
- stdin 傳 prompt：`cat prompt.txt | codex exec --full-auto -`

適用：ensemble review 的 Codex 盲驗、單次 delegation、code review。

## 需要 job management 時（罕見）

```bash
node codex-companion.mjs task --write --effort xhigh "prompt"
node codex-companion.mjs status --all
node codex-companion.mjs result $JOB_ID
node codex-companion.mjs cancel $JOB_ID
```

- 必須加 `--write`，否則預設 read-only sandbox
- companion 路徑會隨版本更新，不要硬編

適用：多個並行 background jobs 且需要 status/cancel 管理。

## 不要做的事

- **不加 `--write` 的 companion** — 預設 read-only，Codex 無法寫檔或跑 R
- **硬編 companion 路徑** — 版本號（如 `1.0.1`）會過時：
  ```bash
  # 不好
  node "$HOME/.claude/plugins/cache/openai-codex/codex/1.0.1/scripts/codex-companion.mjs"
  
  # 較好（如果必須用 companion）
  node "$HOME/.claude/plugins/marketplaces/openai-codex/plugins/codex/scripts/codex-companion.mjs"
  ```
- **用 `-m o3` 替代 effort 設定** — 不同模型用途不同；effort 控制的是思考深度

## 對照表

| | `codex exec` | `codex-companion.mjs` |
|---|---|---|
| 寫入權限 | `--full-auto` | `--write` |
| Effort | `-c 'model_reasoning_effort="xhigh"'` | `--effort xhigh` |
| 輸出 | `-o file.md` | stdout（可能截斷） |
| Job 管理 | 無（一次性） | status / result / cancel |
| Session 恢復 | `codex exec resume` | `--resume` |
| 架構 | 直接跑 CLI | 透過 app-server WebSocket |

## 範例：ensemble review 的 Codex 盲驗

```bash
codex exec --full-auto \
  -c 'model="gpt-5.5"' \
  -c 'model_reasoning_effort="xhigh"' \
  -c 'service_tier="fast"' \
  -o reviews/codex-review.md \
  "審閱 solution.tex，從 methodology/writing/references 三角度。用繁體中文。"
```

## 範例：仲裁兩份解答

```bash
cat arbitration-prompt.txt | codex exec --full-auto \
  -c 'model_reasoning_effort="xhigh"' \
  --add-dir "$(pwd)/reviews" \
  -o reviews/arbitration-codex.md \
  -
```
