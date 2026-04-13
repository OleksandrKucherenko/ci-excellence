#!/usr/bin/env bash
# Test helper: Run a CI script with the e-bash logger pre-initialized.
#
# The logger triggers a bash internal "pop_var_context" warning on some
# bash versions.  Under `set -e` (which every CI script enables) this
# kills the process before the real logic runs.  This wrapper pre-sources
# the logger (and optionally semver) with errexit disabled so the
# pop_var_context error is non-fatal.  When the target script later sources
# _ci-common.sh or _semver.sh, the "already loaded" guards skip
# re-initialization and no error occurs.
#
# Usage: bash spec/support/run_script.sh <script> [args...]

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export E_BASH="${E_BASH:-$REPO_ROOT/scripts/lib}"
export DEBUG="${DEBUG:-*}"

# Pre-source the logger and semver with errexit disabled
set +eu
# shellcheck disable=SC1090,SC1091
source "$E_BASH/_logger.sh" 2>/dev/null

# Initialize all domain loggers that _ci-common.sh creates
logger:init "ci"       "[ci] "       ">&2" 2>/dev/null
logger:init "build"    "[build] "    ">&2" 2>/dev/null
logger:init "test"     "[test] "     ">&2" 2>/dev/null
logger:init "release"  "[release] "  ">&2" 2>/dev/null
logger:init "setup"    "[setup] "    ">&2" 2>/dev/null
logger:init "notify"   "[notify] "   ">&2" 2>/dev/null
logger:init "maint"    "[maint] "    ">&2" 2>/dev/null
logger:init "report"   "[report] "   ">&2" 2>/dev/null
logger:init "security" "[security] " ">&2" 2>/dev/null
logger:init "ops"      "[ops] "      ">&2" 2>/dev/null

# Pre-source semver library (used by release scripts)
# shellcheck disable=SC1090,SC1091
source "$E_BASH/_semver.sh" 2>/dev/null

# Initialize loggers that _semver.sh creates at its bottom
logger:init "semver" "" ">&2" 2>/dev/null
logger:init "regex"  "" ">&2" 2>/dev/null
logger:init "simple" "" ">&2" 2>/dev/null
logger:init "loader" "" ">&2" 2>/dev/null

# Do NOT re-enable errexit -- let each target script set its own options
set +eu

# Source the target script in this process (so it inherits loaded logger state)
SCRIPT="$1"; shift
source "$SCRIPT" "$@"
