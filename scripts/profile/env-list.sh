#!/bin/bash
# CI Excellence Framework - Environment List Script
# Description: List and display information about available environments

set -euo pipefail

# Script Configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load CI Framework Libraries
source "${SCRIPT_DIR}/../lib/common.sh"
source "${SCRIPT_DIR}/../lib/environment.sh"

# Environment Management Constants
readonly DEFAULT_ENVIRONMENTS=("staging" "production")

# Usage information
usage() {
    cat << EOF
Usage: $SCRIPT_NAME [options]

List available environments with detailed information.

Options:
  --detailed         Show detailed environment information
  --type TYPE        Filter by environment type (development|testing|staging|production)
  --format FORMAT    Output format (table|json|yaml) - default: table
  --help             Show this help message

Examples:
  $SCRIPT_NAME
  $SCRIPT_NAME --detailed
  $SCRIPT_NAME --type development
  $SCRIPT_NAME --format json

EOF
}

# Parse command line arguments
parse_arguments() {
    DETAILED=false
    FILTER_TYPE=""
    OUTPUT_FORMAT="table"

    while [[ $# -gt 0 ]]; do
        case $1 in
            --detailed)
                DETAILED=true
                shift
                ;;
            --type)
                FILTER_TYPE="$2"
                shift 2
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
                log_error "Unexpected argument: $1"
                usage
                exit 1
                ;;
        esac
    done

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
}

# Get environment type from configuration
get_environment_type() {
    local env_name="$1"
    local config_file="environments/$env_name/config.yml"

    if [[ -f "$config_file" ]]; then
        if command -v yq >/dev/null 2>&1; then
            yq eval '.environment.type // "unknown"' "$config_file" 2>/dev/null || echo "unknown"
        else
            echo "unknown"
        fi
    else
        echo "unknown"
    fi
}

# Get environment description
get_environment_description() {
    local env_name="$1"
    local config_file="environments/$env_name/config.yml"

    if [[ -f "$config_file" ]]; then
        if command -v yq >/dev/null 2>&1; then
            yq eval '.environment.description // "No description"' "$config_file" 2>/dev/null || echo "No description"
        else
            echo "Use yq to view description"
        fi
    else
        echo "No configuration found"
    fi
}

# Get environment inheritance information
get_environment_inheritance() {
    local env_name="$1"
    local config_file="environments/$env_name/config.yml"

    if [[ -f "$config_file" ]]; then
        if command -v yq >/dev/null 2>&1; then
            yq eval '.extends // "none"' "$config_file" 2>/dev/null || echo "none"
        else
            echo "unknown"
        fi
    else
        echo "none"
    fi
}

# Get environment creation date
get_environment_created() {
    local env_name="$1"
    local config_file="environments/$env_name/config.yml"

    if [[ -f "$config_file" ]]; then
        if command -v yq >/dev/null 2>&1; then
            yq eval '.environment.created // "unknown"' "$config_file" 2>/dev/null || echo "unknown"
        else
            echo "unknown"
        fi
    else
        echo "unknown"
    fi
}

# Get environment regions
get_environment_regions() {
    local env_name="$1"
    local regions_dir="environments/$env_name/regions"

    if [[ -d "$regions_dir" ]]; then
        local regions=()
        for region_dir in "$regions_dir"/*/; do
            if [[ -d "$region_dir" && -f "$region_dir/config.yml" ]]; then
                local region_name
                region_name=$(basename "$region_dir")
                regions+=("$region_name")
            fi
        done

        if [[ ${#regions[@]} -gt 0 ]]; then
            printf '%s' "${regions[*]}"
        else
            echo "none"
        fi
    else
        echo "none"
    fi
}

# Check if environment has secrets file
has_environment_secrets() {
    local env_name="$1"

    if [[ -f "environments/$env_name/secrets.json" ]] || [[ -f "environments/$env_name/secrets.enc" ]]; then
        echo "yes"
    else
        echo "no"
    fi
}

# Display environments in table format
display_table() {
    local environments=("$@")

    if [[ ${#environments[@]} -eq 0 ]]; then
        log_info "No environments found"
        return 0
    fi

    if [[ "$DETAILED" == "true" ]]; then
        printf "%-20s %-12s %-15s %-12s %-20s %-15s %-8s\n" \
            "ENVIRONMENT" "TYPE" "INHERITS" "REGIONS" "CREATED" "DESCRIPTION" "SECRETS"
        printf "%-20s %-12s %-15s %-12s %-20s %-15s %-8s\n" \
            "--------------------" "------------" "---------------" "------------" "--------------------" "---------------" "--------"
    else
        printf "%-20s %-12s %-15s %-8s\n" \
            "ENVIRONMENT" "TYPE" "INHERITS" "SECRETS"
        printf "%-20s %-12s %-15s %-8s\n" \
            "--------------------" "------------" "---------------" "--------"
    fi

    for env in "${environments[@]}"; do
        local env_type
        local inheritance
        local created
        local description
        local regions
        local has_secrets

        env_type=$(get_environment_type "$env")
        inheritance=$(get_environment_inheritance "$env")
        created=$(get_environment_created "$env")
        description=$(get_environment_description "$env")
        regions=$(get_environment_regions "$env")
        has_secrets=$(has_environment_secrets "$env")

        if [[ "$DETAILED" == "true" ]]; then
            # Truncate description if too long
            if [[ ${#description} -gt 15 ]]; then
                description="${description:0:12}..."
            fi

            # Truncate created date if too long
            if [[ ${#created} -gt 20 ]]; then
                created="${created:0:17}..."
            fi

            printf "%-20s %-12s %-15s %-12s %-20s %-15s %-8s\n" \
                "$env" "$env_type" "$inheritance" "$regions" "$created" "$description" "$has_secrets"
        else
            printf "%-20s %-12s %-15s %-8s\n" \
                "$env" "$env_type" "$inheritance" "$has_secrets"
        fi
    done

    echo ""
    log_info "Total environments: ${#environments[@]}"

    # Show default environments
    local default_count=0
    for env in "${environments[@]}"; do
        if is_default_environment "$env"; then
            default_count=$((default_count + 1))
        fi
    done
    log_info "Default environments: $default_count"
    log_info "Custom environments: $((${#environments[@]} - default_count))"
}

# Display environments in JSON format
display_json() {
    local environments=("$@")

    echo "{"
    echo "  \"environments\": ["

    local first=true
    for env in "${environments[@]}"; do
        if [[ "$first" == "false" ]]; then
            echo ","
        fi
        first=false

        local env_type
        local inheritance
        local created
        local description
        local regions
        local has_secrets
        local is_default

        env_type=$(get_environment_type "$env")
        inheritance=$(get_environment_inheritance "$env")
        created=$(get_environment_created "$env")
        description=$(get_environment_description "$env")
        regions=$(get_environment_regions "$env")
        has_secrets=$(has_environment_secrets "$env")
        is_default="false"

        if is_default_environment "$env"; then
            is_default="true"
        fi

        # Convert regions string to JSON array
        local regions_json="[]"
        if [[ "$regions" != "none" ]]; then
            regions_json=$(echo "$regions" | tr ' ' '\n' | jq -R . | jq -s .)
        fi

        cat << EOF
    {
      "name": "$env",
      "type": "$env_type",
      "inherits": "$inheritance",
      "created": "$created",
      "description": $([[ "$description" == *" "* ]] && echo "\"$description\"" || echo "\"$description\""),
      "regions": $regions_json,
      "has_secrets": $has_secrets,
      "is_default": $is_default
EOF
        echo -n "    }"
    done

    echo ""
    echo "  ],"
    echo "  \"summary\": {"
    echo "    \"total_count": ${#environments[@]},"
    echo "    \"default_count\": $(echo "${environments[@]}" | tr ' ' '\n' | grep -E "^(staging|production)$" | wc -l | tr -d ' '),"
    echo "    \"custom_count\": $((${#environments[@]} - $(echo "${environments[@]}" | tr ' ' '\n' | grep -E "^(staging|production)$" | wc -l | tr -d ' ')))"
    echo "  }"
    echo "}"
}

# Display environments in YAML format
display_yaml() {
    local environments=("$@")

    echo "environments:"
    for env in "${environments[@]}"; do
        local env_type
        local inheritance
        local created
        local description
        local regions
        local has_secrets
        local is_default

        env_type=$(get_environment_type "$env")
        inheritance=$(get_environment_inheritance "$env")
        created=$(get_environment_created "$env")
        description=$(get_environment_description "$env")
        regions=$(get_environment_regions "$env")
        has_secrets=$(has_environment_secrets "$env")
        is_default="false"

        if is_default_environment "$env"; then
            is_default="true"
        fi

        echo "  - name: $env"
        echo "    type: $env_type"
        echo "    inherits: $inheritance"
        echo "    created: $created"
        echo "    description: \"$description\""
        echo "    regions: [$regions]"
        echo "    has_secrets: $has_secrets"
        echo "    is_default: $is_default"
    done

    echo ""
    echo "summary:"
    echo "  total_count: ${#environments[@]}"
    echo "  default_count: $(echo "${environments[@]}" | tr ' ' '\n' | grep -E "^(staging|production)$" | wc -l | tr -d ' ')"
    echo "  custom_count: $((${#environments[@]} - $(echo "${environments[@]}" | tr ' ' '\n' | grep -E "^(staging|production)$" | wc -l | tr -d ' '))"
}

# Main execution function
main() {
    # Parse arguments
    parse_arguments "$@"

    # Get all environments
    local all_environments
    all_environments=($(discover_environments))

    # Filter by type if specified
    local filtered_environments=()
    if [[ -n "$FILTER_TYPE" ]]; then
        for env in "${all_environments[@]}"; do
            local env_type
            env_type=$(get_environment_type "$env")
            if [[ "$env_type" == "$FILTER_TYPE" ]]; then
                filtered_environments+=("$env")
            fi
        done
    else
        filtered_environments=("${all_environments[@]}")
    fi

    # Sort environments
    IFS=$'\n' filtered_environments=($(sort <<<"${filtered_environments[*]}"))
    unset IFS

    # Display based on format
    case "$OUTPUT_FORMAT" in
        "table")
            display_table "${filtered_environments[@]}"
            ;;
        "json")
            if command -v jq >/dev/null 2>&1; then
                display_json "${filtered_environments[@]}" | jq .
            else
                display_json "${filtered_environments[@]}"
            fi
            ;;
        "yaml")
            display_yaml "${filtered_environments[@]}"
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi