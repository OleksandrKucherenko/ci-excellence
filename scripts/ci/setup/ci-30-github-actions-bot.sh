#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Configure GitHub Actions Bot Identity
# Purpose: Set git user name and email for automated commits
# Hooks: begin, configure, end (automatic)
#   ci-cd/ci-30-github-actions-bot/configure_*.sh - override bot identity
#
# Default strategy: github-actions[bot] identity.

echo:Setup "Set GitHub Username and Email for Bot"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

if ci:has_hooks configure; then
  set +eu
  hooks:declare configure
  hooks:do configure
  set -eu
else
  # Default: standard GitHub Actions bot identity
  git config user.name "github-actions[bot]"
  git config user.email "github-actions[bot]@users.noreply.github.com"
  echo:Setup "  Name: $(git config user.name)"
  echo:Setup "  Email: $(git config user.email)"
fi

echo:Success "GitHub Actions Bot Setup Completed"
