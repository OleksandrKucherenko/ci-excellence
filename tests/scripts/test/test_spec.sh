#!/usr/bin/env bash
# ShellSpec tests for CI Test Execution Script
# Tests test execution with different test types and testability modes

set -euo pipefail

# Load the script under test
# shellcheck disable=SC1090,SC1091
. "$(dirname "$0")/../../../scripts/test/10-ci-unit-tests.sh" 2>/dev/null || {
  echo "Failed to source 10-ci-unit-tests.sh" >&2
  exit 1
}

# Setup test environment
setup_test_environment() {
  # Create test directory
  mkdir -p "/tmp/test-test"
  cd "/tmp/test-test"

  # Create project structure for different test types
  mkdir -p nodejs-project/{src,tests,docs}
  mkdir -p python-project/{src,tests,docs}
  mkdir -p go-project/{cmd,internal,pkg,test,docs}
  mkdir -p rust-project/{src,tests,docs}
  mkdir -p generic-project/{src,tests,docs}

  # Create Node.js test files
  mkdir -p nodejs-project/tests/unit
  cat > nodejs-project/tests/unit/hello.test.ts << 'EOF'
import { hello } from '../../src/index';

describe('hello function', () => {
  it('should return greeting with name', () => {
    expect(hello('World')).toBe('Hello, World!');
  });

  it('should handle empty string', () => {
    expect(hello('')).toBe('Hello, !');
  });
});
EOF

  cat > nodejs-project/tests/integration/api.test.ts << 'EOF'
describe('API integration', () => {
  it('should handle API requests', () => {
    // Integration test placeholder
    expect(true).toBe(true);
  });
});
EOF

  # Create Python test files
  mkdir -p python-project/tests/unit
  cat > python-project/tests/unit/test_main.py << 'EOF'
import unittest
from src.main import hello

class TestMain(unittest.TestCase):
    def test_hello(self):
        self.assertEqual(hello('World'), 'Hello, World!')

    def test_hello_empty(self):
        self.assertEqual(hello(''), 'Hello, !')

if __name__ == '__main__':
    unittest.main()
EOF

  cat > python-project/tests/integration/test_api.py << 'EOF'
import unittest

class TestAPI(unittest.TestCase):
    def test_api_integration(self):
        # Integration test placeholder
        self.assertTrue(True)

if __name__ == '__main__':
    unittest.main()
EOF

  # Create Go test files
  cat > go-project/main_test.go << 'EOF'
package main

import (
  "testing"
  "test-go-project/internal/greeter"
)

func TestMain(t *testing.T) {
  expected := "Hello, World!"
  actual := greeter.Hello("World")

  if actual != expected {
    t.Errorf("Expected %q, got %q", expected, actual)
  }
}
EOF

  cat > go-project/internal/greeter/greeter_test.go << 'EOF'
package greeter

import (
  "testing"
)

func TestHello(t *testing.T) {
  tests := []struct {
    name     string
    input    string
    expected string
  }{
    {
      name:     "standard greeting",
      input:    "World",
      expected: "Hello, World!",
    },
    {
      name:     "empty input",
      input:    "",
      expected: "Hello, !",
    },
  }

  for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) {
      actual := Hello(tt.input)
      if actual != tt.expected {
        t.Errorf("Hello() = %q, want %q", actual, tt.expected)
      }
    })
  }
}

func BenchmarkHello(b *testing.B) {
  for i := 0; i < b.N; i++ {
    _ = Hello("World")
  }
}
EOF

  # Create Rust test files
  cat > rust-project/src/lib.rs << 'EOF'
pub mod greeter;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_greeter_module() {
        assert_eq!(greeter::hello("Test"), "Hello, Test!");
    }
}
EOF

  cat > rust-project/tests/integration_tests.rs << 'EOF'
use test_rust_project::greeter;

#[test]
fn test_greeter_integration() {
    assert_eq!(greeter::hello("Integration"), "Hello, Integration!");
}
EOF

  # Create generic test files
  mkdir -p generic-project/tests
  cat > generic-project/tests/test_main.sh << 'EOF'
#!/bin/bash
# Generic test script

echo "Running unit tests..."
# Simulate test execution
sleep 0.1
echo "✅ Unit tests passed"

echo "Running integration tests..."
sleep 0.1
echo "✅ Integration tests passed"

echo "Running e2e tests..."
sleep 0.1
echo "✅ E2E tests passed"
EOF
  chmod +x generic-project/tests/test_main.sh

  cat > generic-project/Makefile << 'EOF'
.PHONY: test test-unit test-integration test-e2e test-benchmark

test:
	@echo "Running all tests..."
	@./tests/test_main.sh

test-unit:
	@echo "Running unit tests..."
	@echo "✅ Unit tests passed"

test-integration:
	@echo "Running integration tests..."
	@echo "✅ Integration tests passed"

test-e2e:
	@echo "Running e2e tests..."
	@echo "✅ E2E tests passed"

test-benchmark:
	@echo "Running benchmarks..."
	@echo "✅ Benchmarks completed"
EOF

  # Set test environment variables
  export PROJECT_TYPE="nodejs"
  export PROJECT_ROOT="/tmp/test-test/nodejs-project"
  export TEST_TYPE="unit"
}

# Cleanup test environment
cleanup_test_environment() {
  cd - >/dev/null
  rm -rf "/tmp/test-test"
}

# Mock test tools
mock_test_tools() {
  # Mock npm test commands
  npm() {
    case "$1" in
      "test")
        echo "Running npm test..."
        if [[ "${TEST_FAIL:-}" == "true" ]]; then
          echo "❌ Tests failed" >&2
          return 1
        else
          echo "✅ All tests passed"
        fi
        ;;
      "run")
        case "$2" in
          "test:unit")
            echo "Running unit tests..."
            echo "✅ Unit tests passed"
            ;;
          "test:integration")
            echo "Running integration tests..."
            echo "✅ Integration tests passed"
            ;;
          "test-coverage")
            echo "Running tests with coverage..."
            echo "Coverage report generated"
            echo "Coverage: 85.42%"
            ;;
          *)
            echo "Running npm $2..."
            ;;
        esac
        ;;
      *)
        echo "npm $* command simulated"
        ;;
    esac
  }

  # Mock Python test commands
  python() {
    case "$1" in
      "-m"*)
        case "$2" in
          "pytest")
            echo "Running pytest..."
            if [[ "${TEST_FAIL:-}" == "true" ]]; then
              echo "❌ Tests failed" >&2
              return 1
            else
              echo "✅ All tests passed"
            fi
            ;;
          "unittest")
            echo "Running unittest..."
            echo "✅ Unit tests passed"
            ;;
          *)
            echo "Python $2 simulated"
            ;;
        esac
        ;;
      *)
        echo "Python command simulated"
        ;;
    esac
  }

  # Mock coverage commands
  coverage() {
    echo "Running coverage analysis..."
    echo "Coverage report generated"
    echo "Total coverage: 87.3%"
  }

  # Mock Go test commands
  go() {
    case "$1" in
      "test")
        if [[ "${TEST_FAIL:-}" == "true" ]]; then
          echo "❌ Go tests failed" >&2
          return 1
        else
          echo "Running Go tests..."
          echo "✅ All tests passed"
          echo "Coverage: 82.1% of statements"
        fi
        ;;
      "test"*)
        echo "Running go $*..."
        echo "✅ Tests passed"
        ;;
      *)
        echo "go $* command simulated"
        ;;
    esac
  }

  # Mock Rust test commands
  cargo() {
    case "$1" in
      "test")
        if [[ "${TEST_FAIL:-}" == "true" ]]; then
          echo "❌ Rust tests failed" >&2
          return 1
        else
          echo "Running Rust tests..."
          echo "✅ All tests passed"
        fi
        ;;
      "test"*)
        echo "Running cargo $*..."
        echo "✅ Tests passed"
        ;;
      *)
        echo "cargo $* command simulated"
        ;;
    esac
  }

  # Mock make test commands
  make() {
    case "$1" in
      "test"|"test-unit"|"test-integration"|"test-e2e"|"test-benchmark")
        if [[ "${TEST_FAIL:-}" == "true" ]]; then
          echo "❌ Make tests failed" >&2
          return 1
        else
          echo "Running make $1..."
          echo "✅ Tests passed"
        fi
        ;;
      *)
        echo "make $* command simulated"
        ;;
    esac
  }
}

# Mock logging functions
mock_logging_functions() {
  log_info() {
    echo "[INFO] $*"
  }

  log_success() {
    echo "[SUCCESS] $*"
  }

  log_error() {
    echo "[ERROR] $*" >&2
  }

  log_warn() {
    echo "[WARN] $*" >&2
  }

  log_debug() {
    echo "[DEBUG] $*" >&2
  }
}

Describe "CI Test Execution Script"
  BeforeEach "setup_test_environment"
  BeforeEach "mock_test_tools"
  BeforeEach "mock_logging_functions"
  AfterEach "cleanup_test_environment"

  Describe "Test type detection"
    Context "when detecting test types"
      It "should detect unit tests in Node.js project"
        When call detect_test_types "/tmp/test-test/nodejs-project"
        The output should include "unit"
      End

      It "should detect integration tests in Node.js project"
        When call detect_test_types "/tmp/test-test/nodejs-project"
        The output should include "integration"
      End

      It "should detect unit tests in Python project"
        When call detect_test_types "/tmp/test-test/python-project"
        The output should include "unit"
      End

      It "should detect test files in Go project"
        When call detect_test_types "/tmp/test-test/go-project"
        The output should include "unit"
      End

      It "should detect test files in Rust project"
        When call detect_test_types "/tmp/test-test/rust-project"
        The output should include "unit"
        The output should include "integration"
      End
    End
  End

  Describe "Test execution by project type"
    Context "when running Node.js tests"
      It "should run unit tests"
        When call run_nodejs_tests "unit"
        The output should include "Running npm test..."
        The output should include "✅ All tests passed"
      End

      It "should run integration tests"
        When call run_nodejs_tests "integration"
        The output should include "Running integration tests..."
        The output should include "✅ Integration tests passed"
      End

      It "should run tests with coverage"
        When call run_nodejs_tests "coverage"
        The output should include "Running tests with coverage..."
        The output should include "Coverage: 85.42%"
      End
    End

    Context "when running Python tests"
      BeforeEach "export PROJECT_ROOT=/tmp/test-test/python-project"

      It "should run unit tests with pytest"
        When call run_python_tests "unit"
        The output should include "Running pytest..."
        The output should include "✅ All tests passed"
      End

      It "should run tests with coverage"
        When call run_python_tests "coverage"
        The output should include "Running coverage analysis..."
        The output should include "Total coverage: 87.3%"
      End

      It "should run integration tests"
        When call run_python_tests "integration"
        The output should include "Running integration tests..."
        The output should include "✅ Integration tests passed"
      End
    End

    Context "when running Go tests"
      BeforeEach "export PROJECT_ROOT=/tmp/test-test/go-project"

      It "should run unit tests"
        When call run_go_tests "unit"
        The output should include "Running Go tests..."
        The output should include "✅ All tests passed"
        The output should include "Coverage: 82.1% of statements"
      End

      It "should run benchmarks"
        When call run_go_tests "benchmark"
        The output should include "Running go test -bench..."
        The output should include "✅ Benchmarks completed"
      End
    End

    Context "when running Rust tests"
      BeforeEach "export PROJECT_ROOT=/tmp/test-test/rust-project"

      It "should run unit tests"
        When call run_rust_tests "unit"
        The output should include "Running Rust tests..."
        The output should include "✅ All tests passed"
      End

      It "should run integration tests"
        When call run_rust_tests "integration"
        The output should include "Running integration tests..."
        The output should include "✅ Integration tests passed"
      End
    End

    Context "when running generic project tests"
      BeforeEach "export PROJECT_ROOT=/tmp/test-test/generic-project"

      It "should run all tests"
        When call run_generic_tests "all"
        The output should include "Running make test..."
        The output should include "✅ Tests passed"
      End

      It "should run unit tests"
        When call run_generic_tests "unit"
        The output should include "Running make test-unit..."
        The output should include "✅ Tests passed"
      End

      It "should run integration tests"
        When call run_generic_tests "integration"
        The output should include "Running make test-integration..."
        The output should include "✅ Tests passed"
      End
    End
  End

  Describe "Testability modes"
    Context "when in EXECUTE mode"
      BeforeEach "export TEST_MODE=EXECUTE"

      It "should actually run tests"
        When call run_tests
        The output should include "🚀 EXECUTE: Running tests"
        The output should include "Running npm test..."
        The output should include "✅ All tests passed"
      End
    End

    Context "when in DRY_RUN mode"
      BeforeEach "export TEST_MODE=DRY_RUN"

      It "should simulate test execution"
        When call run_tests
        The output should include "🔍 DRY_RUN: Would run tests"
        The output should not include "Running npm test..."
      End
    End

    Context "when in PASS mode"
      BeforeEach "export TEST_MODE=PASS"

      It "should simulate successful test execution"
        When call run_tests
        The output should include "✅ PASS MODE: Tests simulated successfully"
        The output should not include "Running npm test..."
      End
    End

    Context "when in FAIL mode"
      BeforeEach "export TEST_MODE=FAIL"

      It "should simulate test execution failure"
        When call run_tests
        The status should be failure
        The output should include "❌ FAIL MODE: Simulating test failure"
        The output should not include "Running npm test..."
      End
    End

    Context "when in SKIP mode"
      BeforeEach "export TEST_MODE=SKIP"

      It "should skip test execution"
        When call run_tests
        The output should include "⏭️ SKIP MODE: Tests skipped"
        The output should not include "Running npm test..."
      End
    End

    Context "when in TIMEOUT mode"
      BeforeEach "export TEST_MODE=TIMEOUT"

      It "should simulate test execution timeout"
        When run timeout 2s run_tests
        The status should equal 124  # TIMEOUT exit code
        The output should include "⏰ TIMEOUT MODE: Simulating test timeout"
      End
    End
  End

  Describe "Test result reporting"
    Context "when generating test reports"
      It "should create test results directory"
        When call ensure_test_results_directory
        The directory "/tmp/test-test/nodejs-project/test-results" should exist
      End

      It "should generate test report"
        When call generate_test_report
        The file "/tmp/test-test/nodejs-project/test-results/test-report.json" should exist
      End

      It "should include test metadata in report"
        When call generate_test_report
        The contents of file "/tmp/test-test/nodejs-project/test-results/test-report.json" should include "test_timestamp"
        The contents of file "/tmp/test-test/nodejs-project/test-results/test-report.json" should include "project_type"
        The contents of file "/tmp/test-test/nodejs-project/test-results/test-report.json" should include "test_type"
      End

      It "should generate coverage report"
        When call run_tests "coverage"
        The file "/tmp/test-test/nodejs-project/test-results/coverage.json" should exist
      End
    End
  End

  Describe "Error handling"
    Context "when tests fail"
      It "should handle test failures gracefully"
        BeforeEach "export TEST_FAIL=true"

        When call run_tests
        The status should be failure
        The output should include "Tests failed"
      End
    End

    Context "when test directory doesn't exist"
      It "should handle missing test directory gracefully"
        When call detect_test_types "/nonexistent/tests"
        The output should be blank
      End
    End

    Context "when test tools are not available"
      BeforeEach "unset -f npm"

      It "should handle missing tools gracefully"
        When call run_nodejs_tests "unit"
        The status should be failure
        The output should include "npm is not available"
      End
    End
  End

  Describe "Test configuration"
    Context "when configuring test execution"
      It "should respect test type filter"
        BeforeEach "export TEST_TYPE=integration"
        BeforeEach "export TEST_MODE=EXECUTE"

        When call run_tests
        The output should include "Running integration tests..."
        The output should not include "Running unit tests..."
      End

      It "should support multiple test types"
        BeforeEach "export TEST_TYPE=unit,integration"
        BeforeEach "export TEST_MODE=EXECUTE"

        When call run_tests
        The output should include "Running unit tests..."
        The output should include "Running integration tests..."
      End

      It "should run all tests when no type specified"
        BeforeEach "export TEST_TYPE=all"
        BeforeEach "export TEST_MODE=EXECUTE"

        When call run_tests
        The output should include "Running all test types"
      End
    End
  End

  Describe "Main test function"
    Context "when running main test execution"
      It "should use auto-detected project type"
        BeforeEach "export TEST_MODE=EXECUTE"
        BeforeEach "export PROJECT_ROOT=/tmp/test-test/nodejs-project"

        When call main
        The output should include "Running tests for nodejs project"
        The output should include "Running npm test..."
      End

      It "should respect manual project type override"
        BeforeEach "export TEST_MODE=EXECUTE"
        BeforeEach "export PROJECT_TYPE=python"
        BeforeEach "export PROJECT_ROOT=/tmp/test-test/python-project"

        When call main
        The output should include "Running tests for python project"
        The output should include "Running pytest..."
      End

      It "should generate comprehensive test report"
        BeforeEach "export TEST_MODE=EXECUTE"

        When call main
        The output should include "Tests completed successfully"
        The output should include "Test results generated"
      End
    End
  End
End