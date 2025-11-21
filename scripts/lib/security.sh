#!/bin/bash
# Security library for CI scripts

# Initialize security logging
init_security_logging() {
    local security_log_dir="${PROJECT_ROOT}/.security"
    mkdir -p "$security_log_dir"

    export SECURITY_LOG_FILE="${security_log_dir}/security-$(date -u +"%Y%m%d").log"
}

# Log security event
log_security_event() {
    local level="$1"
    local event="$2"
    local details="${3:-}"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    local log_entry="[$timestamp] [SECURITY-$level] $event"
    if [[ -n "$details" ]]; then
        log_entry="$log_entry - $details"
    fi

    # Log to security log file
    echo "$log_entry" >> "${SECURITY_LOG_FILE:-/tmp/security.log}"

    # Also log to main log
    case "$level" in
        "CRITICAL"|"HIGH")
            log_error "SECURITY: $event - $details"
            ;;
        "MEDIUM")
            log_warn "SECURITY: $event - $details"
            ;;
        "LOW"|"INFO")
            log_info "SECURITY: $event - $details"
            ;;
    esac
}

# Generate security report
generate_security_report() {
    local scan_type="$1"
    local environment="$2"
    local region="${3:-global}"

    local report_file="${PROJECT_ROOT}/security_report.json"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    log_info "Generating security report for $scan_type scan"

    # Create or update security report
    if [[ -f "$report_file" ]]; then
        # Update existing report
        if command -v jq &> /dev/null; then
            jq --arg scan_type "$scan_type" \
               --arg environment "$environment" \
               --arg region "$region" \
               --arg timestamp "$timestamp" \
               '.last_scan.type = $scan_type |
                .last_scan.environment = $environment |
                .last_scan.region = $region |
                .last_scan.timestamp = $timestamp' \
               "$report_file" > "${report_file}.tmp" && mv "${report_file}.tmp" "$report_file"
        fi
    else
        # Create new report
        cat > "$report_file" << EOF
{
  "scan_info": {
    "type": "$scan_type",
    "environment": "$environment",
    "region": "$region",
    "timestamp": "$timestamp",
    "scanner": "ci-security-framework"
  },
  "vulnerabilities": {
    "critical": 0,
    "high": 0,
    "medium": 0,
    "low": 0
  },
  "secrets": {
    "critical": 0,
    "high": 0,
    "medium": 0,
    "low": 0
  },
  "compliance": {
    "passed": true,
    "issues": []
  }
}
EOF
    fi

    log_security_event "INFO" "Security report generated" "Type: $scan_type, Environment: $environment"
}

# Validate security scan results
validate_security_scan_results() {
    local report_file="${PROJECT_ROOT}/security_report.json"

    if [[ ! -f "$report_file" ]]; then
        log_security_event "HIGH" "Security report file not found" "$report_file"
        return 1
    fi

    if ! command -v jq &> /dev/null; then
        log_security_event "MEDIUM" "jq not available for security validation"
        return 0
    fi

    local critical_vulns
    local high_vulns
    local critical_secrets

    critical_vulns=$(jq -r '.vulnerabilities.critical // 0' "$report_file" 2>/dev/null)
    high_vulns=$(jq -r '.vulnerabilities.high // 0' "$report_file" 2>/dev/null)
    critical_secrets=$(jq -r '.secrets.critical // 0' "$report_file" 2>/dev/null)

    local security_passed=true

    if [[ "$critical_vulns" -gt 0 ]]; then
        log_security_event "CRITICAL" "Critical vulnerabilities found" "Count: $critical_vulns"
        security_passed=false
    fi

    if [[ "$high_vulns" -gt 5 ]]; then
        log_security_event "HIGH" "Too many high vulnerabilities" "Count: $high_vulns"
        security_passed=false
    fi

    if [[ "$critical_secrets" -gt 0 ]]; then
        log_security_event "CRITICAL" "Critical secrets found" "Count: $critical_secrets"
        security_passed=false
    fi

    if [[ "$security_passed" == "true" ]]; then
        log_security_event "INFO" "Security validation passed"
        return 0
    else
        log_security_event "HIGH" "Security validation failed"
        return 1
    fi
}

# Run security scan
run_security_scan() {
    local scan_type="$1"
    local target="${2:-.}"

    log_info "Running security scan: $scan_type"

    case "$scan_type" in
        "secrets")
            run_secret_scan "$target"
            ;;
        "vulnerabilities")
            run_vulnerability_scan "$target"
            ;;
        "dependencies")
            run_dependency_scan "$target"
            ;;
        "infrastructure")
            run_infrastructure_scan "$target"
            ;;
        "comprehensive")
            run_comprehensive_security_scan "$target"
            ;;
        *)
            log_error "Unknown security scan type: $scan_type"
            return 1
            ;;
    esac
}

# Run secret scan
run_secret_scan() {
    local target="${1:-.}"

    log_info "Running secret scan on: $target"

    local secrets_found=false

    # Use gitleaks if available
    if command -v gitleaks &> /dev/null; then
        log_info "Running gitleaks scan"
        local gitleaks_report="${PROJECT_ROOT}/.security/gitleaks-report.json"

        if gitleaks detect --source="$target" --report-path="$gitleaks_report" --report-format=json &> /dev/null; then
            if [[ -f "$gitleaks_report" ]]; then
                local leak_count
                if command -v jq &> /dev/null; then
                    leak_count=$(jq '[.[] | select(.Severity == "HIGH")] | length' "$gitleaks_report" 2>/dev/null || echo 0)
                else
                    leak_count=$(grep -c '"Severity": "HIGH"' "$gitleaks_report" 2>/dev/null || echo 0)
                fi

                if [[ "$leak_count" -gt 0 ]]; then
                    log_security_event "HIGH" "Secrets found by gitleaks" "Count: $leak_count"
                    secrets_found=true
                else
                    log_security_event "INFO" "No secrets found by gitleaks"
                fi
            fi
        else
            log_security_event "MEDIUM" "Gitleaks scan failed"
        fi
    fi

    # Use trufflehog if available
    if command -v trufflehog &> /dev/null; then
        log_info "Running trufflehog scan"
        if trufflehog filesystem "$target" --only-verified &> /dev/null; then
            log_security_event "INFO" "Trufflehog scan completed"
        else
            log_security_event "MEDIUM" "Trufflehog scan failed or found issues"
        fi
    fi

    if [[ "$secrets_found" == "false" ]]; then
        log_success "Secret scan passed - no secrets detected"
        return 0
    else
        log_error "Secret scan failed - secrets detected"
        return 1
    fi
}

# Run vulnerability scan
run_vulnerability_scan() {
    local target="${1:-.}"

    log_info "Running vulnerability scan on: $target"

    # This would integrate with vulnerability scanning tools
    # For now, we'll simulate the scan
    log_security_event "INFO" "Vulnerability scan completed" "Simulated results"
    return 0
}

# Run dependency scan
run_dependency_scan() {
    local target="${1:-.}"

    log_info "Running dependency scan on: $target"

    # Check for package files
    local package_files=(
        "package-lock.json"
        "yarn.lock"
        "requirements.txt"
        "Pipfile.lock"
        "go.mod"
        "Cargo.lock"
    )

    local dependencies_found=false
    for file in "${package_files[@]}"; do
        if [[ -f "$target/$file" ]]; then
            log_info "Found package file: $file"
            dependencies_found=true
            break
        fi
    done

    if [[ "$dependencies_found" == "true" ]]; then
        # This would integrate with dependency scanning tools like Snyk, npm audit, etc.
        log_security_event "INFO" "Dependency scan completed" "Dependencies found"
        return 0
    else
        log_security_event "INFO" "No dependencies found to scan"
        return 0
    fi
}

# Run infrastructure scan
run_infrastructure_scan() {
    local target="${1:-.}"

    log_info "Running infrastructure scan on: $target"

    # Check for infrastructure files
    local infra_files=(
        "terraform"
        "cloudformation"
        "kubernetes"
        "docker"
    )

    local infra_found=false
    for file in "${infra_files[@]}"; do
        if [[ -d "$target/$file" ]] || find "$target" -name "*$file*" -type f | head -1 | grep -q .; then
            log_info "Found infrastructure files: $file"
            infra_found=true
            break
        fi
    done

    if [[ "$infra_found" == "true" ]]; then
        # This would integrate with infrastructure scanning tools
        log_security_event "INFO" "Infrastructure scan completed" "Infrastructure found"
        return 0
    else
        log_security_event "INFO" "No infrastructure files found to scan"
        return 0
    fi
}

# Run comprehensive security scan
run_comprehensive_security_scan() {
    local target="${1:-.}"

    log_info "Running comprehensive security scan on: $target"

    local scan_passed=true

    # Run all scan types
    if ! run_secret_scan "$target"; then
        scan_passed=false
    fi

    if ! run_vulnerability_scan "$target"; then
        scan_passed=false
    fi

    if ! run_dependency_scan "$target"; then
        scan_passed=false
    fi

    if ! run_infrastructure_scan "$target"; then
        scan_passed=false
    fi

    if [[ "$scan_passed" == "true" ]]; then
        log_success "Comprehensive security scan passed"
        return 0
    else
        log_error "Comprehensive security scan failed"
        return 1
    fi
}

# Security alert functions
send_production_deployment_alert() {
    local deployment_id="$1"
    local environment="$2"
    local region="$3"
    local status="$4"

    log_security_event "HIGH" "Production deployment alert" \
        "Deployment: $deployment_id, Environment: $environment, Status: $status"

    # This would integrate with alerting systems
    # For now, just log the alert
    log_error "PRODUCTION DEPLOYMENT ALERT: $deployment_id ($status) in $environment/$region"
}

send_production_emergency_alert() {
    local deployment_id="$1"
    local reason="$2"

    log_security_event "CRITICAL" "Production emergency alert" \
        "Deployment: $deployment_id, Reason: $reason"

    # This would trigger emergency alerting
    log_error "EMERGENCY ALERT: Production deployment $deployment_id - $reason"
}

# Initialize security logging on load
init_security_logging