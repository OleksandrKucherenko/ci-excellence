#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2154
# CI Common Bootstrap: Sources e-bash logger and hooks for all CI scripts
#
# Usage: source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"
#
# This file initializes:
# 1. e-bash logger with domain-specific colored tags
# 2. e-bash hooks system with per-script HOOKS_DIR and middleware
#
# Scripts replace `echo` with `echo:Tag` (e.g. echo:Build, echo:Test).
# To rollback to plain bash: string-replace `echo:Tag` back to `echo`.
#
# Logger output is controlled by the DEBUG environment variable:
#   DEBUG=build,test ./script.sh     # enable only build and test logs
#   DEBUG=*,-setup  ./script.sh      # enable all except setup
#   DEBUG=*         ./script.sh      # enable everything
#
# Hooks: consuming projects drop scripts in ci-cd/{step_name}/ directories.
# Scripts matching {hook}-*.sh are auto-discovered and executed via middleware.

_CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_REPO_ROOT="$(cd "$_CI_DIR/../.." && pwd)"
export E_BASH="${E_BASH:-$_REPO_ROOT/scripts/lib}"

# Default: enable all CI loggers (CI environment is always verbose).
# MUST be set before sourcing _hooks.sh, which sets DEBUG="error" if unset.
# In local dev, user can control via DEBUG=build,test,-setup
export DEBUG="${DEBUG:-ci,build,test,release,setup,notify,maint,report,security,ops,success,error,hooks}"

# Source e-bash core and initialize all loggers and hooks.
# The entire block runs with errexit and nounset disabled because the logger's
# eval-based dynamic function creation can trigger internal bash warnings.
# Strict mode is restored at the end.
set +eu
# shellcheck disable=SC1090,SC1091
source "$E_BASH/_logger.sh"
# shellcheck disable=SC1090,SC1091
source "$E_BASH/_hooks.sh"

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

# Cross-cutting status loggers: filterable across all domains.
# Grep for [SUCCESS] or [ERROR] to get a quick pass/fail summary of any pipeline.
logger:init "success"  "${cl_green}${st_bold}[SUCCESS]${cl_reset} "  ">&2"
logger:init "error"    "${cl_red}${st_bold}[ERROR]${cl_reset} "      ">&2"

# ---------------------------------------------------------------------------
# Hooks system: per-script extension points
# ---------------------------------------------------------------------------
# Each script gets its own HOOKS_DIR based on its filename.
# Consuming projects drop scripts in ci-cd/{step_name}/ to extend behavior.
# BASH_SOURCE[1] is the caller of _ci-common.sh (the step script itself).
_CI_SCRIPT_NAME="$(basename "${BASH_SOURCE[1]:-unknown}" .sh)"
export HOOKS_DIR="${HOOKS_DIR:-${_REPO_ROOT}/ci-cd/${_CI_SCRIPT_NAME}}"

# Bootstrap: declare begin + end hooks, install EXIT trap for end hooks
hooks:bootstrap

# Register middleware for contract-based hook communication (exec mode).
# Hook scripts emit contract:env:NAME=VALUE on stdout to safely set env vars.
hooks:middleware begin _hooks:middleware:modes

# Restore strict mode for the calling script
set -eu

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

# ---------------------------------------------------------------------------
# Environment variable helpers
# ---------------------------------------------------------------------------
# Verify a required env var is set, log it, and exit 1 if missing.
# Use this instead of positional args — scripts read from env vars set by workflows.
#   ci:require <tag> <var_name>
ci:require() {
  local tag="${1}" var_name="${2}"
  local value="${!var_name:-}"
  if [ -z "$value" ]; then
    echo:${tag^} "Error: ${var_name} is required but not set"
    exit 1
  fi
  ci:param "$tag" "$var_name" "$value"
}

# Log an optional env var (no error if empty).
#   ci:optional <tag> <var_name> [default]
ci:optional() {
  local tag="${1}" var_name="${2}" default="${3:-}"
  local value="${!var_name:-$default}"
  ci:param "$tag" "$var_name" "$value"
}
