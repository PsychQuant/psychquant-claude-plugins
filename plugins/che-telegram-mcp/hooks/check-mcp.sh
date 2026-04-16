#!/bin/bash
# Session start check for che-telegram-mcp plugin

check_binary() {
    local name="$1" repo="$2" label="$3"
    local found=false
    for loc in "$HOME/bin/$name" "/usr/local/bin/$name" "$HOME/.local/bin/$name" "$HOME/Developer/che-mcps/$(echo "$repo" | cut -d/ -f2)/.build/release/$name"; do
        [[ -x "$loc" ]] && found=true && break
    done
    if [[ "$found" == "true" ]]; then
        echo "✓ $label installed: $loc"
    else
        echo "⚠️  $label not found"
        echo "   Build: git clone https://github.com/$repo.git && cd $(echo "$repo" | cut -d/ -f2) && swift build -c release"
    fi
}

check_keychain() {
    local account="$1" service="$2" label="$3"
    if security find-generic-password -a "$account" -s "$service" -w &>/dev/null; then
        echo "✓ $label in Keychain"
    else
        echo "⚠️  $label not in Keychain"
        echo "   Run: security add-generic-password -a $account -s $service -w 'VALUE' -U"
    fi
}

echo "── Telegram MCP Status ──"
check_binary "CheTelegramAllMCP" "PsychQuant/che-msg" "telegram-all (TDLib)"
check_keychain "che-telegram-all-mcp" "TELEGRAM_API_ID" "API ID"
check_keychain "che-telegram-all-mcp" "TELEGRAM_API_HASH" "API Hash"

check_binary "CheTelegramBotMCP" "PsychQuant/che-msg" "telegram-bot"
check_keychain "che-telegram-bot-mcp" "TELEGRAM_BOT_TOKEN" "Bot Token"
