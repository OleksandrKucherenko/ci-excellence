#!/bin/bash
# CI Excellence Framework - Environment Show Script
# Description: Display detailed information about a specific environment

set -euo pipefail

# Script Configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load CI Framework Libraries
source "${SCRIPT_DIR}/../lib/common.sh"
source "${SCRIPT_DIR}/../lib/environment.sh"

# Usage information
usage() {
    cat << EOF
Usage: $SCRIPT_NAME <environment_name> [options]

Display detailed information about a specific environment.

Arguments:
  environment_name    Name of the environment to show

Options:
  --config-only      Show only configuration details
  --secrets-only     Show only secrets information
  --regions-only     Show only regions information
  --format FORMAT    Output format (table|json|yaml) - default: table
  --help             Show this help message

Examples:
  $SCRIPT_NAME staging
  $SCRIPT_NAME production --config-only
  $SCRIPT_NAME testing --format json
  $SCRIPT_NAME dev-feature --regions-only

EOF
}

# Parse command line arguments
parse_arguments() {
    ENV_NAME=""
    CONFIG_ONLY=false
    SECRETS_ONLY=false
    REGIONS_ONLY=false
    OUTPUT_FORMAT="table"

    while [[ $# -gt 0 ]]; do
        case $1 in
            --config-only)
                CONFIG_ONLY=true
                shift
                ;;
            --secrets-only)
                SECRETS_ONLY=true
                shift
                ;;
            --regions-only)
                REGIONS_ONLY=true
                shift
                ;;
            --format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            --help)
                usage
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                if [[ -z "$ENV_NAME" ]]; then
                    ENV_NAME="$1"
                else
                    log_error "Multiple environment names provided"
                    usage
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$ENV_NAME" ]]; then
        log_error "Environment name is required"
        usage
        exit 1
    fi

    # Validate output format
    case "$OUTPUT_FORMAT" in
        "table"|"json"|"yaml")
            ;;
        *)
            log_error "Invalid output format: $OUTPUT_FORMAT"
            log_error "Valid formats: table, json, yaml"
            exit 1
            ;;
    esac

    # Validate exclusive options
    local exclusive_count=0
    [[ "$CONFIG_ONLY" == "true" ]] && exclusive_count=$((exclusive_count + 1))
    [[ "$SECRETS_ONLY" == "true" ]] && exclusive_count=$((exclusive_count + 1))
    [[ "$REGIONS_ONLY" == "true" ]] && exclusive_count=$((exclusive_count + 1))

    if [[ $exclusive_count -gt 1 ]]; then
        log_error "Only one of --config-only, --secrets-only, or --regions-only can be specified"
        usage
        exit 1
    fi
}

# Get environment configuration details
get_config_details() {
    local env_name="$1"
    local config_file="environments/$env_name/config.yml"

    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi

    if command -v yq >/dev/null 2>&1; then
        # Extract all configuration details
        local name
        local description
        local type
        local created
        local extends
        local deployment_strategy
        local deployment_timeout

        name=$(yq eval '.environment.name // "'"$env_name"'"' "$config_file" 2>/dev/null || echo "$env_name")
        description=$(yq eval '.environment.description // "No description"' "$config_file" 2>/dev/null || echo "No description")
        type=$(yq eval '.environment.type // "unknown"' "$config_file" 2>/dev/null || echo "unknown")
        created=$(yq eval '.environment.created // "unknown"' "$config_file" 2>/dev/null || echo "unknown")
        extends=$(yq eval '.extends // "none"' "$config_file" 2>/dev/null || echo "none")
        deployment_strategy=$(yq eval '.overrides.deployment.strategy // "default"' "$config_file" 2>/dev/null || echo "default")
        deployment_timeout=$(yq eval '.overrides.deployment.timeout // "default"' "$config_file" 2>/dev/null || echo "default")

        # Output configuration details based on format
        case "$OUTPUT_FORMAT" in
            "table")
                echo "Configuration Details:"
                echo "  Name: $name"
                echo "  Description: $description"
                echo "  Type: $type"
                echo "  Created: $created"
                echo "  Extends: $extends"
                echo "  Deployment Strategy: $deployment_strategy"
                echo "  Deployment Timeout: $deployment_timeout"
                ;;
            "json")
                cat << EOF
{
  "name": "$name",
  "description": "$description",
  "type": "$type",
  "created": "$created",
  "extends": "$extends",
  "deployment": {
    "strategy": "$deployment_strategy",
    "timeout": "$deployment_timeout"
  }
}
EOF
                ;;
            "yaml")
                cat << EOF
name: "$name"
description: "$description"
type: "$type"
created: "$created"
extends: "$extends"
deployment:
  strategy: "$deployment_strategy"
  timeout: "$deployment_timeout"
EOF
                ;;
        esac
    else
        log_warning "yq not available, showing file content"
        if [[ "$OUTPUT_FORMAT" == "table" ]]; then
            echo "Configuration File Content:"
            cat "$config_file" | sed 's/^/  /'
        else
            cat "$config_file"
        fi
    fi
}

# Get environment secrets information
get_secrets_info() {
    local env_name="$1"
    local env_dir="environments/$env_name"

    # Check for secrets files
    local json_secrets="$env_dir/secrets.json"
    local enc_secrets="$env_dir/secrets.enc"

    if [[ ! -f "$json_secrets" && ! -f "$enc_secrets" ]]; then
        log_info "No secrets file found for environment '$env_name'"
        return 0
    fi

    case "$OUTPUT_FORMAT" in
        "table")
            echo "Secrets Information:"
            ;;
        "json")
            echo "{"
            echo "  \"secrets\": {"
            ;;
        "yaml")
            echo "secrets:"
            ;;
    esac

    if [[ -f "$json_secrets" ]]; then
        case "$OUTPUT_FORMAT" in
            "table")
                echo "  Format: JSON"
                echo "  File: $json_secrets"
                if command -v jq >/dev/null 2>&1; then
                    local key_count
                    key_count=$(jq 'keys | length' "$json_secrets" 2>/dev/null || echo "unknown")
                    echo "  Keys: $key_count"

                    # List keys without showing values
                    echo "  Key Names:"
                    jq -r 'keys[]' "$json_secrets" 2>/dev/null | sed 's/^/    - /' || echo "    Unable to list keys"
                fi
                ;;
            "json")
                echo "    \"format\": \"json\","
                echo "    \"file\": \"$json_secrets\","
                if command -v jq >/dev/null 2>&1; then
                    local key_count
                    key_count=$(jq 'keys | length' "$json_secrets" 2>/dev/null || echo "0")
                    echo "    \"key_count\": $key_count,"
                    echo "    \"keys\": $(jq -r 'keys' "$json_secrets" 2>/dev/null || echo '[]')"
                else
                    echo "    \"key_count\": \"unknown\""
                fi
                ;;
            "yaml")
                echo "  format: json"
                echo "  file: $json_secrets"
                if command -v jq >/dev/null 2>&1; then
                    local key_count
                    key_count=$(jq 'keys | length' "$json_secrets" 2>/dev/null || echo "unknown")
                    echo "  key_count: $key_count"
                    echo "  keys:"
                    jq -r 'keys[]' "$json_secrets" 2>/dev/null | sed 's/^/    - /' || echo "    - unable_to_list"
                fi
                ;;
        esac
    elif [[ -f "$enc_secrets" ]]; then
        case "$OUTPUT_FORMAT" in
            "table")
                echo "  Format: Encrypted (.enc)"
                echo "  File: $enc_secrets"
                echo "  Status: Legacy format - consider migrating to JSON"
                ;;
            "json")
                echo "    \"format\": \"encrypted\","
                echo "    \"file\": \"$enc_secrets\","
                echo "    \"status\": \"legacy_format\""
                ;;
            "yaml")
                echo "  format: encrypted"
                echo "  file: $enc_secrets"
                echo "  status: legacy_format"
                ;;
        esac
    fi

    case "$OUTPUT_FORMAT" in
        "json")
            echo "  }"
            echo "}"
            ;;
    esac
}

# Get environment regions information
get_regions_info() {
    local env_name="$1"
    local regions_dir="environments/$env_name/regions"

    if [[ ! -d "$regions_dir" ]]; then
        log_info "No regions directory found for environment '$env_name'"
        return 0
    fi

    # Find all region directories with config files
    local regions=()
    for region_dir in "$regions_dir"/*/; do
        if [[ -d "$region_dir" && -f "$region_dir/config.yml" ]]; then
            local region_name
            region_name=$(basename "$region_dir")
            regions+=("$region_name")
        fi
    done

    case "$OUTPUT_FORMAT" in
        "table")
            echo "Regions Information:"
            if [[ ${#regions[@]} -eq 0 ]]; then
                echo "  No regions configured"
            else
                echo "  Total Regions: ${#regions[@]}"
                echo "  Configured Regions:"
                printf '    %s\n' "${regions[@]}"
            fi
            ;;
        "json")
            echo "{"
            echo "  \"regions\": {"
            echo "    \"total_count\": ${#regions[@]},"
            echo "    \"configured_regions\": ["
            local first=true
            for region in "${regions[@]}"; do
                if [[ "$first" == "false" ]]; then
                    echo ","
                fi
                first=false
                echo "      \"$region\""
            done
            echo "    ]"
            echo "  }"
            echo "}"
            ;;
        "yaml")
            echo "regions:"
            echo "  total_count: ${#regions[@]}"
            echo "  configured_regions:"
            for region in "${regions[@]}"; do
                echo "    - $region"
            done
            ;;
    esac
}

# Show environment summary
show_environment_summary() {
    local env_name="$1"

    # Basic environment info
    case "$OUTPUT_FORMAT" in
        "table")
            echo "Environment Summary:"
            echo "  Name: $env_name"
            echo "  Directory: environments/$env_name"

            # Check if it's a default environment
            if is_default_environment "$env_name"; then
                echo "  Type: Default Environment (Protected)"
            else
                echo "  Type: Custom Environment"
            fi

            # Check deployment readiness
            if is_deployment_environment "$env_name"; then
                echo "  Deployment Ready: Yes"
            else
                echo "  Deployment Ready: No"
            fi

            echo ""
            ;;
        "json")
            echo "{"
            echo "  \"name\": \"$env_name\","
            echo "  \"directory\": \"environments/$env_name\","
            echo "  \"is_default\": $(is_default_environment "$env_name" && echo "true" || echo "false"),"
            echo "  \"is_deployment_ready\": $(is_deployment_environment "$env_name" && echo "true" || echo "false")"
            echo "}"
            ;;
        "yaml")
            echo "name: $env_name"
            echo "directory: environments/$env_name"
            echo "is_default: $(is_default_environment "$env_name" && echo "true" || echo "false")"
            echo "is_deployment_ready: $(is_deployment_environment "$env_name" && echo "true" || echo "false")"
            ;;
    esac
}

# Main execution function
main() {
    # Parse arguments
    parse_arguments "$@"

    # Validate environment exists
    if ! validate_environment_exists "$ENV_NAME"; then
        exit 1
    fi

    # Display information based on options
    if [[ "$CONFIG_ONLY" == "true" ]]; then
        get_config_details "$ENV_NAME"
    elif [[ "$SECRETS_ONLY" == "true" ]]; then
        get_secrets_info "$ENV_NAME"
    elif [[ "$REGIONS_ONLY" == "true" ]]; then
        get_regions_info "$ENV_NAME"
    else
        # Show all information
        show_environment_summary "$ENV_NAME"
        echo ""
        get_config_details "$ENV_NAME"
        echo ""
        get_secrets_info "$ENV_NAME"
        echo ""
        get_regions_info "$ENV_NAME"
    fi
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi