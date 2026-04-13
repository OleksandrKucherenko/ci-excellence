#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Pipeline Stub: Cleanup Old Workflow Runs
# Purpose: Delete old GitHub Actions workflow runs

echo:Maint "Cleaning Up Old Workflow Runs"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

# Example: Delete workflow runs older than 30 days using gh CLI
# if command -v gh &> /dev/null; then
#     RETENTION_DAYS=30
#     CUTOFF_DATE=$(date -d "$RETENTION_DAYS days ago" +%Y-%m-%d)
#
#     echo "Deleting workflow runs older than $CUTOFF_DATE..."
#
#     gh run list --limit 1000 --json databaseId,createdAt \
#         --jq ".[] | select(.createdAt < \"$CUTOFF_DATE\") | .databaseId" | \
#     while read -r run_id; do
#         echo "Deleting run $run_id..."
#         gh run delete "$run_id" || true
#     done
# fi


echo:Success "Workflow Runs Cleanup Complete"
