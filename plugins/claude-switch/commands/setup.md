---
description: 設定新的 Claude Code 帳號（建立目錄、IDE symlink）
argument-hint: <account-name>
allowed-tools: Bash(mkdir:*), Bash(ln:*), Bash(ls:*), Bash(echo:*), Bash(cp:*), Read
---

# Claude Switch - 設定新帳號

建立新的 Claude Code 帳號目錄並設定 IDE symlink。

## 參數

- `$1` = 帳號名稱（如 `work`、`personal`、`kiki830621`）

## 流程

### Step 1: 建立帳號目錄

```bash
ACCOUNT_NAME="$1"
CONFIG_DIR="$HOME/.claude-$ACCOUNT_NAME"

if [ -d "$CONFIG_DIR" ]; then
    echo "⚠️  帳號目錄已存在: $CONFIG_DIR"
else
    mkdir -p "$CONFIG_DIR"
    echo "✅ 建立帳號目錄: $CONFIG_DIR"
fi
```

### Step 2: 建立 IDE symlink

```bash
if [ -L "$CONFIG_DIR/ide" ]; then
    echo "✅ IDE symlink 已存在"
elif [ -d "$CONFIG_DIR/ide" ]; then
    echo "⚠️  IDE 是目錄而非 symlink，正在修復..."
    rm -rf "$CONFIG_DIR/ide"
    ln -s "$HOME/.claude/ide" "$CONFIG_DIR/ide"
    echo "✅ IDE symlink 已建立"
else
    ln -s "$HOME/.claude/ide" "$CONFIG_DIR/ide"
    echo "✅ IDE symlink 已建立"
fi
```

### Step 3: 確認預設 ide 目錄存在

```bash
if [ ! -d "$HOME/.claude/ide" ]; then
    mkdir -p "$HOME/.claude/ide"
    echo "✅ 建立預設 IDE 目錄: $HOME/.claude/ide"
fi
```

### Step 4: 顯示結果

```bash
echo ""
echo "📋 帳號設定完成"
echo "==============="
echo ""
echo "帳號名稱: $ACCOUNT_NAME"
echo "設定目錄: $CONFIG_DIR"
echo ""
ls -la "$CONFIG_DIR/"
echo ""
echo "📌 下一步"
echo "---------"
echo ""
echo "1. 切換到此帳號："
echo "   export CLAUDE_CONFIG_DIR=$CONFIG_DIR"
echo ""
echo "2. 登入 Claude："
echo "   claude login"
echo ""
echo "3. 或使用 shell 函數（加入 ~/.zshrc）："
echo ""
echo "   claude-switch() {"
echo "       export CLAUDE_CONFIG_DIR=\"\$HOME/.claude-\$1\""
echo "       echo \"Switched to Claude account: \$1\""
echo "   }"
echo ""
echo "   然後執行: claude-switch $ACCOUNT_NAME"
```

## IDE Symlink 說明

VS Code 的 Claude Code 擴充套件固定使用 `~/.claude/ide/` 目錄。
透過 symlink，所有帳號都能共用同一個 IDE 連接：

```
~/.claude/ide/                    ← VS Code 擴充套件寫入
~/.claude-kiki830621/ide/         → symlink
~/.claude-work/ide/               → symlink
~/.claude-personal/ide/           → symlink
```

這樣不管切換到哪個帳號，`/ide` 都能正常偵測 VS Code。
