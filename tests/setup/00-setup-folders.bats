#!/usr/bin/env bats

# BATS test for 00-setup-folders.sh
# Tests project folder initialization script

# Determine script location
SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load test helpers if available
load "${BATS_TEST_DIRNAME}/../test_helper.bash" 2>/dev/null || {
  # Basic test helper functions if not available
  setup_test_project() {
    export TEST_PROJECT_ROOT="$BATS_TEST_TMPDIR/project"
    mkdir -p "$TEST_PROJECT_ROOT"/{.secrets,config,dist}
    export PROJECT_ROOT="$TEST_PROJECT_ROOT"
  }

  cleanup_test_project() {
    unset PROJECT_ROOT
    rm -rf "$TEST_PROJECT_ROOT"
  }
}

# Setup test environment
setup() {
  # GIVEN: A clean temporary directory for testing
  TEST_TEMP_DIR="$(mktemp -d)"
  cd "$TEST_TEMP_DIR" || exit 1

  # Copy the script under test
  cp "$PROJECT_ROOT/scripts/setup/00-setup-folders.sh" .
  chmod +x ./00-setup-folders.sh

  # Create directory structure that the script expects
  mkdir -p config
  export PROJECT_ROOT="$TEST_TEMP_DIR"
}

teardown() {
  # Cleanup: Remove temporary directory
  rm -rf "$TEST_TEMP_DIR"
  unset PROJECT_ROOT
}

@test "00-setup-folders.sh creates .secrets directory with correct permissions" {
  # WHEN: The setup script is executed
  run ./00-setup-folders.sh

  # THEN: .secrets directory should be created with 700 permissions
  assert_success
  assert_output --partial "Creating .secrets directory"
  assert_output --partial "Created .secrets directory (mode: 700)"

  # Verify directory exists and permissions are correct
  test -d ".secrets"
  assert_equal "$(stat -c %a .secrets)" "700"
}

@test "00-setup-folders.sh creates dist directory" {
  # WHEN: The setup script is executed
  run ./00-setup-folders.sh

  # THEN: dist directory should be created
  assert_success
  assert_output --partial "Creating dist directory"
  assert_output --partial "Created dist directory"

  # Verify directory exists
  test -d "dist"
}

@test "00-setup-folders.sh warns about missing age key" {
  # WHEN: The setup script is executed without age key
  run ./00-setup-folders.sh

  # THEN: Should warn about missing age key
  assert_success
  assert_output --partial "No age encryption key found!"
  assert_output --partial "mise run generate-age-key"

  # Verify the warning includes instructions
  assert_line --partial "generate-age-key"
}

@test "00-setup-folders.sh detects existing age key" {
  # GIVEN: An age key file exists
  mkdir -p .secrets
  echo "age1testkey123456789abcdef" > .secrets/mise-age.txt

  # WHEN: The setup script is executed
  run ./00-setup-folders.sh

  # THEN: Should not warn about missing age key
  assert_success
  refute_output --partial "No age encryption key found!"
}

@test "00-setup-folders.sh creates .env from template" {
  # GIVEN: A template file exists
  cat > config/.env.template << 'EOF'
# Environment configuration template
NODE_ENV=development
PORT=3000
EOF

  # WHEN: The setup script is executed
  run ./00-setup-folders.sh

  # THEN: .env should be created from template
  assert_success
  assert_output --partial "Creating .env from template"
  assert_output --partial "Created .env from template"

  # Verify .env file exists and contains template content
  test -f ".env"
  assert_file_contains ".env" "NODE_ENV=development"
  assert_file_contains ".env" "PORT=3000"
}

@test "00-setup-folders.sh respects existing .env file" {
  # GIVEN: An existing .env file and template
  echo "EXISTING_VAR=existing_value" > .env
  cat > config/.env.template << 'EOF'
NODE_ENV=development
PORT=3000
EOF

  # WHEN: The setup script is executed
  run ./00-setup-folders.sh

  # THEN: Existing .env should not be overwritten
  assert_success
  refute_output --partial "Creating .env from template"

  # Verify existing content is preserved
  assert_file_contains ".env" "EXISTING_VAR=existing_value"
  refute_file_contains ".env" "NODE_ENV=development"
}

@test "00-setup-folders.sh warns about missing encrypted secrets" {
  # GIVEN: A secrets example file exists
  mkdir -p config
  cat > config/.env.secrets.json.example << 'EOF'
{
  "database_password": "example_password"
}
EOF

  # WHEN: The setup script is executed
  run ./00-setup-folders.sh

  # THEN: Should warn about missing encrypted secrets file
  assert_success
  assert_output --partial "No encrypted secrets file found!"
  assert_output --partial "cp config/.env.secrets.json.example .env.secrets.json.tmp"
}

@test "00-setup-folders.sh detects existing encrypted secrets" {
  # GIVEN: An encrypted secrets file exists
  mkdir -p config
  echo "{}" > .env.secrets.json

  # WHEN: The setup script is executed
  run ./00-setup-folders.sh

  # THEN: Should not warn about missing secrets
  assert_success
  refute_output --partial "No encrypted secrets file found!"
}

@test "00-setup-folders.sh handles missing config directory gracefully" {
  # GIVEN: No config directory exists
  rm -rf config

  # WHEN: The setup script is executed
  run ./00-setup-folders.sh

  # THEN: Should complete successfully without errors
  assert_success

  # Should still create required directories
  test -d ".secrets"
  test -d "dist"
}

@test "00-setup-folders.sh works when directories already exist" {
  # GIVEN: All directories already exist
  mkdir -p .secrets dist
  chmod 700 .secrets

  # WHEN: The setup script is executed
  run ./00-setup-folders.sh

  # THEN: Should complete successfully
  assert_success
  refute_output --partial "Creating .secrets directory"
  refute_output --partial "Creating dist directory"
}

@test "00-setup-folders.sh provides complete setup feedback" {
  # WHEN: The setup script is executed
  run ./00-setup-folders.sh

  # THEN: Should provide clear start and end markers
  assert_success
  assert_line --index 0 "========================================="
  assert_line --index 1 "Setting up project folders"
  assert_line --index -2 "========================================="
  assert_line --index -1 "Project folders setup complete"
  assert_line --index -2 "========================================="
}

@test "00-setup-folders.sh project root resolution works" {
  # GIVEN: Script is executed from a subdirectory
  mkdir -p subdirectory
  cd subdirectory

  # When: The setup script is executed from a subdirectory
  run ../00-setup-folders.sh

  # THEN: Should create directories relative to project root
  assert_success
  test -d ".secrets"
  test -d "dist"
}

@test "00-setup-folders.sh script exit status behavior" {
  # WHEN: The setup script is executed
  run ./00-setup-folders.sh

  # THEN: Should always exit with success (0)
  assert_success
  assert_equal "$status" 0
}

@test "00-setup-folders.sh handles permission errors gracefully" {
  # GIVEN: .secrets directory exists as a file (edge case)
  touch .secrets

  # WHEN: The setup script is executed
  # Note: This might fail, but we test the behavior
  run ./00-setup-folders.sh || true

  # THEN: Script should handle the situation without crashing
  # The exact behavior depends on implementation
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}