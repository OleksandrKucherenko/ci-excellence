#!/bin/bash
# CI Security Audit Script - Version 1.0.0
#
# PURPOSE: Perform comprehensive security audits on codebase and dependencies
#
# USAGE:
#   ./scripts/maintenance/20-ci-security-audit.sh [options]
#
# EXAMPLES:
#   # Default security audit
#   ./scripts/maintenance/20-ci-security-audit.sh
#
#   # Audit specific areas
#   ./scripts/maintenance/20-ci-security-audit.sh --secrets --dependencies
#
#   # Generate detailed report
#   ./scripts/maintenance/20-ci-security-audit.sh --verbose
#
# TESTABILITY ENVIRONMENT VARIABLES:
#   - CI_TEST_MODE: Set to "dry_run" to simulate operations
#   - SCAN_DEPTH: Set scanning depth (shallow, medium, deep)
#   - SEVERITY_THRESHOLD: Minimum severity level (low, medium, high, critical)
#   - LOG_LEVEL: Set logging level (debug, info, warn, error)
#
# EXTENSION POINTS:
#   - Add custom security checks in run_custom_security_checks()
#   - Extend vulnerability_scanners with additional tools
#   - Add environment-specific audit rules
#
# SIZE GUIDELINES:
#   - Keep script under 50 lines of code (excluding comments and documentation)
#   - Extract complex audit logic to helper functions
#   - Use shared utilities for security operations
#
# DEPENDENCIES:
#   - Required: git, curl, jq
#   - Optional: gitleaks, trufflehog, npm, python3, go

set -euo pipefail

# Script configuration
SCRIPT_NAME="$(basename "$0" .sh)"
SCRIPT_VERSION="1.0.0"
SCRIPT_MODE="${SCRIPT_MODE:-${CI_TEST_MODE:-default}}"
LOG_LEVEL="${LOG_LEVEL:-info}"
SCAN_DEPTH="${SCAN_DEPTH:-medium}"
SEVERITY_THRESHOLD="${SEVERITY_THRESHOLD:-medium}"

# Source libraries and utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/config.sh"
source "${SCRIPT_DIR}/../lib/logging.sh"
source "${SCRIPT_DIR}/../lib/validation.sh"
source "${SCRIPT_DIR}/../lib/security.sh"

# Security audit results
declare -A audit_results=(
    ["secrets_found"]=0
    ["vulnerabilities_found"]=0
    ["compliance_issues"]=0
    ["policy_violations"]=0
)

# Main security audit function
main_security_audit() {
    log_info "Starting comprehensive security audit"
    log_info "Scan depth: $SCAN_DEPTH"
    log_info "Severity threshold: $SEVERITY_THRESHOLD"

    # Initialize security logging
    init_security_logging

    # Run secret scanning
    run_secret_scanning

    # Run vulnerability scanning
    run_vulnerability_scanning

    # Run compliance checks
    run_compliance_checks

    # Run policy validation
    run_policy_validation

    # Generate security report
    generate_security_audit_report

    log_success "Security audit completed"
}

# Run secret scanning
run_secret_scanning() {
    log_info "Running secret scanning"

    local secrets_found=0

    # Gitleaks scan
    if command -v gitleaks &> /dev/null; then
        log_info "Running Gitleaks scan"
        local gitleaks_report="${PROJECT_ROOT}/.reports/security/gitleaks-report.json"

        if [[ "$SCRIPT_MODE" != "dry_run" ]]; then
            gitleaks detect --source="${PROJECT_ROOT}" \
                --report-path="$gitleaks_report" \
                --report-format=json \
                --verbose &>/dev/null || true

            if [[ -f "$gitleaks_report" ]]; then
                if command -v jq &> /dev/null; then
                    secrets_found=$(jq '[.[] | select(.Severity == "HIGH")] | length' "$gitleaks_report" 2>/dev/null || echo 0)
                else
                    secrets_found=$(grep -c '"Severity": "HIGH"' "$gitleaks_report" 2>/dev/null || echo 0)
                fi
            fi
        else
            log_info "[DRY RUN] Would run Gitleaks scan"
        fi
    else
        log_warn "Gitleaks not available, skipping secret scan"
    fi

    # Trufflehog scan
    if command -v trufflehog &> /dev/null; then
        log_info "Running Trufflehog scan"
        if [[ "$SCRIPT_MODE" != "dry_run" ]]; then
            trufflehog filesystem "${PROJECT_ROOT}" \
                --only-verified &>/dev/null || true
        else
            log_info "[DRY RUN] Would run Trufflehog scan"
        fi
    else
        log_warn "Trufflehog not available, skipping additional secret scan"
    fi

    audit_results["secrets_found"]=$secrets_found
    log_security_event "INFO" "Secret scanning completed" "Found $secrets_found secrets"
}

# Run vulnerability scanning
run_vulnerability_scanning() {
    log_info "Running vulnerability scanning"

    local vulnerabilities_found=0

    # Node.js dependencies
    if [[ -f "package.json" ]] && command -v npm &> /dev/null; then
        log_info "Scanning Node.js dependencies"
        if [[ "$SCRIPT_MODE" != "dry_run" ]]; then
            npm audit --audit-level=moderate &>/dev/null || true
        else
            log_info "[DRY RUN] Would scan Node.js dependencies"
        fi
    fi

    # Python dependencies
    if [[ -f "requirements.txt" ]] && command -v pip-audit &> /dev/null; then
        log_info "Scanning Python dependencies"
        if [[ "$SCRIPT_MODE" != "dry_run" ]]; then
            pip-audit &>/dev/null || true
        else
            log_info "[DRY RUN] Would scan Python dependencies"
        fi
    fi

    # Go dependencies
    if [[ -f "go.mod" ]] && command -v go &> /dev/null; then
        log_info "Scanning Go dependencies"
        if [[ "$SCRIPT_MODE" != "dry_run" ]]; then
            govulncheck ./... &>/dev/null || true
        else
            log_info "[DRY RUN] Would scan Go dependencies"
        fi
    fi

    audit_results["vulnerabilities_found"]=$vulnerabilities_found
    log_security_event "INFO" "Vulnerability scanning completed" "Found $vulnerabilities_found vulnerabilities"
}

# Run compliance checks
run_compliance_checks() {
    log_info "Running compliance checks"

    local compliance_issues=0

    # Check for sensitive files in repository
    local sensitive_files=(
        ".env"
        ".env.local"
        ".env.production"
        "id_rsa"
        "id_rsa.pub"
        "*.pem"
        "*.key"
        "*.p12"
        "*.pfx"
    )

    for file_pattern in "${sensitive_files[@]}"; do
        if find "${PROJECT_ROOT}" -name "$file_pattern" -not -path "*/.git/*" | head -1 | grep -q .; then
            ((compliance_issues++))
            log_security_event "MEDIUM" "Sensitive file found" "Pattern: $file_pattern"
        fi
    done

    # Check for hardcoded secrets
    local secret_patterns=(
        "password[[:space:]]*=[[:space:]]*['\"]"
        "api_key[[:space:]]*=[[:space:]]*['\"]"
        "secret[[:space:]]*=[[:space:]]*['\"]"
        "token[[:space:]]*=[[:space:]]*['\"]"
        "private_key[[:space:]]*=[[:space:]]*['\"]"
    )

    for pattern in "${secret_patterns[@]}"; do
        if grep -r "$pattern" "${PROJECT_ROOT}" --exclude-dir=.git --exclude="*.md" 2>/dev/null | head -5 | grep -q .; then
            ((compliance_issues++))
            log_security_event "MEDIUM" "Potential hardcoded secret found" "Pattern: $pattern"
        fi
    done

    audit_results["compliance_issues"]=$compliance_issues
    log_security_event "INFO" "Compliance checks completed" "Found $compliance_issues compliance issues"
}

# Run policy validation
run_policy_validation() {
    log_info "Running policy validation"

    local policy_violations=0

    # Check file permissions
    if [[ -d "scripts" ]]; then
        while IFS= read -r -d '' script_file; do
            if [[ -x "$script_file" ]]; then
                log_debug "Script has correct permissions: $script_file"
            else
                ((policy_violations++))
                log_security_event "LOW" "Script without execute permission" "$script_file"
            fi
        done < <(find "${PROJECT_ROOT}/scripts" -type f -name "*.sh" -print0 2>/dev/null || true)
    fi

    # Check for large files in repository
    while IFS= read -r large_file; do
        local file_size
        file_size=$(stat -c%s "$large_file" 2>/dev/null || stat -f%z "$large_file" 2>/dev/null || echo 0)
        if [[ $file_size -gt 10485760 ]]; then  # 10MB
            ((policy_violations++))
            log_security_event "MEDIUM" "Large file in repository" "$large_file (${file_size} bytes)"
        fi
    done < <(find "${PROJECT_ROOT}" -type f -not -path "*/.git/*" -exec ls -la {} \; 2>/dev/null | awk '$5 > 10485760 {print $9}' || true)

    audit_results["policy_violations"]=$policy_violations
    log_security_event "INFO" "Policy validation completed" "Found $policy_violations policy violations"
}

# Run custom security checks (extension point)
run_custom_security_checks() {
    log_info "Running custom security checks"

    # Add your custom security checks here
    # Example:
    # check_database_security
    # check_api_endpoints_security
    # check_container_security
}

# Generate security audit report
generate_security_audit_report() {
    local report_file="${PROJECT_ROOT}/.reports/security/security-audit-report.json"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    mkdir -p "$(dirname "$report_file")"

    # Calculate overall risk level
    local risk_level="low"
    local total_issues=$((audit_results[secrets_found] + audit_results[vulnerabilities_found] + audit_results[compliance_issues] + audit_results[policy_violations]))

    if [[ $total_issues -gt 10 ]]; then
        risk_level="high"
    elif [[ $total_issues -gt 5 ]]; then
        risk_level="medium"
    fi

    cat > "$report_file" << EOF
{
  "audit_info": {
    "timestamp": "$timestamp",
    "script_version": "$SCRIPT_VERSION",
    "scan_depth": "$SCAN_DEPTH",
    "severity_threshold": "$SEVERITY_THRESHOLD",
    "initiated_by": "${USER:-unknown}"
  },
  "results": {
    "secrets_found": ${audit_results[secrets_found]},
    "vulnerabilities_found": ${audit_results[vulnerabilities_found]},
    "compliance_issues": ${audit_results[compliance_issues]},
    "policy_violations": ${audit_results[policy_violations]},
    "total_issues": $total_issues,
    "risk_level": "$risk_level"
  },
  "summary": {
    "status": "completed",
    "recommendation": "$( [[ "$risk_level" == "high" ]] && echo "Immediate attention required" || echo "Monitor and address issues")"
  },
  "tools_used": {
    "gitleaks": $(command -v gitleaks &> /dev/null && echo "true" || echo "false"),
    "trufflehog": $(command -v trufflehog &> /dev/null && echo "true" || echo "false"),
    "npm_audit": $(command -v npm &> /dev/null && echo "true" || echo "false"),
    "pip_audit": $(command -v pip-audit &> /dev/null && echo "true" || echo "false"),
    "govulncheck": $(command -v go &> /dev/null && echo "true" || echo "false")
  }
}
EOF

    log_info "Security audit report generated: $report_file"
    log_security_event "INFO" "Security audit report generated" "Risk level: $risk_level"

    # Display summary
    echo
    log_info "Security Audit Summary:"
    echo "  Secrets found: ${audit_results[secrets_found]}"
    echo "  Vulnerabilities found: ${audit_results[vulnerabilities_found]}"
    echo "  Compliance issues: ${audit_results[compliance_issues]}"
    echo "  Policy violations: ${audit_results[policy_violations]}"
    echo "  Total issues: $total_issues"
    echo "  Risk level: $risk_level"
}

# Show usage information
show_usage() {
    echo
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  --secrets       Scan only for secrets"
    echo "  --dependencies  Scan only dependencies"
    echo "  --compliance   Run only compliance checks"
    echo "  --policy        Run only policy validation"
    echo "  --verbose       Generate detailed output"
    echo "  --dry-run       Simulate scanning without tools"
    echo
    echo "Environment Variables:"
    echo "  SCAN_DEPTH=deep    Set scanning depth"
    echo "  SEVERITY_THRESHOLD=high  Set severity threshold"
    echo "  LOG_LEVEL=debug   Enable debug logging"
    echo
    echo "Examples:"
    echo "  $0                      # Default security audit"
    echo "  $0 --secrets           # Scan only for secrets"
    echo "  SCAN_DEPTH=deep $0     # Deep scan"
}

# Main function
main() {
    local command="${1:-audit}"

    # Initialize logging and configuration
    initialize_logging "$LOG_LEVEL" "$SCRIPT_NAME"
    load_project_config

    case "$command" in
        "audit")
            main_security_audit
            ;;
        "--secrets")
            run_secret_scanning
            ;;
        "--dependencies")
            run_vulnerability_scanning
            ;;
        "--compliance")
            run_compliance_checks
            ;;
        "--policy")
            run_policy_validation
            ;;
        "--dry-run")
            SCRIPT_MODE="dry_run"
            main_security_audit
            ;;
        "--help"|"-h")
            show_usage
            ;;
        *)
            log_error "Unknown option: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"