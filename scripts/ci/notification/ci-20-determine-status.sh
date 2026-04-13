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
RUN_NUMBER="${GITHUB_RUN_NUMBER:-???}"
COMMIT_SHA="${GITHUB_SHA:-unknown}"
COMMIT_SHORT="${COMMIT_SHA:0:7}"
REF_NAME="${GITHUB_REF_NAME:-unknown}"
COMMIT_MSG=$(git log -1 --format='%s' "${COMMIT_SHA}" 2>/dev/null || echo "")

CONTEXT="Build: #${RUN_NUMBER}
Branch: ${REF_NAME}
Commit: ${COMMIT_SHORT}"
if [ -n "$COMMIT_MSG" ]; then
  CONTEXT="${CONTEXT}
Message: ${COMMIT_MSG}"
fi

if [ "$SUMMARY_RESULT" == "failure" ]; then
  ci:output notify "status" "failure"
  MESSAGE="Pre-Release Pipeline Failed

${CONTEXT}"
  ci:output:multiline notify "message" "$MESSAGE"
elif [ "$SUMMARY_RESULT" == "success" ]; then
  ci:output notify "status" "success"
  MESSAGE="Pre-Release Pipeline Passed

${CONTEXT}"
  ci:output:multiline notify "message" "$MESSAGE"
else
  ci:output notify "status" "warning"
  MESSAGE="Pre-Release Pipeline Completed with Issues

${CONTEXT}"
  ci:output:multiline notify "message" "$MESSAGE"
fi

echo:Success "Pipeline Status Determined"
