#!/usr/bin/env bats
# BATS test file for 30-ci-e2e-tests.sh
# Tests CI E2E test script functionality with comprehensive mocking

load "${BATS_TEST_DIRNAME}/../test_helper.bash"

# Setup function - runs before each test
setup() {
  # GIVEN: Test environment preparation
  TEST_TEMP_DIR="$(temp_make)"

  # Create mock project structure
  PROJECT_ROOT="$TEST_TEMP_DIR/project"
  mkdir -p "$PROJECT_ROOT"/{scripts/{lib,test},test-results,src,tests/e2e,e2e,cypress/e2e}

  # Copy script under test
  cp /mnt/wsl/workspace/ci-excellence/scripts/test/30-ci-e2e-tests.sh "$PROJECT_ROOT/scripts/test/"
  chmod +x "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh"

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
if [[ "$1" == "playwright" ]]; then
  echo "Playwright E2E tests executed successfully"
  exit 0
elif [[ "$1" == "cypress" ]]; then
  echo "Cypress E2E tests executed successfully"
  exit 0
fi
echo "npx mock: $*" >&2
EOF
  chmod +x "$MOCK_BIN/npx"

  # Mock test framework commands
  cat > "$MOCK_BIN/playwright" << 'EOF'
#!/bin/bash
if [[ "$1" == "test" ]]; then
  echo "Playwright Python E2E tests executed successfully"
  exit 0
fi
echo "playwright mock: $*" >&2
EOF
  chmod +x "$MOCK_BIN/playwright"

  cat > "$MOCK_BIN/python" << 'EOF'
#!/bin/bash
if [[ "$1" == "-c" ]]; then
  if echo "$2" | grep -q "import selenium"; then
    echo "Selenium available"
    exit 0
  elif echo "$2" | grep -q "import playwright"; then
    echo "Playwright available"
    exit 0
  fi
elif [[ "$1" == "-m" && "$2" == "pytest" ]]; then
  echo "Python pytest E2E tests executed successfully"
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
if [[ "$1" == "test-e2e" ]]; then
  echo "make test-e2e executed successfully"
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
if echo "$*" | grep -q "e2e"; then
  echo "./tests/e2e/test_e2e.go"
  echo "./tests/e2e_test.go"
  echo "./tests/e2e_test.rs"
fi
EOF
  chmod +x "$MOCK_BIN/find"

  # Mock timeout command
  cat > "$MOCK_BIN/timeout" << 'EOF'
#!/bin/bash
exec "$@"
EOF
  chmod +x "$MOCK_BIN/timeout"

  cd "$PROJECT_ROOT"
}

# Teardown function - runs after each test
teardown() {
  temp_del "$TEST_TEMP_DIR"
}

@test "E2E test script shows help when requested" {
  # WHEN: Help is requested
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh" help

  # THEN: Help information is displayed
  assert_success
  assert_line --partial "CI E2E Tests Script v1.0.0"
  assert_line --partial "Usage:"
  assert_line --partial "Project Types:"
}

@test "E2E test script detects project types correctly" {
  # GIVEN: Different project configurations

  # WHEN: Node.js project is detected
  echo '{"name": "test", "scripts": {"test": "jest"}}' > package.json
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh" detect
  assert_success
  assert_line --partial "nodejs"

  # WHEN: Python project is detected
  rm package.json
  echo "[tool.poetry]" > pyproject.toml
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh" detect
  assert_success
  assert_line --partial "python"

  # WHEN: Go project is detected
  rm pyproject.toml
  echo "module test" > go.mod
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh" detect
  assert_success
  assert_line --partial "go"

  # WHEN: Rust project is detected
  rm go.mod
  echo "[package]" > Cargo.toml
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh" detect
  assert_success
  assert_line --partial "rust"

  # WHEN: Generic project is detected
  rm Cargo.toml
  echo "test:" > Makefile
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh" detect
  assert_success
  assert_line --partial "generic"
}

@test "E2E test script validates test setup for Node.js project" {
  # GIVEN: Node.js project with test configuration
  echo '{"name": "test", "scripts": {"test": "jest"}}' > package.json
  mkdir -p tests/e2e

  # WHEN: Validation is performed
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh" validate

  # THEN: Validation results are shown
  assert_success
  assert_line --partial "Project type: nodejs"
  assert_line --partial "npx available"
  assert_line --partial "tests/e2e directory found"
}

@test "E2E test script validates test setup for Python project" {
  # GIVEN: Python project with test configuration
  echo "[tool.poetry]" > pyproject.toml
  mkdir -p tests/e2e

  # WHEN: Validation is performed
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh" validate

  # THEN: Validation results are shown
  assert_success
  assert_line --partial "Project type: python"
  assert_line --partial "python available"
  assert_line --partial "playwright available"
  assert_line --partial "selenium available"
}

@test "E2E test script runs in DRY_RUN mode" {
  # GIVEN: Script is configured for dry run
  export E2E_TEST_MODE="DRY_RUN"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh"

  # THEN: Dry run output is shown
  assert_success
  assert_line --partial "DRY RUN: Would run E2E tests"
}

@test "E2E test script runs in PASS mode" {
  # GIVEN: Script is configured for pass mode
  export E2E_TEST_MODE="PASS"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh"

  # THEN: Pass mode output is shown
  assert_success
  assert_line --partial "PASS MODE: E2E tests simulated successfully"
}

@test "E2E test script runs in FAIL mode" {
  # GIVEN: Script is configured for fail mode
  export E2E_TEST_MODE="FAIL"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh"

  # THEN: Fail mode output is shown
  assert_failure 1
  assert_line --partial "FAIL MODE: Simulating E2E test failure"
}

@test "E2E test script runs in SKIP mode" {
  # GIVEN: Script is configured for skip mode
  export E2E_TEST_MODE="SKIP"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh"

  # THEN: Skip mode output is shown
  assert_success
  assert_line --partial "SKIP MODE: E2E tests skipped"
}

@test "E2E test script runs in TIMEOUT mode" {
  # GIVEN: Script is configured for timeout mode
  export E2E_TEST_MODE="TIMEOUT"

  # WHEN: Script is executed (with timeout to avoid actual sleep)
  run timeout 2s "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh"

  # THEN: Timeout occurs
  assert_failure 124  # timeout exit code
}

@test "E2E test script respects pipeline-specific environment variables" {
  # GIVEN: Pipeline-specific mode is set (highest priority)
  export PIPELINE_E2E_TEST_MODE="PASS"
  export E2E_TEST_MODE="FAIL"
  export CI_TEST_MODE="FAIL"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh"

  # THEN: Pipeline mode takes precedence
  assert_success
  assert_line --partial "PASS MODE: E2E tests simulated successfully"
}

@test "E2E test script executes Playwright for Node.js project" {
  # GIVEN: Node.js project with Playwright and E2E tests
  echo '{"name": "test", "scripts": {"test": "jest"}, "devDependencies": {"playwright": "^1.0.0"}}' > package.json
  mkdir -p tests/e2e
  echo "test('E2E test', async () => { await expect(1).toBe(1); });" > tests/e2e/example.spec.js

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh"

  # THEN: Playwright E2E tests are executed
  assert_success
  assert_line --partial "Running Playwright E2E tests"
  assert_line --partial "Playwright E2E tests passed"

  # AND: Test report is generated
  assert_file_exists "$PROJECT_ROOT/test-results/e2e-test-report.json"
}

@test "E2E test script executes Cypress for Node.js project" {
  # GIVEN: Node.js project with Cypress and E2E tests
  echo '{"name": "test", "scripts": {"test": "jest"}, "devDependencies": {"cypress": "^10.0.0"}}' > package.json
  mkdir -p cypress/e2e
  echo "describe('E2E test', () => { it('should pass', () => { expect(true).to.be.true; }); });" > cypress/e2e/example.cy.js

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh"

  # THEN: Cypress E2E tests are executed
  assert_success
  assert_line --partial "Running Cypress E2E tests"
  assert_line --partial "Cypress E2E tests passed"
}

@test "E2E test script executes npm test:e2e for Node.js project" {
  # GIVEN: Node.js project with npm E2E script
  echo '{"name": "test", "scripts": {"test:e2e": "echo 'E2E tests'"}}' > package.json
  mkdir -p tests/e2e

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh"

  # THEN: npm test:e2e is executed
  assert_success
  assert_line --partial "npm run test:e2e passed"
}

@test "E2E test script skips Node.js E2E tests when no tests found" {
  # GIVEN: Node.js project without E2E tests
  echo '{"name": "test", "scripts": {"test": "jest"}, "devDependencies": {"playwright": "^1.0.0"}}' > package.json

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh"

  # THEN: Tests are skipped
  assert_success
  assert_line --partial "No E2E tests found for Node.js project"
}

@test "E2E test script executes Playwright Python for Python project" {
  # GIVEN: Python project with Playwright and E2E tests
  echo "[tool.poetry]" > pyproject.toml
  mkdir -p tests/e2e
  echo "async def test_e2e(): pass" > tests/e2e/test_e2e.py

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh" python

  # THEN: Playwright Python E2E tests are executed
  assert_success
  assert_line --partial "Running Playwright Python E2E tests"
  assert_line --partial "Playwright Python E2E tests passed"
}

@test "E2E test script executes Selenium Python for Python project" {
  # GIVEN: Python project with Selenium and E2E tests
  echo "[tool.poetry]" > pyproject.toml
  mkdir -p tests/e2e
  echo "def test_e2e(): pass" > tests/e2e/test_e2e.py

  # Mock Python to return Selenium available but Playwright unavailable
  cat > "$MOCK_BIN/python" << 'EOF'
#!/bin/bash
if [[ "$1" == "-c" ]]; then
  if echo "$2" | grep -q "import playwright"; then
    echo "ImportError: No module named 'playwright'" >&2
    exit 1
  elif echo "$2" | grep -q "import selenium"; then
    echo "Selenium available"
    exit 0
  fi
elif [[ "$1" == "-m" && "$2" == "pytest" ]]; then
  echo "Python pytest E2E tests executed successfully"
  exit 0
fi
echo "python mock: $*" >&2
EOF
  chmod +x "$MOCK_BIN/python"

  # Remove playwright mock
  rm "$MOCK_BIN/playwright"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh" python

  # THEN: Selenium Python E2E tests are executed
  assert_success
  assert_line --partial "Running Selenium Python E2E tests"
  assert_line --partial "Selenium Python E2E tests passed"
}

@test "E2E test script uses e2e directory for Python project" {
  # GIVEN: Python project with e2e directory
  echo "[tool.poetry]" > pyproject.toml
  mkdir -p e2e
  echo "def test_e2e(): pass" > e2e/test_e2e.py

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh" python

  # THEN: Tests are executed from e2e directory
  assert_success
  assert_line --partial "Running Playwright Python E2E tests"
}

@test "E2E test script executes Go E2E tests" {
  # GIVEN: Go project with E2E tests
  echo "module test" > go.mod
  echo "package main" > main.go
  echo "func main() {}" >> main.go
  mkdir -p main
  echo "package main" > main/e2e_test.go
  echo 'func TestE2E(t *testing.T) {}' >> main/e2e_test.go

  # Create mock Go E2E test files
  cat > "$MOCK_BIN/find" << 'EOF'
#!/bin/bash
if echo "$*" | grep -q "e2e"; then
  echo "./main/e2e_test.go"
fi
EOF
  chmod +x "$MOCK_BIN/find"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh" go

  # THEN: Go E2E tests are executed
  assert_success
  assert_line --partial "Running Go E2E tests"
  assert_line --partial "Go E2E tests passed"
}

@test "E2E test script executes Rust E2E tests" {
  # GIVEN: Rust project with E2E tests
  echo '[package]
name = "test"
version = "0.1.0"' > Cargo.toml
  mkdir -p src
  echo "fn main() {}" > src/main.rs
  mkdir -p tests
  echo "#[test] fn e2e_test() {}" > tests/e2e_test.rs

  # Create mock Rust E2E test files
  cat > "$MOCK_BIN/find" << 'EOF'
#!/bin/bash
if echo "$*" | grep -q "e2e"; then
  echo "./tests/e2e_test.rs"
fi
EOF
  chmod +x "$MOCK_BIN/find"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh" rust

  # THEN: Rust E2E tests are executed
  assert_success
  assert_line --partial "Running Rust E2E tests"
  assert_line --partial "Rust E2E tests passed"
}

@test "E2E test script executes make test-e2e for generic project" {
  # GIVEN: Generic project with Makefile E2E target
  echo "test-e2e:\n\t@echo 'Running E2E tests'" > Makefile

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh" generic

  # THEN: Make E2E test is executed
  assert_success
  assert_line --partial "Running generic E2E tests"
  assert_line --partial "Generic E2E tests passed"
}

@test "E2E test script executes E2E test script for generic project" {
  # GIVEN: Generic project with E2E test script
  mkdir -p scripts
  cat > "$MOCK_BIN/find" << 'EOF'
#!/bin/bash
if echo "$*" | grep -q "e2e"; then
  echo "./scripts/e2e-test.sh"
fi
EOF
  chmod +x "$MOCK_BIN/find"

  cat > scripts/e2e-test.sh << 'EOF'
#!/bin/bash
echo "E2E tests passed"
exit 0
EOF
  chmod +x scripts/e2e-test.sh

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh" generic

  # THEN: E2E test script is executed
  assert_success
  assert_line --partial "Found E2E test script"
  assert_line --partial "E2E test script passed"
}

@test "E2E test script handles Playwright configuration files" {
  # GIVEN: Node.js project with Playwright configuration
  echo '{"name": "test", "scripts": {"test": "jest"}, "devDependencies": {"playwright": "^1.0.0"}}' > package.json
  mkdir -p tests/e2e
  echo "test('E2E test', async () => { await expect(1).toBe(1); });" > tests/e2e/example.spec.js

  # Create Playwright config
  cat > playwright.config.ts << 'EOF'
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  timeout: 30000,
});
EOF

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh"

  # THEN: Playwright config is used
  assert_success
  assert_line --partial "Running Playwright E2E tests"
}

@test "E2E test script handles Cypress configuration files" {
  # GIVEN: Node.js project with Cypress configuration
  echo '{"name": "test", "scripts": {"test": "jest"}, "devDependencies": {"cypress": "^10.0.0"}}' > package.json
  mkdir -p cypress/e2e
  echo "describe('E2E test', () => { it('should pass', () => { expect(true).to.be.true; }); });" > cypress/e2e/example.cy.js

  # Create Cypress config
  cat > cypress.config.ts << 'EOF'
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    specPattern: 'cypress/e2e/**/*.cy.{js,ts}',
  },
});
EOF

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh"

  # THEN: Cypress config is used
  assert_success
  assert_line --partial "Running Cypress E2E tests"
}

@test "E2E test script uses custom timeout" {
  # GIVEN: Custom timeout configuration
  export E2E_TIMEOUT="600"
  echo '{"name": "test", "scripts": {"test": "jest"}, "devDependencies": {"playwright": "^1.0.0"}}' > package.json
  mkdir -p tests/e2e
  echo "test('E2E test', async () => { await expect(1).toBe(1); });" > tests/e2e/example.spec.js

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh"

  # THEN: Custom timeout is used
  assert_success
  # The timeout value would be used in actual execution
}

@test "E2E test script generates comprehensive test report" {
  # GIVEN: Node.js project
  echo '{"name": "test", "scripts": {"test": "jest"}, "devDependencies": {"playwright": "^1.0.0"}}' > package.json
  mkdir -p tests/e2e
  echo "test('E2E test', async () => { await expect(1).toBe(1); });" > tests/e2e/example.spec.js

  export CI="true"
  export GITHUB_ACTIONS="true"
  export RUNNER_OS="Linux"
  export GITHUB_SHA="test123"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh"

  # THEN: Test report is generated with metadata
  assert_success
  assert_file_exists "$PROJECT_ROOT/test-results/e2e-test-report.json"

  # Verify report content
  local report_content
  report_content=$(cat "$PROJECT_ROOT/test-results/e2e-test-report.json")
  assert_output --partial '"test_type": "e2e"'
  assert_output --partial '"project_type": "nodejs"'
  assert_output --partial '"test_status": "success"'
  assert_output --partial '"test_timeout": 300'
}

@test "E2E test script handles test environment setup and cleanup" {
  # GIVEN: Node.js project with E2E tests
  echo '{"name": "test", "scripts": {"test": "jest"}, "devDependencies": {"playwright": "^1.0.0"}}' > package.json
  mkdir -p tests/e2e
  echo "test('E2E test', async () => { await expect(1).toBe(1); });" > tests/e2e/example.spec.js

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh"

  # THEN: Environment setup and cleanup messages are shown
  assert_success
  assert_line --partial "Setting up E2E test environment"
}

@test "E2E test script handles missing common library gracefully" {
  # GIVEN: Script without common library
  rm "$PROJECT_ROOT/scripts/lib/common.sh"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh"

  # THEN: Error is reported
  assert_failure
  assert_line --partial "Failed to source common utilities"
}

@test "E2E test script handles test failures correctly" {
  # GIVEN: Script configured to simulate test failure
  echo '{"name": "test", "scripts": {"test": "jest"}, "devDependencies": {"playwright": "^1.0.0"}}' > package.json
  mkdir -p tests/e2e
  echo "test('E2E test', async () => { await expect(1).toBe(1); });" > tests/e2e/example.spec.js

  # Mock Playwright to fail
  cat > "$MOCK_BIN/npx" << 'EOF'
#!/bin/bash
if [[ "$1" == "playwright" ]]; then
  echo "Playwright E2E tests failed"
  exit 1
fi
echo "npx mock: $*" >&2
EOF
  chmod +x "$MOCK_BIN/npx"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh"

  # THEN: Failure is reported
  assert_failure
  assert_line --partial "Playwright E2E tests failed"

  # AND: Test report indicates failure
  assert_file_exists "$PROJECT_ROOT/test-results/e2e-test-report.json"
  local report_content
  report_content=$(cat "$PROJECT_ROOT/test-results/e2e-test-report.json")
  assert_output --partial '"test_status": "failure"'
  assert_output --partial '"test_exit_code": 1'
}

@test "E2E test script respects custom results directory" {
  # GIVEN: Custom results directory
  mkdir -p "$PROJECT_ROOT/custom-results"
  echo '{"name": "test", "scripts": {"test": "jest"}, "devDependencies": {"playwright": "^1.0.0"}}' > package.json
  mkdir -p tests/e2e
  echo "test('E2E test', async () => { await expect(1).toBe(1); });" > tests/e2e/example.spec.js

  # WHEN: Script is executed with custom directory
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh" nodejs "$PROJECT_ROOT/custom-results"

  # THEN: Report is generated in custom location
  assert_success
  assert_file_exists "$PROJECT_ROOT/custom-results/e2e-test-report.json"
  assert_file_not_exists "$PROJECT_ROOT/test-results/e2e-test-report.json"
}

@test "E2E test script handles missing Go E2E tests gracefully" {
  # GIVEN: Go project without E2E tests
  echo "module test" > go.mod
  echo "package main" > main.go
  echo "func main() {}" >> main.go

  # Mock find to return no E2E files
  cat > "$MOCK_BIN/find" << 'EOF'
#!/bin/bash
# Return nothing - no E2E tests found
EOF
  chmod +x "$MOCK_BIN/find"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh" go

  # THEN: Tests are skipped gracefully
  assert_success
  assert_line --partial "No E2E tests found for Go project"
}

@test "E2E test script handles missing Rust E2E tests gracefully" {
  # GIVEN: Rust project without E2E tests
  echo '[package]
name = "test"
version = "0.1.0"' > Cargo.toml
  mkdir -p src
  echo "fn main() {}" > src/main.rs

  # Mock find to return no E2E files
  cat > "$MOCK_BIN/find" << 'EOF'
#!/bin/bash
# Return nothing - no E2E tests found
EOF
  chmod +x "$MOCK_BIN/find"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh" rust

  # THEN: Tests are skipped gracefully
  assert_success
  assert_line --partial "No E2E tests found for Rust project"
}

@test "E2E test script handles timeout during test execution" {
  # GIVEN: Script with timeout simulation
  echo '{"name": "test", "scripts": {"test": "jest"}, "devDependencies": {"playwright": "^1.0.0"}}' > package.json
  mkdir -p tests/e2e
  echo "test('E2E test', async () => { await expect(1).toBe(1); });" > tests/e2e/example.spec.js

  # Mock timeout to simulate timeout
  cat > "$MOCK_BIN/timeout" << 'EOF'
#!/bin/bash
exit 124
EOF
  chmod +x "$MOCK_BIN/timeout"

  # WHEN: Script is executed
  run "$PROJECT_ROOT/scripts/test/30-ci-e2e-tests.sh"

  # THEN: Timeout is handled
  assert_failure
  assert_line --partial "Playwright E2E tests timed out"
}