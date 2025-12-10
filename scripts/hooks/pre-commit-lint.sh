#!/bin/bash
# Pre-commit Lint Hook
# Validates bash script linting using ShellCheck before allowing commits

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common utilities" >&2
  exit 1
}

# Configuration
readonly PRE_COMMIT_LINT_VERSION="1.0.0"

# ShellCheck severity levels
SEVERITY_ERROR="error"
SEVERITY_WARNING="warning"
SEVERITY_INFO="info"
SEVERITY_STYLE="style"

# Default ShellCheck options
DEFAULT_SHELLCHECK_OPTIONS="--severity=warning"

# Testability configuration
get_behavior_mode() {
  local script_name="pre_commit_lint"
  get_script_behavior "$script_name" "EXECUTE"
}

# Check if ShellCheck is available
check_shellcheck_available() {
  if ! command -v shellcheck >/dev/null 2>&1; then
    log_error "❌ ShellCheck is not installed"
    log_error "Install ShellCheck: https://github.com/koalaman/shellcheck"
    log_error "Or disable this hook by removing it from .lefthook.yml"
    return 1
  fi

  log_debug "ShellCheck is available"
  return 0
}

# Get ShellCheck version
get_shellcheck_version() {
  shellcheck --version 2>/dev/null | grep "version" | head -n1 || echo "unknown"
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
  done <<<"$staged_files"

  if [[ ${#bash_files[@]} -eq 0 ]]; then
    return 0
  fi

  printf '%s\n' "${bash_files[@]}"
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

# Check single file with ShellCheck
check_file_lint() {
  local file="$1"
  local suggestions_only="${2:-false}"

  if [[ ! -f "$file" ]]; then
    log_error "File not found: $file"
    return 1
  fi

  local shellcheck_options
  shellcheck_options=$(get_shellcheck_options)

  # Run ShellCheck
  local lint_output
  lint_output=$(shellcheck $shellcheck_options "$file" 2>&1 || true)

  if [[ -z "$lint_output" ]]; then
    log_success "✓ $file passed lint check"
    return 0
  else
    if [[ "$suggestions_only" == "true" ]]; then
      log_info "ℹ️ Lint suggestions for $file:"
      echo "$lint_output" | sed 's/^/  /'
      return 0
    else
      log_error "✗ $file has lint issues:"
      echo "$lint_output" | sed 's/^/  /'
      return 1
    fi
  fi
}

# Get ShellCheck options
get_shellcheck_options() {
  local options=()

  # Add severity level
  local severity="${SHELLCHECK_SEVERITY:-warning}"
  options+=("--severity=$severity")

  # Add shell type detection
  if [[ "${SHELLCHECK_SHELL:-}" ]]; then
    options+=("--shell=${SHELLCHECK_SHELL}")
  else
    options+=("--shell=bash")
  fi

  # Add source paths for includes
  if [[ -d "$PROJECT_ROOT/scripts" ]]; then
    options+=("--source-path=$PROJECT_ROOT/scripts")
  fi

  # Add custom options from environment
  if [[ -n "${SHELLCHECK_OPTIONS:-}" ]]; then
    # Split options robustly to avoid word splitting
    while IFS= read -r -d '' option; do
      options+=("$option")
    done < <(printf '%s\0' "$SHELLCHECK_OPTIONS")
  fi

  # Check for .shellcheckrc configuration
  # Note: Temporarily disabled due to parsing issues
  # if [[ -f "$PROJECT_ROOT/.shellcheckrc" ]]; then
  #   options+=("--rcfile=$PROJECT_ROOT/.shellcheckrc")
  # fi

  echo "${options[*]}"
}

# Check multiple files with ShellCheck
check_files_lint() {
  local files=("$@")
  local suggestions_only="${SUGGESTIONS_ONLY:-false}"

  if [[ ${#files[@]} -eq 0 ]]; then
    log_info "No files to check"
    return 0
  fi

  local failed_files=()
  local total_files=${#files[@]}
  local total_issues=0

  log_info "Checking $total_files bash files for lint issues"

  for file in "${files[@]}"; do
    if ! check_file_lint "$file" "$suggestions_only"; then
      failed_files+=("$file")
      # Count issues (rough estimate)
      local issue_count
      issue_count=$(shellcheck $(get_shellcheck_options) "$file" 2>&1 | wc -l | tr -dc '0-9')
      total_issues=$((total_issues + issue_count))
    fi
  done

  if [[ ${#failed_files[@]} -gt 0 ]]; then
    log_error "❌ ${#failed_files[@]} files have lint issues ($total_issues total issues)"
    log_error "Files requiring fixes:"
    printf '  %s\n' "${failed_files[@]}"

    log_error ""
    log_error "To see suggestions:"
    log_error "  export SUGGESTIONS_ONLY=true"
    log_error "  ./scripts/hooks/pre-commit-lint.sh"

    log_error ""
    log_error "To fix automatically (where possible):"
    log_error "  shellcheck -f diff file.sh | git apply -"

    return 1
  else
    log_success "✅ All files passed lint check"
    return 0
  fi
}

# Generate lint fixes
generate_lint_fixes() {
  local files=("$@")

  if [[ ${#files[@]} -eq 0 ]]; then
    log_info "No files to generate fixes for"
    return 0
  fi

  local fixed_files=()

  log_info "Generating lint fixes for ${#files[@]} files"

  for file in "${files[@]}"; do
    if [[ ! -f "$file" ]]; then
      log_warn "Skipping non-existent file: $file"
      continue
    fi

    # Generate diff for fixes
    local diff_output
    diff_output=$(shellcheck -f diff $(get_shellcheck_options) "$file" 2>/dev/null || true)

    if [[ -n "$diff_output" ]]; then
      local patch_file="$file.lint.patch"
      echo "$diff_output" >"$patch_file"
      log_info "Generated fix patch: $patch_file"

      # Apply patch automatically if requested
      if [[ "${AUTO_APPLY_FIXES:-false}" == "true" ]]; then
        if patch -p1 <"$patch_file" 2>/dev/null; then
          log_success "✓ Applied fixes to $file"
          rm -f "$patch_file"
          fixed_files+=("$file")
        else
          log_warn "⚠️ Failed to apply fixes to $file"
        fi
      else
        fixed_files+=("$file")
      fi
    else
      log_info "No fixes needed for $file"
    fi
  done

  if [[ ${#fixed_files[@]} -gt 0 ]]; then
    log_info ""
    log_info "Fixes generated for ${#fixed_files[@]} files:"
    printf '  %s\n' "${fixed_files[@]}"

    if [[ "${AUTO_APPLY_FIXES:-false}" != "true" ]]; then
      log_info ""
      log_info "To apply fixes automatically:"
      log_info "  export AUTO_APPLY_FIXES=true"
      log_info "  ./scripts/hooks/pre-commit-lint.sh fix"
      log_info ""
      log_info "Or apply manually:"
      log_info "  patch -p1 < file.lint.patch"
    fi
  fi

  return 0
}

# Process staged files
process_staged_files() {
  log_info "Processing staged files for lint validation"

  local bash_files
  bash_files=$(find_bash_scripts)

  if [[ -z "$bash_files" ]]; then
    log_info "No bash files in staged changes"
    return 0
  fi

  local files_array=()
  while IFS= read -r file; do
    files_array+=("$file")
  done <<<"$bash_files"

  log_info "Checking ${#files_array[@]} bash files"

  check_files_lint "${files_array[@]}"
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
  done <<<"$bash_files"

  log_info "Found ${#files_array[@]} bash files"

  check_files_lint "${files_array[@]}"
}

# Run lint check
run_lint_check() {
  local files=("$@")
  local behavior
  behavior=$(get_behavior_mode)

  case "$behavior" in
  "DRY_RUN")
    echo "🔍 DRY RUN: Would check lint"
    if [[ ${#files[@]} -gt 0 ]]; then
      echo "Would check: ${files[*]}"
    else
      echo "Would check staged bash files"
    fi
    return 0
    ;;
  "PASS")
    log_success "PASS MODE: Lint check simulated successfully"
    return 0
    ;;
  "FAIL")
    log_error "FAIL MODE: Simulating lint check failure"
    return 1
    ;;
  "SKIP")
    log_info "SKIP MODE: Lint check skipped"
    return 0
    ;;
  "TIMEOUT")
    log_info "TIMEOUT MODE: Simulating lint check timeout"
    sleep 5
    return 124
    ;;
  esac

  # EXECUTE mode - Actual lint checking
  if [[ ${#files[@]} -eq 0 ]]; then
    process_staged_files
  else
    check_files_lint "${files[@]}"
  fi
}

# Generate lint report
generate_lint_report() {
  local files=("$@")
  local output_file="${1:-}"

  if [[ ${#files[@]} -eq 0 ]]; then
    log_info "No files to generate report for"
    return 0
  fi

  local report_file="$output_file"
  if [[ -z "$report_file" ]]; then
    report_file="$PROJECT_ROOT/.github/reports/lint-report-$(date +%Y%m%d-%H%M%S).md"
  fi

  # Create report directory
  mkdir -p "$(dirname "$report_file")"

  cat >"$report_file" <<EOF
# 🔍 ShellCheck Lint Report

**Generated**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**ShellCheck Version**: $(get_shellcheck_version)
**Files Checked**: ${#files[@]}
**Severity Level**: ${SHELLCHECK_SEVERITY:-warning}

## 📊 Lint Results

EOF

  local total_issues=0
  local file_issues

  for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
      local lint_output
      lint_output=$(shellcheck $(get_shellcheck_options) "$file" 2>&1 || true)

      if [[ -n "$lint_output" ]]; then
        echo "### $(basename "$file")" >>"$report_file"
        echo '```' >>"$report_file"
        echo "$lint_output" >>"$report_file"
        echo '```' >>"$report_file"
        echo "" >>"$report_file"

        local file_issues
        file_issues=$(wc -l <<<"$lint_output" | tr -dc '0-9')
        total_issues=$((total_issues + file_issues))
      fi
    fi
  done

  if [[ $total_issues -eq 0 ]]; then
    echo "✅ **All files passed lint check**" >>"$report_file"
  else
    echo "❌ **$total_issues lint issues found**" >>"$report_file"
  fi

  cat >>"$report_file" <<EOF

## 🛠️ Fix Options

1. **Manual fixes**: Review each issue and fix manually
2. **Automatic fixes**: Use \`shellcheck -f diff\` to generate patches
3. **IDE integration**: Use ShellCheck plugins for your editor

### Apply Automatic Fixes

\`\`\`bash
# Generate and apply fixes for all files
for file in scripts/**/*.sh; do
  shellcheck -f diff "\$file" | patch "\$file"
done
\`\`\`

## 📚 Resources

- [ShellCheck Wiki](https://github.com/koalaman/shellcheck/wiki)
- [ShellCheck Rules](https://github.com/koalaman/shellcheck/wiki/Checks)
- [Bash Best Practices](https://google.github.io/styleguide/shellguide.html)

---
*This report was generated by ShellCheck*
EOF

  log_success "Lint report generated: $report_file"
  return 0
}

# Generate report
generate_report() {
  local checked_files="${1:-0}"
  local lint_duration="${2:-0}"
  local status="${3:-success}"

  # Create pre-commit report directory
  local report_dir="$PROJECT_ROOT/.github/pre-commit-reports"
  mkdir -p "$report_dir"

  local report_file
  report_file="$report_dir/lint-check-$(date +%Y%m%d-%H%M%S).md"

  cat >"$report_file" <<EOF
# 🔍 Pre-commit Lint Check Report

**Generated**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**ShellCheck Version**: $(get_shellcheck_version)
**Files Checked**: $checked_files
**Check Duration**: ${lint_duration}s
**Status**: $status

## 📋 Summary

EOF

  if [[ "$status" == "success" ]]; then
    cat >>"$report_file" <<EOF
✅ **Pre-commit lint check passed**
- All bash scripts passed ShellCheck validation
- Safe to proceed with commit

EOF
  else
    cat >>"$report_file" <<EOF
❌ **Pre-commit lint check failed**
- Some bash scripts have lint issues
- Commit blocked for code quality reasons

## 🛠️ Next Steps

1. Review the ShellCheck output above for specific issues
2. Fix lint issues manually or using automated tools
3. Re-stage your changes and commit again

### Common Issues and Fixes

\`\`\`bash
# Generate and apply fixes
shellcheck -f diff script.sh | patch script.sh

# Check specific rules
shellcheck -o all script.sh

# Set different shell
shellcheck --shell=bash script.sh
\`\`\`

## 📚 Resources

- [ShellCheck Documentation](https://github.com/koalaman/shellcheck)
- [Bash Style Guide](https://google.github.io/styleguide/shellguide.html)

EOF
  fi

  cat >>"$report_file" <<EOF

---
*This report was generated by the pre-commit lint check hook*
EOF

  log_info "Pre-commit report generated: $report_file"
}

# Main execution
main() {
  local behavior
  behavior=$(get_behavior_mode)

  local start_time
  start_time=$(date +%s)

  log_info "Pre-commit Lint Check Hook v$PRE_COMMIT_LINT_VERSION"

  case "$behavior" in
  "DRY_RUN")
    echo "🔍 DRY RUN: Would check bash script linting"
    return 0
    ;;
  "PASS")
    log_success "PASS MODE: Pre-commit lint check simulated successfully"
    return 0
    ;;
  "FAIL")
    log_error "FAIL MODE: Simulating pre-commit lint check failure"
    return 1
    ;;
  "SKIP")
    log_info "SKIP MODE: Pre-commit lint check skipped"
    return 0
    ;;
  "TIMEOUT")
    log_info "TIMEOUT MODE: Simulating pre-commit lint check timeout"
    sleep 5
    return 124
    ;;
  esac

  # EXECUTE mode - Actual lint checking
  log_info "Starting pre-commit lint check"

  # Validate requirements
  if ! check_shellcheck_available; then
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
    done <<<"$bash_files"

    log_info "Found $checked_files bash files to check"

    # Run lint check
    if ! check_files_lint "${files_array[@]}"; then
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
    log_success "✅ Pre-commit lint check completed successfully"
    return 0
  else
    log_error "❌ Pre-commit lint check failed"
    return 1
  fi
}

# CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Parse command line arguments
  case "${1:-}" in
  "help" | "--help" | "-h")
    cat <<EOF
Pre-commit Lint Check Hook v$PRE_COMMIT_LINT_VERSION

This hook validates bash script linting using ShellCheck before allowing commits.

Usage:
  Used as a git pre-commit hook via Lefthook configuration

Configuration:
  Add to .lefthook.yml:
    pre-commit:
      commands:
        lint:
          run: ./scripts/hooks/pre-commit-lint.sh
          tags: [lint, quality]

Environment Variables:
  PRE_COMMIT_LINT_MODE      EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT
  SHELLCHECK_SEVERITY       error, warning, info, style (default: warning)
  SHELLCHECK_SHELL          bash, sh, zsh (default: bash)
  SHELLCHECK_OPTIONS        Additional ShellCheck options
  SUGGESTIONS_ONLY          true/false - Show suggestions only
  AUTO_APPLY_FIXES          true/false - Apply fixes automatically
  CI_TEST_MODE              Global testability mode

Linting Rules:
- POSIX compliance and bash best practices
- Error handling and variable quoting
- Security vulnerability detection
- Performance optimization suggestions
- Code style and consistency

Examples:
  # Automatic usage via git commit
  git add . && git commit -m "Add feature"

  # Manual checking
  ./scripts/hooks/pre-commit-lint.sh

  # Check with info severity
  SHELLCHECK_SEVERITY=info ./scripts/hooks/pre-commit-lint.sh

  # Generate fix patches
  ./scripts/hooks/pre-commit-lint.sh fix

  # Apply fixes automatically
  AUTO_APPLY_FIXES=true ./scripts/hooks/pre-commit-lint.sh fix

  # Generate detailed report
  ./scripts/hooks/pre-commit-lint.sh report scripts/**/*.sh

Testability:
  CI_TEST_MODE=DRY_RUN ./scripts/hooks/pre-commit-lint.sh
  PRE_COMMIT_LINT_MODE=FAIL ./scripts/hooks/pre-commit-lint.sh

Integration:
  This hook integrates with:
  - Lefthook for pre-commit hook management
  - ShellSpec for testing hook behavior
  - ShellCheck for bash static analysis
  - GitHub Actions for CI pipeline linting
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
    run_lint_check "$@"
    exit $?
    ;;
  "fix")
    # Fix mode
    if [[ $# -lt 2 ]]; then
      echo "Usage: $0 fix <file1> [file2] ..."
      exit 1
    fi
    shift
    generate_lint_fixes "$@"
    exit $?
    ;;
  "report")
    # Report mode
    if [[ $# -lt 2 ]]; then
      echo "Usage: $0 report <file1> [file2] ..."
      exit 1
    fi
    shift
    generate_lint_report "" "$@"
    exit $?
    ;;
  "validate")
    # Validation mode for testing
    echo "Validating pre-commit hook setup..."
    check_shellcheck_available
    validate_git_repository
    echo "✅ Pre-commit hook validation completed"
    ;;
  *)
    main "$@"
    ;;
  esac
fi
