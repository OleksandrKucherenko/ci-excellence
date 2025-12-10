#!/bin/bash
# CI Lint Script with Full Testability Support
# Runs linting based on detected project type with hierarchical testability control

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common utilities" >&2
  exit 1
}

# Configuration
readonly LINT_SCRIPT_VERSION="1.0.0"

# Default linter configurations
DEFAULT_ESLINT_CONFIG=".eslintrc.js"
DEFAULT_PRETTIER_CONFIG=".prettierrc"
DEFAULT_PYLINT_CONFIG=".pylintrc"
DEFAULT_GOLINT_CONFIG="golangci-lint.yml"
DEFAULT_CLIPPY_CONFIG="clippy.toml"

# Testability configuration
get_script_behavior() {
  local script_name="ci_lint"
  local default_behavior="EXECUTE"

  # Priority order: PIPELINE_LINT_MODE > LINT_MODE > CI_TEST_MODE > default
  local behavior

  # 1. Pipeline-specific override (highest priority)
  if [[ -n "${PIPELINE_LINT_MODE:-}" ]]; then
    behavior="$PIPELINE_LINT_MODE"
    log_debug "Using PIPELINE_LINT_MODE: $behavior"
  # 2. Script-specific override
  elif [[ -n "${LINT_MODE:-}" ]]; then
    behavior="$LINT_MODE"
    log_debug "Using LINT_MODE: $behavior"
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

# Ensure lint results directory exists
ensure_lint_results_directory() {
  local results_dir="${1:-$PROJECT_ROOT/lint-results}"

  mkdir -p "$results_dir"
  log_debug "Created lint results directory: $results_dir"
}

# Generate lint report
generate_lint_report() {
  local project_type="${1:-$(detect_project_type)}"
  local lint_status="${2:-success}"
  local results_dir="${3:-$PROJECT_ROOT/lint-results}"

  local report_file="$results_dir/lint-report.json"

  cat > "$report_file" << EOF
{
  "lint_timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "project_type": "$project_type",
  "lint_status": "$lint_status",
  "lint_mode": "$(get_script_behavior)",
  "lint_script_version": "$LINT_SCRIPT_VERSION",
  "lint_environment": {
    "ci": "${CI:-false}",
    "github_actions": "${GITHUB_ACTIONS:-false}",
    "runner_os": "${RUNNER_OS:-unknown}"
  }
}
EOF

  log_debug "Generated lint report: $report_file"
}

# Run ESLint for Node.js projects
run_eslint() {
  log_info "Running ESLint"

  if ! command -v npx >/dev/null 2>&1; then
    log_error "npx is not available"
    return 1
  fi

  local eslint_config="${ESLINT_CONFIG:-$DEFAULT_ESLINT_CONFIG}"
  local eslint_args=()

  # Use custom config if exists
  if [[ -f "$eslint_config" ]]; then
    eslint_args+=("--config" "$eslint_config")
  fi

  # Add file patterns
  eslint_args+=("src/**/*.{js,ts,jsx,tsx}" "*.js" "*.ts")

  log_debug "ESLint args: ${eslint_args[*]}"

  if npx eslint "${eslint_args[@]}"; then
    log_success "ESLint passed"
    return 0
  else
    log_error "ESLint failed"
    return 1
  fi
}

# Run Prettier for Node.js projects
run_prettier() {
  log_info "Running Prettier format check"

  if ! command -v npx >/dev/null 2>&1; then
    log_error "npx is not available"
    return 1
  fi

  local prettier_config="${PRETTIER_CONFIG:-$DEFAULT_PRETTIER_CONFIG}"
  local prettier_args=("--check")

  # Use custom config if exists
  if [[ -f "$prettier_config" ]]; then
    prettier_args+=("--config" "$prettier_config")
  fi

  # Add file patterns
  prettier_args+=("src/**/*.{js,ts,jsx,tsx,json,md}" "*.js" "*.ts" "*.json" "*.md")

  log_debug "Prettier args: ${prettier_args[*]}"

  if npx prettier "${prettier_args[@]}"; then
    log_success "Prettier check passed"
    return 0
  else
    log_error "Prettier check failed"
    return 1
  fi
}

# Lint Node.js project
lint_nodejs_project() {
  log_info "Linting Node.js project"

  local lint_success=true

  # Run ESLint
  if ! run_eslint; then
    lint_success=false
  fi

  # Run Prettier
  if ! run_prettier; then
    lint_success=false
  fi

  return $([[ "$lint_success" == "true" ]] && echo 0 || echo 1)
}

# Run Pylint for Python projects
run_pylint() {
  log_info "Running Pylint"

  if ! command -v pylint >/dev/null 2>&1; then
    log_error "pylint is not available"
    return 1
  fi

  local pylint_config="${PYLINT_CONFIG:-$DEFAULT_PYLINT_CONFIG}"
  local pylint_args=()

  # Use custom config if exists
  if [[ -f "$pylint_config" ]]; then
    pylint_args+=("--rcfile" "$pylint_config")
  fi

  # Add source directory
  pylint_args+=("src/")

  log_debug "Pylint args: ${pylint_args[*]}"

  if pylint "${pylint_args[@]}"; then
    log_success "Pylint passed"
    return 0
  else
    log_error "Pylint failed"
    return 1
  fi
}

# Run Black for Python projects
run_black() {
  log_info "Running Black format check"

  if ! command -v black >/dev/null 2>&1; then
    log_error "black is not available"
    return 1
  fi

  local black_args=("--check" "--diff")

  # Add source directory
  black_args+=("src/")

  log_debug "Black args: ${black_args[*]}"

  if black "${black_args[@]}"; then
    log_success "Black check passed"
    return 0
  else
    log_error "Black check failed"
    return 1
  fi
}

# Run Flake8 for Python projects
run_flake8() {
  log_info "Running Flake8"

  if ! command -v flake8 >/dev/null 2>&1; then
    log_error "flake8 is not available"
    return 1
  fi

  local flake8_args=()

  # Add source directory
  flake8_args+=("src/")

  log_debug "Flake8 args: ${flake8_args[*]}"

  if flake8 "${flake8_args[@]}"; then
    log_success "Flake8 passed"
    return 0
  else
    log_error "Flake8 failed"
    return 1
  fi
}

# Lint Python project
lint_python_project() {
  log_info "Linting Python project"

  local lint_success=true

  # Run Black
  if ! run_black; then
    lint_success=false
  fi

  # Run Flake8
  if ! run_flake8; then
    lint_success=false
  fi

  # Run Pylint (optional, as it can be strict)
  if command -v pylint >/dev/null 2>&1; then
    if ! run_pylint; then
      lint_success=false
    fi
  else
    log_info "Pylint not available, skipping"
  fi

  return $([[ "$lint_success" == "true" ]] && echo 0 || echo 1)
}

# Run golangci-lint for Go projects
run_golangci_lint() {
  log_info "Running golangci-lint"

  if ! command -v golangci-lint >/dev/null 2>&1; then
    log_error "golangci-lint is not available"
    return 1
  fi

  local golint_config="${GOLINT_CONFIG:-$DEFAULT_GOLINT_CONFIG}"
  local golint_args=("run")

  # Use custom config if exists
  if [[ -f "$golint_config" ]]; then
    golint_args+=("--config" "$golint_config")
  fi

  log_debug "golangci-lint args: ${golint_args[*]}"

  if golangci-lint "${golint_args[@]}"; then
    log_success "golangci-lint passed"
    return 0
  else
    log_error "golangci-lint failed"
    return 1
  fi
}

# Run gofmt for Go projects
run_gofmt() {
  log_info "Running gofmt check"

  if ! command -v gofmt >/dev/null 2>&1; then
    log_error "gofmt is not available"
    return 1
  fi

  local gofmt_args=("-l" ".")

  log_debug "gofmt args: ${gofmt_args[*]}"

  local unformatted_files
  unformatted_files=$(gofmt "${gofmt_args[@]}" 2>/dev/null || true)

  if [[ -z "$unformatted_files" ]]; then
    log_success "gofmt check passed"
    return 0
  else
    log_error "gofmt check failed - unformatted files:"
    echo "$unformatted_files" | sed 's/^/  /'
    return 1
  fi
}

# Lint Go project
lint_go_project() {
  log_info "Linting Go project"

  local lint_success=true

  # Run gofmt
  if ! run_gofmt; then
    lint_success=false
  fi

  # Run golangci-lint
  if command -v golangci-lint >/dev/null 2>&1; then
    if ! run_golangci_lint; then
      lint_success=false
    fi
  else
    log_info "golangci-lint not available, skipping"
  fi

  return $([[ "$lint_success" == "true" ]] && echo 0 || echo 1)
}

# Run cargo clippy for Rust projects
run_cargo_clippy() {
  log_info "Running cargo clippy"

  if ! command -v cargo >/dev/null 2>&1; then
    log_error "cargo is not available"
    return 1
  fi

  local clippy_config="${CLIPPY_CONFIG:-$DEFAULT_CLIPPY_CONFIG}"
  local clippy_args=("clippy" "--all-targets" "--all-features" "--" "-D" "warnings")

  log_debug "Cargo clippy args: ${clippy_args[*]}"

  if cargo "${clippy_args[@]}"; then
    log_success "cargo clippy passed"
    return 0
  else
    log_error "cargo clippy failed"
    return 1
  fi
}

# Run cargo fmt for Rust projects
run_cargo_fmt() {
  log_info "Running cargo fmt check"

  if ! command -v cargo >/dev/null 2>&1; then
    log_error "cargo is not available"
    return 1
  fi

  local cargo_fmt_args=("fmt" "--all" "--" "--check")

  log_debug "Cargo fmt args: ${cargo_fmt_args[*]}"

  if cargo "${cargo_fmt_args[@]}"; then
    log_success "cargo fmt check passed"
    return 0
  else
    log_error "cargo fmt check failed"
    return 1
  fi
}

# Lint Rust project
lint_rust_project() {
  log_info "Linting Rust project"

  local lint_success=true

  # Run cargo fmt
  if ! run_cargo_fmt; then
    lint_success=false
  fi

  # Run cargo clippy
  if ! run_cargo_clippy; then
    lint_success=false
  fi

  return $([[ "$lint_success" == "true" ]] && echo 0 || echo 1)
}

# Lint generic project
lint_generic_project() {
  log_info "Linting generic project"

  # Run ShellCheck on shell scripts
  if command -v shellcheck >/dev/null 2>&1; then
    log_info "Running ShellCheck"
    local shell_files
    shell_files=$(find . -name "*.sh" -not -path "./node_modules/*" -not -path "./.git/*" 2>/dev/null || true)

    if [[ -n "$shell_files" ]]; then
      if echo "$shell_files" | xargs shellcheck; then
        log_success "ShellCheck passed"
      else
        log_error "ShellCheck failed"
        return 1
      fi
    else
      log_info "No shell files found"
    fi
  else
    log_info "ShellCheck not available, skipping"
  fi

  return 0
}

# Run linting for detected project type
run_linting() {
  local project_type="${1:-$(detect_project_type)}"
  local lint_success=true

  ensure_lint_results_directory

  case "$project_type" in
    "nodejs")
      lint_nodejs_project || lint_success=false
      ;;
    "python")
      lint_python_project || lint_success=false
      ;;
    "go")
      lint_go_project || lint_success=false
      ;;
    "rust")
      lint_rust_project || lint_success=false
      ;;
    "generic")
      lint_generic_project || lint_success=false
      ;;
    *)
      log_warn "Unknown project type: $project_type, using generic linting"
      lint_generic_project || lint_success=false
      ;;
  esac

  local lint_status="success"
  if [[ "$lint_success" != "true" ]]; then
    lint_status="failure"
  fi

  generate_lint_report "$project_type" "$lint_status"

  return $([[ "$lint_success" == "true" ]] && echo 0 || echo 1)
}

# Main linting function
main() {
  local project_type="${1:-}"
  local behavior
  behavior=$(get_script_behavior)

  log_info "CI Lint Script v$LINT_SCRIPT_VERSION"

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would lint project"
      if [[ -n "$project_type" ]]; then
        echo "Project type: $project_type"
      else
        echo "Project type: $(detect_project_type)"
      fi
      echo "Would run linters and generate report"
      return 0
      ;;
    "PASS")
      echo "✅ PASS MODE: Lint simulated successfully"
      return 0
      ;;
    "FAIL")
      echo "❌ FAIL MODE: Simulating lint failure"
      return 1
      ;;
    "SKIP")
      echo "⏭️ SKIP MODE: Lint skipped"
      return 0
      ;;
    "TIMEOUT")
      echo "⏰ TIMEOUT MODE: Simulating lint timeout"
      sleep 5
      return 124
      ;;
  esac

  # EXECUTE mode - Actual linting
  log_info "🚀 EXECUTE: Linting project"

  # Use provided project type or detect automatically
  if [[ -z "$project_type" ]]; then
    project_type=$(detect_project_type)
  fi

  log_info "Project type: $project_type"

  # Change to project root if not already there
  if [[ "$PWD" != "$PROJECT_ROOT" ]]; then
    cd "$PROJECT_ROOT"
  fi

  # Run linting
  if run_linting "$project_type"; then
    log_success "✅ Lint script completed successfully"
    return 0
  else
    log_error "❌ Lint script failed"
    return 1
  fi
}

# CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Parse command line arguments
  case "${1:-}" in
    "help"|"--help"|"-h")
      cat << EOF
CI Lint Script v$LINT_SCRIPT_VERSION

Runs linting based on detected project type with full testability support.

Usage:
  ./scripts/build/20-ci-lint.sh [project_type]

Project Types:
  nodejs   - Node.js project (ESLint, Prettier)
  python   - Python project (Black, Flake8, Pylint)
  go       - Go project (golangci-lint, gofmt)
  rust     - Rust project (cargo clippy, cargo fmt)
  generic  - Generic project (ShellCheck)

Linter Configuration:
  ESLINT_CONFIG     Path to ESLint configuration (.eslintrc.js)
  PRETTIER_CONFIG   Path to Prettier configuration (.prettierrc)
  PYLINT_CONFIG     Path to Pylint configuration (.pylintrc)
  GOLINT_CONFIG     Path to golangci-lint configuration (golangci-lint.yml)
  CLIPPY_CONFIG     Path to Clippy configuration (clippy.toml)

Environment Variables:
  PIPELINE_LINT_MODE  EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT
  LINT_MODE          EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT
  CI_TEST_MODE       Global testability mode
  CI_JOB_TIMEOUT_MINUTES  Timeout override for lint operations

Testability:
  This script supports hierarchical testability control:
  1. PIPELINE_LINT_MODE (highest priority)
  2. LINT_MODE
  3. CI_TEST_MODE (global)
  4. Default: EXECUTE

Examples:
  # Auto-detect and lint
  ./scripts/build/20-ci-lint.sh

  # Lint specific project type
  ./scripts/build/20-ci-lint.sh nodejs

  # Dry run linting
  LINT_MODE=DRY_RUN ./scripts/build/20-ci-lint.sh

  # Simulate failure
  LINT_MODE=FAIL ./scripts/build/20-ci-lint.sh

  # Pipeline-level override
  PIPELINE_LINT_MODE=SKIP ./scripts/build/20-ci-lint.sh

Integration:
  This script integrates with:
  - GitHub Actions workflows
  - Local development environments
  - CI/CD pipeline orchestration
  - Multi-language project linting
EOF
      exit 0
      ;;
    "detect")
      # Detection mode
      echo "Detected project type: $(detect_project_type)"
      ;;
    "validate")
      # Validation mode
      echo "Validating lint setup..."

      local project_type
      project_type=$(detect_project_type)
      echo "Project type: $project_type"

      case "$project_type" in
        "nodejs")
          command -v npx >/dev/null && echo "✅ npx available" || echo "❌ npx not available"
          ;;
        "python")
          command -v black >/dev/null && echo "✅ black available" || echo "⚠️ black not available"
          command -v flake8 >/dev/null && echo "✅ flake8 available" || echo "⚠️ flake8 not available"
          command -v pylint >/dev/null && echo "✅ pylint available" || echo "⚠️ pylint not available"
          ;;
        "go")
          command -v gofmt >/dev/null && echo "✅ gofmt available" || echo "❌ gofmt not available"
          command -v golangci-lint >/dev/null && echo "✅ golangci-lint available" || echo "⚠️ golangci-lint not available"
          ;;
        "rust")
          command -v cargo >/dev/null && echo "✅ cargo available" || echo "❌ cargo not available"
          ;;
        "generic")
          command -v shellcheck >/dev/null && echo "✅ shellcheck available" || echo "⚠️ shellcheck not available"
          ;;
      esac
      ;;
    *)
      main "$@"
      ;;
  esac
fi