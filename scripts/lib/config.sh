#!/bin/bash
# Configuration library for CI scripts

# Global configuration
export SCRIPT_ROOT="${SCRIPT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
export PROJECT_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || echo "$SCRIPT_ROOT")}"

# Load project configuration
load_project_config() {
    local config_file="${PROJECT_ROOT}/.config/ci-config.yml"

    if [[ -f "$config_file" ]]; then
        # Parse YAML config if yq is available
        if command -v yq &> /dev/null; then
            local env_vars
            env_vars=$(yq eval '.environment_variables | to_entries | .[] | "\(.key)=\(.value)"' "$config_file" 2>/dev/null || true)

            while IFS='=' read -r key value; do
                if [[ -n "$key" && -n "$value" ]]; then
                    export "$key"="$value"
                fi
            done <<< "$env_vars"
        fi
    fi

    # Set defaults
    export CI_LOG_LEVEL="${CI_LOG_LEVEL:-info}"
    export CI_PROJECT_NAME="${CI_PROJECT_NAME:-$(basename "$PROJECT_ROOT")}"
    export CI_VERSION="${CI_VERSION:-1.0.0}"
}

# Generate deployment ID
generate_deployment_id() {
    local timestamp
    timestamp=$(date -u +"%Y%m%d%H%M%S")
    local random_suffix
    random_suffix=$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 6)
    echo "deploy-${timestamp}-${random_suffix}"
}

# Check if deployment exists
deployment_exists() {
    local deployment_id="$1"

    [[ -f "${PROJECT_ROOT}/.deployments/${deployment_id}.json" ]]
}

# Create deployment record
create_deployment_record() {
    local deployment_id="$1"
    local environment="$2"
    local region="$3"
    local commit="$4"
    local record_file="${PROJECT_ROOT}/.deployments/${deployment_id}.json"

    mkdir -p "${PROJECT_ROOT}/.deployments"

    cat > "$record_file" << EOF
{
  "deployment_id": "$deployment_id",
  "environment": "$environment",
  "region": "$region",
  "commit": "$commit",
  "status": "pending",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "updated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
}

# Set deployment status
set_deployment_status() {
    local deployment_id="$1"
    local status="$2"
    local message="${3:-}"

    local record_file="${PROJECT_ROOT}/.deployments/${deployment_id}.json"

    if [[ -f "$record_file" ]]; then
        # Update JSON status using jq if available, otherwise sed
        if command -v jq &> /dev/null; then
            jq --arg status "$status" --arg message "$message" --arg updated_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
               '.status = $status | .message = $message | .updated_at = $updated_at' \
               "$record_file" > "${record_file}.tmp" && mv "${record_file}.tmp" "$record_file"
        else
            sed -i "s/\"status\": \"[^\"]*\"/\"status\": \"$status\"/g" "$record_file"
            if [[ -n "$message" ]]; then
                sed -i "s/\"message\": \"[^\"]*\"/\"message\": \"$message\"/g" "$record_file"
            fi
        fi
    fi
}

# Get deployment status
get_deployment_status() {
    local deployment_id="$1"
    local record_file="${PROJECT_ROOT}/.deployments/${deployment_id}.json"

    if [[ -f "$record_file" ]]; then
        if command -v jq &> /dev/null; then
            jq -r '.status' "$record_file" 2>/dev/null || echo "unknown"
        else
            grep -o '"status": "[^"]*"' "$record_file" | cut -d'"' -f4 || echo "unknown"
        fi
    else
        echo "unknown"
    fi
}

# List recent deployments
list_recent_deployments() {
    local environment="$1"
    local limit="${2:-10}"

    local deployments_dir="${PROJECT_ROOT}/.deployments"

    if [[ -d "$deployments_dir" ]]; then
        find "$deployments_dir" -name "*.json" -exec grep -l "\"environment\": \"$environment\"" {} \; | \
        sort -r | head -n "$limit" | while read -r file; do
            if [[ -f "$file" ]]; then
                local deployment_id
                deployment_id=$(basename "$file" .json)
                local commit
                local status
                local created_at

                if command -v jq &> /dev/null; then
                    commit=$(jq -r '.commit' "$file" 2>/dev/null | cut -c1-12)
                    status=$(jq -r '.status' "$file" 2>/dev/null)
                    created_at=$(jq -r '.created_at' "$file" 2>/dev/null)
                else
                    commit=$(grep -o '"commit": "[^"]*"' "$file" | cut -d'"' -f4 | cut -c1-12)
                    status=$(grep -o '"status": "[^"]*"' "$file" | cut -d'"' -f4)
                    created_at=$(grep -o '"created_at": "[^"]*"' "$file" | cut -d'"' -f4)
                fi

                echo "${deployment_id},${commit},${status},${created_at}"
            fi
        done
    fi
}

# List deployments for specific commit
list_deployments_for_commit() {
    local environment="$1"
    local region="$2"
    local commit="$3"

    local deployments_dir="${PROJECT_ROOT}/.deployments"

    if [[ -d "$deployments_dir" ]]; then
        find "$deployments_dir" -name "*.json" -exec grep -l "\"commit\": \"$commit\"" {} \; | \
        while read -r file; do
            if [[ -f "$file" ]]; then
                local file_environment
                local file_region
                local deployment_id

                if command -v jq &> /dev/null; then
                    file_environment=$(jq -r '.environment' "$file" 2>/dev/null)
                    file_region=$(jq -r '.region' "$file" 2>/dev/null)
                else
                    file_environment=$(grep -o '"environment": "[^"]*"' "$file" | cut -d'"' -f4)
                    file_region=$(grep -o '"region": "[^"]*"' "$file" | cut -d'"' -f4)
                fi

                if [[ "$file_environment" == "$environment" && "$file_region" == "$region" ]]; then
                    deployment_id=$(basename "$file" .json)
                    echo "$deployment_id"
                fi
            fi
        done
    fi
}

# Show environment configuration
show_environment_config() {
    local environment="$1"
    local region="$2"

    echo
    log_info "Configuration for $environment ($region):"
    echo "  Environment: $environment"
    echo "  Region: $region"
    echo "  AWS Region: ${AWS_REGION:-not set}"
    echo "  Deployment Target: ${CI_DEPLOYMENT_TARGET:-not set}"
    echo "  Project Root: $PROJECT_ROOT"
    echo "  Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}

# Initialize configuration on script load
load_project_config