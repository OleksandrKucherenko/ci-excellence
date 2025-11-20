#!/usr/bin/env bash
set -euo pipefail

# CI Script: Send Notification
# Purpose: Send notifications via Telegram

TITLE="${1:-CI/CD Pipeline}"
MESSAGE="${2:-Pipeline completed}"
TYPE="${3:-info}"

echo "=== CI Notification ==="
echo "Type: $TYPE"
echo "Title: $TITLE"
echo "Message: $MESSAGE"
echo ""

# Ensure required environment variables are set
if [ -z "${TELEGRAM_BOT_TOKEN:-}" ] || [ -z "${TELEGRAM_CHAT_ID:-}" ]; then
    echo "Error: TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID must be set"
    exit 1
fi

# Install mise and tools if not already available
if ! command -v mise &> /dev/null; then
    echo "Installing mise..."
    curl -fsSL https://mise.run | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

if ! command -v bun &> /dev/null; then
    echo "Installing bun via mise..."
    mise install bun
    eval "$(mise activate bash --shims)"
fi

echo "Tools ready:"
echo "  mise: $(mise --version)"
echo "  bun: $(bun --version)"
echo ""

# Make notification scripts executable
chmod +x scripts/notify/*.sh scripts/notify/*.ts

# Use the ci-notify.sh wrapper to send notification
echo "Sending notification to Telegram..."
case "$TYPE" in
    success)
        ./scripts/notify/ci-notify.sh success "$MESSAGE" "$TITLE"
        ;;
    failure)
        ./scripts/notify/ci-notify.sh failure "$MESSAGE" "$TITLE"
        ;;
    warning)
        ./scripts/notify/ci-notify.sh warning "$MESSAGE" "$TITLE"
        ;;
    info|*)
        ./scripts/notify/ci-notify.sh info "$MESSAGE" "$TITLE"
        ;;
esac

echo "✓ Notification sent successfully"
