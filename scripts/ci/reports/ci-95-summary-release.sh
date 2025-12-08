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
  echo ""
  echo "| Target | Status | Enabled |"
  echo "|--------|--------|---------|"
  echo "| NPM | $NPM_RESULT | $ENABLE_NPM_PUBLISH |"
  echo "| GitHub | $GITHUB_RESULT | $ENABLE_GITHUB_RELEASE |"
  echo "| Docker | $DOCKER_RESULT | $ENABLE_DOCKER_PUBLISH |"
  echo "| Documentation | $DOCS_RESULT | $ENABLE_DOCUMENTATION |"
} >> "${GITHUB_STEP_SUMMARY}"
