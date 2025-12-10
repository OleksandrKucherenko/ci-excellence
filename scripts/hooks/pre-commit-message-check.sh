#!/bin/bash
# Pre-commit Message Check Hook
# Validates commit messages using Commitizen before allowing commits

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common utilities" >&2
  exit 1
}

# Configuration
readonly PRE_COMMIT_MESSAGE_CHECK_VERSION="1.0.0"

# Commitizen configuration
DEFAULT_COMMITIZEN_CONFIG="cz_conventional_commits"

# Testability configuration
get_behavior_mode() {
  local script_name="pre_commit_message_check"
  get_script_behavior "$script_name" "EXECUTE"
}

# Check if Commitizen is available
check_commitizen_available() {
  if ! command -v cz >/dev/null 2>&1 && ! command -v commitizen >/dev/null 2>&1; then
    log_error "❌ Commitizen is not installed"
    log_error "Install Commitizen: npm install -g commitizen"
    log_error "Install conventional commits: npm install -g cz-conventional-commits"
    log_error "Or disable this hook by removing it from .lefthook.yml"
    return 1
  fi

  log_debug "Commitizen is available"
  return 0
}

# Get Commitizen version
get_commitizen_version() {
  if command -v cz >/dev/null 2>&1; then
    cz --version 2>/dev/null || echo "unknown"
  elif command -v commitizen >/dev/null 2>&1; then
    commitizen --version 2>/dev/null || echo "unknown"
  else
    echo "unknown"
  fi
}

# Validate git repository
validate_git_repository() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    log_error "❌ Not in a git repository"
    return 1
  fi

  return 0
}

# Get commit message from file
get_commit_message() {
  local commit_msg_file="${1:-}"

  if [[ -z "$commit_msg_file" ]]; then
    # Try to find commit message file (used by git hooks)
    if [[ -n "${GIT_COMMIT_MESSAGE_FILE:-}" ]]; then
      commit_msg_file="$GIT_COMMIT_MESSAGE_FILE"
    elif [[ -f ".git/COMMIT_EDITMSG" ]]; then
      commit_msg_file=".git/COMMIT_EDITMSG"
    else
      log_error "No commit message file provided"
      return 1
    fi
  fi

  if [[ ! -f "$commit_msg_file" ]]; then
    log_error "Commit message file not found: $commit_msg_file"
    return 1
  fi

  cat "$commit_msg_file"
}

# Get commitizen command
get_commitizen_cmd() {
  if command -v cz >/dev/null 2>&1; then
    echo "cz"
  elif command -v commitizen >/dev/null 2>&1; then
    echo "commitizen"
  else
    echo ""
  fi
}

# Validate commit message with Commitizen
validate_commit_message() {
  local commit_msg="$1"
  local commitizen_cmd
  commitizen_cmd=$(get_commitizen_cmd)

  if [[ -z "$commitizen_cmd" ]]; then
    log_error "Commitizen command not found"
    return 1
  fi

  # Get config
  local config
  config=$(get_commitizen_config)

  # Write commit message to temporary file
  local temp_file
  temp_file=$(mktemp)
  echo "$commit_msg" > "$temp_file"

  # Validate with commitizen
  local validation_output
  validation_output=$($commitizen_cmd check --message-file "$temp_file" --config "$config" 2>&1 || true)

  rm -f "$temp_file"

  if [[ -z "$validation_output" ]]; then
    log_success "✓ Commit message is valid"
    return 0
  else
    log_error "✗ Commit message validation failed:"
    echo "$validation_output" | sed 's/^/  /'
    return 1
  fi
}

# Get commitizen config
get_commitizen_config() {
  # Check for custom config
  if [[ -n "${COMMITIZEN_CONFIG:-}" ]]; then
    echo "$COMMITIZEN_CONFIG"
    return 0
  fi

  # Check for project config file
  if [[ -f "$PROJECT_ROOT/.czrc" ]]; then
    # Extract config from .czrc
    grep -o '"path": "[^"]*"' "$PROJECT_ROOT/.czrc" 2>/dev/null | cut -d'"' -f4 || echo "$DEFAULT_COMMITIZEN_CONFIG"
    return 0
  fi

  # Check package.json
  if [[ -f "$PROJECT_ROOT/package.json" ]]; then
    if grep -q "cz-conventional-commits" "$PROJECT_ROOT/package.json" 2>/dev/null; then
      echo "cz_conventional_commits"
      return 0
    fi
  fi

  # Use default
  echo "$DEFAULT_COMMITIZEN_CONFIG"
}

# Get commit message statistics
get_commit_message_stats() {
  local commit_msg="$1"

  local lines
  lines=$(echo "$commit_msg" | wc -l)
  local subject_length
  subject_length=$(echo "$commit_msg" | head -n1 | wc -c)
  subject_length=$((subject_length - 1)) # Remove newline

  echo "Lines: $lines, Subject length: $subject_length"
}

# Check commit message format (basic checks)
basic_commit_message_check() {
  local commit_msg="$1"

  # Get first line (subject)
  local subject
  subject=$(echo "$commit_msg" | head -n1)

  # Basic checks
  if [[ -z "$subject" ]]; then
    log_error "Commit message subject is empty"
    return 1
  fi

  # Check subject length (conventional: 50-72 chars)
  local subject_length
  subject_length=$(echo "$subject" | wc -c)
  subject_length=$((subject_length - 1)) # Remove newline

  if [[ $subject_length -gt 72 ]]; then
    log_error "Commit message subject is too long ($subject_length chars, max 72)"
    return 1
  fi

  if [[ $subject_length -lt 10 ]]; then
    log_error "Commit message subject is too short ($subject_length chars, min 10)"
    return 1
  fi

  # Check if starts with conventional commit type
  local conventional_types
  conventional_types="feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert"

  if [[ "$subject" =~ ^($conventional_types)(\(.+\))?:.+ ]]; then
    log_success "✓ Subject follows conventional commit format"
    return 0
  elif [[ "${STRICT_CONVENTIONAL:-false}" == "true" ]]; then
    log_error "Subject does not follow conventional commit format"
    log_error "Expected format: <type>(<scope>): <description>"
    log_error "Types: $conventional_types"
    return 1
  else
    log_warn "⚠️ Subject doesn't follow conventional commit format"
    return 0
  fi
}

# Suggest commit message improvements
suggest_commit_message_improvements() {
  local commit_msg="$1"

  local suggestions=()
  local subject
  subject=$(echo "$commit_msg" | head -n1)

  # Check for common issues
  if [[ "$subject" =~ \.$ ]]; then
    suggestions+=("Remove period from subject line")
  fi

  if [[ ! "$subject" =~ ^[A-Z] ]]; then
    suggestions+=("Start subject with uppercase letter")
  fi

  if [[ "$subject" =~ ^Merge ]]; then
    suggestions+=("Use more descriptive subject instead of 'Merge branch'")
  fi

  # Check body formatting
  local body
  body=$(echo "$commit_msg" | tail -n +2 | sed '/^$/d')

  if [[ -n "$body" ]]; then
    # Check if body lines are too long
    while IFS= read -r line; do
      local line_length
      line_length=$(echo "$line" | wc -c)
      line_length=$((line_length - 1))

      if [[ $line_length -gt 72 ]]; then
        suggestions+=("Wrap body lines at 72 characters")
        break
      fi
    done <<< "$body"

    # Check for empty line between subject and body
    if [[ ! "$commit_msg" =~ ^[^\n]+\n\n ]]; then
      suggestions+=("Add empty line between subject and body")
    fi
  fi

  if [[ ${#suggestions[@]} -gt 0 ]]; then
    log_info "💡 Suggestions for improvement:"
    printf '  - %s\n' "${suggestions[@]}"
  fi

  return 0
}

# Format commit message according to conventional commits
format_commit_message() {
  local commit_msg="$1"
  local interactive="${2:-false}"

  if [[ "$interactive" == "true" ]]; then
    log_info "Interactive commit message formatting"
    log_info "Current message:"
    echo "$commit_msg"
    echo ""
    read -p "Would you like to format this message? (y/N): " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      return 0
    fi
  fi

  # Basic formatting
  local formatted_msg
  formatted_msg=$(echo "$commit_msg" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

  # Ensure proper spacing between subject and body
  if [[ ! "$formatted_msg" =~ ^[^\n]+\n\n ]] && [[ "$formatted_msg" =~ $'\n' ]]; then
    formatted_msg=$(echo "$formatted_msg" | sed '2s/^[[:space:]]*//')
    formatted_msg=$(echo "$formatted_msg" | sed '1a\\')
  fi

  # Remove trailing periods from subject
  formatted_msg=$(echo "$formatted_msg" | sed '1s/\.$//')

  echo "$formatted_msg"
}

# Process commit message file
process_commit_message_file() {
  local commit_msg_file="${1:-}"

  if [[ -z "$commit_msg_file" ]]; then
    # Use git's commit message file
    commit_msg_file=".git/COMMIT_EDITMSG"
  fi

  if [[ ! -f "$commit_msg_file" ]]; then
    log_error "Commit message file not found: $commit_msg_file"
    return 1
  fi

  log_info "Checking commit message in $commit_msg_file"

  local commit_msg
  commit_msg=$(get_commit_message "$commit_msg_file")

  if [[ -z "$commit_msg" ]]; then
    log_error "Commit message is empty"
    return 1
  fi

  log_debug "Commit message:"
  log_debug "$commit_msg"

  # Run validation
  local validation_success=true

  # Basic checks first
  if ! basic_commit_message_check "$commit_msg"; then
    validation_success=false
  fi

  # Commitizen validation
  if [[ "${USE_COMMITIZEN:-true}" == "true" ]]; then
    if ! validate_commit_message "$commit_msg"; then
      validation_success=false
    fi
  fi

  # Show suggestions
  if [[ "${SHOW_SUGGESTIONS:-false}" == "true" ]]; then
    suggest_commit_message_improvements "$commit_msg"
  fi

  # Format message if requested
  if [[ "${AUTO_FORMAT:-false}" == "true" ]]; then
    local formatted_msg
    formatted_msg=$(format_commit_message "$commit_msg")

    if [[ "$formatted_msg" != "$commit_msg" ]]; then
      log_info "📝 Formatting commit message"
      echo "$formatted_msg" > "$commit_msg_file"
      log_success "✓ Commit message formatted"
    fi
  fi

  if [[ "$validation_success" == "true" ]]; then
    log_success "✅ Commit message validation passed"
    return 0
  else
    log_error "❌ Commit message validation failed"
    log_error ""
    log_error "Commit message format requirements:"
    log_error "1. Subject should be 10-72 characters"
    log_error "2. Use conventional commit format: <type>(<scope>): <description>"
    log_error "3. Types: feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert"
    log_error "4. Separate subject from body with blank line"
    log_error "5. Wrap body lines at 72 characters"
    log_error ""
    log_error "Example: feat(auth): add JWT token validation"
    return 1
  fi
}

# Run message check
run_message_check() {
  local commit_msg_file="${1:-}"
  local behavior
  behavior=$(get_behavior_mode)

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would check commit message"
      if [[ -n "$commit_msg_file" ]]; then
        echo "Would check: $commit_msg_file"
      else
        echo "Would check commit message file"
      fi
      return 0
      ;;
    "PASS")
      log_success "PASS MODE: Commit message check simulated successfully"
      return 0
      ;;
    "FAIL")
      log_error "FAIL MODE: Simulating commit message check failure"
      return 1
      ;;
    "SKIP")
      log_info "SKIP MODE: Commit message check skipped"
      return 0
      ;;
    "TIMEOUT")
      log_info "TIMEOUT MODE: Simulating commit message check timeout"
      sleep 5
      return 124
      ;;
  esac

  # EXECUTE mode - Actual message checking
  process_commit_message_file "$commit_msg_file"
}

# Generate report
generate_report() {
  local commit_msg_file="${1:-}"
  local check_duration="${2:-0}"
  local status="${3:-success}"

  # Create pre-commit report directory
  local report_dir="$PROJECT_ROOT/.github/pre-commit-reports"
  mkdir -p "$report_dir"

  local report_file="$report_dir/message-check-$(date +%Y%m%d-%H%M%S).md"

  cat > "$report_file" << EOF
# 📝 Pre-commit Message Check Report

**Generated**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**Commitizen Version**: $(get_commitizen_version)
**Commit Message File**: ${commit_msg_file:-"N/A"}
**Check Duration**: ${check_duration}s
**Status**: $status

## 📋 Summary

EOF

  if [[ "$status" == "success" ]]; then
    cat >> "$report_file" << EOF
✅ **Pre-commit message check passed**
- Commit message follows conventional commit format
- Safe to proceed with commit

EOF
  else
    cat >> "$report_file" << EOF
❌ **Pre-commit message check failed**
- Commit message does not meet format requirements
- Commit blocked for message quality reasons

## 🛠️ Next Steps

1. Review your commit message
2. Follow conventional commit format
3. Update the commit message and try again

### Conventional Commit Format

\`\`\`
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
\`\`\`

### Common Types

- \`feat\`: New feature
- \`fix\`: Bug fix
- \`docs\`: Documentation changes
- \`style\`: Code style changes (formatting, missing semicolons, etc.)
- \`refactor\`: Code refactoring
- \`test\`: Adding or updating tests
- \`chore\`: Maintenance tasks, dependency updates
- \`perf\`: Performance improvements
- \`ci\`: CI/CD changes
- \`build\`: Build system changes

### Examples

\`\`\`
feat(auth): add JWT token validation

fix(api): handle null response in user endpoint

docs(readme): update installation instructions

chore(deps): update lodash to v4.17.21
\`\`\`

## 📚 Resources

- [Conventional Commits Specification](https://www.conventionalcommits.org/)
- [Commitizen Documentation](https://github.com/commitizen-tools/commitizen)
- [Conventional Changelog](https://github.com/conventional-changelog)

EOF
  fi

  cat >> "$report_file" << EOF

---
*This report was generated by the pre-commit message check hook*
EOF

  log_info "Pre-commit report generated: $report_file"
}

# Main execution
main() {
  local commit_msg_file="${1:-}"
  local behavior
  behavior=$(get_behavior_mode)

  local start_time
  start_time=$(date +%s)

  log_info "Pre-commit Message Check Hook v$PRE_COMMIT_MESSAGE_CHECK_VERSION"

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would check commit message format"
      return 0
      ;;
    "PASS")
      log_success "PASS MODE: Pre-commit message check simulated successfully"
      return 0
      ;;
    "FAIL")
      log_error "FAIL MODE: Simulating pre-commit message check failure"
      return 1
      ;;
    "SKIP")
      log_info "SKIP MODE: Pre-commit message check skipped"
      return 0
      ;;
    "TIMEOUT")
      log_info "TIMEOUT MODE: Simulating pre-commit message check timeout"
      sleep 5
      return 124
      ;;
  esac

  # EXECUTE mode - Actual message checking
  log_info "Starting pre-commit message check"

  # Validate requirements
  if ! validate_git_repository; then
    exit 1
  fi

  local check_duration=0
  local check_status="success"

  # Run message check
  if ! run_message_check "$commit_msg_file"; then
    check_status="failure"
  fi

  # Calculate duration
  local end_time
  end_time=$(date +%s)
  check_duration=$((end_time - start_time))

  # Generate report
  generate_report "$commit_msg_file" "$check_duration" "$check_status"

  if [[ "$check_status" == "success" ]]; then
    log_success "✅ Pre-commit message check completed successfully"
    return 0
  else
    log_error "❌ Pre-commit message check failed"
    return 1
  fi
}

# CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Parse command line arguments
  case "${1:-}" in
    "help"|"--help"|"-h")
      cat << EOF
Pre-commit Message Check Hook v$PRE_COMMIT_MESSAGE_CHECK_VERSION

This hook validates commit messages using Commitizen and conventional commit format before allowing commits.

Usage:
  Used as a git commit-msg hook via Lefthook configuration

Configuration:
  Add to .lefthook.yml:
    commit-msg:
      commands:
        message-check:
          run: ./scripts/hooks/pre-commit-message-check.sh {1}
          tags: [commit, message]

Environment Variables:
  PRE_COMMIT_MESSAGE_CHECK_MODE  EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT
  COMMITIZEN_CONFIG              Commitizen config name (default: cz_conventional_commits)
  USE_COMMITIZEN                 true/false - Use Commitizen validation (default: true)
  STRICT_CONVENTIONAL            true/false - Enforce conventional format (default: false)
  SHOW_SUGGESTIONS               true/false - Show improvement suggestions
  AUTO_FORMAT                    true/false - Auto-format messages
  CI_TEST_MODE                   Global testability mode

Commit Message Format:
- Subject: 10-72 characters, starts with conventional type
- Types: feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert
- Optional scope in parentheses: type(scope): description
- Separate subject from body with blank line
- Wrap body lines at 72 characters

Examples:
  # Automatic usage via git commit
  git commit -m "feat(auth): add JWT token validation"

  # Manual checking of commit message file
  ./scripts/hooks/pre-commit-message-check.sh .git/COMMIT_EDITMSG

  # Check specific commit message
  echo "feat: add new feature" | ./scripts/hooks/pre-commit-message-check.sh

  # Show suggestions for improvement
  SHOW_SUGGESTIONS=true ./scripts/hooks/pre-commit-message-check.sh

  # Auto-format message
  AUTO_FORMAT=true ./scripts/hooks/pre-commit-message-check.sh

Testability:
  CI_TEST_MODE=DRY_RUN ./scripts/hooks/pre-commit-message-check.sh
  PRE_COMMIT_MESSAGE_CHECK_MODE=FAIL ./scripts/hooks/pre-commit-message-check.sh

Integration:
  This hook integrates with:
  - Lefthook for commit-msg hook management
  - ShellSpec for testing hook behavior
  - Commitizen for conventional commit validation
  - GitHub Actions for CI pipeline commit message validation
EOF
      exit 0
      ;;
    "check")
      # Check mode
      if [[ $# -lt 2 ]]; then
        echo "Usage: $0 check <commit-message-file>"
        exit 1
      fi
      shift
      run_message_check "$1"
      exit $?
      ;;
    "validate")
      # Validation mode for testing
      echo "Validating pre-commit hook setup..."
      check_commitizen_available
      validate_git_repository
      echo "✅ Pre-commit hook validation completed"
      ;;
    "format")
      # Format mode
      if [[ $# -lt 2 ]]; then
        echo "Usage: $0 format <commit-message>"
        exit 1
      fi
      shift
      format_commit_message "$1" "true"
      ;;
    *)
      main "$@"
      ;;
  esac
fi