#!/usr/bin/env bash
# CI Security Scan Script
# Runs comprehensive security scanning with Gitleaks and Trufflehog

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

# Get script and pipeline names for testability
SCRIPT_NAME=$(get_script_name "$0")
PIPELINE_NAME=$(get_pipeline_name)
MODE=$(resolve_test_mode "$SCRIPT_NAME" "$PIPELINE_NAME")

log_test_mode_source "$SCRIPT_NAME" "$PIPELINE_NAME" "$MODE"

# Configuration
GITLEAKS_CONFIG="${GITLEAKS_CONFIG:-.gitleaks.toml}"
TRUFFLEHOG_CONFIG="${TRUFFLEHOG_CONFIG:-.trufflehog.yaml}"
EXCLUDE_PATTERNS="${EXCLUDE_PATTERNS:-*.min.js,*.min.css,node_modules/*,.git/*,coverage/*,test-results/*}"

# Security scan report output
REPORT_DIR="security-scan-results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${REPORT_DIR}/security-scan-report-${TIMESTAMP}.json"

# Create report directory
create_report_dir() {
  mkdir -p "$REPORT_DIR"
  log_info "Created security scan report directory: $REPORT_DIR"
}

# Run Gitleaks scan
run_gitleaks() {
  log_info "Running Gitleaks secret scanning"

  local gitleaks_report="${REPORT_DIR}/gitleaks-report-${TIMESTAMP}.json"

  # Build exclude patterns
  local exclude_args=()
  if [[ -n "$EXCLUDE_PATTERNS" ]]; then
    IFS=',' read -ra patterns <<< "$EXCLUDE_PATTERNS"
    for pattern in "${patterns[@]}"; do
      exclude_args+=("--exclude-path=$pattern")
    done
  fi

  # Run Gitleaks
  local gitleaks_cmd=("gitleaks" "detect" "--redact" "--verbose" "--no-banner" "--report-path" "$gitleaks_report" "--report-format" "json")
  gitleaks_cmd+=("${exclude_args[@]}")

  log_info "Gitleaks command: ${gitleaks_cmd[*]}"

  if "${gitleaks_cmd[@]}" 2>/dev/null; then
    log_success "Gitleaks scan completed - no secrets found"
    echo '{"status": "success", "findings": 0, "report_file": "'"$gitleaks_report"'"}' > "${REPORT_DIR}/gitleaks-result.json"
  else
    local exit_code=$?
    log_warning "Gitleaks scan completed with findings or warnings (exit code: $exit_code)"

    # Check if report file was created
    if [[ -f "$gitleaks_report" ]]; then
      local findings_count
      findings_count=$(jq '.findings | length' "$gitleaks_report" 2>/dev/null || echo "0")
      log_warning "Gitleaks found $findings_count potential secrets"
      echo '{"status": "findings", "findings": '$findings_count', "report_file": "'"$gitleaks_report"'"}' > "${REPORT_DIR}/gitleaks-result.json"
    else
      log_error "Gitleaks scan failed to create report"
      echo '{"status": "failed", "findings": 0, "error": "Failed to create report"}' > "${REPORT_DIR}/gitleaks-result.json"
    fi
  fi
}

# Run Trufflehog scan
run_trufflehog() {
  log_info "Running Trufflehog secret scanning"

  local trufflehog_report="${REPORT_DIR}/trufflehog-report-${TIMESTAMP}.json"

  # Build exclude patterns
  local exclude_args=()
  if [[ -n "$EXCLUDE_PATTERNS" ]]; then
    IFS=',' read -ra patterns <<< "$EXCLUDE_PATTERNS"
    for pattern in "${patterns[@]}"; do
      exclude_args+=("--exclude-paths=$pattern")
    done
  fi

  # Determine scan base commit
  local base_commit
  if [[ -n "${GITHUB_BASE_REF:-}" ]]; then
    # For pull requests, scan from the base branch
    base_commit="origin/${GITHUB_BASE_REF}"
  elif [[ -n "${GITHUB_BEFORE:-}" && "$GITHUB_BEFORE" != "0000000000000000000000000000000000000000" ]]; then
    # For pushes, scan from the previous commit
    base_commit="$GITHUB_BEFORE"
  else
    # Fallback to last 100 commits
    base_commit="HEAD~100"
  fi

  # Run Trufflehog
  local trufflehog_cmd=("trufflehog" "git" "file://." "--since-commit" "$base_commit" "--only-verified" "--json" "--output" "$trufflehog_report")
  trufflehog_cmd+=("${exclude_args[@]}")

  log_info "Trufflehog command: ${trufflehog_cmd[*]}"
  log_info "Scanning from commit: $base_commit"

  if "${trufflehog_cmd[@]}" 2>/dev/null; then
    log_success "Trufflehog scan completed - no secrets found"
    echo '{"status": "success", "findings": 0, "report_file": "'"$trufflehog_report"'"}' > "${REPORT_DIR}/trufflehog-result.json"
  else
    local exit_code=$?
    log_warning "Trufflehog scan completed with findings or warnings (exit code: $exit_code)"

    # Check if report file was created and has findings
    if [[ -f "$trufflehog_report" ]]; then
      local findings_count
      findings_count=$(jq 'length' "$trufflehog_report" 2>/dev/null || echo "0")
      log_warning "Trufflehog found $findings_count potential secrets"
      echo '{"status": "findings", "findings": '$findings_count', "report_file": "'"$trufflehog_report"'"}' > "${REPORT_DIR}/trufflehog-result.json"
    else
      log_error "Trufflehog scan failed to create report"
      echo '{"status": "failed", "findings": 0, "error": "Failed to create report"}' > "${REPORT_DIR}/trufflehog-result.json"
    fi
  fi
}

# Run npm audit for Node.js projects
run_npm_audit() {
  if [[ ! -f "package.json" ]]; then
    log_info "No package.json found, skipping npm audit"
    return 0
  fi

  log_info "Running npm audit for dependency vulnerabilities"

  local npm_report="${REPORT_DIR}/npm-audit-report-${TIMESTAMP}.json"

  # Run npm audit with JSON output
  if npm audit --json > "$npm_report" 2>/dev/null; then
    log_success "npm audit completed - no vulnerabilities found"
    echo '{"status": "success", "vulnerabilities": 0, "report_file": "'"$npm_report"'"}' > "${REPORT_DIR}/npm-result.json"
  else
    local exit_code=$?
    log_warning "npm audit completed with vulnerabilities (exit code: $exit_code)"

    if [[ -f "$npm_report" ]]; then
      local vuln_count
      vuln_count=$(jq '.vulnerabilities | length' "$npm_report" 2>/dev/null || echo "0")
      local high_vuln_count
      high_vuln_count=$(jq '.metadata.vulnerabilities.total' "$npm_report" 2>/dev/null || echo "0")

      log_warning "npm found $vuln_count total vulnerabilities ($high_vuln_count high severity)"
      echo '{"status": "vulnerabilities", "vulnerabilities": '$vuln_count', "high_vulnerabilities": '$high_vuln_count', "report_file": "'"$npm_report"'"}' > "${REPORT_DIR}/npm-result.json"
    else
      log_error "npm audit failed to create report"
      echo '{"status": "failed", "vulnerabilities": 0, "error": "Failed to create report"}' > "${REPORT_DIR}/npm-result.json"
    fi
  fi
}

# Check for hardcoded credentials in configuration files
check_hardcoded_credentials() {
  log_info "Checking for hardcoded credentials in configuration files"

  local credential_report="${REPORT_DIR}/credential-check-report-${TIMESTAMP}.json"
  local findings=()

  # Common patterns that might indicate hardcoded credentials
  local patterns=(
    "password\s*=\s*['\"][^'\"]{8,}['\"]"
    "secret\s*=\s*['\"][^'\"]{8,}['\"]"
    "key\s*=\s*['\"][^'\"]{8,}['\"]"
    "token\s*=\s*['\"][^'\"]{8,}['\"]"
    "api[_-]?key\s*=\s*['\"][^'\"]{8,}['\"]"
    "auth[_-]?token\s*=\s*['\"][^'\"]{8,}['\"]"
    "private[_-]?key\s*=\s*['\"][^'\"]{8,}['\"]"
    "aws[_-]?access[_-]?key\s*=\s*['\"][^'\"]{8,}['\"]"
    "aws[_-]?secret[_-]?key\s*=\s*['\"][^'\"]{8,}['\"]"
    "db[_-]?password\s*=\s*['\"][^'\"]{8,}['\"]"
    "database[_-]?url\s*=\s*['\"][^'\"]+://[^:]+:[^@]+@['\"]"
    "connection[_-]?string\s*=\s*['\"][^'\"]+://[^:]+:[^@]+@['\"]"
  )

  # Files to check (excluding node_modules, .git, etc.)
  local files_to_check=()
  while IFS= read -r -d '' file; do
    # Skip binary files and excluded directories
    if file -b --mime-type "$file" 2>/dev/null | grep -q "text/"; then
      if [[ ! "$file" =~ ^(node_modules|\.git|coverage|test-results|dist|build)/ ]]; then
        files_to_check+=("$file")
      fi
    fi
  done < <(find . -type f \( -name "*.js" -o -name "*.ts" -o -name "*.json" -o -name "*.yml" -o -name "*.yaml" -o -name "*.env*" -o -name "*.config" -o -name "*.conf" \) -print0)

  # Check each file for patterns
  for file in "${files_to_check[@]}"; do
    for pattern in "${patterns[@]}"; do
      if grep -E "$pattern" "$file" >/dev/null 2>&1; then
        local line_number
        line_number=$(grep -n -E "$pattern" "$file" | head -1 | cut -d: -f1)
        local matched_line
        matched_line=$(grep -E "$pattern" "$file" | head -1)
        findings+=("{\"file\": \"$file\", \"line\": $line_number, \"pattern\": \"$pattern\", \"match\": \"$matched_line\"}")
      fi
    done
  done

  # Create report
  local findings_count=${#findings[@]}
  if [[ $findings_count -gt 0 ]]; then
    log_warning "Found $findings_count potential hardcoded credentials"
    echo '{"status": "findings", "findings": '$findings_count', "details": ['$(IFS=','; echo "${findings[*]}")']}' > "$credential_report"
  else
    log_success "No hardcoded credentials found"
    echo '{"status": "success", "findings": 0}' > "$credential_report"
  fi
}

# Generate comprehensive security report
generate_security_report() {
  log_info "Generating comprehensive security report"

  local gitleaks_result="${REPORT_DIR}/gitleaks-result.json"
  local trufflehog_result="${REPORT_DIR}/trufflehog-result.json"
  local npm_result="${REPORT_DIR}/npm-result.json"
  local credential_result="${REPORT_DIR}/credential-check-report.json"

  local gitleaks_findings=0
  local trufflehog_findings=0
  local npm_vulnerabilities=0
  local npm_high_vuln=0
  local credential_findings=0

  # Extract results
  if [[ -f "$gitleaks_result" ]]; then
    gitleaks_findings=$(jq -r '.findings // 0' "$gitleaks_result" 2>/dev/null || echo "0")
  fi

  if [[ -f "$trufflehog_result" ]]; then
    trufflehog_findings=$(jq -r '.findings // 0' "$trufflehog_result" 2>/dev/null || echo "0")
  fi

  if [[ -f "$npm_result" ]]; then
    npm_vulnerabilities=$(jq -r '.vulnerabilities // 0' "$npm_result" 2>/dev/null || echo "0")
    npm_high_vuln=$(jq -r '.high_vulnerabilities // 0' "$npm_result" 2>/dev/null || echo "0")
  fi

  if [[ -f "$credential_result" ]]; then
    credential_findings=$(jq -r '.findings // 0' "$credential_result" 2>/dev/null || echo "0")
  fi

  # Create summary report
  cat > "$REPORT_FILE" <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "scan_duration": "${SCAN_DURATION:-unknown}",
  "repository": "${GITHUB_REPOSITORY:-unknown}",
  "branch": "${GITHUB_REF_NAME:-unknown}",
  "commit": "${GITHUB_SHA:-unknown}",
  "workflow": "${GITHUB_WORKFLOW:-unknown}",
  "total_findings": $((gitleaks_findings + trufflehog_findings + credential_findings)),
  "total_vulnerabilities": $npm_vulnerabilities,
  "high_vulnerabilities": $npm_high_vuln,
  "gitleaks": {
    "findings": $gitleaks_findings,
    "status": "$(jq -r '.status // "unknown"' "$gitleaks_result" 2>/dev/null || echo "unknown")"
  },
  "trufflehog": {
    "findings": $trufflehog_findings,
    "status": "$(jq -r '.status // "unknown"' "$trufflehog_result" 2>/dev/null || echo "unknown")"
  },
  "npm_audit": {
    "vulnerabilities": $npm_vulnerabilities,
    "high_vulnerabilities": $npm_high_vuln,
    "status": "$(jq -r '.status // "unknown"' "$npm_result" 2>/dev/null || echo "unknown")"
  },
  "credential_check": {
    "findings": $credential_findings,
    "status": "$(jq -r '.status // "unknown"' "$credential_result" 2>/dev/null || echo "unknown")"
  },
  "recommendations": [
    "Use environment variables for secrets and credentials",
    "Rotate any exposed keys or tokens immediately",
    "Enable dependency scanning in your CI/CD pipeline",
    "Review and patch high-severity vulnerabilities",
    "Consider using secret scanning tools in your development workflow"
  ]
}
EOF

  # Log summary
  log_info "Security Scan Summary:"
  log_info "  - Gitleaks findings: $gitleaks_findings"
  log_info "  - Trufflehog findings: $trufflehog_findings"
  log_info "  - Hardcoded credentials: $credential_findings"
  log_info "  - npm vulnerabilities: $npm_vulnerabilities ($npm_high_vuln high severity)"
  log_info "  - Total security findings: $((gitleaks_findings + trufflehog_findings + credential_findings))"
}

# Determine overall security status
determine_security_status() {
  local gitleaks_result="${REPORT_DIR}/gitleaks-result.json"
  local trufflehog_result="${REPORT_DIR}/trufflehog-result.json"
  local npm_result="${REPORT_DIR}/npm-result.json"
  local credential_result="${REPORT_DIR}/credential-check-report.json"

  local has_critical_issues=false

  # Check for critical security findings
  if [[ -f "$gitleaks_result" ]]; then
    local status
    status=$(jq -r '.status // "unknown"' "$gitleaks_result" 2>/dev/null || echo "unknown")
    if [[ "$status" == "findings" ]]; then
      has_critical_issues=true
    fi
  fi

  if [[ -f "$trufflehog_result" ]]; then
    local status
    status=$(jq -r '.status // "unknown"' "$trufflehog_result" 2>/dev/null || echo "unknown")
    if [[ "$status" == "findings" ]]; then
      has_critical_issues=true
    fi
  fi

  if [[ -f "$credential_result" ]]; then
    local findings
    findings=$(jq -r '.findings // 0' "$credential_result" 2>/dev/null || echo "0")
    if [[ $findings -gt 0 ]]; then
      has_critical_issues=true
    fi
  fi

  # Exit with appropriate code
  if [[ "$has_critical_issues" == "true" ]]; then
    log_error "Security scan failed: Critical issues found"
    return 1
  else
    log_success "Security scan passed: No critical issues found"
    return 0
  fi
}

# Main execution function
main() {
  local start_time
  start_time=$(date +%s)

  log_info "Starting comprehensive security scan"

  # Execute based on test mode
  case "$MODE" in
    DRY_RUN)
      log_info "Dry run: would run comprehensive security scan"
      log_info "Would execute: Gitleaks scan, Trufflehog scan, npm audit, credential check"
      exit 0
      ;;
    PASS)
      log_info "Simulated security scan success"
      exit 0
      ;;
    FAIL)
      log_error "Simulated security scan failure"
      exit 1
      ;;
    SKIP)
      log_info "Skipping security scan"
      exit 0
      ;;
    TIMEOUT)
      log_warning "Simulating security scan timeout"
      sleep infinity
      ;;
    EXECUTE)
      # Continue with normal execution
      ;;
    *)
      log_error "Unknown test mode: $MODE"
      exit 1
      ;;
  esac

  # Create report directory
  create_report_dir

  # Run all security scans
  run_gitleaks
  run_trufflehog
  run_npm_audit
  check_hardcoded_credentials

  # Generate comprehensive report
  generate_security_report

  # Calculate scan duration
  local end_time
  end_time=$(date +%s)
  SCAN_DURATION=$((end_time - start_time))
  log_info "Security scan completed in $(format_duration "$SCAN_DURATION")"

  # Determine overall status and exit appropriately
  determine_security_status
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi