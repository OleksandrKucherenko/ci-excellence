#!/usr/bin/env bash
# ShellSpec tests for CI Install Dependencies Script
# Tests the 10-ci-install-deps.sh script functionality

set -euo pipefail

# Load the script under test
# shellcheck disable=SC1090,SC1091
. "$(dirname "$0")/../../../scripts/setup/10-ci-install-deps.sh" 2>/dev/null || {
  echo "Failed to source 10-ci-install-deps.sh" >&2
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

# Mock package manager commands
mock_package_managers() {
  # Mock npm
  npm() {
    case "$1" in
      "ci")
        echo "npm ci mock called with: $*"
        if [[ "${CI_INSTALL_DEPS_BEHAVIOR:-}" == "FAIL" ]]; then
          echo "Mock npm ci failure" >&2
          return 1
        elif [[ "${CI_INSTALL_DEPS_BEHAVIOR:-}" == "TIMEOUT" ]]; then
          echo "Mock npm ci timeout" >&2
          sleep 5
          return 124
        fi
        echo "npm ci completed successfully"
        ;;
      "version")
        echo "9.8.1"
        ;;
      *)
        echo "npm mock called with: $*"
        ;;
    esac
  }

  # Mock bun
  bun() {
    case "$1" in
      "install")
        echo "bun install mock called with: $*"
        if [[ "${CI_INSTALL_DEPS_BEHAVIOR:-}" == "FAIL" ]]; then
          echo "Mock bun install failure" >&2
          return 1
        fi
        echo "bun install completed successfully"
        ;;
      "version")
        echo "1.1.8"
        ;;
      *)
        echo "bun mock called with: $*"
        ;;
    esac
  }

  # Mock yarn
  yarn() {
    case "$1" in
      "install")
        echo "yarn install mock called with: $*"
        if [[ "${CI_INSTALL_DEPS_BEHAVIOR:-}" == "FAIL" ]]; then
          echo "Mock yarn install failure" >&2
          return 1
        fi
        echo "yarn install completed successfully"
        ;;
      "--version")
        echo "1.22.19"
        ;;
      *)
        echo "yarn mock called with: $*"
        ;;
    esac
  }

  # Mock pnpm
  pnpm() {
    case "$1" in
      "install")
        echo "pnpm install mock called with: $*"
        if [[ "${CI_INSTALL_DEPS_BEHAVIOR:-}" == "FAIL" ]]; then
          echo "Mock pnpm install failure" >&2
          return 1
        fi
        echo "pnpm install completed successfully"
        ;;
      "--version")
        echo "8.6.12"
        ;;
      *)
        echo "pnpm mock called with: $*"
        ;;
    esac
  }

  # Mock pip
  pip() {
    case "$1" in
      "install")
        echo "pip install mock called with: $*"
        if [[ "${CI_INSTALL_DEPS_BEHAVIOR:-}" == "FAIL" ]]; then
          echo "Mock pip install failure" >&2
          return 1
        fi
        echo "pip install completed successfully"
        ;;
      "--version")
        echo "pip 23.2.1"
        ;;
      *)
        echo "pip mock called with: $*"
        ;;
    esac
  }

  # Mock pip3
  pip3() {
    pip "$@"
  }

  # Mock go
  go() {
    case "$1" in
      "mod")
        case "$2" in
          "download")
            echo "go mod download mock called"
            if [[ "${CI_INSTALL_DEPS_BEHAVIOR:-}" == "FAIL" ]]; then
              echo "Mock go mod download failure" >&2
              return 1
            fi
            echo "go mod download completed successfully"
            ;;
          "verify")
            echo "go mod verify mock called"
            if [[ "${CI_INSTALL_DEPS_BEHAVIOR:-}" == "FAIL" ]]; then
              echo "Mock go mod verify failure" >&2
              return 1
            fi
            echo "go mod verify completed successfully"
            ;;
          *)
            echo "go mod $2 mock called"
            ;;
        esac
        ;;
      "version")
        echo "go version go1.21.0 linux/amd64"
        ;;
      *)
        echo "go mock called with: $*"
        ;;
    esac
  }

  # Mock cargo
  cargo() {
    case "$1" in
      "check")
        echo "cargo check mock called"
        ;;
      "build")
        echo "cargo build mock called"
        ;;
      "--version")
        echo "cargo 1.71.0"
        ;;
      *)
        echo "cargo mock called with: $*"
        ;;
    esac
  }
}

# Setup test environment
setup_test_environment() {
  # Create test directory
  mkdir -p "/tmp/install-deps-test"

  # Set test environment variables
  export CI_INSTALL_DEPS_BEHAVIOR="${CI_INSTALL_DEPS_BEHAVIOR:-EXECUTE}"
  export CI_TEST_MODE="${CI_TEST_MODE:-EXECUTE}"

  # Mock common functions
  mock_common_functions

  # Mock package managers
  mock_package_managers

  # Mock package-lock.json
  echo '{"name": "test-project", "version": "1.0.0"}' > "/tmp/install-deps-test/package-lock.json"
  echo '{"name": "test-project", "version": "1.0.0"}' > "/tmp/install-deps-test/yarn.lock"
  echo '{"lockfileVersion": 6, "packages": {}}' > "/tmp/install-deps-test/pnpm-lock.yaml"
  echo 'module test_project' > "/tmp/install-deps-test/go.mod"

  # Mock requirements.txt
  echo 'requests==2.31.0' > "/tmp/install-deps-test/requirements.txt"
  echo 'pytest==7.4.0' >> "/tmp/install-deps-test/requirements.txt"

  # Mock Cargo.toml
  cat > "/tmp/install-deps-test/Cargo.toml" << EOF
[package]
name = "test_project"
version = "0.1.0"
edition = "2021"
EOF
}

# Cleanup test environment
cleanup_test_environment() {
  rm -rf "/tmp/install-deps-test"
}

Describe "CI Install Dependencies Script"
  BeforeEach "setup_test_environment"
  AfterEach "cleanup_test_environment"

  Describe "behavior mode handling"
    Context "when CI_INSTALL_DEPS_BEHAVIOR is DRY_RUN"
      BeforeEach "export CI_INSTALL_DEPS_BEHAVIOR=DRY_RUN"

      It "should run in dry run mode"
        When call install_dependencies "node"
        The output should include "🔍 DRY RUN: Would install dependencies for node"
      End
    End

    Context "when CI_INSTALL_DEPS_BEHAVIOR is PASS"
      BeforeEach "export CI_INSTALL_DEPS_BEHAVIOR=PASS"

      It "should simulate successful dependency installation"
        When call install_dependencies "node"
        The output should include "PASS MODE: Dependencies installation simulated successfully"
      End
    End

    Context "when CI_INSTALL_DEPS_BEHAVIOR is FAIL"
      BeforeEach "export CI_INSTALL_DEPS_BEHAVIOR=FAIL"

      It "should simulate dependency installation failure"
        When call install_dependencies "node"
        The output should include "FAIL MODE: Simulating dependencies installation failure"
        The status should be failure
      End
    End

    Context "when CI_INSTALL_DEPS_BEHAVIOR is SKIP"
      BeforeEach "export CI_INSTALL_DEPS_BEHAVIOR=SKIP"

      It "should skip dependency installation"
        When call install_dependencies "node"
        The output should include "SKIP MODE: Dependencies installation skipped"
      End
    End

    Context "when CI_INSTALL_DEPS_BEHAVIOR is TIMEOUT"
      BeforeEach "export CI_INSTALL_DEPS_BEHAVIOR=TIMEOUT"

      It "should simulate timeout"
        When run timeout 10s install_dependencies "node"
        The output should include "TIMEOUT MODE: Simulating dependencies installation timeout"
        The status should be timeout
      End
    End
  End

  Describe "EXECUTE mode functionality"
    BeforeEach "export CI_INSTALL_DEPS_BEHAVIOR=EXECUTE"
    BeforeEach "cd /tmp/install-deps-test"

    Context "when installing Node.js dependencies"
      It "should detect package manager and install dependencies"
        When call install_dependencies "node"
        The output should include "Installing Node.js dependencies"
        The output should include "npm ci completed successfully"
      End

      It "should use npm when package-lock.json exists"
        When call install_dependencies "node"
        The output should include "Using npm (package-lock.json found)"
      End

      It "should use yarn when yarn.lock exists and no package-lock.json"
        BeforeEach "rm -f package-lock.json"
        When call install_dependencies "node"
        The output should include "Using yarn (yarn.lock found)"
      End

      It "should use pnpm when pnpm-lock.yaml exists and no other lock files"
        BeforeEach "rm -f package-lock.json yarn.lock"
        When call install_dependencies "node"
        The output should include "Using pnpm (pnpm-lock.yaml found)"
      End

      It "should use bun when bun.lockb exists"
        BeforeEach "echo '{}' > bun.lockb && rm -f package-lock.json yarn.lock pnpm-lock.yaml"
        When call install_dependencies "node"
        The output should include "Using bun (bun.lockb found)"
      End

      It "should use npm as default when no lock files exist"
        BeforeEach "rm -f package-lock.json yarn.lock pnpm-lock.yaml bun.lockb"
        When call install_dependencies "node"
        The output should include "Using npm (default)"
      End
    End

    Context "when installing Python dependencies"
      It "should install Python dependencies with pip"
        When call install_dependencies "python"
        The output should include "Installing Python dependencies"
        The output should include "pip install completed successfully"
      End

      It "should use pip3 when available"
        When call install_dependencies "python"
        The output should include "Using pip3 for dependency installation"
      End
    End

    Context "when installing Go dependencies"
      It "should install Go dependencies"
        When call install_dependencies "go"
        The output should include "Installing Go dependencies"
        The output should include "go mod download completed successfully"
        The output should include "go mod verify completed successfully"
      End

      Context "when installing Rust dependencies"
      It "should install Rust dependencies"
        When call install_dependencies "rust"
        The output should include "Installing Rust dependencies"
        The output should include "cargo check completed successfully"
      End

      Context "when project type is not recognized"
      It "should handle unknown project types gracefully"
        When call install_dependencies "unknown"
        The output should include "No dependency installation required for: unknown"
      End
    End

    Context "when dependency installation fails"
      It "should handle installation failures gracefully"
        BeforeEach "export CI_INSTALL_DEPS_BEHAVIOR=FAIL"

        When call install_dependencies "node"
        The output should include "❌ Dependency installation failed for: node"
        The status should be failure
      End
    End

    Context "when installing dependencies for specified directory"
      It "should change to specified directory"
        mkdir -p "/tmp/install-deps-test/subdir"
        BeforeEach "cd /tmp"

        When call install_dependencies "node" "/tmp/install-deps-test/subdir"
        The output should include "Installing Node.js dependencies in: /tmp/install-deps-test/subdir"
      End
    End
  End

  Describe "detect_package_manager function"
    BeforeEach "cd /tmp/install-deps-test"

    It "should detect npm when package-lock.json exists"
      When call detect_package_manager
      The output should equal "npm"
    End

    It "should detect yarn when yarn.lock exists and no package-lock.json"
      BeforeEach "rm -f package-lock.json"
      When call detect_package_manager
      The output should equal "yarn"
    End

    It "should detect pnpm when pnpm-lock.yaml exists and no other lock files"
      BeforeEach "rm -f package-lock.json yarn.lock"
      When call detect_package_manager
      The output should equal "pnpm"
    End

    It "should detect bun when bun.lockb exists and no other lock files"
      BeforeEach "rm -f package-lock.json yarn.lock pnpm-lock.yaml && echo '{}' > bun.lockb"
      When call detect_package_manager
      The output should equal "bun"
    End

    It "should default to npm when no lock files exist"
      BeforeEach "rm -f package-lock.json yarn.lock pnpm-lock.yaml bun.lockb"
      When call detect_package_manager
      The output should equal "npm"
    End
  End

  Describe "get_dependency_list function"
    BeforeEach "export CI_INSTALL_DEPS_BEHAVIOR=EXECUTE"
    BeforeEach "cd /tmp/install-deps-test"

    Context "for Node.js projects"
      It "should return empty list when using npm ci"
        When call get_dependency_list "node"
        The output should equal ""
      End
    End

    Context "for Python projects"
      It "should return requirements file when exists"
        When call get_dependency_list "python"
        The output should include "requirements.txt"
      End
    End

    Context "for Go projects"
      It "should return empty list for go mod download"
        When call get_dependency_list "go"
        The output should equal ""
      End
    End
  End

  Describe "validate_project_directory function"
    It "should succeed when directory exists"
      When call validate_project_directory "/tmp/install-deps-test"
      The status should be success
    End

    It "should fail when directory doesn't exist"
      When call validate_project_directory "/tmp/nonexistent-directory"
      The status should be failure
    End
  End

  Describe "project type detection"
    BeforeEach "cd /tmp/install-deps-test"

    It "should detect Node.js project from package.json"
      echo '{"name": "test"}' > package.json
      When call detect_project_type
      The output should equal "node"
    End

    It "should detect Python project from requirements.txt"
      When call detect_project_type
      The output should equal "python"
    End

    It "should detect Go project from go.mod"
      When call detect_project_type
      The output should equal "go"
    End

    It "should detect Rust project from Cargo.toml"
      When call detect_project_type
      The output should equal "rust"
    End

    It "should return unknown when no known indicators found"
      BeforeEach "rm -f package.json requirements.txt go.mod Cargo.toml"
      When call detect_project_type
      The output should equal "unknown"
    End
  End
End