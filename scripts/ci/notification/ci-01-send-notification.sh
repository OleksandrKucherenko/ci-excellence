#!/usr/bin/env bash
set -euo pipefail

# CI Script: Send Notification
# Purpose: Send notifications via Apprise

TITLE="${1:-CI/CD Pipeline}"
MESSAGE="${2:-Pipeline completed}"
TYPE="${3:-info}"

echo "Making setup scripts executable..."
chmod +x scripts/setup/*.sh

echo "Sending notification: $TYPE - $TITLE"
./scripts/setup/send-notification.sh "$TITLE" "$MESSAGE" "$TYPE"
