#!/usr/bin/env bash
# ShellSpec tests for Config Library
# Tests the config.sh library functionality

set -euo pipefail

# Setup test environment
setup_test_environment() {
  export TEMP_DIR="/tmp/config-test-$$"
  mkdir -p "$TEMP_DIR/.deployments"
  mkdir -p "$TEMP_DIR/scripts/lib"

  # Mock common.sh since config.sh sources it
  touch "$TEMP_DIR/scripts/lib/common.sh"

  # Mock PROJECT_ROOT to point to our temp dir
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
# We use a function to source it so we can control the environment before sourcing
load_lib() {
  # Use PWD or SHELLSPEC_PROJECT_ROOT to find the library
  local project_root="${SHELLSPEC_PROJECT_ROOT:-$PWD}"
  # shellcheck disable=SC1090
  . "${project_root}/scripts/lib/config.sh"
}

Describe "Config Library"
BeforeEach "setup_test_environment"
AfterEach "cleanup_test_environment"

Describe "initialization"
It "should export default variables"
When call load_lib
The variable CI_VERSION should equal "1.0.0"
The variable CI_LOG_LEVEL should equal "info"
End
End

Describe "deployment management"
Include "scripts/lib/config.sh"

Describe "generate_deployment_id"
It "should generate an ID with deploy prefix"
When call generate_deployment_id
The output should match pattern "deploy-??????????????-??????"
End
End

Describe "create_deployment_record"
It "should create a deployment JSON file"
local id="deploy-test-123"
When call create_deployment_record "$id" "prod" "us-east-1" "abcdef123456"
The path "$TEMP_DIR/.deployments/$id.json" should be exist
The contents of file "$TEMP_DIR/.deployments/$id.json" should include '"status": "pending"'
The contents of file "$TEMP_DIR/.deployments/$id.json" should include '"environment": "prod"'
End
End

Describe "deployment_exists"
It "should return success if deployment exists"
local id="deploy-exists-123"
touch "$TEMP_DIR/.deployments/$id.json"
When call deployment_exists "$id"
The status should be success
End

It "should return failure if deployment does not exist"
When call deployment_exists "non-existent"
The status should be failure
End
End

Describe "set_deployment_status"
It "should update status in the json file"
local id="deploy-status-123"
# Create initial record
echo '{"status": "pending", "message": ""}' >"$TEMP_DIR/.deployments/$id.json"

When call set_deployment_status "$id" "success" "All good"
The contents of file "$TEMP_DIR/.deployments/$id.json" should include '"status": "success"'
The contents of file "$TEMP_DIR/.deployments/$id.json" should include '"message": "All good"'
End
End

Describe "get_deployment_status"
It "should retrieve the status"
local id="deploy-get-status-123"
echo '{"status": "failed"}' >"$TEMP_DIR/.deployments/$id.json"

When call get_deployment_status "$id"
The output should equal "failed"
End

It "should return unknown for missing file"
When call get_deployment_status "missing-id"
The output should equal "unknown"
End
End
End
End
