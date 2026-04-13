#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

echo:Maint "Test After Update"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

echo:Maint "Running tests after dependency update..."
./scripts/ci/test/ci-10-unit-tests.sh || echo:Maint "Tests failed, will be noted in PR"

echo:Success "Test After Update Done"
