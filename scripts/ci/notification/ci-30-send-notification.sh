#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Send Notification
# Purpose: Send notifications to configured services using Apprise (tech-agnostic)

TITLE="${NOTIFY_TITLE:-CI/CD Pipeline}"
MESSAGE="${NOTIFY_MESSAGE:-Pipeline completed}"
TYPE="${NOTIFY_STATUS:-info}"  # info, success, warning, failure

echo:Notify "Sending Notification"
ci:param notify "NOTIFY_TITLE" "$TITLE"
ci:param notify "NOTIFY_MESSAGE" "$MESSAGE"
ci:param notify "NOTIFY_STATUS" "$TYPE"
ci:secret notify "APPRISE_URLS" "${APPRISE_URLS:-}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

# Check if Apprise is installed
if ! command -v apprise &> /dev/null; then
    echo:Notify "Installing Apprise..."
    pip3 install apprise || pip install apprise || {
        echo:Error "Failed to install Apprise"
        echo:Notify "  Notifications will be skipped"
        exit 0
    }
fi

# Get notification URLs from environment variable
NOTIFICATION_URLS="${APPRISE_URLS:-}"

if [ -z "$NOTIFICATION_URLS" ]; then
    echo:Error "No notification URLs configured"
    echo:Notify "  Set APPRISE_URLS secret. See: https://github.com/caronc/apprise/wiki"
    exit 0
fi

# Status emoji
case "$TYPE" in
    success)        TAG="✅" ;;
    failure|error)  TAG="❌" ;;
    warning)        TAG="⚠️" ;;
    *)              TAG="ℹ️" ;;
esac

# Build compact message: emoji + title + status details + run link + actor
REPO="${GITHUB_REPOSITORY:-}"
FULL_MESSAGE="${TAG} <b>${TITLE}</b>"

# Add repo as short name (no owner prefix if readable)
if [ -n "$REPO" ]; then
    FULL_MESSAGE="${FULL_MESSAGE} — ${REPO##*/}"
fi

# Status details from the calling script (branch, commit, etc.)
FULL_MESSAGE="${FULL_MESSAGE}

${MESSAGE}"

# Run link + actor on one footer line
FOOTER_PARTS=()
if [ -n "${GITHUB_RUN_ID:-}" ] && [ -n "${GITHUB_SERVER_URL:-}" ] && [ -n "$REPO" ]; then
    RUN_URL="${GITHUB_SERVER_URL}/${REPO}/actions/runs/${GITHUB_RUN_ID}"
    FOOTER_PARTS+=("<a href=\"${RUN_URL}\">Logs</a>")
fi
if [ -n "${GITHUB_ACTOR:-}" ]; then
    FOOTER_PARTS+=("by ${GITHUB_ACTOR}")
fi

if [ ${#FOOTER_PARTS[@]} -gt 0 ]; then
    FOOTER=$(IFS=' · '; echo "${FOOTER_PARTS[*]}")
    FULL_MESSAGE="${FULL_MESSAGE}

${FOOTER}"
fi

# Send the notification
echo:Notify "Sending notification to configured services..."

IFS=' ' read -ra URL_ARRAY <<< "$NOTIFICATION_URLS"

if apprise \
    --title="$TITLE" \
    --body="$FULL_MESSAGE" \
    --input-format=html \
    "${URL_ARRAY[@]}" 2>&1; then
    echo:Success "Notification sent successfully"
else
    echo:Error "Failed to send notification (non-fatal)"
    exit 0
fi

echo:Success "Notification Complete"
