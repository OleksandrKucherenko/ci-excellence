#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Determine Notification Status
# Purpose: Determine pipeline status for notifications with detailed context

echo:Notify "Determining Pipeline Status"

SUMMARY_RESULT="${RESULT_SUMMARY:-unknown}"

ci:param notify "RESULT_SUMMARY" "$SUMMARY_RESULT"
ci:param notify "GITHUB_RUN_NUMBER" "${GITHUB_RUN_NUMBER:-}"
ci:param notify "GITHUB_SHA" "${GITHUB_SHA:-}"
ci:param notify "GITHUB_REF_NAME" "${GITHUB_REF_NAME:-}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

# Get context information
COMMIT_SHA="${GITHUB_SHA:-unknown}"
COMMIT_MSG=$(git log -1 --format='%s' "${COMMIT_SHA}" 2>/dev/null || echo "")

# Build message — just context, no pipeline name (TITLE handles that)
MESSAGE="<b>Branch:</b> ${GITHUB_REF_NAME:-unknown}
<b>Commit:</b> <code>${COMMIT_SHA:0:7}</code> ${COMMIT_MSG}"

if [ "$SUMMARY_RESULT" == "failure" ]; then
  ci:output notify "status" "failure"
elif [ "$SUMMARY_RESULT" == "success" ]; then
  ci:output notify "status" "success"
else
  ci:output notify "status" "warning"
fi

ci:output:multiline notify "message" "$MESSAGE"

echo:Success "Pipeline Status Determined"
