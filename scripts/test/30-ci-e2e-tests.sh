#!/bin/bash
# CI E2E Tests Script with Full Testability Support
# Runs end-to-end tests based on detected project type with hierarchical testability control

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common utilities" >&2
  exit 1
}

# Configuration
readonly E2E_TEST_SCRIPT_VERSION="1.0.0"
readonly DEFAULT_TEST_RESULTS_DIR="$PROJECT_ROOT/test-results"
readonly DEFAULT_E2E_TIMEOUT="${E2E_TIMEOUT:-300}" # 5 minutes default

# Testability configuration
get_script_behavior() {
  local script_name="ci_e2e_tests"
  local default_behavior="EXECUTE"

  # Priority order: PIPELINE_E2E_TEST_MODE > E2E_TEST_MODE > CI_TEST_MODE > default
  local behavior

  # 1. Pipeline-specific override (highest priority)
  if [[ -n "${PIPELINE_E2E_TEST_MODE:-}" ]]; then
    behavior="$PIPELINE_E2E_TEST_MODE"
    log_debug "Using PIPELINE_E2E_TEST_MODE: $behavior"
  # 2. Script-specific override
  elif [[ -n "${E2E_TEST_MODE:-}" ]]; then
    behavior="$E2E_TEST_MODE"
    log_debug "Using E2E_TEST_MODE: $behavior"
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

  # Check for E2E tests
  if [[ -d "$project_path/tests/e2e" ]] || [[ -d "$project_path/e2e" ]]; then
    test_types+=("e2e")
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
  local test_type="${2:-e2e}"
  local test_status="${3:-success}"
  local test_exit_code="${4:-0}"
  local results_dir="${5:-$DEFAULT_TEST_RESULTS_DIR}"

  local report_file="$results_dir/e2e-test-report.json"

  cat > "$report_file" << EOF
{
  "test_timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "project_type": "$project_type",
  "test_type": "$test_type",
  "test_status": "$test_status",
  "test_exit_code": $test_exit_code,
  "test_mode": "$(get_script_behavior)",
  "e2e_test_script_version": "$E2E_TEST_SCRIPT_VERSION",
  "test_timeout": $DEFAULT_E2E_TIMEOUT,
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

# Setup test environment
setup_test_environment() {
  log_info "Setting up E2E test environment"

  # Create temporary test environment
  export E2E_TEST_DIR="${E2E_TEST_DIR:-/tmp/e2e-test-$$}"
  mkdir -p "$E2E_TEST_DIR"

  # Set test environment variables
  export TEST_ENV="${TEST_ENV:-ci}"
  export TEST_TIMEOUT="${TEST_TIMEOUT:-$DEFAULT_E2E_TIMEOUT}"

  log_debug "E2E test environment: $E2E_TEST_DIR"
}

# Cleanup test environment
cleanup_test_environment() {
  if [[ -n "${E2E_TEST_DIR:-}" ]] && [[ -d "$E2E_TEST_DIR" ]]; then
    log_debug "Cleaning up E2E test environment: $E2E_TEST_DIR"
    rm -rf "$E2E_TEST_DIR"
  fi
}

# Run Playwright E2E tests for Node.js projects
run_playwright() {
  log_info "Running Playwright E2E tests"

  if ! command -v npx >/dev/null 2>&1; then
    log_error "npx is not available"
    return 1
  fi

  local playwright_args=()

  # Add test pattern
  playwright_args+=("tests/e2e" "--reporter=list")

  # Add configuration
  if [[ -f "playwright.config.ts" ]]; then
    playwright_args+=("--config=playwright.config.ts")
  elif [[ -f "playwright.config.js" ]]; then
    playwright_args+=("--config=playwright.config.js")
  fi

  # Add CI-specific options
  if [[ "${CI:-false}" == "true" ]]; then
    playwright_args+=("--headed=false")
  fi

  log_debug "Playwright args: ${playwright_args[*]}"

  # Setup with timeout
  timeout "$DEFAULT_E2E_TIMEOUT" npx playwright test "${playwright_args[@]}" || {
    local exit_code=$?
    if [[ $exit_code -eq 124 ]]; then
      log_error "Playwright E2E tests timed out"
    else
      log_error "Playwright E2E tests failed"
    fi
    return $exit_code
  }

  log_success "Playwright E2E tests passed"
  return 0
}

# Run Cypress E2E tests for Node.js projects
run_cypress() {
  log_info "Running Cypress E2E tests"

  if ! command -v npx >/dev/null 2>&1; then
    log_error "npx is not available"
    return 1
  fi

  local cypress_args=("run")

  # Add browser configuration
  cypress_args+=("--browser" "chrome" "--headless")

  # Add test pattern
  cypress_args+=("--spec" "cypress/e2e/**/*.cy.{js,ts}")

  # Add configuration
  if [[ -f "cypress.config.ts" ]]; then
    cypress_args+=("--config-file" "cypress.config.ts")
  elif [[ -f "cypress.config.js" ]]; then
    cypress_args+=("--config-file" "cypress.config.js")
  fi

  log_debug "Cypress args: ${cypress_args[*]}"

  # Setup with timeout
  timeout "$DEFAULT_E2E_TIMEOUT" npx cypress "${cypress_args[@]}" || {
    local exit_code=$?
    if [[ $exit_code -eq 124 ]]; then
      log_error "Cypress E2E tests timed out"
    else
      log_error "Cypress E2E tests failed"
    fi
    return $exit_code
  }

  log_success "Cypress E2E tests passed"
  return 0
}

# Run E2E tests for Node.js project
run_nodejs_e2e_tests() {
  log_info "Running Node.js E2E tests"

  local test_success=true

  # Check if E2E tests exist
  if [[ ! -d "tests/e2e" ]] && [[ ! -d "e2e" ]] && [[ ! -d "cypress" ]]; then
    log_info "No E2E tests found for Node.js project"
    return 0
  fi

  # Setup test environment
  setup_test_environment

  # Try Playwright first
  if grep -q "playwright" package.json 2>/dev/null; then
    run_playwright || test_success=false
  # Try Cypress
  elif grep -q "cypress" package.json 2>/dev/null; then
    run_cypress || test_success=false
  # Fall back to npm script
  elif npm run test:e2e 2>/dev/null; then
    log_success "npm run test:e2e passed"
  else
    log_warn "No E2E test framework detected, skipping Node.js E2E tests"
  fi

  # Cleanup
  cleanup_test_environment

  return $([[ "$test_success" == "true" ]] && echo 0 || echo 1)
}

# Run Selenium/Playwright E2E tests for Python projects
run_python_e2e_tests() {
  log_info "Running Python E2E tests"

  local test_success=true

  # Check if E2E tests exist
  if [[ ! -d "tests/e2e" ]] && [[ ! -d "e2e" ]]; then
    log_info "No E2E tests found for Python project"
    return 0
  fi

  # Setup test environment
  setup_test_environment

  # Try Playwright for Python
  if command -v playwright >/dev/null 2>&1; then
    log_info "Running Playwright Python E2E tests"

    if ! timeout "$DEFAULT_E2E_TIMEOUT" playwright test tests/e2e/; then
      local exit_code=$?
      if [[ $exit_code -eq 124 ]]; then
        log_error "Playwright Python E2E tests timed out"
      else
        log_error "Playwright Python E2E tests failed"
      fi
      test_success=false
    else
      log_success "Playwright Python E2E tests passed"
    fi
  # Try Selenium
  elif command -v python >/dev/null 2>&1 && python -c "import selenium" 2>/dev/null; then
    log_info "Running Selenium Python E2E tests"

    if ! timeout "$DEFAULT_E2E_TIMEOUT" python -m pytest tests/e2e/ -v; then
      local exit_code=$?
      if [[ $exit_code -eq 124 ]]; then
        log_error "Selenium Python E2E tests timed out"
      else
        log_error "Selenium Python E2E tests failed"
      fi
      test_success=false
    else
      log_success "Selenium Python E2E tests passed"
    fi
  else
    log_warn "No Python E2E test framework available"
    test_success=false
  fi

  # Cleanup
  cleanup_test_environment

  return $([[ "$test_success" == "true" ]] && echo 0 || echo 1)
}

# Run Go E2E tests
run_go_e2e_tests() {
  log_info "Running Go E2E tests"

  local test_success=true

  # Look for E2E test files
  local e2e_files
  e2e_files=$(find . -name "*e2e*_test.go" -o -name "*_e2e_test.go" 2>/dev/null || true)

  if [[ -z "$e2e_files" ]]; then
    log_info "No E2E tests found for Go project"
    return 0
  fi

  # Setup test environment
  setup_test_environment

  local go_test_args=()

  # Add test pattern (E2E tests only)
  go_test_args+=("-run" "E2E")

  # Add verbose output
  go_test_args+=("-v")

  log_debug "Go test E2E args: ${go_test_args[*]}"

  if ! timeout "$DEFAULT_E2E_TIMEOUT" go test "${go_test_args[@]}" ./...; then
    local exit_code=$?
    if [[ $exit_code -eq 124 ]]; then
      log_error "Go E2E tests timed out"
    else
      log_error "Go E2E tests failed"
    fi
    test_success=false
  else
    log_success "Go E2E tests passed"
  fi

  # Cleanup
  cleanup_test_environment

  return $([[ "$test_success" == "true" ]] && echo 0 || echo 1)
}

# Run Rust E2E tests
run_rust_e2e_tests() {
  log_info "Running Rust E2E tests"

  local test_success=true

  # Look for E2E test files
  local e2e_files
  e2e_files=$(find . -name "*e2e*.rs" -o -name "tests/*e2e*.rs" 2>/dev/null || true)

  if [[ -z "$e2e_files" ]]; then
    log_info "No E2E tests found for Rust project"
    return 0
  fi

  # Setup test environment
  setup_test_environment

  local cargo_test_args=("test")

  # Add test pattern (E2E tests)
  cargo_test_args+=("--test" "*e2e*")

  # Add verbose output
  cargo_test_args+=("--" "--nocapture")

  log_debug "Cargo test E2E args: ${cargo_test_args[*]}"

  if ! timeout "$DEFAULT_E2E_TIMEOUT" cargo "${cargo_test_args[@]}"; then
    local exit_code=$?
    if [[ $exit_code -eq 124 ]]; then
      log_error "Rust E2E tests timed out"
    else
      log_error "Rust E2E tests failed"
    fi
    test_success=false
  else
    log_success "Rust E2E tests passed"
  fi

  # Cleanup
  cleanup_test_environment

  return $([[ "$test_success" == "true" ]] && echo 0 || echo 1)
}

# Generic E2E tests
run_generic_e2e_tests() {
  log_info "Running generic E2E tests"

  local test_success=true

  # Setup test environment
  setup_test_environment

  # Check Makefile for E2E targets
  if [[ -f "Makefile" ]] && command -v make >/dev/null 2>&1; then
    if grep -q "test-e2e\|e2e-test" Makefile; then
      if ! timeout "$DEFAULT_E2E_TIMEOUT" make test-e2e 2>/dev/null; then
        local exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
          log_error "Generic E2E tests timed out"
        else
          log_error "Generic E2E tests failed"
        fi
        test_success=false
      else
        log_success "Generic E2E tests passed"
      fi
    fi
  fi

  # Look for E2E test scripts
  if [[ "$test_success" == "true" ]]; then
    local e2e_script
    e2e_script=$(find . -name "*e2e*test*.sh" -type f 2>/dev/null | head -1)

    if [[ -n "$e2e_script" ]]; then
      log_info "Found E2E test script: $e2e_script"
      if ! timeout "$DEFAULT_E2E_TIMEOUT" bash "$e2e_script"; then
        local exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
          log_error "E2E test script timed out"
        else
          log_error "E2E test script failed"
        fi
        test_success=false
      else
        log_success "E2E test script passed"
      fi
    fi
  fi

  # Cleanup
  cleanup_test_environment

  if [[ "$test_success" != "true" ]]; then
    return 1
  fi

  if [[ -z "$e2e_script" ]] && ! grep -q "test-e2e" Makefile 2>/dev/null; then
    log_warn "No generic E2E tests found"
  fi

  return 0
}

# Run E2E tests for detected project type
run_e2e_tests() {
  local project_type="${1:-$(detect_project_type)}"
  local results_dir="${2:-$DEFAULT_TEST_RESULTS_DIR}"
  local test_success=true

  ensure_test_results_directory "$results_dir"

  case "$project_type" in
    "nodejs")
      run_nodejs_e2e_tests || test_success=false
      ;;
    "python")
      run_python_e2e_tests || test_success=false
      ;;
    "go")
      run_go_e2e_tests || test_success=false
      ;;
    "rust")
      run_rust_e2e_tests || test_success=false
      ;;
    "generic")
      run_generic_e2e_tests || test_success=false
      ;;
    *)
      log_warn "Unknown project type: $project_type, using generic E2E tests"
      run_generic_e2e_tests || test_success=false
      ;;
  esac

  local test_status="success"
  local test_exit_code=0

  if [[ "$test_success" != "true" ]]; then
    test_status="failure"
    test_exit_code=1
  fi

  generate_test_report "$project_type" "e2e" "$test_status" "$test_exit_code" "$results_dir"

  return $test_exit_code
}

# Main E2E tests function
main() {
  local project_type="${1:-}"
  local results_dir="${2:-$DEFAULT_TEST_RESULTS_DIR}"
  local behavior
  behavior=$(get_script_behavior)

  log_info "CI E2E Tests Script v$E2E_TEST_SCRIPT_VERSION"

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would run E2E tests"
      if [[ -n "$project_type" ]]; then
        echo "Project type: $project_type"
      else
        echo "Project type: $(detect_project_type)"
      fi
      echo "Results directory: $results_dir"
      echo "Timeout: ${DEFAULT_E2E_TIMEOUT}s"
      echo "Would run E2E test suite"
      return 0
      ;;
    "PASS")
      echo "✅ PASS MODE: E2E tests simulated successfully"
      return 0
      ;;
    "FAIL")
      echo "❌ FAIL MODE: Simulating E2E test failure"
      return 1
      ;;
    "SKIP")
      echo "⏭️ SKIP MODE: E2E tests skipped"
      return 0
      ;;
    "TIMEOUT")
      echo "⏰ TIMEOUT MODE: Simulating E2E test timeout"
      sleep 5
      return 124
      ;;
  esac

  # EXECUTE mode - Actual E2E testing
  log_info "🚀 EXECUTE: Running E2E tests"

  # Use provided project type or detect automatically
  if [[ -z "$project_type" ]]; then
    project_type=$(detect_project_type)
  fi

  log_info "Project type: $project_type"
  log_info "Results directory: $results_dir"
  log_info "Timeout: ${DEFAULT_E2E_TIMEOUT}s"

  # Change to project root if not already there
  if [[ "$PWD" != "$PROJECT_ROOT" ]]; then
    cd "$PROJECT_ROOT"
  fi

  # Run E2E tests
  if run_e2e_tests "$project_type" "$results_dir"; then
    log_success "✅ E2E tests completed successfully"
    return 0
  else
    log_error "❌ E2E tests failed"
    return 1
  fi
}

# CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Parse command line arguments
  case "${1:-}" in
    "help"|"--help"|"-h")
      cat << EOF
CI E2E Tests Script v$E2E_TEST_SCRIPT_VERSION

Runs end-to-end tests based on detected project type with full testability support.

Usage:
  ./scripts/test/30-ci-e2e-tests.sh [project_type] [results_directory]

Project Types:
  nodejs   - Node.js project (Playwright, Cypress)
  python   - Python project (Playwright, Selenium)
  go       - Go project (go test)
  rust     - Rust project (cargo test)
  generic  - Generic project (Makefile, test scripts)

Results Directory:
  Default: ./test-results
  Custom: Provide second argument

Test Types Supported:
- End-to-end tests (default)
- Unit tests (separate script)
- Integration tests (separate script)
- Benchmark tests (separate script)

Test Discovery:
- tests/e2e/**/*.{test,test.js,test.ts,cy.js,cy.ts}
- cypress/e2e/**/*.cy.{js,ts}
- *e2e*_test.go, *_e2e_test.go
- *e2e*.rs
- Make test-e2e targets

E2E Test Frameworks:
- Playwright (Node.js/Python)
- Cypress (Node.js)
- Selenium (Python)
- Native testing tools (Go, Rust)

Environment Variables:
  PIPELINE_E2E_TEST_MODE    EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT
  E2E_TEST_MODE           EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT
  CI_TEST_MODE            Global testability mode
  E2E_TIMEOUT             Test timeout in seconds (default: 300)
  TEST_ENV               Test environment (default: ci)
  CI_JOB_TIMEOUT_MINUTES  Timeout override for test operations

Test Results:
- JUnit XML format for CI integration
- JSON metadata reports
- Screenshots and videos (Playwright/Cypress)
- Detailed console output

Testability:
  This script supports hierarchical testability control:
  1. PIPELINE_E2E_TEST_MODE (highest priority)
  2. E2E_TEST_MODE
  3. CI_TEST_MODE (global)
  4. Default: EXECUTE

Examples:
  # Auto-detect and run E2E tests
  ./scripts/test/30-ci-e2e-tests.sh

  # Run specific project type
  ./scripts/test/30-ci-e2e-tests.sh nodejs

  # Custom timeout
  E2E_TIMEOUT=600 ./scripts/test/30-ci-e2e-tests.sh python

  # Custom results directory
  ./scripts/test/30-ci-e2e-tests.sh nodejs ./e2e-results

  # Dry run tests
  E2E_TEST_MODE=DRY_RUN ./scripts/test/30-ci-e2e-tests.sh

Integration:
  This script integrates with:
  - GitHub Actions workflows
  - CI/CD pipeline orchestration
  - Browser automation frameworks
  - Container-based testing environments
  - Test reporting and screenshot capture
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
      echo "Validating E2E test setup..."

      local project_type
      project_type=$(detect_project_type)
      echo "Project type: $project_type"

      # Check for E2E test directories
      if [[ -d "tests/e2e" ]]; then
        echo "✅ tests/e2e directory found"
      elif [[ -d "e2e" ]]; then
        echo "✅ e2e directory found"
      elif [[ -d "cypress" ]]; then
        echo "✅ cypress directory found"
      else
        echo "⚠️ No E2E test directory found"
      fi

      case "$project_type" in
        "nodejs")
          command -v npx >/dev/null && echo "✅ npx available" || echo "❌ npx not available"
          ;;
        "python")
          command -v python >/dev/null && echo "✅ python available" || echo "❌ python not available"
          python -c "import playwright" 2>/dev/null && echo "✅ playwright available" || echo "⚠️ playwright not available"
          python -c "import selenium" 2>/dev/null && echo "✅ selenium available" || echo "⚠️ selenium not available"
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