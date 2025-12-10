#!/bin/bash
# CI Commit Fixes Script
# Commits formatting and linting fixes with proper commit messages

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common utilities" >&2
  exit 1
}

# Configuration
readonly COMMIT_FIXES_VERSION="1.0.0"

# Git configuration for auto-commits
GIT_AUTHOR_NAME="CI Auto-Fix Bot"
GIT_AUTHOR_EMAIL="ci-autofix@example.com"
GIT_COMMITTER_NAME="CI Auto-Fix Bot"
GIT_COMMITTER_EMAIL="ci-autofix@example.com"

# Testability configuration
get_behavior_mode() {
  local script_name="ci_commit_fixes"
  get_script_behavior "$script_name" "EXECUTE"
}

# Check git is available
check_git_available() {
  if ! command -v git >/dev/null 2>&1; then
    log_error "❌ git is not available"
    return 1
  fi

  log_debug "git is available"
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

# Configure git for auto-commits
configure_git() {
  if [[ "${SKIP_GIT_CONFIG:-false}" != "true" ]]; then
    git config user.name "$GIT_AUTHOR_NAME"
    git config user.email "$GIT_AUTHOR_EMAIL"
    log_debug "Git configured for auto-commits"
  fi
}

# Check if there are changes to commit
has_changes() {
  # Check for unstaged changes
  if ! git diff --quiet; then
    return 0
  fi

  # Check for staged changes
  if ! git diff --cached --quiet; then
    return 0
  fi

  # Check for untracked files
  if [[ -n "$(git ls-files --others --exclude-standard)" ]]; then
    return 0
  fi

  return 1
}

# Get changes summary
get_changes_summary() {
  local summary=""

  # Get modified files
  local modified_files
  modified_files=$(git diff --name-only 2>/dev/null || true)
  if [[ -n "$modified_files" ]]; then
    summary+="Modified: $(echo "$modified_files" | wc -l) files\n"
  fi

  # Get added files
  local added_files
  added_files=$(git diff --cached --name-only --diff-filter=A 2>/dev/null || true)
  if [[ -n "$added_files" ]]; then
    summary+="Added: $(echo "$added_files" | wc -l) files\n"
  fi

  # Get deleted files
  local deleted_files
  deleted_files=$(git diff --name-only --diff-filter=D 2>/dev/null || true)
  if [[ -n "$deleted_files" ]]; then
    summary+="Deleted: $(echo "$deleted_files" | wc -l) files\n"
  fi

  if [[ -z "$summary" ]]; then
    summary="No changes detected\n"
  fi

  echo -e "$summary"
}

# Get specific changes for formatting fixes
get_format_changes() {
  local files=()

  # Get staged bash files
  while IFS= read -r file; do
    if [[ "$file" =~ \.(sh|bash|zsh)$ ]]; then
      files+=("$file")
    fi
  done <<< "$(git diff --cached --name-only --diff-filter=AM 2>/dev/null || true)"

  # Get unstaged bash files
  while IFS= read -r file; do
    if [[ "$file" =~ \.(sh|bash|zsh)$ ]]; then
      files+=("$file")
    fi
  done <<< "$(git diff --name-only 2>/dev/null || true)"

  # Remove duplicates
  printf '%s\n' "${files[@]}" | sort -u
}

# Get specific changes for lint fixes
get_lint_changes() {
  local files=()

  # Get staged bash files
  while IFS= read -r file; do
    if [[ "$file" =~ \.(sh|bash|zsh)$ ]]; then
      files+=("$file")
    fi
  done <<< "$(git diff --cached --name-only --diff-filter=AM 2>/dev/null || true)"

  # Get unstaged bash files
  while IFS= read -r file; do
    if [[ "$file" =~ \.(sh|bash|zsh)$ ]]; then
      files+=("$file")
    fi
  done <<< "$(git diff --name-only 2>/dev/null || true)"

  # Remove duplicates
  printf '%s\n' "${files[@]}" | sort -u
}

# Generate commit message for formatting fixes
generate_format_commit_message() {
  local files_changed
  files_changed=$(get_format_changes | wc -l)

  local branch_name
  branch_name=$(git branch --show-current 2>/dev/null || echo "unknown")

  local commit_sha
  commit_sha=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

  cat << EOF
auto: format bash scripts

- Applied shfmt formatting to $files_changed bash script files
- Ensured consistent indentation and style
- Auto-generated commit by CI auto-fix workflow

Files: $(get_format_changes | tr '\n' ' ' | sed 's/ $//')

CI_COMMIT_FIXES_SHA: $commit_sha
Branch: $branch_name
Workflow: $GITHUB_WORKFLOW
Run: $GITHUB_RUN_ID
EOF
}

# Generate commit message for lint fixes
generate_lint_commit_message() {
  local files_changed
  files_changed=$(get_lint_changes | wc -l)

  local branch_name
  branch_name=$(git branch --show-current 2>/dev/null || echo "unknown")

  local commit_sha
  commit_sha=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

  cat << EOF
auto: fix shellcheck linting issues

- Fixed ShellCheck issues in $files_changed bash script files
- Applied automatic fixes for common linting issues
- Auto-generated commit by CI auto-fix workflow

Files: $(get_lint_changes | tr '\n' ' ' | sed 's/ $//')

CI_COMMIT_FIXES_SHA: $commit_sha
Branch: $branch_name
Workflow: $GITHUB_WORKFLOW
Run: $GITHUB_RUN_ID
EOF
}

# Generate generic commit message
generate_generic_commit_message() {
  local changes_summary
  changes_summary=$(get_changes_summary)

  local branch_name
  branch_name=$(git branch --show-current 2>/dev/null || echo "unknown")

  local commit_sha
  commit_sha=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

  cat << EOF
auto: apply automated fixes

- Applied automated fixes to codebase
- Changes:
$(echo "$changes_summary" | sed 's/^/  - /')
- Auto-generated commit by CI auto-fix workflow

CI_COMMIT_FIXES_SHA: $commit_sha
Branch: $branch_name
Workflow: $GITHUB_WORKFLOW
Run: $GITHUB_RUN_ID
EOF
}

# Stage all relevant changes
stage_changes() {
  local fix_type="${1:-all}"

  case "$fix_type" in
    "format")
      # Stage bash script changes
      git add "*.sh" "*.bash" "*.zsh" 2>/dev/null || true
      git add "scripts/**/*.sh" "scripts/**/*.bash" "scripts/**/*.zsh" 2>/dev/null || true
      ;;
    "lint")
      # Stage bash script changes
      git add "*.sh" "*.bash" "*.zsh" 2>/dev/null || true
      git add "scripts/**/*.sh" "scripts/**/*.bash" "scripts/**/*.zsh" 2>/dev/null || true
      ;;
    "all"|*)
      # Stage all changes
      git add -A
      ;;
  esac

  log_debug "Staged changes for fix type: $fix_type"
}

# Commit changes with appropriate message
commit_changes() {
  local fix_type="${1:-all}"
  local dry_run="${DRY_RUN:-false}"

  if ! has_changes; then
    log_info "No changes to commit"
    return 0
  fi

  if [[ "$dry_run" == "true" ]]; then
    log_info "🔍 DRY RUN: Would commit changes"
    get_changes_summary
    return 0
  fi

  # Stage changes
  stage_changes "$fix_type"

  # Check if there are staged changes after staging
  if git diff --cached --quiet; then
    log_info "No staged changes after staging"
    return 0
  fi

  # Generate commit message
  local commit_message
  case "$fix_type" in
    "format")
      commit_message=$(generate_format_commit_message)
      ;;
    "lint")
      commit_message=$(generate_lint_commit_message)
      ;;
    *)
      commit_message=$(generate_generic_commit_message)
      ;;
  esac

  # Create commit
  if git commit -m "$commit_message"; then
    log_success "✅ Committed fixes for type: $fix_type"

    # Get commit SHA for output
    local new_commit_sha
    new_commit_sha=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
    log_info "Commit SHA: $new_commit_sha"
    echo "::set-output name=commit_sha::$new_commit_sha"

    return 0
  else
    log_error "❌ Failed to commit fixes for type: $fix_type"
    return 1
  fi
}

# Push changes if configured
push_changes() {
  local remote="${1:-origin}"
  local branch="${2:-$(git branch --show-current 2>/dev/null || echo "main")}"

  if [[ "${PUSH_CHANGES:-false}" != "true" ]]; then
    log_info "Push is disabled (PUSH_CHANGES=false)"
    return 0
  fi

  log_info "Pushing changes to $remote/$branch"

  if git push "$remote" "$branch"; then
    log_success "✅ Pushed changes to remote"
    return 0
  else
    log_error "❌ Failed to push changes to remote"
    return 1
  fi
}

# Generate commit report
generate_commit_report() {
  local fix_type="${1:-all}"
  local commit_success="${2:-true}"
  local commit_duration="${3:-0}"
  local commit_sha="${4:-unknown}"

  # Create CI report directory
  local report_dir="$PROJECT_ROOT/.github/reports"
  mkdir -p "$report_dir"

  local report_file="$report_dir/commit-fixes-$(date +%Y%m%d-%H%M%S).md"

  cat > "$report_file" << EOF
# 📝 Commit Fixes Report

**Generated**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**Fix Type**: $fix_type
**Commit SHA**: $commit_sha
**Duration**: ${commit_duration}s
**Status**: $([[ "$commit_success" == "true" ]] && echo "Success" || echo "Failed")

## 📊 Changes Summary

$(get_changes_summary)

## 🔧 Files Modified

EOF

  # Add files list
  local all_files
  all_files=$(git diff-tree --no-commit-id --name-only -r "$commit_sha" 2>/dev/null || echo "")
  if [[ -n "$all_files" ]]; then
    while IFS= read -r file; do
      echo "- \`$file\`" >> "$report_file"
    done <<< "$all_files"
  else
    echo "No files modified" >> "$report_file"
  fi

  cat >> "$report_file" << EOF

## 📋 Commit Details

- **Author**: $GIT_AUTHOR_NAME <$GIT_AUTHOR_EMAIL>
- **Branch**: $(git branch --show-current 2>/dev/null || echo "unknown")
- **Workflow**: ${GITHUB_WORKFLOW:-"unknown"}
- **Run ID**: ${GITHUB_RUN_ID:-"unknown"}

## 🔄 Next Steps

EOF

  if [[ "$commit_success" == "true" ]]; then
    cat >> "$report_file" << EOF
✅ **Fixes successfully committed**

- Changes have been applied and committed
- Automated fixes are now part of the codebase
- Continue with your development workflow

EOF
  else
    cat >> "$report_file" << EOF
❌ **Commit failed**

- Changes were staged but commit failed
- Check the CI logs for specific error messages
- Manual intervention may be required

### Manual Recovery

1. **Check status**:
   \`\`\`bash
   git status
   git diff --cached
   \`\`\`

2. **Manual commit**:
   \`\`\`bash
   git commit -m "auto: apply manual fixes"
   \`\`\`

3. **Push changes**:
   \`\`\`bash
   git push origin \$(git branch --show-current)
   \`\`\`

EOF
  fi

  cat >> "$report_file" << EOF

---
*This report was generated by the CI commit fixes workflow*
EOF

  log_success "Commit report generated: $report_file"
  echo "::set-output name=report_file::$report_file"
}

# Run commit fixes workflow
run_commit_fixes() {
  local fix_type="${1:-all}"
  local push_changes="${PUSH_CHANGES:-false}"
  local behavior
  behavior=$(get_behavior_mode)

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would commit fixes"
      echo "Fix type: $fix_type"
      echo "Push changes: $push_changes"
      return 0
      ;;
    "PASS")
      log_success "PASS MODE: Commit fixes simulated successfully"
      return 0
      ;;
    "FAIL")
      log_error "FAIL MODE: Simulating commit fixes failure"
      return 1
      ;;
    "SKIP")
      log_info "SKIP MODE: Commit fixes skipped"
      return 0
      ;;
    "TIMEOUT")
      log_info "TIMEOUT MODE: Simulating commit fixes timeout"
      sleep 5
      return 124
      ;;
  esac

  # EXECUTE mode - Actual commit fixes
  log_info "Starting commit fixes workflow"
  log_info "Fix type: $fix_type"
  log_info "Push changes: $push_changes"

  local start_time
  start_time=$(date +%s)

  # Validate requirements
  if ! check_git_available; then
    exit 1
  fi

  if ! validate_git_repository; then
    exit 1
  fi

  # Configure git
  configure_git

  local commit_success=true
  local commit_sha="unknown"

  # Commit changes
  if ! commit_changes "$fix_type"; then
    commit_success=false
  else
    # Get commit SHA
    commit_sha=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
  fi

  # Push changes if configured
  if [[ "$commit_success" == "true" ]] && [[ "$push_changes" == "true" ]]; then
    if ! push_changes; then
      commit_success=false
    fi
  fi

  # Calculate duration
  local end_time
  end_time=$(date +%s)
  local commit_duration=$((end_time - start_time))

  # Generate report
  generate_commit_report "$fix_type" "$commit_success" "$commit_duration" "$commit_sha"

  if [[ "$commit_success" == "true" ]]; then
    log_success "✅ Commit fixes workflow completed successfully"
    return 0
  else
    log_error "❌ Commit fixes workflow completed with errors"
    return 1
  fi
}

# Main execution
main() {
  local fix_type="${1:-all}"
  local behavior
  behavior=$(get_behavior_mode)

  log_info "CI Commit Fixes Script v$COMMIT_FIXES_VERSION"

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would commit fixes"
      return 0
      ;;
    "PASS")
      log_success "PASS MODE: Commit fixes simulated successfully"
      return 0
      ;;
    "FAIL")
      log_error "FAIL MODE: Simulating commit fixes failure"
      return 1
      ;;
    "SKIP")
      log_info "SKIP MODE: Commit fixes skipped"
      return 0
      ;;
    "TIMEOUT")
      log_info "TIMEOUT MODE: Simulating commit fixes timeout"
      sleep 5
      return 124
      ;;
  esac

  run_commit_fixes "$fix_type"
}

# CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Parse command line arguments
  case "${1:-}" in
    "help"|"--help"|"-h")
      cat << EOF
CI Commit Fixes Script v$COMMIT_FIXES_VERSION

Commits formatting and linting fixes with proper commit messages.

Usage:
  ./scripts/ci/70-ci-commit-fixes.sh [type]

Types:
  all     - Commit all changes (default)
  format  - Commit only formatting fixes
  lint    - Commit only linting fixes

Environment Variables:
  CI_COMMIT_FIXES_MODE    EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT
  PUSH_CHANGES           true/false - Push changes to remote (default: false)
  SKIP_GIT_CONFIG        true/false - Skip git configuration (default: false)
  GIT_AUTHOR_NAME        Custom git author name
  GIT_AUTHOR_EMAIL       Custom git author email
  CI_TEST_MODE           Global testability mode

Examples:
  # Commit all changes
  ./scripts/ci/70-ci-commit-fixes.sh all

  # Commit only formatting fixes
  ./scripts/ci/70-ci-commit-fixes.sh format

  # Commit and push changes
  PUSH_CHANGES=true ./scripts/ci/70-ci-commit-fixes.sh all

  # Check what would be committed
  DRY_RUN=true ./scripts/ci/70-ci-commit-fixes.sh all

GitHub Actions Integration:
  This script is designed to run in GitHub Actions workflows:
  - Commits automated fixes with proper attribution
  - Generates detailed commit reports
  - Supports pushing changes back to repository
  - Integrates with auto-format and auto-lint-fix scripts

Testability:
  CI_TEST_MODE=DRY_RUN ./scripts/ci/70-ci-commit-fixes.sh
  CI_COMMIT_FIXES_MODE=FAIL ./scripts/ci/70-ci-commit-fixes.sh

Integration:
  This script integrates with:
  - GitHub Actions workflows
  - Git for version control and automatic commits
  - Auto-format and auto-lint-fix workflows
  - CI/CD pipeline automation
EOF
      exit 0
      ;;
    "validate")
      # Validation mode
      echo "Validating commit fixes setup..."
      check_git_available
      validate_git_repository
      echo "✅ Commit fixes validation completed"
      ;;
    "status")
      # Status mode
      echo "Current repository status:"
      git status
      echo ""
      if has_changes; then
        echo "Changes to be committed:"
        get_changes_summary
      else
        echo "No changes to commit"
      fi
      ;;
    *)
      main "$@"
      ;;
  esac
fi