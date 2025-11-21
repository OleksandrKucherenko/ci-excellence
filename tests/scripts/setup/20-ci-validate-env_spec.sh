#!/usr/bin/env bash
# ShellSpec tests for CI Environment Validation Script
# Tests the 20-ci-validate-env.sh script functionality

set -euo pipefail

# Load the script under test
# shellcheck disable=SC1090,SC1091
. "$(dirname "$0")/../../../scripts/setup/20-ci-validate-env.sh" 2>/dev/null || {
  echo "Failed to source 20-ci-validate-env.sh" >&2
  exit 1
}

# Mock common functions for testing
mock_common_functions() {
  log_info() {
    echo "[INFO] $*"
  }

  log_success() {
    echo "[SUCCESS] $*"
  }

  log_error() {
    echo "[ERROR] $*"
  }

  log_warn() {
    echo "[WARN] $*"
  }

  log_debug() {
    echo "[DEBUG] $*"
  }
}

# Mock command detection
mock_commands() {
  # Mock command existence checks
  command() {
    case "$1" in
      "node")
        if [[ "${CI_VALIDATE_ENV_BEHAVIOR:-}" == "FAIL_NODE" ]]; then
          return 1
        fi
        return 0
        ;;
      "npm"|"yarn"|"pnpm"|"bun")
        if [[ "${CI_VALIDATE_ENV_BEHAVIOR:-}" == "FAIL_PACKAGE" ]]; then
          return 1
        fi
        return 0
        ;;
      "python3"|"python")
        if [[ "${CI_VALIDATE_ENV_BEHAVIOR:-}" == "FAIL_PYTHON" ]]; then
          return 1
        fi
        return 0
        ;;
      "pip"|"pip3")
        if [[ "${CI_VALIDATE_ENV_BEHAVIOR:-}" == "FAIL_PIP" ]]; then
          return 1
        fi
        return 0
        ;;
      "go")
        if [[ "${CI_VALIDATE_ENV_BEHAVIOR:-}" == "FAIL_GO" ]]; then
          return 1
        fi
        return 0
        ;;
      "cargo"|"rustc")
        if [[ "${CI_VALIDATE_ENV_BEHAVIOR:-}" == "FAIL_RUST" ]]; then
          return 1
        fi
        return 0
        ;;
      "mise")
        if [[ "${CI_VALIDATE_ENV_BEHAVIOR:-}" == "FAIL_MISE" ]]; then
          return 1
        fi
        return 0
        ;;
      "sops")
        if [[ "${CI_VALIDATE_ENV_BEHAVIOR:-}" == "FAIL_SOPS" ]]; then
          return 1
        fi
        return 0
        ;;
      "age")
        if [[ "${CI_VALIDATE_ENV_BEHAVIOR:-}" == "FAIL_AGE" ]]; then
          return 1
        fi
        return 0
        ;;
      "git")
        if [[ "${CI_VALIDATE_ENV_BEHAVIOR:-}" == "FAIL_GIT" ]]; then
          return 1
        fi
        return 0
        ;;
      "jq")
        return 0
        ;;
      "yq")
        if [[ "${CI_VALIDATE_ENV_BEHAVIOR:-}" == "FAIL_YQ" ]]; then
          return 1
        fi
        return 0
        ;;
      "grep")
        return 0
        ;;
      "head")
        return 0
        ;;
      "cut")
        return 0
        ;;
      "wc")
        return 0
        ;;
      *)
        echo "mock command: $1" >&2
        return 127
        ;;
    esac
  }

  # Mock command output
  node() {
    echo "v20.10.0"
  }

  npm() {
    echo "9.8.1"
  }

  yarn() {
    echo "1.22.19"
  }

  pnpm() {
    echo "8.6.12"
  }

  bun() {
    echo "1.1.8"
  }

  python3() {
    echo "Python 3.11.5"
  }

  python() {
    echo "Python 3.11.5"
  }

  pip() {
    echo "pip 23.2.1"
  }

  pip3() {
    echo "pip 23.2.1"
  }

  go() {
    echo "go version go1.21.0 linux/amd64"
  }

  cargo() {
    echo "cargo 1.71.0"
  }

  rustc() {
    echo "rustc 1.71.0"
  }

  mise() {
    echo "mise 2024.1.1"
  }

  sops() {
    echo "sops 3.7.3"
  }

  age() {
    echo "v1.1.1"
  }

  git() {
    case "$1" in
      "version")
        echo "git version 2.39.3"
        ;;
      "rev-parse")
        if [[ "$2" == "--git-dir" ]]; then
          echo ".git"
        else
          return 1
        fi
        ;;
      "config")
        if [[ "$2" == "--get" && "$3" == "remote.origin.url" ]]; then
          echo ""
        else
          return 1
        fi
        ;;
      "diff-index")
        echo ""  # No output means clean
        ;;
      "status")
        echo ""  # Mock clean status
        ;;
      *)
        echo "git $*"
        ;;
    esac
  }
}

# Mock file operations
mock_files() {
  # Mock file existence checks
  [[ -f "$1" ]]
}

# Setup test environment
setup_test_environment() {
  # Create test directory
  mkdir -p "/tmp/validate-env-test"

  # Set test environment variables
  export CI_VALIDATE_ENV_BEHAVIOR="${CI_VALIDATE_ENV_BEHAVIOR:-EXECUTE}"
  export CI_TEST_MODE="${CI_TEST_MODE:-EXECUTE}"

  # Mock common functions
  mock_common_functions

  # Mock commands
  mock_commands

  # Mock project files
  mkdir -p "/tmp/validate-env-test/node-project"
  mkdir -p "/tmp/validate-env-test/python-project"
  mkdir -p "/tmp/validate-env-test/go-project"
  mkdir -p "/tmp/validate-env-test/rust-project"

  # Node.js project files
  echo '{"name": "test-node", "version": "1.0.0"}' > "/tmp/validate-env-test/node-project/package.json"
  echo '{"name": "test-node", "version": "1.0.0"}' > "/tmp/validate-env-test/node-project/package-lock.json"

  # Python project files
  echo "requests==2.31.0" > "/tmp/validate-env-test/python-project/requirements.txt"
  echo "pytest==7.4.0" >> "/tmp/validate-env-test/python-project/requirements.txt"

  # Go project files
  echo 'module test-go' > "/tmp/validate-env-test/go-project/go.mod"

  # Rust project files
  cat > "/tmp/validate-env-test/rust-project/Cargo.toml" << EOF
[package]
name = "test-rust"
version = "0.1.0"
edition = "2021"
EOF

  # Mock age key file
  mkdir -p "/tmp/validate-env-test/.secrets"
  echo "AGE-SECRET-1-1xyz123abc456def" > "/tmp/validate-env-test/.secrets/mise-age.txt"

  # Mock SOPS config
  cat > "/tmp/validate-env-test/.sops.yaml" << EOF
creation_rules:
  - path_regex: ^.*\\.enc$
    age: age1y8l0yvdvpzcyphwr29ua8pwwm6uw8t2t7g4df3awfgcrdla5d3dq9ldk2n
EOF

  # Mock mise.toml
  cat > "/tmp/validate-env-test/mise.toml" << EOF
[tools]
bun = "latest"
node = "lts/*"
sops = "latest"
age = "latest"
EOF

  # Mock environment files
  cat > "/tmp/validate-env-test/.env.local" << EOF
DEPLOYMENT_PROFILE=local
ENVIRONMENT_CONTEXT=development
CI_TEST_MODE=EXECUTE
EOF
}

# Cleanup test environment
cleanup_test_environment() {
  rm -rf "/tmp/validate-env-test"
}

Describe "CI Environment Validation Script"
  BeforeEach "setup_test_environment"
  AfterEach "cleanup_test_environment"

  Describe "behavior mode handling"
    Context "when CI_VALIDATE_ENV_BEHAVIOR is DRY_RUN"
      BeforeEach "export CI_VALIDATE_ENV_BEHAVIOR=DRY_RUN"

      It "should run in dry run mode"
        When call validate_environment "all"
        The output should include "🔍 DRY RUN: Would validate environment"
      End
    End

    Context "when CI_VALIDATE_ENV_BEHAVIOR is PASS"
      BeforeEach "export CI_VALIDATE_ENV_BEHAVIOR=PASS"

      It "should simulate successful validation"
        When call validate_environment "all"
        The output should include "PASS MODE: Environment validation simulated successfully"
      End
    End

    Context "when CI_VALIDATE_ENV_BEHAVIOR is FAIL"
      BeforeEach "export CI_VALIDATE_ENV_BEHAVIOR=FAIL"

      It "should simulate validation failure"
        When call validate_environment "mise"
        The output should include "FAIL MODE: Simulating environment validation failure"
        The status should be failure
      End
    End

    Context "when CI_VALIDATE_ENV_BEHAVIOR is SKIP"
      BeforeEach "export CI_VALIDATE_ENV_BEHAVIOR=SKIP"

      It "should skip validation"
        When call validate_environment "all"
        The output should include "SKIP MODE: Environment validation skipped"
      End
    End

    Context "when CI_VALIDATE_ENV_BEHAVIOR is TIMEOUT"
      BeforeEach "export CI_VALIDATE_ENV_BEHAVIOR=TIMEOUT"

      It "should simulate timeout"
        When run timeout 10s validate_environment "all"
        The output should include "TIMEOUT MODE: Simulating environment validation timeout"
        The status should be timeout
      End
    End
  End

  Describe "EXECUTE mode functionality"
    BeforeEach "export CI_VALIDATE_ENV_BEHAVIOR=EXECUTE"
    BeforeEach "cd /tmp/validate-env-test"

    Describe "MISE environment validation"
      It "should succeed when MISE is installed"
        When call validate_mise_env
        The output should include "✅ MISE is installed"
        The output should include "✅ Project mise.toml exists"
      End

      It "should fail when MISE is not installed"
        BeforeEach "export CI_VALIDATE_ENV_BEHAVIOR=FAIL_MISE"

        When call validate_mise_env
        The output should include "❌ MISE is not installed"
        The status should be failure
      End
    End

    Describe "SOPS environment validation"
      It "should succeed when SOPS and Age are installed"
        When call validate_sops_env
        The output should include "✅ SOPS is installed"
        The output should include "✅ Age is installed"
        The output should include "✅ Age key file exists"
        The output should include "✅ SOPS configuration exists"
      End

      It "should fail when SOPS is not installed"
        BeforeEach "export CI_VALIDATE_ENV_BEHAVIOR=FAIL_SOPS"

        When call validate_sops_env
        The output should include "❌ SOPS is not installed"
        The status should be failure
      End

      It "should fail when Age is not installed"
        BeforeEach "export CI_VALIDATE_ENV_BEHAVIOR=FAIL_AGE"

        When call validate_sops_env
        The output should include "❌ Age is not installed"
        The status should be failure
      End

      It "should fail when age key file is missing"
        BeforeEach "rm -f .secrets/mise-age.txt"

        When call validate_sops_env
        The output should include "❌ Age key file not found"
        The status should be failure
      End
    End

    Describe "Git environment validation"
      It "should succeed when Git is installed"
        When call validate_git_env
        The output should include "✅ Git is installed"
        The output should include "✅ Current directory is a Git repository"
      End

      It "should fail when Git is not installed"
        BeforeEach "export CI_VALIDATE_ENV_BEHAVIOR=FAIL_GIT"

        When call validate_git_env
        The output should include "❌ Git is not installed"
        The status should be failure
      End
    End

    Describe "Node.js environment validation"
      BeforeEach "cd /tmp/validate-env-test/node-project"

      It "should succeed when Node.js and npm are installed"
        When call validate_node_env
        The output should include "✅ Node.js is installed"
        The output should include "✅ npm is installed"
        The output should include "✅ package.json exists"
        The output should include "✅ Lock file found: package-lock.json"
      End

      It "should fail when Node.js is not installed"
        BeforeEach "export CI_VALIDATE_ENV_BEHAVIOR=FAIL_NODE"

        When call validate_node_env
        The output should include "❌ Node.js is not installed"
        The status should be failure
      End

      It "should fail when npm is not installed"
        BeforeEach "export CI_VALIDATE_ENV_BEHAVIOR=FAIL_PACKAGE"

        When call validate_node_env
        The output should include "❌ npm is not installed"
        The status should be failure
      End
    End

    Describe "Python environment validation"
      BeforeEach "cd /tmp/validate-env-test/python-project"

      It "should succeed when Python and pip are installed"
        When call validate_python_env
        The output should include "✅ Python 3 is installed"
        The output should include "✅ pip is installed"
        The output should include "✅ requirements.txt exists"
      End

      It "should fail when Python is not installed"
        BeforeEach "export CI_VALIDATE_ENV_BEHAVIOR=FAIL_PYTHON"

        When call validate_python_env
        The output should include "❌ Python is not installed"
        The status should be failure
      End

      It "should fail when pip is not installed"
        BeforeEach "export CI_VALIDATE_ENV_BEHAVIOR=FAIL_PIP"

        When call validate_python_env
        The output should include "❌ pip is not installed"
        The status should be failure
      End
    End

    Describe "Go environment validation"
      BeforeEach "cd /tmp/validate-env-test/go-project"

      It "should succeed when Go is installed"
        When call validate_go_env
        The output should include "✅ Go is installed"
        The output should include "✅ go.mod exists"
      End

      It "should fail when Go is not installed"
        BeforeEach "export CI_VALIDATE_ENV_BEHAVIOR=FAIL_GO"

        When call validate_go_env
        The output should include "❌ Go is not installed"
        The status should be failure
      End
    End

    Describe "Rust environment validation"
      BeforeEach "cd /tmp/validate-env-test/rust-project"

      It "should succeed when Rust and Cargo are installed"
        When call validate_rust_env
        The output should include "✅ Rust is installed"
        The output should include "✅ Cargo is installed"
        The output should include "✅ Cargo.toml exists"
      End

      It "should fail when Rust is not installed"
        BeforeEach "export CI_VALIDATE_ENV_BEHAVIOR=FAIL_RUST"

        When call validate_rust_env
        The output should include "❌ Rust is not installed"
        The status should be failure
      End
    End

    Describe "scope-specific validation"
      It "should validate only mise when scope is mise"
        When call validate_environment "mise"
        The output should include "Validating MISE environment"
        The output should not include "Validating SOPS environment"
        The output should not include "Validating Git environment"
      End

      It "should validate only sops when scope is sops"
        When call validate_environment "sops"
        The output should include "Validating SOPS environment"
        The output should not include "Validating MISE environment"
        The output should not include "Validating Git environment"
      End

      It "should validate only git when scope is git"
        When call validate_environment "git"
        The output should include "Validating Git environment"
        The output should not include "Validating MISE environment"
        The output should not include "Validating SOPS environment"
      End
    End

    Describe "project type auto-detection"
      BeforeEach "cd /tmp/validate-env-test"

      It "should detect Node.js project and validate it"
        When call validate_environment "node"
        The output should include "Validating Node.js environment"
        The output should include "✅ Node.js is installed"
      End

      It "should detect Python project and validate it"
        When call validate_environment "python"
        The output should include "Validating Python environment"
        The output should include "✅ Python 3 is installed"
      End

      It "should detect Go project and validate it"
        When call validate_environment "go"
        The output should include "Validating Go environment"
        The output should include "✅ Go is installed"
      End

      It "should detect Rust project and validate it"
        When call validate_environment "rust"
        The output should include "Validating Rust environment"
        The output should include "✅ Rust is installed"
      End
    End
  End

  Describe "validate_required_var function"
    It "should succeed when variable is set"
      BeforeEach "export TEST_VAR=test_value"

      When call validate_required_var "TEST_VAR" "test variable"
      The status should be success
    End

    It "should pass when optional variable is not set"
      When call validate_required_var "UNSET_VAR" "unset variable" "false"
      The status should be success
    End

    It "should fail when required variable is not set"
      When call validate_required_var "MISSING_VAR" "missing variable" "true"
      The status should be failure
    End
  End

  Describe "validate_env_file_format function"
    It "should pass when dotenv file is valid"
      echo "VALID_VAR=valid_value" > "/tmp/validate-env-test/.env.valid"
      When call validate_env_file "/tmp/validate-env-test/.env.valid" "dotenv file"
      The status should be success
      rm -f "/tmp/validate-env-test/.env.valid"
    End

    It "should fail when dotenv file has invalid format"
      echo "^INVALID_VAR=value" > "/tmp/validate-env-test/.env.invalid"
      When call validate_env_file "/tmp/validate-env-test/.env.invalid" "dotenv file"
      The status should be failure
      rm -f "/tmp/validate-env-test/.env.invalid"
    End
  End

  Describe "get_age_key_file function"
    It "should return correct age key file path"
      BeforeEach "export MISE_SOPS_AGE_KEY_FILE=.secrets/test-age.txt"

      When call get_age_key_file
      The output should include "/tmp/validate-env-test/.secrets/test-age.txt"
    End

    It "should use default when no environment variable is set"
      BeforeEach "unset MISE_SOPS_AGE_KEY_FILE SOPS_AGE_KEY_FILE"

      When call get_age_key_file
      The output should include ".secrets/mise-age.txt"
    End
  End
End