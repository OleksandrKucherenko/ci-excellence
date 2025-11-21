#!/usr/bin/env bash
# ShellSpec helper file for CI Excellence tests

# Source the project libraries
# shellcheck source=../scripts/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../scripts/lib/common.sh"

# shellcheck source=../scripts/lib/tag-utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../scripts/lib/tag-utils.sh"

# shellcheck source=../scripts/lib/secret-utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../scripts/lib/secret-utils.sh"

# shellcheck source=../scripts/lib/config-utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../scripts/lib/config-utils.sh"

# Test helper functions
setup_test_env() {
  # Create test environment
  export TEST_MODE="EXECUTE"
  export VERBOSE=false
  export CONFIG_ENVIRONMENT="test"

  # Create test directories
  mkdir -p ".cache/test"
  mkdir -p "spec/tmp"

  # Set up test configuration
  mkdir -p "config/environments"
  cat > "config/environments/test.json" << EOF
{
  "environment": {
    "name": "test",
    "type": "test",
    "description": "Test environment for shellspec"
  },
  "application": {
    "log_level": "debug",
    "debug": true
  }
}
EOF
}

cleanup_test_env() {
  # Clean up test environment
  rm -rf ".cache/test"
  rm -rf "spec/tmp"
  rm -rf "config/environments/test.json"
}

# Mock functions for testing
mock_command() {
  local command_name="$1"
  local return_code="${2:-0}"

  # Create a mock function that returns the specified code
  eval "${command_name}() { return ${return_code}; }"
}

# Test data helpers
create_test_tag() {
  local tag_name="$1"
  local tag_message="$2"

  git tag -a "$tag_name" -m "$tag_message"
}

remove_test_tag() {
  local tag_name="$1"
  git tag -d "$tag_name" 2>/dev/null || true
}

# Configuration helpers
create_test_config() {
  local env="$1"
  local config_file="config/environments/${env}.json"

  mkdir -p "config/environments"
  cat > "$config_file" << EOF
{
  "environment": {
    "name": "$env",
    "type": "test",
    "description": "Test environment for $env"
  },
  "application": {
    "log_level": "debug",
    "debug": true
  }
}
EOF
}

# Secrets helpers
create_test_secrets() {
  local env="$1"
  local secrets_file="secrets/${env}.secrets.yaml"

  mkdir -p "secrets"
  cat > "$secrets_file" << EOF
database:
  host: test-host
  password: test-password
security:
  jwt_secret: test-jwt-secret
EOF
}

# Utility functions for assertions
assert_file_exists() {
  local file="$1"
  [[ -f "$file" ]]
}

assert_file_contains() {
  local file="$1"
  local content="$2"
  grep -q "$content" "$file"
}

assert_env_var_set() {
  local var_name="$1"
  [[ -n "${!var_name:-}" ]]
}

assert_command_succeeded() {
  local command="$1"
  eval "$command" >/dev/null 2>&1
}

# Export helper functions
export -f setup_test_env
export -f cleanup_test_env
export -f mock_command
export -f create_test_tag
export -f remove_test_tag
export -f create_test_config
export -f create_test_secrets
export -f assert_file_exists
export -f assert_file_contains
export -f assert_env_var_set
export -f assert_command_succeeded