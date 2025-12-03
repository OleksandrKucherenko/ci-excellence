#!/usr/bin/env bats
# BATS test file for simple test scripts (unit.sh, integration.sh, e2e.sh, smoke.sh)
# Tests basic functionality of stub test scripts

load "${BATS_TEST_DIRNAME}/../test_helper.bash"

# Setup function - runs before each test
setup() {
  # GIVEN: Test environment preparation
  TEST_TEMP_DIR="$(temp_make)"

  # Create mock project structure
  PROJECT_ROOT="$TEST_TEMP_DIR/project"
  mkdir -p "$PROJECT_ROOT"/{scripts/test,scripts/lib}

  # Copy simple test scripts
  cp /mnt/wsl/workspace/ci-excellence/scripts/test/unit.sh "$PROJECT_ROOT/scripts/test/"
  cp /mnt/wsl/workspace/ci-excellence/scripts/test/integration.sh "$PROJECT_ROOT/scripts/test/"
  cp /mnt/wsl/workspace/ci-excellence/scripts/test/e2e.sh "$PROJECT_ROOT/scripts/test/"
  cp /mnt/wsl/workspace/ci-excellence/scripts/test/smoke.sh "$PROJECT_ROOT/scripts/test/"

  chmod +x "$PROJECT_ROOT/scripts/test"/*.sh

  cd "$PROJECT_ROOT"
}

# Teardown function - runs after each test
teardown() {
  temp_del "$TEST_TEMP_DIR"
}

@test "unit.sh script executes successfully" {
  # WHEN: Unit test script is executed
  run "$PROJECT_ROOT/scripts/test/unit.sh"

  # THEN: Script runs without error and shows expected output
  assert_success
  assert_line --partial "Running Unit Tests"
  assert_line --partial "Unit test stub executed"
  assert_line --partial "Customize this script in scripts/test/unit.sh"
  assert_line --partial "Unit Tests Complete"
}

@test "unit.sh script handles exit codes correctly" {
  # GIVEN: Script with simulated failure
  # Modify the script to simulate failure
  sed -i 's/EXIT_CODE=0/EXIT_CODE=1/' "$PROJECT_ROOT/scripts/test/unit.sh"

  # WHEN: Unit test script is executed with failure
  run "$PROJECT_ROOT/scripts/test/unit.sh"

  # THEN: Script reports failure correctly
  assert_failure 1
  assert_line --partial "Running Unit Tests"
  assert_line --partial "Unit Tests Complete"
  assert_line --partial "⚠ Unit Tests Failed"
}

@test "integration.sh script executes successfully" {
  # WHEN: Integration test script is executed
  run "$PROJECT_ROOT/scripts/test/integration.sh"

  # THEN: Script runs without error and shows expected output
  assert_success
  assert_line --partial "Running Integration Tests"
  assert_line --partial "Integration test stub executed"
  assert_line --partial "Customize this script in scripts/test/integration.sh"
  assert_line --partial "Integration Tests Complete"
}

@test "integration.sh script handles exit codes correctly" {
  # GIVEN: Script with simulated failure
  # Modify the script to simulate failure
  sed -i 's/EXIT_CODE=0/EXIT_CODE=1/' "$PROJECT_ROOT/scripts/test/integration.sh"

  # WHEN: Integration test script is executed with failure
  run "$PROJECT_ROOT/scripts/test/integration.sh"

  # THEN: Script reports failure correctly
  assert_failure 1
  assert_line --partial "Running Integration Tests"
  assert_line --partial "Integration Tests Complete"
  assert_line --partial "⚠ Integration Tests Failed"
}

@test "e2e.sh script executes successfully" {
  # WHEN: E2E test script is executed
  run "$PROJECT_ROOT/scripts/test/e2e.sh"

  # THEN: Script runs without error and shows expected output
  assert_success
  assert_line --partial "Running End-to-End Tests"
  assert_line --partial "E2E test stub executed"
  assert_line --partial "Customize this script in scripts/test/e2e.sh"
  assert_line --partial "E2E Tests Complete"
}

@test "e2e.sh script handles exit codes correctly" {
  # GIVEN: Script with simulated failure
  # Modify the script to simulate failure
  sed -i 's/EXIT_CODE=0/EXIT_CODE=1/' "$PROJECT_ROOT/scripts/test/e2e.sh"

  # WHEN: E2E test script is executed with failure
  run "$PROJECT_ROOT/scripts/test/e2e.sh"

  # THEN: Script reports failure correctly
  assert_failure 1
  assert_line --partial "Running End-to-End Tests"
  assert_line --partial "E2E Tests Complete"
  assert_line --partial "⚠ E2E Tests Failed"
}

@test "smoke.sh script executes successfully with default version" {
  # WHEN: Smoke test script is executed without version
  run "$PROJECT_ROOT/scripts/test/smoke.sh"

  # THEN: Script runs without error and shows expected output
  assert_success
  assert_line --partial "Running Smoke Tests"
  assert_line --partial "Version: latest"
  assert_line --partial "Smoke test stub executed"
  assert_line --partial "Customize this script in scripts/test/smoke.sh"
  assert_line --partial "Smoke Tests Complete"
}

@test "smoke.sh script executes successfully with custom version" {
  # WHEN: Smoke test script is executed with custom version
  run "$PROJECT_ROOT/scripts/test/smoke.sh" "v1.2.3"

  # THEN: Script runs without error and shows expected version
  assert_success
  assert_line --partial "Running Smoke Tests"
  assert_line --partial "Version: v1.2.3"
  assert_line --partial "Smoke test stub executed"
  assert_line --partial "Customize this script in scripts/test/smoke.sh"
  assert_line --partial "Smoke Tests Complete"
}

@test "smoke.sh script handles exit codes correctly" {
  # GIVEN: Script with simulated failure
  # Modify the script to simulate failure
  sed -i 's/EXIT_CODE=0/EXIT_CODE=1/' "$PROJECT_ROOT/scripts/test/smoke.sh"

  # WHEN: Smoke test script is executed with failure
  run "$PROJECT_ROOT/scripts/test/smoke.sh" "v1.0.0"

  # THEN: Script reports failure correctly
  assert_failure 1
  assert_line --partial "Running Smoke Tests"
  assert_line --partial "Version: v1.0.0"
  assert_line --partial "Smoke Tests Complete"
  assert_line --partial "⚠ Smoke Tests Failed"
}

@test "simple test scripts follow consistent output format" {
  # WHEN: All scripts are executed
  run "$PROJECT_ROOT/scripts/test/unit.sh"
  assert_success
  assert_output --regex "Running.*Tests"
  assert_output --regex "Tests Complete"

  run "$PROJECT_ROOT/scripts/test/integration.sh"
  assert_success
  assert_output --regex "Running.*Tests"
  assert_output --regex "Tests Complete"

  run "$PROJECT_ROOT/scripts/test/e2e.sh"
  assert_success
  assert_output --regex "Running.*Tests"
  assert_output --regex "Tests Complete"

  run "$PROJECT_ROOT/scripts/test/smoke.sh"
  assert_success
  assert_output --regex "Running.*Tests"
  assert_output --regex "Tests Complete"
}

@test "simple test scripts use proper error handling" {
  # GIVEN: Scripts should use set -euo pipefail

  # THEN: All scripts should have proper error handling
  assert_success
  # Check that scripts have the error handling directive
  grep -q "set -euo pipefail" "$PROJECT_ROOT/scripts/test/unit.sh"
  grep -q "set -euo pipefail" "$PROJECT_ROOT/scripts/test/integration.sh"
  grep -q "set -euo pipefail" "$PROJECT_ROOT/scripts/test/e2e.sh"
  grep -q "set -euo pipefail" "$PROJECT_ROOT/scripts/test/smoke.sh"
}

@test "simple test scripts provide customization guidance" {
  # WHEN: All scripts are executed
  run "$PROJECT_ROOT/scripts/test/unit.sh"
  assert_output --partial "Customize this script in scripts/test/unit.sh"

  run "$PROJECT_ROOT/scripts/test/integration.sh"
  assert_output --partial "Customize this script in scripts/test/integration.sh"

  run "$PROJECT_ROOT/scripts/test/e2e.sh"
  assert_output --partial "Customize this script in scripts/test/e2e.sh"

  run "$PROJECT_ROOT/scripts/test/smoke.sh"
  assert_output --partial "Customize this script in scripts/test/smoke.sh"
}

@test "smoke.sh script uses correct shebang" {
  # GIVEN: Check script shebangs
  assert_success

  # THEN: All scripts should use proper shebang
  assert grep -q "^#!/usr/bin/env bash" "$PROJECT_ROOT/scripts/test/unit.sh"
  assert grep -q "^#!/usr/bin/env bash" "$PROJECT_ROOT/scripts/test/integration.sh"
  assert grep -q "^#!/usr/bin/env bash" "$PROJECT_ROOT/scripts/test/e2e.sh"
  assert grep -q "^#!/usr/bin/env bash" "$PROJECT_ROOT/scripts/test/smoke.sh"
}

@test "simple test scripts are executable" {
  # GIVEN: Check script permissions
  assert_success

  # THEN: All scripts should be executable
  assert [ -x "$PROJECT_ROOT/scripts/test/unit.sh" ]
  assert [ -x "$PROJECT_ROOT/scripts/test/integration.sh" ]
  assert [ -x "$PROJECT_ROOT/scripts/test/e2e.sh" ]
  assert [ -x "$PROJECT_ROOT/scripts/test/smoke.sh" }
}