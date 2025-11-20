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
  cat >> $GITHUB_OUTPUT <<EOF
message=❌ Pre-Release Pipeline Failed

**Build:** #${RUN_NUMBER}
**Branch:** \`${REF_NAME}\`
**Commit:** \`${COMMIT_SHORT}\`
**Triggered by:** ${ACTOR}

[View Logs](${RUN_URL})
EOF
elif [ "$SUMMARY_RESULT" == "success" ]; then
  echo "status=success" >> $GITHUB_OUTPUT
  cat >> $GITHUB_OUTPUT <<EOF
message=✅ Pre-Release Pipeline Passed

**Build:** #${RUN_NUMBER}
**Branch:** \`${REF_NAME}\`
**Commit:** \`${COMMIT_SHORT}\`
**Triggered by:** ${ACTOR}

[View Logs](${RUN_URL})
EOF
else
  echo "status=warning" >> $GITHUB_OUTPUT
  cat >> $GITHUB_OUTPUT <<EOF
message=⚠️ Pre-Release Pipeline Completed with Issues

**Build:** #${RUN_NUMBER}
**Branch:** \`${REF_NAME}\`
**Commit:** \`${COMMIT_SHORT}\`
**Triggered by:** ${ACTOR}

[View Logs](${RUN_URL})
EOF
fi
