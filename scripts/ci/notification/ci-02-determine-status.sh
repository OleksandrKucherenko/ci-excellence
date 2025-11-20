#!/usr/bin/env bash
set -euo pipefail

# CI Script: Determine Notification Status
# Purpose: Determine pipeline status for notifications with detailed context

SUMMARY_RESULT="${1:-unknown}"

# Build comprehensive message with context
REPO="${GITHUB_REPOSITORY:-repository}"
RUN_ID="${GITHUB_RUN_ID:-unknown}"
RUN_NUMBER="${GITHUB_RUN_NUMBER:-#???}"
COMMIT_SHA="${GITHUB_SHA:-unknown}"
COMMIT_SHORT="${GITHUB_SHA:0:7}"
REF_NAME="${GITHUB_REF_NAME:-branch}"
ACTOR="${GITHUB_ACTOR:-user}"
RUN_URL="${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY:-repo}/actions/runs/${GITHUB_RUN_ID:-0}"

if [ "$SUMMARY_RESULT" == "failure" ]; then
  echo "status=failure" >> $GITHUB_OUTPUT
  {
    echo "message<<EOF_MESSAGE"
    echo "❌ Pre-Release Pipeline Failed"
    echo ""
    echo "**Build:** #${RUN_NUMBER}"
    echo "**Branch:** \`${REF_NAME}\`"
    echo "**Commit:** \`${COMMIT_SHORT}\`"
    echo "**Triggered by:** ${ACTOR}"
    echo ""
    echo "[View Logs](${RUN_URL})"
    echo "EOF_MESSAGE"
  } >> $GITHUB_OUTPUT
elif [ "$SUMMARY_RESULT" == "success" ]; then
  echo "status=success" >> $GITHUB_OUTPUT
  {
    echo "message<<EOF_MESSAGE"
    echo "✅ Pre-Release Pipeline Passed"
    echo ""
    echo "**Build:** #${RUN_NUMBER}"
    echo "**Branch:** \`${REF_NAME}\`"
    echo "**Commit:** \`${COMMIT_SHORT}\`"
    echo "**Triggered by:** ${ACTOR}"
    echo ""
    echo "[View Logs](${RUN_URL})"
    echo "EOF_MESSAGE"
  } >> $GITHUB_OUTPUT
else
  echo "status=warning" >> $GITHUB_OUTPUT
  {
    echo "message<<EOF_MESSAGE"
    echo "⚠️ Pre-Release Pipeline Completed with Issues"
    echo ""
    echo "**Build:** #${RUN_NUMBER}"
    echo "**Branch:** \`${REF_NAME}\`"
    echo "**Commit:** \`${COMMIT_SHORT}\`"
    echo "**Triggered by:** ${ACTOR}"
    echo ""
    echo "[View Logs](${RUN_URL})"
    echo "EOF_MESSAGE"
  } >> $GITHUB_OUTPUT
fi
