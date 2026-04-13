#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Pipeline Stub: Cleanup Old Artifacts
# Purpose: Delete old GitHub Actions artifacts

echo:Maint "Cleaning Up Old Artifacts"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

# Example: Delete artifacts older than 7 days using gh CLI
# if command -v gh &> /dev/null; then
#     RETENTION_DAYS=${RETENTION_DAYS:-7}  # Default to 7 days if not set
#
#     echo "Deleting artifacts older than $RETENTION_DAYS days..."
#
#     gh api repos/:owner/:repo/actions/artifacts \
#         --paginate \
#         --jq ".artifacts[] | select(.created_at < (now - ($RETENTION_DAYS * 86400))) | .id" | \
#     while read -r artifact_id; do
#         echo "Deleting artifact $artifact_id..."
#         gh api -X DELETE "repos/:owner/:repo/actions/artifacts/$artifact_id" || true
#     done
# fi


echo:Success "Artifacts Cleanup Complete"
