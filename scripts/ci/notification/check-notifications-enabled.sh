#!/usr/bin/env bash
set -euo pipefail

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

# Debug output (will appear in GitHub Actions logs)
echo "Checking notification requirements..."
echo "APPRISE_URLS: $([ -n "$APPRISE_URLS" ] && echo 'SET' || echo 'NOT SET')"
echo "TELEGRAM_BOT_TOKEN: $([ -n "$TELEGRAM_BOT_TOKEN" ] && echo 'SET' || echo 'NOT SET')"
echo "TELEGRAM_CHAT_ID: $([ -n "$TELEGRAM_CHAT_ID" ] && echo 'SET' || echo 'NOT SET')"
echo "ENABLE_NOTIFICATIONS: ${ENABLE_NOTIFICATIONS:-'not set'}"

# Check if explicitly disabled
if [ -n "$ENABLE_NOTIFICATIONS" ] && is_false "$ENABLE_NOTIFICATIONS"; then
    echo "Notifications explicitly disabled via ENABLE_NOTIFICATIONS=$ENABLE_NOTIFICATIONS"
    echo "enabled=false" >> $GITHUB_OUTPUT
    exit 0
fi

# Determine which notification URLs to use
FINAL_URLS=""

if [ -n "$APPRISE_URLS" ]; then
    # Use Apprise URLs directly
    FINAL_URLS="$APPRISE_URLS"
    echo "✓ Using APPRISE_URLS for notifications"
elif [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
    # Convert Telegram credentials to Apprise format
    FINAL_URLS="tgram://${TELEGRAM_BOT_TOKEN}/${TELEGRAM_CHAT_ID}"
    echo "✓ Converting Telegram credentials to Apprise format"
fi

# Check if we have any notification URLs
if [ -n "$FINAL_URLS" ]; then
    echo "✓ Notifications enabled"
    echo "enabled=true" >> $GITHUB_OUTPUT
    echo "apprise_urls=$FINAL_URLS" >> $GITHUB_OUTPUT
    exit 0
else
    echo "✗ No notification credentials available"
    echo "  Set either:"
    echo "    - APPRISE_URLS (supports 90+ services)"
    echo "    - TELEGRAM_BOT_TOKEN + TELEGRAM_CHAT_ID (Telegram only)"
    echo "enabled=false" >> $GITHUB_OUTPUT
    exit 0
fi
