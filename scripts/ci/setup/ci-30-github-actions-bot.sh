#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Configure GitHub Actions Bot Identity
# Purpose: Set git user name and email for automated commits
# Hooks: begin, configure, end (automatic)
#   ci-cd/ci-30-github-actions-bot/begin_*.sh     - pre-configure setup
#   ci-cd/ci-30-github-actions-bot/configure_*.sh - git identity commands
#   ci-cd/ci-30-github-actions-bot/end_*.sh       - post-configure verification

echo:Setup "Set GitHub Username and Email for Bot"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

hooks:declare configure
hooks:do configure

echo:Success "GitHub Actions Bot Setup Completed"
