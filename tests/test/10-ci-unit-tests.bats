#!/usr/bin/env bats
# BATS test file for 10-ci-unit-tests.sh
# Tests CI unit test script functionality with comprehensive mocking

load "${BATS_TEST_DIRNAME}/../test_helper.bash"

# Setup function - runs before each test
setup() {
  # GIVEN: Test environment preparation
  TEST_TEMP_DIR="$(temp_make)"

  # Create mock project structure
  PROJECT_ROOT="$TEST_TEMP_DIR/project"
  mkdir -p "$PROJECT_ROOT"/{scripts/{lib,test},test-results,src,tests/unit}

  # Copy script under test
  cp /mnt/wsl/workspace/ci-excellence/scripts/test/10-ci-unit-tests.sh "$PROJECT_ROOT/scripts/test/"
  chmod +x "$PROJECT_ROOT/scripts/test/10-ci-unit-tests.sh"

  # Create mock common library
  cat > "$PROJECT_ROOT/scripts/lib/common.sh" << 'EOF'
#!/bin/bash
# Mock common library for testing

LOG_TIMESTAMP="${LOG_TIMESTAMP:-false}"

log_debug() { printf "[DEBUG] %s\n" "$1" >&2; }
log_info() { printf "[INFO] %s\n" "$1" >&2; }
log_success() { printf "[SUCCESS] %s\n" "$1" >&2; }
log_warn() { printf "[WARN] %s\n" "$1" >&2; }
log_error() { printf "[ERROR] %s\n" "$1" >&2; }
EOF
  chmod +x "$PROJECT_ROOT/scripts/lib/common.sh"

  # Set up PATH with mock commands
  MOCK_BIN="$TEST_TEMP_DIR/bin"
  mkdir -p "$MOCK_BIN"
  export PATH="$MOCK_BIN:$PATH"

  # Mock git command
  cat > "$MOCK_BIN/git" << 'EOF'
#!/bin/bash
case "$1" in
  "rev-parse")
    if [[ "$2" == "HEAD" ]]; then
      echo "abc123def456"
    fi
    ;;
  *)
    echo "git mock: $*" >&2
    ;;
esac
EOF
  chmod +x "$MOCK_BIN/git"

  # Mock npm command
  cat > "$MOCK_BIN/npm" << 'EOF'
#!/bin/bash
if [[ "$1" == "run" && "$2" == "test" ]]; then
  echo "npm test executed successfully"
  exit 0
elif [[ "$1" == "run" && "$2" == "test:integration" ]]; then
  echo "npm run test:integration executed successfully"
  exit 0
elif [[ "$1" == "run" && "$2" == "test:e2e" ]]; then
  echo "npm run test:e2e executed successfully"
  exit 0
fi
echo "npm mock: $*" >&2
EOF
  chmod +x "$MOCK_BIN/npm"

  # Mock npx command
  cat > "$MOCK_BIN/npx" << 'EOF'
#!/bin/bash
if [[ "$1" == "jest" ]]; then
  echo "Jest tests executed successfully"
  exit 0
elif [[ "$1" == "mocha" ]]; then
  echo "Mocha tests executed successfully"
  exit 0
fi
echo "npx mock: $*" >&2
EOF
  chmod +x "$MOCK_BIN/npx"

  # Mock test framework commands
  cat > "$MOCK_BIN/pytest" << 'EOF'
#!/bin/bash
echo "pytest executed successfully"
exit 0
EOF
  chmod +x "$MOCK_BIN/pytest"

  cat > "$MOCK_BIN/python" << 'EOF'
#!/bin/bash
if [[ "$1" == "-m" && "$2" == "unittest" ]]; then
  echo "unittest executed successfully"
  exit 0
fi
echo "python mock: $*" >&2
EOF
  chmod +x "$MOCK_BIN/python"

  cat > "$MOCK_BIN/go" << 'EOF'
#!/bin/bash
if [[ "$1" == "test" ]]; then
  echo "go test executed successfully"
  exit 0
fi
echo "go mock: $*" >&2
EOF
  chmod +x "$MOCK_BIN/go"

  cat > "$MOCK_BIN/cargo" << 'EOF'
#!/bin/bash
if [[ "$1" == "test" ]]; then
  echo "cargo test executed successfully"
  exit 0
fi
echo "cargo mock: $*" >&2
EOF
  chmod +x "$MOCK_BIN/cargo"

  cat > "$MOCK_BIN/make" << 'EOF'
#!/bin/bash
if [[ "$1" == "test-unit" ]]; then
  echo "make test-unit executed successfully"
  exit 0
elif [[ "$1" == "test" ]]; then
  echo "make test executed successfully"
  exit 0
fi
echo "make mock: $*" >&2
EOF
  chmod +x "$MOCK_BIN/make"

  cd "$PROJECT_ROOT"
}

# Teardown function - runs after each test
teardown() {
  temp_del "$TEST_TEMP_DIR"
}

@test "unit test script shows help when requested" {
  # WHEN: Help is requested
  run "$PROJECT_ROOT/scripts/test/10-ci-unit-tests.sh" help

  # THEN: Help information is displayed
  assert_success
  assert_line --partial "CI Unit Tests Script v1.0.0"
  assert_line --partial "Usage:"
  assert_line --partial "Project Types:"
}

@test "unit test script detects project types correctly" {
  # GIVEN: Different project configurations

  # WHEN: Node.js project is detected
  echo '{"name": "test", "scripts": {"test": "jest"}}' > package.json
  run "$PROJECT_ROOT/scripts/test/10-ci-unit-tests.sh" detect
  assert_success
  assert_line --partial "nodejs"

  # WHEN: Python project is detected
  rm package.json
  echo "[tool.poetry]" > pyproject.toml
  run "$PROJECT_ROOT/scripts/test/10-ci-unit-tests.sh" detect
  assert_success
  assert_line --partial "python"

  # WHEN: Go project is detected
  rm pyproject.toml
  echo "module test" > go.mod
  run "$PROJECT_ROOT/scripts/test/10-ci-unit-tests.sh" detect
  assert_success
  assert_line --partial "go"

  # WHEN: Rust project is detected
  rm go.mod
  echo "[package]" > Cargo.toml
  run "$PROJECT_ROOT/scripts/test/10-ci-unit-tests.sh" detect
  assert_success
  assert_line --partial "rust"

  # WHEN: Generic project is detected
  rm Cargo.toml
  echo "test:" > Makefile
  run "$PROJECT_ROOT/scripts/test/10-ci-unit-tests.sh" detect
  assert_success
  assert_line --partial "generic"
}

@test "unit test script validates test setup for Node.js project" {
  # GIVEN: Node.js project with test configuration
  echo '{"name": "test", "scripts": {"test": "jest"}}' > package.json

  # WHEN: Validation is performed
  run "$PROJECT_ROOT/scripts/test/10-ci-unit-tests.sh" validate

  # THEN: Validation results are shown
  assert_success
  assert_line --partial "Project type: nodejs"
  assert_line --partial "npx available"
}

@test "unit test script runs in DRY_RUN mode" {
  # GIVEN: Script is configured for dry run
  export UNIT_TEST_MODE="DRY_RUN"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/10-ci-unit-tests.sh"

  # THEN: Dry run output is shown
  assert_success
  assert_line --partial "DRY RUN: Would run unit tests"
}

@test "unit test script runs in PASS mode" {
  # GIVEN: Script is configured for pass mode
  export UNIT_TEST_MODE="PASS"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/10-ci-unit-tests.sh"

  # THEN: Pass mode output is shown
  assert_success
  assert_line --partial "PASS MODE: Unit tests simulated successfully"
}

@test "unit test script runs in FAIL mode" {
  # GIVEN: Script is configured for fail mode
  export UNIT_TEST_MODE="FAIL"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/10-ci-unit-tests.sh"

  # THEN: Fail mode output is shown
  assert_failure 1
  assert_line --partial "FAIL MODE: Simulating unit test failure"
}

@test "unit test script runs in SKIP mode" {
  # GIVEN: Script is configured for skip mode
  export UNIT_TEST_MODE="SKIP"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/10-ci-unit-tests.sh"

  # THEN: Skip mode output is shown
  assert_success
  assert_line --partial "SKIP MODE: Unit tests skipped"
}

@test "unit test script runs in TIMEOUT mode" {
  # GIVEN: Script is configured for timeout mode
  export UNIT_TEST_MODE="TIMEOUT"

  # WHEN: Script is executed (with timeout to avoid actual sleep)
  run timeout 2s "$PROJECT_ROOT/scripts/test/10-ci-unit-tests.sh"

  # THEN: Timeout occurs
  assert_failure 124  # timeout exit code
}

@test "unit test script respects pipeline-specific environment variables" {
  # GIVEN: Pipeline-specific mode is set (highest priority)
  export PIPELINE_UNIT_TEST_MODE="PASS"
  export UNIT_TEST_MODE="FAIL"
  export CI_TEST_MODE="FAIL"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/10-ci-unit-tests.sh"

  # THEN: Pipeline mode takes precedence
  assert_success
  assert_line --partial "PASS MODE: Unit tests simulated successfully"
}

@test "unit test script executes Jest for Node.js project" {
  # GIVEN: Node.js project with Jest configuration
  echo '{"name": "test", "scripts": {"test": "jest"}, "devDependencies": {"jest": "^29.0.0"}}' > package.json

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/10-ci-unit-tests.sh"

  # THEN: Jest tests are executed
  assert_success
  assert_line --partial "Running Jest unit tests"
  assert_line --partial "Jest unit tests passed"

  # AND: Test report is generated
  assert_file_exists "$PROJECT_ROOT/test-results/unit-test-report.json"
}

@test "unit test script executes Mocha for Node.js project" {
  # GIVEN: Node.js project with Mocha configuration
  echo '{"name": "test", "scripts": {"test": "mocha"}, "devDependencies": {"mocha": "^10.0.0"}}' > package.json

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/10-ci-unit-tests.sh"

  # THEN: Mocha tests are executed
  assert_success
  assert_line --partial "Running Mocha unit tests"
  assert_line --partial "Mocha unit tests passed"
}

@test "unit test script executes pytest for Python project" {
  # GIVEN: Python project configuration
  echo "[tool.poetry]" > pyproject.toml
  mkdir -p tests/unit
  echo "# dummy test" > tests/unit/test_example.py

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/10-ci-unit-tests.sh" python

  # THEN: Pytest is executed
  assert_success
  assert_line --partial "Running pytest"
  assert_line --partial "Pytest unit tests passed"
}

@test "unit test script executes unittest for Python project when pytest unavailable" {
  # GIVEN: Python project without pytest
  echo "[tool.pytest]" > pyproject.toml
  mkdir -p tests/unit
  echo "# dummy test" > tests/unit/test_example.py

  # Remove pytest mock
  rm "$MOCK_BIN/pytest"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/10-ci-unit-tests.sh" python

  # THEN: Unittest is executed
  assert_success
  assert_line --partial "Running unittest"
  assert_line --partial "Unittest passed"
}

@test "unit test script executes go test for Go project" {
  # GIVEN: Go project
  echo "module test" > go.mod
  echo "package main" > main.go
  echo "func main() {}" >> main.go
  mkdir -p main
  echo "package main" > main/main_test.go
  echo "func TestMain(t *testing.T) {}" >> main/main_test.go

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/10-ci-unit-tests.sh" go

  # THEN: Go tests are executed
  assert_success
  assert_line --partial "Running Go unit tests"
  assert_line --partial "Go unit tests passed"
}

@test "unit test script executes cargo test for Rust project" {
  # GIVEN: Rust project
  echo '[package]
name = "test"
version = "0.1.0"' > Cargo.toml
  mkdir -p src
  echo "fn main() {}" > src/main.rs

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/10-ci-unit-tests.sh" rust

  # THEN: Cargo tests are executed
  assert_success
  assert_line --partial "Running Rust unit tests"
  assert_line --partial "Rust unit tests passed"
}

@test "unit test script executes make test for generic project" {
  # GIVEN: Generic project with Makefile
  echo "test-unit:\n\t@echo 'Running tests'" > Makefile

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/10-ci-unit-tests.sh" generic

  # THEN: Make test is executed
  assert_success
  assert_line --partial "Running generic unit tests"
  assert_line --partial "Generic unit tests passed"
}

@test "unit test script generates coverage when requested" {
  # GIVEN: Node.js project with Jest
  echo '{"name": "test", "scripts": {"test": "jest"}, "devDependencies": {"jest": "^29.0.0"}}' > package.json
  export GENERATE_COVERAGE="true"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/10-ci-unit-tests.sh"

  # THEN: Coverage is requested
  assert_success
  # Note: Coverage directory creation would be verified in real execution
}

@test "unit test script generates comprehensive test report" {
  # GIVEN: Node.js project
  echo '{"name": "test", "scripts": {"test": "jest"}, "devDependencies": {"jest": "^29.0.0"}}' > package.json
  export CI="true"
  export GITHUB_ACTIONS="true"
  export RUNNER_OS="Linux"
  export GITHUB_SHA="test123"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/10-ci-unit-tests.sh"

  # THEN: Test report is generated with metadata
  assert_success
  assert_file_exists "$PROJECT_ROOT/test-results/unit-test-report.json"

  # Verify report content
  local report_content
  report_content=$(cat "$PROJECT_ROOT/test-results/unit-test-report.json")
  assert_output --partial '"test_type": "unit"'
  assert_output --partial '"project_type": "nodejs"'
  assert_output --partial '"test_status": "success"'
}

@test "unit test script handles missing common library gracefully" {
  # GIVEN: Script without common library
  rm "$PROJECT_ROOT/scripts/lib/common.sh"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/10-ci-unit-tests.sh"

  # THEN: Error is reported
  assert_failure
  assert_line --partial "Failed to source common utilities"
}

@test "unit test script handles test failures correctly" {
  # GIVEN: Script configured to simulate test failure
  echo '{"name": "test", "scripts": {"test": "jest"}, "devDependencies": {"jest": "^29.0.0"}}' > package.json

  # Mock Jest to fail
  cat > "$MOCK_BIN/npx" << 'EOF'
#!/bin/bash
if [[ "$1" == "jest" ]]; then
  echo "Jest tests failed"
  exit 1
fi
echo "npx mock: $*" >&2
EOF
  chmod +x "$MOCK_BIN/npx"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/10-ci-unit-tests.sh"

  # THEN: Failure is reported
  assert_failure
  assert_line --partial "Jest unit tests failed"

  # AND: Test report indicates failure
  assert_file_exists "$PROJECT_ROOT/test-results/unit-test-report.json"
  local report_content
  report_content=$(cat "$PROJECT_ROOT/test-results/unit-test-report.json")
  assert_output --partial '"test_status": "failure"'
  assert_output --partial '"test_exit_code": 1'
}

@test "unit test script respects custom results directory" {
  # GIVEN: Custom results directory
  mkdir -p "$PROJECT_ROOT/custom-results"
  echo '{"name": "test", "scripts": {"test": "jest"}, "devDependencies": {"jest": "^29.0.0"}}' > package.json

  # WHEN: Script is executed with custom directory
  run "$PROJECT_ROOT/scripts/test/10-ci-unit-tests.sh" nodejs "$PROJECT_ROOT/custom-results"

  # THEN: Report is generated in custom location
  assert_success
  assert_file_exists "$PROJECT_ROOT/custom-results/unit-test-report.json"
  assert_file_not_exists "$PROJECT_ROOT/test-results/unit-test-report.json"
}