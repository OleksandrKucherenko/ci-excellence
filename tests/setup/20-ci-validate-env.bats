#!/usr/bin/env bats

# BATS test for 20-ci-validate-env.sh
# Tests CI environment validation script

# Determine script location
SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load test helpers if available
load "${BATS_TEST_DIRNAME}/../test_helper.bash" 2>/dev/null || true

# Setup test environment
setup() {
  # GIVEN: A clean temporary directory for testing
  TEST_TEMP_DIR="$(mktemp -d)"
  cd "$TEST_TEMP_DIR" || exit 1

  # Create mock bin directory for PATH manipulation
  mkdir -p "$TEST_TEMP_DIR/bin"
  export PATH="$TEST_TEMP_DIR/bin:$PATH"

  # Create mock common.sh library
  mkdir -p "$TEST_TEMP_DIR/scripts/lib"
  cat > "$TEST_TEMP_DIR/scripts/lib/common.sh" << 'EOF'
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

# Testability utilities
get_script_behavior() {
    local script_name="$1"
    local default_behavior="$2"
    echo "${CI_TEST_MODE:-$default_behavior}"
}

get_age_key_file() {
    echo "${PROJECT_ROOT:-}/.secrets/mise-age.txt"
}
EOF

  # Copy the script under test
  cp "$PROJECT_ROOT/scripts/setup/20-ci-validate-env.sh" .
  chmod +x ./20-ci-validate-env.sh

  # Set project root for the script
  export PROJECT_ROOT="$TEST_TEMP_DIR"
  export SCRIPT_ROOT="$TEST_TEMP_DIR/scripts"

  # Create mock commands for various tools
  create_mock_tools
}

# Create mock tools and commands
create_mock_tools() {
  local mock_bin="$TEST_TEMP_DIR/bin"

  # Mock node
  cat > "$mock_bin/node" << 'EOF'
#!/bin/bash
case "$1" in
  "--version")
    echo "v18.17.0"
    ;;
  *)
    echo "node $*"
    ;;
esac
EOF
  chmod +x "$mock_bin/node"

  # Mock npm
  cat > "$mock_bin/npm" << 'EOF'
#!/bin/bash
case "$1" in
  "--version")
    echo "9.6.7"
    ;;
  *)
    echo "npm $*"
    ;;
esac
EOF
  chmod +x "$mock_bin/npm"

  # Mock python3
  cat > "$mock_bin/python3" << 'EOF'
#!/bin/bash
case "$1" in
  "--version")
    echo "Python 3.11.4"
    ;;
  *)
    echo "python3 $*"
    ;;
esac
EOF
  chmod +x "$mock_bin/python3"

  # Mock pip3
  cat > "$mock_bin/pip3" << 'EOF'
#!/bin/bash
case "$1" in
  "--version")
    echo "pip 23.2.1"
    ;;
  *)
    echo "pip3 $*"
    ;;
esac
EOF
  chmod +x "$mock_bin/pip3"

  # Mock go
  cat > "$mock_bin/go" << 'EOF'
#!/bin/bash
case "$1" in
  "version")
    echo "go version go1.21.0"
    ;;
  *)
    echo "go $*"
    ;;
esac
EOF
  chmod +x "$mock_bin/go"

  # Mock rustc
  cat > "$mock_bin/rustc" << 'EOF'
#!/bin/bash
case "$1" in
  "--version")
    echo "rustc 1.71.0"
    ;;
  *)
    echo "rustc $*"
    ;;
esac
EOF
  chmod +x "$mock_bin/rustc"

  # Mock cargo
  cat > "$mock_bin/cargo" << 'EOF'
#!/bin/bash
case "$1" in
  "--version")
    echo "cargo 1.71.0"
    ;;
  *)
    echo "cargo $*"
    ;;
esac
EOF
  chmod +x "$mock_bin/cargo"

  # Mock mise
  cat > "$mock_bin/mise" << 'EOF'
#!/bin/bash
case "$1" in
  "--version")
    echo "2025.1.1"
    ;;
  *)
    echo "mise $*"
    ;;
esac
EOF
  chmod +x "$mock_bin/mise"

  # Mock sops
  cat > "$mock_bin/sops" << 'EOF'
#!/bin/bash
case "$1" in
  "--version")
    echo "sops 3.8.1"
    ;;
  *)
    echo "sops $*"
    ;;
esac
EOF
  chmod +x "$mock_bin/sops"

  # Mock age
  cat > "$mock_bin/age" << 'EOF'
#!/bin/bash
case "$1" in
  "--version")
    echo "age v1.1.1"
    ;;
  *)
    echo "age $*"
    ;;
esac
EOF
  chmod +x "$mock_bin/age"

  # Mock git
  cat > "$mock_bin/git" << 'EOF'
#!/bin/bash
case "$1" in
  "--version")
    echo "git version 2.41.0"
    ;;
  "rev-parse")
    if [[ "$2" == "--git-dir" ]]; then
      # Simulate being in a git repo
      echo ".git"
    fi
    ;;
  "config")
    if [[ "$2" == "--get" ]]; then
      echo "https://github.com/example/repo.git"
    fi
    ;;
  "diff-index")
    # Simulate clean working directory
    exit 0
    ;;
  *)
    echo "git $*"
    ;;
esac
EOF
  chmod +x "$mock_bin/git"

  # Mock jq
  cat > "$mock_bin/jq" << 'EOF'
#!/bin/bash
case "$2" in
  ".name")
    echo "test-project"
    ;;
  ".version")
    echo "1.0.0"
    ;;
  *)
    echo "null"
    ;;
esac
EOF
  chmod +x "$mock_bin/jq"

  # Mock grep
  cat > "$mock_bin/grep" << 'EOF'
#!/bin/bash
# Simple grep mock that returns true if pattern is found
if grep -q "$@" 2>/dev/null; then
  exit 0
fi
# For our tests, simulate finding common patterns
case "$1" in
  "^[^#][^A-Z_][A-Z0-9_]*=")
    # For invalid variable format test
    if [[ -f "invalid.env" ]]; then
      exit 0
    fi
    exit 1
    ;;
  "^[A-Z_][A-Z0-9_]*=.*#.*$")
    # For comment after assignment test
    if [[ -f "comment.env" ]]; then
      exit 0
    fi
    exit 1
    ;;
  *)
    exit 1
    ;;
esac
EOF
  chmod +x "$mock_bin/grep"

  # Mock python3 for JSON validation
  cat > "$mock_bin/python3" << 'EOF'
#!/bin/bash
case "$1" in
  "--version")
    echo "Python 3.11.4"
    ;;
  "-m")
    if [[ "$2" == "json.tool" ]]; then
      if [[ -f "invalid.json" ]]; then
        echo "Invalid JSON" >&2
        exit 1
      fi
      exit 0
    fi
    ;;
  *)
    echo "python3 $*"
    ;;
esac
EOF
  chmod +x "$mock_bin/python3"
}

teardown() {
  # Cleanup: Remove temporary directory
  rm -rf "$TEST_TEMP_DIR"
  unset PROJECT_ROOT SCRIPT_ROOT CI_TEST_MODE
  # Unset CI variables that might have been set
  unset CI GITHUB_ACTIONS GITHUB_REPOSITORY GITHUB_RUN_ID GITHUB_SHA
}

@test "validate_required_var succeeds for set variable" {
  # GIVEN: A required environment variable is set
  export TEST_VAR="test_value"

  # WHEN: We source the script and call validate_required_var
  source ./20-ci-validate-env.sh
  run validate_required_var "TEST_VAR" "test variable"

  # THEN: Should succeed
  assert_success
  assert_output --partial "test variable is set: TEST_VAR"

  # Cleanup
  unset TEST_VAR
}

@test "validate_required_var fails for unset required variable" {
  # GIVEN: A required environment variable is not set

  # WHEN: We source the script and call validate_required_var
  source ./20-ci-validate-env.sh
  run validate_required_var "UNSET_VAR" "unset variable" "true"

  # THEN: Should fail
  assert_failure
  assert_output --partial "Required unset variable not set: UNSET_VAR"
}

@test "validate_required_var succeeds for unset optional variable" {
  # GIVEN: An optional environment variable is not set

  # WHEN: We source the script and call validate_required_var
  source ./20-ci-validate-env.sh
  run validate_required_var "OPTIONAL_VAR" "optional variable" "false"

  # THEN: Should succeed
  assert_success
  assert_output --partial "Optional optional variable not set: OPTIONAL_VAR"
}

@test "validate_env_file succeeds for existing file" {
  # GIVEN: An environment file exists
  touch .env

  # WHEN: We source the script and call validate_env_file
  source ./20-ci-validate-env.sh
  run validate_env_file ".env" "environment file"

  # THEN: Should succeed
  assert_success
  assert_output --partial "environment file exists: .env"
}

@test "validate_env_file warns for missing file" {
  # GIVEN: An environment file does not exist

  # WHEN: We source the script and call validate_env_file
  source ./20-ci-validate-env.sh
  run validate_env_file ".missing" "missing file"

  # THEN: Should warn but not fail
  assert_success
  assert_output --partial "missing file not found: .missing"
}

@test "validate_env_file_format validates dotenv correctly" {
  # GIVEN: A valid dotenv file
  cat > .env << 'EOF'
VALID_VAR=value
ANOTHER_VAR=another_value
# Comment line
EOF

  # WHEN: We source the script and call validate_env_file_format
  source ./20-ci-validate-env.sh
  run validate_env_file_format ".env" "dotenv"

  # THEN: Should succeed
  assert_success
  assert_output --partial ".env has valid format"
}

@test "validate_env_file_format detects invalid dotenv" {
  # GIVEN: An invalid dotenv file (variable starts with lowercase)
  cat > invalid.env << 'EOF'
invalidVar=value
EOF

  # WHEN: We source the script and call validate_env_file_format
  source ./20-ci-validate-env.sh
  run validate_env_file_format "invalid.env" "dotenv"

  # THEN: Should fail
  assert_failure
  assert_output --partial "invalid.env has invalid variable format"
}

@test "validate_env_file_format validates JSON correctly" {
  # GIVEN: A valid JSON file
  cat > config.json << 'EOF'
{
  "key": "value",
  "number": 42
}
EOF

  # WHEN: We source the script and call validate_env_file_format
  source ./20-ci-validate-env.sh
  run validate_env_file_format "config.json" "json"

  # THEN: Should succeed
  assert_success
  assert_output --partial "config.json has valid format"
}

@test "validate_env_file_format detects invalid JSON" {
  # GIVEN: An invalid JSON file
  cat > invalid.json << 'EOF'
{
  "key": "value",
  "number": 42
EOF

  # WHEN: We source the script and call validate_env_file_format
  source ./20-ci-validate-env.sh
  run validate_env_file_format "invalid.json" "json"

  # THEN: Should fail
  assert_failure
  assert_output --partial "invalid.json has invalid JSON format"
}

@test "validate_node_env succeeds with Node.js environment" {
  # GIVEN: A Node.js project with package.json and lock file
  cat > package.json << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0"
}
EOF
  touch package-lock.json

  # WHEN: We source the script and call validate_node_env
  source ./20-ci-validate-env.sh
  run validate_node_env

  # THEN: Should succeed
  assert_success
  assert_output --partial "Node.js is installed: v18.17.0"
  assert_output --partial "npm is installed: 9.6.7"
  assert_output --partial "package.json exists"
  assert_output --partial "Lock file found: package-lock.json"
}

@test "validate_node_env fails when node is missing" {
  # GIVEN: Node command is not available (remove from PATH)
  mv "$TEST_TEMP_DIR/bin/node" "$TEST_TEMP_DIR/bin/node.bak"

  # WHEN: We source the script and call validate_node_env
  source ./20-ci-validate-env.sh
  run validate_node_env

  # THEN: Should fail
  assert_failure
  assert_output --partial "Node.js is not installed"

  # Restore node
  mv "$TEST_TEMP_DIR/bin/node.bak" "$TEST_TEMP_DIR/bin/node"
}

@test "validate_python_env succeeds with Python environment" {
  # GIVEN: A Python project with requirements.txt
  cat > requirements.txt << 'EOF'
flask>=2.0.0
requests>=2.25.0
EOF

  # WHEN: We source the script and call validate_python_env
  source ./20-ci-validate-env.sh
  run validate_python_env

  # THEN: Should succeed
  assert_success
  assert_output --partial "Python 3 is installed: Python 3.11.4"
  assert_output --partial "pip3 is installed: pip 23.2.1"
  assert_output --partial "requirements.txt exists"
}

@test "validate_python_env detects virtual environment" {
  # GIVEN: A Python project with virtual environment
  mkdir -p venv
  touch venv/pyvenv.cfg

  # WHEN: We source the script and call validate_python_env
  source ./20-ci-validate-env.sh
  run validate_python_env

  # THEN: Should detect virtual environment
  assert_success
  assert_output --partial "Virtual environment found: venv"
}

@test "validate_go_env succeeds with Go environment" {
  # GIVEN: A Go project with go.mod
  cat > go.mod << 'EOF'
module github.com/example/test

go 1.21
EOF

  # WHEN: We source the script and call validate_go_env
  source ./20-ci-validate-env.sh
  run validate_go_env

  # THEN: Should succeed
  assert_success
  assert_output --partial "Go is installed: go version go1.21.0"
  assert_output --partial "go.mod exists"
  assert_output --partial "Module: github.com/example/test"
}

@test "validate_rust_env succeeds with Rust environment" {
  # GIVEN: A Rust project with Cargo.toml
  cat > Cargo.toml << 'EOF'
[package]
name = "test-project"
version = "0.1.0"
edition = "2021"
EOF

  # WHEN: We source the script and call validate_rust_env
  source ./20-ci-validate-env.sh
  run validate_rust_env

  # THEN: Should succeed
  assert_success
  assert_output --partial "Rust is installed: rustc 1.71.0"
  assert_output --partial "Cargo is installed: cargo 1.71.0"
  assert_output --partial "Cargo.toml exists"
}

@test "validate_mise_env succeeds with MISE installed" {
  # GIVEN: MISE is installed and mise.toml exists
  cat > mise.toml << 'EOF'
[tools]
node = "18"
EOF

  # WHEN: We source the script and call validate_mise_env
  source ./20-ci-validate-env.sh
  run validate_mise_env

  # THEN: Should succeed
  assert_success
  assert_output --partial "MISE is installed: 2025.1.1"
  assert_output --partial "mise.toml exists"
  assert_output --partial "Project mise.toml exists"
}

@test "validate_mise_env warns when MISE is missing" {
  # GIVEN: MISE command is not available (remove from PATH)
  mv "$TEST_TEMP_DIR/bin/mise" "$TEST_TEMP_DIR/bin/mise.bak"

  # WHEN: We source the script and call validate_mise_env
  source ./20-ci-validate-env.sh
  run validate_mise_env

  # THEN: Should fail
  assert_failure
  assert_output --partial "MISE is not installed"

  # Restore mise
  mv "$TEST_TEMP_DIR/bin/mise.bak" "$TEST_TEMP_DIR/bin/mise"
}

@test "validate_sops_env succeeds with SOPS and age installed" {
  # GIVEN: SOPS configuration and age key file exist
  mkdir -p .secrets
  echo "age1testkey123456789abcdef" > .secrets/mise-age.txt
  cat > .sops.yaml << 'EOF'
creation_rules:
  - age: age1testkey123456789abcdef
EOF

  # WHEN: We source the script and call validate_sops_env
  source ./20-ci-validate-env.sh
  run validate_sops_env

  # THEN: Should succeed
  assert_success
  assert_output --partial "SOPS is installed: sops 3.8.1"
  assert_output --partial "Age is installed: age v1.1.1"
  assert_output --partial "SOPS configuration exists: .sops.yaml"
  assert_output --partial "Age key file exists:"
}

@test "validate_sops_env fails when SOPS is missing" {
  # GIVEN: SOPS command is not available (remove from PATH)
  mv "$TEST_TEMP_DIR/bin/sops" "$TEST_TEMP_DIR/bin/sops.bak"

  # WHEN: We source the script and call validate_sops_env
  source ./20-ci-validate-env.sh
  run validate_sops_env

  # THEN: Should fail
  assert_failure
  assert_output --partial "SOPS is not installed"

  # Restore sops
  mv "$TEST_TEMP_DIR/bin/sops.bak" "$TEST_TEMP_DIR/bin/sops"
}

@test "validate_git_env succeeds in git repository" {
  # GIVEN: We're in a git repository (mocked)
  mkdir -p .git
  touch .git/HEAD

  # WHEN: We source the script and call validate_git_env
  source ./20-ci-validate-env.sh
  run validate_git_env

  # THEN: Should succeed
  assert_success
  assert_output --partial "Git is installed: git version 2.41.0"
  assert_output --partial "Current directory is a Git repository"
  assert_output --partial "Working directory is clean"
  assert_output --partial "Git remote is configured"
}

@test "validate_ci_env checks CI environment variables" {
  # GIVEN: CI environment variables are set
  export CI=true
  export GITHUB_ACTIONS=true
  export GITHUB_REPOSITORY="example/repo"
  export GITHUB_RUN_ID="123456789"
  export GITHUB_SHA="abcdef1234567890"

  # WHEN: We source the script and call validate_ci_env
  source ./20-ci-validate-env.sh
  run validate_ci_env

  # THEN: Should validate all variables
  assert_success
  assert_output --partial "Continuous Integration indicator is set: CI"
  assert_output --partial "GitHub Actions indicator is set: GITHUB_ACTIONS"
  assert_output --partial "GitHub repository name is set: GITHUB_REPOSITORY"
}

@test "validate_environment handles DRY_RUN mode" {
  # GIVEN: CI_TEST_MODE is set to DRY_RUN
  export CI_TEST_MODE=DRY_RUN

  # WHEN: We source the script and call validate_environment
  source ./20-ci-validate-env.sh
  run validate_environment all

  # THEN: Should perform dry run
  assert_success
  assert_output --partial "DRY RUN: Would validate environment"
}

@test "validate_environment handles PASS mode" {
  # GIVEN: CI_TEST_MODE is set to PASS
  export CI_TEST_MODE=PASS

  # WHEN: We source the script and call validate_environment
  source ./20-ci-validate-env.sh
  run validate_environment all

  # THEN: Should simulate success
  assert_success
  assert_output --partial "PASS MODE: Environment validation simulated successfully"
}

@test "validate_environment handles FAIL mode" {
  # GIVEN: CI_TEST_MODE is set to FAIL
  export CI_TEST_MODE=FAIL

  # WHEN: We source the script and call validate_environment
  source ./20-ci-validate-env.sh
  run validate_environment all

  # THEN: Should simulate failure
  assert_failure
  assert_output --partial "FAIL MODE: Simulating environment validation failure"
}

@test "validate_environment handles SKIP mode" {
  # GIVEN: CI_TEST_MODE is set to SKIP
  export CI_TEST_MODE=SKIP

  # WHEN: We source the script and call validate_environment
  source ./20-ci-validate-env.sh
  run validate_environment all

  # THEN: Should skip validation
  assert_success
  assert_output --partial "SKIP MODE: Environment validation skipped"
}

@test "validate_environment handles TIMEOUT mode" {
  # GIVEN: CI_TEST_MODE is set to TIMEOUT
  export CI_TEST_MODE=TIMEOUT

  # WHEN: We run with timeout
  timeout 10s bash -c "source ./20-ci-validate-env.sh && validate_environment all"

  # THEN: Should simulate timeout (exit code 124)
  assert_equal $? 124
}

@test "validate_environment with specific scope works" {
  # GIVEN: MISE is installed

  # WHEN: We source the script and call validate_environment with mise scope
  source ./20-ci-validate-env.sh
  run validate_environment mise

  # THEN: Should only validate MISE environment
  assert_success
  assert_output --partial "Validating MISE environment"
  assert_output --partial "MISE is installed: 2025.1.1"
}

@test "validate_environment with unknown scope fails" {
  # WHEN: We source the script and call validate_environment with unknown scope
  source ./20-ci-validate-env.sh
  run validate_environment unknown

  # THEN: Should fail
  assert_failure
  assert_output --partial "Unknown validation scope: unknown"
}

@test "main script shows help when requested" {
  # WHEN: We run the script with help argument
  run ./20-ci-validate-env.sh help

  # THEN: Should show help and exit successfully
  assert_success
  assert_output --partial "CI Environment Validation Script v1.0.0"
  assert_output --partial "Usage:"
  assert_output --partial "Scopes:"
}

@test "main script runs comprehensive validation by default" {
  # GIVEN: All required tools and files are available
  mkdir -p .secrets .git
  echo "age1testkey123456789abcdef" > .secrets/mise-age.txt
  touch .sops.yaml mise.toml package.json package-lock.json go.mod Cargo.toml requirements.txt
  touch .git/HEAD

  # WHEN: We run the script without arguments
  run ./20-ci-validate-env.sh

  # THEN: Should run comprehensive validation
  assert_success
  assert_output --partial "Running comprehensive environment validation"
  assert_output --partial "Environment validation completed successfully"
}

@test "main script handles single scope validation" {
  # GIVEN: MISE is installed

  # WHEN: We run the script with mise scope
  run ./20-ci-validate-env.sh mise

  # THEN: Should validate only MISE
  assert_success
  assert_output --partial "Validating MISE environment"
}

@test "validate_required_var handles empty string values" {
  # GIVEN: An environment variable is set to empty string
  export EMPTY_VAR=""

  # WHEN: We source the script and call validate_required_var
  source ./20-ci-validate-env.sh
  run validate_required_var "EMPTY_VAR" "empty variable" "true"

  # THEN: Should fail for empty required variable
  assert_failure
  assert_output --partial "Required empty variable not set: EMPTY_VAR"

  # Cleanup
  unset EMPTY_VAR
}