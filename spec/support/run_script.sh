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
# Usage: bash spec/support/run_script.sh <script>
# Scripts read inputs from environment variables (not positional args).

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export E_BASH="${E_BASH:-$REPO_ROOT/scripts/lib}"
export DEBUG="${DEBUG:-*}"

# Pre-source the logger and semver with errexit disabled
set +eu
# shellcheck disable=SC1090,SC1091
source "$E_BASH/_logger.sh" 2>/dev/null

# Initialize all domain loggers that _ci-common.sh creates (colors match _ci-common.sh)
logger:init "ci"       "${cl_white:-}${st_bold:-}[ci]${cl_reset:-} "       ">&2" 2>/dev/null
logger:init "build"    "${cl_cyan:-}${st_bold:-}[build]${cl_reset:-} "     ">&2" 2>/dev/null
logger:init "test"     "${cl_green:-}${st_bold:-}[test]${cl_reset:-} "     ">&2" 2>/dev/null
logger:init "release"  "${cl_purple:-}${st_bold:-}[release]${cl_reset:-} " ">&2" 2>/dev/null
logger:init "setup"    "${cl_blue:-}${st_bold:-}[setup]${cl_reset:-} "     ">&2" 2>/dev/null
logger:init "notify"   "${cl_yellow:-}[notify]${cl_reset:-} "              ">&2" 2>/dev/null
logger:init "maint"    "${cl_grey:-}${st_italic:-}[maint]${cl_reset:-} "   ">&2" 2>/dev/null
logger:init "report"   "${cl_grey:-}[report]${cl_reset:-} "                ">&2" 2>/dev/null
logger:init "security" "${cl_red:-}${st_bold:-}[security]${cl_reset:-} "   ">&2" 2>/dev/null
logger:init "ops"      "${cl_lpurple:-}${st_bold:-}[ops]${cl_reset:-} "    ">&2" 2>/dev/null
logger:init "success"  "${cl_green:-}${st_bold:-}[SUCCESS]${cl_reset:-} "  ">&2" 2>/dev/null
logger:init "error"    "${cl_red:-}${st_bold:-}[ERROR]${cl_reset:-} "      ">&2" 2>/dev/null

# Pre-source semver library (used by release scripts)
# shellcheck disable=SC1090,SC1091
source "$E_BASH/_semver.sh" 2>/dev/null

# Initialize loggers that _semver.sh creates at its bottom
logger:init "semver" "" ">&2" 2>/dev/null
logger:init "regex"  "" ">&2" 2>/dev/null
logger:init "simple" "" ">&2" 2>/dev/null
logger:init "loader" "" ">&2" 2>/dev/null

# Parameter logging helpers (match _ci-common.sh)
ci:param() {
  local tag="${1}" name="${2}" value="${3:-}"
  if [ -z "$value" ]; then
    printf:${tag^} "  %-24s = ${cl_grey:-}(empty)${cl_reset:-}\n" "$name" 2>/dev/null
  else
    printf:${tag^} "  %-24s = %s\n" "$name" "$value" 2>/dev/null
  fi
}
ci:secret() {
  local tag="${1}" name="${2}" value="${3:-}"
  local masked
  if [ -z "$value" ]; then
    masked="${cl_grey:-}(not set)${cl_reset:-}"
  elif [ "${#value}" -le 6 ]; then
    masked="***"
  else
    masked="${value:0:3}***${value: -3}"
  fi
  printf:${tag^} "  %-24s = %s\n" "$name" "$masked" 2>/dev/null
}
ci:output() {
  local tag="${1}" name="${2}" value="${3:-}"
  echo "${name}=${value}" >> "$GITHUB_OUTPUT"
  printf:${tag^} "  output %-18s = %s\n" "$name" "$value" 2>/dev/null
}
ci:output:multiline() {
  local tag="${1}" name="${2}" value="${3:-}"
  { echo "${name}<<EOF"; echo "$value"; echo "EOF"; } >> "$GITHUB_OUTPUT"
  local preview="${value%%$'\n'*}"
  printf:${tag^} "  output %-18s = %s... (%d lines)\n" "$name" "${preview:0:60}" "$(echo "$value" | wc -l)" 2>/dev/null
}
ci:require() {
  local tag="${1}" var_name="${2}"
  local value="${!var_name:-}"
  if [ -z "$value" ]; then
    echo:${tag^} "Error: ${var_name} is required but not set" 2>/dev/null
    exit 1
  fi
  ci:param "$tag" "$var_name" "$value"
}
ci:optional() {
  local tag="${1}" var_name="${2}" default="${3:-}"
  local value="${!var_name:-$default}"
  ci:param "$tag" "$var_name" "$value"
}

# Do NOT re-enable errexit -- let each target script set its own options
set +eu

# Source the target script in this process (so it inherits env vars + loaded logger state)
SCRIPT="$1"; shift
source "$SCRIPT"
