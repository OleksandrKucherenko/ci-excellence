#!/usr/bin/env bash
# ShellSpec spec_helper: sourced before every test file

# Point e-bash to the vendored library
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export E_BASH="$REPO_ROOT/scripts/lib"

# Create temp files that CI scripts write to via GITHUB_OUTPUT / GITHUB_STEP_SUMMARY
_gh_output=$(mktemp)
_gh_summary=$(mktemp)
export GITHUB_OUTPUT="$_gh_output"
export GITHUB_STEP_SUMMARY="$_gh_summary"

# Enable all loggers so that logger:init calls succeed
export DEBUG="*"

# Source e-bash logger (needed by _ci-common.sh which every script sources)
set +u
# shellcheck disable=SC1090,SC1091
source "$E_BASH/_logger.sh"
set -u

# ---------------------------------------------------------------------------
# Cleanup helper -- called by ShellSpec after each example group
# ---------------------------------------------------------------------------
spec_helper_cleanup() {
  # Truncate output files so the next test starts clean
  : > "$GITHUB_OUTPUT"
  : > "$GITHUB_STEP_SUMMARY"
}

# Register the cleanup as an AfterEach hook (ShellSpec convention)
AfterEach 'spec_helper_cleanup'

# Remove temp files when the entire test run finishes
spec_helper_teardown() {
  rm -f "$_gh_output" "$_gh_summary" 2>/dev/null || true
}

AfterAll 'spec_helper_teardown'
