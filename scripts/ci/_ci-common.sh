#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2154
# CI Common Bootstrap: Sources e-bash logger for all CI scripts
#
# Usage: source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"
#
# This file initializes the e-bash logger system with domain-specific tags.
# Scripts replace `echo` with `echo:Tag` (e.g. echo:Build, echo:Test).
# To rollback to plain bash: string-replace `echo:Tag` back to `echo`.
#
# Logger output is controlled by the DEBUG environment variable:
#   DEBUG=build,test ./script.sh     # enable only build and test logs
#   DEBUG=*,-setup  ./script.sh      # enable all except setup
#   DEBUG=*         ./script.sh      # enable everything

_CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_REPO_ROOT="$(cd "$_CI_DIR/../.." && pwd)"
export E_BASH="${E_BASH:-$_REPO_ROOT/scripts/lib}"

# Source e-bash logger (disable unbound variable check for vendored code)
set +u
# shellcheck disable=SC1090,SC1091
source "$E_BASH/_logger.sh"
set -u

# Default: enable all CI loggers (CI environment is always verbose)
# In local dev, user can control via DEBUG=build,test,-setup
export DEBUG="${DEBUG:-ci,build,test,release,setup,notify,maint,report,security,ops}"

# Register domain loggers with prefixes, redirect to stderr
# Each logger creates echo:Tag and printf:Tag functions
logger:init "ci"       "[ci] "       ">&2"
logger:init "build"    "[build] "    ">&2"
logger:init "test"     "[test] "     ">&2"
logger:init "release"  "[release] "  ">&2"
logger:init "setup"    "[setup] "    ">&2"
logger:init "notify"   "[notify] "   ">&2"
logger:init "maint"    "[maint] "    ">&2"
logger:init "report"   "[report] "   ">&2"
logger:init "security" "[security] " ">&2"
logger:init "ops"      "[ops] "      ">&2"
