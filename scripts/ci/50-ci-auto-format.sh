#!/bin/bash
# CI Auto-Format Script
# Automatically formats bash scripts using shfmt and commits fixes

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common utilities" >&2
  exit 1
}

# Configuration
readonly AUTO_FORMAT_VERSION="1.0.0"

# Default shfmt options
DEFAULT_SHFMT_OPTIONS="-i 2 -bn -ci -sr"

# Testability configuration
get_behavior_mode() {
  local script_name="ci_auto_format"
  get_script_behavior "$script_name" "EXECUTE"
}

# Check if shfmt is available
check_shfmt_available() {
  if ! command -v shfmt >/dev/null 2>&1; then
    log_error "❌ shfmt is not installed"
    return 1
  fi

  log_debug "shfmt is available"
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

# Find all bash files in repository
find_bash_files() {
  local scope="${1:-all}"

  local find_cmd=(find "$PROJECT_ROOT" -type f)

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
      find_cmd+=(
        "("
        "-name" "*.sh"
        "-o" "-name" "*.bash"
        "-o" "-name" "*.zsh"
        ")"
        "-not" "-path" "*/.git/*"
        "-not" "-path" "*/node_modules/*"
        "-not" "-path" "*/vendor/*"
        "-not" "-path" "*/target/*"
        "-not" "-path" "*/build/*"
        "-not" "-path" "*/dist/*"
      )
      ;;
  esac

  "${find_cmd[@]}" 2>/dev/null || true
}

# Check if file needs formatting
check_file_needs_formatting() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    return 1
  fi

  local shfmt_options
  shfmt_options=$(get_shfmt_options)

  # Check diff
  local diff_output
  diff_output=$(shfmt $shfmt_options -d "$file" 2>/dev/null || true)

  if [[ -n "$diff_output" ]]; then
    return 0
  else
    return 1
  fi
}

# Format single file
format_file() {
  local file="$1"
  local dry_run="${2:-false}"

  if [[ ! -f "$file" ]]; then
    log_error "File not found: $file"
    return 1
  fi

  # Check if file needs formatting
  if ! check_file_needs_formatting "$file"; then
    log_debug "✓ $file is already properly formatted"
    return 0
  fi

  local shfmt_options
  shfmt_options=$(get_shfmt_options)

  if [[ "$dry_run" == "true" ]]; then
    log_info "🔍 Would format: $file"
    return 0
  else
    if shfmt $shfmt_options -w "$file" 2>/dev/null; then
      log_success "✓ Formatted: $file"
      return 0
    else
      log_error "✗ Failed to format: $file"
      return 1
    fi
  fi
}

# Format multiple files
format_files() {
  local files=("$@")
  local dry_run="${DRY_RUN:-false}"

  if [[ ${#files[@]} -eq 0 ]]; then
    log_info "No files to format"
    return 0
  fi

  local formatted_files=()
  local failed_files=()

  log_info "Formatting ${#files[@]} bash files"

  for file in "${files[@]}"; do
    if format_file "$file" "$dry_run"; then
      formatted_files+=("$file")
    else
      failed_files+=("$file")
    fi
  done

  # Report results
  log_success "✅ Successfully formatted ${#formatted_files[@]} files"

  if [[ ${#failed_files[@]} -gt 0 ]]; then
    log_error "❌ Failed to format ${#failed_files[@]} files:"
    printf '  %s\n' "${failed_files[@]}"
    return 1
  fi

  return 0
}

# Get commit message for auto-format fixes
get_commit_message() {
  local files_fixed="${1:-0}"
  local branch_name
  branch_name=$(git branch --show-current 2>/dev/null || echo "unknown")

  cat << EOF
auto: format bash scripts

- Fixed formatting in $files_fixed bash script files using shfmt
- Applied consistent indentation and style
- Auto-generated commit by CI auto-format workflow

CI_AUTO_FORMAT_SHA: $(git rev-parse HEAD 2>/dev/null || echo "unknown")
Branch: $branch_name
EOF
}

# Commit formatting fixes
commit_format_fixes() {
  local files_fixed="${1:-0}"

  if [[ $files_fixed -eq 0 ]]; then
    log_info "No formatting changes to commit"
    return 0
  fi

  # Check if there are changes to commit
  if git diff --quiet; then
    log_info "No changes detected after formatting"
    return 0
  fi

  # Add formatted files
  git add -A

  # Check if there are staged changes
  if git diff --cached --quiet; then
    log_info "No staged changes after formatting"
    return 0
  fi

  # Get commit message
  local commit_message
  commit_message=$(get_commit_message "$files_fixed")

  # Commit changes
  if git commit -m "$commit_message"; then
    log_success "✅ Committed formatting fixes"
    return 0
  else
    log_error "❌ Failed to commit formatting fixes"
    return 1
  fi
}

# Generate format report
generate_format_report() {
  local files_checked="${1:-0}"
  local files_fixed="${2:-0}"
  local files_failed="${3:-0}"
  local format_duration="${4:-0}"
  local status="${5:-success}"

  # Create CI report directory
  local report_dir="$PROJECT_ROOT/.github/reports"
  mkdir -p "$report_dir"

  local report_file="$report_dir/auto-format-$(date +%Y%m%d-%H%M%S).md"

  cat > "$report_file" << EOF
# 🔧 Auto-Format Report

**Generated**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**shfmt Version**: $(shfmt --version 2>/dev/null || echo "unknown")
**Files Checked**: $files_checked
**Files Fixed**: $files_fixed
**Files Failed**: $files_failed
**Duration**: ${format_duration}s
**Status**: $status

## 📊 Summary

EOF

  if [[ "$status" == "success" && $files_failed -eq 0 ]]; then
    cat >> "$report_file" << EOF
✅ **Auto-format completed successfully**
- All bash scripts are properly formatted
- $files_fixed files were automatically fixed
- Changes committed to repository

EOF
  else
    cat >> "$report_file" << EOF
⚠️ **Auto-format completed with issues**
- $files_fixed files were successfully fixed
- $files_failed files failed to format
- Manual intervention may be required

## 🛠️ Failed Files

The following files could not be formatted automatically:
EOF

    # Add failed files list if available
    if [[ $files_failed -gt 0 ]]; then
      echo "- Check the CI logs for specific file names and error messages" >> "$report_file"
    fi

    cat >> "$report_file" << EOF

### Manual Fix Options

1. **Check individual files**:
   \`\`\`bash
   shfmt -d path/to/file.sh  # Show differences
   shfmt -w path/to/file.sh  # Fix manually
   \`\`\`

2. **Review shfmt configuration**:
   - Check \`.shfmt.toml\` configuration file
   - Verify custom SHFMT_OPTIONS
   - Ensure files are valid bash scripts

3. **Handle special cases**:
   - Some files may need manual formatting
   - Consider excluding problematic files from auto-format

EOF
  fi

  cat >> "$report_file" << EOF

## 📚 Resources

- [shfmt Documentation](https://github.com/mvdan/sh)
- [Bash Style Guide](https://google.github.io/styleguide/shellguide.html)

---
*This report was generated by the CI auto-format workflow*
EOF

  log_success "Auto-format report generated: $report_file"
  echo "::set-output name=report_file::$report_file"
}

# Run auto-format workflow
run_auto_format() {
  local scope="${1:-all}"
  local auto_commit="${AUTO_COMMIT:-true}"
  local behavior
  behavior=$(get_behavior_mode)

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would auto-format bash scripts"
      echo "Scope: $scope"
      echo "Auto-commit: $auto_commit"
      return 0
      ;;
    "PASS")
      log_success "PASS MODE: Auto-format simulated successfully"
      return 0
      ;;
    "FAIL")
      log_error "FAIL MODE: Simulating auto-format failure"
      return 1
      ;;
    "SKIP")
      log_info "SKIP MODE: Auto-format skipped"
      return 0
      ;;
    "TIMEOUT")
      log_info "TIMEOUT MODE: Simulating auto-format timeout"
      sleep 5
      return 124
      ;;
  esac

  # EXECUTE mode - Actual auto-formatting
  log_info "Starting auto-format workflow"
  log_info "Scope: $scope"
  log_info "Auto-commit: $auto_commit"

  local start_time
  start_time=$(date +%s)

  # Validate requirements
  if ! check_shfmt_available; then
    exit 1
  fi

  if ! validate_git_repository; then
    exit 1
  fi

  # Get files to format
  local files_to_format
  mapfile -t files_to_format < <(find_bash_files "$scope")

  if [[ ${#files_to_format[@]} -eq 0 ]]; then
    log_info "No bash files found for scope: $scope"
    generate_format_report "0" "0" "0" "0" "success"
    return 0
  fi

  log_info "Found ${#files_to_format[@]} bash files to check"

  # Filter files that need formatting
  local files_needing_format=()
  for file in "${files_to_format[@]}"; do
    if check_file_needs_formatting "$file"; then
      files_needing_format+=("$file")
    fi
  done

  if [[ ${#files_needing_format[@]} -eq 0 ]]; then
    log_info "All bash files are already properly formatted"
    generate_format_report "${#files_to_format[@]}" "0" "0" "0" "success"
    return 0
  fi

  log_info "Found ${#files_needing_format[@]} files that need formatting"

  # Format files
  local format_success=true
  local files_fixed=0
  local files_failed=0

  for file in "${files_needing_format[@]}"; do
    if format_file "$file" "false"; then
      files_fixed=$((files_fixed + 1))
    else
      files_failed=$((files_failed + 1))
      format_success=false
    fi
  done

  # Commit changes if requested
  if [[ "$auto_commit" == "true" ]]; then
    if ! commit_format_fixes "$files_fixed"; then
      format_success=false
    fi
  fi

  # Calculate duration
  local end_time
  end_time=$(date +%s)
  local format_duration=$((end_time - start_time))

  # Generate report
  local final_status="success"
  if [[ "$format_success" != "true" ]]; then
    final_status="failure"
  fi

  generate_format_report "${#files_to_format[@]}" "$files_fixed" "$files_failed" "$format_duration" "$final_status"

  if [[ "$format_success" == "true" ]]; then
    log_success "✅ Auto-format workflow completed successfully"
    return 0
  else
    log_error "❌ Auto-format workflow completed with errors"
    return 1
  fi
}

# Main execution
main() {
  local scope="${1:-all}"
  local behavior
  behavior=$(get_behavior_mode)

  log_info "CI Auto-Format Script v$AUTO_FORMAT_VERSION"

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would auto-format bash scripts"
      return 0
      ;;
    "PASS")
      log_success "PASS MODE: Auto-format simulated successfully"
      return 0
      ;;
    "FAIL")
      log_error "FAIL MODE: Simulating auto-format failure"
      return 1
      ;;
    "SKIP")
      log_info "SKIP MODE: Auto-format skipped"
      return 0
      ;;
    "TIMEOUT")
      log_info "TIMEOUT MODE: Simulating auto-format timeout"
      sleep 5
      return 124
      ;;
  esac

  run_auto_format "$scope"
}

# CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Parse command line arguments
  case "${1:-}" in
    "help"|"--help"|"-h")
      cat << EOF
CI Auto-Format Script v$AUTO_FORMAT_VERSION

Automatically formats bash scripts using shfmt and commits fixes.

Usage:
  ./scripts/ci/50-ci-auto-format.sh [scope]

Scopes:
  all      - Format all bash files in repository (default)
  staged   - Format only staged files
  modified - Format only modified files

Environment Variables:
  CI_AUTO_FORMAT_MODE     EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT
  AUTO_COMMIT            true/false - Commit fixes automatically (default: true)
  SHFMT_OPTIONS          Custom shfmt options (e.g., "-i 4 -bn")
  CI_TEST_MODE           Global testability mode

Examples:
  # Format all bash files
  ./scripts/ci/50-ci-auto-format.sh all

  # Format only staged files
  ./scripts/ci/50-ci-auto-format.sh staged

  # Format without committing
  AUTO_COMMIT=false ./scripts/ci/50-ci-auto-format.sh all

  # Check what would be formatted
  DRY_RUN=true ./scripts/ci/50-ci-auto-format.sh all

GitHub Actions Integration:
  This script is designed to run in GitHub Actions workflows:
  - Automatically triggered on push/PR
  - Commits fixes back to the repository
  - Generates detailed reports
  - Supports testability modes

Testability:
  CI_TEST_MODE=DRY_RUN ./scripts/ci/50-ci-auto-format.sh
  CI_AUTO_FORMAT_MODE=FAIL ./scripts/ci/50-ci-auto-format.sh

Integration:
  This script integrates with:
  - GitHub Actions workflows
  - shfmt for bash code formatting
  - Git for version control and automatic commits
  - Lefthook for local development hooks
EOF
      exit 0
      ;;
    "validate")
      # Validation mode
      echo "Validating auto-format setup..."
      check_shfmt_available
      validate_git_repository
      echo "✅ Auto-format validation completed"
      ;;
    "check")
      # Check mode - just check what needs formatting
      DRY_RUN=true
      run_auto_format "${2:-all}"
      ;;
    *)
      main "$@"
      ;;
  esac
fi