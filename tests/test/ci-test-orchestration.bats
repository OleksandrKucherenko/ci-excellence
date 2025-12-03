#!/usr/bin/env bats
# BATS test file for CI test orchestration scripts (ci-01-unit-tests.sh, ci-02-integration-tests.sh, ci-03-e2e-tests.sh)
# Tests CI orchestration of test scripts

load "${BATS_TEST_DIRNAME}/../test_helper.bash"

# Setup function - runs before each test
setup() {
  # GIVEN: Test environment preparation
  TEST_TEMP_DIR="$(temp_make)"

  # Create mock project structure
  PROJECT_ROOT="$TEST_TEMP_DIR/project"
  mkdir -p "$PROJECT_ROOT"/{scripts/{lib,test,ci/test}}

  # Copy CI test orchestration scripts
  cp /mnt/wsl/workspace/ci-excellence/scripts/ci/test/ci-01-unit-tests.sh "$PROJECT_ROOT/scripts/ci/test/"
  cp /mnt/wsl/workspace/ci-excellence/scripts/ci/test/ci-02-integration-tests.sh "$PROJECT_ROOT/scripts/ci/test/"
  cp /mnt/wsl/workspace/ci-excellence/scripts/ci/test/ci-03-e2e-tests.sh "$PROJECT_ROOT/scripts/ci/test/"

  chmod +x "$PROJECT_ROOT/scripts/ci/test"/*.sh

  # Create mock simple test scripts
  cat > "$PROJECT_ROOT/scripts/test/unit.sh" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "========================================="
echo "Running Unit Tests"
echo "========================================="

EXIT_CODE=0

echo "✓ Unit test stub executed"
echo "  Customize this script in scripts/test/unit.sh"

if [ $EXIT_CODE -ne 0 ]; then
    echo "========================================="
    echo "⚠ Unit Tests Failed"
    echo "========================================="
    exit $EXIT_CODE
fi

echo "========================================="
echo "Unit Tests Complete"
echo "========================================="
EOF

  cat > "$PROJECT_ROOT/scripts/test/integration.sh" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "========================================="
echo "Running Integration Tests"
echo "========================================="

EXIT_CODE=0

echo "✓ Integration test stub executed"
echo "  Customize this script in scripts/test/integration.sh"

if [ $EXIT_CODE -ne 0 ]; then
    echo "========================================="
    echo "⚠ Integration Tests Failed"
    echo "========================================="
    exit $EXIT_CODE
fi

echo "========================================="
echo "Integration Tests Complete"
echo "========================================="
EOF

  cat > "$PROJECT_ROOT/scripts/test/e2e.sh" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "========================================="
echo "Running End-to-End Tests"
echo "========================================="

EXIT_CODE=0

echo "✓ E2E test stub executed"
echo "  Customize this script in scripts/test/e2e.sh"

if [ $EXIT_CODE -ne 0 ]; then
    echo "========================================="
    echo "⚠ E2E Tests Failed"
    echo "========================================="
    exit $EXIT_CODE
fi

echo "========================================="
echo "E2E Tests Complete"
echo "========================================="
EOF

  chmod +x "$PROJECT_ROOT/scripts/test"/*.sh

  # Set up PATH with mock chmod command
  MOCK_BIN="$TEST_TEMP_DIR/bin"
  mkdir -p "$MOCK_BIN"
  export PATH="$MOCK_BIN:$PATH"

  # Mock chmod command
  cat > "$MOCK_BIN/chmod" << 'EOF'
#!/bin/bash
echo "chmod $*"
exit 0
EOF
  chmod +x "$MOCK_BIN/chmod"

  cd "$PROJECT_ROOT"
}

# Teardown function - runs after each test
teardown() {
  temp_del "$TEST_TEMP_DIR"
}

@test "ci-01-unit-tests.sh script makes test scripts executable and runs unit tests" {
  # WHEN: CI unit test orchestration script is executed
  run "$PROJECT_ROOT/scripts/ci/test/ci-01-unit-tests.sh"

  # THEN: Script makes scripts executable and runs unit tests
  assert_success
  assert_line --partial "Making test scripts executable"
  assert_line --partial "chmod +x scripts/test/*.sh"
  assert_line --partial "Running unit tests"
  assert_line --partial "Running Unit Tests"
  assert_line --partial "Unit Tests Complete"
}

@test "ci-02-integration-tests.sh script makes test scripts executable and runs integration tests" {
  # WHEN: CI integration test orchestration script is executed
  run "$PROJECT_ROOT/scripts/ci/test/ci-02-integration-tests.sh"

  # THEN: Script makes scripts executable and runs integration tests
  assert_success
  assert_line --partial "Making test scripts executable"
  assert_line --partial "chmod +x scripts/test/*.sh"
  assert_line --partial "Running integration tests"
  assert_line --partial "Running Integration Tests"
  assert_line --partial "Integration Tests Complete"
}

@test "ci-03-e2e-tests.sh script makes test scripts executable and runs E2E tests" {
  # WHEN: CI E2E test orchestration script is executed
  run "$PROJECT_ROOT/scripts/ci/test/ci-03-e2e-tests.sh"

  # THEN: Script makes scripts executable and runs E2E tests
  assert_success
  assert_line --partial "Making test scripts executable"
  assert_line --partial "chmod +x scripts/test/*.sh"
  assert_line --partial "Running E2E tests"
  assert_line --partial "Running End-to-End Tests"
  assert_line --partial "E2E Tests Complete"
}

@test "CI orchestration scripts handle unit test failures correctly" {
  # GIVEN: Unit test script configured to fail
  sed -i 's/EXIT_CODE=0/EXIT_CODE=1/' "$PROJECT_ROOT/scripts/test/unit.sh"

  # WHEN: CI unit test orchestration script is executed
  run "$PROJECT_ROOT/scripts/ci/test/ci-01-unit-tests.sh"

  # THEN: Script reports failure correctly
  assert_failure 1
  assert_line --partial "Making test scripts executable"
  assert_line --partial "Running unit tests"
  assert_line --partial "⚠ Unit Tests Failed"
}

@test "CI orchestration scripts handle integration test failures correctly" {
  # GIVEN: Integration test script configured to fail
  sed -i 's/EXIT_CODE=0/EXIT_CODE=1/' "$PROJECT_ROOT/scripts/test/integration.sh"

  # WHEN: CI integration test orchestration script is executed
  run "$PROJECT_ROOT/scripts/ci/test/ci-02-integration-tests.sh"

  # THEN: Script reports failure correctly
  assert_failure 1
  assert_line --partial "Making test scripts executable"
  assert_line --partial "Running integration tests"
  assert_line --partial "⚠ Integration Tests Failed"
}

@test "CI orchestration scripts handle E2E test failures correctly" {
  # GIVEN: E2E test script configured to fail
  sed -i 's/EXIT_CODE=0/EXIT_CODE=1/' "$PROJECT_ROOT/scripts/test/e2e.sh"

  # WHEN: CI E2E test orchestration script is executed
  run "$PROJECT_ROOT/scripts/ci/test/ci-03-e2e-tests.sh"

  # THEN: Script reports failure correctly
  assert_failure 1
  assert_line --partial "Making test scripts executable"
  assert_line --partial "Running E2E tests"
  assert_line --partial "⚠ E2E Tests Failed"
}

@test "CI orchestration scripts use proper error handling" {
  # GIVEN: Check script error handling

  # THEN: All scripts should use set -euo pipefail
  assert grep -q "set -euo pipefail" "$PROJECT_ROOT/scripts/ci/test/ci-01-unit-tests.sh"
  assert grep -q "set -euo pipefail" "$PROJECT_ROOT/scripts/ci/test/ci-02-integration-tests.sh"
  assert grep -q "set -euo pipefail" "$PROJECT_ROOT/scripts/ci/test/ci-03-e2e-tests.sh"
}

@test "CI orchestration scripts have correct shebang" {
  # GIVEN: Check script shebangs
  assert_success

  # THEN: All scripts should use proper shebang
  assert grep -q "^#!/usr/bin/env bash" "$PROJECT_ROOT/scripts/ci/test/ci-01-unit-tests.sh"
  assert grep -q "^#!/usr/bin/env bash" "$PROJECT_ROOT/scripts/ci/test/ci-02-integration-tests.sh"
  assert grep -q "^#!/usr/bin/env bash" "$PROJECT_ROOT/scripts/ci/test/ci-03-e2e-tests.sh"
}

@test "CI orchestration scripts are executable" {
  # GIVEN: Check script permissions
  assert_success

  # THEN: All scripts should be executable
  assert [ -x "$PROJECT_ROOT/scripts/ci/test/ci-01-unit-tests.sh" ]
  assert [ -x "$PROJECT_ROOT/scripts/ci/test/ci-02-integration-tests.sh" ]
  assert [ -x "$PROJECT_ROOT/scripts/ci/test/ci-03-e2e-tests.sh" ]
}

@test "CI orchestration scripts handle missing test scripts gracefully" {
  # GIVEN: Remove test scripts
  rm -f "$PROJECT_ROOT/scripts/test/unit.sh"

  # WHEN: CI unit test orchestration script is executed
  run "$PROJECT_ROOT/scripts/ci/test/ci-01-unit-tests.sh"

  # THEN: Script handles missing test script gracefully
  assert_failure
  # Script should fail when trying to run missing script
}

@test "CI orchestration scripts provide clear purpose comments" {
  # GIVEN: Check script documentation
  assert_success

  # THEN: All scripts should have purpose comments
  assert grep -q "CI Script: Unit Tests" "$PROJECT_ROOT/scripts/ci/test/ci-01-unit-tests.sh"
  assert grep -q "Purpose: Run unit tests" "$PROJECT_ROOT/scripts/ci/test/ci-01-unit-tests.sh"

  assert grep -q "CI Script: Integration Tests" "$PROJECT_ROOT/scripts/ci/test/ci-02-integration-tests.sh"
  assert grep -q "Purpose: Run integration tests" "$PROJECT_ROOT/scripts/ci/test/ci-02-integration-tests.sh"

  assert grep -q "CI Script: E2E Tests" "$PROJECT_ROOT/scripts/ci/test/ci-03-e2e-tests.sh"
  assert grep -q "Purpose: Run end-to-end tests" "$PROJECT_ROOT/scripts/ci/test/ci-03-e2e-tests.sh"
}

@test "CI orchestration scripts maintain consistent execution flow" {
  # WHEN: All CI orchestration scripts are executed
  run "$PROJECT_ROOT/scripts/ci/test/ci-01-unit-tests.sh"
  assert_success
  assert_output --regex "Making.*executable"
  assert_output --regex "Running.*tests"

  run "$PROJECT_ROOT/scripts/ci/test/ci-02-integration-tests.sh"
  assert_success
  assert_output --regex "Making.*executable"
  assert_output --regex "Running.*tests"

  run "$PROJECT_ROOT/scripts/ci/test/ci-03-e2e-tests.sh"
  assert_success
  assert_output --regex "Making.*executable"
  assert_output --regex "Running.*tests"
}

@test "CI orchestration scripts handle chmod command correctly" {
  # GIVEN: Mock chmod command should be called
  # WHEN: CI unit test orchestration script is executed
  run "$PROJECT_ROOT/scripts/ci/test/ci-01-unit-tests.sh"

  # THEN: chmod command should be called with correct arguments
  assert_success
  assert_line --partial "chmod +x scripts/test/*.sh"
}