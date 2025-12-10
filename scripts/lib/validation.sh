#!/bin/bash
# Validation library for CI scripts

# Validate deployment configuration
validate_deployment_config() {
    local -n config_ref=$1
    local environment="${config_ref[environment]:-unknown}"
    local max_concurrent="${config_ref[max_concurrent_deployments]}"
    local health_timeout="${config_ref[health_check_timeout]}"

    log_info "Validating deployment configuration for $environment"

    # Validate environment
    if [[ -z "$environment" ]]; then
        log_error "Environment not specified in deployment config"
        return 1
    fi

    # Validate numeric values
    if [[ ! "$max_concurrent" =~ ^[0-9]+$ ]]; then
        log_error "Invalid max_concurrent_deployments: $max_concurrent"
        return 1
    fi

    if [[ ! "$health_timeout" =~ ^[0-9]+$ ]]; then
        log_error "Invalid health_check_timeout: $health_timeout"
        return 1
    fi

    log_success "Deployment configuration validation passed"
    return 0
}

# Validate environment variables
validate_environment_variables() {
    local -a required_vars=("$@")
    local missing_vars=()

    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done

    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing required environment variables:"
        for var in "${missing_vars[@]}"; do
            log_error "  - $var"
        done
        return 1
    fi

    return 0
}

# Validate commit hash
validate_commit_hash() {
    local commit_hash="$1"

    if [[ -z "$commit_hash" ]]; then
        log_error "Commit hash is required"
        return 1
    fi

    if [[ ! "$commit_hash" =~ ^[a-fA-F0-9]{7,40}$ ]]; then
        log_error "Invalid commit hash format: $commit_hash"
        return 1
    fi

    if ! git rev-parse --verify "$commit_hash" &> /dev/null; then
        log_error "Commit hash not found in repository: $commit_hash"
        return 1
    fi

    return 0
}

# Validate version tag
validate_version_tag() {
    local version_tag="$1"

    if [[ -z "$version_tag" ]]; then
        log_error "Version tag is required"
        return 1
    fi

    if [[ ! "$version_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$ ]]; then
        log_error "Invalid version tag format: $version_tag"
        log_info "Expected format: vX.Y.Z or vX.Y.Z-prerelease"
        return 1
    fi

    return 0
}

# Validate email address
validate_email() {
    local email="$1"

    if [[ -z "$email" ]]; then
        log_error "Email address is required"
        return 1
    fi

    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        log_error "Invalid email address format: $email"
        return 1
    fi

    return 0
}

# Validate URL
validate_url() {
    local url="$1"

    if [[ -z "$url" ]]; then
        log_error "URL is required"
        return 1
    fi

    if [[ ! "$url" =~ ^https?:// ]]; then
        log_error "URL must start with http:// or https://: $url"
        return 1
    fi

    return 0
}

# Validate port number
validate_port() {
    local port="$1"

    if [[ -z "$port" ]]; then
        log_error "Port number is required"
        return 1
    fi

    if [[ ! "$port" =~ ^[0-9]+$ ]]; then
        log_error "Port must be a number: $port"
        return 1
    fi

    if [[ $port -lt 1 || $port -gt 65535 ]]; then
        log_error "Port must be between 1 and 65535: $port"
        return 1
    fi

    return 0
}

# Validate timeout value
validate_timeout() {
    local timeout="$1"

    if [[ -z "$timeout" ]]; then
        log_error "Timeout value is required"
        return 1
    fi

    if [[ ! "$timeout" =~ ^[0-9]+$ ]]; then
        log_error "Timeout must be a number: $timeout"
        return 1
    fi

    if [[ $timeout -lt 1 || $timeout -gt 3600 ]]; then
        log_error "Timeout must be between 1 and 3600 seconds: $timeout"
        return 1
    fi

    return 0
}

# Validate file path
validate_file_path() {
    local file_path="$1"
    local must_exist="${2:-true}"

    if [[ -z "$file_path" ]]; then
        log_error "File path is required"
        return 1
    fi

    # Check for dangerous paths
    if [[ "$file_path" =~ ^\.\./ ]] || [[ "$file_path" =~ \.\.$ ]]; then
        log_error "Dangerous file path: $file_path"
        return 1
    fi

    if [[ "$must_exist" == "true" ]] && [[ ! -f "$file_path" ]]; then
        log_error "File does not exist: $file_path"
        return 1
    fi

    return 0
}

# Validate directory path
validate_directory_path() {
    local dir_path="$1"
    local must_exist="${2:-true}"

    if [[ -z "$dir_path" ]]; then
        log_error "Directory path is required"
        return 1
    fi

    # Check for dangerous paths
    if [[ "$dir_path" =~ ^\.\./ ]] || [[ "$dir_path" =~ \.\.$ ]]; then
        log_error "Dangerous directory path: $dir_path"
        return 1
    fi

    if [[ "$must_exist" == "true" ]] && [[ ! -d "$dir_path" ]]; then
        log_error "Directory does not exist: $dir_path"
        return 1
    fi

    return 0
}

# Validate AWS credentials
validate_aws_credentials() {
    log_debug "Validating AWS credentials"

    # Check AWS CLI is available
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed"
        return 1
    fi

    # Check AWS credentials are configured
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials are not configured or invalid"
        log_info "Run 'aws configure' or set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY"
        return 1
    fi

    log_debug "AWS credentials validation passed"
    return 0
}

# Validate required tools
validate_required_tools() {
    local -a tools=("$@")
    local missing_tools=()

    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools:"
        for tool in "${missing_tools[@]}"; do
            log_error "  - $tool"
        done
        return 1
    fi

    return 0
}

# Validate configuration file
validate_config_file() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi

    # Check if file is readable
    if [[ ! -r "$config_file" ]]; then
        log_error "Configuration file is not readable: $config_file"
        return 1
    fi

    # For YAML files, check syntax if yq is available
    if [[ "$config_file" =~ \.(ya?ml)$ ]] && command -v yq &> /dev/null; then
        if ! yq eval '.' "$config_file" &> /dev/null; then
            log_error "Invalid YAML syntax in: $config_file"
            return 1
        fi
    fi

    return 0
}

# Validate test coverage
validate_test_coverage() {
    local min_coverage="${1:-80}"
    local coverage_file="${PROJECT_ROOT}/test_results.json"

    if [[ ! -f "$coverage_file" ]]; then
        log_error "Test coverage file not found: $coverage_file"
        return 1
    fi

    if command -v jq &> /dev/null; then
        local coverage
        coverage=$(jq -r '.coverage.total // 0' "$coverage_file" 2>/dev/null)

        if (( $(echo "$coverage < $min_coverage" | bc -l 2>/dev/null || echo "1") )); then
            log_error "Test coverage ${coverage}% is below required ${min_coverage}%"
            return 1
        fi

        log_info "Test coverage: ${coverage}%"
    else
        log_warn "jq not available, skipping coverage validation"
    fi

    return 0
}

# Validate security scan results
validate_security_scan() {
    local max_high_sev="${1:-0}"
    local max_critical_sev="${2:-0}"
    local security_file="${PROJECT_ROOT}/security_report.json"

    if [[ ! -f "$security_file" ]]; then
        log_error "Security report file not found: $security_file"
        return 1
    fi

    if command -v jq &> /dev/null; then
        local high_vulns
        local critical_vulns

        high_vulns=$(jq -r '.vulnerabilities.high // 0' "$security_file" 2>/dev/null)
        critical_vulns=$(jq -r '.vulnerabilities.critical // 0' "$security_file" 2>/dev/null)

        if [[ "$high_vulns" -gt "$max_high_sev" ]]; then
            log_error "High severity vulnerabilities ($high_vulns) exceed threshold ($max_high_sev)"
            return 1
        fi

        if [[ "$critical_vulns" -gt "$max_critical_sev" ]]; then
            log_error "Critical severity vulnerabilities ($critical_vulns) exceed threshold ($max_critical_sev)"
            return 1
        fi

        log_info "Security validation passed - High: $high_vulns, Critical: $critical_vulns"
    else
        log_warn "jq not available, skipping security validation"
    fi

    return 0
}

# Run comprehensive validation
run_comprehensive_validation() {
    local environment="$1"
    local validation_errors=0

    log_info "Running comprehensive validation for $environment"

    # Validate environment configuration
    if ! validate_environment_config "$environment" "${DEPLOYMENT_REGION:-us-east}"; then
        ((validation_errors++))
    fi

    # Validate required tools
    local required_tools=("git" "curl")
    if [[ "$environment" == "production" ]]; then
        required_tools+=("aws")
    fi

    if ! validate_required_tools "${required_tools[@]}"; then
        ((validation_errors++))
    fi

    # Validate AWS credentials for production
    if [[ "$environment" == "production" ]]; then
        if ! validate_aws_credentials; then
            ((validation_errors++))
        fi
    fi

    # Validate commit hash
    if ! validate_commit_hash "${CI_COMMIT_SHA:-}"; then
        ((validation_errors++))
    fi

    # Validate version tag for production
    if [[ "$environment" == "production" ]]; then
        if ! validate_version_tag "${CI_COMMIT_TAG:-}"; then
            ((validation_errors++))
        fi
    fi

    if [[ $validation_errors -gt 0 ]]; then
        log_error "Comprehensive validation failed with $validation_errors errors"
        return 1
    else
        log_success "Comprehensive validation passed"
        return 0
    fi
}