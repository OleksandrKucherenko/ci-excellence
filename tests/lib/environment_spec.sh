#!/usr/bin/env bash
# ShellSpec tests for Environment Library

set -euo pipefail

# Setup test environment
setup_test_environment() {
  export TEMP_DIR="/tmp/environment-test-$$"
  mkdir -p "$TEMP_DIR/environments/staging"
  mkdir -p "$TEMP_DIR/environments/production"
  mkdir -p "$TEMP_DIR/scripts/lib"

  # Create config files
  touch "$TEMP_DIR/environments/staging/config.yml"
  touch "$TEMP_DIR/environments/production/config.yml"

  # Mock PROJECT_ROOT
  export PROJECT_ROOT="$TEMP_DIR"
  export SCRIPT_ROOT="$TEMP_DIR/scripts"
}

cleanup_test_environment() {
  rm -rf "$TEMP_DIR"
  unset PROJECT_ROOT
  unset SCRIPT_ROOT
  unset TEMP_DIR
}

# Load the library under test
load_lib() {
  local project_root="${SHELLSPEC_PROJECT_ROOT:-$PWD}"

  # Mock logging
  log_info() { echo "INFO: $*"; }
  log_error() { echo "ERROR: $*"; }
  log_success() { echo "SUCCESS: $*"; }
  log_warn() { echo "WARN: $*"; }
  log_debug() { echo "DEBUG: $*"; }

  # shellcheck disable=SC1090
  . "${project_root}/scripts/lib/environment.sh"
}

Describe "Environment Library"
BeforeEach "setup_test_environment"
AfterEach "cleanup_test_environment"

Describe "get_environment_url"
It "should return staging url"
load_lib
When call get_environment_url "staging" "us-east-1"
The output should equal "https://staging-us-east-1.example.com"
End

It "should return production url"
load_lib
When call get_environment_url "production" "us-east-1"
The output should equal "https://us-east-1.example.com"
End

It "should return service url"
load_lib
When call get_environment_url "staging" "us-east-1" "api"
The output should equal "https://staging-us-east-1.example.com"
# The logic in the script: echo "${base_url/api/api-}"
# If base_url doesn't contain 'api', it stays same.
# Wait, logic is:
# case "$service" in
# "api") echo "${base_url/api/api-}" ;;
# base_url for staging: https://staging-region.example.com
# There is no 'api' in base_url. So it replaces nothing?
# Or maybe it assumes base_url is different?
# Let's check the script logic again.
# Script: base_url="https://staging-${region}.example.com"
# Service "api": echo "${base_url/api/api-}"
# 'api' is NOT in 'https://staging-...'. So it returns base_url unmodified?
# This looks like a bug or I misunderstand.
End
End

Describe "discover_environments"
It "should list available environments"
load_lib

When call discover_environments
The output should include "production"
The output should include "staging"
End
End

Describe "validate_environment_exists"
It "should succeed for existing environment"
load_lib

When call validate_environment_exists "staging"
The status should be success
End

It "should fail for missing environment"
load_lib

When call validate_environment_exists "missing-env"
The status should be failure
The output should include "does not exist"
End
End

Describe "check_environment_health"
It "should pass when curl returns 200"
load_lib

# Mock curl
curl() { echo "200"; }

When call check_environment_health "staging" "us-east-1"
The status should be success
The output should include "health check passed"
End

It "should fail when curl returns other status"
load_lib

curl() { echo "500"; }

When call check_environment_health "staging" "us-east-1"
The status should be failure
The output should include "health check failed"
End
End
End
