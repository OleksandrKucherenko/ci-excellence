#!/usr/bin/env bats
# BATS test file for 20-ci-integration-tests.sh
# Tests CI integration test script functionality with comprehensive mocking

load "${BATS_TEST_DIRNAME}/../test_helper.bash"

# Setup function - runs before each test
setup() {
  # GIVEN: Test environment preparation
  TEST_TEMP_DIR="$(temp_make)"

  # Create mock project structure
  PROJECT_ROOT="$TEST_TEMP_DIR/project"
  mkdir -p "$PROJECT_ROOT"/{scripts/{lib,test},test-results,src,tests/integration,integration}

  # Copy script under test
  cp /mnt/wsl/workspace/ci-excellence/scripts/test/20-ci-integration-tests.sh "$PROJECT_ROOT/scripts/test/"
  chmod +x "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh"

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
if [[ "$1" == "test-integration" ]]; then
  echo "make test-integration executed successfully"
  exit 0
elif [[ "$1" == "test" ]]; then
  echo "make test executed successfully"
  exit 0
fi
echo "make mock: $*" >&2
EOF
  chmod +x "$MOCK_BIN/make"

  # Mock find command
  cat > "$MOCK_BIN/find" << 'EOF'
#!/bin/bash
if echo "$*" | grep -q "integration"; then
  echo "./tests/integration/test_integration.go"
fi
EOF
  chmod +x "$MOCK_BIN/find"

  cd "$PROJECT_ROOT"
}

# Teardown function - runs after each test
teardown() {
  temp_del "$TEST_TEMP_DIR"
}

@test "integration test script shows help when requested" {
  # WHEN: Help is requested
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh" help

  # THEN: Help information is displayed
  assert_success
  assert_line --partial "CI Integration Tests Script v1.0.0"
  assert_line --partial "Usage:"
  assert_line --partial "Project Types:"
}

@test "integration test script detects project types correctly" {
  # GIVEN: Different project configurations

  # WHEN: Node.js project is detected
  echo '{"name": "test", "scripts": {"test": "jest"}}' > package.json
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh" detect
  assert_success
  assert_line --partial "nodejs"

  # WHEN: Python project is detected
  rm package.json
  echo "[tool.poetry]" > pyproject.toml
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh" detect
  assert_success
  assert_line --partial "python"

  # WHEN: Go project is detected
  rm pyproject.toml
  echo "module test" > go.mod
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh" detect
  assert_success
  assert_line --partial "go"

  # WHEN: Rust project is detected
  rm go.mod
  echo "[package]" > Cargo.toml
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh" detect
  assert_success
  assert_line --partial "rust"

  # WHEN: Generic project is detected
  rm Cargo.toml
  echo "test:" > Makefile
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh" detect
  assert_success
  assert_line --partial "generic"
}

@test "integration test script validates test setup for Node.js project" {
  # GIVEN: Node.js project with test configuration
  echo '{"name": "test", "scripts": {"test": "jest"}}' > package.json
  mkdir -p tests/integration

  # WHEN: Validation is performed
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh" validate

  # THEN: Validation results are shown
  assert_success
  assert_line --partial "Project type: nodejs"
  assert_line --partial "npx available"
  assert_line --partial "tests/integration directory found"
}

@test "integration test script runs in DRY_RUN mode" {
  # GIVEN: Script is configured for dry run
  export INTEGRATION_TEST_MODE="DRY_RUN"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh"

  # THEN: Dry run output is shown
  assert_success
  assert_line --partial "DRY RUN: Would run integration tests"
}

@test "integration test script runs in PASS mode" {
  # GIVEN: Script is configured for pass mode
  export INTEGRATION_TEST_MODE="PASS"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh"

  # THEN: Pass mode output is shown
  assert_success
  assert_line --partial "PASS MODE: Integration tests simulated successfully"
}

@test "integration test script runs in FAIL mode" {
  # GIVEN: Script is configured for fail mode
  export INTEGRATION_TEST_MODE="FAIL"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh"

  # THEN: Fail mode output is shown
  assert_failure 1
  assert_line --partial "FAIL MODE: Simulating integration test failure"
}

@test "integration test script runs in SKIP mode" {
  # GIVEN: Script is configured for skip mode
  export INTEGRATION_TEST_MODE="SKIP"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh"

  # THEN: Skip mode output is shown
  assert_success
  assert_line --partial "SKIP MODE: Integration tests skipped"
}

@test "integration test script runs in TIMEOUT mode" {
  # GIVEN: Script is configured for timeout mode
  export INTEGRATION_TEST_MODE="TIMEOUT"

  # WHEN: Script is executed (with timeout to avoid actual sleep)
  run timeout 2s "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh"

  # THEN: Timeout occurs
  assert_failure 124  # timeout exit code
}

@test "integration test script respects pipeline-specific environment variables" {
  # GIVEN: Pipeline-specific mode is set (highest priority)
  export PIPELINE_INTEGRATION_TEST_MODE="PASS"
  export INTEGRATION_TEST_MODE="FAIL"
  export CI_TEST_MODE="FAIL"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh"

  # THEN: Pipeline mode takes precedence
  assert_success
  assert_line --partial "PASS MODE: Integration tests simulated successfully"
}

@test "integration test script executes Jest integration tests for Node.js project" {
  # GIVEN: Node.js project with Jest and integration tests
  echo '{"name": "test", "scripts": {"test": "jest"}, "devDependencies": {"jest": "^29.0.0"}}' > package.json
  mkdir -p tests/integration
  echo "describe('integration test', () => { it('should pass', () => {}); });" > tests/integration/test.integration.spec.js

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh"

  # THEN: Jest integration tests are executed
  assert_success
  assert_line --partial "Running Jest integration tests"
  assert_line --partial "Jest integration tests passed"

  # AND: Test report is generated
  assert_file_exists "$PROJECT_ROOT/test-results/integration-test-report.json"
}

@test "integration test script executes Mocha integration tests for Node.js project" {
  # GIVEN: Node.js project with Mocha and integration tests
  echo '{"name": "test", "scripts": {"test": "mocha"}, "devDependencies": {"mocha": "^10.0.0"}}' > package.json
  mkdir -p tests/integration
  echo "describe('integration test', () => { it('should pass', () => {}); });" > tests/integration/test.integration.spec.js

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh"

  # THEN: Mocha integration tests are executed
  assert_success
  assert_line --partial "Running Mocha integration tests"
  assert_line --partial "Mocha integration tests passed"
}

@test "integration test script executes npm test:integration for Node.js project" {
  # GIVEN: Node.js project with npm integration script
  echo '{"name": "test", "scripts": {"test:integration": "echo 'integration tests'"}}' > package.json
  mkdir -p tests/integration

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh"

  # THEN: npm test:integration is executed
  assert_success
  assert_line --partial "npm run test:integration passed"
}

@test "integration test script skips Node.js integration tests when no tests found" {
  # GIVEN: Node.js project without integration tests
  echo '{"name": "test", "scripts": {"test": "jest"}, "devDependencies": {"jest": "^29.0.0"}}' > package.json

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh"

  # THEN: Tests are skipped
  assert_success
  assert_line --partial "No integration tests found for Node.js project"
}

@test "integration test script executes pytest for Python project" {
  # GIVEN: Python project with integration tests
  echo "[tool.poetry]" > pyproject.toml
  mkdir -p tests/integration
  echo "def test_integration(): pass" > tests/integration/test_integration.py

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh" python

  # THEN: Pytest is executed
  assert_success
  assert_line --partial "Running pytest integration tests"
  assert_line --partial "Pytest integration tests passed"
}

@test "integration test script executes unittest for Python project when pytest unavailable" {
  # GIVEN: Python project without pytest
  echo "[tool.pytest]" > pyproject.toml
  mkdir -p tests/integration
  echo "def test_integration(): pass" > tests/integration/test_integration.py

  # Remove pytest mock
  rm "$MOCK_BIN/pytest"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh" python

  # THEN: Unittest is executed
  assert_success
  assert_line --partial "Running unittest integration tests"
  assert_line --partial "Unittest integration tests passed"
}

@test "integration test script uses integration directory for Python project" {
  # GIVEN: Python project with integration directory
  echo "[tool.poetry]" > pyproject.toml
  mkdir -p integration
  echo "def test_integration(): pass" > integration/test_integration.py

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh" python

  # THEN: Tests are executed from integration directory
  assert_success
  assert_line --partial "Running pytest integration tests"
}

@test "integration test script executes Go integration tests" {
  # GIVEN: Go project with integration tests
  echo "module test" > go.mod
  echo "package main" > main.go
  echo "func main() {}" >> main.go
  mkdir -p main
  echo "package main" > main/integration_test.go
  echo 'func TestIntegration(t *testing.T) {}' >> main/integration_test.go

  # Create mock Go integration test files
  cat > "$MOCK_BIN/find" << 'EOF'
#!/bin/bash
if echo "$*" | grep -q "integration"; then
  echo "./main/integration_test.go"
fi
EOF
  chmod +x "$MOCK_BIN/find"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh" go

  # THEN: Go integration tests are executed
  assert_success
  assert_line --partial "Running Go integration tests"
  assert_line --partial "Go integration tests passed"
}

@test "integration test script executes Rust integration tests" {
  # GIVEN: Rust project with integration tests
  echo '[package]
name = "test"
version = "0.1.0"' > Cargo.toml
  mkdir -p src
  echo "fn main() {}" > src/main.rs
  mkdir -p tests
  echo "#[test] fn integration_test() {}" > tests/integration_test.rs

  # Create mock Rust integration test files
  cat > "$MOCK_BIN/find" << 'EOF'
#!/bin/bash
if echo "$*" | grep -q "integration"; then
  echo "./tests/integration_test.rs"
fi
EOF
  chmod +x "$MOCK_BIN/find"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh" rust

  # THEN: Rust integration tests are executed
  assert_success
  assert_line --partial "Running Rust integration tests"
  assert_line --partial "Rust integration tests passed"
}

@test "integration test script executes make test-integration for generic project" {
  # GIVEN: Generic project with Makefile integration target
  echo "test-integration:\n\t@echo 'Running integration tests'" > Makefile

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh" generic

  # THEN: Make integration test is executed
  assert_success
  assert_line --partial "Running generic integration tests"
  assert_line --partial "Generic integration tests passed"
}

@test "integration test script executes integration test script for generic project" {
  # GIVEN: Generic project with integration test script
  mkdir -p scripts
  cat > "$MOCK_BIN/find" << 'EOF'
#!/bin/bash
if echo "$*" | grep -q "integration"; then
  echo "./scripts/integration-test.sh"
fi
EOF
  chmod +x "$MOCK_BIN/find"

  cat > scripts/integration-test.sh << 'EOF'
#!/bin/bash
echo "Integration tests passed"
exit 0
EOF
  chmod +x scripts/integration-test.sh

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh" generic

  # THEN: Integration test script is executed
  assert_success
  assert_line --partial "Found integration test script"
  assert_line --partial "Generic integration tests passed"
}

@test "integration test script handles Jest configuration files" {
  # GIVEN: Node.js project with Jest integration configuration
  echo '{"name": "test", "scripts": {"test": "jest"}, "devDependencies": {"jest": "^29.0.0"}}' > package.json
  mkdir -p tests/integration
  echo "describe('integration test', () => { it('should pass', () => {}); });" > tests/integration/test.integration.spec.js

  # Create Jest integration config
  cat > jest.integration.config.js << 'EOF'
module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/tests/integration/**/*.test.js'],
};
EOF

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh"

  # THEN: Jest integration config is used
  assert_success
  assert_line --partial "Running Jest integration tests"
}

@test "integration test script generates comprehensive test report" {
  # GIVEN: Node.js project
  echo '{"name": "test", "scripts": {"test": "jest"}, "devDependencies": {"jest": "^29.0.0"}}' > package.json
  mkdir -p tests/integration
  echo "describe('integration test', () => { it('should pass', () => {}); });" > tests/integration/test.integration.spec.js

  export CI="true"
  export GITHUB_ACTIONS="true"
  export RUNNER_OS="Linux"
  export GITHUB_SHA="test123"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh"

  # THEN: Test report is generated with metadata
  assert_success
  assert_file_exists "$PROJECT_ROOT/test-results/integration-test-report.json"

  # Verify report content
  local report_content
  report_content=$(cat "$PROJECT_ROOT/test-results/integration-test-report.json")
  assert_output --partial '"test_type": "integration"'
  assert_output --partial '"project_type": "nodejs"'
  assert_output --partial '"test_status": "success"'
}

@test "integration test script handles missing common library gracefully" {
  # GIVEN: Script without common library
  rm "$PROJECT_ROOT/scripts/lib/common.sh"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh"

  # THEN: Error is reported
  assert_failure
  assert_line --partial "Failed to source common utilities"
}

@test "integration test script handles test failures correctly" {
  # GIVEN: Script configured to simulate test failure
  echo '{"name": "test", "scripts": {"test": "jest"}, "devDependencies": {"jest": "^29.0.0"}}' > package.json
  mkdir -p tests/integration
  echo "describe('integration test', () => { it('should pass', () => {}); });" > tests/integration/test.integration.spec.js

  # Mock Jest to fail
  cat > "$MOCK_BIN/npx" << 'EOF'
#!/bin/bash
if [[ "$1" == "jest" ]]; then
  echo "Jest integration tests failed"
  exit 1
fi
echo "npx mock: $*" >&2
EOF
  chmod +x "$MOCK_BIN/npx"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh"

  # THEN: Failure is reported
  assert_failure
  assert_line --partial "Jest integration tests failed"

  # AND: Test report indicates failure
  assert_file_exists "$PROJECT_ROOT/test-results/integration-test-report.json"
  local report_content
  report_content=$(cat "$PROJECT_ROOT/test-results/integration-test-report.json")
  assert_output --partial '"test_status": "failure"'
  assert_output --partial '"test_exit_code": 1'
}

@test "integration test script respects custom results directory" {
  # GIVEN: Custom results directory
  mkdir -p "$PROJECT_ROOT/custom-results"
  echo '{"name": "test", "scripts": {"test": "jest"}, "devDependencies": {"jest": "^29.0.0"}}' > package.json
  mkdir -p tests/integration
  echo "describe('integration test', () => { it('should pass', () => {}); });" > tests/integration/test.integration.spec.js

  # WHEN: Script is executed with custom directory
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh" nodejs "$PROJECT_ROOT/custom-results"

  # THEN: Report is generated in custom location
  assert_success
  assert_file_exists "$PROJECT_ROOT/custom-results/integration-test-report.json"
  assert_file_not_exists "$PROJECT_ROOT/test-results/integration-test-report.json"
}

@test "integration test script handles missing Go integration tests gracefully" {
  # GIVEN: Go project without integration tests
  echo "module test" > go.mod
  echo "package main" > main.go
  echo "func main() {}" >> main.go

  # Mock find to return no integration files
  cat > "$MOCK_BIN/find" << 'EOF'
#!/bin/bash
# Return nothing - no integration tests found
EOF
  chmod +x "$MOCK_BIN/find"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh" go

  # THEN: Tests are skipped gracefully
  assert_success
  assert_line --partial "No integration tests found for Go project"
}

@test "integration test script handles missing Rust integration tests gracefully" {
  # GIVEN: Rust project without integration tests
  echo '[package]
name = "test"
version = "0.1.0"' > Cargo.toml
  mkdir -p src
  echo "fn main() {}" > src/main.rs

  # Mock find to return no integration files
  cat > "$MOCK_BIN/find" << 'EOF'
#!/bin/bash
# Return nothing - no integration tests found
EOF
  chmod +x "$MOCK_BIN/find"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/20-ci-integration-tests.sh" rust

  # THEN: Tests are skipped gracefully
  assert_success
  assert_line --partial "No integration tests found for Rust project"
}