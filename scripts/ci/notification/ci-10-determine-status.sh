#!/usr/bin/env bash
set -euo pipefail

# CI Script: Determine Notification Status
# Purpose: Determine pipeline status for notifications with detailed context

SUMMARY_RESULT="${1:-unknown}"

# Get context information
RUN_NUMBER="${GITHUB_RUN_NUMBER:-???}"
COMMIT_SHA="${GITHUB_SHA:-unknown}"
COMMIT_SHORT="${COMMIT_SHA:0:7}"
REF_NAME="${GITHUB_REF_NAME:-unknown}"

if [ "$SUMMARY_RESULT" == "failure" ]; then
  echo "status=failure" >> $GITHUB_OUTPUT
  {
    echo "message<<EOF_MESSAGE"
    echo "Pre-Release Pipeline Failed"
    echo ""
    echo "Build: #${RUN_NUMBER}"
    echo "Branch: ${REF_NAME}"
    echo "Commit: ${COMMIT_SHORT}"
    echo "EOF_MESSAGE"
  } >> $GITHUB_OUTPUT
elif [ "$SUMMARY_RESULT" == "success" ]; then
  echo "status=success" >> $GITHUB_OUTPUT
  {
    echo "message<<EOF_MESSAGE"
    echo "Pre-Release Pipeline Passed"
    echo ""
    echo "Build: #${RUN_NUMBER}"
    echo "Branch: ${REF_NAME}"
    echo "Commit: ${COMMIT_SHORT}"
    echo "EOF_MESSAGE"
  } >> $GITHUB_OUTPUT
else
  echo "status=warning" >> $GITHUB_OUTPUT
  {
    echo "message<<EOF_MESSAGE"
    echo "Pre-Release Pipeline Completed with Issues"
    echo ""
    echo "Build: #${RUN_NUMBER}"
    echo "Branch: ${REF_NAME}"
    echo "Commit: ${COMMIT_SHORT}"
    echo "EOF_MESSAGE"
  } >> $GITHUB_OUTPUT
fi
