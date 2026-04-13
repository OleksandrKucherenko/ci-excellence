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

# Register domain loggers with colored prefixes, redirect to stderr.
# Each tag has a distinct color for easy recognition in CI logs.
# Each logger creates echo:Tag and printf:Tag functions.
logger:init "ci"       "${cl_white}${st_bold}[ci]${cl_reset} "       ">&2"
logger:init "build"    "${cl_cyan}${st_bold}[build]${cl_reset} "     ">&2"
logger:init "test"     "${cl_green}${st_bold}[test]${cl_reset} "     ">&2"
logger:init "release"  "${cl_purple}${st_bold}[release]${cl_reset} " ">&2"
logger:init "setup"    "${cl_blue}${st_bold}[setup]${cl_reset} "     ">&2"
logger:init "notify"   "${cl_yellow}[notify]${cl_reset} "            ">&2"
logger:init "maint"    "${cl_grey}${st_italic}[maint]${cl_reset} "   ">&2"
logger:init "report"   "${cl_grey}[report]${cl_reset} "              ">&2"
logger:init "security" "${cl_red}${st_bold}[security]${cl_reset} "   ">&2"
logger:init "ops"      "${cl_lpurple}${st_bold}[ops]${cl_reset} "    ">&2"

# ---------------------------------------------------------------------------
# Parameter logging helpers
# ---------------------------------------------------------------------------
# Print a safe (non-secret) parameter value to the CI log.
#   ci:param <tag> <name> <value>
ci:param() {
  local tag="${1}" name="${2}" value="${3:-}"
  if [ -z "$value" ]; then
    printf:${tag^} "  %-24s = ${cl_grey}(empty)${cl_reset}\n" "$name"
  else
    printf:${tag^} "  %-24s = %s\n" "$name" "$value"
  fi
}

# Print a masked secret value: first 3 chars + *** + last 3 chars.
# Short values (<=6 chars) are fully masked as ***
#   ci:secret <tag> <name> <value>
ci:secret() {
  local tag="${1}" name="${2}" value="${3:-}"
  local masked
  if [ -z "$value" ]; then
    masked="${cl_grey}(not set)${cl_reset}"
  elif [ "${#value}" -le 6 ]; then
    masked="***"
  else
    masked="${value:0:3}***${value: -3}"
  fi
  printf:${tag^} "  %-24s = %s\n" "$name" "$masked"
}

# ---------------------------------------------------------------------------
# Output logging helpers
# ---------------------------------------------------------------------------
# Write a key=value to GITHUB_OUTPUT and log it to the CI log.
# Replaces bare `echo "key=value" >> "$GITHUB_OUTPUT"` with visible logging.
#   ci:output <tag> <name> <value>
ci:output() {
  local tag="${1}" name="${2}" value="${3:-}"
  echo "${name}=${value}" >> "$GITHUB_OUTPUT"
  printf:${tag^} "  ${cl_green}output${cl_reset} %-18s = %s\n" "$name" "$value"
}

# Write a multiline value to GITHUB_OUTPUT using heredoc delimiter and log it.
# For values that span multiple lines (e.g. release notes).
#   ci:output:multiline <tag> <name> <value>
ci:output:multiline() {
  local tag="${1}" name="${2}" value="${3:-}"
  {
    echo "${name}<<EOF"
    echo "$value"
    echo "EOF"
  } >> "$GITHUB_OUTPUT"
  local preview="${value%%$'\n'*}"
  printf:${tag^} "  ${cl_green}output${cl_reset} %-18s = %s... (%d lines)\n" "$name" "${preview:0:60}" "$(echo "$value" | wc -l)"
}
