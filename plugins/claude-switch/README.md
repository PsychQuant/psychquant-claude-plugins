# claude-switch

Claude Code 多帳號管理工具。解決使用 `CLAUDE_CONFIG_DIR` 切換帳號時 `/ide` 無法偵測 VS Code 的問題。

## 問題背景

當使用 `CLAUDE_CONFIG_DIR` 環境變數切換 Claude Code 帳號時，VS Code 的 Claude Code 擴充套件仍然固定將 IDE 連接資訊寫入 `~/.claude/ide/`。這導致 CLI 的 `/ide` 命令找不到 VS Code。

## 解決方案

透過 symlink 讓所有帳號目錄的 `ide/` 都指向預設的 `~/.claude/ide/`：

```
~/.claude/ide/                ← VS Code 擴充套件寫入（固定）
~/.claude-account1/ide/       → symlink to ~/.claude/ide/
~/.claude-account2/ide/       → symlink to ~/.claude/ide/
```

## 命令

### `/claude-switch:list`

列出所有可用的 Claude Code 帳號。

```bash
/claude-switch:list
```

輸出範例：
```
📋 Claude Code 帳號列表
========================

  ⬜ default (預設)
     路徑: /Users/che/.claude

  ✅ kiki830621 ← 目前使用中
     IDE: ✅ symlink 已設定
     路徑: /Users/che/.claude-kiki830621
```

### `/claude-switch:current`

顯示目前使用的帳號及其狀態。

```bash
/claude-switch:current
```

### `/claude-switch:setup <account-name>`

建立新帳號目錄並自動設定 IDE symlink。

```bash
/claude-switch:setup work
/claude-switch:setup personal
```

### `/claude-switch:switch <account-name>`

切換到指定帳號（輸出需要執行的 shell 命令）。

```bash
/claude-switch:switch kiki830621
```

## Shell 函數（建議）

將以下函數加入 `~/.zshrc` 或 `~/.bashrc`：

```bash
# Claude Code 帳號切換
claude-switch() {
    local account="$1"
    local config_dir="$HOME/.claude-$account"

    if [ -z "$account" ]; then
        echo "Usage: claude-switch <account-name>"
        echo "       claude-switch default  # 切換回預設帳號"
        return 1
    fi

    if [ "$account" = "default" ]; then
        unset CLAUDE_CONFIG_DIR
        echo "Switched to default Claude account"
        return 0
    fi

    if [ ! -d "$config_dir" ]; then
        echo "Account not found: $config_dir"
        echo "Run: /claude-switch:setup $account"
        return 1
    fi

    # 確保 IDE symlink 存在
    if [ ! -L "$config_dir/ide" ]; then
        ln -s "$HOME/.claude/ide" "$config_dir/ide" 2>/dev/null
    fi

    export CLAUDE_CONFIG_DIR="$config_dir"
    echo "Switched to Claude account: $account"
}

# 自動補全
_claude_switch_completion() {
    local accounts=("default")
    for dir in "$HOME"/.claude-*; do
        if [ -d "$dir" ]; then
            accounts+=("$(basename "$dir" | sed 's/^\.claude-//')")
        fi
    done
    COMPREPLY=($(compgen -W "${accounts[*]}" -- "${COMP_WORDS[COMP_CWORD]}"))
}
complete -F _claude_switch_completion claude-switch
```

使用方式：

```bash
claude-switch kiki830621    # 切換到 kiki830621 帳號
claude-switch work          # 切換到 work 帳號
claude-switch default       # 切換回預設帳號
```

## 安裝

```bash
/plugin install claude-switch@kiki830621/che-claude-plugins
```

## 版本歷史

- **v1.0.0** - 初始版本
  - 支援帳號列表、目前帳號、設定新帳號、切換帳號
  - 自動建立 IDE symlink 解決 VS Code 偵測問題
