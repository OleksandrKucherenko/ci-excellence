#!/usr/bin/env bash
# ShellSpec tests for Deployment Library

set -euo pipefail

# Setup test environment
setup_test_environment() {
  export TEMP_DIR="/tmp/deployment-test-$$"
  mkdir -p "$TEMP_DIR/.reports"
  mkdir -p "$TEMP_DIR/scripts/lib"

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

  # Source dependencies
  # Mock logging functions if they are not loaded (simple echo for testing)
  log_info() { echo "INFO: $*"; }
  log_error() { echo "ERROR: $*"; }
  log_success() { echo "SUCCESS: $*"; }
  log_warn() { echo "WARN: $*"; }
  log_debug() { echo "DEBUG: $*"; }

  # shellcheck disable=SC1090
  . "${project_root}/scripts/lib/deployment.sh"
}

Describe "Deployment Library"
BeforeEach "setup_test_environment"
AfterEach "cleanup_test_environment"

Describe "generate_deployment_report"
It "should generate a JSON report file"
load_lib

local id="deploy-report-123"
When call generate_deployment_report "$id" "prod" "us-east-1" "success"

The output should include "Generating deployment report"
The path "$TEMP_DIR/.reports/deployment-$id.json" should be exist
The contents of file "$TEMP_DIR/.reports/deployment-$id.json" should include '"status": "success"'
The contents of file "$TEMP_DIR/.reports/deployment-$id.json" should include '"deployment_id": "deploy-report-123"'
End
End

Describe "check_infrastructure_health"
It "should pass when AWS is mocked and successful"
load_lib

# Mock aws command
aws() { return 0; }
export CLOUD_PROVIDER="aws"

When call check_infrastructure_health "prod" "us-east-1"
The status should be success
The output should include "Infrastructure health check passed"
End

It "should fail when AWS authentication fails"
load_lib

# Mock aws command to fail on identity check
aws() {
  if [[ "$*" == *"sts get-caller-identity"* ]]; then
    return 1
  fi
  return 0
}
export CLOUD_PROVIDER="aws"

When call check_infrastructure_health "prod" "us-east-1"
The status should be failure
The output should include "AWS authentication failed"
End
End

Describe "run_smoke_tests"
It "should pass when curl returns 200"
load_lib

# Mock get_environment_url (it is called inside)
get_environment_url() { echo "http://example.com"; }

# Mock curl
curl() { echo "200"; }

When call run_smoke_tests "prod" "us-east-1"
The status should be success
The output should include "Smoke test passed"
End

It "should fail when curl returns 500"
load_lib

get_environment_url() { echo "http://example.com"; }
curl() { echo "500"; }

When call run_smoke_tests "prod" "us-east-1"
The status should be failure
The output should include "Smoke test failed"
End
End
End
