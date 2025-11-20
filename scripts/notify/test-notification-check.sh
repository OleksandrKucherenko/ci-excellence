#!/usr/bin/env bash
set -euo pipefail

# Test script for notification auto-detection logic
# This simulates the check-notifications-enabled.sh behavior locally

echo "=== Testing Notification Auto-Detection ==="
echo ""

# Function to check if a value is "false-like"
is_false() {
    local value="${1:-}"
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

# Test cases
test_case() {
    local test_name="$1"
    local bot_token="$2"
    local chat_id="$3"
    local enable_flag="$4"
    local expected="$5"

    echo "Test: $test_name"
    echo "  TELEGRAM_BOT_TOKEN: $([ -n "$bot_token" ] && echo 'SET' || echo 'NOT SET')"
    echo "  TELEGRAM_CHAT_ID: $([ -n "$chat_id" ] && echo 'SET' || echo 'NOT SET')"
    echo "  ENABLE_NOTIFICATIONS: ${enable_flag:-'not set'}"

    local result="disabled"

    # Check if explicitly disabled
    if [ -n "$enable_flag" ] && is_false "$enable_flag"; then
        result="disabled (explicit)"
    # Check if secrets are available
    elif [ -n "$bot_token" ] && [ -n "$chat_id" ]; then
        result="enabled (auto-detected)"
    else
        result="disabled (missing secrets)"
    fi

    echo "  Result: $result"
    echo "  Expected: $expected"

    if [[ "$result" == *"$expected"* ]]; then
        echo "  ✓ PASS"
    else
        echo "  ✗ FAIL"
    fi
    echo ""
}

# Run test cases
echo "Running test cases..."
echo ""

test_case "Both secrets set, no flag" \
    "123456:ABC" \
    "987654321" \
    "" \
    "enabled"

test_case "Both secrets set, flag=false" \
    "123456:ABC" \
    "987654321" \
    "false" \
    "disabled"

test_case "Both secrets set, flag=False" \
    "123456:ABC" \
    "987654321" \
    "False" \
    "disabled"

test_case "Both secrets set, flag=FALSE" \
    "123456:ABC" \
    "987654321" \
    "FALSE" \
    "disabled"

test_case "Both secrets set, flag=no" \
    "123456:ABC" \
    "987654321" \
    "no" \
    "disabled"

test_case "Both secrets set, flag=No" \
    "123456:ABC" \
    "987654321" \
    "No" \
    "disabled"

test_case "Both secrets set, flag=NO" \
    "123456:ABC" \
    "987654321" \
    "NO" \
    "disabled"

test_case "Both secrets set, flag=0" \
    "123456:ABC" \
    "987654321" \
    "0" \
    "disabled"

test_case "Both secrets set, flag=off" \
    "123456:ABC" \
    "987654321" \
    "off" \
    "disabled"

test_case "Both secrets set, flag=true" \
    "123456:ABC" \
    "987654321" \
    "true" \
    "enabled"

test_case "Missing bot token" \
    "" \
    "987654321" \
    "" \
    "disabled"

test_case "Missing chat ID" \
    "123456:ABC" \
    "" \
    "" \
    "disabled"

test_case "Both secrets missing" \
    "" \
    "" \
    "" \
    "disabled"

test_case "Both secrets missing, flag=true" \
    "" \
    "" \
    "true" \
    "disabled"

echo "=== Test Complete ==="
