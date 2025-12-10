#!/bin/bash
#
# Quick Test Script for Telegram Notifications
#
# This script tests the notification system with your Telegram bot.
# Run this locally (not in sandboxed CI environment) to verify it works.
#
# Usage:
#   ./scripts/notify/test-telegram.sh
#

set -e

echo "🧪 Testing Telegram Notification System"
echo "========================================"
echo ""

# Check if credentials are set in environment
if [ -z "${TELEGRAM_BOT_TOKEN:-}" ] || [ -z "${TELEGRAM_CHAT_ID:-}" ]; then
    echo "❌ Error: Required environment variables not set"
    echo ""
    echo "Please set your Telegram bot credentials:"
    echo "  export TELEGRAM_BOT_TOKEN='your-bot-token'"
    echo "  export TELEGRAM_CHAT_ID='your-chat-id'"
    echo ""
    echo "Or load from secrets file:"
    echo "  source <(mise exec -- sops -d .env.secrets.json | jq -r 'to_entries | .[] | \"export \\(.key)=\\(.value)\"')"
    exit 1
fi

echo "✓ Bot Token: ${TELEGRAM_BOT_TOKEN:0:20}..."
echo "✓ Chat ID: ${TELEGRAM_CHAT_ID}"
echo ""

# Test 1: Simple notification
echo "📤 Test 1: Sending simple notification..."
bun scripts/notify/telegram.ts \
  --new-thread \
  --title "Test Notification" \
  --body "Hello from CI Excellence! 🚀 This is a test of the notification system." \
  --type info

echo ""
sleep 2

# Test 2: Thread conversation
echo "📤 Test 2: Starting thread conversation..."
bun scripts/notify/telegram.ts \
  --new-thread \
  --title "Build #Test-001" \
  --body "Starting CI pipeline test..." \
  --type info

sleep 2

echo "📤 Test 3: Continuing thread..."
bun scripts/notify/telegram.ts \
  --thread \
  --body "Running tests... 🧪" \
  --type info

sleep 2

echo "📤 Test 4: Success message in thread..."
bun scripts/notify/telegram.ts \
  --thread \
  --body "All tests passed! ✅" \
  --type success

sleep 2

echo "📤 Test 5: Final message..."
bun scripts/notify/telegram.ts \
  --thread \
  --title "Build Complete" \
  --body "Build completed successfully in 0.5s" \
  --type success

echo ""
echo "✅ All tests completed!"
echo ""
echo "Check your Telegram chat with @v001TestTelegramBot"
echo "You should see two message threads:"
echo "  1. A simple test message"
echo "  2. A conversation thread showing build progress"
echo ""
