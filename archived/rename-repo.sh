#!/bin/bash
# rename-repo.sh — 將 che-claude-plugins 改名為 psychquant-claude-plugins
# 執行前請先關閉 VS Code 中的此 workspace

set -euo pipefail

OLD_NAME="che-claude-plugins"
NEW_NAME="psychquant-claude-plugins"
REPO_DIR="$HOME/Developer"
CLAUDE_PROJECTS="$HOME/.claude/projects"
CLAUDE_CACHE="$HOME/.claude/plugins/cache"

OLD_PATH="$REPO_DIR/$OLD_NAME"
NEW_PATH="$REPO_DIR/$NEW_NAME"

# Claude Code project context 目錄（路徑中 / 替換為 -）
OLD_CTX="$CLAUDE_PROJECTS/-Users-che-Developer-$OLD_NAME"
NEW_CTX="$CLAUDE_PROJECTS/-Users-che-Developer-$NEW_NAME"

echo "=== Rename: $OLD_NAME → $NEW_NAME ==="
echo ""

# 1. 檢查前置條件
if [ ! -d "$OLD_PATH" ]; then
    echo "❌ 找不到 $OLD_PATH"
    exit 1
fi

if [ -d "$NEW_PATH" ]; then
    echo "❌ $NEW_PATH 已存在"
    exit 1
fi

# 2. 重新命名本地資料夾
echo "1/3  重新命名資料夾..."
mv "$OLD_PATH" "$NEW_PATH"
echo "     $OLD_PATH → $NEW_PATH"

# 3. 重新命名 Claude Code project context
echo "2/3  遷移 Claude Code project context..."
if [ -d "$OLD_CTX" ]; then
    mv "$OLD_CTX" "$NEW_CTX"
    echo "     已遷移 project context"
else
    echo "     (無舊的 project context，跳過)"
fi

# 4. 重新命名 plugin cache 目錄
echo "3/3  重新命名 plugin cache..."
if [ -d "$CLAUDE_CACHE/$OLD_NAME" ]; then
    mv "$CLAUDE_CACHE/$OLD_NAME" "$CLAUDE_CACHE/$NEW_NAME"
    echo "     已重新命名 cache 目錄"
else
    echo "     (無舊的 cache 目錄，跳過)"
fi

echo ""
echo "=== 完成 ==="
echo ""
echo "下一步："
echo "  cd $NEW_PATH"
echo "  code .                          # 重新開啟 VS Code"
echo "  claude                          # 啟動 Claude Code"
echo "  /reload-plugins                 # 重新載入 plugins"
