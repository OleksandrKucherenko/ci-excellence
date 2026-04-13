#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Install Tools
# Purpose: Install required tools for the project
# Hooks: begin, install, end (automatic)
#   ci-cd/ci-10-install-tools/begin_*.sh   - pre-install setup
#   ci-cd/ci-10-install-tools/install_*.sh - tool install commands
#   ci-cd/ci-10-install-tools/end_*.sh     - post-install verification

echo:Setup "Installing Required Tools"
ci:secret setup "GITHUB_TOKEN" "${GITHUB_TOKEN:-}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

set +eu
hooks:declare install
hooks:do install
set -eu

echo:Success "Tool Installation Complete"
