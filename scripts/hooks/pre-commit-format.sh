#!/usr/bin/env bash
# Pre-commit Format Hook
# Formats bash scripts using shfmt

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

# Check if shfmt is available
check_shfmt() {
  if ! command -v shfmt >/dev/null 2>&1; then
    log_warning "shfmt not found, skipping formatting"
    return 1
  fi
  return 0
}

# Get list of staged shell files
get_staged_shell_files() {
  # Get staged files that are shell scripts
  git diff --cached --name-only --diff-filter=ACM | grep -E '\.(sh|bash|ksh|zsh)$' || true
}

# Format staged shell files
format_staged_files() {
  log_info "Formatting staged shell files with shfmt"

  local staged_files
  readarray -t staged_files < <(get_staged_shell_files)

  if [[ ${#staged_files[@]} -eq 0 ]]; then
    log_info "No shell files to format"
    return 0
  fi

  log_info "Formatting ${#staged_files[@]} shell files"

  local files_to_restage=()
  local formatting_errors=0

  for file in "${staged_files[@]}"; do
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
          log_info "Formatted: $file"
          files_to_restage+=("$file")
        fi
      else
        log_error "Formatting failed for: $file"
        ((formatting_errors++))
      fi

      # Clean up backup
      rm -f "$temp_file"
    fi
  done

  # Restage formatted files
  if [[ ${#files_to_restage[@]} -gt 0 ]]; then
    log_info "Restaging ${#files_to_restage[@]} formatted files"
    git add "${files_to_restage[@]}"
  fi

  # Check for errors
  if [[ $formatting_errors -gt 0 ]]; then
    log_error "❌ Formatting failed for $formatting_errors files"
    return 1
  fi

  log_success "✅ Shell scripts formatted successfully"
}

# Check formatting without modifying files
check_format() {
  log_info "Checking shell script formatting"

  local staged_files
  readarray -t staged_files < <(get_staged_shell_files)

  if [[ ${#staged_files[@]} -eq 0 ]]; then
    log_info "No shell files to check"
    return 0
  fi

  log_info "Checking ${#staged_files[@]} shell files"

  local formatting_issues=0

  for file in "${staged_files[@]}"; do
    if [[ -f "$file" ]]; then
      if ! shfmt -d -i 2 -ci -sr "$file" 2>/dev/null; then
        log_error "Formatting issues found in: $file"
        log_info "Run 'shfmt -w -i 2 -ci -sr $file' to fix"
        ((formatting_issues++))
      fi
    fi
  done

  if [[ $formatting_issues -gt 0 ]]; then
    log_error "❌ Formatting issues found in $formatting_issues files"
    return 1
  fi

  log_success "✅ All shell scripts are properly formatted"
}

# Main execution
main() {
  local mode="${1:-format}"

  log_info "🎨 Running pre-commit formatting ($mode)"

  if ! check_shfmt; then
    return 0
  fi

  case "$mode" in
    "check")
      check_format
      ;;
    "format"|*)
      format_staged_files
      ;;
  esac
}

# Execute main function
main "$@"