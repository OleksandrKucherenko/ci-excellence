#!/bin/bash
# CI Excellence Framework - Environment Deletion Script
# Description: Safely delete custom environments with confirmation

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
readonly DEFAULT_ENVIRONMENTS=("staging" "production")

# Usage information
usage() {
    cat << EOF
Usage: $SCRIPT_NAME <environment_name> [options]

Safely delete a custom environment and all its configuration.

Arguments:
  environment_name    Name of the environment to delete

Options:
  --force            Skip confirmation prompts (use with caution)
  --dry-run          Show what would be deleted without deleting
  --help             Show this help message

Examples:
  $SCRIPT_NAME testing
  $SCRIPT_NAME dev-feature --force
  $SCRIPT_NAME temp-env --dry-run

Protected environments (cannot be deleted): ${DEFAULT_ENVIRONMENTS[*]}

EOF
}

# Parse command line arguments
parse_arguments() {
    ENV_NAME=""
    FORCE_DELETE=false
    DRY_RUN=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                FORCE_DELETE=true
                shift
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
}

# Validate environment can be deleted
validate_deletion() {
    local env_name="$1"

    # Check if environment exists
    if [[ ! -d "$ENVIRONMENTS_DIR/$env_name" ]]; then
        log_error "❌ Environment '$env_name' does not exist"
        log_info "Available environments: $(discover_environments | tr '\n' ' ')"
        return 1
    fi

    # Check if it's a default environment
    if is_default_environment "$env_name"; then
        log_error "❌ Cannot delete default environment '$env_name'"
        log_error "Default environments are protected and cannot be deleted"
        log_info "Default environments: ${DEFAULT_ENVIRONMENTS[*]}"
        return 1
    fi

    return 0
}

# Show environment information before deletion
show_environment_info() {
    local env_name="$1"
    local env_dir="$ENVIRONMENTS_DIR/$env_name"

    log_info "Environment Information:"
    echo "  Name: $env_name"
    echo "  Directory: $env_dir"

    # Show configuration info if available
    if [[ -f "$env_dir/config.yml" ]]; then
        local description
        local env_type
        local created

        if command -v yq >/dev/null 2>&1; then
            description=$(yq eval '.environment.description // "No description"' "$env_dir/config.yml" 2>/dev/null || echo "No description")
            env_type=$(yq eval '.environment.type // "unknown"' "$env_dir/config.yml" 2>/dev/null || echo "unknown")
            created=$(yq eval '.environment.created // "unknown"' "$env_dir/config.yml" 2>/dev/null || echo "unknown")
        else
            description="Use yq to view details"
            env_type="unknown"
            created="unknown"
        fi

        echo "  Type: $env_type"
        echo "  Description: $description"
        echo "  Created: $created"
    fi

    # Show files and directories to be deleted
    echo ""
    log_info "Files and directories that will be deleted:"
    if [[ -d "$env_dir" ]]; then
        find "$env_dir" -type f -o -type d | sed 's/^/  /'
        local file_count
        file_count=$(find "$env_dir" -type f | wc -l)
        local dir_count
        dir_count=$(find "$env_dir" -type d | wc -l)
        echo "  Total: $file_count files, $dir_count directories"
    fi

    # Check for regions
    local regions_dir="$env_dir/regions"
    if [[ -d "$regions_dir" ]]; then
        local region_count
        region_count=$(find "$regions_dir" -maxdepth 1 -type d | wc -l)
        region_count=$((region_count - 1))  # Exclude the regions directory itself
        if [[ $region_count -gt 0 ]]; then
            echo "  Regions: $region_count region configurations"
        fi
    fi
}

# Check for active deployments or references
check_active_references() {
    local env_name="$1"

    log_info "Checking for active references..."

    # Check for environment tags in git
    if command -v git >/dev/null 2>&1; then
        local env_tags
        env_tags=$(git tag 2>/dev/null | grep "^$env_name" || true)

        if [[ -n "$env_tags" ]]; then
            log_warning "⚠️  Found git tags for this environment:"
            echo "$env_tags" | sed 's/^/    /'
            echo ""
            log_warning "These tags will remain after environment deletion"
            log_warning "Consider cleaning up tags after deletion if needed"
        fi
    fi

    # Check for deployment references (basic check)
    local deploy_refs=()

    # Check if environment tag exists (points to current deployment)
    if git rev-parse --verify "$env_name" >/dev/null 2>&1; then
        deploy_refs+=("Git tag: $env_name (points to $(git rev-parse --short "$env_name"))")
    fi

    if [[ ${#deploy_refs[@]} -gt 0 ]]; then
        log_warning "⚠️  Found potential deployment references:"
        printf '    %s\n' "${deploy_refs[@]}"
        echo ""
    fi
}

# Prompt for confirmation
prompt_confirmation() {
    local env_name="$1"

    if [[ "$FORCE_DELETE" == "true" ]]; then
        log_warning "⚠️  Skipping confirmation due to --force flag"
        return 0
    fi

    echo ""
    log_warning "⚠️  WARNING: This will permanently delete environment '$env_name'"
    log_warning "   - All configuration files"
    log_warning "   - All secrets and credentials"
    log_warning "   - All region configurations"
    log_warning "   - Environment history and settings"
    echo ""

    # First confirmation - type environment name
    read -p "Type '$env_name' to confirm deletion: " -r confirmation

    if [[ "$confirmation" != "$env_name" ]]; then
        log_error "❌ Environment deletion cancelled - confirmation mismatch"
        exit 1
    fi

    # Second confirmation - type DELETE
    read -p "Type 'DELETE' to confirm permanent deletion: " -r final_confirmation

    if [[ "$final_confirmation" != "DELETE" ]]; then
        log_error "❌ Environment deletion cancelled - safety word not entered"
        exit 1
    fi

    echo ""
    log_info "✅ Deletion confirmed by user"
}

# Perform the deletion
delete_environment() {
    local env_name="$1"
    local env_dir="$ENVIRONMENTS_DIR/$env_name"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY_RUN: Would delete environment directory:"
        log_info "  rm -rf $env_dir"
        return 0
    fi

    log_info "Deleting environment directory..."

    # Double-check we're deleting the right thing
    if [[ ! -d "$env_dir" ]]; then
        log_error "❌ Environment directory not found: $env_dir"
        return 1
    fi

    # Perform the deletion
    rm -rf "$env_dir"

    # Verify deletion
    if [[ -d "$env_dir" ]]; then
        log_error "❌ Failed to delete environment directory"
        return 1
    fi

    log_success "✅ Environment directory deleted successfully"
}

# Show post-deletion information
show_post_deletion_info() {
    local env_name="$1"

    echo ""
    log_info "Post-deletion Information:"
    echo "  Environment '$env_name' has been deleted"
    echo "  Directory: $ENVIRONMENTS_DIR/$env_name (removed)"

    if [[ "$DRY_RUN" == "false" ]]; then
        echo ""
        log_info "Recommended cleanup actions:"
        echo "  1. Remove any git tags: git tag -d $env_name"
        echo "  2. Remove any deployment references"
        echo "  3. Update documentation that referenced this environment"
        echo "  4. Remove any external service configurations"

        # Check for remaining git tags
        if command -v git >/dev/null 2>&1; then
            local remaining_tags
            remaining_tags=$(git tag 2>/dev/null | grep "^$env_name" || true)
            if [[ -n "$remaining_tags" ]]; then
                echo ""
                log_warning "⚠️  Git tags still exist:"
                echo "$remaining_tags" | sed 's/^/    /'
                echo "Remove them with: git tag -d $env_name"
            fi
        fi
    fi
}

# Main execution function
main() {
    log_info "Starting environment deletion process..."

    # Parse and validate arguments
    parse_arguments "$@"

    # Check testability mode
    local test_mode="${CI_TEST_MODE:-${PIPELINE_SCRIPT_MODE:-EXECUTE}}"
    if [[ "$test_mode" == "DRY_RUN" ]]; then
        DRY_RUN=true
        log_info "DRY_RUN mode enabled by CI_TEST_MODE"
    fi

    # Validate environment can be deleted
    validate_deletion "$ENV_NAME"

    # Show environment information
    show_environment_info "$ENV_NAME"

    # Check for active references
    check_active_references "$ENV_NAME"

    # Prompt for confirmation (unless force mode)
    if [[ "$DRY_RUN" == "false" ]]; then
        prompt_confirmation "$ENV_NAME"
    fi

    # Perform deletion
    delete_environment "$ENV_NAME"

    # Show post-deletion information
    show_post_deletion_info "$ENV_NAME"

    if [[ "$DRY_RUN" == "false" ]]; then
        log_success "✅ Environment '$ENV_NAME' deleted successfully"
    else
        log_info "DRY_RUN: Environment '$ENV_NAME' would be deleted"
    fi
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi