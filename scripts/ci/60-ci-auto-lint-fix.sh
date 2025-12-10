#!/bin/bash
# CI Auto-Lint-Fix Script
# Automatically fixes ShellCheck linting issues and commits fixes

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common utilities" >&2
  exit 1
}

# Configuration
readonly AUTO_LINT_FIX_VERSION="1.0.0"

# ShellCheck severity levels
SEVERITY_ERROR="error"
SEVERITY_WARNING="warning"
SEVERITY_INFO="info"
SEVERITY_STYLE="style"

# Testability configuration
get_behavior_mode() {
  local script_name="ci_auto_lint_fix"
  get_script_behavior "$script_name" "EXECUTE"
}

# Check if ShellCheck is available
check_shellcheck_available() {
  if ! command -v shellcheck >/dev/null 2>&1; then
    log_error "❌ ShellCheck is not installed"
    return 1
  fi

  log_debug "ShellCheck is available"
  return 0
}

# Validate git repository
validate_git_repository() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    log_error "❌ Not in a git repository"
    return 1
  fi

  return 0
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
    options+=($SHELLCHECK_OPTIONS)
  fi

  # Check for .shellcheckrc configuration
  if [[ -f "$PROJECT_ROOT/.shellcheckrc" ]]; then
    options+=("--config-file=$PROJECT_ROOT/.shellcheckrc")
  fi

  echo "${options[*]}"
}

# Find all bash files in repository
find_bash_files() {
  local scope="${1:-all}"

  case "$scope" in
    "staged")
      # Get staged files only
      git diff --cached --name-only --diff-filter=ACM | grep -E '\.(sh|bash|zsh)$' || true
      return 0
      ;;
    "modified")
      # Get modified files
      git diff --name-only --diff-filter=AM | grep -E '\.(sh|bash|zsh)$' || true
      return 0
      ;;
    "all"|*)
      # Find all bash files
      find "$PROJECT_ROOT" -type f \
        "(" -name "*.sh" -o -name "*.bash" -o -name "*.zsh" ")" \
        -not -path "*/.git/*" \
        -not -path "*/node_modules/*" \
        -not -path "*/vendor/*" \
        -not -path "*/target/*" \
        -not -path "*/build/*" \
        -not -path "*/dist/*" \
        2>/dev/null || true
      ;;
  esac
}

# Check if file has linting issues
check_file_has_lint_issues() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    return 1
  fi

  local shellcheck_options
  shellcheck_options=$(get_shellcheck_options)

  # Run ShellCheck
  local lint_output
  lint_output=$(shellcheck $shellcheck_options "$file" 2>&1 || true)

  if [[ -n "$lint_output" ]]; then
    return 0
  else
    return 1
  fi
}

# Generate lint fixes for file
generate_file_lint_fixes() {
  local file="$1"
  local auto_apply="${2:-false}"

  if [[ ! -f "$file" ]]; then
    log_error "File not found: $file"
    return 1
  fi

  # Check if file has issues
  if ! check_file_has_lint_issues "$file"; then
    log_debug "✓ $file has no lint issues"
    return 0
  fi

  local shellcheck_options
  shellcheck_options=$(get_shellcheck_options)

  # Generate diff for fixes
  local diff_output
  diff_output=$(shellcheck -f diff $shellcheck_options "$file" 2>/dev/null || true)

  if [[ -z "$diff_output" ]]; then
    log_info "ℹ️ $file has lint issues but no automatic fixes available"
    return 0
  fi

  local patch_file="$file.lint.patch"
  echo "$diff_output" > "$patch_file"

  if [[ "$auto_apply" == "true" ]]; then
    # Apply patch
    if patch -p1 < "$patch_file" 2>/dev/null; then
      log_success "✓ Applied fixes to $file"
      rm -f "$patch_file"
      return 0
    else
      log_warn "⚠️ Failed to apply fixes to $file"
      log_info "Patch file saved: $patch_file"
      return 1
    fi
  else
    log_info "🔧 Generated fix patch: $patch_file"
    return 0
  fi
}

# Apply lint fixes to multiple files
apply_lint_fixes() {
  local files=("$@")
  local auto_apply="${AUTO_APPLY_FIXES:-true}"
  local dry_run="${DRY_RUN:-false}"

  if [[ ${#files[@]} -eq 0 ]]; then
    log_info "No files to fix"
    return 0
  fi

  local files_fixed=()
  local files_failed=()
  local files_no_fixes=()

  log_info "Applying lint fixes to ${#files[@]} bash files"

  for file in "${files[@]}"; do
    if [[ "$dry_run" == "true" ]]; then
      if check_file_has_lint_issues "$file"; then
        log_info "🔍 Would fix: $file"
        files_fixed+=("$file")
      fi
      continue
    fi

    if generate_file_lint_fixes "$file" "$auto_apply"; then
      if check_file_has_lint_issues "$file"; then
        # Still has issues (no fixes available)
        files_no_fixes+=("$file")
      else
        # Fixed successfully
        files_fixed+=("$file")
      fi
    else
      files_failed+=("$file")
    fi
  done

  # Report results
  log_success "✅ Successfully fixed ${#files_fixed[@]} files"

  if [[ ${#files_no_fixes[@]} -gt 0 ]]; then
    log_info "ℹ️ ${#files_no_fixes[@]} files have issues requiring manual fixes:"
    printf '  %s\n' "${files_no_fixes[@]}"
  fi

  if [[ ${#files_failed[@]} -gt 0 ]]; then
    log_error "❌ Failed to fix ${#files_failed[@]} files:"
    printf '  %s\n' "${files_failed[@]}"
    return 1
  fi

  return 0
}

# Get detailed lint report for file
get_file_lint_report() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    return 1
  fi

  local shellcheck_options
  shellcheck_options=$(get_shellcheck_options)

  # Run ShellCheck
  local lint_output
  lint_output=$(shellcheck $shellcheck_options "$file" 2>&1 || true)

  if [[ -z "$lint_output" ]]; then
    return 1
  fi

  echo "$lint_output"
}

# Generate comprehensive lint report
generate_lint_report() {
  local files_checked="${1:-0}"
  local files_fixed="${2:-0}"
  local files_failed="${3:-0}"
  local files_no_fixes="${4:-0}"
  local lint_duration="${5:-0}"
  local status="${6:-success}"

  # Create CI report directory
  local report_dir="$PROJECT_ROOT/.github/reports"
  mkdir -p "$report_dir"

  local report_file="$report_dir/auto-lint-fix-$(date +%Y%m%d-%H%M%S).md"

  cat > "$report_file" << EOF
# 🔧 Auto-Lint-Fix Report

**Generated**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**ShellCheck Version**: $(shellcheck --version 2>/dev/null | grep "version" | head -n1 || echo "unknown")
**Files Checked**: $files_checked
**Files Fixed**: $files_fixed
**Files Failed**: $files_failed
**Files No Auto-Fix**: $files_no_fixes
**Duration**: ${lint_duration}s
**Status**: $status

## 📊 Summary

EOF

  if [[ "$status" == "success" && $files_failed -eq 0 ]]; then
    cat >> "$report_file" << EOF
✅ **Auto-lint-fix completed successfully**
- $files_fixed files were automatically fixed
- $files_no_fixes files have issues requiring manual intervention
- Changes committed to repository

EOF
  else
    cat >> "$report_file" << EOF
⚠️ **Auto-lint-fix completed with issues**
- $files_fixed files were successfully fixed
- $files_failed files failed to process
- $files_no_fixes files need manual fixes

## ❌ Failed Files

The following files could not be processed automatically:
EOF

    if [[ $files_failed -gt 0 ]]; then
      echo "- Check the CI logs for specific file names and error messages" >> "$report_file"
    fi

    cat >> "$report_file" << EOF

## 🔧 Manual Fix Required

Files with no automatic fixes available:
EOF

    if [[ $files_no_fixes -gt 0 ]]; then
      echo "- These files contain issues that require manual intervention" >> "$report_file"
      echo "- Review ShellCheck output for specific guidance" >> "$report_file"
    fi

    cat >> "$report_file" << EOF

### Manual Fix Process

1. **Review ShellCheck output**:
   \`\`\`bash
   shellcheck --severity=warning path/to/file.sh
   \`\`\`

2. **Apply common fixes**:
   - Quote variables: \`echo "\$VAR"\`
   - Use \[[ ... ]] for tests
   - Add error handling: \`set -euo pipefail\`
   - Use local variables in functions

3. **Fix manually and re-run**:
   \`\`\`bash
   # Apply fixes manually
   # Re-run auto-lint-fix to verify
   ./scripts/ci/60-ci-auto-lint-fix.sh
   \`\`\`

EOF
  fi

  cat >> "$report_file" << EOF

## 📚 Resources

- [ShellCheck Wiki](https://github.com/koalaman/shellcheck/wiki)
- [ShellCheck Rules](https://github.com/koalaman/shellcheck/wiki/Checks)
- [Bash Best Practices](https://google.github.io/styleguide/shellguide.html)

### Common ShellCheck Fixes

| Issue Code | Description | Fix |
|------------|-------------|-----|
| SC2086 | Double quote to prevent globbing | Use \`"\$VAR"\` instead of \`$VAR\` |
| SC2046 | Quote to prevent word splitting | Use \`"\$(cmd)"\` instead of \`\$(cmd)\` |
| SC2162 | Read without -r | Use \`read -r\` |
| SC2034 | Unused variable | Remove or prefix with \`_\` |
| SC2155 | Declare and assign separately | Use \`local var; var=\$(cmd)\` |

---
*This report was generated by the CI auto-lint-fix workflow*
EOF

  log_success "Auto-lint-fix report generated: $report_file"
  echo "::set-output name=report_file::$report_file"
}

# Get commit message for lint fixes
get_commit_message() {
  local files_fixed="${1:-0}"
  local files_no_fixes="${2:-0}"
  local branch_name
  branch_name=$(git branch --show-current 2>/dev/null || echo "unknown")

  cat << EOF
auto: fix shellcheck linting issues

- Fixed ShellCheck issues in $files_fixed bash script files
- $files_no_fixes files have issues requiring manual fixes
- Auto-generated commit by CI auto-lint-fix workflow

CI_AUTO_LINT_FIX_SHA: $(git rev-parse HEAD 2>/dev/null || echo "unknown")
Branch: $branch_name
EOF
}

# Commit lint fixes
commit_lint_fixes() {
  local files_fixed="${1:-0}"
  local files_no_fixes="${2:-0}"

  if [[ $files_fixed -eq 0 ]]; then
    log_info "No lint fixes to commit"
    return 0
  fi

  # Check if there are changes to commit
  if git diff --quiet; then
    log_info "No changes detected after lint fixes"
    return 0
  fi

  # Add fixed files
  git add -A

  # Check if there are staged changes
  if git diff --cached --quiet; then
    log_info "No staged changes after lint fixes"
    return 0
  fi

  # Get commit message
  local commit_message
  commit_message=$(get_commit_message "$files_fixed" "$files_no_fixes")

  # Commit changes
  if git commit -m "$commit_message"; then
    log_success "✅ Committed lint fixes"
    return 0
  else
    log_error "❌ Failed to commit lint fixes"
    return 1
  fi
}

# Run auto-lint-fix workflow
run_auto_lint_fix() {
  local scope="${1:-all}"
  local auto_commit="${AUTO_COMMIT:-true}"
  local behavior
  behavior=$(get_behavior_mode)

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would auto-fix ShellCheck linting issues"
      echo "Scope: $scope"
      echo "Auto-commit: $auto_commit"
      return 0
      ;;
    "PASS")
      log_success "PASS MODE: Auto-lint-fix simulated successfully"
      return 0
      ;;
    "FAIL")
      log_error "FAIL MODE: Simulating auto-lint-fix failure"
      return 1
      ;;
    "SKIP")
      log_info "SKIP MODE: Auto-lint-fix skipped"
      return 0
      ;;
    "TIMEOUT")
      log_info "TIMEOUT MODE: Simulating auto-lint-fix timeout"
      sleep 5
      return 124
      ;;
  esac

  # EXECUTE mode - Actual auto-lint-fixing
  log_info "Starting auto-lint-fix workflow"
  log_info "Scope: $scope"
  log_info "Auto-commit: $auto_commit"

  local start_time
  start_time=$(date +%s)

  # Validate requirements
  if ! check_shellcheck_available; then
    exit 1
  fi

  if ! validate_git_repository; then
    exit 1
  fi

  # Get files to check
  local files_to_check
  mapfile -t files_to_check < <(find_bash_files "$scope")

  if [[ ${#files_to_check[@]} -eq 0 ]]; then
    log_info "No bash files found for scope: $scope"
    generate_lint_report "0" "0" "0" "0" "0" "success"
    return 0
  fi

  log_info "Found ${#files_to_check[@]} bash files to check"

  # Filter files that have lint issues
  local files_with_issues=()
  for file in "${files_to_check[@]}"; do
    if check_file_has_lint_issues "$file"; then
      files_with_issues+=("$file")
    fi
  done

  if [[ ${#files_with_issues[@]} -eq 0 ]]; then
    log_info "All bash files passed ShellCheck validation"
    generate_lint_report "${#files_to_check[@]}" "0" "0" "0" "0" "success"
    return 0
  fi

  log_info "Found ${#files_with_issues[@]} files with lint issues"

  # Apply fixes
  local lint_success=true
  local files_fixed=0
  local files_failed=0
  local files_no_fixes=0

  for file in "${files_with_issues[@]}"; do
    if generate_file_lint_fixes "$file" "true"; then
      if check_file_has_lint_issues "$file"; then
        # Still has issues (no fixes available)
        files_no_fixes=$((files_no_fixes + 1))
      else
        # Fixed successfully
        files_fixed=$((files_fixed + 1))
      fi
    else
      files_failed=$((files_failed + 1))
      lint_success=false
    fi
  done

  # Commit changes if requested
  if [[ "$auto_commit" == "true" ]]; then
    if ! commit_lint_fixes "$files_fixed" "$files_no_fixes"; then
      lint_success=false
    fi
  fi

  # Calculate duration
  local end_time
  end_time=$(date +%s)
  local lint_duration=$((end_time - start_time))

  # Generate report
  local final_status="success"
  if [[ "$lint_success" != "true" ]]; then
    final_status="failure"
  fi

  generate_lint_report "${#files_to_check[@]}" "$files_fixed" "$files_failed" "$files_no_fixes" "$lint_duration" "$final_status"

  if [[ "$lint_success" == "true" ]]; then
    log_success "✅ Auto-lint-fix workflow completed successfully"
    return 0
  else
    log_error "❌ Auto-lint-fix workflow completed with errors"
    return 1
  fi
}

# Main execution
main() {
  local scope="${1:-all}"
  local behavior
  behavior=$(get_behavior_mode)

  log_info "CI Auto-Lint-Fix Script v$AUTO_LINT_FIX_VERSION"

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would auto-fix ShellCheck linting issues"
      return 0
      ;;
    "PASS")
      log_success "PASS MODE: Auto-lint-fix simulated successfully"
      return 0
      ;;
    "FAIL")
      log_error "FAIL MODE: Simulating auto-lint-fix failure"
      return 1
      ;;
    "SKIP")
      log_info "SKIP MODE: Auto-lint-fix skipped"
      return 0
      ;;
    "TIMEOUT")
      log_info "TIMEOUT MODE: Simulating auto-lint-fix timeout"
      sleep 5
      return 124
      ;;
  esac

  run_auto_lint_fix "$scope"
}

# CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Parse command line arguments
  case "${1:-}" in
    "help"|"--help"|"-h")
      cat << EOF
CI Auto-Lint-Fix Script v$AUTO_LINT_FIX_VERSION

Automatically fixes ShellCheck linting issues in bash scripts and commits fixes.

Usage:
  ./scripts/ci/60-ci-auto-lint-fix.sh [scope]

Scopes:
  all      - Fix all bash files in repository (default)
  staged   - Fix only staged files
  modified - Fix only modified files

Environment Variables:
  CI_AUTO_LINT_FIX_MODE    EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT
  AUTO_COMMIT            true/false - Commit fixes automatically (default: true)
  AUTO_APPLY_FIXES       true/false - Apply fixes automatically (default: true)
  SHELLCHECK_SEVERITY    error, warning, info, style (default: warning)
  SHELLCHECK_SHELL       bash, sh, zsh (default: bash)
  SHELLCHECK_OPTIONS     Additional ShellCheck options
  CI_TEST_MODE           Global testability mode

Examples:
  # Fix all bash files
  ./scripts/ci/60-ci-auto-lint-fix.sh all

  # Fix only staged files
  ./scripts/ci/60-ci-auto-lint-fix.sh staged

  # Check what would be fixed without applying
  AUTO_APPLY_FIXES=false ./scripts/ci/60-ci-auto-lint-fix.sh all

  # Generate patches without applying
  DRY_RUN=true ./scripts/ci/60-ci-auto-lint-fix.sh all

GitHub Actions Integration:
  This script is designed to run in GitHub Actions workflows:
  - Automatically triggered on push/PR
  - Applies automatic fixes and commits back to repository
  - Generates detailed reports for manual fixes
  - Supports testability modes

Testability:
  CI_TEST_MODE=DRY_RUN ./scripts/ci/60-ci-auto-lint-fix.sh
  CI_AUTO_LINT_FIX_MODE=FAIL ./scripts/ci/60-ci-auto-lint-fix.sh

Integration:
  This script integrates with:
  - GitHub Actions workflows
  - ShellCheck for bash static analysis
  - Patch system for automatic fixes
  - Git for version control and automatic commits
EOF
      exit 0
      ;;
    "validate")
      # Validation mode
      echo "Validating auto-lint-fix setup..."
      check_shellcheck_available
      validate_git_repository
      echo "✅ Auto-lint-fix validation completed"
      ;;
    "check")
      # Check mode - just check what has issues
      DRY_RUN=true
      run_auto_lint_fix "${2:-all}"
      ;;
    "report")
      # Generate detailed report for specific files
      if [[ $# -lt 2 ]]; then
        echo "Usage: $0 report <file1> [file2] ..."
        exit 1
      fi
      shift
      for file in "$@"; do
        echo "### $(basename "$file")"
        get_file_lint_report "$file" || echo "No issues found"
        echo ""
      done
      ;;
    *)
      main "$@"
      ;;
  esac
fi