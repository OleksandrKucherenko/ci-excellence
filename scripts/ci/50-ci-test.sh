#!/usr/bin/env bash
# CI Test Script
# Runs comprehensive tests including unit, integration, and security tests

set -euo pipefail

# Source shared utilities
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Script configuration
readonly SCRIPT_NAME="$(basename "$0" .sh)"
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_DESCRIPTION="Run comprehensive test suite"

# Default test configuration
DEFAULT_TEST_TYPE="all"
DEFAULT_COVERAGE_ENABLED=true
DEFAULT_PARALLEL_JOBS=4
DEFAULT_FAIL_FAST=false

# Usage information
usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS] [TEST_PATTERN]

Run comprehensive tests including unit, integration, and security tests.

OPTIONS:
  -t, --type TYPE           Test type to run (unit|integration|e2e|security|all) [default: $DEFAULT_TEST_TYPE]
  -c, --coverage            Enable code coverage collection
  --no-coverage             Disable code coverage collection
  -j, --jobs NUM            Number of parallel test jobs [default: $DEFAULT_PARALLEL_JOBS]
  -f, --fail-fast           Stop on first test failure
  --no-fail-fast            Continue running tests after failures
  -p, --pattern PATTERN     Test pattern to match (can also be passed as argument)
  -r, --retry NUM           Retry failed tests NUM times [default: 0]
  -t, --test-mode MODE      Test mode (DRY_RUN|SIMULATE|EXECUTE)
  -h, --help                Show this help message
  -V, --version             Show version information

ARGUMENTS:
  TEST_PATTERN              Test pattern to match (same as --pattern)

EXAMPLES:
  $SCRIPT_NAME                           # Run all tests
  $SCRIPT_NAME --type unit               # Run only unit tests
  $SCRIPT_NAME --coverage --fail-fast    # Run with coverage and fail-fast
  $SCRIPT_NAME --pattern "auth.*"         # Run tests matching pattern
  $SCRIPT_NAME --retry 2                 # Retry failed tests twice

TEST TYPES:
  unit          Run unit tests (fast, isolated)
  integration   Run integration tests (between components)
  e2e           Run end-to-end tests (full application flow)
  security      Run security-focused tests
  all           Run all test types (default)

ENVIRONMENT VARIABLES:
  CI_TEST_MODE               Test mode override (DRY_RUN|SIMULATE|EXECUTE)
  CI_TEST_TYPE               Test type override
  CI_COVERAGE_ENABLED        Enable/disable coverage collection
  CI_PARALLEL_JOBS           Number of parallel jobs
  CI_FAIL_FAST               Stop on first failure (true|false)
  TEST_PATTERN               Default test pattern
  TEST_RETRY_COUNT           Number of retries for failed tests
  COVERAGE_THRESHOLD         Minimum coverage percentage required

EXIT CODES:
  0     Success (all tests passed)
  1     General error
  2     Tests failed
  3     Coverage threshold not met
  4     Invalid arguments
  5     Prerequisites not met

EOF
}

# Show version information
version() {
  echo "$SCRIPT_NAME version $SCRIPT_VERSION"
  echo "$SCRIPT_DESCRIPTION"
}

# Parse command line arguments
parse_args() {
  # Default options
  local opt_test_type="$DEFAULT_TEST_TYPE"
  local opt_coverage_enabled="$DEFAULT_COVERAGE_ENABLED"
  local opt_parallel_jobs="$DEFAULT_PARALLEL_JOBS"
  local opt_fail_fast="$DEFAULT_FAIL_FAST"
  local opt_test_pattern=""
  local opt_retry_count="0"
  local opt_test_mode=""

  # Parse options
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -t|--type)
        shift
        if [[ -z "$1" ]]; then
          log_error "Test type cannot be empty"
          return 4
        fi
        case "$1" in
          unit|integration|e2e|security|all) ;;
          *)
            log_error "Invalid test type: $1. Use unit, integration, e2e, security, or all"
            return 4
            ;;
        esac
        opt_test_type="$1"
        shift
        ;;
      -c|--coverage)
        opt_coverage_enabled=true
        shift
        ;;
      --no-coverage)
        opt_coverage_enabled=false
        shift
        ;;
      -j|--jobs)
        shift
        if [[ -z "$1" ]]; then
          log_error "Jobs count cannot be empty"
          return 4
        fi
        if ! [[ "$1" =~ ^[1-9][0-9]*$ ]]; then
          log_error "Jobs count must be a positive integer"
          return 4
        fi
        opt_parallel_jobs="$1"
        shift
        ;;
      -f|--fail-fast)
        opt_fail_fast=true
        shift
        ;;
      --no-fail-fast)
        opt_fail_fast=false
        shift
        ;;
      -p|--pattern)
        shift
        if [[ -z "$1" ]]; then
          log_error "Test pattern cannot be empty"
          return 4
        fi
        opt_test_pattern="$1"
        shift
        ;;
      -r|--retry)
        shift
        if [[ -z "$1" ]]; then
          log_error "Retry count cannot be empty"
          return 4
        fi
        if ! [[ "$1" =~ ^[0-9]+$ ]]; then
          log_error "Retry count must be a non-negative integer"
          return 4
        fi
        opt_retry_count="$1"
        shift
        ;;
      -t|--test-mode)
        shift
        if [[ -z "$1" ]]; then
          log_error "Test mode cannot be empty"
          return 4
        fi
        case "$1" in
          DRY_RUN|SIMULATE|EXECUTE) ;;
          *)
            log_error "Invalid test mode: $1. Use DRY_RUN, SIMULATE, or EXECUTE"
            return 4
            ;;
        esac
        opt_test_mode="$1"
        shift
        ;;
      -h|--help)
        usage
        return 0
        ;;
      -V|--version)
        version
        return 0
        ;;
      -*)
        log_error "Unknown option: $1"
        usage
        return 4
        ;;
      *)
        # Accept pattern as argument
        if [[ -z "$opt_test_pattern" ]]; then
          opt_test_pattern="$1"
        else
          log_error "Unexpected argument: $1"
          usage
          return 4
        fi
        shift
        ;;
    esac
  done

  # Set global variables
  export TEST_TYPE="$opt_test_type"
  export COVERAGE_ENABLED="$opt_coverage_enabled"
  export PARALLEL_JOBS="$opt_parallel_jobs"
  export FAIL_FAST="$opt_fail_fast"
  export TEST_PATTERN="$opt_test_pattern"
  export RETRY_COUNT="$opt_retry_count"

  # Resolve test mode
  local resolved_mode
  if ! resolved_mode=$(resolve_test_mode "$SCRIPT_NAME" "test" "$opt_test_mode"); then
    return 1
  fi
  export TEST_MODE="$resolved_mode"

  return 0
}

# Check test prerequisites
check_prerequisites() {
  log_info "Checking test prerequisites"

  local missing_tools=()

  # Check for Node.js
  if ! command -v node >/dev/null 2>&1; then
    missing_tools+=("node")
  fi

  # Check for package managers
  if command -v npm >/dev/null 2>&1; then
    export PKG_MANAGER="npm"
  elif command -v bun >/dev/null 2>&1; then
    export PKG_MANAGER="bun"
  else
    missing_tools+=("npm or bun")
  fi

  # Check for test frameworks
  local test_frameworks_found=false
  if command -v jest >/dev/null 2>&1; then
    test_frameworks_found=true
    export TEST_FRAMEWORK="jest"
  fi
  if command -v vitest >/dev/null 2>&1; then
    test_frameworks_found=true
    export TEST_FRAMEWORK="vitest"
  fi

  if [[ "$test_frameworks_found" != "true" ]]; then
    # Check for local test frameworks in node_modules
    if [[ -d "node_modules/.bin" ]]; then
      if [[ -x "node_modules/.bin/jest" ]]; then
        test_frameworks_found=true
        export TEST_FRAMEWORK="jest"
      elif [[ -x "node_modules/.bin/vitest" ]]; then
        test_frameworks_found=true
        export TEST_FRAMEWORK="vitest"
      fi
    fi
  fi

  if [[ "$test_frameworks_found" != "true" ]]; then
    log_warning "No test framework found (jest or vitest)"
  fi

  # Check for shellspec for shell script testing
  if [[ -d "spec" ]] && ! command -v shellspec >/dev/null 2>&1; then
    missing_tools+=("shellspec (for shell script tests)")
  fi

  if [[ ${#missing_tools[@]} -gt 0 ]]; then
    log_error "Missing test tools: ${missing_tools[*]}"
    return 5
  fi

  log_success "✅ Test prerequisites met"
  return 0
}

# Configure test environment
configure_test_environment() {
  log_info "Configuring test environment"

  # Export test environment variables
  export NODE_ENV="test"
  export CI="true"
  export TEST_MODE="$TEST_MODE"
  export TEST_TYPE="$TEST_TYPE"
  export COVERAGE_ENABLED="$COVERAGE_ENABLED"

  # Configure test runner settings
  export TEST_TIMEOUT="${TEST_TIMEOUT:-30000}"  # 30 seconds default
  export TEST_REPORTER="${TEST_REPORTER:-default}"
  export TEST_OUTPUT_DIR="${TEST_OUTPUT_DIR:-test-results}"
  export COVERAGE_DIR="${COVERAGE_DIR:-coverage}"
  export COVERAGE_THRESHOLD="${COVERAGE_THRESHOLD:-80}"

  # Create test output directories
  mkdir -p "$TEST_OUTPUT_DIR"
  mkdir -p "$COVERAGE_DIR"

  # Configure test framework specific settings
  case "${TEST_FRAMEWORK:-}" in
    "jest")
      export JEST_CONFIG="${JEST_CONFIG:-jest.config.js}"
      export JEST_JUNIT_OUTPUT="${TEST_OUTPUT_DIR}/junit.xml"
      export JEST_COVERAGE_OUTPUT="${COVERAGE_DIR}/lcov.info"
      ;;
    "vitest")
      export VITEST_CONFIG="${VITEST_CONFIG:-vitest.config.ts}"
      export VITEST_JUNIT_OUTPUT="${TEST_OUTPUT_DIR}/junit.xml"
      export VITEST_COVERAGE_OUTPUT="${COVERAGE_DIR}/lcov.info"
      ;;
  esac

  log_info "Test environment configured:"
  log_info "  Node environment: $NODE_ENV"
  log_info "  Test type: $TEST_TYPE"
  log_info "  Coverage enabled: $COVERAGE_ENABLED"
  log_info "  Parallel jobs: $PARALLEL_JOBS"
  log_info "  Fail fast: $FAIL_FAST"
  log_info "  Test framework: ${TEST_FRAMEWORK:-none}"
  log_info "  Output directory: $TEST_OUTPUT_DIR"

  return 0
}

# Run unit tests
run_unit_tests() {
  log_info "Running unit tests"

  case "$TEST_MODE" in
    "DRY_RUN")
      log_info "Would run unit tests"
      return 0
      ;;
    "SIMULATE")
      log_info "Simulating unit tests"
      sleep 2
      return 0
      ;;
  esac

  local test_cmd=""
  local test_args=""

  # Configure test command based on framework
  case "${TEST_FRAMEWORK:-}" in
    "jest")
      test_cmd="npx jest"
      test_args="--testPathPattern=unit"
      [[ -n "$TEST_PATTERN" ]] && test_args="$test_args --testNamePattern='$TEST_PATTERN'"
      [[ "$FAIL_FAST" == "true" ]] && test_args="$test_args --bail"
      [[ "$COVERAGE_ENABLED" == "true" ]] && test_args="$test_args --coverage"
      [[ $PARALLEL_JOBS -gt 1 ]] && test_args="$test_args --maxWorkers=$PARALLEL_JOBS"
      ;;
    "vitest")
      test_cmd="npx vitest run"
      test_args="--config=vitest.config.unit.ts"
      [[ -n "$TEST_PATTERN" ]] && test_args="$test_args -t '$TEST_PATTERN'"
      [[ "$FAIL_FAST" == "true" ]] && test_args="$test_args --fail-fast"
      [[ "$COVERAGE_ENABLED" == "true" ]] && test_args="$test_args --coverage"
      [[ $PARALLEL_JOBS -gt 1 ]] && test_args="$test_args --threads"
      ;;
    *)
      log_warning "No test framework configured, running generic tests"
      # Use npm test if available
      if [[ -f "package.json" ]] && npm run test --silent 2>/dev/null; then
        test_cmd="npm test"
      else
        log_info "No tests found to run"
        return 0
      fi
      ;;
  esac

  log_info "Running: $test_cmd $test_args"

  # Retry logic for failed tests
  local attempt=0
  local max_attempts=$((RETRY_COUNT + 1))

  while [[ $attempt -lt $max_attempts ]]; do
    ((attempt++))

    if [[ $attempt -gt 1 ]]; then
      log_info "Retry attempt $attempt/$max_attempts"
    fi

    if eval "$test_cmd $test_args"; then
      log_success "✅ Unit tests passed (attempt $attempt)"
      return 0
    else
      local exit_code=$?
      if [[ $attempt -lt $max_attempts ]]; then
        log_warning "Unit tests failed, retrying..."
        sleep 1
      else
        log_error "❌ Unit tests failed after $max_attempts attempts"
        return 2
      fi
    fi
  done
}

# Run integration tests
run_integration_tests() {
  log_info "Running integration tests"

  case "$TEST_MODE" in
    "DRY_RUN")
      log_info "Would run integration tests"
      return 0
      ;;
    "SIMULATE")
      log_info "Simulating integration tests"
      sleep 3
      return 0
      ;;
  esac

  local test_cmd=""
  local test_args=""

  # Configure test command based on framework
  case "${TEST_FRAMEWORK:-}" in
    "jest")
      test_cmd="npx jest"
      test_args="--testPathPattern=integration"
      [[ -n "$TEST_PATTERN" ]] && test_args="$test_args --testNamePattern='$TEST_PATTERN'"
      [[ "$FAIL_FAST" == "true" ]] && test_args="$test_args --bail"
      [[ $PARALLEL_JOBS -gt 1 ]] && test_args="$test_args --maxWorkers=$PARALLEL_JOBS"
      ;;
    "vitest")
      test_cmd="npx vitest run"
      test_args="--config=vitest.config.integration.ts"
      [[ -n "$TEST_PATTERN" ]] && test_args="$test_args -t '$TEST_PATTERN'"
      [[ "$FAIL_FAST" == "true" ]] && test_args="$test_args --fail-fast"
      [[ $PARALLEL_JOBS -gt 1 ]] && test_args="$test_args --threads"
      ;;
    *)
      log_info "No integration tests configured"
      return 0
      ;;
  esac

  log_info "Running: $test_cmd $test_args"

  if eval "$test_cmd $test_args"; then
    log_success "✅ Integration tests passed"
    return 0
  else
    log_error "❌ Integration tests failed"
    return 2
  fi
}

# Run end-to-end tests
run_e2e_tests() {
  log_info "Running end-to-end tests"

  case "$TEST_MODE" in
    "DRY_RUN")
      log_info "Would run end-to-end tests"
      return 0
      ;;
    "SIMULATE")
      log_info "Simulating end-to-end tests"
      sleep 5
      return 0
      ;;
  esac

  local test_cmd=""
  local test_args=""

  # Check for Playwright
  if command -v npx playwright >/dev/null 2>&1; then
    test_cmd="npx playwright test"
    [[ -n "$TEST_PATTERN" ]] && test_args="$test_args --grep '$TEST_PATTERN'"
    [[ "$FAIL_FAST" == "true" ]] && test_args="$test_args --max-failures=1"
  elif command -v cypress >/dev/null 2>&1; then
    test_cmd="npx cypress run"
    [[ -n "$TEST_PATTERN" ]] && test_args="$test_args --spec '**/*$TEST_PATTERN*'"
  elif [[ -d "e2e" ]]; then
    # Try using generic test framework
    case "${TEST_FRAMEWORK:-}" in
      "jest")
        test_cmd="npx jest"
        test_args="--testPathPattern=e2e"
        ;;
      "vitest")
        test_cmd="npx vitest run"
        test_args="--config=vitest.config.e2e.ts"
        ;;
    esac
  else
    log_info "No end-to-end tests configured"
    return 0
  fi

  if [[ -n "$test_cmd" ]]; then
    log_info "Running: $test_cmd $test_args"

    if eval "$test_cmd $test_args"; then
      log_success "✅ End-to-end tests passed"
      return 0
    else
      log_error "❌ End-to-end tests failed"
      return 2
    fi
  fi

  return 0
}

# Run security tests
run_security_tests() {
  log_info "Running security tests"

  case "$TEST_MODE" in
    "DRY_RUN")
      log_info "Would run security tests"
      return 0
      ;;
    "SIMULATE")
      log_info "Simulating security tests"
      sleep 2
      return 0
      ;;
  esac

  local security_passed=true

  # Run npm audit if package.json exists
  if [[ -f "package.json" ]]; then
    log_info "Running npm audit"
    if npm audit --audit-level=moderate; then
      log_success "✅ npm audit passed"
    else
      log_warning "⚠️ npm audit found vulnerabilities"
      security_passed=false
    fi
  fi

  # Run shellspec tests if spec directory exists
  if [[ -d "spec" ]] && command -v shellspec >/dev/null 2>&1; then
    log_info "Running shellspec tests"
    if shellspec; then
      log_success "✅ shellspec tests passed"
    else
      log_error "❌ shellspec tests failed"
      security_passed=false
    fi
  fi

  if [[ "$security_passed" == "true" ]]; then
    log_success "✅ Security tests passed"
    return 0
  else
    log_error "❌ Security tests failed"
    return 2
  fi
}

# Run shell script tests
run_shell_tests() {
  log_info "Running shell script tests"

  if [[ ! -d "spec" ]]; then
    log_info "No shell test specs found"
    return 0
  fi

  case "$TEST_MODE" in
    "DRY_RUN")
      log_info "Would run shell tests"
      return 0
      ;;
    "SIMULATE")
      log_info "Simulating shell tests"
      sleep 1
      return 0
      ;;
  esac

  if command -v shellspec >/dev/null 2>&1; then
    log_info "Running shellspec"
    if shellspec; then
      log_success "✅ Shell tests passed"
      return 0
    else
      log_error "❌ Shell tests failed"
      return 2
    fi
  else
    log_warning "shellspec not available, skipping shell tests"
    return 0
  fi
}

# Check coverage thresholds
check_coverage_thresholds() {
  if [[ "$COVERAGE_ENABLED" != "true" ]]; then
    log_info "Coverage collection disabled"
    return 0
  fi

  log_info "Checking coverage thresholds"

  case "$TEST_MODE" in
    "DRY_RUN"|"SIMULATE")
      log_info "Would check coverage thresholds"
      return 0
      ;;
  esac

  local coverage_file="$COVERAGE_DIR/coverage-summary.json"
  local threshold="${COVERAGE_THRESHOLD}"

  if [[ ! -f "$coverage_file" ]]; then
    log_warning "Coverage summary file not found: $coverage_file"
    return 0
  fi

  # Parse coverage from JSON
  local total_lines
  local covered_lines
  local coverage_percentage

  if command -v jq >/dev/null 2>&1; then
    total_lines=$(jq -r '.total.lines.total' "$coverage_file" 2>/dev/null || echo "0")
    covered_lines=$(jq -r '.total.lines.covered' "$coverage_file" 2>/dev/null || echo "0")
  else
    log_warning "jq not available for coverage parsing"
    return 0
  fi

  if [[ "$total_lines" -gt 0 ]]; then
    coverage_percentage=$((covered_lines * 100 / total_lines))
    log_info "Coverage: $coverage_percentage% (threshold: $threshold%)"

    if [[ $coverage_percentage -lt $threshold ]]; then
      log_error "❌ Coverage threshold not met: $coverage_percentage% < $threshold%"
      return 3
    fi

    log_success "✅ Coverage threshold met: $coverage_percentage% >= $threshold%"
  else
    log_warning "No lines found in coverage report"
  fi

  return 0
}

# Generate test report
generate_test_report() {
  local test_status="$1"
  local start_time="$2"
  local end_time=$(date +%s)

  log_info "Generating test report"

  local test_duration=$((end_time - start_time))
  local output_dir="${TEST_REPORT_OUTPUT:-reports/test}"
  mkdir -p "$output_dir"

  local report_file="$output_dir/test-report-$(date +%Y%m%d-%H%M%S).json"

  # Count test files
  local unit_files=0
  local integration_files=0
  local e2e_files=0
  local shell_files=0

  [[ -d "test/unit" ]] && unit_files=$(find test/unit -name "*.test.*" -o -name "*.spec.*" 2>/dev/null | wc -l)
  [[ -d "test/integration" ]] && integration_files=$(find test/integration -name "*.test.*" -o -name "*.spec.*" 2>/dev/null | wc -l)
  [[ -d "test/e2e" ]] && e2e_files=$(find test/e2e -name "*.test.*" -o -name "*.spec.*" 2>/dev/null | wc -l)
  [[ -d "spec" ]] && shell_files=$(find spec -name "*.sh" 2>/dev/null | wc -l)

  # Build report content
  cat > "$report_file" << EOF
{
  "test": {
    "script": "$SCRIPT_NAME",
    "version": "$SCRIPT_VERSION",
    "status": "$test_status",
    "type": "$TEST_TYPE",
    "test_mode": "$TEST_MODE",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "duration_seconds": $test_duration,
    "configuration": {
      "coverage_enabled": "$COVERAGE_ENABLED",
      "parallel_jobs": "$PARALLEL_JOBS",
      "fail_fast": "$FAIL_FAST",
      "test_pattern": "$TEST_PATTERN",
      "retry_count": "$RETRY_COUNT",
      "coverage_threshold": "${COVERAGE_THRESHOLD}"
    }
  },
  "files": {
    "unit_tests": $unit_files,
    "integration_tests": $integration_files,
    "e2e_tests": $e2e_files,
    "shell_tests": $shell_files,
    "total_test_files": $((unit_files + integration_files + e2e_files + shell_files))
  },
  "output": {
    "directory": "$TEST_OUTPUT_DIR",
    "coverage_directory": "$COVERAGE_DIR"
  }
}
EOF

  log_success "✅ Test report generated: $report_file"

  # Export for CI systems
  export TEST_REPORT_FILE="$report_file"

  return 0
}

# Main test function
main() {
  local start_time
  start_time=$(date +%s)

  log_info "🧪 Starting CI test suite"
  log_info "Script version: $SCRIPT_VERSION"

  # Parse command line arguments
  if ! parse_args "$@"; then
    return 1
  fi

  log_info "Test configuration:"
  log_info "  Test type: $TEST_TYPE"
  log_info "  Coverage enabled: $COVERAGE_ENABLED"
  log_info "  Parallel jobs: $PARALLEL_JOBS"
  log_info "  Fail fast: $FAIL_FAST"
  log_info "  Test pattern: ${TEST_PATTERN:-none}"
  log_info "  Retry count: $RETRY_COUNT"
  log_info "  Test mode: $TEST_MODE"

  # Run test pipeline
  if ! check_prerequisites; then
    return 5
  fi

  if ! configure_test_environment; then
    return 1
  fi

  local test_results=()

  # Run tests based on type
  case "$TEST_TYPE" in
    "unit")
      run_unit_tests || test_results+=("unit")
      ;;
    "integration")
      run_integration_tests || test_results+=("integration")
      ;;
    "e2e")
      run_e2e_tests || test_results+=("e2e")
      ;;
    "security")
      run_security_tests || test_results+=("security")
      ;;
    "all")
      run_unit_tests || test_results+=("unit")
      run_integration_tests || test_results+=("integration")
      run_e2e_tests || test_results+=("e2e")
      run_security_tests || test_results+=("security")
      run_shell_tests || test_results+=("shell")
      ;;
  esac

  # Check coverage thresholds
  if [[ "$COVERAGE_ENABLED" == "true" ]]; then
    check_coverage_thresholds || test_results+=("coverage")
  fi

  # Determine overall result
  if [[ ${#test_results[@]} -eq 0 ]]; then
    log_success "✅ All tests passed"
    generate_test_report "success" "$start_time"

    # Show actionable items for CI
    if [[ -n "${CI:-}" ]]; then
      echo
      log_info "🔗 Next steps for CI pipeline:"
      log_info "   • Publish artifacts: scripts/ci/60-ci-publish.sh"
      log_info "   • Deploy to staging: scripts/release/60-ci-deploy.sh --environment staging"
    fi

    return 0
  else
    log_error "❌ Tests failed in: ${test_results[*]}"
    generate_test_report "failed" "$start_time"
    return 2
  fi
}

# Error handling
trap 'log_error "Script failed with exit code $?"' ERR

# Execute main function with all arguments
main "$@"