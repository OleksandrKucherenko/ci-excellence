# shellcheck shell=bash
# ShellSpec spec_helper: loaded before every spec file via --require spec_helper

# Absolute path to the project root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export E_BASH="${REPO_ROOT}/scripts/lib"

# Create temp files that stand in for GitHub Actions outputs
export GITHUB_OUTPUT
GITHUB_OUTPUT="$(mktemp)"
export GITHUB_STEP_SUMMARY
GITHUB_STEP_SUMMARY="$(mktemp)"

# Enable all loggers so CI-common bootstrap succeeds
export DEBUG="*"

# Path to the run_script.sh wrapper used by all tests
export RUN_SCRIPT="${REPO_ROOT}/spec/support/run_script.sh"

# Pre-source the logger in the ShellSpec process itself (with errexit disabled)
set +eu
# shellcheck disable=SC1090,SC1091
source "${E_BASH}/_logger.sh" 2>/dev/null
set -u

# Cleanup temp files when the ShellSpec process exits
spec_helper_cleanup() {
  rm -f "$GITHUB_OUTPUT" "$GITHUB_STEP_SUMMARY" 2>/dev/null || true
}
trap spec_helper_cleanup EXIT
