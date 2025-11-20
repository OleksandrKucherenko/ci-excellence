#!/usr/bin/env bash
set -euo pipefail

# CI Script: Check if Notifications Should Be Enabled
# Purpose: Auto-detect if notification secrets are available and not explicitly disabled
#
# Logic:
# 1. If TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID are both available -> notifications can be enabled
# 2. If ENABLE_NOTIFICATIONS is explicitly false (false, False, FALSE, no, No, NO, 0) -> force disable
# 3. Otherwise, enable notifications if secrets are available
#
# Returns: "true" or "false" (as string for GitHub Actions)

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

# Check if required secrets are available
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"

# Check explicit enable/disable flag
ENABLE_NOTIFICATIONS="${ENABLE_NOTIFICATIONS:-}"

# Debug output (will appear in GitHub Actions logs)
echo "Checking notification requirements..."
echo "TELEGRAM_BOT_TOKEN: $([ -n "$TELEGRAM_BOT_TOKEN" ] && echo 'SET' || echo 'NOT SET')"
echo "TELEGRAM_CHAT_ID: $([ -n "$TELEGRAM_CHAT_ID" ] && echo 'SET' || echo 'NOT SET')"
echo "ENABLE_NOTIFICATIONS: ${ENABLE_NOTIFICATIONS:-'not set'}"

# Check if explicitly disabled
if [ -n "$ENABLE_NOTIFICATIONS" ] && is_false "$ENABLE_NOTIFICATIONS"; then
    echo "Notifications explicitly disabled via ENABLE_NOTIFICATIONS=$ENABLE_NOTIFICATIONS"
    echo "enabled=false" >> $GITHUB_OUTPUT
    echo "false"
    exit 0
fi

# Check if secrets are available
if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
    echo "✓ Notification secrets available - notifications enabled"
    echo "enabled=true" >> $GITHUB_OUTPUT
    echo "true"
    exit 0
else
    echo "✗ Required secrets missing - notifications disabled"
    if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
        echo "  Missing: TELEGRAM_BOT_TOKEN"
    fi
    if [ -z "$TELEGRAM_CHAT_ID" ]; then
        echo "  Missing: TELEGRAM_CHAT_ID"
    fi
    echo "enabled=false" >> $GITHUB_OUTPUT
    echo "false"
    exit 0
fi
