# Plugin Component Surface ↔ README 同步紀律

Plugin 自身的「工具面」是它匯出的 skills / agents / commands / hooks。這個集合變動時，**必須**在同一個 commit 或同一個 release 週期內更新 README。

## 為什麼

Plugin README 是 marketplace 卡片的延伸。讀者（人 + LLM）靠 README 判斷：

| 問題 | README 要能回答 |
|------|--------------|
| 這 plugin 做什麼？ | Features / Overview |
| 裝了之後我能用哪些東西？ | Skills 清單 + Agents 清單 + Commands 清單 |
| 對應工作流怎麼跑？ | Usage / Examples |
| 和相關 plugin 怎麼區分？ | Comparison / When to use which |

Plugin 的 component 一改但 README 沒動：

- 新加的 skill 使用者不知道它存在 → 沒人叫 → 做白工
- 移除的 skill README 還寫著 → 使用者叫了但找不到 → 回報 bug
- Skills 之間職責分工改動（例如把功能從 A skill 搬到 B skill）→ 舊 README 的決策樹誤導

## 觸發條件

滿足任一即啟動：

1. **新增 skill / agent / command / hook**
2. **移除 / rename 上述任一**
3. **Skill 的 description 重大改寫**（因為 description 決定 LLM 何時叫它）
4. **Skill 之間職責重分配**（功能從 A 搬到 B，兩邊 README 都要動）
5. **Plugin keyword / description 在 plugin.json 改變**
6. **依賴的 binary 或外部 plugin 改變**（例如原本依賴 mcp-X，改成內建）

純 SKILL.md 內部步驟優化（2-step 改 3-step，不影響使用者感知）→ 不需動 README。

## 必要的 README 改動範圍

| 改動 | README 連動 |
|------|------------|
| 加 skill | Skills 表格 / Quick Reference / Usage Examples |
| 加 agent | Agents 表格 + When to use this agent |
| 加 command | Commands 表格 + 觸發語法 |
| Skill 之間職責重劃 | 「Skill 比較表」或 Decision tree |
| 依賴其他 plugin | Prerequisites / Related plugins |
| 重大重構（v1 → v2） | Migration section |

## Plugin 家族的「橫向同步」責任

`plugin-tools` / `mcp-tools` / `cli-tools` 這種**家族 plugin**有額外義務：
當其中一個 plugin 的 `*-deploy` skill 規則改了（例如 `mcp-deploy` 加了 Step 2.6 README check），
它的 sibling（`cli-deploy`、`plugin-deploy`）如果適用同樣的 pattern，**應該同步加**。

否則會出現「MCP 的 deploy 會檢查 README，CLI 的 deploy 不會」這種隱性不對稱，踩坑的是未來的自己。

## Deploy 前的自我檢查

`plugin-deploy` skill 跑完**前**做這個檢查：

```bash
# 實際有的 components
ACTUAL_SKILLS=$(ls plugins/$PLUGIN/skills/ 2>/dev/null | sort)
ACTUAL_AGENTS=$(ls plugins/$PLUGIN/agents/*.md 2>/dev/null | xargs -n1 basename | sort)
ACTUAL_COMMANDS=$(ls plugins/$PLUGIN/commands/*.md 2>/dev/null | xargs -n1 basename -s .md | sort)

# README 裡提到的 components
DOCUMENTED=$(grep -oE '`[a-z_-]+`' plugins/$PLUGIN/README.md | sort -u)

# 找出 README 沒提到的 actual component
for s in $ACTUAL_SKILLS; do
  grep -q "\`$s\`" plugins/$PLUGIN/README.md || echo "⚠️ Skill '$s' 不在 README"
done
```

## 當 README 落差已累積時的補救

1. **用 `ls skills/ agents/ commands/` 做 ground truth**，逐一檢查 README 是否列齊
2. **Skills 表格重建** — 每個 skill 的 description frontmatter 抓出來對照 README
3. **Agent 描述重建** — agent 描述是判斷「這個 agent 是否應該被叫」的關鍵，對照 README 確保對齊
4. **Version History 表格補齊** — 把中間遺漏的 minor 版本補上，寫明當時加了什麼

## 例外

- 純 rule 修改或 bug fix（SKILL.md 內部小改，沒加減 component）→ README 可不動
- 未發佈到 marketplace 的 WIP plugin → README 可延後；但 push 前要補

## 和其他 skill 的關係

- `plugin-deploy` Step 2.6 做 component inventory 對照，不一致時 **BLOCK** 發布
- `plugin-upgrade` 建議加新 skill 時，會提醒「README Skills 表格要補 1 行」
- `plugin-create` scaffold 直接產出含 Skills / Agents / Commands 三區塊的 README 骨架

## TL;DR

**改了 `skills/` `agents/` `commands/` 任一個目錄，就改 README；README 沒改就不要 bump 版本、不要 push。**
