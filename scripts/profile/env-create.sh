#!/bin/bash
# CI Excellence Framework - Environment Creation Script
# Description: Create new environments with inheritance from staging or production

set -euo pipefail

# Script Configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load CI Framework Libraries
source "${SCRIPT_DIR}/../lib/common.sh"
source "${SCRIPT_DIR}/../lib/environment.sh"

# Environment Management Constants
readonly ENVIRONMENTS_DIR="environments"
readonly GLOBAL_ENV_DIR="environments/global"
readonly DEFAULT_ENVIRONMENTS=("staging" "production")

# Usage information
usage() {
    cat << EOF
Usage: $SCRIPT_NAME <environment_name> --from <base_environment> [options]

Create a new environment with inheritance from base configuration.

Arguments:
  environment_name    Name of the new environment to create

Required Options:
  --from BASE         Base environment to inherit from (staging|production)

Options:
  --type TYPE         Environment type (development|testing|staging|production)
                       Default: development
  --description DESC  Environment description
  --dry-run           Show what would be created without creating
  --help              Show this help message

Examples:
  $SCRIPT_NAME testing --from staging
  $SCRIPT_NAME pre-production --from production --type testing
  $SCRIPT_NAME dev-feature --from staging --description "Feature development environment"

Available base environments: ${DEFAULT_ENVIRONMENTS[*]}

EOF
}

# Parse command line arguments
parse_arguments() {
    ENV_NAME=""
    BASE_ENV=""
    ENV_TYPE="development"
    ENV_DESCRIPTION=""
    DRY_RUN=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --from)
                BASE_ENV="$2"
                shift 2
                ;;
            --type)
                ENV_TYPE="$2"
                shift 2
                ;;
            --description)
                ENV_DESCRIPTION="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
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

    if [[ -z "$BASE_ENV" ]]; then
        log_error "Base environment (--from) is required"
        usage
        exit 1
    fi

    # Set default description if not provided
    if [[ -z "$ENV_DESCRIPTION" ]]; then
        ENV_DESCRIPTION="Environment created from $BASE_ENV"
    fi
}

# Validate environment name
validate_env_name() {
    local env_name="$1"

    # Check for valid environment name format
    if [[ ! "$env_name" =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]]; then
        log_error "Invalid environment name: '$env_name'"
        log_error "Environment names must:"
        log_error "  - Start with a lowercase letter or number"
        log_error "  - Contain only lowercase letters, numbers, and hyphens"
        log_error "  - End with a lowercase letter or number"
        log_error "  - Be 1-63 characters long"
        return 1
    fi

    # Check if environment already exists
    if [[ -d "$ENVIRONMENTS_DIR/$env_name" ]]; then
        log_error "❌ Environment '$env_name' already exists"
        return 1
    fi

    # Check if trying to use reserved names
    if is_default_environment "$env_name"; then
        log_error "❌ Cannot create default environment '$env_name' using this command"
        log_info "Default environments: ${DEFAULT_ENVIRONMENTS[*]}"
        return 1
    fi

    return 0
}

# Validate base environment
validate_base_environment() {
    local base_env="$1"

    if ! is_default_environment "$base_env"; then
        log_error "❌ Base environment must be one of: ${DEFAULT_ENVIRONMENTS[*]}"
        return 1
    fi

    if ! validate_environment_exists "$base_env"; then
        log_error "❌ Base environment '$base_env' does not exist or is invalid"
        return 1
    fi

    return 0
}

# Create environment directory structure
create_environment_structure() {
    local env_name="$1"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY_RUN: Would create directory structure:"
        log_info "  mkdir -p $ENVIRONMENTS_DIR/$env_name"
        log_info "  mkdir -p $ENVIRONMENTS_DIR/$env_name/regions"
        log_info "  touch $ENVIRONMENTS_DIR/$env_name/.gitkeep"
        log_info "  touch $ENVIRONMENTS_DIR/$env_name/regions/.gitkeep"
        return 0
    fi

    log_info "Creating environment directory structure..."

    # Create main environment directory
    mkdir -p "$ENVIRONMENTS_DIR/$env_name"
    log_info "Created: $ENVIRONMENTS_DIR/$env_name"

    # Create regions directory
    mkdir -p "$ENVIRONMENTS_DIR/$env_name/regions"
    log_info "Created: $ENVIRONMENTS_DIR/$env_name/regions"

    # Create .gitkeep files to ensure directory structure is tracked
    touch "$ENVIRONMENTS_DIR/$env_name/.gitkeep"
    touch "$ENVIRONMENTS_DIR/$env_name/regions/.gitkeep"
    log_info "Created .gitkeep files for directory tracking"
}

# Generate environment configuration
generate_environment_config() {
    local env_name="$1"
    local base_env="$2"
    local env_type="$3"
    local env_description="$4"

    local config_file="$ENVIRONMENTS_DIR/$env_name/config.yml"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY_RUN: Would create configuration file:"
        log_info "  File: $config_file"
        log_info "  Content:"
        cat << EOF
extends: $base_env

environment:
  name: $env_name
  description: "$env_description"
  type: $env_type
  created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
  inherits:
    - $base_env-secrets
    - $base_env-config

overrides:
  deployment:
    created_by: "mise task env create"
    created_at: "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    strategy: "rolling"
    timeout: "30m"
EOF
        return 0
    fi

    log_info "Creating environment configuration..."

    # Create configuration file with inheritance
    cat > "$config_file" << EOF
extends: $base_env

environment:
  name: $env_name
  description: "$env_description"
  type: $env_type
  created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
  inherits:
    - $base_env-secrets
    - $base_env-config

overrides:
  deployment:
    created_by: "mise task env create"
    created_at: "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    strategy: "rolling"
    timeout: "30m"
EOF

    log_info "Created: $config_file"
}

# Generate environment secrets file
generate_environment_secrets() {
    local env_name="$1"
    local base_env="$2"

    local secrets_file="$ENVIRONMENTS_DIR/$env_name/secrets.json"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY_RUN: Would create secrets file:"
        log_info "  File: $secrets_file"
        log_info "  Content:"
        cat << EOF
{
  "environment": "$env_name",
  "created": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "created_from": "$base_env",
  "inherited_from_$base_env": {
    "message": "Inherited secrets from $base_env environment"
  },
  "custom_values": {}
}
EOF
        return 0
    fi

    log_info "Creating environment secrets file..."

    # Create secrets file with inheritance support
    cat > "$secrets_file" << EOF
{
  "environment": "$env_name",
  "created": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "created_from": "$base_env",
  "inherited_from_$base_env": {
    "message": "Inherited secrets from $base_env environment"
  },
  "custom_values": {}
}
EOF

    log_info "Created: $secrets_file"
}

# Validate created environment
validate_created_environment() {
    local env_name="$1"

    log_info "Validating created environment..."

    if ! validate_environment_exists "$env_name"; then
        log_error "❌ Created environment validation failed"
        return 1
    fi

    # Test YAML syntax
    if command -v yq >/dev/null 2>&1; then
        if ! yq eval "$ENVIRONMENTS_DIR/$env_name/config.yml" >/dev/null 2>&1; then
            log_error "❌ Generated YAML configuration is invalid"
            return 1
        fi
    else
        log_warning "yq not available, skipping YAML validation"
    fi

    # Test JSON syntax for secrets
    if command -v jq >/dev/null 2>&1; then
        if ! jq . "$ENVIRONMENTS_DIR/$env_name/secrets.json" >/dev/null 2>&1; then
            log_error "❌ Generated JSON secrets file is invalid"
            return 1
        fi
    else
        log_warning "jq not available, skipping JSON validation"
    fi

    log_success "✅ Environment '$env_name' validation passed"
}

# Show environment summary
show_environment_summary() {
    local env_name="$1"
    local base_env="$2"

    log_info "Environment Creation Summary:"
    echo "  Environment Name: $env_name"
    echo "  Base Environment: $base_env"
    echo "  Environment Type: $ENV_TYPE"
    echo "  Description: $ENV_DESCRIPTION"
    echo "  Configuration: $ENVIRONMENTS_DIR/$env_name/config.yml"
    echo "  Secrets: $ENVIRONMENTS_DIR/$env_name/secrets.json"
    echo "  Created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "  Status: DRY RUN - No files created"
    else
        echo "  Status: ✅ Successfully created"
        echo ""
        echo "Next steps:"
        echo "  1. Review and customize the configuration: $ENVIRONMENTS_DIR/$env_name/config.yml"
        echo "  2. Add environment-specific secrets: $ENVIRONMENTS_DIR/$env_name/secrets.json"
        echo "  3. Validate the environment: mise run env validate $env_name"
        echo "  4. Test deployment: mise run deploy --environment $env_name"
    fi
}

# Main execution function
main() {
    log_info "Starting environment creation process..."

    # Parse and validate arguments
    parse_arguments "$@"

    # Validate inputs
    validate_env_name "$ENV_NAME"
    validate_base_environment "$BASE_ENV"

    # Check testability mode
    local test_mode="${CI_TEST_MODE:-${PIPELINE_SCRIPT_MODE:-EXECUTE}}"
    if [[ "$test_mode" == "DRY_RUN" ]]; then
        DRY_RUN=true
        log_info "DRY_RUN mode enabled by CI_TEST_MODE"
    fi

    # Create environment
    create_environment_structure
    generate_environment_config "$ENV_NAME" "$BASE_ENV" "$ENV_TYPE" "$ENV_DESCRIPTION"
    generate_environment_secrets "$ENV_NAME" "$BASE_ENV"

    # Validate if not in dry run mode
    if [[ "$DRY_RUN" == "false" ]]; then
        validate_created_environment "$ENV_NAME"
    fi

    # Show summary
    show_environment_summary "$ENV_NAME" "$BASE_ENV"

    if [[ "$DRY_RUN" == "false" ]]; then
        log_success "✅ Environment '$ENV_NAME' created successfully (inherits from $BASE_ENV)"
    fi
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi