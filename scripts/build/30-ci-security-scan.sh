#!/bin/bash
# CI Security Scan Script
# Performs comprehensive secret scanning using Gitleaks, Trufflehog, and detect-secrets

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common utilities" >&2
  exit 1
}

# Configuration
readonly SECURITY_SCAN_VERSION="1.0.0"
readonly SECURITY_REPORT_DIR="${GITHUB_WORKSPACE:-$PROJECT_ROOT}/.github/security-reports"

# Testability configuration
get_behavior_mode() {
  local script_name="security_scan"
  get_script_behavior "$script_name" "EXECUTE"
}

# Security scan settings
get_security_config() {
  # Severity levels: error, warning, info
  local severity="${SECURITY_SCAN_SEVERITY:-error}"

  # Scan scope: all, staged, committed, filesystem
  local scope="${SECURITY_SCAN_SCOPE:-all}"

  # Output formats: json, sarif, text
  local format="${SECURITY_SCAN_FORMAT:-json}"

  # Enable/disable specific scanners
  local enable_gitleaks="${ENABLE_GITLEAKS:-true}"
  local enable_trufflehog="${ENABLE_TRUFFLEHOG:-true}"
  local enable_detect_secrets="${ENABLE_DETECT_SECRETS:-true}"
  local enable_shhgit="${ENABLE_SHHGIT:-false}"

  echo "$severity|$scope|$format|$enable_gitleaks|$enable_trufflehog|$enable_detect_secrets|$enable_shhgit"
}

# Check if security scanning tools are available
validate_security_tools() {
  local available_tools=()
  local missing_tools=()

  log_info "Validating security scanning tools"

  if [[ "${GITLEAKS_ENABLED:-true}" == "true" ]]; then
    if command -v gitleaks >/dev/null 2>&1; then
      available_tools+=("gitleaks")
      log_success "✓ Gitleaks is available: $(gitleaks --version 2>/dev/null || echo 'version unknown')"
    else
      missing_tools+=("gitleaks")
      log_error "❌ Gitleaks is not installed"
    fi
  fi

  if [[ "${TRUFFLEHOG_ENABLED:-true}" == "true" ]]; then
    if command -v trufflehog >/dev/null 2>&1; then
      available_tools+=("trufflehog")
      log_success "✓ Trufflehog is available: $(trufflehog --version 2>/dev/null || echo 'version unknown')"
    else
      missing_tools+=("trufflehog")
      log_error "❌ Trufflehog is not installed"
    fi
  fi

  if [[ "${DETECT_SECRETS_ENABLED:-true}" == "true" ]]; then
    if command -v detect-secrets >/dev/null 2>&1; then
      available_tools+=("detect-secrets")
      log_success "✓ Detect-secrets is available: $(detect-secrets --version 2>/dev/null || echo 'version unknown')"
    else
      missing_tools+=("detect-secrets")
      log_error "❌ Detect-secrets is not installed"
    fi
  fi

  if [[ "${SHHGIT_ENABLED:-false}" == "true" ]]; then
    if command -v shhgit >/dev/null 2>&1; then
      available_tools+=("shhgit")
      log_success "✓ Shhgit is available"
    else
      missing_tools+=("shhgit")
      log_error "❌ Shhgit is not installed"
    fi
  fi

  if [[ ${#missing_tools[@]} -gt 0 ]]; then
    log_warn "⚠️  Optional security tools not available: ${missing_tools[*]}"
    log_warn "   Install missing tools or disable them via environment variables"
  fi

  if [[ ${#available_tools[@]} -eq 0 ]]; then
    log_error "❌ No security tools are available"
    return 1
  fi

  log_success "✅ Available security tools: ${available_tools[*]}"
  return 0
}

# Validate git repository
validate_git_repository() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    log_error "❌ Not in a git repository"
    return 1
  fi

  log_success "✅ Git repository validation passed"
  return 0
}

# Get git repository information
get_git_info() {
  local repo_url
  repo_url=$(git remote get-url origin 2>/dev/null || echo "unknown")

  log_info "Repository: $(git rev-parse --show-toplevel)"
  log_info "Remote URL: $repo_url"
  log_info "Current commit: $(git rev-parse HEAD 2>/dev/null || echo "unknown")"
  log_info "Branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"

  echo "repo_url=$repo_url"
}

# Run Gitleaks protect (prevent secrets in new commits)
run_gitleaks_protect() {
  if [[ "${GITLEAKS_ENABLED:-true}" != "true" ]]; then
    log_info "Gitleaks is disabled, skipping protect scan"
    return 0
  fi

  log_info "Running Gitleaks protect scan"

  local config
  config=$(get_security_config)
  local severity="${config%%|*}"

  # Create Gitleaks config if not exists
  if [[ ! -f "$PROJECT_ROOT/.gitleaks.toml" ]]; then
    log_info "Creating default Gitleaks configuration"
    cat > "$PROJECT_ROOT/.gitleaks.toml" << EOF
# Gitleaks configuration
title = "Gitleaks Configuration"

[allowlist]
description = "Global allowlist"
paths = [
  '''gitleaks:allow''',
  '''*password*''',
]

[[rules]]
description = "Allow pattern"
id = "gitleaks-allow"
regex = '''gitleaks:allow'''
EOF
  fi

  if gitleaks protect --config "$PROJECT_ROOT/.gitleaks.toml" --verbose; then
    log_success "✅ Gitleaks protect completed - no secrets detected"
  else
    log_error "❌ Gitleaks protect detected potential secrets"
    return 1
  fi
}

# Run Gitleaks detect (find existing secrets)
run_gitleaks_detect() {
  if [[ "${GITLEAKS_ENABLED:-true}" != "true" ]]; then
    log_info "Gitleaks is disabled, skipping detect scan"
    return 0
  fi

  log_info "Running Gitleaks detect scan"

  local config
  config=$(get_security_config)
  local format="${config#*#*|*|*}"

  # Create output directory
  mkdir -p "$SECURITY_REPORT_DIR"

  local report_file="$SECURITY_REPORT_DIR/gitleaks-report.$format"

  log_info "Gitleaks scan output: $report_file"

  if gitleaks detect \
    --config "$PROJECT_ROOT/.gitleaks.toml" \
    --verbose \
    --report-path "$report_file" \
    --report-format "$format"; then

    log_success "✅ Gitleaks detect completed - see report for details"
    return 0
  else
    local exit_code=$?
    log_error "❌ Gitleaks detect failed with exit code: $exit_code"

    # Extract summary information
    if [[ -f "$report_file" ]]; then
      log_info "Report generated at: $report_file"

      # Try to extract summary from JSON report
      if [[ "$format" == "json" ]]; then
        local secrets_found
        secrets_found=$(jq -r '.summary.secretsFound // 0' "$report_file" 2>/dev/null || echo "unknown")
        log_warn "⚠️ Gitleaks found $secrets_found potential secrets"
      fi
    fi

    return 1
  fi
}

# Run Trufflehog git scan
run_trufflehog_git_scan() {
  if [[ "${TRUFFLEHOG_ENABLED:-true}" != "true" ]]; then
    log_info "Trufflehog is disabled, skipping git scan"
    return 0
  fi

  log_info "Running Trufflehog git scan"

  # Create output directory
  mkdir -p "$SECURITY_REPORT_DIR"

  local report_file="$SECURITY_REPORT_DIR/trufflehog-report.json"

  log_info "Trufflehog scan output: $report_file"

  local trufflehog_args=(
    "git"
    "."
    "--only-verified"
    "--json"
    "--output" "$report_file"
  )

  if trufflehog "${trufflehog_args[@]}"; then
    log_success "✅ Trufflehog git scan completed - no verified secrets found"
    return 0
  else
    local exit_code=$?
    log_error "❌ Trufflehog git scan failed with exit code: $exit_code"

    # Extract summary from report
    if [[ -f "$report_file" ]]; then
      local secrets_count
      secrets_count=$(jq length "$report_file" 2>/dev/null || echo "unknown")
      log_warn "⚠️ Trufflehog found $secrets_count potential secrets"
    fi

    return 1
  fi
}

# Run Trufflehog filesystem scan
run_trufflehog_filesystem_scan() {
  if [[ "${TRUFFLEHOG_ENABLED:-true}" != "true" ]]; then
    log_info "Trufflehog is disabled, skipping filesystem scan"
    return 0
  fi

  log_info "Running Trufflehog filesystem scan"

  # Define scan patterns
  local scan_patterns=(
    "scripts/**/*.sh"
    "config/**/*.{json,yaml,yml,toml}"
    "src/**/*.{js,ts,py,php,rb,go,java}"
    "docs/**/*.{md,txt}"
    "*.{env,ini,cfg}"
  )

  local found_files=false
  local total_secrets=0

  for pattern in "${scan_patterns[@]}"; do
    if compgen -G "$pattern" >/dev/null 2>&1; then
      found_files=true
      log_info "Scanning pattern: $pattern"

      # Create temporary report for this pattern
      local temp_report
      temp_report=$(mktemp)

      local trufflehog_args=(
        "filesystem"
        "$pattern"
        "--json"
        "--output" "$temp_report"
      )

      if trufflehog "${trufflehog_args[@]}" 2>/dev/null; then
        local secrets_count
        secrets_count=$(jq length "$temp_report" 2>/dev/null || echo "0")
        total_secrets=$((total_secrets + secrets_count))
        log_info "✓ Scanned $pattern - no secrets found"
      else
        local secrets_count
        secrets_count=$(jq length "$temp_report" 2>/dev/null || echo "0")
        total_secrets=$((total_secrets + secrets_count))
        log_warn "⚠️ Found $secrets_count potential secrets in $pattern"

        # Merge into main report
        if [[ -f "$temp_report" ]]; then
          jq -s '.' "$temp_report" >> "$SECURITY_REPORT_DIR/trufflehog-filesystem-report.json" 2>/dev/null || true
        fi
      fi

      rm -f "$temp_report"
    else
      log_debug "No files found for pattern: $pattern"
    fi
  done

  if [[ "$found_files" == "false" ]]; then
    log_info "No files found to scan in filesystem"
    return 0
  fi

  if [[ $total_secrets -eq 0 ]]; then
    log_success "✅ Trufflehog filesystem scan completed - no secrets found"
  else
    log_error "❌ Trufflehog filesystem scan found $total_secrets potential secrets"
    return 1
  fi
}

# Run detect-secrets scan
run_detect_secrets_scan() {
  if [[ "${DETECT_SECRETS_ENABLED:-true}" != "true" ]]; then
    log_info "Detect-secrets is disabled, skipping scan"
    return 0
  fi

  log_info "Running detect-secrets scan"

  # Create output directory
  mkdir -p "$SECURITY_REPORT_DIR"

  local baseline_file="$PROJECT_ROOT/.secrets.baseline"
  local report_file="$SECURITY_REPORT_DIR/detect-secrets-report.json"

  # Create baseline if it doesn't exist
  if [[ ! -f "$baseline_file" ]]; then
    log_info "Creating detect-secrets baseline"
    if detect-secrets scan --all-files --baseline "$baseline_file" >/dev/null 2>&1; then
      log_success "✅ Created detect-secrets baseline with $(jq length "$baseline_file" 2>/dev/null || echo "unknown") patterns"
    else
      log_warn "⚠️ Failed to create detect-secrets baseline"
    fi
  fi

  if [[ -f "$baseline_file" ]]; then
    log_info "Scanning with baseline: $baseline_file"

    if detect-secrets scan --baseline "$baseline_file" --all-files > "$report_file" 2>&1; then
      log_success "✅ Detect-secrets scan completed - no new secrets detected"
      return 0
    else
      log_error "❌ Detect-secrets scan found new potential secrets"
      log_info "Report generated at: $report_file"
      return 1
    fi
  else
    log_warn "⚠️ No baseline file found, running full scan"

    if detect-secrets scan --all-files > "$report_file" 2>&1; then
      log_success "✅ Detect-secrets full scan completed - no secrets detected"
      return 0
    else
      log_error "❌ Detect-secrets full scan found potential secrets"
      log_info "Report generated at: $report_file"
      return 1
    fi
  fi
}

# Run shhgit scan
run_shhgit_scan() {
  if [[ "${SHHGIT_ENABLED:-false}" != "true" ]]; then
    log_info "Shhgit is disabled, skipping scan"
    return 0
  fi

  log_info "Running Shhgit scan"

  # Create output directory
  mkdir -p "$SECURITY_REPORT_DIR"

  if shhgit --no-metadata 2>/dev/null > "$SECURITY_REPORT_DIR/shhgit-report.txt"; then
    log_success "✅ Shhgit scan completed - no secrets found"
    return 0
  else
    log_error "❌ Shhgit scan found potential secrets"
    return 1
  fi
}

# Run security scan with specified scope
run_security_scan() {
  local scope="${1:-all}"
  local config
  config=$(get_security_config)
  local severity="${config%%|*}"
  local scan_scope="${config#*|*|*}"

  log_info "Starting comprehensive security scan (scope: $scope, severity: $severity)"

  local overall_success=true
  local scan_results=()

  # Always run Gitleaks protect first
  if ! run_gitleaks_protect; then
    scan_results+=("gitleaks-protect: failed")
    overall_success=false
  else
    scan_results+=("gitleaks-protect: success")
  fi

  case "$scope" in
    "all")
      # Run all scanners
      if ! run_gitleaks_detect; then
        scan_results+=("gitleaks-detect: failed")
        overall_success=false
      else
        scan_results+=("gitleaks-detect: success")
      fi

      if ! run_trufflehog_git_scan; then
        scan_results+=("trufflehog-git: failed")
        overall_success=false
      else
        scan_results+=("trufflehog-git: success")
      fi

      if ! run_trufflehog_filesystem_scan; then
        scan_results+=("trufflehog-filesystem: failed")
        overall_success=false
      else
        scan_results+=("trufflehog-filesystem: success")
      fi

      if ! run_detect_secrets_scan; then
        scan_results+=("detect-secrets: failed")
        overall_success=false
      else
        scan_results+=("detect-secrets: success")
      fi

      if ! run_shhgit_scan; then
        scan_results+=("shhgit: failed")
        overall_success=false
      else
        scan_results+=("shhgit: success")
      fi
      ;;
    "gitleaks")
      if ! run_gitleaks_detect; then
        scan_results+=("gitleaks-detect: failed")
        overall_success=false
      else
        scan_results+=("gitleaks-detect: success")
      fi
      ;;
    "trufflehog")
      if ! run_trufflehog_git_scan; then
        scan_results+=("trufflehog-git: failed")
        overall_success=false
      else
        scan_results+=("trufflehog-git: success")
      fi
      ;;
    "detect-secrets")
      if ! run_detect_secrets_scan; then
        scan_results+=("detect-secrets: failed")
        overall_success=false
      else
        scan_results+=("detect-secrets: success")
      fi
      ;;
    "shhgit")
      if ! run_shhgit_scan; then
        scan_results+=("shhgit: failed")
        overall_success=false
      else
        scan_results+=("shhgit: success")
      fi
      ;;
    *)
      log_error "Unknown scan scope: $scope"
      log_info "Available scopes: all, gitleaks, trufflehog, detect-secrets, shhgit"
      overall_success=false
      ;;
  esac

  # Display scan results summary
  log_info "Security Scan Results:"
  for result in "${scan_results[@]}"; do
    log_info "  $result"
  done

  if [[ "$overall_success" == "true" ]]; then
    log_success "✅ Comprehensive security scan completed successfully"
    return 0
  else
    log_error "❌ Security scan completed with issues"
    return 1
  fi
}

# Generate comprehensive security summary
generate_security_summary() {
  local scope="${1:-all}"

  log_info "Generating security scan summary"

  # Create output directory
  mkdir -p "$SECURITY_REPORT_DIR"

  local summary_file="$SECURITY_REPORT_DIR/security-summary.md"

  cat > "$summary_file" << EOF
# 🔒 Security Scan Summary

**Generated**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**Scan Scope**: $scope
**Repository**: $(git remote get-url origin 2>/dev/null || echo "unknown")

## 📊 Scan Results

| Scanner | Status | Report File |
|---------|--------|------------|
EOF

  # Add scanner results to table
  local scanner_status

  if [[ "${GITLEAKS_ENABLED:-true}" == "true" ]]; then
    scanner_status="❌ Failed"
    if [[ -f "$SECURITY_REPORT_DIR/gitleaks-report.json" ]]; then
      local secrets_found
      secrets_found=$(jq -r '.summary.secretsFound // 0' "$SECURITY_REPORT_DIR/gitleaks-report.json" 2>/dev/null || echo "0")
      if [[ "$secrets_found" == "0" ]]; then
        scanner_status="✅ Passed"
      fi
    fi
    echo "| Gitleaks | $scanner_status | [gitleaks-report.json](gitleaks-report.json) |" >> "$summary_file"
  fi

  if [[ "${TRUFFLEHOG_ENABLED:-true}" == "true" ]]; then
    scanner_status="❌ Failed"
    if [[ -f "$SECURITY_REPORT_DIR/trufflehog-report.json" ]]; then
      local secrets_count
      secrets_count=$(jq length "$SECURITY_REPORT_DIR/trufflehog-report.json" 2>/dev/null || echo "0")
      if [[ "$secrets_count" == "0" ]]; then
        scanner_status="✅ Passed"
      fi
    fi
    echo "| Trufflehog (Git) | $scanner_status | [trufflehog-report.json](trufflehog-report.json) |" >> "$summary_file"
  fi

  if [[ "${DETECT_SECRETS_ENABLED:-true}" == "true" ]]; then
    scanner_status="❌ Failed"
    if [[ -f "$SECURITY_REPORT_DIR/detect-secrets-report.json" ]]; then
      # Check if report is empty or has findings
      local report_size
      report_size=$(stat -c%s "$SECURITY_REPORT_DIR/detect-secrets.json" 2>/dev/null || echo "0")
      if [[ "$report_size" -lt 50 ]]; then  # Empty or minimal report
        scanner_status="✅ Passed"
      fi
    fi
    echo "| Detect-secrets | $scanner_status | [detect-secrets-report.json](detect-secrets-report.json) |" >> "$summary_file"
  fi

  if [[ "${SHHGIT_ENABLED:-false}" == "true" ]]; then
    scanner_status="❌ Failed"
    if [[ -f "$SECURITY_REPORT_DIR/shhgit-report.txt" ]]; then
      if grep -q "No secrets found" "$SECURITY_REPORT_DIR/shhgit-report.txt"; then
        scanner_status="✅ Passed"
      fi
    fi
    echo "| Shhgit | $scanner_status | [shhgit-report.txt](shhgit-report.txt) |" >> "$summary_file"
  fi

  cat >> "$summary_file" << EOF

## 🔧 Tool Versions

EOF

  # Add tool versions
  if command -v gitleaks >/dev/null 2>&1; then
    echo "- **Gitleaks**: $(gitleaks --version 2>/dev/null || echo 'version unknown')" >> "$summary_file"
  fi

  if command -v trufflehog >/dev/null 2>&1; then
    echo "- **Trufflehog**: $(trufflehog --version 2>/dev/null || echo 'version unknown')" >> "$summary_file"
  fi

  if command -v detect-secrets >/dev/null 2>&1; then
    echo "- **Detect-secrets**: $(detect-secrets --version 2>/dev/null || echo 'version unknown')" >> "$summary_file"
  fi

  if command -v shhgit >/dev/null 2>&1; then
    echo "- **Shhgit**: $(shhgit --version 2>/dev/null || echo 'version unknown')" >> "$summary_file"
  fi

  log_success "Security scan summary generated: $summary_file"
}

# Main execution
main() {
  local scope="${1:-all}"
  local behavior
  behavior=$(get_behavior_mode)

  log_info "CI Security Scan Script v$SECURITY_SCAN_VERSION"
  log_info "Scan scope: $scope"

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would run security scan (scope: $scope)"
      return 0
      ;;
    "PASS")
      log_success "PASS MODE: Security scan simulated successfully"
      return 0
      ;;
    "FAIL")
      log_error "FAIL MODE: Simulating security scan failure"
      return 1
      ;;
    "SKIP")
      log_info "SKIP MODE: Security scan skipped"
      return 0
      ;;
    "TIMEOUT")
      log_info "TIMEOUT MODE: Simulating security scan timeout"
      sleep 5
      return 124
      ;;
  esac

  # EXECUTE mode - Actual security scanning
  # Create output directory
  mkdir -p "$SECURITY_REPORT_DIR"

  # Validate tools
  if ! validate_security_tools; then
    log_error "❌ Security tool validation failed"
    exit 1
  fi

  # Validate git repository
  if ! validate_git_repository; then
    log_error "❌ Git repository validation failed"
    exit 1
  fi

  # Get git information
  get_git_info

  # Run security scan
  if ! run_security_scan "$scope"; then
    log_error "❌ Security scan failed for scope: $scope"
    exit 1
  fi

  # Generate summary
  generate_security_summary "$scope"

  log_success "Security scan completed successfully"
}

# CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Parse command line arguments
  case "${1:-}" in
    "help"|"--help"|"-h")
      cat << EOF
CI Security Scan Script v$SECURITY_SCAN_VERSION

Usage: $0 [scope] [options]

Arguments:
  scope              Security scan scope (all, gitleaks, trufflehog, detect-secrets, shhgit)
                    Default: all

Options:
  --severity LEVEL   Minimum severity level (error, warning, info)
  --format FORMAT    Output format (json, sarif, text)
  --scope SCOPE      Scan scope (all, staged, committed, filesystem)
  --config CONFIG     Configuration file path

Environment Variables:
  SECURITY_SCAN_MODE    EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT
  CI_TEST_MODE          Global testability mode
  ENABLE_GITLEAKS     Enable/disable Gitleaks (default: true)
  ENABLE_TRUFFLEHOG   Enable/disable Trufflehog (default: true)
  ENABLE_DETECT_SECRETS Enable/disable detect-secrets (default: true)
  ENABLE_SHHGIT       Enable/disable Shhgit (default: false)
  SECURITY_SCAN_SEVERITY  Minimum severity level (default: error)
  SECURITY_SCAN_SCOPE     Scan scope (default: all)
  SECURITY_SCAN_FORMAT     Output format (default: json)
  GITLEAKS_ENABLED        DEPRECATED: use ENABLE_GITLEAKS
  TRUFFLEHOG_ENABLED     DEPRECATED: use ENABLE_TRUFFLEHOG
  DETECT_SECRETS_ENABLED  DEPRECATED: use ENABLE_DETECT_SECRETS
  SHHGIT_ENABLED         DEPRECATED: use ENABLE_SHHGIT

Examples:
  $0                          # Run all security scans
  $0 gitleaks                 # Run only Gitleaks
  $0 trufflehog               # Run only Trufflehog
  $0 detect-secrets           # Run only detect-secrets
  $0 --severity warning       # Include warnings in scan
  $0 --format sarif          # Generate SARIF format reports

Testability Examples:
  CI_TEST_MODE=DRY_RUN $0
  SECURITY_SCAN_MODE=FAIL $0 gitleaks
  PIPELINE_SCRIPT_SECURITY_SCAN_BEHAVIOR=SKIP $0 trufflehog
EOF
      exit 0
      ;;
    "validate")
      # Validation mode for testing
      if [[ $# -lt 2 ]]; then
        echo "Usage: $0 validate <tool> [options]"
        exit 1
      fi
      shift
      validate_security_tools "$@"
      exit $?
      ;;
    *)
      main "$@"
      ;;
  esac
fi