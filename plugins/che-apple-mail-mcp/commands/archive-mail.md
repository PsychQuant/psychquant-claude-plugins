---
description: 歸檔指定聯絡人的 Apple Mail 郵件到 Markdown 檔案
argument-hint: "[email-filter] [output-dir]  # 零參數時讀 .claude/.mail/config.yaml"
allowed-tools: mcp__plugin_che-apple-mail-mcp_mail__*, Bash(mkdir:*), Read, Write, Glob
---

# Archive Mail

歸檔指定聯絡人的郵件到 Markdown 檔案。

## 使用方式

```
/archive-mail                                    # 零參數(v2.12.0+;v2.16.0+ 讀 .claude/.mail/config.yaml,.md fallback)
/archive-mail user@example.com
/archive-mail user@example.com communication/emails
```

- 第一個參數(**v2.12.0+ 可選**):Email 過濾條件(寄件人或收件人包含此字串)
- 第二個參數(可選):輸出目錄,預設 `communication/emails`

#### 零參數模式

當 cwd 已有 `.claude/.mail/config.yaml`(v2.16.0+;舊 `.md` 仍 fallback,首次 invoke auto-migrate 為 `.yaml`)並設定 `filters` 時,可不帶任何參數呼叫;從 config 讀取:

| Field | 用途 |
|-------|------|
| `filters` | 多個 filter,作 OR-search 合併 corpus |
| `output_dir` | 覆寫 default `communication/emails` |
| `last_archived` | 給 search_emails 設 `date_from`(只抓此時點之後的信)|
| `exclude_mailboxes` | search 跳過(垃圾郵件 / 草稿等)|

命令列參數仍可覆寫 config(傳一個 filter 就只用該 filter,不讀 config 的 filters 清單)。詳細 schema 見 plugin CLAUDE.md。

## 執行步驟

### Step 0: Bootstrap Stage Task List(v2.9.0+ 鐵律,強制)

**在動任何事之前**先用 `TaskCreate` 為這個 stage 建 stage-level todo list，確保每個 sub-step 都被追蹤。學 IDD `idd-implement` 的 enforcement pattern。

```
TaskCreate(subject="resolve_filter_and_paths",
           description="Step 1 + 1.6: 解析 $ARGUMENTS → filter + output_dir. 計算 .claude/.mail/state/archives/{slug} 路徑。Auto-migrate legacy .email_index.json / .threads.json / .claude/emails.md。")

TaskCreate(subject="phase1_disambiguation",
           description="Step 1.5: 若 filter 模糊(中文人名「陳老師」/相對時間「最近」/通用 scope「全部」) → 列候選讓 user 選;明確 email/Message-ID/--no-confirm → skip。由 confirmation-protocol skill Phase 1 + email-search-disambiguation 處理。")

TaskCreate(subject="load_indices_and_config",
           description="Step 2: 從 ${INDEX_DIR}/ 讀 email_index.json + threads.json + ${CONFIG_FILE} 的 attachment_routing / subject_keywords / participant_aliases。")

TaskCreate(subject="search_emails",
           description="Step 3 + 3b + 3c + 3d: 對每個帳號跑 sender 搜尋 + subject_keywords 搜尋 + bare-subject thread expansion,三組結果 Message-ID 去重 → corpus。注意 account_name 必須用 display name 不可用 ews:// URL。")

TaskCreate(subject="filter_and_scan_false_positives",
           description="Step 4 + 強制 false-positive scan(rules/false-positive-detection.md): 過濾出 Message-ID 不在索引的 emails → 待歸檔清單。對每個 thread 跑 flag_thread() → 標 ✓/⚠/⚠⚠/❓。Sibling activity / CC pollution / subject collision 三種 pattern 必須 check。")

TaskCreate(subject="phase2_3_preview_and_confirm",
           description="Step 4.5: 若待歸檔 ≥ 5 封 OR 有 ⚠⚠ flag OR destructive op → Phase 2 preview (thread breakdown + flags) + Phase 3 operation confirmation (file count + attachment size)。等 user 確認(a)/排除(b)/改 filter(c)/取消(d)。User skip 條件見 confirmation-triggers.md。")

TaskCreate(subject="fetch_and_write_markdown",
           description="Step 5: 對每封新郵件 get_email(format='text', 用 display name) → YAML frontmatter (message_id/thread_key/in_reply_to/date/sender/direction) + body markdown，按檔名規則(YYYY-MM-DD_subject-hyphenated[-N].md, 截 50 graphemes) 寫到 ${output_dir}/。")

TaskCreate(subject="download_and_classify_attachments",
           description="Step 5.5: list_attachments → 用 classify() 分 data/document → save_attachment 到 data_dir / documents_dir/{email_stem}/。Markdown 插 Attachments: 區塊。回覆信無 byte 附件但引用原信附件 → cross-reference。")

TaskCreate(subject="update_indices",
           description="Step 5.7 + Step 6: 對每封新歸檔的信 append 到 ${THREADS_FILE} 的 thread_key entry (messages append, participants set, first/last_message, message_count)。把新 Message-ID + thread_key 加到 ${INDEX_FILE}。Append-only,不修改既有 entry。")

TaskCreate(subject="report_and_audit",
           description="Step 7 + 8: 輸出歸檔報告(新歸檔/跳過/thread 索引/附件分流)。執行 Coverage Audit (8a 附件完整性 + 8b thread 完整性 → search by bare_subject 比對 archived/total)。")
```

**完成每一步立即 `TaskUpdate → completed`。靜默完成 = 違規。**

中途若發現要分更多 sub-tasks(例如 Phase 2 preview 需要分批,或 attachment 下載失敗需要 retry),用 `TaskCreate` 補加。

**為什麼**:沒有 Stage TaskList 時,Claude 看 markdown spec 容易跳步驟(例如 false-positive scan 漏跑、Phase 2 preview 用「應該不需要」rationalize 掉)。Stage TaskList 把「跳過」變成顯眼的 incomplete task,user 在 UI 看得到。歷史上 2026-05-01 archive 陳老師信件就是因為沒跑 false-positive scan,265250 false positive 漏網,事後又花一輪 rm + index 修復。

### Step 1: 解析參數

從 `$ARGUMENTS` 取得:
- `filter`: 第一個參數(可選,**v2.12.0+ 零參數模式**)
- `output_dir`: 第二個參數;若未給且 `${CONFIG_FILE}` 也沒設,進 **Workspace Layout Detection**(v2.17.0+,見下方)決定;最終 fallback 為 `communication/emails`

#### Config parsing(always-on,v2.17.0+ #49)

不論 `$ARGUMENTS` 是空還是有內容,**只要 `${CONFIG_FILE}` 存在就先 parse**。理由:`/archive-mail <filter>`(只給第一個 arg)的 user 也應該尊重 config `output_dir:` pin,不能 silently fall through 到 detection。

> **Forward reference**:`${CONFIG_FILE}` 由 Step 1.6 計算(`.claude/.mail/config.yaml`,legacy `.md` fallback)。AI executor 整段 skill 讀完才開始執行,所以 forward-reference 在 markdown skill 慣例下 OK;若有人手動 copy bash 出來跑,先看 Step 1.6 的 `CONFIG_FILE` 賦值。

```bash
# Always parse config if file exists — independent of $ARGUMENTS state
CFG_OUTPUT_DIR=""
LAST_ARCHIVED=""
EXCLUDE_MBX=""
if [ -f "${CONFIG_FILE}" ]; then
    # Parse YAML config (top-level scalars + sequences only)
    # 兼容 pure YAML(`.yaml` v2.16.0+)與 frontmatter-wrapped(`.md` legacy);awk pattern 對兩者皆 work
    # `---` 邊界(若 .md 用 frontmatter style)由 pattern 自然 skip(不 match `^[a-z_]+:`)
    CFG_OUTPUT_DIR=$(awk '/^output_dir:[ \t]*/{sub(/^output_dir:[ \t]*/,"");print;exit}' "${CONFIG_FILE}")
    LAST_ARCHIVED=$(awk '/^last_archived:[ \t]*/{sub(/^last_archived:[ \t]*/,"");print;exit}' "${CONFIG_FILE}")
    EXCLUDE_MBX=$(awk '/^exclude_mailboxes:/{flag=1;next} /^[a-z_]+:/{flag=0} flag && /^  - /{sub(/^  - /,"");print}' "${CONFIG_FILE}")
fi

# output_dir precedence (高 → 低):
#   1. $ARGUMENTS[2] (cmdline second arg) — 若已設,跳過下面的 fallback
#   2. ${CONFIG_FILE} 的 output_dir: 欄位(本 step,both zero-arg and single-arg modes)
#   3. Workspace Layout Detection(下方,v2.17.0+)
#   4. Baseline default `communication/emails`(detection 中的 Probe 3)
[ -z "$output_dir" ] && [ -n "$CFG_OUTPUT_DIR" ] && output_dir="$CFG_OUTPUT_DIR"
# last_archived feeds Step 3 search_emails 的 date_from (strict `>`)
# exclude_mailboxes feeds Step 3 mailbox-filter
```

#### Zero-arg 模式(v2.12.0+,resolves #13)

若 `$ARGUMENTS` 為空,從 `${CONFIG_FILE}` 讀取 `filters`(否則無 filter 可搜):

```bash
if [ -z "$ARGUMENTS" ]; then
    if [ ! -f "${CONFIG_FILE}" ]; then
        echo "Error: 沒有給 filter 也找不到 ${CONFIG_FILE}。" >&2
        echo "請建立 \${CONFIG_FILE} 並設定 filters,或直接傳 filter 參數。" >&2
        exit 1
    fi

    # filters → list,作 OR-search 的 filter set
    FILTERS=$(awk '/^filters:/{flag=1;next} /^[a-z_]+:/{flag=0} flag && /^  - /{sub(/^  - /,"");print}' "${CONFIG_FILE}")

    if [ -z "$FILTERS" ]; then
        echo "Error: ${CONFIG_FILE} 沒設定 filters。請補 filters 或傳命令列參數。" >&2
        exit 1
    fi
fi
```

#### 命令列覆寫(現行行為,backward compat)

若 `$ARGUMENTS` 非空,命令列參數覆寫 config:
- `filter` = 第一個 arg(視為單一 filter,即使 config 有多個 filters 仍只用此一個)
- `output_dir` = 第二個 arg(若有);**否則仍走上方 Config parsing 區段已 apply 的 `CFG_OUTPUT_DIR`**(v2.17.0+ 修掉 explicit-config-bypass-in-non-zero-arg-mode 漏洞);config 沒設則走 **Workspace Layout Detection**(v2.17.0+) / default

#### Workspace Layout Detection(v2.17.0+,#49)

當 `output_dir` 既非 `$ARGUMENTS[1]` 也非 `${CONFIG_FILE}` 的 `output_dir:` 欄位給定時,probe 工作目錄看是否符合已知的 workspace layout。**Detection 只在「沒有 explicit choice」時觸發**——如果 user 在 config 或命令列已 pin,detection 完全不跑,既有行為 100% backward compat。

**Probe 順序**(命中即停):

```bash
# Only run when output_dir is still empty after $ARGUMENTS[1] + ${CONFIG_FILE} resolution
if [ -z "$output_dir" ]; then
    # Probe 1: communications/<channel>/ pattern (v2.17.0+ canonical)
    if [ -d "communications/email" ]; then
        # Ambiguity guard: if both layouts have content, refuse to guess
        if [ -d "correspondence/emails" ] && \
           [ -n "$(find -P correspondence/emails -maxdepth 1 -name '*.md' 2>/dev/null | head -1)" ] && \
           [ -n "$(find -P communications/email  -maxdepth 1 -name '*.md' 2>/dev/null | head -1)" ]; then
            echo "❌ Ambiguous workspace layout: both 'communications/email/' and 'correspondence/emails/' have archived markdowns." >&2
            echo "   Pin 'output_dir:' in .claude/.mail/config.yaml to disambiguate." >&2
            exit 1
        fi
        output_dir="communications/email"
        echo "🔍 Detected output_dir: communications/email (from layout probe)"

    # Probe 2: correspondence/emails/ legacy pattern (pre-v2.17 user convention)
    elif [ -d "correspondence/emails" ]; then
        output_dir="correspondence/emails"
        echo "🔍 Detected output_dir: correspondence/emails (legacy layout probe)"

    # Probe 3: nothing detected — fall back to baseline default
    else
        output_dir="communication/emails"
        # No log line — silent default keeps non-detection workspace flow unchanged
    fi
fi
```

**Why probe order = `communications/email` → `correspondence/emails` → default**:

1. `communications/<channel>/` 是 forward direction(per kiki830621/chchen-lab 2026-05-08 reorg)。當 user 已建好 `communications/email/`,intent 明確。
2. `correspondence/emails/` 是 legacy convention(per 既有 `psychophysic_representations` 等 workspaces)。但這些 workspaces 通常已有 explicit `output_dir:` 在 config,此 probe 主要為「legacy workspace 沒寫 config」的少數情境兜底。
3. 都不符合則用 baseline default,既有 zero-config flow 不變。

**Ambiguity guard**:當 `communications/email/` 與 `correspondence/emails/` **同時存在且都有 `*.md`** 時,refuse 而非 silent guess。Mid-migration 的 workspace 必須 explicit pin,否則風險:detection 把新信寫到 `communications/email/` 但 dedup index 依然指 legacy 路徑,半實作狀態下的 message-id collision 不會被偵測。Empty-dir-as-marker 不算ambiguity(常見:user 才剛建好 `communications/email/`,還沒 archive 過)。

**Detection 與 explicit config 的關係**(precedence,高 → 低):

1. `$ARGUMENTS[1]`(命令列 `/archive-mail <filter> <output_dir>` 的第二個參數)
2. `${CONFIG_FILE}` 的 `output_dir:` 欄位(zero-arg 模式)
3. **Workspace Layout Detection**(本節,v2.17.0+)
4. Baseline default `communication/emails`

#### 模糊 filter

不論來源(命令列 / config),若 filter 為模糊詞 → 進 Step 1.5 disambiguation。

### Step 1.5: Confirmation — Phase 1: Disambiguation（v2.7.0+）

**Skill ref**: `confirmation-protocol`、`email-search-disambiguation`

如果 filter 是模糊詞（中文人名「陳老師」、相對時間「最近」、通用 scope「全部」），**不要直接執行 search**。先用 disambiguation:

```
「{filter}」可能對應到:
1. {email_1} ({description_1}, 推薦)
2. {email_2} ({description_2})
3. 其他

你要哪一個?
```

候選來源:
- `.claude/emails.md` 的 `participant_aliases` 欄位
- 之前歸檔的 `.threads.json` participants
- Address book / contacts MCP

**Skip Phase 1**(可直接進 Step 2):
- Filter 是明確 email 地址(含 `@`)
- Filter 是 Message-ID
- 單一 user-typed `--no-confirm` flag 或明確說「直接做」

詳見 `skills/confirmation-protocol/SKILL.md` 和 `skills/email-search-disambiguation/SKILL.md`。

### Step 1.6: 解析 namespace 路徑（v2.8.0+,學 IDD `.claude/.idd/` pattern）

統一所有 mail 工作流的 config + state 到 `.claude/.mail/`(學 idd 的 namespace 收斂):

```bash
NAMESPACE_DIR=".claude/.mail"

# Slug for output_dir (用於支援多個 archive target 並存)
SLUG=$(echo "${output_dir}" | tr '/' '-' | sed 's/^[-.]*//;s/[-.]*$//')

INDEX_DIR="${NAMESPACE_DIR}/state/archives/${SLUG}"
INDEX_FILE="${INDEX_DIR}/email_index.json"
THREADS_FILE="${INDEX_DIR}/threads.json"

# v2.16.0+ (#47): config 改 .yaml 為 first-class;.md 維持 fallback 直到 v3.0
# Auto-migrate legacy .md → .yaml 時機在下方 "Auto-migrate" 區塊處理
CONFIG_FILE="${NAMESPACE_DIR}/config.yaml"
[ ! -f "$CONFIG_FILE" ] && [ -f "${NAMESPACE_DIR}/config.md" ] && CONFIG_FILE="${NAMESPACE_DIR}/config.md"

mkdir -p "${INDEX_DIR}"
```

**Resolve dedup strategy** (v2.14.0+, issue #18):

```bash
# Default: index-based dedup (backward compat with v2.13.0 ↓)
DEDUP_STRATEGY=$(awk '/^dedup_strategy:[ \t]*/{sub(/^dedup_strategy:[ \t]*/,"");print;exit}' "${CONFIG_FILE}" 2>/dev/null)
DEDUP_STRATEGY="${DEDUP_STRATEGY:-index}"

case "$DEDUP_STRATEGY" in
    index|last_archived|both) ;;  # valid
    *)
        echo "Error: invalid dedup_strategy '${DEDUP_STRATEGY}'. Valid: index | last_archived | both" >&2
        exit 1
        ;;
esac

# If last_archived strategy: require last_archived field present
if [ "$DEDUP_STRATEGY" = "last_archived" ]; then
    LAST_ARCHIVED=$(awk '/^last_archived:[ \t]*/{sub(/^last_archived:[ \t]*/,"");print;exit}' "${CONFIG_FILE}" 2>/dev/null)
    if [ -z "$LAST_ARCHIVED" ]; then
        echo "Error: dedup_strategy=last_archived requires '${CONFIG_FILE}' to have a 'last_archived: YYYY-MM-DD' field." >&2
        echo "Either set last_archived (manually or after first archive run) or use dedup_strategy: index | both." >&2
        exit 1
    fi
fi
```

| `dedup_strategy` | Step 2 (load index) | Step 4 (dedup logic) | Step 5/6 (write index) |
|------------------|---------------------|----------------------|-----------------------|
| `index` (default) | load `email_index.json` | filter Message-ID not in index | append new Message-IDs |
| `last_archived` | skip | filter received-date `>` last_archived | skip |
| `both` | load | union: not-in-index AND date `>` last_archived | append (索引 still maintained) |

**Auto-migrate from legacy paths**(silent,只在新位置不存在時觸發):

```bash
# Legacy → new: indices
if [ ! -f "${INDEX_FILE}" ] && [ -f "${output_dir}/.email_index.json" ]; then
  mv "${output_dir}/.email_index.json" "${INDEX_FILE}"
  echo "🔄 Migrated ${output_dir}/.email_index.json → ${INDEX_FILE}"
fi
if [ ! -f "${THREADS_FILE}" ] && [ -f "${output_dir}/.threads.json" ]; then
  mv "${output_dir}/.threads.json" "${THREADS_FILE}"
  echo "🔄 Migrated ${output_dir}/.threads.json → ${THREADS_FILE}"
fi

# Legacy → new: config v2.7.0 ↓ (.claude/emails.md → namespace)
if [ ! -f "${NAMESPACE_DIR}/config.yaml" ] && [ ! -f "${NAMESPACE_DIR}/config.md" ] && [ -f ".claude/emails.md" ]; then
  mv ".claude/emails.md" "${NAMESPACE_DIR}/config.yaml"
  CONFIG_FILE="${NAMESPACE_DIR}/config.yaml"
  echo "🔄 Migrated .claude/emails.md → ${NAMESPACE_DIR}/config.yaml"
fi

# Legacy → new: config v2.15.0 ↓ (.md → .yaml, v2.16.0+ #47)
# 只 rename,不改內容(awk parser 對 YAML body 兩種格式皆 work)
if [ ! -f "${NAMESPACE_DIR}/config.yaml" ] && [ -f "${NAMESPACE_DIR}/config.md" ]; then
  mv "${NAMESPACE_DIR}/config.md" "${NAMESPACE_DIR}/config.yaml"
  CONFIG_FILE="${NAMESPACE_DIR}/config.yaml"
  echo "🔄 Migrated ${NAMESPACE_DIR}/config.md → ${NAMESPACE_DIR}/config.yaml (v2.16.0+ schema rename)"
fi
```

> **v2.16.0+ schema clarification (#47)**:config 副檔名改 `.yaml`(內容向來都是 YAML,只是 v2.15.0 ↓ 用 `.md` 副檔名造成語意 mismatch)。Auto-migrate 是 silent rename,user 不需動手。`.md` 仍 work 為 fallback,**v3.0 移除**;期間 README / CLAUDE.md schema 範例都改示範 `.yaml`。

或者用 `/archive-mail-migrate` 批次 migrate 所有舊 archive targets,詳見該 command。

### Step 2: 建立目錄和載入索引

```bash
mkdir -p "${output_dir}"   # archive markdown 目的地(不變)
```

**讀取兩個索引檔**(v2.8.0+ 從 `${INDEX_DIR}/` 讀;v2.14.0+ 條件 skip per `dedup_strategy`):

`${INDEX_FILE}` (`.claude/.mail/state/archives/${SLUG}/email_index.json`) — Message-ID 去重索引(canonical key):
- 若 `dedup_strategy=last_archived`(v2.14.0+) → **skip**, 完全不讀 index
- 若 `dedup_strategy=index`(default)或 `both` → 載入已歸檔 Message-ID;不存在則建立空索引 `{"version": "1.0", "emails": {}}`

`${THREADS_FILE}` (`.claude/.mail/state/archives/${SLUG}/threads.json`) — Thread 關係索引(append-only thread view):
- 若存在,載入既有 thread 結構
- 若不存在,建立空索引 `{"version": "1.0", "threads": {}}`
- 格式見 Step 5.7

兩個索引**獨立維護**,thread 索引純粹為了快速查詢 thread 關係,不影響單封信的儲存。若 `threads.json` 損壞,可用 `/archive-mail-rebuild-threads` 從 md frontmatter 重建。

#### Step 2.1: Sibling-archive dedup extension(v2.17.0+,#49)

當 `${output_dir}` 下有 symlinked subdirectory(典型情境:transitioned-project pattern,例如 chchen_lab 把 `email/application/` symlink 到 `applications/completed/.../emails/`),掃描其下 markdown 的 YAML frontmatter,把 `message_id:` 值併入 in-memory dedup set。**讀取 only,從不寫入 symlink target**。

```bash
# Only run when dedup_strategy uses index (skip if last_archived only)
if [ "$DEDUP_STRATEGY" = "index" ] || [ "$DEDUP_STRATEGY" = "both" ]; then
    # Find symlinked subdirectories in output_dir (1 level deep)
    EXTENDED_COUNT=0
    EXTENDED_SOURCES=()
    while IFS= read -r symlink_dir; do
        [ -z "$symlink_dir" ] && continue
        # Bound search depth + use -P to NOT follow symlinks recursively (we follow once into the symlinked dir, then stay)
        ENTRIES_THIS_DIR=0
        while IFS= read -r mdfile; do
            [ -z "$mdfile" ] && continue
            # Read just the YAML frontmatter (first ~30 lines is generous)
            mid=$(head -30 "$mdfile" 2>/dev/null | awk '/^message_id:[ \t]*/{sub(/^message_id:[ \t]*"?/,"");sub(/"?$/,"");print;exit}')
            if [ -n "$mid" ]; then
                # Add to in-memory dedup set (Message-ID is canonical key, same as INDEX_FILE)
                # Implementation: append to a shadow set the dedup logic in Step 4 will consult
                EXTENDED_DEDUP_IDS+=("$mid")
                ENTRIES_THIS_DIR=$((ENTRIES_THIS_DIR + 1))
            fi
        done < <(find -P "$symlink_dir/" -maxdepth 2 -name "*.md" -type f 2>/dev/null)

        if [ "$ENTRIES_THIS_DIR" -gt 0 ]; then
            EXTENDED_COUNT=$((EXTENDED_COUNT + ENTRIES_THIS_DIR))
            EXTENDED_SOURCES+=("$symlink_dir ($ENTRIES_THIS_DIR entries)")
        fi
    done < <(find -P "${output_dir}" -maxdepth 1 -type l 2>/dev/null)

    if [ "$EXTENDED_COUNT" -gt 0 ]; then
        echo "🔗 Extended dedup with $EXTENDED_COUNT entries from sibling archives:"
        for src in "${EXTENDED_SOURCES[@]}"; do
            echo "   - $src"
        done
    fi
    # Silent when zero — typical zero-symlink workspace flow stays clean
fi
```

**Step 4 dedup logic 銜接**:`EXTENDED_DEDUP_IDS` 由 Step 4 透過 set union **併入** existing predicate(不取代 strategy-specific date filter)。完整 pseudocode 見 [Step 4 過濾新郵件](#step-4-過濾新郵件)。Composition rule 摘要:

- `dedup_strategy=index`:`known_ids = existing_index_ids ∪ extended_ids`,filter by Message-ID set membership only
- `dedup_strategy=last_archived`:本 step 2.1 完全 skip(`EXTENDED_DEDUP_IDS` 不會被 populate),Step 4 仍走 date gate
- `dedup_strategy=both`:`known_ids = existing_index_ids ∪ extended_ids` AND date > `last_archived`,**两条件 AND**(extended IDs 不打破 date filter)

**Properties / invariants**:

- **Read-only**:never `mv` / `rm` / `>` against symlink target;`find` + `head` + `awk` only。
- **Bounded**:`find -P -maxdepth 2`(symlink dir 本身 + 一層 immediate children),避免 deep archive 拖慢 startup。
- **archive-mail v2.6+ format compatibility**:設計 target 是 archive-mail 自產的 frontmatter(`message_id: "<...>"` 雙引號格式)。Manual archive 若 frontmatter 用單引號 / 內含 inline comment / CRLF / trailing whitespace,parser 會 silent skip 該檔(計入 ENTRIES_THIS_DIR=0)。Future hardening(yq parser / robust awk)deferred until N≥3 user reports of manual-archive missed dedup — see follow-up #54 / #50 for tracking。
- **Compose with `dedup_strategy`**:僅在 `index` / `both` strategy 跑;`last_archived` strategy 完全 skip(那種 strategy 的 user 顯然不依賴 Message-ID dedup)。Compose 邏輯:`EXTENDED_DEDUP_IDS` 透過 set union 併入 existing Message-ID set,不取代 strategy-specific date predicate。

**讀取附件設定**(可選):檢查 `${CONFIG_FILE}` (`.claude/.mail/config.md`) 是否有 `attachment_routing` YAML front matter 區塊。
若有，載入自訂規則（all-or-nothing 取代，不做 merge）。若無，使用以下內建預設：

```yaml
attachment_routing:
  data_extensions: [csv, tsv, sav, dta, parquet, feather, xlsx, sas7bdat]
  document_extensions: [pdf, docx, doc, txt, md, rtf, odt]
  data_keywords: [data, raw, indicators, codebook, dataset]          # 大小寫不敏感子字串匹配
  document_keywords: [Submission, Figures, Tables, Manuscript, draft, Revision, v1, v2, v3]
  data_dir: data/raw
  documents_dir: correspondence/attachments
```

**讀取搜尋擴展設定**（可選，v2.4.0+）：

```yaml
subject_keywords: [taxometric, SSQ, paper]    # subject 關鍵字搜尋（補抓 sender 漏掉的 internal threads）
participant_aliases:                           # 成員別名（用於 audit 報告顯示）
  "b08801008@ntu.edu.tw": "Pei-Chi"
  "r13227202@ntu.edu.tw": "Pei-Chi"
```

- `subject_keywords`：可選。若有，Step 3 會做第二輪 subject 搜尋。若無，只跑 sender 搜尋（向後相容）。
- `participant_aliases`：可選。目前用於 audit 報告的顯示名稱；不影響搜尋行為。

**分類優先序**（config > keyword > extension）：
1. YAML config 明確指定 → 最高
2. 檔名 keyword 子字串匹配（先比 `data_keywords`，再比 `document_keywords`）→ 中
3. 副檔名匹配（先比 `data_extensions`，再比 `document_extensions`）→ 最低
4. 全部未命中 → 保守預設：歸類為 document

### Step 3: 搜尋郵件（使用 apple-mail MCP）

使用 `mcp__plugin_che-apple-mail-mcp_mail__search_emails` 搜尋：

1. **搜尋收到的郵件**（sender 包含 filter）
2. **搜尋寄出的郵件**（在 Sent 信箱搜尋）

需要先用 `mcp__plugin_che-apple-mail-mcp_mail__list_accounts` 取得帳號列表。

對每個帳號執行：
```
mcp__plugin_che-apple-mail-mcp_mail__search_emails(
  account_name: "帳號名稱",
  query: "${filter}",
  field: "sender",
  limit: 100
)
```

> **⚠️ account_name 陷阱（fixes #15）— 全域適用，`search_emails` 與 `get_email` 皆然**
> `list_accounts` 對 Exchange 帳號回傳的 `name` 是 `ews://AAMkA...` 形式的內部 URL；`uuid` 也不接受。後續呼叫 `get_email` / `search_emails` 時必須改用 **display name**（email 地址，例如 `user@example.com`），否則會觸發：
>
> ```
> AppleScript error (-1728): Mail got an error: Can't get account "ews://...".
> ```
>
> 若配置 `.claude/emails.md` 的 `accounts` 欄位明列 email 地址，可直接拿來用。否則需要人工比對帳號。
> **此陷阱對 Step 5 讀取郵件內文同樣適用**，不要假設搜尋階段記的 `account_name` 可以直接沿用——若那是 EWS URL，到 `get_email` 會重現 -1728。

**3b. Subject-keyword 搜尋**（v2.4.0+，若 `subject_keywords` 有設定）：

對每個 keyword，執行：
```
search_emails(account_name: "...", query: keyword, field: "subject", limit: 100)
```

將結果加入 corpus。

**3c. Thread-subject 擴展**（v2.4.0+，自動）：

對步驟 3 / 3b 找到的每封信：
1. 提取 bare subject（去掉 `Re:` / `RE:` / `Fwd:` / `FW:` / `转发:` / `轉寄:` 前綴，用正則 `^(Re|RE|Fwd|FW|转发|轉寄):\s*`）
2. 用 bare subject 搜尋：`search_emails(query: bare_subject, field: "subject", limit: 100)`
3. 將結果加入 corpus

**3d. 合併去重**：

三組結果（sender + subject_keywords + thread-subject）用 Message-ID 去重。最終 corpus 進入 Step 4。

在 Step 7 報告中加上：`搜尋結果: {sender_count} by sender + {keyword_count} by subject + {thread_count} by thread expansion = {total_unique} unique`

### Step 4: 過濾新郵件

對每封搜尋到的郵件,依當前 `dedup_strategy` 套用 dedup logic。**v2.17.0+ #49**:除了既有 `INDEX_FILE` 來源的 Message-ID set,**也必須消費 Step 2.1 累積的 `EXTENDED_DEDUP_IDS`**(從 sibling-archive symlink 抽出的 historical Message-ID)。

```python
# Build the canonical "known" Message-ID set per dedup_strategy
existing_ids = set(load_json(INDEX_FILE)["emails"].keys()) if DEDUP_STRATEGY in ("index", "both") else set()
extended_ids = set(EXTENDED_DEDUP_IDS)  # v2.17.0+ — populated by Step 2.1 if symlinked siblings exist
known_ids = existing_ids | extended_ids

# Apply strategy-specific predicate (note: extended_ids compose IN to existing predicate, not replace it)
def is_new(email):
    # Always: not in known Message-ID set
    if email["message_id"] in known_ids:
        return False
    # Extra gate for last_archived / both: also require date > last_archived
    if DEDUP_STRATEGY in ("last_archived", "both") and LAST_ARCHIVED:
        if email["date"] <= LAST_ARCHIVED:
            return False
    return True

new_emails = [e for e in fetched if is_new(e)]
```

對每封新郵件:
1. 檢查其 Message-ID 是否已在 `known_ids`(`INDEX_FILE` ∪ `EXTENDED_DEDUP_IDS`)中
2. 若已存在 → 跳過
3. 若不存在(且通過 strategy-specific date gate)→ 加入待歸檔清單

> **Why `known_ids` 而非單純 `existing_ids`?** 對 transitioned-project workspace(see Step 2.1),`EXTENDED_DEDUP_IDS` 來自 read-only sibling archive(symlink target),這些 historical Message-ID 不在 `INDEX_FILE` 但代表「使用者已 archive 過的信」。若不消費 extended set,sibling archive 裡的舊信被 forward 回來會 silent re-archive。
>
> **`dedup_strategy=both` composition 細節**:extended IDs 透過 set union **加入** known set,而非取代。`both` strategy 的 date filter 仍照常 apply(對所有 emails,不論其 Message-ID 來源)。

### Step 4.5: Confirmation — Phase 2 + 3: Search Preview + Operation Confirmation（v2.7.0+）

**Skill ref**: `bulk-operation-preview`、`confirmation-protocol`

如果 Step 4 過濾後的待歸檔清單 **≥ 5 封**(或 ≥ 1 封 destructive op),**不要直接進 Step 5 fetch + write**。先 preview:

#### Phase 2: Search Preview

按 thread 分組,跑 false-positive detection,展示給 user:

```
搜尋結果:{N} 封 emails (filter: {filter}, output: {output_dir})

Filter:
  Mail
    -> filter(sender = '...' OR recipient = '...' OR subject contains '...')
    -> sort(date desc)

Threads 分布:
  ✓ [{date}] {thread_key} ({M} msgs)
       Participants: {p1, p2, p3}
  ⚠ [{date}] {thread_key} ({M} msgs)  ← potential false positive
       Reason: sender 不在 filter, 僅 subject 含關鍵字

附件預估:{K} 個 ({total_size})
```

False-positive flagging 規則見 `rules/false-positive-detection.md`:
- ✓ sender/recipient 直接匹配 filter
- ⚠ email 在 thread 但不是 principal
- ⚠⚠ 只 subject keyword match,sender 不符
- ❓ metadata 不足以判斷

#### Phase 3: Operation Confirmation

```
我將執行:
  - 寫 {N} 個 markdown 檔到 {output_dir}/
  - 下載 {K} 個 attachments ({total_size}),分流到 {data_dir}/ 和 {documents_dir}/
  - 建立/更新 .email_index.json 和 .threads.json
  - 不修改 Mail.app 內容(read-only operation)

⚠ 此操作會建立約 {N+K+2} 個檔案
確認執行嗎?

選項:
  (a) 確認,全部歸檔
  (b) 排除 false positive,歸檔 {N - flagged} 封
  (c) 修改 filter 重 search
  (d) 取消
```

#### Phase 4: User response handling

- 「對」/「a」/「OK」 → 進 Step 5 執行
- 「b」/「排除 ⚠」 → 從待歸檔清單移除 flagged threads,重 confirm
- 「c」/「修改 filter」 → 回 Step 1 重新 parse
- 「d」/「取消」 → abort,不 write 任何檔案

**Skip Phase 2+3**(可直接進 Step 5):
- 待歸檔清單 < 5 封 且 沒有 false-positive flag
- User 在 Phase 1 已說「直接做」
- 配置 `.claude/emails.md` 含 `confirmation: skip`

詳見 `skills/bulk-operation-preview/SKILL.md` 和 `rules/confirmation-triggers.md`。

### Step 5: 生成 Markdown

對每封新郵件，建立 Markdown 檔案。

> **⚠️ 再次提醒（來自 Step 3）**：在 Step 5 呼叫 `mcp__plugin_che-apple-mail-mcp_mail__get_email` 讀取內文時，同樣要用 **display name（email 地址）**作為 `account_name`，不可用 `list_accounts` 回的 `ews://` URL 或 UUID——否則 AppleScript error -1728。

`search_emails` 回傳**不含**完整內容（僅 subject / sender / date / mailbox / account），因此對每封新郵件先呼叫：

```
mcp__plugin_che-apple-mail-mcp_mail__get_email(
  id: "<id from search>",
  mailbox: "<mailbox from search>",
  account_name: "<display name / email 地址>",
  format: "text"
)
```


**檔名格式**（fixes #16）：`YYYY-MM-DD_{subject-hyphenated}.md`

Subject → filename 轉換規則（依此順序執行）：
1. **標點轉 `-`**：空白、冒號、斜線、反斜線、引號、問號、驚嘆號、中英標點（`,`、`。`、`、`、`:`、`；`、`(`、`)`、`[`、`]`、`?`、`!`）→ `-`
2. **路徑字元移除**：`.` 開頭的檔名加底線前綴 `_`；`..` 保留為字面（標點轉換已把 `/` 變 `-`，不會路徑越界）
3. **連續 dash 保留**：**不**合併連續 `-`（實務上 `Re:` + 空白 = `Re--`，符合 50 個歷史歸檔慣例）
4. **截斷至 50 個字元**（extended grapheme clusters，即 Swift `String.count` 的語意；非 Unicode code points、非 UTF-8 byte。`é` / `🇹🇼` / 中日韓字各算 1）
5. **首尾 `-` 去除**（截斷後若尾部是 `-`，再次去除；最終檔名不應以 `-` 結尾）
6. **空字串 fallback**：若步驟 1–5 後為空（空白 subject 或全標點 subject），使用 `no-subject`
7. **保留 Unicode**（中文、日文、韓文、emoji 維持原樣）

同日同主旨多封郵件：
- 第 1 封：**無後綴** → `2026-04-08_Re--Some-topic.md`
- 第 2 封：`-1` → `2026-04-08_Re--Some-topic-1.md`
- 第 3 封：`-2` → `2026-04-08_Re--Some-topic-2.md`
- 第 N 封（N ≥ 2）：`-{N-1}`

偵測後綴編號：用 `Glob` 列出 `YYYY-MM-DD_{subject}*.md`，取現有最大 `-N` +1（若無匹配則第 1 封無後綴；有 1 個匹配則 `-1`）。

範例（來自 `tatsuma/communications/`）：

| Subject | 順序 | 檔名 |
|---------|------|------|
| `Re: sabbatical year` | 第 1 封 | `2023-08-28_Re--sabbatical-year.md` |
| `翻訳のお願い` | 第 1 封 | `2024-03-26_翻訳のお願い.md` |
| `NTU PSY seminar 2024 final PPT` | 第 1 封 | `2024-04-04_NTU-PSY-seminar-2024-final-PPT.md` |
| `Re: Poster at 九州心理学会` | 第 4 封 | `2024-11-20_Re--Poster-at-九州心理学会-3.md` |
| `(空白 subject)` | 第 1 封 | `2026-04-08_no-subject.md` |

> **歷史相容 note**：`communications/` 有少量 `-a` / `-b` 字母後綴（如 `2024-07-14_...-a.md`）。新規不遷移舊檔，但新檔**一律用 `-1` `-2` `-3` 數字後綴**。若混用造成困擾，另開 follow-up issue。

**內容格式**(v2.13.0+ 預設簡化,issue #17;v2.6.0+ 加入 YAML frontmatter):

預設使用 **simple template**(對應 tatsuma 50 個既有檔案格式)。若 `${CONFIG_FILE}` 設 `enrichment: summary+todos`,改用下方 **enriched template** 加上 AI 摘要 + 待辦兩段。

```bash
# Step 1.6 階段已 parse;此處使用
ENRICHMENT=$(awk '/^enrichment:[ \t]*/{sub(/^enrichment:[ \t]*/,"");print;exit}' "${CONFIG_FILE}" 2>/dev/null)
ENRICHMENT="${ENRICHMENT:-none}"  # default: simple template (v2.13.0+)
```

#### Simple template (default, v2.13.0+):

```markdown
---
message_id: "<9c7a43db76e94a64a51f85d04c3bf01b@ntu.edu.tw>"
thread_key: "SE manuscript 10xx-2025"
in_reply_to: "<eddba65d53754587aeee5d86ff631d2c@ntu.edu.tw>"
date: 2026-01-28T08:35:34Z
sender: yfhsu@ntu.edu.tw
direction: received
---

Subject: <subject>
From: <sender display name OR email>
To: <recipient(s)>
Date: YYYY-MM-DD HH:MM

[完整 body]
```

Frontmatter 保留全部 6 欄位(thread index 重建仍依賴);header 改為 4 行純文字 `Subject/From/To/Date`,直接接 body,不再有元數據表 / 重點摘要 / 待辦事項三段。

#### Enriched template (opt-in via `enrichment: summary+todos`):

僅在 `${CONFIG_FILE}` 設定後觸發。Schema:

```markdown
---
message_id: "<9c7a43db76e94a64a51f85d04c3bf01b@ntu.edu.tw>"
thread_key: "SE manuscript 10xx-2025"
in_reply_to: "<eddba65d53754587aeee5d86ff631d2c@ntu.edu.tw>"
date: 2026-01-28T08:35:34Z
sender: yfhsu@ntu.edu.tw
direction: received
---

# [主題] - YYYY-MM-DD HH:MM

## 元數據

| 項目 | 內容 |
|------|------|
| **日期** | YYYY-MM-DD HH:MM |
| **類型** | 收到 / 寄出 |
| **寄件人** | xxx |
| **收件人** | xxx |

---

## 信件內容

[完整郵件內容]

---

## 重點摘要

- [AI 提取的重點]

## 待辦事項

- [ ] [AI 提取的待辦]

---

*歸檔日期：YYYY-MM-DD*
```

**Frontmatter 欄位說明**：
- `message_id`: 該封信的 RFC 5322 Message-ID（用引號包住，避免 YAML 解析角括號）
- `thread_key`: 依下列規則計算的 bare subject：
  1. 去掉前綴 `Re:` / `RE:` / `Fwd:` / `FW:` / `转发:` / `轉寄:`（重複出現多次也全部去除）
  2. 去除首尾空白
  3. 保留原始大小寫和標點
  4. 若結果為空，用 `no-subject`
- `in_reply_to`: 若有，來自郵件的 `In-Reply-To` header；若 MCP 未暴露，從 body 的 quote intro 嘗試提取第一個 Message-ID，否則留空
- `date`: ISO 8601 UTC 時間
- `sender`: 寄件人 email 地址（display name 剝除）
- `direction`: `received` 或 `sent`

這些 frontmatter 欄位是 **canonical truth**——`.threads.json` 僅為衍生索引。

### Step 5.5: 下載並分流附件

對每封已歸檔的新郵件,**處理兩類**:explicit MIME attachments(由 `list_attachments` 回傳)+ inline `cid:` 圖片(由 HTML body 解析,v2.15.0+ 加,issue #45)。

#### Step 5.5.0: Inline `cid:` images(v2.15.0+,resolves #45)

`list_attachments` **不**回傳 inline `cid:` 圖片(`Content-Disposition: inline`)。先從 HTML body 抽出再 download:

```bash
# Parse HTML body for inline cid references + alt-attribute filenames
# Pattern 1: <img src="cid:XXX" ... alt="filename.png">
# Pattern 2: <span id="cid:XXX">&lt;filename.tex&gt;</span>  (Mail.app quote-time marker — 已由 Step 5.5 #6 cross-reference 處理,本 step 只處理 Pattern 1)

INLINE_LIST=$(echo "$HTML_BODY" | python3 -c "
import re, sys, html
body = sys.stdin.read()
# 抓 <img ... cid:XXX ... alt='...'>;tolerant 大小寫 + 屬性順序
pattern = re.compile(
    r'<img\b[^>]*?src=[\"\\']cid:([^\"\\']+)[\"\\'][^>]*?alt=[\"\\']([^\"\\']+)[\"\\']',
    re.IGNORECASE | re.DOTALL
)
seen = set()
for m in pattern.finditer(body):
    cid, alt = m.group(1), html.unescape(m.group(2))
    if cid not in seen:
        seen.add(cid)
        print(f'{cid}\t{alt}')
")
```

對每個 `(cid, alt_filename)` pair:

1. **目標路徑**:`{documents_dir}/{email_md_stem}/inline/{alt_filename}`
   - 與 explicit attachments 同 stem 資料夾,但放 `inline/` 子目錄
   - filename 保留原始 alt(空白 / emoji / 中日文都不改)
   - 若 `documents_dir/{email_md_stem}/inline/` 不存在,先 `mkdir -p`

2. **下載**:呼叫 `save_attachment(attachment_name=alt_filename, save_path=...)`
   - **預期假設**:Apple Mail binary 接受 inline filename(尚未驗證,需要實測)
   - 若 `save_attachment` 失敗 → log warning + 改用 cross-reference 註記(見 Step 5.5.5),不中斷歸檔
   - 若 alt 屬性失敗解析(例如 charset 異常)→ fallback 用 `{cid}.png`(假設 PNG;典型 inline 都是)

3. **去重**:同一 thread 不同信引用同一 cid(thread quote 累積) → 只在**首次**出現的信下載,後續信只在 markdown 引用既有檔(看路徑是否存在判斷)

4. **計數**:記錄 `inline_count` 供 Step 7 報告 + Step 8 audit。

#### Step 5.5.1: Explicit MIME attachments

(原 Step 5.5 邏輯,不變)

1. **列出附件**：呼叫 `mcp__plugin_che-apple-mail-mcp_mail__list_attachments`（或 `list_attachments_batch`）取得附件清單。若為空 → 跳到下一封(但 Step 5.5.0 inline 仍跑)。

2. **分類每個附件**：用 Step 2 載入的分類規則判斷 `data` 或 `document`：

   ```
   classify(filename):
     lowercase_name = filename.lowercased()
     ext = filename 的副檔名（去掉 `.`）

     # Tier 1: keyword match（先比 data_keywords）
     for kw in data_keywords:
       if lowercase_name contains kw → return "data"
     for kw in document_keywords:
       if lowercase_name contains kw → return "document"

     # Tier 2: extension match
     if ext in data_extensions → return "data"
     if ext in document_extensions → return "document"

     # Tier 3: fallback
     return "document"
   ```

3. **決定目標路徑**：
   - `"data"` → `{data_dir}/{original_filename}`
   - `"document"` → `{documents_dir}/{email_md_stem}/{original_filename}`
   
   其中 `email_md_stem` 是該封信的 Markdown 檔名去掉 `.md`（例如 `2026-04-08_Re--Taxometric-Analysis`）。

4. **下載**：呼叫 `mcp__plugin_che-apple-mail-mcp_mail__save_attachment` 將附件存到目標路徑。
   - 檔名保留原始 bytes（空白、`&`、中日文、emoji 不改）
   - 目標目錄若不存在，先 `mkdir -p`
   - 若 `save_attachment` 失敗，log warning 繼續下一個（不中斷歸檔）

5. **更新 Markdown**：在該封信的 Markdown 中插入 attachment 區塊。

   **放置位置**：簽名（signature）之後、thread quote 之前。
   Thread quote 的辨識 pattern：第一個匹配 `差出人:` / `寄件者:` / `From:` / `On .* wrote:` 的行。
   若沒有 thread quote（原始信件，非回覆），attachment 區塊接在 body 最後。

   **兩個獨立 section**(v2.15.0+,issue #45):若該信同時有 inline + explicit,先 `Inline images:` 後 `Attachments:`;只有一邊則只列該邊;空 thread 全省略。

   **連結格式**：
   ```markdown
   Inline images:
   - ![原始檔名](相對路徑URL編碼)

   Attachments:
   - [原始檔名](相對路徑URL編碼) (大小 KB)
   ```

   `Inline images:` 用 `![]()`(image syntax,markdown viewer 直接渲染),`Attachments:` 用 `[]()`(link syntax,點擊下載)。

   URL 編碼規則（僅用於 Markdown link URL，display text 保留原始）：
   - 空白 → `%20`
   - `&` → `%26`
   - 其餘（含中日文）→ 保留原字元

   範例:
   ```markdown
   Inline images:
   - ![CleanShot 2026-05-07 at 15.44.58@2x.png](attachments/2026-05-07_Re--Solution---Iverson-similarity/inline/CleanShot%202026-05-07%20at%2015.44.58%402x.png)

   Attachments:
   - [Figures & Tables20260408.docx](attachments/2026-04-08_Re--Taxometric-Analysis/Figures%20%26%20Tables20260408.docx) (93 KB)
   - [raw_indicators.csv](../../data/raw/raw_indicators.csv) (12 KB)
   ```

6. **回覆信無附件但引用原信附件時**：若 `list_attachments` 為空，但 body 中出現 `<filename.ext>` 形式的引用標記（Mail.app 的 quote-time marker），插入 cross-reference：

   ```markdown
   Attachments:
   (Attachments on the original email from {original_sender} — see `{original_stem}.md`)
   ```

   若無法推斷原始 stem（原信未歸檔），改為：
   ```markdown
   (Attachments referenced in thread quote — original not yet archived)
   ```

7. **累計計數**：記錄 `data_count`、`document_count`、`inline_count`(v2.15.0+) 供 Step 7 報告用。

#### Step 5.5.5: Inline cid: download fallback (v2.15.0+, issue #45)

若 Step 5.5.0 的 `save_attachment(inline_filename)` 失敗(binary 不支援 inline name 或 inline cid: 不在 binary 的 attachment list),**不**完全 skip — 改寫 cross-reference 註記:

```markdown
Inline images:
- (cid:331ECED2 — CleanShot 2026-05-07 at 15.44.58@2x.png — binary 無法 download by name;見 Mail.app 原始信)
```

User 看到註記知道 inline 圖存在但需手動 export from Mail.app。Filed 上游 issue 在 PsychQuant/che-apple-mail-mcp 跟進 binary-side support。

### Step 5.7: 維護 `threads.json`（v2.6.0+,路徑 v2.8.0+ 改 `${THREADS_FILE}`）

每封新歸檔的 md 寫出後,同步更新 `${THREADS_FILE}` (`.claude/.mail/state/archives/${SLUG}/threads.json`):

**格式**：

```json
{
  "version": "1.0",
  "last_updated": "2026-04-22T15:01:09Z",
  "threads": {
    "SE manuscript 10xx-2025": {
      "messages": [
        {
          "message_id": "<7F43E052-EA1B-432D-AF0C-64F0CDBD8B32@ntu.edu.tw>",
          "file": "2026-01-28_Re--SE-manuscript-10xx-2025.md",
          "date": "2026-01-28T08:00:24Z",
          "sender": "d06227105@ntu.edu.tw",
          "in_reply_to": "<eddba65d53754587aeee5d86ff631d2c@ntu.edu.tw>"
        }
      ],
      "participants": ["yfhsu@ntu.edu.tw", "d06227105@ntu.edu.tw", "d11227103@ntu.edu.tw"],
      "first_message": "2025-12-19T06:19:30Z",
      "last_message": "2026-01-28T08:00:24Z",
      "message_count": 1
    }
  }
}
```

**更新演算法**（對每封新歸檔的信）：

1. 從 md frontmatter 讀 `thread_key`
2. 若 `.threads.json` 裡沒有此 thread_key，建立新 entry：
   ```
   {"messages": [], "participants": [], "first_message": null, "last_message": null, "message_count": 0}
   ```
3. 在 `messages` 陣列**尾端** append 新 message（保持時間序；若日期早於 last_message，可插入正確位置，但一般 append 即可）
4. 更新 `participants` 集合（加入 sender + to + cc 的 email，去重）
5. 更新 `first_message` = `min(first_message, new.date)`，`last_message` = `max(last_message, new.date)`
6. `message_count += 1`
7. 更新頂層 `last_updated` 為目前時間

**Append-only 原則**：此索引只做新增，不修改、不刪除既有 entry。若 thread 需要分割或合併，用 `/archive-mail-rebuild-threads` 重建。

**同 thread 不同時段的處理**：若 bare subject 相同但兩組訊息時間相差 > 90 天，**仍歸在同一 thread**（因為我們尊重使用者的 subject 選擇）。若要拆分，使用者需手動改 md frontmatter 的 `thread_key`（例如加 `-2026` 後綴），然後跑 rebuild。

### Step 6: 更新 Message-ID 索引

將新歸檔的郵件加入 `${INDEX_FILE}` (`.claude/.mail/state/archives/${SLUG}/email_index.json`):

```json
{
  "version": "1.0",
  "last_updated": "YYYY-MM-DD",
  "emails": {
    "message-id@example.com": {
      "file": "2026-01-13_Meeting-notes.md",
      "date": "2026-01-13 14:30",
      "subject": "郵件主旨",
      "thread_key": "Meeting notes"
    }
  }
}
```

v2.6.0+ 在每個 email entry 多記一個 `thread_key`，方便反向查詢。

### Step 7: 輸出報告

```
═══════════════════════════════════════════
Archive Mail 完成
═══════════════════════════════════════════

過濾條件: user@example.com
輸出目錄: communication/emails

新歸檔: 5 封
  - 2026-01-13_Meeting-request.md
  - 2026-01-12_Report-feedback.md
  - ...

跳過（已歸檔）: 12 封

Thread 索引: 2 new threads, 3 existing threads updated
  - "Meeting notes": 3 new messages (total 5)
  - "Report feedback": 2 new messages (total 2, new thread)

附件: 15 個下載
  → 4 to data/raw
  → 11 to correspondence/attachments
  → 2 inline images to correspondence/attachments/{stem}/inline/  (v2.15.0+, #45)

═══════════════════════════════════════════
```

若無附件：`附件: 0 個下載`(不顯示分類明細)。
若無 inline images,省略該行(v2.15.0+ 新加,只在有 inline 時顯示)。
Thread 索引行（v2.6.0+）：永遠顯示，即使沒新 thread。

### Step 8: 覆蓋率稽核（Coverage Audit）（v2.4.0+）

歸檔主流程結束後，自動執行覆蓋率稽核：

**8a. 附件完整性檢查**：

對所有新歸檔的郵件,**分兩部分檢查**(v2.15.0+, #45):

**8a.1 Explicit attachments**:呼叫 `list_attachments` 取得 explicit MIME attachment 數量,比對磁碟上對應目錄的實際檔案數。

- 一致 → pass
- 不一致 → 發出 warning：`⚠️ {email_stem}: {差異} explicit attachment missing (expected {報告數}, found {磁碟數})`

**8a.2 Inline cid: images** (v2.15.0+):從 HTML body 解析 inline cid: 引用數量,比對 `{stem}/inline/` 目錄實際檔案數。

- 一致 → pass
- 不一致(已 cross-reference 註記取代下載)→ 發出 warning:`⚠️ {email_stem}: {N} inline images cross-referenced (binary download unsupported); see Mail.app for visual content`
- 完全 miss(連 cross-reference 都沒)→ `⚠️ {email_stem}: {N} inline images parsed from body but not handled (skill bug, file follow-up)`

**8b. Thread 完整性檢查**：

對歸檔中每個唯一的 bare subject：
1. 用 bare subject 搜尋 `search_emails(field: "subject", query: bare_subject)`，取得 total count
2. 比對已歸檔的 count
3. 若 `archived < total` → 發出 warning：`⚠️ Thread "{subject}": {差額} potential missing siblings (archived {已歸檔}/{total})`

**8c. 稽核報告**：

```
Archive Coverage Audit
═══════════════════════════════════════════
附件覆蓋: explicit 15/15 + inline 2/3 (1 cross-ref'd) (94%)
Thread 覆蓋: 3 threads, 2 complete, 1 with gaps

搜尋結果: 37 by sender + 12 by subject + 9 by thread expansion = 58 unique

Issues:
  ⚠️ 2026-04-08_Re--Taxometric: 1 attachment missing
  ⚠️ 2026-05-07_Re--Solution: 1 inline image cross-referenced (binary unsupported)
  ⚠️ Thread "indicator selection": 2 potential missing siblings

建議: 在 .claude/.mail/config.md 加入 subject_keywords 擴大搜尋範圍
═══════════════════════════════════════════
```

若所有檢查通過：
```
Archive Coverage Audit
═══════════════════════════════════════════
附件覆蓋: explicit 15/15 + inline 3/3 (100%) ✓
Thread 覆蓋: 3 threads, 3 complete ✓
═══════════════════════════════════════════
```

若無 inline,簡化:`附件覆蓋: 15/15 (100%) ✓`(同 v2.14.0 ↓ 行為)。

## 注意事項

- 使用 apple-mail MCP，需確保 MCP server 已連接
- Message-ID 用於去重，確保不會重複歸檔
- 寄出的郵件不產生「重點摘要」和「待辦事項」
- **附件自動下載**（v2.3.0+）：每封歸檔信件的附件會自動下載到分類目錄。研究資料檔（csv / sav / xlsx 等）放到 `data/raw/`；文件附件（pdf / docx 等）放到 `correspondence/attachments/{email_stem}/`。可透過 `.claude/emails.md` 的 `attachment_routing` 區塊自訂規則。
- **搜尋擴展 + 覆蓋率稽核**（v2.4.0+）：除了 sender 搜尋，可設定 `subject_keywords` 補抓 internal threads。每次歸檔後自動跑 Coverage Audit 檢查附件完整性和 thread 覆蓋率。
- **Thread 索引**（v2.6.0+）：歸檔時自動維護 `.threads.json`，記錄每個 thread 包含哪些 messages、參與者、時間範圍。每封 md 的 YAML frontmatter 也帶有 `thread_key` / `in_reply_to`，為 canonical truth。搭配 `/archive-mail-view <thread_key>` 生成聚合 thread 視圖，`/archive-mail-rebuild-threads` 從 md 重建索引。

## 附件分類設定範例

在 `.claude/emails.md` front matter 加入 `attachment_routing` 覆寫預設規則。**注意：partial override 取代所有預設**——省略的欄位會變成空列表，不會自動使用內建預設。

完整預設值（供 copy-paste）：

```yaml
---
filters:
  - tatsuma
attachment_routing:
  data_extensions: [csv, tsv, sav, dta, parquet, feather, xlsx, sas7bdat]
  document_extensions: [pdf, docx, doc, txt, md, rtf, odt]
  data_keywords: [data, raw, indicators, codebook, dataset]
  document_keywords: [Submission, Figures, Tables, Manuscript, draft, Revision, v1, v2, v3]
  data_dir: data/raw
  documents_dir: correspondence/attachments
---
```

只需列出想改的部分（但理解：列出即取代整組預設）：

```yaml
---
attachment_routing:
  data_extensions: [csv, sav]            # 只認這兩種為 data
  data_keywords: [raw, indicators]       # 窄化 keyword
  data_dir: research/raw-data            # 自訂 data 目標路徑
  documents_dir: correspondence/attachments  # 保留預設
---
```

## 搜尋擴展設定範例（v2.4.0+）

```yaml
---
filters:
  - tatsuma
subject_keywords:                        # 用 subject 關鍵字補抓 internal threads
  - taxometric
  - SSQ
  - "attachment security"
participant_aliases:                     # 成員別名（audit 報告顯示用）
  "b08801008@ntu.edu.tw": "Pei-Chi"
  "kllay@ntu.edu.tw": "Lay"
attachment_routing:
  data_dir: data/raw
  documents_dir: correspondence/attachments
---
```

設定 `subject_keywords` 後，Step 3 會自動做三輪搜尋（sender + subject keyword + thread-subject expansion）並去重。Step 8 Coverage Audit 會報告覆蓋率。
