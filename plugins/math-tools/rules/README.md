# math-tools rules — v0.1.0 frozen baseline

The 3 rules in this directory are **verbatim copies** from `PsychQuantHsu/psychophysical_representations/.claude/rules/` as of 2026-05-15 (dogfood origin of this plugin, see issue #107 closing comment for full pilot history).

## Files

| Rule | Origin | Scope |
|------|--------|-------|
| `manuscript-jsonl-sync.md` | psychophysic_representations#106 | Prop-level main.tex ↔ JSONL sync HARD RULE (edit-time prevention) |
| `manuscript-consistency-audit.md` | psychophysic_representations#42 + #78 | Audit-time R1-R4 detection SOP (post-hoc + CI gate) |
| `code-and-manuscript-sync.md` | psychophysic_representations (per `code-and-manuscript-sync.md` §歷史成因) | Repo-level cross-repo cluster PR scope discipline |

## v0.1.0 limitations

These rules currently reference **source-repo-specific** paths and identifiers:

- Path conventions: `manuscript/main.tex`, `manuscript/propositions/*.jsonl`, `analysis/`, `references/*.tex`, `correspondence/`
- Issue refs: `PsychQuantHsu/psychophysical_representations#NNN`
- Tool paths: `scripts/validate-propositions.py`, `scripts/audit-symbols.py`, `scripts/refresh-prop-locations.py`

If you install `math-tools` in another math-article repo, these references **will not auto-resolve**. Treat them as illustrative until v0.2.0 generalizes:

- v0.2.0 target: parameterize paths via `.claude/math-tools.json` per-project config
- v0.2.0 target: extract issue refs into generic dogfood-origin pointers
- v0.2.0 target: bundle scripts inside this plugin (not link out to source repo)

## Why ship frozen baseline first

Per `#107` proofread workflow experiment closing summary §改進空間:

> Skill systematization — 3 pilots 累積足夠 UX data,下次值得 build skill。已標 [-] deferred。

This plugin is the **first step** toward that systematization — capture the working content now while the methodology is fresh; generalize after 2-3 more repos prove the pattern transfers.

## Loading

These rules are auto-injected into every Claude Code session that has the `math-tools` plugin installed and enabled in a math-article repo (file extension heuristic: `.tex` in working tree). Per `psychquant-claude-plugins` marketplace convention.
