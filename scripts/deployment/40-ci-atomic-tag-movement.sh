#!/bin/bash
# T103: Atomic tag movement script for environment tags and version tracking

set -euo pipefail

# Script configuration
SCRIPT_NAME="$(basename "$0" .sh)"
SCRIPT_VERSION="1.0.0"
SCRIPT_MODE="${CI_ATOMIC_TAG_MODE:-${CI_TEST_MODE:-default}}"
LOG_LEVEL="${CI_LOG_LEVEL:-info}"

# Tag naming conventions
VERSION_TAG_PREFIX="v"
ENVIRONMENT_TAG_PREFIX="env/"
STATE_TAG_PREFIX="state/"
DEPLOYMENT_TAG_PREFIX="deploy/"

# Tag types and their properties
declare -a TAG_TYPES=(
    "version:immutable:Version tags (v1.2.3) - never move after creation"
    "environment:movable:Environment tags (env/staging, env/production) - point to current deployment"
    "state:immutable:State tags (state/success, state/failed) - mark deployment outcomes"
    "deployment:immutable:Deployment tags (deploy/2024-01-01-deploy-123) - track specific deployments"
)

# Environment tag configurations
declare -a ENVIRONMENT_TAGS=(
    "env/staging:Points to current staging deployment"
    "env/production:Points to current production deployment"
    "env/rollback-staging:Previous stable staging version"
    "env/rollback-production:Previous stable production version"
    "env/candidate:Candidate for next production deployment"
)

# State tag configurations
declare -a STATE_TAGS=(
    "state/staging-success:Last successful staging deployment"
    "state/production-success:Last successful production deployment"
    "state/staging-failed:Last failed staging deployment"
    "state/production-failed:Last failed production deployment"
    "state/rollback-initiated:Rollback was initiated"
    "state/emergency:Emergency state marker"
)

# Source libraries and utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/config.sh"
source "${SCRIPT_DIR}/../lib/logging.sh"
source "${SCRIPT_DIR}/../lib/validation.sh"
source "${SCRIPT_DIR}/../lib/git.sh"

# Function to validate tag name format
validate_tag_name() {
    local tag_name="$1"
    local tag_type="$2"

    case "$tag_type" in
        "version")
            if [[ ! "$tag_name" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$ ]]; then
                log_error "Invalid version tag format: $tag_name"
                log_info "Expected format: vX.Y.Z or vX.Y.Z-prerelease"
                return 1
            fi
            ;;
        "environment")
            if [[ ! "$tag_name" =~ ^env/[a-zA-Z0-9_-]+$ ]]; then
                log_error "Invalid environment tag format: $tag_name"
                log_info "Expected format: env/<environment-name>"
                return 1
            fi
            ;;
        "state")
            if [[ ! "$tag_name" =~ ^state/[a-zA-Z0-9_-]+$ ]]; then
                log_error "Invalid state tag format: $tag_name"
                log_info "Expected format: state/<state-name>"
                return 1
            fi
            ;;
        "deployment")
            if [[ ! "$tag_name" =~ ^deploy/[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-zA-Z0-9_-]+$ ]]; then
                log_error "Invalid deployment tag format: $tag_name"
                log_info "Expected format: deploy/YYYY-MM-DD-<identifier>"
                return 1
            fi
            ;;
        *)
            log_error "Unknown tag type: $tag_type"
            return 1
            ;;
    esac

    return 0
}

# Function to check if tag exists
tag_exists() {
    local tag_name="$1"

    git rev-parse --verify "refs/tags/$tag_name" &> /dev/null
}

# Function to get tag commit hash
get_tag_commit() {
    local tag_name="$1"

    git rev-list -n 1 "$tag_name" 2>/dev/null || echo ""
}

# Function to check if tag is movable (not a version tag)
is_movable_tag() {
    local tag_name="$1"

    # Version tags and deployment tags are immutable
    if [[ "$tag_name" =~ ^v[0-9] ]] || [[ "$tag_name" =~ ^deploy/ ]]; then
        return 1
    fi

    # Environment and state tags are movable
    if [[ "$tag_name" =~ ^env/ ]] || [[ "$tag_name" =~ ^state/ ]]; then
        return 0
    fi

    return 1
}

# Function to create atomic tag
create_atomic_tag() {
    local tag_name="$1"
    local target_commit="$2"
    local tag_type="$3"
    local message="$4"
    local force="${5:-false}"

    log_info "Creating atomic tag: $tag_name"

    # Validate tag name format
    validate_tag_name "$tag_name" "$tag_type" || return 1

    # Validate target commit
    if ! git rev-parse --verify "$target_commit" &> /dev/null; then
        log_error "Invalid target commit: $target_commit"
        return 1
    fi

    # Check if tag already exists
    if tag_exists "$tag_name"; then
        if [[ "$force" != "true" ]] && ! is_movable_tag "$tag_name"; then
            log_error "Tag $tag_name already exists and is immutable"
            log_info "Use force=true to override (not recommended for version tags)"
            return 1
        fi

        local existing_commit
        existing_commit=$(get_tag_commit "$tag_name")
        if [[ "$existing_commit" == "$target_commit" ]]; then
            log_info "Tag $tag_name already points to $target_commit"
            return 0
        fi
    fi

    # Create the tag atomically
    local tag_args=()
    if [[ "$force" == "true" ]]; then
        tag_args+=("-f")
    fi

    if [[ -n "$message" ]]; then
        tag_args+=("-m" "$message")
    fi

    # Atomic tag creation with retry
    local max_attempts=3
    local attempt=1

    while [[ $attempt -le $max_attempts ]]; do
        log_debug "Tag creation attempt $attempt/$max_attempts"

        if git tag "${tag_args[@]}" "$tag_name" "$target_commit"; then
            log_success "Tag $tag_name created successfully pointing to $target_commit"
            return 0
        else
            log_warn "Tag creation attempt $attempt failed"
            if [[ $attempt -eq $max_attempts ]]; then
                log_error "Failed to create tag $tag_name after $max_attempts attempts"
                return 1
            fi
            sleep 1
            ((attempt++))
        fi
    done

    return 1
}

# Function to move environment tag atomically
move_environment_tag() {
    local environment="$1"
    local target_commit="$2"
    local deployment_id="$3"
    local region="${4:-global}"

    local tag_name="env/$environment"
    local message="Deploy $deployment_id to $environment ($region) - $(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    log_info "Moving environment tag: $tag_name"

    # Validate environment name
    local valid_environments=("staging" "production" "rollback-staging" "rollback-production" "candidate")
    if [[ ! " ${valid_environments[*]} " =~ " $environment " ]]; then
        log_error "Invalid environment: $environment"
        log_info "Valid environments: ${valid_environments[*]}"
        return 1
    fi

    # Create backup of current tag if it exists
    if tag_exists "$tag_name"; then
        local current_commit
        current_commit=$(get_tag_commit "$tag_name")
        local backup_tag="backup/${tag_name}/$(date -u +"%Y%m%d%H%M%S")"

        log_info "Creating backup tag: $backup_tag"
        create_atomic_tag "$backup_tag" "$current_commit" "deployment" "Backup of $tag_name before move"
    fi

    # Move the environment tag atomically
    if create_atomic_tag "$tag_name" "$target_commit" "environment" "$message" "true"; then
        log_success "Environment tag $tag_name moved to $target_commit"

        # Record tag movement
        record_tag_movement "$tag_name" "$target_commit" "$deployment_id" "$environment" "$region"
        return 0
    else
        log_error "Failed to move environment tag $tag_name"
        return 1
    fi
}

# Function to create version tag
create_version_tag() {
    local version="$1"
    local target_commit="$2"
    local message="${3:-Release version $version}"

    local tag_name="$version"

    log_info "Creating version tag: $tag_name"

    # Validate version format
    if [[ ! "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$ ]]; then
        log_error "Invalid version format: $version"
        log_info "Expected format: vX.Y.Z or vX.Y.Z-prerelease"
        return 1
    fi

    # Check if version tag already exists (version tags are immutable)
    if tag_exists "$tag_name"; then
        log_error "Version tag $tag_name already exists and is immutable"
        log_info "Version tags cannot be moved. Use a different version number."
        return 1
    fi

    # Create the version tag
    if create_atomic_tag "$tag_name" "$target_commit" "version" "$message"; then
        log_success "Version tag $tag_name created at $target_commit"

        # Record version tag creation
        record_version_creation "$tag_name" "$target_commit" "$message"
        return 0
    else
        log_error "Failed to create version tag $tag_name"
        return 1
    fi
}

# Function to create state tag
create_state_tag() {
    local state="$1"
    local target_commit="$2"
    local environment="$3"
    local deployment_id="$4"

    local tag_name="state/$state"
    local message="State: $state for deployment $deployment_id ($environment) - $(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    log_info "Creating state tag: $tag_name"

    # Validate state name
    local valid_states=("staging-success" "staging-failed" "production-success" "production-failed" "rollback-initiated" "emergency")
    if [[ ! " ${valid_states[*]} " =~ " $state " ]]; then
        log_error "Invalid state: $state"
        log_info "Valid states: ${valid_states[*]}"
        return 1
    fi

    # Create the state tag
    if create_atomic_tag "$tag_name" "$target_commit" "state" "$message" "true"; then
        log_success "State tag $tag_name created at $target_commit"

        # Record state change
        record_state_change "$tag_name" "$target_commit" "$state" "$environment" "$deployment_id"
        return 0
    else
        log_error "Failed to create state tag $tag_name"
        return 1
    fi
}

# Function to create deployment tag
create_deployment_tag() {
    local deployment_id="$1"
    local target_commit="$2"
    local environment="$3"
    local region="${4:-global}"

    local timestamp
    timestamp=$(date -u +"%Y-%m-%d")
    local tag_name="deploy/${timestamp}-${deployment_id}"
    local message="Deployment $deployment_id to $environment ($region) - $(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    log_info "Creating deployment tag: $tag_name"

    # Create the deployment tag
    if create_atomic_tag "$tag_name" "$target_commit" "deployment" "$message"; then
        log_success "Deployment tag $tag_name created at $target_commit"

        # Record deployment tag creation
        record_deployment_tag_creation "$tag_name" "$target_commit" "$deployment_id" "$environment" "$region"
        return 0
    else
        log_error "Failed to create deployment tag $tag_name"
        return 1
    fi
}

# Function to record tag movement
record_tag_movement() {
    local tag_name="$1"
    local target_commit="$2"
    local deployment_id="$3"
    local environment="$4"
    local region="$5"

    local record_file="${PROJECT_ROOT}/.tag_movements.log"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    echo "${timestamp} MOVE $tag_name $target_commit $deployment_id $environment $region" >> "$record_file"
    log_debug "Recorded tag movement: $tag_name -> $target_commit"
}

# Function to record version tag creation
record_version_creation() {
    local tag_name="$1"
    local target_commit="$2"
    local message="$3"

    local record_file="${PROJECT_ROOT}/.version_tags.log"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    echo "${timestamp} CREATE $tag_name $target_commit $message" >> "$record_file"
    log_debug "Recorded version creation: $tag_name"
}

# Function to record state change
record_state_change() {
    local tag_name="$1"
    local target_commit="$2"
    local state="$3"
    local environment="$4"
    local deployment_id="$5"

    local record_file="${PROJECT_ROOT}/.state_changes.log"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    echo "${timestamp} STATE $tag_name $target_commit $state $environment $deployment_id" >> "$record_file"
    log_debug "Recorded state change: $state"
}

# Function to record deployment tag creation
record_deployment_tag_creation() {
    local tag_name="$1"
    local target_commit="$2"
    local deployment_id="$3"
    local environment="$4"
    local region="$5"

    local record_file="${PROJECT_ROOT}/.deployment_tags.log"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    echo "${timestamp} DEPLOY $tag_name $target_commit $deployment_id $environment $region" >> "$record_file"
    log_debug "Recorded deployment tag: $tag_name"
}

# Function to get current environment tag
get_environment_tag() {
    local environment="$1"

    local tag_name="env/$environment"

    if tag_exists "$tag_name"; then
        get_tag_commit "$tag_name"
    else
        echo ""
    fi
}

# Function to get deployment history
get_deployment_history() {
    local environment="$1"
    local limit="${2:-10}"

    log_info "Getting deployment history for $environment (last $limit deployments)"

    echo
    log_info "Deployment History for $environment:"
    printf "%-20s %-12s %-20s %-15s %s\n" "TIMESTAMP" "ENVIRONMENT" "DEPLOYMENT_ID" "COMMIT" "STATUS"
    printf "%-20s %-12s %-20s %-15s %s\n" "--------------------" "------------" "--------------------" "---------------" "--------------"

    local record_file="${PROJECT_ROOT}/.tag_movements.log"
    if [[ -f "$record_file" ]]; then
        grep "MOVE env/$environment " "$record_file" | tail -n "$limit" | while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                local timestamp
                local tag_name
                local commit
                local deployment_id
                local env
                local region

                read -r timestamp tag_name commit deployment_id env region <<< "$line"

                # Determine status by checking state tags
                local status="unknown"
                if tag_exists "state/${environment}-success" && [[ "$(get_tag_commit "state/${environment}-success")" == "$commit" ]]; then
                    status="success"
                elif tag_exists "state/${environment}-failed" && [[ "$(get_tag_commit "state/${environment}-failed")" == "$commit" ]]; then
                    status="failed"
                fi

                printf "%-20s %-12s %-20s %-15s %s\n" "$timestamp" "$env" "$deployment_id" "${commit:0:12}" "$status"
            fi
        done
    else
        echo "No deployment history found"
    fi
}

# Function to show current tag status
show_tag_status() {
    log_info "Current tag status"

    echo
    log_info "Environment Tags:"
    for env_tag in "${ENVIRONMENT_TAGS[@]}"; do
        local tag_name
        tag_name=$(echo "$env_tag" | cut -d':' -f1)
        local description
        description=$(echo "$env_tag" | cut -d':' -f2)

        if tag_exists "$tag_name"; then
            local commit
            commit=$(get_tag_commit "$tag_name")
            local commit_date
            commit_date=$(git show -s --format=%ci "$commit" 2>/dev/null || echo "unknown")
            echo "  ✓ $tag_name: ${commit:0:12} ($commit_date) - $description"
        else
            echo "  ✗ $tag_name: not found - $description"
        fi
    done

    echo
    log_info "Recent Version Tags:"
    git tag --sort=-version:refname | grep "^v[0-9]" | head -n 5 | while read -r tag; do
        local commit
        commit=$(get_tag_commit "$tag")
        local commit_date
        commit_date=$(git show -s --format=%ci "$commit" 2>/dev/null || echo "unknown")
        echo "  ✓ $tag: ${commit:0:12} ($commit_date)"
    done

    echo
    log_info "Recent State Tags:"
    git tag --sort=-creatordate | grep "^state/" | head -n 5 | while read -r tag; do
        local commit
        commit=$(get_tag_commit "$tag")
        local commit_date
        commit_date=$(git show -s --format=%ci "$commit" 2>/dev/null || echo "unknown")
        echo "  ✓ $tag: ${commit:0:12} ($commit_date)"
    done

    echo
    log_info "Recent Deployment Tags:"
    git tag --sort=-creatordate | grep "^deploy/" | head -n 5 | while read -r tag; do
        local commit
        commit=$(get_tag_commit "$tag")
        local commit_date
        commit_date=$(git show -s --format=%ci "$commit" 2>/dev/null || echo "unknown")
        echo "  ✓ $tag: ${commit:0:12} ($commit_date)"
    done
}

# Function to validate tag consistency
validate_tag_consistency() {
    log_info "Validating tag consistency"

    local errors=0

    # Check environment tags point to valid commits
    for env_tag in "${ENVIRONMENT_TAGS[@]}"; do
        local tag_name
        tag_name=$(echo "$env_tag" | cut -d':' -f1)

        if tag_exists "$tag_name"; then
            local commit
            commit=$(get_tag_commit "$tag_name")

            if ! git rev-parse --verify "$commit" &> /dev/null; then
                log_error "Environment tag $tag_name points to invalid commit: $commit"
                ((errors++))
            fi
        fi
    done

    # Check version tags are immutable (no duplicates)
    local version_tags
    version_tags=$(git tag | grep "^v[0-9]" | sort -V)
    local prev_tag=""
    while read -r tag; do
        if [[ -n "$tag" ]]; then
            if tag_exists "$tag"; then
                local commit
                commit=$(get_tag_commit "$tag")
                if [[ -n "$prev_tag" ]] && [[ "$(get_tag_commit "$prev_tag")" == "$commit" ]]; then
                    log_error "Version tags $prev_tag and $tag point to same commit"
                    ((errors++))
                fi
                prev_tag="$tag"
            fi
        fi
    done <<< "$version_tags"

    # Check for orphaned deployment tags
    local deployment_tags
    deployment_tags=$(git tag | grep "^deploy/" | sort -r)
    while read -r tag; do
        if [[ -n "$tag" ]]; then
            local commit
            commit=$(get_tag_commit "$tag")
            local has_env_tag=false

            for env_tag in "env/staging" "env/production"; do
                if tag_exists "$env_tag" && [[ "$(get_tag_commit "$env_tag")" == "$commit" ]]; then
                    has_env_tag=true
                    break
                fi
            done

            if [[ "$has_env_tag" == "false" ]]; then
                log_warn "Deployment tag $tag appears to be orphaned (no matching environment tag)"
            fi
        fi
    done <<< "$deployment_tags"

    if [[ $errors -eq 0 ]]; then
        log_success "Tag consistency validation passed"
        return 0
    else
        log_error "Tag consistency validation failed with $errors errors"
        return 1
    fi
}

# Function to push tags to remote
push_tags_to_remote() {
    local remote="${1:-origin}"
    local tag_pattern="${2:-*}"

    log_info "Pushing tags to remote: $remote (pattern: $tag_pattern)"

    if ! git remote get-url "$remote" &> /dev/null; then
        log_error "Remote $remote not found"
        return 1
    fi

    # Push tags matching pattern
    if git push "$remote" "refs/tags/$tag_pattern"; then
        log_success "Tags pushed to $remote successfully"
        return 0
    else
        log_error "Failed to push tags to $remote"
        return 1
    fi
}

# Main function
main() {
    local command="${1:-status}"
    local arg1="${2:-}"
    local arg2="${3:-}"
    local arg3="${4:-}"
    local arg4="${5:-}"

    # Initialize logging and configuration
    initialize_logging "$LOG_LEVEL" "ci-atomic-tag-movement"
    load_project_config

    case "$command" in
        "create-version")
            if [[ -z "$arg1" || -z "$arg2" ]]; then
                log_error "Version and commit are required"
                echo "Usage: $0 create-version <version> <commit> [message]"
                exit 1
            fi
            create_version_tag "$arg1" "$arg2" "$arg3"
            ;;
        "move-environment")
            if [[ -z "$arg1" || -z "$arg2" || -z "$arg3" ]]; then
                log_error "Environment, commit, and deployment_id are required"
                echo "Usage: $0 move-environment <environment> <commit> <deployment_id> [region]"
                exit 1
            fi
            move_environment_tag "$arg1" "$arg2" "$arg3" "$arg4"
            ;;
        "create-state")
            if [[ -z "$arg1" || -z "$arg2" || -z "$arg3" || -z "$arg4" ]]; then
                log_error "State, commit, environment, and deployment_id are required"
                echo "Usage: $0 create-state <state> <commit> <environment> <deployment_id>"
                exit 1
            fi
            create_state_tag "$arg1" "$arg2" "$arg3" "$arg4"
            ;;
        "create-deployment")
            if [[ -z "$arg1" || -z "$arg2" || -z "$arg3" ]]; then
                log_error "Deployment_id, commit, and environment are required"
                echo "Usage: $0 create-deployment <deployment_id> <commit> <environment> [region]"
                exit 1
            fi
            create_deployment_tag "$arg1" "$arg2" "$arg3" "$arg4"
            ;;
        "get-environment")
            if [[ -z "$arg1" ]]; then
                log_error "Environment is required"
                echo "Usage: $0 get-environment <environment>"
                exit 1
            fi
            get_environment_tag "$arg1"
            ;;
        "history")
            if [[ -z "$arg1" ]]; then
                log_error "Environment is required"
                echo "Usage: $0 history <environment> [limit]"
                exit 1
            fi
            get_deployment_history "$arg1" "${arg2:-10}"
            ;;
        "status")
            show_tag_status
            ;;
        "validate")
            validate_tag_consistency
            ;;
        "push")
            local remote="${arg1:-origin}"
            local pattern="${arg2:-*}"
            push_tags_to_remote "$remote" "$pattern"
            ;;
        *)
            log_error "Unknown command: $command"
            echo
            echo "Usage: $0 [command] [args...]"
            echo
            echo "Commands:"
            echo "  create-version <version> <commit> [message]  Create immutable version tag"
            echo "  move-environment <env> <commit> <deploy_id> [region]  Move environment tag atomically"
            echo "  create-state <state> <commit> <env> <deploy_id>  Create state tag"
            echo "  create-deployment <deploy_id> <commit> <env> [region]  Create deployment tag"
            echo "  get-environment <environment>                     Get current environment tag commit"
            echo "  history <environment> [limit]                     Show deployment history"
            echo "  status                                           Show current tag status"
            echo "  validate                                         Validate tag consistency"
            echo "  push [remote] [pattern]                          Push tags to remote"
            echo
            echo "Examples:"
            echo "  $0 create-version v1.2.3 abc123               Create version tag"
            echo "  $0 move-environment production abc123 deploy-456 Move production tag"
            echo "  $0 create-state production-success abc123 production deploy-456 Create state tag"
            echo "  $0 create-deployment deploy-456 abc123 production     Create deployment tag"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"