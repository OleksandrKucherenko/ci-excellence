#!/bin/bash
# CI Integration Tests Script with Full Testability Support
# Runs integration tests based on detected project type with hierarchical testability control

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common utilities" >&2
  exit 1
}

# Configuration
readonly INTEGRATION_TEST_SCRIPT_VERSION="1.0.0"
readonly DEFAULT_TEST_RESULTS_DIR="$PROJECT_ROOT/test-results"

# Testability configuration
get_script_behavior() {
  local script_name="ci_integration_tests"
  local default_behavior="EXECUTE"

  # Priority order: PIPELINE_INTEGRATION_TEST_MODE > INTEGRATION_TEST_MODE > CI_TEST_MODE > default
  local behavior

  # 1. Pipeline-specific override (highest priority)
  if [[ -n "${PIPELINE_INTEGRATION_TEST_MODE:-}" ]]; then
    behavior="$PIPELINE_INTEGRATION_TEST_MODE"
    log_debug "Using PIPELINE_INTEGRATION_TEST_MODE: $behavior"
  # 2. Script-specific override
  elif [[ -n "${INTEGRATION_TEST_MODE:-}" ]]; then
    behavior="$INTEGRATION_TEST_MODE"
    log_debug "Using INTEGRATION_TEST_MODE: $behavior"
  # 3. Global testability mode
  elif [[ -n "${CI_TEST_MODE:-}" ]]; then
    behavior="$CI_TEST_MODE"
    log_debug "Using CI_TEST_MODE: $behavior"
  # 4. Default behavior
  else
    behavior="$default_behavior"
    log_debug "Using default behavior: $behavior"
  fi

  echo "$behavior"
}

# Detect project type based on project structure
detect_project_type() {
  local project_path="${1:-$PROJECT_ROOT}"

  if [[ -f "$project_path/package.json" ]]; then
    echo "nodejs"
  elif [[ -f "$project_path/pyproject.toml" ]] || [[ -f "$project_path/setup.py" ]] || [[ -f "$project_path/requirements.txt" ]]; then
    echo "python"
  elif [[ -f "$project_path/go.mod" ]]; then
    echo "go"
  elif [[ -f "$project_path/Cargo.toml" ]]; then
    echo "rust"
  elif [[ -f "$project_path/Makefile" ]]; then
    echo "generic"
  else
    echo "generic"
  fi
}

# Detect available test types
detect_test_types() {
  local project_path="${1:-$PROJECT_ROOT}"
  local test_types=()

  # Check for integration tests
  if [[ -d "$project_path/tests/integration" ]] || [[ -d "$project_path/integration" ]]; then
    test_types+=("integration")
  fi

  printf '%s\n' "${test_types[@]}"
}

# Ensure test results directory exists
ensure_test_results_directory() {
  local results_dir="${1:-$DEFAULT_TEST_RESULTS_DIR}"

  mkdir -p "$results_dir"
  log_debug "Created test results directory: $results_dir"
}

# Generate test report
generate_test_report() {
  local project_type="${1:-$(detect_project_type)}"
  local test_type="${2:-integration}"
  local test_status="${3:-success}"
  local test_exit_code="${4:-0}"
  local results_dir="${5:-$DEFAULT_TEST_RESULTS_DIR}"

  local report_file="$results_dir/integration-test-report.json"

  cat > "$report_file" << EOF
{
  "test_timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "project_type": "$project_type",
  "test_type": "$test_type",
  "test_status": "$test_status",
  "test_exit_code": $test_exit_code,
  "test_mode": "$(get_script_behavior)",
  "integration_test_script_version": "$INTEGRATION_TEST_SCRIPT_VERSION",
  "test_environment": {
    "ci": "${CI:-false}",
    "github_actions": "${GITHUB_ACTIONS:-false}",
    "runner_os": "${RUNNER_OS:-unknown}",
    "github_sha": "${GITHUB_SHA:-$(git rev-parse HEAD 2>/dev/null || echo 'unknown')}"
  }
}
EOF

  log_debug "Generated test report: $report_file"
}

# Run Jest integration tests for Node.js projects
run_jest_integration() {
  log_info "Running Jest integration tests"

  if ! command -v npx >/dev/null 2>&1; then
    log_error "npx is not available"
    return 1
  fi

  local jest_args=()

  # Add test pattern
  jest_args+=("--testPathPattern=tests/integration" "--verbose")

  # Add JUnit XML output for CI
  jest_args+=("--reporters=default" "--reporters=jest-junit")

  # Setup test environment if needed
  if [[ -f "jest.integration.config.js" ]]; then
    jest_args+=("--config" "jest.integration.config.js")
  elif [[ -f "jest.config.js" ]]; then
    jest_args+=("--config" "jest.config.js")
  fi

  log_debug "Jest integration args: ${jest_args[*]}"

  if npx jest "${jest_args[@]}"; then
    log_success "Jest integration tests passed"
    return 0
  else
    log_error "Jest integration tests failed"
    return 1
  fi
}

# Run Mocha integration tests for Node.js projects
run_mocha_integration() {
  log_info "Running Mocha integration tests"

  if ! command -v npx >/dev/null 2>&1; then
    log_error "npx is not available"
    return 1
  fi

  local mocha_args=()

  # Add test pattern
  mocha_args+=("tests/integration/**/*.test.js" "tests/integration/**/*.test.ts")

  # Add reporter
  mocha_args+=("--reporter" "spec" "--reporter" "xunit" "--timeout" "10000")

  # Setup test environment
  mocha_args+=("--require" "ts-node/register")

  log_debug "Mocha integration args: ${mocha_args[*]}"

  if npx mocha "${mocha_args[@]}"; then
    log_success "Mocha integration tests passed"
    return 0
  else
    log_error "Mocha integration tests failed"
    return 1
  fi
}

# Run integration tests for Node.js project
run_nodejs_integration_tests() {
  log_info "Running Node.js integration tests"

  local test_success=true

  # Check if integration tests exist
  if [[ ! -d "tests/integration" ]] && [[ ! -d "integration" ]]; then
    log_info "No integration tests found for Node.js project"
    return 0
  fi

  # Try Jest first
  if grep -q "jest" package.json 2>/dev/null; then
    run_jest_integration || test_success=false
  # Try Mocha
  elif grep -q "mocha" package.json 2>/dev/null; then
    run_mocha_integration || test_success=false
  # Fall back to npm script
  elif npm run test:integration 2>/dev/null; then
    log_success "npm run test:integration passed"
  else
    log_warn "No integration test framework detected, skipping Node.js integration tests"
  fi

  return $([[ "$test_success" == "true" ]] && echo 0 || echo 1)
}

# Run pytest integration tests for Python projects
run_pytest_integration() {
  log_info "Running pytest integration tests"

  if ! command -v pytest >/dev/null 2>&1; then
    log_error "pytest is not available"
    return 1
  fi

  local pytest_args=()

  # Add test pattern
  if [[ -d "tests/integration" ]]; then
    pytest_args+=("tests/integration")
  elif [[ -d "integration" ]]; then
    pytest_args+=("integration")
  else
    log_info "No integration tests found for Python project"
    return 0
  fi

  pytest_args+=("-v" "--tb=short")

  # Add JUnit XML output
  pytest_args+=("--junitxml=test-results/integration-junit.xml")

  log_debug "Pytest integration args: ${pytest_args[*]}"

  if pytest "${pytest_args[@]}"; then
    log_success "Pytest integration tests passed"
    return 0
  else
    log_error "Pytest integration tests failed"
    return 1
  fi
}

# Run unittest integration tests for Python projects
run_unittest_integration() {
  log_info "Running unittest integration tests"

  if ! command -v python >/dev/null 2>&1; then
    log_error "python is not available"
    return 1
  fi

  local unittest_args=("-m" "unittest")

  # Add test pattern
  if [[ -d "tests/integration" ]]; then
    unittest_args+=("discover" "-s" "tests/integration" "-p" "*test*.py")
  elif [[ -d "integration" ]]; then
    unittest_args+=("discover" "-s" "integration" "-p" "*test*.py")
  else
    log_info "No integration tests found for Python project"
    return 0
  fi

  unittest_args+=("-v")

  log_debug "Unittest integration args: ${unittest_args[*]}"

  if python "${unittest_args[@]}"; then
    log_success "Unittest integration tests passed"
    return 0
  else
    log_error "Unittest integration tests failed"
    return 1
  fi
}

# Run integration tests for Python project
run_python_integration_tests() {
  log_info "Running Python integration tests"

  local test_success=true

  # Try pytest first
  if command -v pytest >/dev/null 2>&1; then
    run_pytest_integration || test_success=false
  # Try unittest
  elif command -v python >/dev/null 2>&1; then
    run_unittest_integration || test_success=false
  else
    log_error "No Python test framework available"
    return 1
  fi

  return $([[ "$test_success" == "true" ]] && echo 0 || echo 1)
}

# Run Go integration tests
run_go_integration_tests() {
  log_info "Running Go integration tests"

  if ! command -v go >/dev/null 2>&1; then
    log_error "go is not available"
    return 1
  fi

  local go_test_args=()

  # Look for integration test files
  local integration_files
  integration_files=$(find . -name "*integration*_test.go" -o -name "*_integration_test.go" 2>/dev/null || true)

  if [[ -z "$integration_files" ]]; then
    log_info "No integration tests found for Go project"
    return 0
  fi

  # Add test pattern (exclude unit tests)
  go_test_args+=("-run" "Integration")

  # Add verbose output
  go_test_args+=("-v")

  log_debug "Go test integration args: ${go_test_args[*]}"

  if go test "${go_test_args[@]}" ./...; then
    log_success "Go integration tests passed"
    return 0
  else
    log_error "Go integration tests failed"
    return 1
  fi
}

# Run Rust integration tests
run_rust_integration_tests() {
  log_info "Running Rust integration tests"

  if ! command -v cargo >/dev/null 2>&1; then
    log_error "cargo is not available"
    return 1
  fi

  local cargo_test_args=("test")

  # Look for integration test files
  local integration_files
  integration_files=$(find . -name "*integration*.rs" -o -name "tests/*integration*.rs" 2>/dev/null || true)

  if [[ -z "$integration_files" ]]; then
    log_info "No integration tests found for Rust project"
    return 0
  fi

  # Add test pattern (integration tests)
  cargo_test_args+=("--test" "*integration*")

  # Add verbose output
  cargo_test_args+=("--" "--nocapture")

  log_debug "Cargo test integration args: ${cargo_test_args[*]}"

  if cargo "${cargo_test_args[@]}"; then
    log_success "Rust integration tests passed"
    return 0
  else
    log_error "Rust integration tests failed"
    return 1
  fi
}

# Generic integration tests
run_generic_integration_tests() {
  log_info "Running generic integration tests"

  if [[ -f "Makefile" ]] && command -v make >/dev/null 2>&1; then
    if grep -q "test-integration\|integration-test" Makefile; then
      if make test-integration 2>/dev/null; then
        log_success "Generic integration tests passed"
        return 0
      fi
    fi
  fi

  # Look for integration test scripts
  local integration_script
  integration_script=$(find . -name "*integration*test*.sh" -type f 2>/dev/null | head -1)

  if [[ -n "$integration_script" ]]; then
    log_info "Found integration test script: $integration_script"
    if bash "$integration_script"; then
      log_success "Generic integration tests passed"
      return 0
    else
      log_error "Generic integration tests failed"
      return 1
    fi
  fi

  log_warn "No generic integration tests found"
  return 0
}

# Run integration tests for detected project type
run_integration_tests() {
  local project_type="${1:-$(detect_project_type)}"
  local results_dir="${2:-$DEFAULT_TEST_RESULTS_DIR}"
  local test_success=true

  ensure_test_results_directory "$results_dir"

  case "$project_type" in
    "nodejs")
      run_nodejs_integration_tests || test_success=false
      ;;
    "python")
      run_python_integration_tests || test_success=false
      ;;
    "go")
      run_go_integration_tests || test_success=false
      ;;
    "rust")
      run_rust_integration_tests || test_success=false
      ;;
    "generic")
      run_generic_integration_tests || test_success=false
      ;;
    *)
      log_warn "Unknown project type: $project_type, using generic integration tests"
      run_generic_integration_tests || test_success=false
      ;;
  esac

  local test_status="success"
  local test_exit_code=0

  if [[ "$test_success" != "true" ]]; then
    test_status="failure"
    test_exit_code=1
  fi

  generate_test_report "$project_type" "integration" "$test_status" "$test_exit_code" "$results_dir"

  return $test_exit_code
}

# Main integration tests function
main() {
  local project_type="${1:-}"
  local results_dir="${2:-$DEFAULT_TEST_RESULTS_DIR}"
  local behavior
  behavior=$(get_script_behavior)

  log_info "CI Integration Tests Script v$INTEGRATION_TEST_SCRIPT_VERSION"

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would run integration tests"
      if [[ -n "$project_type" ]]; then
        echo "Project type: $project_type"
      else
        echo "Project type: $(detect_project_type)"
      fi
      echo "Results directory: $results_dir"
      echo "Would run integration test suite"
      return 0
      ;;
    "PASS")
      echo "✅ PASS MODE: Integration tests simulated successfully"
      return 0
      ;;
    "FAIL")
      echo "❌ FAIL MODE: Simulating integration test failure"
      return 1
      ;;
    "SKIP")
      echo "⏭️ SKIP MODE: Integration tests skipped"
      return 0
      ;;
    "TIMEOUT")
      echo "⏰ TIMEOUT MODE: Simulating integration test timeout"
      sleep 5
      return 124
      ;;
  esac

  # EXECUTE mode - Actual integration testing
  log_info "🚀 EXECUTE: Running integration tests"

  # Use provided project type or detect automatically
  if [[ -z "$project_type" ]]; then
    project_type=$(detect_project_type)
  fi

  log_info "Project type: $project_type"
  log_info "Results directory: $results_dir"

  # Change to project root if not already there
  if [[ "$PWD" != "$PROJECT_ROOT" ]]; then
    cd "$PROJECT_ROOT"
  fi

  # Run integration tests
  if run_integration_tests "$project_type" "$results_dir"; then
    log_success "✅ Integration tests completed successfully"
    return 0
  else
    log_error "❌ Integration tests failed"
    return 1
  fi
}

# CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Parse command line arguments
  case "${1:-}" in
    "help"|"--help"|"-h")
      cat << EOF
CI Integration Tests Script v$INTEGRATION_TEST_SCRIPT_VERSION

Runs integration tests based on detected project type with full testability support.

Usage:
  ./scripts/test/20-ci-integration-tests.sh [project_type] [results_directory]

Project Types:
  nodejs   - Node.js project (Jest, Mocha)
  python   - Python project (pytest, unittest)
  go       - Go project (go test)
  rust     - Rust project (cargo test)
  generic  - Generic project (Makefile, test scripts)

Results Directory:
  Default: ./test-results
  Custom: Provide second argument

Test Types Supported:
- Integration tests (default)
- Unit tests (separate script)
- End-to-end tests (separate script)
- Benchmark tests (separate script)

Test Discovery:
- tests/integration/**/*.{test,test.js,test.ts}
- integration/**/*.{test,test.py,test.go,test.rs}
- *integration*_test.go, *_integration_test.go
- *integration*.rs
- Make test-integration targets

Environment Variables:
  PIPELINE_INTEGRATION_TEST_MODE  EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT
  INTEGRATION_TEST_MODE          EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT
  CI_TEST_MODE                   Global testability mode
  CI_JOB_TIMEOUT_MINUTES         Timeout override for test operations

Test Results:
- JUnit XML format for CI integration
- JSON metadata reports
- Detailed console output

Testability:
  This script supports hierarchical testability control:
  1. PIPELINE_INTEGRATION_TEST_MODE (highest priority)
  2. INTEGRATION_TEST_MODE
  3. CI_TEST_MODE (global)
  4. Default: EXECUTE

Examples:
  # Auto-detect and run integration tests
  ./scripts/test/20-ci-integration-tests.sh

  # Run specific project type
  ./scripts/test/20-ci-integration-tests.sh python

  # Custom results directory
  ./scripts/test/20-ci-integration-tests.sh nodejs ./reports

  # Dry run tests
  INTEGRATION_TEST_MODE=DRY_RUN ./scripts/test/20-ci-integration-tests.sh

Integration:
  This script integrates with:
  - GitHub Actions workflows
  - CI/CD pipeline orchestration
  - Test reporting systems
  - Container-based testing environments
EOF
      exit 0
      ;;
    "detect")
      # Detection mode
      echo "Detected project type: $(detect_project_type)"
      echo "Available test types: $(detect_test_types | tr '\n' ' ')"
      ;;
    "validate")
      # Validation mode
      echo "Validating integration test setup..."

      local project_type
      project_type=$(detect_project_type)
      echo "Project type: $project_type"

      # Check for integration test directories
      if [[ -d "tests/integration" ]]; then
        echo "✅ tests/integration directory found"
      elif [[ -d "integration" ]]; then
        echo "✅ integration directory found"
      else
        echo "⚠️ No integration test directory found"
      fi

      case "$project_type" in
        "nodejs")
          command -v npx >/dev/null && echo "✅ npx available" || echo "❌ npx not available"
          ;;
        "python")
          command -v python >/dev/null && echo "✅ python available" || echo "❌ python not available"
          command -v pytest >/dev/null && echo "✅ pytest available" || echo "⚠️ pytest not available"
          ;;
        "go")
          command -v go >/dev/null && echo "✅ go available" || echo "❌ go not available"
          ;;
        "rust")
          command -v cargo >/dev/null && echo "✅ cargo available" || echo "❌ cargo not available"
          ;;
        "generic")
          command -v make >/dev/null && echo "✅ make available" || echo "⚠️ make not available"
          ;;
      esac
      ;;
    *)
      main "$@"
      ;;
  esac
fi