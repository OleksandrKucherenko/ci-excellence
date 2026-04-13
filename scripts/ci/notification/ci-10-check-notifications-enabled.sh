#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Check if Notifications Should Be Enabled
# Purpose: Auto-detect if notification secrets are available and not explicitly disabled
#
# Logic:
# 1. If APPRISE_URLS is available -> use it directly
# 2. If TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID are available -> convert to Apprise format
# 3. If ENABLE_NOTIFICATIONS is explicitly false -> force disable
# 4. Otherwise, enable notifications if secrets are available
#
# Returns: "enabled" (true/false) and "apprise_urls" outputs for GitHub Actions

# Function to check if a value is "false-like"
is_false() {
    local value="${1:-}"
    # Normalize to lowercase for comparison
    local normalized=$(echo "$value" | tr '[:upper:]' '[:lower:]')

    case "$normalized" in
        false|no|n|0|off|disabled)
            return 0  # Is false
            ;;
        *)
            return 1  # Not false
            ;;
    esac
}

# Check available notification credentials
APPRISE_URLS="${APPRISE_URLS:-}"
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"
ENABLE_NOTIFICATIONS="${ENABLE_NOTIFICATIONS:-}"

echo:Notify "Checking Notification Configuration"
ci:secret notify "APPRISE_URLS" "$APPRISE_URLS"
ci:secret notify "TELEGRAM_BOT_TOKEN" "$TELEGRAM_BOT_TOKEN"
ci:param notify "TELEGRAM_CHAT_ID" "$TELEGRAM_CHAT_ID"
ci:param notify "ENABLE_NOTIFICATIONS" "$ENABLE_NOTIFICATIONS"

# Check if explicitly disabled
if [ -n "$ENABLE_NOTIFICATIONS" ] && is_false "$ENABLE_NOTIFICATIONS"; then
    echo:Notify "Notifications explicitly disabled via ENABLE_NOTIFICATIONS=$ENABLE_NOTIFICATIONS"
    ci:output notify "enabled" "false"
    echo:Notify "Notification Check Complete"
    exit 0
fi

# Determine which notification URLs to use
FINAL_URLS=""

if [ -n "$APPRISE_URLS" ]; then
    # Use Apprise URLs directly
    FINAL_URLS="$APPRISE_URLS"
    echo:Notify "✓ Using APPRISE_URLS for notifications"
elif [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
    # Convert Telegram credentials to Apprise format with HTML formatting
    FINAL_URLS="tgram://${TELEGRAM_BOT_TOKEN}/${TELEGRAM_CHAT_ID}?format=html"
    echo:Notify "✓ Converting Telegram credentials to Apprise format (HTML mode)"
fi

# Check if we have any notification URLs
if [ -n "$FINAL_URLS" ]; then
    echo:Notify "✓ Notifications enabled"
    ci:output notify "enabled" "true"
    echo "apprise_urls=$FINAL_URLS" >> "$GITHUB_OUTPUT"
    ci:secret notify "apprise_urls (output)" "$FINAL_URLS"
    echo:Notify "Notification Check Complete"
    exit 0
else
    echo:Notify "✗ No notification credentials available"
    echo:Notify "  Set either:"
    echo:Notify "    - APPRISE_URLS (supports 90+ services)"
    echo:Notify "    - TELEGRAM_BOT_TOKEN + TELEGRAM_CHAT_ID (Telegram only)"
    ci:output notify "enabled" "false"
    echo:Notify "Notification Check Complete"
    exit 0
fi
