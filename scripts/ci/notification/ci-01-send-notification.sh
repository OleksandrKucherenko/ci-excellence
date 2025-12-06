#!/usr/bin/env bash
set -euo pipefail

# CI Script: Send Notification
# Purpose: Send notifications to configured services using Apprise (tech-agnostic)

TITLE="${1:-CI/CD Pipeline}"
MESSAGE="${2:-Pipeline completed}"
TYPE="${3:-info}"  # info, success, warning, failure

echo "========================================="
echo "Sending Notification"
echo "========================================="

# Check if Apprise is installed
if ! command -v apprise &> /dev/null; then
    echo "Installing Apprise..."
    pip3 install apprise || pip install apprise || {
        echo "⚠ Failed to install Apprise"
        echo "  Notifications will be skipped"
        exit 0
    }
fi

# Get notification URLs from environment variable
NOTIFICATION_URLS="${APPRISE_URLS:-}"

if [ -z "$NOTIFICATION_URLS" ]; then
    echo "⚠ No notification URLs configured"
    echo "  Set APPRISE_URLS environment variable or GitHub secret"
    echo "  Example formats:"
    echo "    Slack:    slack://token_a/token_b/token_c"
    echo "    Teams:    msteams://webhook_url"
    echo "    Discord:  discord://webhook_id/webhook_token"
    echo "    Telegram: tgram://bot_token/chat_id"
    echo "    Email:    mailto://user:pass@domain.com"
    echo ""
    echo "  Multiple services: separate with spaces"
    echo "  See: https://github.com/caronc/apprise/wiki"
    exit 0
fi

# Determine notification tag based on type
TAG="info"
case "$TYPE" in
    success)
        TAG="✅"
        ;;
    failure|error)
        TAG="❌"
        ;;
    warning)
        TAG="⚠️"
        ;;
    info)
        TAG="ℹ️"
        ;;
esac

# Build the full notification message with HTML formatting for Telegram
# Note: Each HTML tag must open and close on the same line
FULL_MESSAGE="$TAG <b>${TITLE}</b>

${MESSAGE}"

# Add repository and workflow information if available
if [ -n "${GITHUB_REPOSITORY:-}" ]; then
    FULL_MESSAGE="${FULL_MESSAGE}

<b>Repository:</b> ${GITHUB_REPOSITORY}"
fi

if [ -n "${GITHUB_WORKFLOW:-}" ]; then
    FULL_MESSAGE="${FULL_MESSAGE}
<b>Workflow:</b> ${GITHUB_WORKFLOW}"
fi

if [ -n "${GITHUB_RUN_ID:-}" ] && [ -n "${GITHUB_SERVER_URL:-}" ] && [ -n "${GITHUB_REPOSITORY:-}" ]; then
    RUN_URL="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"
    FULL_MESSAGE="${FULL_MESSAGE}
<b>Run:</b> <a href=\"${RUN_URL}\">View Logs</a>"
fi

if [ -n "${GITHUB_ACTOR:-}" ]; then
    FULL_MESSAGE="${FULL_MESSAGE}
<b>Triggered by:</b> ${GITHUB_ACTOR}"
fi

# Send notification using Apprise
echo "Sending notification to configured services..."

# Convert space-separated URLs to individual arguments
IFS=' ' read -ra URL_ARRAY <<< "$NOTIFICATION_URLS"

# Build apprise command
APPRISE_ARGS=()
for url in "${URL_ARRAY[@]}"; do
    APPRISE_ARGS+=("$url")
done

# Send the notification
if apprise \
    --title="$TITLE" \
    --body="$FULL_MESSAGE" \
    --input-format=html \
    --tag="$TYPE" \
    "${APPRISE_ARGS[@]}" 2>&1; then
    echo "✓ Notification sent successfully"
else
    echo "⚠ Failed to send notification (non-fatal)"
    exit 0
fi

echo "========================================="
echo "Notification Complete"
echo "========================================="
