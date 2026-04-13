#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Send Notification
# Purpose: Send notifications to configured services using Apprise (tech-agnostic)

TITLE="${1:-CI/CD Pipeline}"
MESSAGE="${2:-Pipeline completed}"
TYPE="${3:-info}"  # info, success, warning, failure

echo:Notify "Sending Notification"
ci:param notify "TITLE" "$TITLE"
ci:param notify "MESSAGE" "$MESSAGE"
ci:param notify "TYPE" "$TYPE"
ci:secret notify "APPRISE_URLS" "${APPRISE_URLS:-}"

# Check if Apprise is installed
if ! command -v apprise &> /dev/null; then
    echo:Notify "Installing Apprise..."
    pip3 install apprise || pip install apprise || {
        echo:Notify "⚠ Failed to install Apprise"
        echo:Notify "  Notifications will be skipped"
        exit 0
    }
fi

# Get notification URLs from environment variable
NOTIFICATION_URLS="${APPRISE_URLS:-}"

if [ -z "$NOTIFICATION_URLS" ]; then
    echo:Notify "⚠ No notification URLs configured"
    echo:Notify "  Set APPRISE_URLS environment variable or GitHub secret"
    echo:Notify "  Example formats:"
    echo:Notify "    Slack:    slack://token_a/token_b/token_c"
    echo:Notify "    Teams:    msteams://webhook_url"
    echo:Notify "    Discord:  discord://webhook_id/webhook_token"
    echo:Notify "    Telegram: tgram://bot_token/chat_id"
    echo:Notify "    Email:    mailto://user:pass@domain.com"
    echo:Notify ""
    echo:Notify "  Multiple services: separate with spaces"
    echo:Notify "  See: https://github.com/caronc/apprise/wiki"
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
echo:Notify "Sending notification to configured services..."

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
    echo:Notify "✓ Notification sent successfully"
else
    echo:Notify "⚠ Failed to send notification (non-fatal)"
    exit 0
fi

echo:Notify "Notification Complete"
