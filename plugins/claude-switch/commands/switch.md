---
description: 切換 Claude Code 帳號（設定 CLAUDE_CONFIG_DIR）
argument-hint: <account-name>
allowed-tools: Bash(export:*), Bash(ls:*), Bash(mkdir:*), Bash(ln:*), Bash(echo:*), Bash(cat:*), Read
---

# Claude Switch - 切換帳號

切換到指定的 Claude Code 帳號。

## 參數

- `$1` = 帳號名稱（如 `kiki830621`、`work`、`personal`）

## 流程

### Step 1: 確認帳號目錄存在

```bash
ACCOUNT_NAME="$1"
CONFIG_DIR="$HOME/.claude-$ACCOUNT_NAME"

if [ ! -d "$CONFIG_DIR" ]; then
    echo "❌ 帳號目錄不存在: $CONFIG_DIR"
    echo "請先執行: /claude-switch:setup $ACCOUNT_NAME"
    exit 1
fi
```

### Step 2: 確認 IDE symlink 存在

```bash
if [ ! -L "$CONFIG_DIR/ide" ]; then
    echo "⚠️  IDE symlink 不存在，正在建立..."
    ln -s "$HOME/.claude/ide" "$CONFIG_DIR/ide"
    echo "✅ IDE symlink 已建立"
fi
```

### Step 3: 輸出切換指令

**重要**: Claude Code 無法直接修改 shell 環境變數。輸出指令讓使用者執行：

```bash
echo ""
echo "📋 請在終端機執行以下指令來切換帳號："
echo ""
echo "    export CLAUDE_CONFIG_DIR=$CONFIG_DIR"
echo ""
echo "💡 建議加入 ~/.zshrc 或 ~/.bashrc："
echo ""
echo "    # Claude Code 帳號切換函數"
echo "    claude-switch() {"
echo "        export CLAUDE_CONFIG_DIR=\"\$HOME/.claude-\$1\""
echo "        echo \"Switched to Claude account: \$1\""
echo "    }"
echo ""
```

### Step 4: 顯示帳號資訊

```bash
echo "📁 帳號目錄: $CONFIG_DIR"
echo ""
ls -la "$CONFIG_DIR/" | head -10
```

## 注意事項

1. 切換帳號後需要重新啟動 Claude Code session
2. VS Code 的 Claude Code 擴充套件不受 CLAUDE_CONFIG_DIR 影響
3. IDE 連接透過 symlink 共用，不受帳號切換影響
