#!/bin/bash
# CI Excellence Framework - Environment Secrets Migration Script
# Description: Migrate .enc secret files to JSON format with inheritance support

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
readonly BACKUP_DIR="environments/.secrets-backup"

# Usage information
usage() {
    cat << EOF
Usage: $SCRIPT_NAME [environment_name] [options]

Migrate environment secrets from .enc format to JSON format with inheritance support.

Arguments:
  environment_name    Name of environment to migrate (optional, migrates all if not provided)

Options:
  --backup           Create backup of original .enc files
  --dry-run          Show what would be migrated without making changes
  --force            Overwrite existing JSON files
  --keep-original    Keep original .enc files after migration
  --help             Show this help message

Examples:
  $SCRIPT_NAME                              # Migrate all environments
  $SCRIPT_NAME staging                     # Migrate specific environment
  $SCRIPT_NAME --backup --keep-original    # Migrate with backup and keep originals
  $SCRIPT_NAME production --dry-run        # Preview migration for production

EOF
}

# Parse command line arguments
parse_arguments() {
    ENV_NAME=""
    CREATE_BACKUP=false
    DRY_RUN=false
    FORCE_OVERWRITE=false
    KEEP_ORIGINAL=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --backup)
                CREATE_BACKUP=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --force)
                FORCE_OVERWRITE=true
                shift
                ;;
            --keep-original)
                KEEP_ORIGINAL=true
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
}

# Create backup directory
create_backup_directory() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY_RUN: Would create backup directory: $BACKUP_DIR"
        return 0
    fi

    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
        log_info "Created backup directory: $BACKUP_DIR"
    fi
}

# Backup .enc file
backup_enc_file() {
    local env_name="$1"
    local enc_file="$ENVIRONMENTS_DIR/$env_name/secrets.enc"

    if [[ -f "$enc_file" ]]; then
        local backup_file="$BACKUP_DIR/${env_name}-secrets.enc.backup.$(date +%Y%m%d_%H%M%S)"

        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "DRY_RUN: Would backup $enc_file to $backup_file"
            return 0
        fi

        cp "$enc_file" "$backup_file"
        log_success "✅ Backed up $enc_file"
        log_info "   Backup: $backup_file"
    fi
}

# Decrypt .enc file content
decrypt_enc_content() {
    local env_name="$1"
    local enc_file="$ENVIRONMENTS_DIR/$env_name/secrets.enc"

    if [[ ! -f "$enc_file" ]]; then
        log_warning "⚠️  No .enc file found for environment '$env_name'"
        return 1
    fi

    if command -v sops >/dev/null 2>&1; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "DRY_RUN: Would decrypt $enc_file"
            return 0
        fi

        local decrypted_content
        decrypted_content=$(sops --decrypt "$enc_file" 2>/dev/null || echo "")

        if [[ -z "$decrypted_content" ]]; then
            log_error "❌ Failed to decrypt $enc_file"
            return 1
        fi

        echo "$decrypted_content"
        return 0
    else
        log_error "❌ sops not available for decryption"
        return 1
    fi
}

# Convert decrypted content to JSON
convert_to_json() {
    local env_name="$1"
    local decrypted_content="$2"
    local json_file="$ENVIRONMENTS_DIR/$env_name/secrets.json"

    # Check if JSON file already exists
    if [[ -f "$json_file" && "$FORCE_OVERWRITE" == "false" ]]; then
        log_warning "⚠️  JSON secrets file already exists: $json_file"
        log_info "   Use --force to overwrite"
        return 1
    fi

    # Create JSON structure
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    local json_content
    json_content=$(cat << EOF
{
  "environment": "$env_name",
  "migrated": {
    "from": "secrets.enc",
    "at": "$timestamp",
    "by": "env-migrate-secrets.sh"
  },
  "original_content": $(
    if command -v jq >/dev/null 2>&1; then
        # Try to parse as JSON first
        if echo "$decrypted_content" | jq . >/dev/null 2>&1; then
            echo "$decrypted_content"
        else
            # Treat as key=value pairs and convert to JSON
            echo "$decrypted_content" | sed 's/^export //' | while IFS='=' read -r key value; do
                if [[ -n "$key" && -n "$value" ]]; then
                    # Remove quotes from value if present
                    value=$(echo "$value" | sed 's/^"//;s/"$//')
                    echo "\"$key\": \"$value\""
                fi
            done | jq -s 'add'
        fi
    else
        # Fallback without jq
        echo "{}"
        log_warning "⚠️  jq not available, cannot properly convert content"
    fi
  ),
  "custom_values": {}
}
EOF
)

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY_RUN: Would create JSON file: $json_file"
        if [[ "$DETAILED" == "true" ]]; then
            echo "Content preview:"
            echo "$json_content" | head -20
            echo "..."
        fi
        return 0
    fi

    # Write JSON file
    echo "$json_content" > "$json_file"

    # Validate generated JSON
    if command -v jq >/dev/null 2>&1; then
        if ! jq . "$json_file" >/dev/null 2>&1; then
            log_error "❌ Generated JSON is invalid"
            return 1
        fi
    fi

    log_success "✅ Created JSON secrets file: $json_file"
    return 0
}

# Migrate single environment
migrate_environment() {
    local env_name="$1"

    log_info "Migrating environment: $env_name"
    echo "----------------------------------------"

    local enc_file="$ENVIRONMENTS_DIR/$env_name/secrets.enc"
    local json_file="$ENVIRONMENTS_DIR/$env_name/secrets.json"

    # Check if .enc file exists
    if [[ ! -f "$enc_file" ]]; then
        log_info "ℹ️  No .enc file found for environment '$env_name'"

        # Check if JSON file already exists
        if [[ -f "$json_file" ]]; then
            log_info "✅ JSON secrets file already exists"
        else
            log_info "ℹ️  No secrets files found for environment '$env_name'"
        fi
        return 0
    fi

    # Create backup if requested
    if [[ "$CREATE_BACKUP" == "true" ]]; then
        backup_enc_file "$env_name"
    fi

    # Decrypt content
    local decrypted_content
    decrypted_content=$(decrypt_enc_content "$env_name")

    if [[ -z "$decrypted_content" ]]; then
        log_error "❌ Failed to decrypt or no content found"
        return 1
    fi

    # Convert to JSON
    if ! convert_to_json "$env_name" "$decrypted_content"; then
        log_error "❌ Failed to convert to JSON"
        return 1
    fi

    # Remove original file if not keeping it
    if [[ "$KEEP_ORIGINAL" == "false" && "$DRY_RUN" == "false" ]]; then
        rm "$enc_file"
        log_info "🗑️  Removed original .enc file"
    fi

    log_success "✅ Environment '$env_name' migration completed"
    return 0
}

# Migration summary
show_migration_summary() {
    local environments=("$@")
    local total_envs=${#environments[@]}

    echo ""
    log_info "Migration Summary:"
    echo "  Total environments: $total_envs"
    echo "  Backup created: $([[ "$CREATE_BACKUP" == "true" ]] && echo "Yes" || echo "No")"
    echo "  Keep original files: $([[ "$KEEP_ORIGINAL" == "true" ]] && echo "Yes" || echo "No")"
    echo "  Dry run mode: $([[ "$DRY_RUN" == "true" ]] && echo "Yes" || echo "No")"

    if [[ "$CREATE_BACKUP" == "true" ]]; then
        echo "  Backup directory: $BACKUP_DIR"
    fi

    echo ""
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY_RUN completed - no files were modified"
    else
        log_info "Migration completed successfully"

        if [[ "$KEEP_ORIGINAL" == "false" ]]; then
            log_warning "⚠️  Original .enc files were removed"
            log_info "   Backups are available if --backup was used"
        fi

        echo ""
        log_info "Next steps:"
        echo "  1. Verify JSON files: mise run env validate"
        echo "  2. Update any scripts that reference .enc files"
        echo "  3. Test deployments with new JSON secrets"
        if [[ "$KEEP_ORIGINAL" == "true" ]]; then
            echo "  4. Remove original .enc files when ready: rm environments/*/secrets.enc"
        fi
    fi
}

# Main execution function
main() {
    # Parse arguments
    parse_arguments "$@"

    # Create backup directory if requested
    if [[ "$CREATE_BACKUP" == "true" ]]; then
        create_backup_directory
    fi

    # Determine which environments to migrate
    local environments_to_migrate=()
    if [[ -n "$ENV_NAME" ]]; then
        environments_to_migrate=("$ENV_NAME")
    else
        readarray -t environments_to_migrate < <(discover_environments)
    fi

    log_info "Starting secrets migration..."
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY_RUN mode - no files will be modified"
    fi
    echo ""

    local successful_migrations=0
    local failed_migrations=0

    # Migrate each environment
    for env in "${environments_to_migrate[@]}"; do
        if migrate_environment "$env"; then
            successful_migrations=$((successful_migrations + 1))
        else
            failed_migrations=$((failed_migrations + 1))
        fi
        echo ""
    done

    # Show summary
    show_migration_summary "${environments_to_migrate[@]}"

    # Exit with appropriate code
    if [[ $failed_migrations -gt 0 ]]; then
        log_error "❌ $failed_migrations migration(s) failed"
        exit 1
    else
        log_success "✅ All migrations completed successfully"
        exit 0
    fi
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi