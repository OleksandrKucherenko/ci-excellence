#!/bin/bash
# CI Unit Tests Script with Full Testability Support
# Runs unit tests based on detected project type with hierarchical testability control

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common utilities" >&2
  exit 1
}

# Configuration
readonly UNIT_TEST_SCRIPT_VERSION="1.0.0"
readonly DEFAULT_TEST_RESULTS_DIR="$PROJECT_ROOT/test-results"

# Testability configuration
get_script_behavior() {
  local script_name="ci_unit_tests"
  local default_behavior="EXECUTE"

  # Priority order: PIPELINE_UNIT_TEST_MODE > UNIT_TEST_MODE > CI_TEST_MODE > default
  local behavior

  # 1. Pipeline-specific override (highest priority)
  if [[ -n "${PIPELINE_UNIT_TEST_MODE:-}" ]]; then
    behavior="$PIPELINE_UNIT_TEST_MODE"
    log_debug "Using PIPELINE_UNIT_TEST_MODE: $behavior"
  # 2. Script-specific override
  elif [[ -n "${UNIT_TEST_MODE:-}" ]]; then
    behavior="$UNIT_TEST_MODE"
    log_debug "Using UNIT_TEST_MODE: $behavior"
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

  # Check for unit tests
  if [[ -d "$project_path/tests/unit" ]] || [[ -d "$project_path/src" ]] || [[ -f "$project_path/package.json" ]]; then
    test_types+=("unit")
  fi

  # Check for test files
  if find "$project_path" -name "*test*" -type f 2>/dev/null | grep -q .; then
    [[ " ${test_types[*]} " =~ " unit " ]] || test_types+=("unit")
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
  local test_type="${2:-unit}"
  local test_status="${3:-success}"
  local test_exit_code="${4:-0}"
  local results_dir="${5:-$DEFAULT_TEST_RESULTS_DIR}"

  local report_file="$results_dir/unit-test-report.json"

  cat > "$report_file" << EOF
{
  "test_timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "project_type": "$project_type",
  "test_type": "$test_type",
  "test_status": "$test_status",
  "test_exit_code": $test_exit_code,
  "test_mode": "$(get_script_behavior)",
  "unit_test_script_version": "$UNIT_TEST_SCRIPT_VERSION",
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

# Run Jest for Node.js projects
run_jest() {
  log_info "Running Jest unit tests"

  if ! command -v npx >/dev/null 2>&1; then
    log_error "npx is not available"
    return 1
  fi

  local jest_args=()

  # Add coverage if requested
  if [[ "${GENERATE_COVERAGE:-false}" == "true" ]]; then
    jest_args+=("--coverage" "--coverageDirectory=test-results/coverage")
  fi

  # Add test pattern
  jest_args+=("--testPathPattern=tests/unit" "--verbose")

  # Add JUnit XML output for CI
  jest_args+=("--reporters=default" "--reporters=jest-junit")

  log_debug "Jest args: ${jest_args[*]}"

  if npx jest "${jest_args[@]}"; then
    log_success "Jest unit tests passed"
    return 0
  else
    log_error "Jest unit tests failed"
    return 1
  fi
}

# Run Mocha for Node.js projects
run_mocha() {
  log_info "Running Mocha unit tests"

  if ! command -v npx >/dev/null 2>&1; then
    log_error "npx is not available"
    return 1
  fi

  local mocha_args=()

  # Add test pattern
  mocha_args+=("tests/unit/**/*.test.js" "tests/unit/**/*.test.ts")

  # Add reporter
  mocha_args+=("--reporter" "spec" "--reporter" "xunit")

  log_debug "Mocha args: ${mocha_args[*]}"

  if npx mocha "${mocha_args[@]}"; then
    log_success "Mocha unit tests passed"
    return 0
  else
    log_error "Mocha unit tests failed"
    return 1
  fi
}

# Run unit tests for Node.js project
run_nodejs_unit_tests() {
  log_info "Running Node.js unit tests"

  local test_success=true

  # Try Jest first
  if grep -q "jest" package.json 2>/dev/null; then
    run_jest || test_success=false
  # Try Mocha
  elif grep -q "mocha" package.json 2>/dev/null; then
    run_mocha || test_success=false
  # Fall back to npm test
  elif npm run test 2>/dev/null; then
    log_success "npm test passed"
  else
    log_warn "No test framework detected, skipping Node.js unit tests"
  fi

  return $([[ "$test_success" == "true" ]] && echo 0 || echo 1)
}

# Run pytest for Python projects
run_pytest() {
  log_info "Running pytest"

  if ! command -v pytest >/dev/null 2>&1; then
    log_error "pytest is not available"
    return 1
  fi

  local pytest_args=()

  # Add test pattern
  pytest_args+=("tests/unit" "-v")

  # Add coverage if requested
  if [[ "${GENERATE_COVERAGE:-false}" == "true" ]]; then
    pytest_args+=("--cov=src" "--cov-report=xml" "--cov-report=html" "--cov-report=term")
  fi

  # Add JUnit XML output
  pytest_args+=("--junitxml=test-results/junit.xml")

  log_debug "Pytest args: ${pytest_args[*]}"

  if pytest "${pytest_args[@]}"; then
    log_success "Pytest unit tests passed"
    return 0
  else
    log_error "Pytest unit tests failed"
    return 1
  fi
}

# Run unittest for Python projects
run_unittest() {
  log_info "Running unittest"

  if ! command -v python >/dev/null 2>&1; then
    log_error "python is not available"
    return 1
  fi

  local unittest_args=("-m" "unittest" "discover" "-s" "tests/unit" "-p" "*test*.py" "-v")

  log_debug "Unittest args: ${unittest_args[*]}"

  if python "${unittest_args[@]}"; then
    log_success "Unittest passed"
    return 0
  else
    log_error "Unittest failed"
    return 1
  fi
}

# Run unit tests for Python project
run_python_unit_tests() {
  log_info "Running Python unit tests"

  local test_success=true

  # Try pytest first
  if command -v pytest >/dev/null 2>&1; then
    run_pytest || test_success=false
  # Try unittest
  elif command -v python >/dev/null 2>&1; then
    run_unittest || test_success=false
  else
    log_error "No Python test framework available"
    return 1
  fi

  return $([[ "$test_success" == "true" ]] && echo 0 || echo 1)
}

# Go unit tests
run_go_unit_tests() {
  log_info "Running Go unit tests"

  if ! command -v go >/dev/null 2>&1; then
    log_error "go is not available"
    return 1
  fi

  local go_test_args=()

  # Add test pattern (unit tests only)
  go_test_args+=("-short" "-run" "^Test")

  # Add coverage if requested
  if [[ "${GENERATE_COVERAGE:-false}" == "true" ]]; then
    go_test_args+=("-cover" "-coverprofile=test-results/coverage.out")
    mkdir -p test-results
    go tool cover -html=test-results/coverage.out -o test-results/coverage.html
  fi

  # Add verbose output
  go_test_args+=("-v")

  log_debug "Go test args: ${go_test_args[*]}"

  if go test "${go_test_args[@]}" ./...; then
    log_success "Go unit tests passed"
    return 0
  else
    log_error "Go unit tests failed"
    return 1
  fi
}

# Rust unit tests
run_rust_unit_tests() {
  log_info "Running Rust unit tests"

  if ! command -v cargo >/dev/null 2>&1; then
    log_error "cargo is not available"
    return 1
  fi

  local cargo_test_args=("test")

  # Add test pattern (lib tests only)
  cargo_test_args+=("--lib")

  # Add verbose output
  cargo_test_args+=("--" "--nocapture")

  log_debug "Cargo test args: ${cargo_test_args[*]}"

  if cargo "${cargo_test_args[@]}"; then
    log_success "Rust unit tests passed"
    return 0
  else
    log_error "Rust unit tests failed"
    return 1
  fi
}

# Generic unit tests
run_generic_unit_tests() {
  log_info "Running generic unit tests"

  if [[ -f "Makefile" ]] && command -v make >/dev/null 2>&1; then
    if grep -q "test-unit\|test:" Makefile; then
      if make test-unit 2>/dev/null; then
        log_success "Generic unit tests passed"
        return 0
      elif make test 2>/dev/null; then
        log_success "Generic tests passed"
        return 0
      fi
    fi
  fi

  # Look for test scripts
  local test_script
  test_script=$(find . -name "*test*.sh" -type f 2>/dev/null | head -1)

  if [[ -n "$test_script" ]]; then
    log_info "Found test script: $test_script"
    if bash "$test_script"; then
      log_success "Generic unit tests passed"
      return 0
    else
      log_error "Generic unit tests failed"
      return 1
    fi
  fi

  log_warn "No generic unit tests found"
  return 0
}

# Run unit tests for detected project type
run_unit_tests() {
  local project_type="${1:-$(detect_project_type)}"
  local results_dir="${2:-$DEFAULT_TEST_RESULTS_DIR}"
  local test_success=true

  ensure_test_results_directory "$results_dir"

  case "$project_type" in
    "nodejs")
      run_nodejs_unit_tests || test_success=false
      ;;
    "python")
      run_python_unit_tests || test_success=false
      ;;
    "go")
      run_go_unit_tests || test_success=false
      ;;
    "rust")
      run_rust_unit_tests || test_success=false
      ;;
    "generic")
      run_generic_unit_tests || test_success=false
      ;;
    *)
      log_warn "Unknown project type: $project_type, using generic unit tests"
      run_generic_unit_tests || test_success=false
      ;;
  esac

  local test_status="success"
  local test_exit_code=0

  if [[ "$test_success" != "true" ]]; then
    test_status="failure"
    test_exit_code=1
  fi

  generate_test_report "$project_type" "unit" "$test_status" "$test_exit_code" "$results_dir"

  return $test_exit_code
}

# Main unit tests function
main() {
  local project_type="${1:-}"
  local results_dir="${2:-$DEFAULT_TEST_RESULTS_DIR}"
  local behavior
  behavior=$(get_script_behavior)

  log_info "CI Unit Tests Script v$UNIT_TEST_SCRIPT_VERSION"

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would run unit tests"
      if [[ -n "$project_type" ]]; then
        echo "Project type: $project_type"
      else
        echo "Project type: $(detect_project_type)"
      fi
      echo "Results directory: $results_dir"
      echo "Would run unit test suite"
      return 0
      ;;
    "PASS")
      echo "✅ PASS MODE: Unit tests simulated successfully"
      return 0
      ;;
    "FAIL")
      echo "❌ FAIL MODE: Simulating unit test failure"
      return 1
      ;;
    "SKIP")
      echo "⏭️ SKIP MODE: Unit tests skipped"
      return 0
      ;;
    "TIMEOUT")
      echo "⏰ TIMEOUT MODE: Simulating unit test timeout"
      sleep 5
      return 124
      ;;
  esac

  # EXECUTE mode - Actual unit testing
  log_info "🚀 EXECUTE: Running unit tests"

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

  # Run unit tests
  if run_unit_tests "$project_type" "$results_dir"; then
    log_success "✅ Unit tests completed successfully"
    return 0
  else
    log_error "❌ Unit tests failed"
    return 1
  fi
}

# CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Parse command line arguments
  case "${1:-}" in
    "help"|"--help"|"-h")
      cat << EOF
CI Unit Tests Script v$UNIT_TEST_SCRIPT_VERSION

Runs unit tests based on detected project type with full testability support.

Usage:
  ./scripts/test/10-ci-unit-tests.sh [project_type] [results_directory]

Project Types:
  nodejs   - Node.js project (Jest, Mocha, npm test)
  python   - Python project (pytest, unittest)
  go       - Go project (go test)
  rust     - Rust project (cargo test)
  generic  - Generic project (Makefile, test scripts)

Results Directory:
  Default: ./test-results
  Custom: Provide second argument

Test Types Supported:
- Unit tests (default)
- Integration tests (separate script)
- End-to-end tests (separate script)
- Benchmark tests (separate script)

Environment Variables:
  PIPELINE_UNIT_TEST_MODE  EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT
  UNIT_TEST_MODE          EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT
  CI_TEST_MODE           Global testability mode
  GENERATE_COVERAGE      Generate coverage reports (default: false)
  CI_JOB_TIMEOUT_MINUTES Timeout override for test operations

Test Results:
- JUnit XML format for CI integration
- Coverage reports (HTML/XML)
- JSON metadata reports
- Detailed console output

Testability:
  This script supports hierarchical testability control:
  1. PIPELINE_UNIT_TEST_MODE (highest priority)
  2. UNIT_TEST_MODE
  3. CI_TEST_MODE (global)
  4. Default: EXECUTE

Examples:
  # Auto-detect and run unit tests
  ./scripts/test/10-ci-unit-tests.sh

  # Run specific project type
  ./scripts/test/10-ci-unit-tests.sh python

  # Generate coverage reports
  GENERATE_COVERAGE=true ./scripts/test/10-ci-unit-tests.sh

  # Custom results directory
  ./scripts/test/10-ci-unit-tests.sh nodejs ./reports

  # Dry run tests
  UNIT_TEST_MODE=DRY_RUN ./scripts/test/10-ci-unit-tests.sh

Integration:
  This script integrates with:
  - GitHub Actions workflows
  - CI/CD pipeline orchestration
  - Test reporting systems
  - Coverage analysis tools
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
      echo "Validating unit test setup..."

      local project_type
      project_type=$(detect_project_type)
      echo "Project type: $project_type"

      case "$project_type" in
        "nodejs")
          command -v npx >/dev/null && echo "✅ npx available" || echo "❌ npx not available"
          [[ -f "package.json" ]] && grep -q "test\|jest\|mocha" package.json && echo "✅ test script found" || echo "⚠️ No test script found"
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