#!/usr/bin/env bash
# Common Test Mocks Library for BATS Testing
# Provides shared mock patterns used across multiple test files

# Setup common test environment variables
setup_common_test_environment() {
    local project_root="${1:-$BATS_TEST_TMPDIR/project}"

    # CI Environment Variables
    export CI="${CI:-true}"
    export GITHUB_ACTIONS="${GITHUB_ACTIONS:-true}"
    export RUNNER_OS="${RUNNER_OS:-linux}"
    export LOG_TIMESTAMP="${LOG_TIMESTAMP:-false}"
    export DEBUG="${DEBUG:-false}"

    # Project Structure Variables
    export PROJECT_ROOT="$project_root"
    export SCRIPT_ROOT="${project_root}/scripts"
    export SCRIPT_DIR="${SCRIPT_ROOT}"
    export PATH="${BATS_TEST_TMPDIR}/bin:${PATH}"

    # Test Mode Configuration
    export CI_TEST_MODE="${CI_TEST_MODE:-EXECUTE}"

    # Common mock directories
    mkdir -p "${project_root}"/{.secrets,config,dist}
    mkdir -p "${SCRIPT_ROOT}"/{lib,setup,build,hooks,deployment,release}
    mkdir -p "${project_root}/.github/pre-commit-reports"
    mkdir -p "${BATS_TEST_TMPDIR}/bin"
}

# Create mock common library with logging functions
create_mock_common_library() {
    local lib_dir="${1:-$SCRIPT_ROOT/lib}"

    mkdir -p "$lib_dir"

    cat > "${lib_dir}/common.sh" << 'EOF'
#!/bin/bash
# Mock common library for testing

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Logging functions
log_debug() { [[ "${DEBUG:-false}" == "true" ]] && printf "${CYAN}[DEBUG] %s${NC}\n" "$1" >&2; }
log_info() { printf "${BLUE}[INFO] %s${NC}\n" "$1" >&2; }
log_success() { printf "${GREEN}[SUCCESS] %s${NC}\n" "$1" >&2; }
log_warn() { printf "${YELLOW}[WARN] %s${NC}\n" "$1" >&2; }
log_error() { printf "${RED}[ERROR] %s${NC}\n" "$1" >&2; }
log_critical() { printf "${RED}[CRITICAL] %s${NC}\n" "$1" >&2; }

# Testability utilities
get_script_behavior() {
    local script_name="$1"
    local default_behavior="$2"
    echo "${CI_TEST_MODE:-$default_behavior}"
}

get_env_var() {
    local var_name="$1"
    local default_value="$2"
    echo "${!var_name:-$default_value}"
}

get_age_key_file() {
    echo "${PROJECT_ROOT:-}/.secrets/mise-age.txt"
}

# Array helper functions
array_contains() {
    local element="$1"
    shift
    for item in "$@"; do
        [[ "$item" == "$element" ]] && return 0
    done
    return 1
}
EOF
}

# Create mock environment library
create_mock_environment_library() {
    local lib_dir="${1:-$SCRIPT_ROOT/lib}"

    mkdir -p "$lib_dir"

    cat > "${lib_dir}/environment.sh" << 'EOF'
#!/bin/bash
# Mock environment library for testing

discover_environments() {
    echo "staging production local development"
}

is_default_environment() {
    local env="$1"
    [[ "$env" == "staging" || "$env" == "production" ]]
}

validate_environment() {
    local env="$1"
    case "$env" in
        "local"|"development"|"staging"|"production")
            return 0
            ;;
        *)
            echo "Unknown environment: $env" >&2
            return 1
            ;;
    esac
}
EOF
}

# Setup test mode behaviors
setup_test_mode() {
    local mode="${1:-EXECUTE}"
    export CI_TEST_MODE="$mode"

    case "$mode" in
        "DRY_RUN")
            echo "DRY RUN mode enabled - commands will be simulated"
            ;;
        "PASS")
            echo "PASS mode enabled - commands will always succeed"
            ;;
        "FAIL")
            echo "FAIL mode enabled - commands will always fail"
            ;;
        "SKIP")
            echo "SKIP mode enabled - commands will be skipped"
            ;;
        "TIMEOUT")
            echo "TIMEOUT mode enabled - commands will simulate timeout"
            ;;
        "EXECUTE")
            echo "EXECUTE mode enabled - commands will run normally"
            ;;
        *)
            echo "Unknown test mode: $mode" >&2
            return 1
            ;;
    esac
}

# Configure mock failures
set_mock_failure() {
    local command="$1"
    local should_fail="${2:-true}"

    export "FAIL_${command^^}=$should_fail"
}

# Clear all mock failure configurations
clear_mock_failures() {
    local var
    for var in $(set | grep '^FAIL_' | cut -d= -f1); do
        unset "$var"
    done
}

# Create test configuration files
create_test_config_files() {
    local project_root="${1:-$PROJECT_ROOT}"

    # Create .shfmt.toml for formatting tests
    cat > "${project_root}/.shfmt.toml" << 'EOF'
indent = 2
binary_next_line = true
case_indent = true
space_redirects = true
EOF

    # Create basic package.json for Node.js tests
    cat > "${project_root}/package.json" << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0",
  "description": "Test project for CI excellence",
  "scripts": {
    "test": "echo \"Running tests\"",
    "build": "echo \"Building project\"",
    "lint": "echo \"Linting code\""
  }
}
EOF

    # Create mise configuration
    cat > "${project_root}/.mise.toml" << 'EOF'
[env]
CI = "true"
GITHUB_ACTIONS = "true"

[tools]
node = "18.17.0"
bash = "5.0.0"
EOF
}

# Setup mock git repository
setup_mock_git_repo() {
    local repo_dir="${1:-$PROJECT_ROOT}"
    local branch="${2:-main}"

    cd "$repo_dir" || return 1

    # Initialize git repository structure (mock)
    mkdir -p .git/objects .git/refs/heads

    # Create basic git config
    cat > .git/config << 'EOF'
[core]
	repositoryformatversion = 0
	filemode = true
	bare = false
[user]
	name = Test User
	email = test@example.com
EOF

    # Create HEAD reference
    echo "ref: refs/heads/${branch}" > .git/HEAD

    # Create branch reference
    mkdir -p .git/refs/heads
    echo "abc123def4567890abcdef1234567890abcdef12" > ".git/refs/heads/${branch}"

    export GIT_MOCK_BRANCH="$branch"
    export GIT_MOCK_SHA="abc123def4567890abcdef1234567890abcdef12"
}

# Cleanup common test environment
cleanup_common_test_environment() {
    # Unset common environment variables
    unset PROJECT_ROOT SCRIPT_ROOT SCRIPT_DIR
    unset CI GITHUB_ACTIONS RUNNER_OS LOG_TIMESTAMP DEBUG CI_TEST_MODE

    # Clear mock failures
    clear_mock_failures

    # Remove mock bin directory from PATH
    local mock_bin="${BATS_TEST_TMPDIR}/bin"
    if [[ ":$PATH:" == *":$mock_bin:"* ]]; then
        export PATH="${PATH//:$mock_bin:/}"
    fi
}