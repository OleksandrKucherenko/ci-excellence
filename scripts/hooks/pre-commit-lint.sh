#!/usr/bin/env bash
# Pre-commit Lint Hook
# Runs shellcheck on staged shell files

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

log_error() {
  echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $*" >&2
}

log_info() {
  echo -e "${GREEN}[INFO]${NC} $*" >&2
}

# Check if shellcheck is available
check_shellcheck() {
  if ! command -v shellcheck >/dev/null 2>&1; then
    log_warning "shellcheck not found, skipping linting"
    return 1
  fi
  return 0
}

# Get list of staged shell files
get_staged_shell_files() {
  # Get staged files that are shell scripts
  git diff --cached --name-only --diff-filter=ACM | grep -E '\.(sh|bash|ksh|zsh)$' || true
}

# Lint staged shell files
lint_staged_files() {
  log_info "Running shellcheck on staged shell files"

  local staged_files
  readarray -t staged_files < <(get_staged_shell_files)

  if [[ ${#staged_files[@]} -eq 0 ]]; then
    log_info "No shell files to lint"
    return 0
  fi

  log_info "Linting ${#staged_files[@]} shell files"

  local lint_errors=0
  local warning_count=0

  # Create temporary file for shellcheck configuration
  local config_file
  config_file=$(mktemp)
  cat > "$config_file" <<EOF
# Shellcheck configuration for this project
enable=all

# Disable some rules that are handled by other tools
exclude=SC2086,SC2155

# Set shell dialect
shell=bash

# Add source paths for shellcheck to find sourced files
source=scripts/lib
source=scripts/hooks
source=scripts/ci

# Severity levels
severity=style
EOF

  # Run shellcheck on each file
  for file in "${staged_files[@]}"; do
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
        echo "$shellcheck_output" | grep "error:" | head -10
        ((lint_errors += errors))
      elif [[ $warnings -gt 0 ]]; then
        log_warning "⚠️  Shellcheck warnings in $file ($warnings warnings)"
        ((warning_count += warnings))
      else
        log_info "✅ Shellcheck passed for $file"
      fi
    fi
  done

  # Clean up config file
  rm -f "$config_file"

  # Report summary
  if [[ $lint_errors -gt 0 ]]; then
    log_error ""
    log_error "❌ Shellcheck failed with $lint_errors errors and $warning_count warnings"
    log_error ""
    log_error "To fix this:"
    log_error "1. Review and fix the shellcheck errors above"
    log_error "2. Consider adding shellcheck directives to suppress false positives"
    log_error "3. Restage your changes and retry the commit"
    return 1
  elif [[ $warning_count -gt 0 ]]; then
    log_warning ""
    log_warning "⚠️ Shellcheck completed with $warning_count warnings (no errors)"
    log_warning "Consider fixing warnings for better code quality"
  else
    log_success "✅ All shell scripts passed shellcheck"
  fi

  log_info "Shellcheck completed: $lint_errors errors, $warning_count warnings"
}

# Main execution
main() {
  log_info "🔍 Running pre-commit shellcheck"

  if ! check_shellcheck; then
    return 0
  fi

  lint_staged_files
}

# Execute main function
main "$@"