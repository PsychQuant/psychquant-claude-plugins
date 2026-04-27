#!/bin/bash
# SessionStart check for che-telegram-mcp plugin
#
# Verifies binaries + Keychain entries needed by the two bundled MCP servers
# (telegram-all and telegram-bot). Output mirrors what the wrappers will look
# for at runtime, so a green checkmark here means the wrapper will succeed.
#
# Note: this hook does NOT read disabledMcpjsonServers from settings.json. If
# you've intentionally disabled one server, ignore its warnings (the footer
# note explains how).

# Search locations — MUST match the wrapper's `for loc in ...` list.
# See bin/che-telegram-{all,bot}-mcp-wrapper.sh.
check_binary() {
    local name="$1" pkg_dir="$2" label="$3"
    local found=""
    # Order matters: prefer installed binary > source build (matches wrapper).
    for loc in \
        "$HOME/bin/$name" \
        "/usr/local/bin/$name" \
        "$HOME/.local/bin/$name" \
        "$HOME/Developer/che-msg/$pkg_dir/.build/release/$name" \
        "$HOME/Developer/che-mcps/$pkg_dir/.build/release/$name"; do
        if [[ -x "$loc" ]]; then
            found="$loc"
            break
        fi
    done
    if [[ -n "$found" ]]; then
        echo "✓ $label installed: $found"
    else
        echo "⚠️  $label not found"
        echo "   Wrappers will auto-download on first invocation, or build manually:"
        echo "     git clone https://github.com/PsychQuant/che-msg.git ~/Developer/che-msg"
        echo "     cd ~/Developer/che-msg/$pkg_dir && swift build -c release --product $name"
    fi
}

check_keychain_required() {
    local account="$1" service="$2" label="$3"
    if security find-generic-password -a "$account" -s "$service" -w &>/dev/null; then
        echo "✓ $label in Keychain"
    else
        echo "⚠️  $label not in Keychain"
        echo "   security add-generic-password -a $account -s $service -w 'VALUE' -U"
    fi
}

check_keychain_optional() {
    local account="$1" service="$2" label="$3"
    if security find-generic-password -a "$account" -s "$service" -w &>/dev/null; then
        echo "✓ $label in Keychain (optional)"
    fi
    # Silent when missing — optional creds shouldn't generate warnings.
}

echo "── Telegram MCP Status ──"

# telegram-all: personal account via TDLib
check_binary "CheTelegramAllMCP" "che-telegram-all-mcp" "telegram-all (TDLib)"
check_keychain_required "che-telegram-all-mcp" "TELEGRAM_API_ID" "API ID"
check_keychain_required "che-telegram-all-mcp" "TELEGRAM_API_HASH" "API Hash"
check_keychain_optional "che-telegram-all-mcp" "TELEGRAM_PHONE" "Phone (auto-fire)"
check_keychain_optional "che-telegram-all-mcp" "TELEGRAM_2FA_PASSWORD" "2FA password (auto-fire)"

# telegram-bot: bot account via Bot API
check_binary "CheTelegramBotMCP" "che-telegram-bot-mcp" "telegram-bot"
check_keychain_required "che-telegram-bot-mcp" "TELEGRAM_BOT_TOKEN" "Bot Token"

# Footer: how to silence warnings for a server you don't use.
echo "ℹ  Using only one server? Add the other to disabledMcpjsonServers in"
echo "    ~/.claude/settings.json or .claude/settings.json (project), e.g."
echo "    {\"disabledMcpjsonServers\": [\"telegram-bot\"]}  ← suppresses bot."
