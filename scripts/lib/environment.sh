#!/bin/bash
# Environment management library for CI scripts

# Load environment-specific configuration
load_environment_config() {
    local environment="$1"
    local region="${2:-us-east}"

    local config_file="${PROJECT_ROOT}/environments/${environment}/config.yml"
    local region_config="${PROJECT_ROOT}/environments/${environment}/regions/${region}/config.yml"

    log_info "Loading environment configuration for $environment ($region)"

    # Load base environment config
    if [[ -f "$config_file" ]]; then
        load_yaml_config "$config_file"
    else
        log_warn "Environment config not found: $config_file"
    fi

    # Load region-specific config
    if [[ -f "$region_config" ]]; then
        load_yaml_config "$region_config"
    else
        log_warn "Region config not found: $region_config"
    fi

    # Set environment variables
    export DEPLOYMENT_ENVIRONMENT="$environment"
    export DEPLOYMENT_REGION="$region"
    export CI_DEPLOYMENT_TARGET="$environment"
}

# Load YAML configuration file
load_yaml_config() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi

    # Use yq if available, otherwise provide basic fallback
    if command -v yq &> /dev/null; then
        log_debug "Parsing YAML configuration with yq"

        # Extract environment variables
        local env_vars
        env_vars=$(yq eval '.environment_variables | to_entries | .[] | "\(.key)=\(.value)"' "$config_file" 2>/dev/null || true)

        # Export variables
        while IFS='=' read -r key value; do
            if [[ -n "$key" && -n "$value" ]]; then
                export "$key"="$value"
                log_debug "Exported $key from config"
            fi
        done <<< "$env_vars"

        # Extract cloud provider settings
        local cloud_provider
        cloud_provider=$(yq eval '.cloud.provider // "aws"' "$config_file" 2>/dev/null)
        export CLOUD_PROVIDER="$cloud_provider"

        local aws_region
        aws_region=$(yq eval '.cloud.region // "us-east-1"' "$config_file" 2>/dev/null)
        export AWS_REGION="$aws_region"

    else
        log_warn "yq not available, using basic config loading"
        export CLOUD_PROVIDER="aws"
        export AWS_REGION="us-east-1"
    fi
}

# Validate environment configuration
validate_environment_config() {
    local environment="$1"
    local region="$2"

    log_info "Validating environment configuration for $environment ($region)"

    # Check required files
    local config_file="${PROJECT_ROOT}/environments/${environment}/config.yml"
    if [[ ! -f "$config_file" ]]; then
        log_error "Environment config file not found: $config_file"
        return 1
    fi

    # Validate environment name
    local valid_environments=("staging" "production" "development")
    if [[ ! " ${valid_environments[*]} " =~ " $environment " ]]; then
        log_error "Invalid environment: $environment"
        log_info "Valid environments: ${valid_environments[*]}"
        return 1
    fi

    # Validate required environment variables
    local required_vars=(
        "DEPLOYMENT_ENVIRONMENT"
        "DEPLOYMENT_REGION"
        "CI_DEPLOYMENT_TARGET"
    )

    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log_error "Required environment variable $var is not set"
            return 1
        fi
    done

    log_success "Environment configuration validation passed"
}

# Get environment URL
get_environment_url() {
    local environment="$1"
    local region="$2"
    local service="${3:-web}"

    local base_url
    case "$environment" in
        "staging")
            base_url="https://staging-${region}.example.com"
            ;;
        "production")
            base_url="https://${region}.example.com"
            ;;
        "development")
            base_url="https://dev-${region}.example.com"
            ;;
        *)
            base_url="https://${environment}-${region}.example.com"
            ;;
    esac

    case "$service" in
        "api")
            echo "${base_url/api/api-}"
            ;;
        "web")
            echo "$base_url"
            ;;
        *)
            echo "${base_url}/${service}"
            ;;
    esac
}

# Check environment health
check_environment_health() {
    local environment="$1"
    local region="$2"
    local timeout="${3:-30}"

    local health_url
    health_url=$(get_environment_url "$environment" "$region")/health

    log_info "Checking environment health: $health_url"

    if command -v curl &> /dev/null; then
        local response
        response=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$timeout" "$health_url" 2>/dev/null || echo "000")

        case "$response" in
            "200")
                log_success "Environment health check passed (200)"
                return 0
                ;;
            "000")
                log_error "Environment health check failed - connection timeout"
                return 1
                ;;
            *)
                log_error "Environment health check failed - HTTP $response"
                return 1
                ;;
        esac
    else
        log_warn "curl not available, skipping health check"
        return 0
    fi
}

# Get environment status
get_environment_status() {
    local environment="$1"
    local region="$2"

    echo
    log_info "Environment Status: $environment ($region)"
    echo "  Environment: $environment"
    echo "  Region: $region"
    echo "  Cloud Provider: ${CLOUD_PROVIDER:-aws}"
    echo "  AWS Region: ${AWS_REGION:-not set}"
    echo "  Health Status: $(check_environment_health "$environment" "$region" && echo "healthy" || echo "unhealthy")"
    echo "  Last Check: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}

# Switch environment context
switch_environment_context() {
    local environment="$1"
    local region="${2:-us-east}"

    log_info "Switching to environment context: $environment ($region)"

    # Load environment configuration
    load_environment_config "$environment" "$region"

    # Validate configuration
    validate_environment_config "$environment" "$region"

    log_success "Switched to $environment ($region) environment context"
}

# List available environments
list_environments() {
    local environments_dir="${PROJECT_ROOT}/environments"

    echo
    log_info "Available Environments:"

    if [[ -d "$environments_dir" ]]; then
        find "$environments_dir" -maxdepth 1 -type d -not -path "$environments_dir" | while read -r env_dir; do
            local env_name
            env_name=$(basename "$env_dir")
            echo "  - $env_name"
        done
    else
        echo "  No environments found"
    fi
}

# List regions for environment
list_environment_regions() {
    local environment="$1"
    local regions_dir="${PROJECT_ROOT}/environments/${environment}/regions"

    echo
    log_info "Available regions for $environment:"

    if [[ -d "$regions_dir" ]]; then
        find "$regions_dir" -maxdepth 1 -type d -not -path "$regions_dir" | while read -r region_dir; do
            local region_name
            region_name=$(basename "$region_dir")
            echo "  - $region_name"
        done
    else
        echo "  No regions found for $environment"
    fi
}

# Environment-specific defaults
set_environment_defaults() {
    local environment="$1"

    case "$environment" in
        "staging")
            export SKIP_TESTS="${SKIP_TESTS:-false}"
            export CREATE_BACKUP="${CREATE_BACKUP:-false}"
            export REQUIRE_APPROVAL="${REQUIRE_APPROVAL:-false}"
            export ROLLBACK_ON_FAILURE="${ROLLBACK_ON_FAILURE:-true}"
            ;;
        "production")
            export SKIP_TESTS="${SKIP_TESTS:-false}"
            export CREATE_BACKUP="${CREATE_BACKUP:-true}"
            export REQUIRE_APPROVAL="${REQUIRE_APPROVAL:-true}"
            export ROLLBACK_ON_FAILURE="${ROLLBACK_ON_FAILURE:-true}"
            export PRODUCTION_SAFE_MODE="${PRODUCTION_SAFE_MODE:-true}"
            ;;
        "development")
            export SKIP_TESTS="${SKIP_TESTS:-true}"
            export CREATE_BACKUP="${CREATE_BACKUP:-false}"
            export REQUIRE_APPROVAL="${REQUIRE_APPROVAL:-false}"
            export ROLLBACK_ON_FAILURE="${ROLLBACK_ON_FAILURE:-false}"
            ;;
    esac
}