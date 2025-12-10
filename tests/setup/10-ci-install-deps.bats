#!/usr/bin/env bats

# BATS test for 10-ci-install-deps.sh
# Tests CI dependency installation script

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
  cp "$PROJECT_ROOT/scripts/setup/10-ci-install-deps.sh" .
  chmod +x ./10-ci-install-deps.sh

  # Set project root for the script
  export PROJECT_ROOT="$TEST_TEMP_DIR"
  export SCRIPT_ROOT="$TEST_TEMP_DIR/scripts"

  # Create mock commands for package managers
  create_mock_package_managers
}

# Create mock package manager commands
create_mock_package_managers() {
  local mock_bin="$TEST_TEMP_DIR/bin"

  # Mock npm
  cat > "$mock_bin/npm" << 'EOF'
#!/bin/bash
case "$1" in
  "ci")
    if [[ "${FAIL_NPM:-false}" == "true" ]]; then
      echo "npm ci failed" >&2
      exit 1
    fi
    echo "npm ci successful"
    ;;
  "install")
    if [[ "${FAIL_NPM:-false}" == "true" ]]; then
      echo "npm install failed" >&2
      exit 1
    fi
    echo "npm install successful"
    ;;
  "--version")
    echo "9.0.0"
    ;;
  *)
    echo "npm $*"
    ;;
esac
EOF
  chmod +x "$mock_bin/npm"

  # Mock yarn
  cat > "$mock_bin/yarn" << 'EOF'
#!/bin/bash
if [[ "${FAIL_YARN:-false}" == "true" ]]; then
  echo "yarn install failed" >&2
  exit 1
fi
echo "yarn install successful"
EOF
  chmod +x "$mock_bin/yarn"

  # Mock pnpm
  cat > "$mock_bin/pnpm" << 'EOF'
#!/bin/bash
if [[ "${FAIL_PNPM:-false}" == "true" ]]; then
  echo "pnpm install failed" >&2
  exit 1
fi
echo "pnpm install successful"
EOF
  chmod +x "$mock_bin/pnpm"

  # Mock bun
  cat > "$mock_bin/bun" << 'EOF'
#!/bin/bash
if [[ "${FAIL_BUN:-false}" == "true" ]]; then
  echo "bun install failed" >&2
  exit 1
fi
echo "bun install successful"
EOF
  chmod +x "$mock_bin/bun"

  # Mock pip/pip3
  cat > "$mock_bin/pip" << 'EOF'
#!/bin/bash
case "$1" in
  "install")
    if [[ "${FAIL_PIP:-false}" == "true" ]]; then
      echo "pip install failed" >&2
      exit 1
    fi
    echo "pip install successful"
    ;;
  "--version")
    echo "pip 23.0.0"
    ;;
  *)
    echo "pip $*"
    ;;
esac
EOF
  chmod +x "$mock_bin/pip"

  cat > "$mock_bin/pip3" << 'EOF'
#!/bin/bash
case "$1" in
  "install")
    if [[ "${FAIL_PIP:-false}" == "true" ]]; then
      echo "pip3 install failed" >&2
      exit 1
    fi
    echo "pip3 install successful"
    ;;
  "--version")
    echo "pip3 23.0.0"
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
  "mod")
    case "$2" in
      "download")
        if [[ "${FAIL_GO:-false}" == "true" ]]; then
          echo "go mod download failed" >&2
          exit 1
        fi
        echo "go mod download successful"
        ;;
      "verify")
        if [[ "${FAIL_GO_VERIFY:-false}" == "true" ]]; then
          echo "go mod verify failed" >&2
          exit 1
        fi
        echo "go mod verify successful"
        ;;
      *)
        echo "go mod $2"
        ;;
    esac
    ;;
  "version")
    echo "go version go1.21.0"
    ;;
  *)
    echo "go $*"
    ;;
esac
EOF
  chmod +x "$mock_bin/go"

  # Mock cargo
  cat > "$mock_bin/cargo" << 'EOF'
#!/bin/bash
if [[ "${FAIL_CARGO:-false}" == "true" ]]; then
  echo "cargo check failed" >&2
  exit 1
fi
echo "cargo check successful"
EOF
  chmod +x "$mock_bin/cargo"

  # Mock mvn
  cat > "$mock_bin/mvn" << 'EOF'
#!/bin/bash
if [[ "${FAIL_MAVEN:-false}" == "true" ]]; then
  echo "Maven install failed" >&2
  exit 1
fi
echo "Maven install successful"
EOF
  chmod +x "$mock_bin/mvn"

  # Mock gradle
  cat > "$mock_bin/gradle" << 'EOF'
#!/bin/bash
if [[ "${FAIL_GRADLE:-false}" == "true" ]]; then
  echo "Gradle build failed" >&2
  exit 1
fi
echo "Gradle build successful"
EOF
  chmod +x "$mock_bin/gradle"

  # Mock dotnet
  cat > "$mock_bin/dotnet" << 'EOF'
#!/bin/bash
if [[ "${FAIL_DOTNET:-false}" == "true" ]]; then
  echo "dotnet restore failed" >&2
  exit 1
fi
echo "dotnet restore successful"
EOF
  chmod +x "$mock_bin/dotnet"
}

teardown() {
  # Cleanup: Remove temporary directory
  rm -rf "$TEST_TEMP_DIR"
  unset PROJECT_ROOT SCRIPT_ROOT CI_TEST_MODE
  unset FAIL_NPM FAIL_YARN FAIL_PNPM FAIL_BUN FAIL_PIP FAIL_GO FAIL_CARGO FAIL_MAVEN FAIL_GRADLE FAIL_DOTNET
}

@test "detect_project_type correctly identifies Node.js projects" {
  # GIVEN: A Node.js project with package.json
  cat > package.json << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0"
}
EOF

  # WHEN: We source the script and call detect_project_type
  source ./10-ci-install-deps.sh
  run detect_project_type

  # THEN: Should identify as node project
  assert_success
  assert_output "node"
}

@test "detect_project_type correctly identifies Python projects" {
  # GIVEN: A Python project with requirements.txt
  cat > requirements.txt << 'EOF'
flask>=2.0.0
requests>=2.25.0
EOF

  # WHEN: We source the script and call detect_project_type
  source ./10-ci-install-deps.sh
  run detect_project_type

  # THEN: Should identify as python project
  assert_success
  assert_output "python"
}

@test "detect_project_type correctly identifies Go projects" {
  # GIVEN: A Go project with go.mod
  cat > go.mod << 'EOF'
module github.com/example/test

go 1.21
EOF

  # WHEN: We source the script and call detect_project_type
  source ./10-ci-install-deps.sh
  run detect_project_type

  # THEN: Should identify as go project
  assert_success
  assert_output "go"
}

@test "detect_project_type correctly identifies Rust projects" {
  # GIVEN: A Rust project with Cargo.toml
  cat > Cargo.toml << 'EOF'
[package]
name = "test-project"
version = "0.1.0"
edition = "2021"

[dependencies]
EOF

  # WHEN: We source the script and call detect_project_type
  source ./10-ci-install-deps.sh
  run detect_project_type

  # THEN: Should identify as rust project
  assert_success
  assert_output "rust"
}

@test "detect_project_type correctly identifies Java projects" {
  # GIVEN: A Java project with pom.xml
  cat > pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project>
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.example</groupId>
  <artifactId>test-project</artifactId>
  <version>1.0.0</version>
</project>
EOF

  # WHEN: We source the script and call detect_project_type
  source ./10-ci-install-deps.sh
  run detect_project_type

  # THEN: Should identify as java project
  assert_success
  assert_output "java"
}

@test "detect_package_manager correctly identifies npm" {
  # GIVEN: A Node.js project with package-lock.json
  cat > package.json << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0"
}
EOF
  touch package-lock.json

  # WHEN: We source the script and call detect_package_manager
  source ./10-ci-install-deps.sh
  run detect_package_manager

  # THEN: Should identify npm
  assert_success
  assert_output "npm"
}

@test "detect_package_manager correctly identifies yarn" {
  # GIVEN: A Node.js project with yarn.lock
  cat > package.json << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0"
}
EOF
  touch yarn.lock

  # WHEN: We source the script and call detect_package_manager
  source ./10-ci-install-deps.sh
  run detect_package_manager

  # THEN: Should identify yarn
  assert_success
  assert_output "yarn"
}

@test "detect_package_manager correctly identifies pnpm" {
  # GIVEN: A Node.js project with pnpm-lock.yaml
  cat > package.json << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0"
}
EOF
  touch pnpm-lock.yaml

  # WHEN: We source the script and call detect_package_manager
  source ./10-ci-install-deps.sh
  run detect_package_manager

  # THEN: Should identify pnpm
  assert_success
  assert_output "pnpm"
}

@test "detect_package_manager correctly identifies bun" {
  # GIVEN: A Node.js project with bun.lockb
  cat > package.json << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0"
}
EOF
  touch bun.lockb

  # WHEN: We source the script and call detect_package_manager
  source ./10-ci-install-deps.sh
  run detect_package_manager

  # THEN: Should identify bun
  assert_success
  assert_output "bun"
}

@test "install_node_dependencies succeeds with npm" {
  # GIVEN: A Node.js project with package-lock.json
  cat > package.json << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0"
}
EOF
  touch package-lock.json

  # WHEN: We source the script and call install_node_dependencies
  source ./10-ci-install-deps.sh
  run install_node_dependencies

  # THEN: Should install successfully with npm
  assert_success
  assert_output --partial "Using npm (package-lock.json found)"
  assert_output --partial "npm ci successful"
  assert_output --partial "Node.js dependencies installed successfully"
}

@test "install_node_dependencies succeeds with yarn" {
  # GIVEN: A Node.js project with yarn.lock
  cat > package.json << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0"
}
EOF
  touch yarn.lock

  # WHEN: We source the script and call install_node_dependencies
  source ./10-ci-install-deps.sh
  run install_node_dependencies

  # THEN: Should install successfully with yarn
  assert_success
  assert_output --partial "Using yarn (yarn.lock found)"
  assert_output --partial "yarn install successful"
  assert_output --partial "Node.js dependencies installed successfully"
}

@test "install_node_dependencies handles npm failure" {
  # GIVEN: A Node.js project and npm is set to fail
  cat > package.json << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0"
}
EOF
  touch package-lock.json
  export FAIL_NPM=true

  # WHEN: We source the script and call install_node_dependencies
  source ./10-ci-install-deps.sh
  run install_node_dependencies

  # THEN: Should fail gracefully
  assert_failure
  assert_output --partial "npm ci failed"
}

@test "install_python_dependencies succeeds with pip3" {
  # GIVEN: A Python project with requirements.txt
  cat > requirements.txt << 'EOF'
flask>=2.0.0
requests>=2.25.0
EOF

  # WHEN: We source the script and call install_python_dependencies
  source ./10-ci-install-deps.sh
  run install_python_dependencies

  # THEN: Should install successfully with pip3
  assert_success
  assert_output --partial "Using pip3 for dependency installation"
  assert_output --partial "pip3 install successful"
  assert_output --partial "Python dependencies installed successfully"
}

@test "install_python_dependencies handles missing requirements file" {
  # GIVEN: A Python project without requirements files
  # (no requirements files created)

  # WHEN: We source the script and call install_python_dependencies
  source ./10-ci-install-deps.sh
  run install_python_dependencies

  # THEN: Should warn but not fail
  assert_success
  assert_output --partial "No requirements file found, skipping Python dependency installation"
}

@test "install_go_dependencies succeeds" {
  # GIVEN: A Go project with go.mod
  cat > go.mod << 'EOF'
module github.com/example/test

go 1.21
EOF

  # WHEN: We source the script and call install_go_dependencies
  source ./10-ci-install-deps.sh
  run install_go_dependencies

  # THEN: Should install and verify successfully
  assert_success
  assert_output --partial "go mod download successful"
  assert_output --partial "go mod verify successful"
  assert_output --partial "Go dependencies installed and verified successfully"
}

@test "install_rust_dependencies succeeds" {
  # GIVEN: A Rust project with Cargo.toml
  cat > Cargo.toml << 'EOF'
[package]
name = "test-project"
version = "0.1.0"
edition = "2021"

[dependencies]
EOF

  # WHEN: We source the script and call install_rust_dependencies
  source ./10-ci-install-deps.sh
  run install_rust_dependencies

  # THEN: Should check successfully
  assert_success
  assert_output --partial "cargo check successful"
  assert_output --partial "Rust dependencies checked successfully"
}

@test "install_java_dependencies succeeds with Maven" {
  # GIVEN: A Java project with pom.xml
  cat > pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project>
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.example</groupId>
  <artifactId>test-project</artifactId>
  <version>1.0.0</version>
</project>
EOF

  # WHEN: We source the script and call install_java_dependencies
  source ./10-ci-install-deps.sh
  run install_java_dependencies

  # THEN: Should install successfully with Maven
  assert_success
  assert_output --partial "Found Maven project (pom.xml)"
  assert_output --partial "Maven install successful"
  assert_output --partial "Java dependencies installed successfully"
}

@test "install_dependencies handles DRY_RUN mode" {
  # GIVEN: CI_TEST_MODE is set to DRY_RUN
  export CI_TEST_MODE=DRY_RUN

  # WHEN: We run the main script
  run ./10-ci-install-deps.sh node

  # THEN: Should perform dry run
  assert_success
  assert_output --partial "DRY RUN: Would install dependencies for node"
}

@test "install_dependencies handles PASS mode" {
  # GIVEN: CI_TEST_MODE is set to PASS
  export CI_TEST_MODE=PASS

  # WHEN: We run the main script
  run ./10-ci-install-deps.sh node

  # THEN: Should simulate success
  assert_success
  assert_output --partial "PASS MODE: Dependencies installation simulated successfully"
}

@test "install_dependencies handles FAIL mode" {
  # GIVEN: CI_TEST_MODE is set to FAIL
  export CI_TEST_MODE=FAIL

  # WHEN: We run the main script
  run ./10-ci-install-deps.sh node

  # THEN: Should simulate failure
  assert_failure
  assert_output --partial "FAIL MODE: Simulating dependencies installation failure"
}

@test "install_dependencies handles SKIP mode" {
  # GIVEN: CI_TEST_MODE is set to SKIP
  export CI_TEST_MODE=SKIP

  # WHEN: We run the main script
  run ./10-ci-install-deps.sh node

  # THEN: Should skip installation
  assert_success
  assert_output --partial "SKIP MODE: Dependencies installation skipped"
}

@test "install_dependencies handles TIMEOUT mode" {
  # GIVEN: CI_TEST_MODE is set to TIMEOUT
  export CI_TEST_MODE=TIMEOUT

  # WHEN: We run the main script with timeout
  timeout 10s ./10-ci-install-deps.sh node

  # THEN: Should simulate timeout (exit code 124)
  assert_equal $? 124
}

@test "install_dependencies with auto-detection works for Node.js" {
  # GIVEN: A Node.js project
  cat > package.json << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0"
}
EOF
  touch package-lock.json

  # WHEN: We run the script with auto-detection
  run ./10-ci-install-deps.sh auto

  # THEN: Should auto-detect and install Node.js dependencies
  assert_success
  assert_output --partial "Auto-detected project type: node"
  assert_output --partial "Node.js dependencies installed successfully"
}

@test "validate_project_directory fails for non-existent directory" {
  # WHEN: We source the script and call validate_project_directory with non-existent dir
  source ./10-ci-install-deps.sh
  run validate_project_directory "/non/existent/directory"

  # THEN: Should fail
  assert_failure
}

@test "validate_project_directory succeeds for valid directory" {
  # WHEN: We source the script and call validate_project_directory with current dir
  source ./10-ci-install-deps.sh
  run validate_project_directory "."

  # THEN: Should succeed
  assert_success
}

@test "main script shows help when requested" {
  # WHEN: We run the script with help argument
  run ./10-ci-install-deps.sh help

  # THEN: Should show help and exit successfully
  assert_success
  assert_output --partial "CI Install Dependencies Script v1.0.0"
  assert_output --partial "Usage:"
  assert_output --partial "Supported Project Types:"
}

@test "main script shows help with --help" {
  # WHEN: We run the script with --help argument
  run ./10-ci-install-deps.sh --help

  # THEN: Should show help and exit successfully
  assert_success
  assert_output --partial "CI Install Dependencies Script v1.0.0"
}

@test "main script shows help with -h" {
  # WHEN: We run the script with -h argument
  run ./10-ci-install-deps.sh -h

  # THEN: Should show help and exit successfully
  assert_success
  assert_output --partial "CI Install Dependencies Script v1.0.0"
}

@test "main script handles unknown project type" {
  # GIVEN: No recognizable project files exist

  # WHEN: We run the script with unknown project type
  run ./10-ci-install-deps.sh unknown

  # THEN: Should fail gracefully
  assert_failure
  assert_output --partial "Unsupported project type: unknown"
}

@test "main script succeeds with unknown auto-detected project" {
  # GIVEN: No recognizable project files exist

  # WHEN: We run the script with auto-detection
  run ./10-ci-install-deps.sh auto

  # THEN: Should succeed without installing anything
  assert_success
  assert_output --partial "No dependency installation required for: unknown"
}

@test "get_dependency_list returns correct flags for Node.js package managers" {
  # WHEN: We source the script and test get_dependency_list for node
  source ./10-ci-install-deps.sh

  # Test npm (empty string for ci)
  run get_dependency_list "node"
  assert_success
  assert_output ""

  # Test other package managers would return different flags
  # This would need mocking of detect_package_manager for complete testing
}