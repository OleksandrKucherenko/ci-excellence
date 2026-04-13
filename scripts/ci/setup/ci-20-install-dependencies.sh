#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Install Dependencies
# Purpose: Install project dependencies
# Hooks: begin, install, end (automatic)
#   ci-cd/ci-20-install-dependencies/begin_*.sh   - pre-install setup
#   ci-cd/ci-20-install-dependencies/install_*.sh - install commands
#   ci-cd/ci-20-install-dependencies/end_*.sh     - post-install cleanup

echo:Setup "Installing Project Dependencies"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

set +eu
hooks:declare install
hooks:do install
set -eu

echo:Success "Dependency Installation Complete"
