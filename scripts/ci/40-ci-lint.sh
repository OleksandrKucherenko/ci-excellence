#!/usr/bin/env bash
# CI Lint Script
# Runs comprehensive linting including shell, TypeScript, and security linting

set -euo pipefail

# Source shared utilities
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Script configuration
readonly SCRIPT_NAME="$(basename "$0" .sh)"
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_DESCRIPTION="Run comprehensive linting suite"

# Default lint configuration
DEFAULT_LINT_TYPE="all"
DEFAULT_FIX_ISSUES=false
DEFAULT_FAIL_ON_WARNINGS=false

# Usage information
usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS] [PATH_PATTERN]

Run comprehensive linting including shell, TypeScript, and security linting.

OPTIONS:
  -t, --type TYPE           Lint type to run (shell|typescript|security|all) [default: $DEFAULT_LINT_TYPE]
  -f, --fix                 Auto-fix fixable issues
  --no-fix                  Do not auto-fix issues
  -w, --fail-on-warnings    Treat warnings as errors
  --no-fail-on-warnings     Do not treat warnings as errors (default)
  -p, --pattern PATTERN     Path pattern to lint (can also be passed as argument)
  -e, --exclude PATTERN     Path pattern to exclude from linting
  -t, --test-mode MODE      Test mode (DRY_RUN|SIMULATE|EXECUTE)
  -h, --help                Show this help message
  -V, --version             Show version information

ARGUMENTS:
  PATH_PATTERN              Path pattern to lint (same as --pattern)

EXAMPLES:
  $SCRIPT_NAME                           # Run all linting
  $SCRIPT_NAME --type shell              # Run only shell linting
  $SCRIPT_NAME --fix                     # Run linting with auto-fix
  $SCRIPT_NAME --pattern "src/**/*"      # Lint specific paths
  $SCRIPT_NAME --exclude "node_modules"  # Exclude paths from linting

LINT TYPES:
  shell         Run shellcheck on shell scripts
  typescript    Run ESLint/Prettier on TypeScript/JavaScript
  security      Run security-focused linting
  all           Run all lint types (default)

ENVIRONMENT VARIABLES:
  CI_TEST_MODE               Test mode override (DRY_RUN|SIMULATE|EXECUTE)
  CI_LINT_TYPE               Lint type override
  CI_FIX_ISSUES              Auto-fix issues (true|false)
  CI_FAIL_ON_WARNINGS        Treat warnings as errors (true|false)
  LINT_PATTERN               Default path pattern
  LINT_EXCLUDE               Default exclude pattern
  SHELLCHECK_SEVERITY        Minimum severity level (style|warning|error)

EXIT CODES:
  0     Success (all linting passed)
  1     General error
  2     Linting failed
  3     Auto-fix failed
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
  local opt_lint_type="$DEFAULT_LINT_TYPE"
  local opt_fix_issues="$DEFAULT_FIX_ISSUES"
  local opt_fail_on_warnings="$DEFAULT_FAIL_ON_WARNINGS"
  local opt_path_pattern=""
  local opt_exclude_pattern=""
  local opt_test_mode=""

  # Parse options
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -t|--type)
        shift
        if [[ -z "$1" ]]; then
          log_error "Lint type cannot be empty"
          return 4
        fi
        case "$1" in
          shell|typescript|security|all) ;;
          *)
            log_error "Invalid lint type: $1. Use shell, typescript, security, or all"
            return 4
            ;;
        esac
        opt_lint_type="$1"
        shift
        ;;
      -f|--fix)
        opt_fix_issues=true
        shift
        ;;
      --no-fix)
        opt_fix_issues=false
        shift
        ;;
      -w|--fail-on-warnings)
        opt_fail_on_warnings=true
        shift
        ;;
      --no-fail-on-warnings)
        opt_fail_on_warnings=false
        shift
        ;;
      -p|--pattern)
        shift
        if [[ -z "$1" ]]; then
          log_error "Path pattern cannot be empty"
          return 4
        fi
        opt_path_pattern="$1"
        shift
        ;;
      -e|--exclude)
        shift
        if [[ -z "$1" ]]; then
          log_error "Exclude pattern cannot be empty"
          return 4
        fi
        opt_exclude_pattern="$1"
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
        if [[ -z "$opt_path_pattern" ]]; then
          opt_path_pattern="$1"
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
  export LINT_TYPE="$opt_lint_type"
  export FIX_ISSUES="$opt_fix_issues"
  export FAIL_ON_WARNINGS="$opt_fail_on_warnings"
  export PATH_PATTERN="$opt_path_pattern"
  export EXCLUDE_PATTERN="$opt_exclude_pattern"

  # Resolve test mode
  local resolved_mode
  if ! resolved_mode=$(resolve_test_mode "$SCRIPT_NAME" "lint" "$opt_test_mode"); then
    return 1
  fi
  export TEST_MODE="$resolved_mode"

  return 0
}

# Check lint prerequisites
check_prerequisites() {
  log_info "Checking lint prerequisites"

  local missing_tools=()

  # Check for shellcheck (for shell linting)
  if [[ "$LINT_TYPE" == "all" || "$LINT_TYPE" == "shell" ]]; then
    if ! command -v shellcheck >/dev/null 2>&1; then
      missing_tools+=("shellcheck")
    fi
  fi

  # Check for shfmt (for shell formatting)
  if [[ "$LINT_TYPE" == "all" || "$LINT_TYPE" == "shell" ]]; then
    if ! command -v shfmt >/dev/null 2>&1; then
      missing_tools+=("shfmt")
    fi
  fi

  # Check for Node.js tools (for TypeScript linting)
  if [[ "$LINT_TYPE" == "all" || "$LINT_TYPE" == "typescript" ]]; then
    if [[ -f "package.json" ]]; then
      # Check for ESLint
      if ! command -v eslint >/dev/null 2>&1 && [[ ! -f "node_modules/.bin/eslint" ]]; then
        missing_tools+=("eslint")
      fi

      # Check for Prettier
      if ! command -v prettier >/dev/null 2>&1 && [[ ! -f "node_modules/.bin/prettier" ]]; then
        log_warning "prettier not found, code formatting will be skipped"
      fi

      # Check for TypeScript compiler
      if [[ -f "tsconfig.json" ]] && ! command -v tsc >/dev/null 2>&1 && ! command -v bun >/dev/null 2>&1; then
        missing_tools+=("typescript")
      fi
    fi
  fi

  if [[ ${#missing_tools[@]} -gt 0 ]]; then
    log_error "Missing lint tools: ${missing_tools[*]}"
    return 5
  fi

  log_success "✅ Lint prerequisites met"
  return 0
}

# Configure lint environment
configure_lint_environment() {
  log_info "Configuring lint environment"

  # Export lint environment variables
  export LINT_TYPE="$LINT_TYPE"
  export FIX_ISSUES="$FIX_ISSUES"
  export FAIL_ON_WARNINGS="$FAIL_ON_WARNINGS"
  export TEST_MODE="$TEST_MODE"

  # Configure shellcheck settings
  export SHELLCHECK_SEVERITY="${SHELLCHECK_SEVERITY:-style}"
  export SHELLCHECK_EXCLUDE="${SHELLCHECK_EXCLUDE:-SC2086,SC2155}"
  export SHELLCHECK_SHELL="${SHELLCHECK_SHELL:-bash}"

  # Configure ESLint settings
  export ESLINT_CONFIG="${ESLINT_CONFIG:-.eslintrc.js}"
  export ESLINT_FORMAT="${ESLINT_FORMAT:-stylish}"
  export ESLINT_MAX_WARNINGS="${ESLINT_MAX_WARNINGS:-0}"

  # Configure Prettier settings
  export PRETTIER_CONFIG="${PRETTIER_CONFIG:-.prettierrc}"
  export PRETTIER_TAB_WIDTH="${PRETTIER_TAB_WIDTH:-2}"
  export PRETTIER_USE_TABS="${PRETTIER_USE_TABS:-false}"

  # Set default patterns
  local default_pattern="${PATH_PATTERN:-**/*.{sh,ts,js,json,md,yml,yaml}}"
  export PATH_PATTERN="${default_pattern}"

  log_info "Lint environment configured:"
  log_info "  Lint type: $LINT_TYPE"
  log_info "  Fix issues: $FIX_ISSUES"
  log_info "  Fail on warnings: $FAIL_ON_WARNINGS"
  log_info "  Path pattern: $PATH_PATTERN"
  log_info "  Exclude pattern: ${EXCLUDE_PATTERN:-none}"
  log_info "  Shellcheck severity: $SHELLCHECK_SEVERITY"

  return 0
}

# Find files to lint
find_files_to_lint() {
  local file_type="$1"
  local files=()

  case "$file_type" in
    "shell")
      # Find shell files
      while IFS= read -r -d '' file; do
        files+=("$file")
      done < <(find . -type f \( -name "*.sh" -o -name "*.bash" -o -name "*.ksh" \) \
              ${PATH_PATTERN:+-path "$PATH_PATTERN"} \
              ${EXCLUDE_PATTERN:+-not -path "$EXCLUDE_PATTERN"} \
              -not -path "./node_modules/*" \
              -not -path "./.git/*" \
              -print0 2>/dev/null)
      ;;
    "typescript")
      # Find TypeScript and JavaScript files
      while IFS= read -r -d '' file; do
        files+=("$file")
      done < <(find . -type f \( -name "*.ts" -o -name "*.js" -o -name "*.jsx" -o -name "*.tsx" \) \
              ${PATH_PATTERN:+-path "$PATH_PATTERN"} \
              ${EXCLUDE_PATTERN:+-not -path "$EXCLUDE_PATTERN"} \
              -not -path "./node_modules/*" \
              -not -path "./dist/*" \
              -not -path "./build/*" \
              -not -path "./.git/*" \
              -print0 2>/dev/null)
      ;;
    "config")
      # Find configuration files
      while IFS= read -r -d '' file; do
        files+=("$file")
      done < <(find . -type f \( -name "*.json" -o -name "*.yml" -o -name "*.yaml" -o -name "*.md" \) \
              ${PATH_PATTERN:+-path "$PATH_PATTERN"} \
              ${EXCLUDE_PATTERN:+-not -path "$EXCLUDE_PATTERN"} \
              -not -path "./node_modules/*" \
              -not -path "./dist/*" \
              -not -path "./.git/*" \
              -print0 2>/dev/null)
      ;;
  esac

  printf '%s\n' "${files[@]}"
}

# Run shellcheck linting
run_shellcheck_lint() {
  log_info "Running shellcheck linting"

  local files
  readarray -t files < <(find_files_to_lint "shell")

  if [[ ${#files[@]} -eq 0 ]]; then
    log_info "No shell files to lint"
    return 0
  fi

  log_info "Linting ${#files[@]} shell files"

  case "$TEST_MODE" in
    "DRY_RUN")
      log_info "Would run shellcheck on ${#files[@]} files"
      return 0
      ;;
    "SIMULATE")
      log_info "Simulating shellcheck on ${#files[@]} files"
      sleep 1
      return 0
      ;;
  esac

  # Create temporary config file for shellcheck
  local config_file
  config_file=$(mktemp)
  cat > "$config_file" << EOF
# Shellcheck configuration for this project
enable=all

# Exclude specific rules that are handled elsewhere
exclude=$SHELLCHECK_EXCLUDE

# Set shell dialect
shell=$SHELLCHECK_SHELL

# Add source paths for shellcheck to find sourced files
source=scripts/lib
source=scripts/hooks
source=scripts/ci

# Severity level
severity=$SHELLCHECK_SEVERITY
EOF

  local shellcheck_failed=false
  local warning_count=0
  local error_count=0

  # Run shellcheck on each file
  for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
      log_info "Linting: $file"

      # Run shellcheck with configuration
      local shellcheck_output
      shellcheck_output=$(shellcheck --config-file="$config_file" "$file" 2>&1 || true)

      # Count warnings and errors
      local warnings
      local errors
      warnings=$(echo "$shellcheck_output" | grep -c "warning:" || true)
      errors=$(echo "$shellcheck_output" | grep -c "error:" || true)

      if [[ $errors -gt 0 ]]; then
        log_error "❌ Shellcheck errors in $file:"
        echo "$shellcheck_output" | grep "error:" | head -5
        ((error_count += errors))
        shellcheck_failed=true
      elif [[ $warnings -gt 0 ]]; then
        log_warning "⚠️  Shellcheck warnings in $file ($warnings warnings)"
        ((warning_count += warnings))
        if [[ "$FAIL_ON_WARNINGS" == "true" ]]; then
          shellcheck_failed=true
        fi
      else
        log_success "✅ Shellcheck passed for $file"
      fi
    fi
  done

  # Clean up config file
  rm -f "$config_file"

  # Report summary
  if [[ "$shellcheck_failed" == "true" ]]; then
    log_error ""
    log_error "❌ Shellcheck failed with $error_count errors and $warning_count warnings"
    log_error ""
    log_error "To fix this:"
    log_error "1. Review and fix the shellcheck errors above"
    log_error "2. Consider adding shellcheck directives to suppress false positives"
    log_error "3. Run '$SCRIPT_NAME --type shell --fix' to auto-fix where possible"
    return 2
  elif [[ $warning_count -gt 0 ]]; then
    log_warning ""
    log_warning "⚠️ Shellcheck completed with $warning_count warnings (no errors)"
    log_warning "Consider fixing warnings for better code quality"
  else
    log_success "✅ All shell scripts passed shellcheck"
  fi

  log_info "Shellcheck completed: $error_count errors, $warning_count warnings"
  return 0
}

# Run shell formatting with shfmt
run_shfmt_format() {
  if [[ "$FIX_ISSUES" != "true" ]]; then
    log_info "Shell formatting disabled (use --fix to enable)"
    return 0
  fi

  log_info "Running shell formatting with shfmt"

  local files
  readarray -t files < <(find_files_to_lint "shell")

  if [[ ${#files[@]} -eq 0 ]]; then
    log_info "No shell files to format"
    return 0
  fi

  case "$TEST_MODE" in
    "DRY_RUN")
      log_info "Would format ${#files[@]} shell files"
      return 0
      ;;
    "SIMULATE")
      log_info "Simulating shell formatting on ${#files[@]} files"
      sleep 1
      return 0
      ;;
  esac

  local formatted_files=()
  local format_errors=0

  for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
      log_info "Formatting: $file"

      # Create a backup to compare
      local temp_file
      temp_file=$(mktemp)
      cp "$file" "$temp_file"

      # Format the file
      if shfmt -w -i 2 -ci -sr "$file" 2>/dev/null; then
        # Check if file was changed
        if ! diff -q "$temp_file" "$file" >/dev/null 2>&1; then
          log_success "Formatted: $file"
          formatted_files+=("$file")
        fi
      else
        log_error "Formatting failed for: $file"
        ((format_errors++))
      fi

      # Clean up backup
      rm -f "$temp_file"
    fi
  done

  # Report results
  if [[ $format_errors -gt 0 ]]; then
    log_error "❌ Shell formatting failed for $format_errors files"
    return 3
  elif [[ ${#formatted_files[@]} -gt 0 ]]; then
    log_success "✅ Formatted ${#formatted_files[@]} shell files"
  else
    log_info "All shell files are already properly formatted"
  fi

  return 0
}

# Run ESLint linting
run_eslint_lint() {
  log_info "Running ESLint linting"

  local files
  readarray -t files < <(find_files_to_lint "typescript")

  if [[ ${#files[@]} -eq 0 ]]; then
    log_info "No TypeScript/JavaScript files to lint"
    return 0
  fi

  log_info "Linting ${#files[@]} TypeScript/JavaScript files"

  case "$TEST_MODE" in
    "DRY_RUN")
      log_info "Would run ESLint on ${#files[@]} files"
      return 0
      ;;
    "SIMULATE")
      log_info "Simulating ESLint on ${#files[@]} files"
      sleep 2
      return 0
      ;;
  esac

  # Find ESLint executable
  local eslint_cmd="eslint"
  if [[ ! -f "node_modules/.bin/eslint" ]] && command -v npx >/dev/null 2>&1; then
    eslint_cmd="npx eslint"
  elif [[ -f "node_modules/.bin/eslint" ]]; then
    eslint_cmd="./node_modules/.bin/eslint"
  else
    log_warning "ESLint not found, skipping TypeScript/JavaScript linting"
    return 0
  fi

  # Build ESLint command
  local eslint_args=(
    "--format" "$ESLINT_FORMAT"
    "--max-warnings" "$ESLINT_MAX_WARNINGS"
  )

  if [[ "$FAIL_ON_WARNINGS" == "true" ]]; then
    eslint_args+=("--max-warnings" "0")
  fi

  if [[ "$FIX_ISSUES" == "true" ]]; then
    eslint_args+=("--fix")
  fi

  # Run ESLint
  if eval "$eslint_cmd ${eslint_args[*]} ${files[*]}"; then
    log_success "✅ ESLint passed for all TypeScript/JavaScript files"
  else
    local exit_code=$?
    log_error "❌ ESLint failed for TypeScript/JavaScript files"
    return 2
  fi

  return 0
}

# Run TypeScript compiler check
run_typescript_check() {
  if [[ ! -f "tsconfig.json" ]]; then
    log_info "No TypeScript configuration found, skipping type checking"
    return 0
  fi

  log_info "Running TypeScript type checking"

  case "$TEST_MODE" in
    "DRY_RUN")
      log_info "Would run TypeScript type checking"
      return 0
      ;;
    "SIMULATE")
      log_info "Simulating TypeScript type checking"
      sleep 2
      return 0
      ;;
  esac

  # Use TypeScript compiler if available
  if command -v tsc >/dev/null 2>&1; then
    log_info "Using TypeScript compiler"
    if tsc --noEmit; then
      log_success "✅ TypeScript type checking passed"
    else
      log_error "❌ TypeScript type checking failed"
      return 2
    fi
  elif command -v bun >/dev/null 2>&1; then
    log_info "Using bun for TypeScript checking"
    if bun tsc --noEmit; then
      log_success "✅ TypeScript type checking passed"
    else
      log_error "❌ TypeScript type checking failed"
      return 2
    fi
  else
    log_warning "TypeScript compiler not available, skipping type checking"
    return 0
  fi

  return 0
}

# Run configuration file linting
run_config_lint() {
  log_info "Running configuration file linting"

  local files
  readarray -t files < <(find_files_to_lint "config")

  if [[ ${#files[@]} -eq 0 ]]; then
    log_info "No configuration files to lint"
    return 0
  fi

  log_info "Linting ${#files[@]} configuration files"

  case "$TEST_MODE" in
    "DRY_RUN")
      log_info "Would lint ${#files[@]} configuration files"
      return 0
      ;;
    "SIMULATE")
      log_info "Simulating configuration file linting"
      sleep 1
      return 0
      ;;
  esac

  # Check for Prettier and run it if available
  local prettier_cmd="prettier"
  if [[ ! -f "node_modules/.bin/prettier" ]] && command -v npx >/dev/null 2>&1; then
    prettier_cmd="npx prettier"
  elif [[ -f "node_modules/.bin/prettier" ]]; then
    prettier_cmd="./node_modules/.bin/prettier"
  else
    log_warning "Prettier not found, skipping configuration file formatting"
    return 0
  fi

  # Build Prettier command
  local prettier_args=(
    "--check"  # Check mode, don't write files
  )

  if [[ "$FIX_ISSUES" == "true" ]]; then
    prettier_args=("--write")  # Write mode
  fi

  # Run Prettier
  if eval "$prettier_cmd ${prettier_args[*]} ${files[*]}"; then
    if [[ "$FIX_ISSUES" == "true" ]]; then
      log_success "✅ Configuration files formatted successfully"
    else
      log_success "✅ Configuration files passed formatting check"
    fi
  else
    local exit_code=$?
    if [[ "$FIX_ISSUES" == "true" ]]; then
      log_error "❌ Configuration file formatting failed"
    else
      log_error "❌ Configuration files failed formatting check"
      log_error "Run '$SCRIPT_NAME --fix' to auto-fix formatting issues"
    fi
    return 2
  fi

  return 0
}

# Generate lint report
generate_lint_report() {
  local lint_status="$1"
  local start_time="$2"
  local end_time=$(date +%s)

  log_info "Generating lint report"

  local lint_duration=$((end_time - start_time))
  local output_dir="${LINT_REPORT_OUTPUT:-reports/lint}"
  mkdir -p "$output_dir"

  local report_file="$output_dir/lint-report-$(date +%Y%m%d-%H%M%S).json"

  # Count files by type
  local shell_files=0
  local typescript_files=0
  local config_files=0

  shell_files=$(find . -type f \( -name "*.sh" -o -name "*.bash" \) 2>/dev/null | wc -l)
  typescript_files=$(find . -type f \( -name "*.ts" -o -name "*.js" -o -name "*.jsx" -o -name "*.tsx" \) \
                     -not -path "./node_modules/*" 2>/dev/null | wc -l)
  config_files=$(find . -type f \( -name "*.json" -o -name "*.yml" -o -name "*.yaml" -o -name "*.md" \) \
                    -not -path "./node_modules/*" 2>/dev/null | wc -l)

  # Build report content
  cat > "$report_file" << EOF
{
  "lint": {
    "script": "$SCRIPT_NAME",
    "version": "$SCRIPT_VERSION",
    "status": "$lint_status",
    "type": "$LINT_TYPE",
    "test_mode": "$TEST_MODE",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "duration_seconds": $lint_duration,
    "configuration": {
      "fix_issues": "$FIX_ISSUES",
      "fail_on_warnings": "$FAIL_ON_WARNINGS",
      "path_pattern": "$PATH_PATTERN",
      "exclude_pattern": "${EXCLUDE_PATTERN:-none}",
      "shellcheck_severity": "${SHELLCHECK_SEVERITY}"
    }
  },
  "files": {
    "shell_files": $shell_files,
    "typescript_files": $typescript_files,
    "config_files": $config_files,
    "total_files": $((shell_files + typescript_files + config_files))
  }
}
EOF

  log_success "✅ Lint report generated: $report_file"

  # Export for CI systems
  export LINT_REPORT_FILE="$report_file"

  return 0
}

# Main lint function
main() {
  local start_time
  start_time=$(date +%s)

  log_info "🔍 Starting CI linting"
  log_info "Script version: $SCRIPT_VERSION"

  # Parse command line arguments
  if ! parse_args "$@"; then
    return 1
  fi

  log_info "Lint configuration:"
  log_info "  Lint type: $LINT_TYPE"
  log_info "  Fix issues: $FIX_ISSUES"
  log_info "  Fail on warnings: $FAIL_ON_WARNINGS"
  log_info "  Path pattern: $PATH_PATTERN"
  log_info "  Exclude pattern: ${EXCLUDE_PATTERN:-none}"
  log_info "  Test mode: $TEST_MODE"

  # Run lint pipeline
  if ! check_prerequisites; then
    return 5
  fi

  if ! configure_lint_environment; then
    return 1
  fi

  local lint_results=()

  # Run linting based on type
  case "$LINT_TYPE" in
    "shell")
      run_shellcheck_lint || lint_results+=("shellcheck")
      run_shfmt_format || lint_results+=("shfmt")
      ;;
    "typescript")
      run_eslint_lint || lint_results+=("eslint")
      run_typescript_check || lint_results+=("typescript")
      ;;
    "security")
      # Security-focused linting is a subset of other lint types
      run_shellcheck_lint || lint_results+=("shellcheck")
      run_eslint_lint || lint_results+=("eslint")
      ;;
    "all")
      run_shellcheck_lint || lint_results+=("shellcheck")
      run_shfmt_format || lint_results+=("shfmt")
      run_eslint_lint || lint_results+=("eslint")
      run_typescript_check || lint_results+=("typescript")
      run_config_lint || lint_results+=("config")
      ;;
  esac

  # Determine overall result
  if [[ ${#lint_results[@]} -eq 0 ]]; then
    log_success "✅ All linting passed"
    generate_lint_report "success" "$start_time"

    # Show actionable items for CI
    if [[ -n "${CI:-}" ]]; then
      echo
      log_info "🔗 Next steps for CI pipeline:"
      log_info "   • Run tests: scripts/ci/50-ci-test.sh"
      log_info "   • Build artifacts: scripts/build/20-ci-compile.sh"
    fi

    return 0
  else
    log_error "❌ Linting failed in: ${lint_results[*]}"
    generate_lint_report "failed" "$start_time"
    return 2
  fi
}

# Error handling
trap 'log_error "Script failed with exit code $?"' ERR

# Execute main function with all arguments
main "$@"