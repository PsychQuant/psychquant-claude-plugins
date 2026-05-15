# Code-and-Manuscript Sync — 改一邊必改另一邊

## 規則(HARD RULE)

本專案的「**程式碼**」(`analysis/`)、「**參考文獻**」(`references/`)、「**manuscript**」(`manuscript/docs/` + `manuscript/*.tex`)是**單一 deliverable 的三面**,不是三個獨立 deliverable。

任何 IDD 改動(`/idd-diagnose` → `/idd-implement`)若觸及其中一面,**必須**在同一個 PR / commit cluster 內審視並改動所有受影響的另外兩面。**禁止**把跨面 propagation 標為「out-of-scope follow-up」並另開 PR 處理。

## 為什麼

學術論文的程式碼產出餵進 manuscript 的 theorem / proof;manuscript 的推導依賴 references/ 的 source paper;references 又是 code 命名與算法 spec 的源頭。三者構成 source-of-truth 三角:

```
references/*.tex  ←→  analysis/*.py
       ↓                  ↓
       └──→ manuscript/docs/*.md ←──┘
            manuscript/*.tex
```

任一面改動而另兩面未同步 = source-of-truth drift。具體危害:

- **Reviewer**:看到 manuscript 引用已不存在的 reference paper / 已不存在的 analysis function → 無法 reproduce。
- **下次來開發的 AI / 合作者**:讀 manuscript 想對照 code,grep 不到對應函數 → 誤以為 code base 不完整或 manuscript 是 stale。
- **Submission 階段**:Late-stage 才發現「程式 omit Form B 但 manuscript 還有 50 行 Form B 推導」→ 大幅 rework 或撤稿風險。

## Submodule 邊界 ≠ IDD scope 邊界

`manuscript/` 是獨立 git repo(`PsychQuantHsu/psychophysical_representations_manuscript`),掛為上層 submodule。**這個 repo boundary 不該成為 IDD scope 邊界。**

正確流程:

```bash
# 1. 在 manuscript submodule 內 commit manuscript 改動
cd manuscript
git checkout -b idd/cluster-19-22-manuscript-scope
# ...edit docs/formB_*.md / *.tex...
git commit -m "refactor(manuscript): remove Form B docs (Refs PsychQuantHsu/psychophysical_representations#19)"
git push -u origin idd/cluster-19-22-manuscript-scope
gh pr create --repo PsychQuantHsu/psychophysical_representations_manuscript ...

# 2. 上層 repo bump submodule pointer 到 manuscript branch HEAD,在同 cluster PR
cd ..
git add manuscript
git commit -m "chore: bump manuscript submodule pointer (Refs #19 #22 cluster scope)"
```

兩個 PR 互相 cross-link(上層 PR refs manuscript PR;manuscript PR refs 上層 issue + PR)。**不可**讓上層 PR merge 後才打開 manuscript PR — 那是「split scope」反 pattern,違反本規則。

## 例外(rare,需明示理由)

容許 split scope 的唯一情境:

- **Overleaf 端衝突 in-flight**:user 正在 Overleaf 改 `manuscript/*.tex`,沒辦法在 AI session 內安全 edit。此時:
  - 仍**列**所有受影響的 manuscript files 在 PR body
  - 標 `OVERLEAF-WAIT`(不是 `OUT-OF-SCOPE`)
  - PR body 給 follow-up issue link + 期望 sync 時點
  - `idd-close` 前必須 verify manuscript 已 sync

- **Manuscript 影響 unclear**:diagnosis 階段就告訴 user「不確定 manuscript 是否受影響」,AskUserQuestion 確認後才寫成 out-of-scope。**禁止** AI 自行判斷「manuscript 應該不太需要動」就 split。

## Within-file frozen subregion exception(v1.2, 2026-05-12)

某些 living docs(例如 `manuscript/docs/review-summary.md`)結構上**混合 current-state + historical log**:檔案的頭部是 living 內容(top scope-update note、currently-active section),body 是 frozen historical iteration log(rounds 1-N 的 history)。對這種「within-file frozen subregion」混合檔案:

- **頭部 living 部分** — sync 要求**完全適用**(must update with current scope changes)
- **body frozen iteration log** — 視為「within-file frozen subregion」,sync 要求**不適用**(歷史 log 的 value 是不被修改的時間順序紀錄)

實務 marker(at least one needed for within-file exception to apply):

1. 檔案頭部明確 section header 標示「historical」/「audit trail」/「iteration log」/「scope-update note above」,且該 section 之後的 body 都是 frozen 內容
2. Living portion 主動 forward-link 到 #N(scope decision)讓 reader 知道 body 內容是 pre-decision 狀態
3. 檔案被 idd-issue / idd-implement / idd-verify cycle 明確標記為 「partial-sync」(在 PR body 列出)

不滿足 marker = 整檔視為 living,sync 要求完全適用。

混淆風險:若 living portion 沒有明確 "scope-update note above + frozen section below" 結構,容易讓 reader 誤把 frozen log 當 current state。**Diagnose 階段必補檢查**:對 partial-sync 檔案,確認 marker 存在 + frozen subregion 對外有明示 boundary。

## Frozen historical record exception(v1.1, 2026-05-12)

以下 paths 是 **frozen historical records**,本規則的 sync 要求**不適用**;若這些 path 內仍有對已刪 / 已改 symbol 的引用,**不**視為 dangling consumer,但需在當前的 living docs(`docs/review-summary.md`、`docs/STATE.md` 等)中加 scope-update 註記指向新決策:

- `manuscript/docs/rounds/*.md` — 個別 review round 的 audit log,frozen at the time of review
- `manuscript/docs/legacy/*` — 已 retire 的 working drafts
- `correspondence/*` — email archive 與歷史 thread,frozen at receipt time
- 任何 `archived/` / `archive/` directory(已有 archive-first plugin 守護)

**為什麼例外**:這些 path 的 value 是 audit trail(「什麼時候誰決定了什麼」)。Retroactive editing 會 destroy 這個 value — 三個月後 reviewer 想看「Form B 當時是怎麼被討論的」會看到 sanitized 版本而非真實當時 state。修改 frozen records = 改變歷史。

**邊界**:`manuscript/docs/STATE.md`、`README.md`、`docs/README.md`、`cover-letter-template.md`、`reviewer-reply-template.md`、`review-summary.md` 等 living docs **不在例外範圍** — 它們 represent current state,sync 要求**完全適用**。

**Diagnosis check 必補一句**:對被 grep 到的引用,explicit 區分 (a) frozen record(免 sync,標 audit-update 在 living docs)vs (b) living doc(必 sync)。混 (a) 與 (b) = 規則 violation。

## Diagnosis 階段必檢

`/idd-diagnose` 對任何 code / references 改動,**必須**在 Strategy / Impact 段顯式回答:

1. 此 code 改動會 invalidate 哪些 `manuscript/docs/*.md` 的推導 / 引用?(用 `grep -rln "<deleted-symbol>" manuscript/docs/`)
2. 此 code 改動會 invalidate 哪些 `manuscript/*.tex` 的 theorem / proof?
3. 上述受影響檔案是否在本 cluster 的 implementation plan 內?如否,**升級** scope 或 abort 重新 diagnose。

回答「**N/A — 純 IDD tooling 改動,manuscript 不影響**」是合法答案(例如改 `.mail/` config),但必須**明示寫出**這個判斷,不能省略。

## Verification 階段必檢

`/idd-verify` 的 Regression Reviewer 必須額外驗證:

- diff 中刪除的 symbol / 檔案,grep manuscript/docs/ + manuscript/*.tex 有無遺漏引用
- 若 manuscript 仍引用已刪內容 → **blocking finding**,PR 不能 PASS

## 歷史成因

本規則 2026-05-12 加入,起因為 cluster PR #25 (`#19` Form B omission + `#22` references housekeeping):AI 把 `manuscript/docs/` 10 個 Form B docs 標為 `out-of-scope follow-up` 並另期 PR 處理。User 介入指正:此 split 違反 source-of-truth 三角約束,manuscript edits 應在同 cluster 完成。

完整原則(來自 user 2026-05-12 對話):
> 「我發現你好像忽略了改的時候 manuscripts 也都要一併修改,不是只有程式」

## 與 issue-routing.md 的關係

[`.claude/rules/issue-routing.md`](issue-routing.md):「所有 issue 都開上層 repo」— 這是 **GitHub issue tracking** 的紀律。
**本規則**:「所有 implementation 都跨 code + manuscript」— 這是 **PR scope** 的紀律。

兩者互補。同一 issue 可以驅動上層 repo PR + manuscript submodule PR 兩條,只要 cross-link + 同 cluster + 同步 merge。

## See also

[`manuscript-consistency-audit.md`](manuscript-consistency-audit.md) — **audit-time detection** SOP,互補於本規則的 **PR-time prevention**。

| Rule | 何時運作 | 防範什麼 |
|------|----------|----------|
| 本規則 `code-and-manuscript-sync.md` | PR-time(改一邊時) | 避免單 PR 內 code 改但 manuscript 沒同步 |
| `manuscript-consistency-audit.md` | Audit-time(大改稿後 / 投稿前) | 偵測歷史 drift 累積後的不一致(working-file leak、citation drift、symbol drift) |
| `.github/workflows/manuscript-audit.yml`(CI gate, #78) | PR-side machine enforcement | 把 audit SOP 自動跑在每個 PR;R1/R2/R4 blocking → PR 紅燈無法 merge |

兩者**並非**取代關係:hard rule(本規則)是 prevention,SOP(audit)是 detection,CI gate(#78)是兩者的 machine-side enforcement。即使 hard rule 嚴格執行,drift 仍可能在 review back-and-forth、concurrent editing、scope-split mistakes 等情境下累積,需要 audit pass 補抓 + CI gate 把 audit 自動化。

## GH Actions CI gate (PR-side enforcement, #78)

從 #78 開始,`.github/workflows/manuscript-audit.yml` 成為本規則的 **PR-time prevention** 機械補強層。本規則(prevention by author discipline)+ CI gate(prevention by machine enforcement)+ audit SOP(detection)三層 defense-in-depth:

| 層級 | Enforcement | 失敗時 |
|------|-------------|--------|
| 本規則 `code-and-manuscript-sync.md`(human-side) | Reviewer / author 自我紀律 | PR open 即被 reviewer 標 "scope split" 然後 author 補 |
| `.githooks/pre-commit`(author-side machine) | R1 + R2 + R4 fast passes | Commit aborts(`git commit --no-verify` bypass for emergency) |
| `.github/workflows/manuscript-audit.yml`(PR-side machine) | Full R1 + R2 + R3 + R4 on every PR | PR 紅燈 `manuscript-audit / run` = FAILURE,無法 merge |
| `./scripts/run-audit.sh manuscript/`(on-demand) | Per SOP §5 trigger(大改稿 / 投稿前 / 新階段) | Author 自決修不修 |

CI gate 確保即使 author 跳過 pre-commit hook、或外部 contributor 從未裝過 hook,只要 PR open / push to main 就會被 audit。Cross-repo private submodule auth via `MANUSCRIPT_TOKEN` PAT secret(see README "CI gate" subsection)。

CI gate 不取代本規則 — 本規則的「manuscript 同步必須在同 PR」紀律,CI 只能驗 audit 過,不能驗 author intent。但 CI 抓 R1/R2/R4 drift 後拒絕 merge (R3 視為 informational baseline,不阻 merge — 詳見 `manuscript-consistency-audit.md` §8 + §9 Pattern 7/8),等於把「scope split 偷渡」的 escape hatch 關掉。
