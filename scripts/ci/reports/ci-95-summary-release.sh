#!/usr/bin/env bash
set -euo pipefail

# CI Script: Release Summary
# Purpose: Generate release summary table

VERSION="${1:-unknown}"
IS_PRERELEASE="${2:-false}"
NPM_RESULT="${3:-unknown}"
GITHUB_RESULT="${4:-unknown}"
DOCKER_RESULT="${5:-unknown}"
DOCS_RESULT="${6:-unknown}"

ENABLE_NPM_PUBLISH="${ENABLE_NPM_PUBLISH:-false}"
ENABLE_GITHUB_RELEASE="${ENABLE_GITHUB_RELEASE:-false}"
ENABLE_DOCKER_PUBLISH="${ENABLE_DOCKER_PUBLISH:-false}"
ENABLE_DOCUMENTATION="${ENABLE_DOCUMENTATION:-false}"

{
  echo "## Release Summary"
  echo ""
  echo "**Version:** $VERSION"
  echo "**Pre-release:** $IS_PRERELEASE"
  echo "**Commit:** ${GITHUB_SHA::7}"
  echo ""
  echo "| Target | Status | Enabled |"
  echo "|--------|--------|---------|"
  echo "| NPM | $NPM_RESULT | $ENABLE_NPM_PUBLISH |"
  echo "| GitHub | $GITHUB_RESULT | $ENABLE_GITHUB_RELEASE |"
  echo "| Docker | $DOCKER_RESULT | $ENABLE_DOCKER_PUBLISH |"
  echo "| Documentation | $DOCS_RESULT | $ENABLE_DOCUMENTATION |"
  echo ""
  echo "### 🚀 One-click Ops Actions"
  echo ""
  echo "Run these commands locally to manage this release:"
  echo ""
  echo "<details>"
  echo "<summary>Promote Release</summary>"
  echo ""
  echo "\`\`\`bash"
  echo "gh workflow run ops.yml -f action=promote-release -f version=$VERSION"
  echo "\`\`\`"
  echo "</details>"
  echo ""
  echo "<details>"
  echo "<summary>Deploy to Staging</summary>"
  echo ""
  echo "\`\`\`bash"
  echo "gh workflow run ops.yml -f action=deploy-staging -f version=$VERSION"
  echo "\`\`\`"
  echo "</details>"
  echo ""
  echo "<details>"
  echo "<summary>Deploy to Production</summary>"
  echo ""
  echo "\`\`\`bash"
  echo "gh workflow run ops.yml -f action=deploy-production -f version=$VERSION -f confirm=yes"
  echo "\`\`\`"
  echo "</details>"
  echo ""
  echo "<details>"
  echo "<summary>Mark as Stable</summary>"
  echo ""
  echo "\`\`\`bash"
  echo "gh workflow run ops.yml -f action=mark-stable -f version=$VERSION"
  echo "\`\`\`"
  echo "</details>"
} >> "${GITHUB_STEP_SUMMARY}"

# Post/Update PR comment (Requires finding PR associated with commit)
# This is a placeholder for logic that would use 'gh pr comment' if a PR number is found.
# PR_NUMBER=$(gh pr list --state open --head "${GITHUB_REF_NAME}" --json number --jq '.[0].number')
# if [ -n "$PR_NUMBER" ]; then
#   gh pr comment "$PR_NUMBER" --body "Release $VERSION summary..."
# fi
