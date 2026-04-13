#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Parse Tag
# Purpose: Parse git tag and extract version and prerelease status
# Hooks: begin, parse, end (automatic)
#   ci-cd/ci-09-parse-tag/begin_*.sh - pre-parse setup
#   ci-cd/ci-09-parse-tag/parse_*.sh - tag parsing commands
#   ci-cd/ci-09-parse-tag/end_*.sh   - post-parse verification

echo:Release "Parse Tag"
ci:param release "CI_GIT_REF" "${CI_GIT_REF:?CI_GIT_REF is required}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

ci:skip_if_no_hooks parse

set +eu
hooks:declare parse
hooks:do parse
set -eu

echo:Success "Parse Tag Done"
