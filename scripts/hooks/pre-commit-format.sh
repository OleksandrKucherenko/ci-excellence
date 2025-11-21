#!/bin/bash
# Pre-commit Format Hook
# Validates and fixes bash script formatting using shfmt

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common utilities" >&2
  exit 1
}

# Configuration
readonly PRE_COMMIT_FORMAT_VERSION="1.0.0"

# Default shfmt options
DEFAULT_SHFMT_OPTIONS="-i 2 -bn -ci -sr"

# Testability configuration
get_behavior_mode() {
  local script_name="pre_commit_format"
  get_script_behavior "$script_name" "EXECUTE"
}

# Check if shfmt is available
check_shfmt_available() {
  if ! command -v shfmt >/dev/null 2>&1; then
    log_error "❌ shfmt is not installed"
    log_error "Install shfmt: go install mvdan.cc/sh/v3/cmd/shfmt@latest"
    log_error "Or disable this hook by removing it from .lefthook.yml"
    return 1
  fi

  log_debug "shfmt is available"
  return 0
}

# Get shfmt version
get_shfmt_version() {
  shfmt --version 2>/dev/null || echo "unknown"
}

# Validate git repository
validate_git_repository() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    log_error "❌ Not in a git repository"
    return 1
  fi

  return 0
}

# Find bash script files
find_bash_scripts() {
  # Get only staged files
  local staged_files
  staged_files=$(git diff --cached --name-only --diff-filter=ACM)

  if [[ -z "$staged_files" ]]; then
    return 0
  fi

  # Filter for bash files
  local bash_files=()
  while IFS= read -r file; do
    if [[ -f "$file" ]]; then
      # Check file extension
      if [[ "$file" =~ \.(sh|bash|zsh)$ ]]; then
        bash_files+=("$file")
        continue
      fi

      # Check shebang
      if [[ -f "$file" ]] && head -n1 "$file" 2>/dev/null | grep -q '^#!.*bash\|^#!.*sh\|^#!.*zsh'; then
        bash_files+=("$file")
        continue
      fi
    fi
  done <<< "$staged_files"

  if [[ ${#bash_files[@]} -eq 0 ]]; then
    return 0
  fi

  printf '%s\n' "${bash_files[@]}"
}

# Find files with bash shebang
find_shebang_files() {
  local files=("$@")

  local shebang_files=()
  for file in "${files[@]}"; do
    if [[ -f "$file" ]] && head -n1 "$file" 2>/dev/null | grep -q '^#!.*bash\|^#!.*sh\|^#!.*zsh'; then
      shebang_files+=("$file")
    fi
  done

  if [[ ${#shebang_files[@]} -eq 0 ]]; then
    return 0
  fi

  printf '%s\n' "${shebang_files[@]}"
}

# Filter bash files from file list
filter_bash_files() {
  local files=("$@")
  local bash_files=()

  for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
      # Check file extension
      if [[ "$file" =~ \.(sh|bash|zsh)$ ]]; then
        bash_files+=("$file")
        continue
      fi

      # Check shebang
      if head -n1 "$file" 2>/dev/null | grep -q '^#!.*bash\|^#!.*sh\|^#!.*zsh'; then
        bash_files+=("$file")
        continue
      fi
    fi
  done

  printf '%s\n' "${bash_files[@]}"
}

# Check file format
check_file_format() {
  local file="$1"
  local fix_mode="${2:-false}"

  if [[ ! -f "$file" ]]; then
    log_error "File not found: $file"
    return 1
  fi

  # Check if file is binary
  if [[ -f "$file" ]] && ! grep -q . "$file" >/dev/null 2>&1; then
    log_debug "Skipping binary file: $file"
    return 0
  fi

  local shfmt_options
  shfmt_options=$(get_shfmt_options)

  # Check if file needs formatting
  local diff_output
  diff_output=$(shfmt $shfmt_options -d "$file" 2>/dev/null || true)

  if [[ -z "$diff_output" ]]; then
    log_success "✓ $file is properly formatted"
    return 0
  else
    if [[ "$fix_mode" == "true" ]]; then
      # Fix the file
      if shfmt $shfmt_options -w "$file" 2>/dev/null; then
        log_success "✓ Fixed $file"
        return 0
      else
        log_error "✗ Failed to fix $file"
        return 1
      fi
    else
      log_error "✗ $file needs formatting"
      log_info "Run: shfmt $shfmt_options -w $file"
      return 1
    fi
  fi
}

# Fix file format
fix_file_format() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    log_error "File not found: $file"
    return 1
  fi

  if ! check_file_format "$file" "true"; then
    return 1
  fi

  return 0
}

# Check multiple files format
check_files_format() {
  local files=("$@")
  local fix_mode="${FIX_FORMAT:-false}"

  if [[ ${#files[@]} -eq 0 ]]; then
    log_info "No files to check"
    return 0
  fi

  local failed_files=()
  local total_files=${#files[@]}

  log_info "Checking $total_files bash files for format issues"

  for file in "${files[@]}"; do
    if ! check_file_format "$file" "$fix_mode"; then
      failed_files+=("$file")
    fi
  done

  if [[ ${#failed_files[@]} -gt 0 ]]; then
    log_error "❌ ${#failed_files[@]} files need formatting"
    log_error "Files requiring formatting:"
    printf '  %s\n' "${failed_files[@]}"

    if [[ "$fix_mode" != "true" ]]; then
      log_error ""
      log_error "To fix automatically:"
      log_error "  export FIX_FORMAT=true"
      log_error "  ./scripts/hooks/pre-commit-format.sh"
      log_error ""
      log_error "Or fix manually:"
      log_error "  shfmt -i 2 -bn -ci -sr -w file.sh"
    fi

    return 1
  else
    log_success "✅ All files are properly formatted"
    return 0
  fi
}

# Fix multiple files format
fix_files_format() {
  local files=("$@")

  if [[ ${#files[@]} -eq 0 ]]; then
    log_info "No files to fix"
    return 0
  fi

  local fixed_files=()
  local total_files=${#files[@]}

  log_info "Fixing $total_files bash files"

  for file in "${files[@]}"; do
    if fix_file_format "$file"; then
      fixed_files+=("$file")
    fi
  done

  log_success "✅ Fixed ${#fixed_files[@]} files"
  return 0
}

# Show format diff
show_format_diff() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    log_error "File not found: $file"
    return 1
  fi

  local shfmt_options
  shfmt_options=$(get_shfmt_options)

  local diff_output
  diff_output=$(shfmt $shfmt_options -d "$file" 2>/dev/null || true)

  if [[ -z "$diff_output" ]]; then
    log_info "No formatting differences found in $file"
    return 0
  else
    log_info "Formatting differences in $file:"
    echo "$diff_output"
    return 0
  fi
}

# Get shfmt options
get_shfmt_options() {
  # Use environment variable if set
  if [[ -n "${SHFMT_OPTIONS:-}" ]]; then
    echo "$SHFMT_OPTIONS"
    return 0
  fi

  # Check for .shfmt.toml configuration
  local config_file="$PROJECT_ROOT/.shfmt.toml"
  if [[ -f "$config_file" ]]; then
    echo "--config $config_file"
    return 0
  fi

  # Check for .editorconfig
  if [[ -f "$PROJECT_ROOT/.editorconfig" ]]; then
    # shfmt supports .editorconfig by default
    echo ""
    return 0
  fi

  # Use default options
  echo "$DEFAULT_SHFMT_OPTIONS"
}

# Get format mode
get_format_mode() {
  if [[ "${FIX_FORMAT:-false}" == "true" ]]; then
    echo "fix"
  else
    echo "check"
  fi
}

# Process staged files
process_staged_files() {
  log_info "Processing staged files for format validation"

  local bash_files
  bash_files=$(find_bash_scripts)

  if [[ -z "$bash_files" ]]; then
    log_info "No bash files in staged changes"
    return 0
  fi

  local files_array=()
  while IFS= read -r file; do
    files_array+=("$file")
  done <<< "$bash_files"

  log_info "Checking ${#files_array[@]} bash files"

  check_files_format "${files_array[@]}"
}

# Validate all bash files in repository
validate_all_bash_files() {
  log_info "Validating all bash files in repository"

  local bash_files
  bash_files=$(find "$PROJECT_ROOT" -type f \( -name "*.sh" -o -name "*.bash" -o -name "*.zsh" \) -not -path "*/.git/*" -not -path "*/node_modules/*" -not -path "*/vendor/*" || true)

  if [[ -z "$bash_files" ]]; then
    log_info "No bash files found in repository"
    return 0
  fi

  local files_array=()
  while IFS= read -r file; do
    files_array+=("$file")
  done <<< "$bash_files"

  log_info "Found ${#files_array[@]} bash files"

  check_files_format "${files_array[@]}"
}

# Run format check
run_format_check() {
  local files=("$@")
  local behavior
  behavior=$(get_behavior_mode)

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would check format"
      if [[ ${#files[@]} -gt 0 ]]; then
        echo "Would check: ${files[*]}"
      else
        echo "Would check staged bash files"
      fi
      return 0
      ;;
    "PASS")
      log_success "PASS MODE: Format check simulated successfully"
      return 0
      ;;
    "FAIL")
      log_error "FAIL MODE: Simulating format check failure"
      return 1
      ;;
    "SKIP")
      log_info "SKIP MODE: Format check skipped"
      return 0
      ;;
    "TIMEOUT")
      log_info "TIMEOUT MODE: Simulating format check timeout"
      sleep 5
      return 124
      ;;
  esac

  # EXECUTE mode - Actual format checking
  if [[ ${#files[@]} -eq 0 ]]; then
    process_staged_files
  else
    check_files_format "${files[@]}"
  fi
}

# Generate report
generate_report() {
  local checked_files="${1:-0}"
  local format_duration="${2:-0}"
  local status="${3:-success}"

  # Create pre-commit report directory
  local report_dir="$PROJECT_ROOT/.github/pre-commit-reports"
  mkdir -p "$report_dir"

  local report_file="$report_dir/format-check-$(date +%Y%m%d-%H%M%S).md"

  cat > "$report_file" << EOF
# 📝 Pre-commit Format Check Report

**Generated**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**shfmt Version**: $(get_shfmt_version)
**Files Checked**: $checked_files
**Check Duration**: ${format_duration}s
**Status**: $status

## 📋 Summary

EOF

  if [[ "$status" == "success" ]]; then
    cat >> "$report_file" << EOF
✅ **Pre-commit format check passed**
- All bash scripts are properly formatted
- Safe to proceed with commit

EOF
  else
    cat >> "$report_file" << EOF
❌ **Pre-commit format check failed**
- Some bash scripts need formatting
- Commit blocked for code quality reasons

## 🛠️ Next Steps

1. Review the format issues above
2. Fix formatting automatically with \`shfmt\`
3. Re-stage your changes and commit again

### Auto-fix Options

\`\`\`bash
# Fix all bash files
shfmt -i 2 -bn -ci -sr -w scripts/**/*.sh

# Or use this script with fix mode
FIX_FORMAT=true ./scripts/hooks/pre-commit-format.sh
\`\`\`

## 📚 Resources

- [shfmt Documentation](https://github.com/mvdan/sh)
- [Bash Style Guide](https://google.github.io/styleguide/shellguide.html)

EOF
  fi

  cat >> "$report_file" << EOF

---
*This report was generated by the pre-commit format check hook*
EOF

  log_info "Pre-commit report generated: $report_file"
}

# Main execution
main() {
  local behavior
  behavior=$(get_behavior_mode)

  local start_time
  start_time=$(date +%s)

  log_info "Pre-commit Format Check Hook v$PRE_COMMIT_FORMAT_VERSION"

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would check bash script formatting"
      return 0
      ;;
    "PASS")
      log_success "PASS MODE: Pre-commit format check simulated successfully"
      return 0
      ;;
    "FAIL")
      log_error "FAIL MODE: Simulating pre-commit format check failure"
      return 1
      ;;
    "SKIP")
      log_info "SKIP MODE: Pre-commit format check skipped"
      return 0
      ;;
    "TIMEOUT")
      log_info "TIMEOUT MODE: Simulating pre-commit format check timeout"
      sleep 5
      return 124
      ;;
  esac

  # EXECUTE mode - Actual format checking
  log_info "Starting pre-commit format check"

  # Validate requirements
  if ! check_shfmt_available; then
    exit 1
  fi

  if ! validate_git_repository; then
    exit 1
  fi

  local checked_files=0
  local check_duration=0
  local check_status="success"

  # Get staged bash files
  local bash_files
  bash_files=$(find_bash_scripts)

  if [[ -n "$bash_files" ]]; then
    # Convert to array
    local files_array=()
    while IFS= read -r line; do
      files_array+=("$line")
      checked_files=$((checked_files + 1))
    done <<< "$bash_files"

    log_info "Found $checked_files bash files to check"

    # Run format check
    if ! check_files_format "${files_array[@]}"; then
      check_status="failure"
    fi
  else
    log_info "No bash files to check"
  fi

  # Calculate duration
  local end_time
  end_time=$(date +%s)
  check_duration=$((end_time - start_time))

  # Generate report
  generate_report "$checked_files" "$check_duration" "$check_status"

  if [[ "$check_status" == "success" ]]; then
    log_success "✅ Pre-commit format check completed successfully"
    return 0
  else
    log_error "❌ Pre-commit format check failed"
    return 1
  fi
}

# CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Parse command line arguments
  case "${1:-}" in
    "help"|"--help"|"-h")
      cat << EOF
Pre-commit Format Check Hook v$PRE_COMMIT_FORMAT_VERSION

This hook validates and fixes bash script formatting using shfmt before allowing commits.

Usage:
  Used as a git pre-commit hook via Lefthook configuration

Configuration:
  Add to .lefthook.yml:
    pre-commit:
      commands:
        format:
          run: ./scripts/hooks/pre-commit-format.sh
          tags: [format, style]

Environment Variables:
  PRE_COMMIT_FORMAT_MODE    EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT
  FIX_FORMAT               true/false - Auto-fix formatting issues
  SHFMT_OPTIONS            Custom shfmt options (e.g., "-i 4 -bn")
  CI_TEST_MODE             Global testability mode

Formatting Rules:
- 2 spaces indentation (customizable via SHFMT_OPTIONS)
- Binary operators on next line
- Case statement indentation
- Redirection operators spacing

Examples:
  # Automatic usage via git commit
  git add . && git commit -m "Add feature"

  # Manual checking
  ./scripts/hooks/pre-commit-format.sh

  # Fix formatting issues
  FIX_FORMAT=true ./scripts/hooks/pre-commit-format.sh

  # Check specific files
  ./scripts/hooks/pre-commit-format.sh script1.sh script2.sh

  # Show diff for a file
  ./scripts/hooks/pre-commit-format.sh diff script.sh

Testability:
  CI_TEST_MODE=DRY_RUN ./scripts/hooks/pre-commit-format.sh
  PRE_COMMIT_FORMAT_MODE=FAIL ./scripts/hooks/pre-commit-format.sh

Integration:
  This hook integrates with:
  - Lefthook for pre-commit hook management
  - ShellSpec for testing hook behavior
  - shfmt for bash code formatting
  - GitHub Actions for CI pipeline style checking
EOF
      exit 0
      ;;
    "check")
      # Check mode
      if [[ $# -lt 2 ]]; then
        echo "Usage: $0 check <file1> [file2] ..."
        exit 1
      fi
      shift
      run_format_check "$@"
      exit $?
      ;;
    "fix")
      # Fix mode
      export FIX_FORMAT=true
      if [[ $# -lt 2 ]]; then
        echo "Usage: $0 fix <file1> [file2] ..."
        exit 1
      fi
      shift
      fix_files_format "$@"
      exit $?
      ;;
    "diff")
      # Show diff mode
      if [[ $# -ne 2 ]]; then
        echo "Usage: $0 diff <file>"
        exit 1
      fi
      shift
      show_format_diff "$1"
      exit $?
      ;;
    "validate")
      # Validation mode for testing
      echo "Validating pre-commit hook setup..."
      check_shfmt_available
      validate_git_repository
      echo "✅ Pre-commit hook validation completed"
      ;;
    *)
      main "$@"
      ;;
  esac
fi