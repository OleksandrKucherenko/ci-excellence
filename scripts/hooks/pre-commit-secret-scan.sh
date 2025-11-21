#!/bin/bash
# Pre-commit Secret Scan Hook
# Scans staged files for secrets using Gitleaks before allowing commits

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common utilities" >&2
  exit 1
}

# Configuration
readonly PRE_COMMIT_SECRET_SCAN_VERSION="1.0.0"

# Testability configuration
get_behavior_mode() {
  local script_name="pre_commit_secret_scan"
  get_script_behavior "$script_name" "EXECUTE"
}

# Check if Gitleaks is available
check_gitleaks_available() {
  if ! command -v gitleaks >/dev/null 2>&1; then
    log_error "❌ Gitleaks is not installed"
    log_error "Install gitleaks: https://github.com/gitleaks/gitleaks"
    log_error "Or disable this hook by removing it from .lefthook.yml"
    return 1
  fi

  return 0
}

# Get Gitleaks version
get_gitleaks_version() {
  gitleaks --version 2>/dev/null || echo "unknown"
}

# Validate git repository
validate_git_repository() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    log_error "❌ Not in a git repository"
    return 1
  fi

  return 0
}

# Get staged files for scanning
get_staged_files() {
  # Get only staged files that could contain secrets
  local staged_files
  staged_files=$(git diff --cached --name-only --diff-filter=ACM | \
    grep -E '\.(env|ini|cfg|conf|key|pem|p12|pfx|crt|der|jks|keystore|store)$' 2>/dev/null || true)

  # Add staged files with common secret patterns in content
  local additional_files
  additional_files=$(git diff --cached --name-only --diff-filter=ACM | \
    grep -E '\.(sh|bash|zsh|fish|py|js|ts|php|rb|go|java|cs|vb|ps1|psm1|sql)$' 2>/dev/null || true)

  # Combine and deduplicate
  local all_files
  if [[ -n "$staged_files" && -n "$additional_files" ]]; then
    all_files=$(printf '%s\n%s\n' "$staged_files" "$additional_files" | sort -u)
  elif [[ -n "$staged_files" ]]; then
    all_files="$staged_files"
  elif [[ -n "$additional_files" ]]; then
    all_files="$additional_files"
  else
    all_files=""
  fi

  # Remove empty lines
  all_files=$(echo "$all_files" | grep -v '^$' 2>/dev/null || echo "$all_files")

  if [[ -z "$all_files" ]]; then
    return 0
  fi

  echo "$all_files"
}

# Run Gitleaks on specific files
run_gitleaks_scan() {
  local files=("$@")

  if [[ ${#files[@]} -eq 0 ]]; then
    log_info "No files to scan for secrets"
    return 0
  fi

  log_info "Scanning ${#files[@]} files for secrets with Gitleaks"
  log_info "Files: ${files[*]}"

  # Create Gitleaks config if not exists
  if [[ ! -f "$PROJECT_ROOT/.gitleaks.toml" ]]; then
    log_info "Creating Gitleaks configuration for pre-commit hook"
    cat > "$PROJECT_ROOT/.gitleaks.toml" << EOF
# Gitleaks configuration for pre-commit hook
title = "Pre-commit Secret Scanning"

[allowlist]
description = "Allow common development patterns"
paths = [
  # Allow example passwords for testing
  '''example-password''',
  '''test-secret''',
  '''dummy-key''',
  # Allow localhost patterns
  '''localhost''',
  '''127\.0\.0\.1''',
  '''0\.0\.0\.0''',
  # Allow common development ports
  ''':3000''',
  ''':8080''',
  ''':5432''',
  # Allow example patterns
  '''xxx''',
  '''yyy''',
  '''zzz''',
]
EOF
  fi

  # Run Gitleaks on the specified files
  local gitleaks_args=(
    "detect"
    "--config" "$PROJECT_ROOT/.gitleaks.toml"
    "--no-banner"
    "--verbose"
  )

  # Add each file to the scan
  for file in "${files[@]}"; do
    gitleks_args+=("$file")
  done

  log_debug "Running: gitleaks ${gitleks_args[*]}"

  if gitleaks "${gitleaks_args[@]}"; then
    log_success "✅ No secrets detected in staged files"
    return 0
  else
    log_error "❌ Gitleaks detected potential secrets in staged files"
    log_error "Commit blocked for security reasons"
    log_error ""
    log_error "To fix:"
    log_error "1. Review the detected secrets above"
    log_error "2. Remove or replace the secrets with environment variables"
    log_error "3. Add the patterns to .gitleaks.toml if they are false positives"
    log_error "4. Re-stage your changes and commit again"
    return 1
  fi
}

# Scan specific file type patterns
scan_file_patterns() {
  local patterns=("$@")

  local all_files=()
  local found_files=false

  # Find files matching patterns
  for pattern in "${patterns[@]}"; do
    local files
    files=$(git diff --cached --name-only --diff-filter=ACM | grep -E "$pattern" || true)

    if [[ -n "$files" ]]; then
      found_files=true
      while IFS= read -r file; do
        all_files+=("$file")
      done <<< "$files"
    fi
  done

  if [[ "$found_files" == "false" ]]; then
    log_info "No files found matching patterns: ${patterns[*]}"
    return 0
  fi

  log_info "Found files matching patterns: ${patterns[*]}"
  run_gitleaks_scan "${all_files[@]}"
}

# Scan for common secret file patterns
scan_common_secret_patterns() {
  log_info "Scanning for common secret file patterns"

  # Define patterns for files that commonly contain secrets
  local secret_patterns=(
    '.*\.env$'
    '.*\.ini$'
    '.*\.cfg$'
    '.*\.conf$'
    '.*\.key$'
    '.*\.pem$'
    '.*\.p12$'
    '.*\.pfx$'
    '.*\.crt$'
    '.*\.der$'
    '.*\.jks$'
    '.*\.keystore$'
    '.*\.store$'
    '.*\.p8$'
    '.*\.json$'
    '.*\.yaml$'
    '.*\.yml$'
    '.*\.toml$'
  )

  scan_file_patterns "${secret_patterns[@]}"
}

# Scan for script files that might contain hardcoded secrets
scan_script_files() {
  log_info "Scanning script files for hardcoded secrets"

  # Define patterns for script files
  local script_patterns=(
    '.*\.sh$'
    '.*\.bash$'
    '.*\.zsh$'
    '.*\.fish$'
    '.*\.py$'
    '.*\.js$'
    '.*\.ts$'
    '.*\.php$'
    '.*\.rb$'
    '.*\.go$'
    '.*\.java$'
    '.*\.cs$'
    '.*\.vb$'
    '.*\.ps1$'
    '.*\.psm1$'
    '.*\.sql$'
  )

  scan_file_patterns "${script_patterns[@]}"
}

# Quick scan for obvious secret patterns
quick_secret_scan() {
  local files=("$@")

  if [[ ${#files[@]} -eq 0 ]]; then
    return 0
  fi

  log_info "Performing quick secret pattern check"

  local found_secrets=false
  local secret_patterns=(
    'AKIA[0-9A-Z]{16}'
    'sk-[0-9a-zA-Z]{48}'
    'ghp_[0-9a-zA-Z]{36}'
    'glpat-[0-9a-zA-Z]{27}'
    'xoxb-[0-9a-zA-Z]{46}'
  )

  for file in "${files[@]}"; do
    if [[ ! -f "$file" ]]; then
      continue
    fi

    while IFS= read -r line; do
      for pattern in "${secret_patterns[@]}"; do
        if [[ "$line" =~ $pattern ]]; then
          log_error "❌ Potential secret found in $file:"
          log_error "  Pattern: $pattern"
          log_error "  Line: $line"
          log_error "  Position: $(awk -v var="$pattern" 'BEGIN {print index($var, $line)}' <<< "$line")"
          found_secrets=true
          break 2
        fi
      done
      if [[ "$found_secrets" == "true" ]]; then
        break 1
      fi
    done < "$file"

    if [[ "$found_secrets" == "true" ]]; then
      break
    fi
  done

  if [[ "$found_secrets" == "true" ]]; then
    log_error "❌ Quick secret scan detected potential secrets"
    log_error "Commit blocked for security reasons"
    return 1
  fi
}

# Generate pre-commit report
generate_report() {
  local scanned_files="${1:-0}"
  local scan_duration="${2:-0}"
  local status="${3:-success}"

  # Create pre-commit report directory
  local report_dir="$PROJECT_ROOT/.github/pre-commit-reports"
  mkdir -p "$report_dir"

  local report_file="$report_dir/secret-scan-$(date +%Y%m%d-%H%M%S).md"

  cat > "$report_file" << EOF
# 🔍 Pre-commit Secret Scan Report

**Generated**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**Gitleaks Version**: $(get_gitleaks_version)
**Files Scanned**: $scanned_files
**Scan Duration**: ${scan_duration}s
**Status**: $status

## 📋 Summary

EOF

  if [[ "$status" == "success" ]]; then
    cat >> "$report_file" << EOF
✅ **Pre-commit secret scan passed**
- No secrets detected in staged files
- Safe to proceed with commit

EOF
  else
    cat >> "$report_file" << EOF
❌ **Pre-commit secret scan failed**
- Potential secrets detected in staged files
- Commit blocked for security reasons

## 🛠️ Next Steps

1. Review the Gitleaks output above for specific issues
2. Remove or replace detected secrets with environment variables
3. Add false positives to .gitleaks.toml if needed
4. Re-stage your changes and commit again

## 📚 Resources

- [Gitleaks Documentation](https://github.com/gitleaks/gitleaks)
- [Secret Management Best Practices](https://docs.github.com/en/code-security/secret-scanning/keeping-secrets-and-credentials-out-of-your-repository)

EOF
  fi

  cat >> "$report_file" << EOF

---
*This report was generated by the pre-commit secret scan hook*
EOF

  log_info "Pre-commit report generated: $report_file"
}

# Main execution
main() {
  local behavior
  behavior=$(get_behavior_mode)

  local start_time
  start_time=$(date +%s)

  local overall_success=true

  log_info "Pre-commit Secret Scan Hook v$PRE_COMMIT_SECRET_SCAN_VERSION"

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would scan staged files for secrets"
      return 0
      ;;
    "PASS")
      log_success "PASS MODE: Pre-commit secret scan simulated successfully"
      return 0
      ;;
    "FAIL")
      log_error "FAIL MODE: Simulating pre-commit secret scan failure"
      return 1
      ;;
    "SKIP")
      log_info "SKIP MODE: Pre-commit secret scan skipped"
      return 0
      ;;
    "TIMEOUT")
      log_info "TIMEOUT MODE: Simulating pre-commit secret scan timeout"
      sleep 5
      return 124
      ;;
  esac

  # EXECUTE mode - Actual secret scanning
  log_info "Starting pre-commit secret scan"

  # Validate requirements
  if ! check_gitleaks_available; then
    exit 1
  fi

  if ! validate_git_repository; then
    exit 1
  fi

  # Get staged files
  local staged_files
  staged_files=$(get_staged_files)

  local scanned_files=0
  local scan_duration=0

  if [[ -n "$staged_files" ]]; then
    # Convert to array
    local files_array=()
    while IFS= read -r line; do
      files_array+=("$line")
      scanned_files=$((scanned_files + 1))
    done <<< "$staged_files"

    log_info "Found $scanned_files staged files to scan"

    # Perform different types of scans

    # Quick pattern check first (fast)
    if ! quick_secret_scan "${files_array[@]}"; then
      overall_success=false
    fi

    # Full Gitleaks scan
    if ! run_gitleaks_scan "${files_array[@]}"; then
      overall_success=false
    fi

    # Additional pattern-based scans
    if ! scan_common_secret_patterns; then
      overall_success=false
    fi

    if ! scan_script_files; then
      overall_success=false
    fi

    if [[ "$overall_success" == "true" ]]; then
      local status="success"
    else
      local status="failure"
    fi

    # Calculate duration
    local end_time
    end_time=$(date +%s)
    scan_duration=$((end_time - start_time))

    # Generate report
    generate_report "$scanned_files" "$scan_duration" "$status"
  else
    log_info "No staged files to scan"
    generate_report "0" "0" "success"
  fi

  if [[ "$overall_success" == "true" ]]; then
    log_success "✅ Pre-commit secret scan completed successfully"
    return 0
  else
    log_error "❌ Pre-commit secret scan failed"
    return 1
  fi
}

# CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Parse command line arguments
  case "${1:-}" in
    "help"|"--help"|"-h")
      cat << EOF
Pre-commit Secret Scan Hook v$PRE_COMMIT_SECRET_SCAN_VERSION

This hook scans staged files for secrets using Gitleaks before allowing commits.

Usage:
  Used as a git pre-commit hook via Lefthook configuration

Configuration:
  Add to .lefthook.yml:
    pre-commit:
      commands:
        secret-scan:
          run: ./scripts/hooks/pre-commit-secret-scan.sh
          tags: [security, secrets]

Environment Variables:
  PRE_COMMIT_SECRET_SCAN_MODE  EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT
  CI_TEST_MODE                 Global testability mode

Security Patterns Scanned:
- API keys (AWS, GitHub, etc.)
- Database passwords and connection strings
- SSH private keys and certificates
- Environment files (.env, .ini, .cfg, etc.)
- Configuration files with sensitive data
- Script files with hardcoded secrets

Examples:
  # Automatic usage via git commit
  git add . && git commit -m "Add feature"

  # Manual testing
  ./scripts/hooks/pre-commit-secret-scan.sh help

Testability:
  CI_TEST_MODE=DRY_RUN ./scripts/hooks/pre-commit-secret-scan.sh
  PRE_COMMIT_SECRET_SCAN_MODE=FAIL ./scripts/hooks/pre-commit-secret-scan.sh

Integration:
  This hook integrates with:
  - Lefthook for pre-commit hook management
  - ShellSpec for testing hook behavior
  - GitHub Actions for CI pipeline security scanning
EOF
      exit 0
      ;;
    "scan")
      # Manual scanning mode
      if [[ $# -lt 1 ]]; then
        echo "Usage: $0 scan <file1> [file2] ..."
        exit 1
      fi
      shift
      run_gitleaks_scan "$@"
      exit $?
      ;;
    "quick")
      # Quick scan mode
      if [[ $# -lt 1 ]]; then
        echo "Usage: $0 quick <file1> [file2] ..."
        exit 1
      fi
      shift
      quick_secret_scan "$@"
      exit $?
      ;;
    "validate")
      # Validation mode for testing
      echo "Validating pre-commit hook setup..."
      check_gitleaks_available
      validate_git_repository
      echo "✅ Pre-commit hook validation completed"
      ;;
    *)
      main "$@"
      ;;
  esac
fi