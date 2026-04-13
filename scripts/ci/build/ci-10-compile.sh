#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Compile/Build
# Purpose: Compile or build the project
# Hooks: begin, compile, end (automatic)
#   ci-cd/ci-10-compile/begin_*.sh   - pre-compile setup
#   ci-cd/ci-10-compile/compile_*.sh - build commands
#   ci-cd/ci-10-compile/end_*.sh     - post-compile cleanup

echo:Build "Compiling/Building Project"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

set +eu
hooks:declare compile
hooks:do compile
set -eu

echo:Success "Build Complete"
