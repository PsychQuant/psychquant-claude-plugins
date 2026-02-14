---
description: 列出所有 Claude Code 帳號
argument-hint:
allowed-tools: Bash(ls:*), Bash(echo:*), Bash(grep:*), Bash(wc:*), Read
---

# Claude Switch - 列出帳號

顯示所有可用的 Claude Code 帳號。

## 流程

### Step 1: 找出所有帳號目錄

```bash
echo "📋 Claude Code 帳號列表"
echo "========================"
echo ""

# 預設帳號
if [ -d "$HOME/.claude" ]; then
    if [ "$CLAUDE_CONFIG_DIR" = "" ] || [ "$CLAUDE_CONFIG_DIR" = "$HOME/.claude" ]; then
        echo "  ✅ default (預設) ← 目前使用中"
    else
        echo "  ⬜ default (預設)"
    fi
    echo "     路徑: $HOME/.claude"
    echo ""
fi

# 其他帳號
for dir in "$HOME"/.claude-*; do
    if [ -d "$dir" ]; then
        ACCOUNT_NAME=$(basename "$dir" | sed 's/^\.claude-//')

        # 檢查是否為目前使用的帳號
        if [ "$CLAUDE_CONFIG_DIR" = "$dir" ]; then
            echo "  ✅ $ACCOUNT_NAME ← 目前使用中"
        else
            echo "  ⬜ $ACCOUNT_NAME"
        fi

        # 檢查 IDE symlink
        if [ -L "$dir/ide" ]; then
            echo "     IDE: ✅ symlink 已設定"
        else
            echo "     IDE: ⚠️  symlink 未設定（執行 /claude-switch:setup $ACCOUNT_NAME）"
        fi

        echo "     路徑: $dir"
        echo ""
    fi
done
```

### Step 2: 顯示統計

```bash
TOTAL=$(ls -d "$HOME"/.claude-* 2>/dev/null | wc -l | tr -d ' ')
echo "------------------------"
echo "總計: $((TOTAL + 1)) 個帳號（含預設）"
echo ""
echo "💡 切換帳號: /claude-switch:switch <account-name>"
echo "💡 新增帳號: /claude-switch:setup <account-name>"
```
