---
description: 顯示目前使用的 Claude Code 帳號
argument-hint:
allowed-tools: Bash(echo:*), Bash(ls:*), Bash(cat:*), Read
---

# Claude Switch - 目前帳號

顯示目前使用的 Claude Code 帳號資訊。

## 流程

### Step 1: 檢查 CLAUDE_CONFIG_DIR

```bash
echo "🔍 目前 Claude Code 帳號"
echo "========================="
echo ""

if [ -z "$CLAUDE_CONFIG_DIR" ]; then
    echo "帳號: default (預設)"
    echo "路徑: $HOME/.claude"
    CONFIG_DIR="$HOME/.claude"
else
    ACCOUNT_NAME=$(basename "$CLAUDE_CONFIG_DIR" | sed 's/^\.claude-//')
    echo "帳號: $ACCOUNT_NAME"
    echo "路徑: $CLAUDE_CONFIG_DIR"
    CONFIG_DIR="$CLAUDE_CONFIG_DIR"
fi
```

### Step 2: 檢查帳號狀態

```bash
echo ""
echo "📁 目錄狀態"
echo "-----------"

# 檢查目錄是否存在
if [ -d "$CONFIG_DIR" ]; then
    echo "目錄: ✅ 存在"
else
    echo "目錄: ❌ 不存在"
fi

# 檢查 IDE symlink
if [ -L "$CONFIG_DIR/ide" ]; then
    TARGET=$(readlink "$CONFIG_DIR/ide")
    echo "IDE:  ✅ symlink → $TARGET"
elif [ -d "$CONFIG_DIR/ide" ]; then
    echo "IDE:  ⚠️  是目錄（非 symlink）"
else
    echo "IDE:  ❌ 不存在"
fi

# 檢查 settings.json
if [ -f "$CONFIG_DIR/settings.json" ]; then
    echo "設定: ✅ settings.json 存在"
else
    echo "設定: ⚠️  settings.json 不存在"
fi
```

### Step 3: 顯示登入狀態

```bash
echo ""
echo "🔐 登入狀態"
echo "-----------"

if [ -f "$CONFIG_DIR/.credentials.json" ]; then
    echo "憑證: ✅ 已登入"
else
    echo "憑證: ❌ 未登入（需要執行 claude login）"
fi
```
