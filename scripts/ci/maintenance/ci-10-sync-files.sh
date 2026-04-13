#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Sync Files
# Purpose: Synchronize version files
# Hooks: begin, sync, end (automatic)
#   ci-cd/ci-10-sync-files/begin_*.sh - pre-sync setup
#   ci-cd/ci-10-sync-files/sync_*.sh  - file sync commands
#   ci-cd/ci-10-sync-files/end_*.sh   - post-sync verification

echo:Maint "Synchronizing Version Files"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

set +eu
hooks:declare sync
hooks:do sync
set -eu

echo:Success "Version Files Synchronization Complete"
