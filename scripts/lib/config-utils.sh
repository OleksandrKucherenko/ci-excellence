#!/usr/bin/env bash
# Configuration Utilities Library
# Handles environment configuration and secrets management with SOPS

set -euo pipefail

# Source shared utilities
# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Configuration constants
readonly CONFIG_DIR="config"
readonly SECRETS_DIR="secrets"
readonly ENVIRONMENTS_DIR="${CONFIG_DIR}/environments"
readonly CONFIG_CACHE_DIR=".cache/config"
readonly SECRETS_CACHE_DIR=".cache/secrets"

# Initialize configuration environment
init_config_environment() {
  local environment="${1:-}"

  log_info "Initializing configuration environment"

  # Create cache directories
  mkdir -p "$CONFIG_CACHE_DIR"
  mkdir -p "$SECRETS_CACHE_DIR"

  # Set environment
  if [[ -n "$environment" ]]; then
    export CONFIG_ENVIRONMENT="$environment"
  elif [[ -n "${DEPLOY_ENVIRONMENT:-}" ]]; then
    export CONFIG_ENVIRONMENT="$DEPLOY_ENVIRONMENT"
  elif [[ -n "${CI_ENVIRONMENT:-}" ]]; then
    export CONFIG_ENVIRONMENT="$CI_ENVIRONMENT"
  else
    export CONFIG_ENVIRONMENT="development"
  fi

  log_info "Configuration environment set to: $CONFIG_ENVIRONMENT"

  # Validate environment
  if [[ ! -f "${ENVIRONMENTS_DIR}/${CONFIG_ENVIRONMENT}.json" ]]; then
    log_error "Environment configuration not found: ${ENVIRONMENTS_DIR}/${CONFIG_ENVIRONMENT}.json"
    return 1
  fi

  return 0
}

# Load environment configuration
load_environment_config() {
  local environment="${1:-$CONFIG_ENVIRONMENT}"
  local config_file="${ENVIRONMENTS_DIR}/${environment}.json"

  if [[ ! -f "$config_file" ]]; then
    log_error "Environment configuration file not found: $config_file"
    return 1
  fi

  # Use jq to parse and validate JSON
  if ! command -v jq >/dev/null 2>&1; then
    log_error "jq is required for configuration management"
    return 1
  fi

  # Validate JSON syntax
  if ! jq empty "$config_file" 2>/dev/null; then
    log_error "Invalid JSON in configuration file: $config_file"
    return 1
  fi

  # Load configuration into environment variables
  local temp_config
  temp_config=$(mktemp)

  # Extract key configuration values
  {
    echo "# Auto-generated environment configuration from $config_file"
    echo "export CONFIG_ENVIRONMENT=\"$environment\""
    echo "export CONFIG_TYPE=\"$(jq -r '.environment.type' "$config_file")\""
    echo "export CONFIG_DESCRIPTION=\"$(jq -r '.environment.description' "$config_file")\""

    # Database configuration
    echo "export DB_HOST=\"$(jq -r '.database.host // "localhost"' "$config_file")\""
    echo "export DB_PORT=\"$(jq -r '.database.port // 5432' "$config_file")\""
    echo "export DB_NAME=\"$(jq -r '.database.name' "$config_file")\""
    echo "export DB_SSL_MODE=\"$(jq -r '.database.ssl_mode // "prefer"' "$config_file")\""

    # Application configuration
    echo "export APP_LOG_LEVEL=\"$(jq -r '.application.log_level // "info"' "$config_file")\""
    echo "export APP_DEBUG=\"$(jq -r '.application.debug // false' "$config_file")\""
    echo "export METRICS_ENABLED=\"$(jq -r '.application.metrics.enabled // false' "$config_file")\""
    echo "export METRICS_PORT=\"$(jq -r '.application.metrics.port // 9090' "$config_file")\""

    # Infrastructure configuration
    echo "export K8S_NAMESPACE=\"$(jq -r '.infrastructure.namespace // "default"' "$config_file")\""
    echo "export K8S_REPLICAS=\"$(jq -r '.infrastructure.replicas.default // 1' "$config_file")\""

    # Network configuration
    echo "export INGRESS_HOST=\"$(jq -r '.network.ingress.host // "localhost"' "$config_file")\""
    echo "export HTTP_PORT=\"$(jq -r '.network.ports.http // 3000' "$config_file")\""

  } > "$temp_config"

  # Source the configuration
  # shellcheck source=/dev/null
  source "$temp_config"

  # Clean up
  rm -f "$temp_config"

  log_success "✅ Environment configuration loaded: $environment"
  return 0
}

# Load and decrypt secrets
load_secrets() {
  local environment="${1:-$CONFIG_ENVIRONMENT}"
  local secrets_file="${SECRETS_DIR}/${environment}.secrets.yaml"

  if [[ ! -f "$secrets_file" ]]; then
    log_warning "Secrets file not found: $secrets_file"
    return 0
  fi

  # Check if SOPS is available
  if ! command -v sops >/dev/null 2>&1; then
    log_warning "SOPS not available, skipping secrets loading"
    return 0
  fi

  # Create cache file
  local cache_file="${SECRETS_CACHE_DIR}/${environment}.env"
  local cache_valid=false

  # Check if cache is valid (secrets file hasn't been modified)
  if [[ -f "$cache_file" ]]; then
    local secrets_mtime
    local cache_mtime
    secrets_mtime=$(stat -c %Y "$secrets_file" 2>/dev/null || echo 0)
    cache_mtime=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)

    if [[ $cache_mtime -gt $secrets_mtime ]]; then
      cache_valid=true
    fi
  fi

  if [[ "$cache_valid" == "true" ]]; then
    log_info "Loading secrets from cache"
    # shellcheck source=/dev/null
    source "$cache_file"
  else
    log_info "Decrypting and caching secrets"

    # Decrypt secrets and convert to environment variables
    local temp_secrets
    temp_secrets=$(mktemp)

    # Use SOPS to decrypt and extract secrets
    if sops --decrypt "$secrets_file" > "$temp_secrets" 2>/dev/null; then
      # Convert YAML to environment variables
      local env_file
      env_file=$(mktemp)

      {
        echo "# Auto-generated secrets from $secrets_file"

        # Extract database secrets
        if yq eval '.database.host' "$temp_secrets" 2>/dev/null | grep -v null >/dev/null; then
          echo "export DB_HOST_PASSWORD=\"$(yq eval '.database.password' "$temp_secrets")\""
          echo "export DB_HOST_USERNAME=\"$(yq eval '.database.username' "$temp_secrets")\""
        fi

        # Extract Redis secrets
        if yq eval '.redis.password' "$temp_secrets" 2>/dev/null | grep -v null >/dev/null; then
          echo "export REDIS_PASSWORD=\"$(yq eval '.redis.password' "$temp_secrets")\""
        fi

        # Extract security secrets
        if yq eval '.security.jwt_secret' "$temp_secrets" 2>/dev/null | grep -v null >/dev/null; then
          echo "export JWT_SECRET=\"$(yq eval '.security.jwt_secret' "$temp_secrets")\""
        fi

        if yq eval '.security.encryption_key' "$temp_secrets" 2>/dev/null | grep -v null >/dev/null; then
          echo "export ENCRYPTION_KEY=\"$(yq eval '.security.encryption_key' "$temp_secrets")\""
        fi

        # Extract external service secrets
        if yq eval '.external_services.stripe.api_key' "$temp_secrets" 2>/dev/null | grep -v null >/dev/null; then
          echo "export STRIPE_API_KEY=\"$(yq eval '.external_services.stripe.api_key' "$temp_secrets")\""
        fi

        if yq eval '.external_services.stripe.webhook_secret' "$temp_secrets" 2>/dev/null | grep -v null >/dev/null; then
          echo "export STRIPE_WEBHOOK_SECRET=\"$(yq eval '.external_services.stripe.webhook_secret' "$temp_secrets")\""
        fi

        # Extract AWS secrets
        if yq eval '.aws.access_key_id' "$temp_secrets" 2>/dev/null | grep -v null >/dev/null; then
          echo "export AWS_ACCESS_KEY_ID=\"$(yq eval '.aws.access_key_id' "$temp_secrets")\""
        fi

        if yq eval '.aws.secret_access_key' "$temp_secrets" 2>/dev/null | grep -v null >/dev/null; then
          echo "export AWS_SECRET_ACCESS_KEY=\"$(yq eval '.aws.secret_access_key' "$temp_secrets")\""
        fi

      } > "$env_file"

      # Source the secrets
      # shellcheck source=/dev/null
      source "$env_file"

      # Cache the secrets
      cp "$env_file" "$cache_file"
      chmod 600 "$cache_file"

      # Clean up
      rm -f "$env_file"
    else
      log_error "Failed to decrypt secrets: $secrets_file"
      rm -f "$temp_secrets"
      return 1
    fi

    # Clean up
    rm -f "$temp_secrets"
  fi

  log_success "✅ Secrets loaded for environment: $environment"
  return 0
}

# Validate configuration
validate_configuration() {
  local environment="${1:-$CONFIG_ENVIRONMENT}"
  local config_file="${ENVIRONMENTS_DIR}/${environment}.json"
  local secrets_file="${SECRETS_DIR}/${environment}.secrets.yaml"

  log_info "Validating configuration for environment: $environment"

  local validation_failed=false

  # Validate environment configuration
  if [[ ! -f "$config_file" ]]; then
    log_error "Environment configuration missing: $config_file"
    validation_failed=true
  else
    # Validate JSON structure
    if ! jq empty "$config_file" 2>/dev/null; then
      log_error "Invalid JSON in environment configuration: $config_file"
      validation_failed=true
    fi

    # Check required fields
    local required_fields=(
      ".environment.name"
      ".environment.type"
      ".infrastructure.platform"
      ".deployment.strategy"
    )

    for field in "${required_fields[@]}"; do
      if ! jq -e "$field" "$config_file" >/dev/null 2>&1; then
        log_error "Required field missing in configuration: $field"
        validation_failed=true
      fi
    done
  fi

  # Validate secrets file (if it exists)
  if [[ -f "$secrets_file" ]]; then
    if ! command -v sops >/dev/null 2>&1; then
      log_warning "SOPS not available, cannot validate secrets"
    else
      if ! sops --decrypt "$secrets_file" >/dev/null 2>&1; then
        log_error "Invalid or corrupt secrets file: $secrets_file"
        validation_failed=true
      fi
    fi
  fi

  if [[ "$validation_failed" == "true" ]]; then
    log_error "❌ Configuration validation failed"
    return 1
  fi

  log_success "✅ Configuration validation passed"
  return 0
}

# Get configuration value
get_config_value() {
  local key="$1"
  local environment="${2:-$CONFIG_ENVIRONMENT}"
  local default_value="${3:-}"
  local config_file="${ENVIRONMENTS_DIR}/${environment}.json"

  if [[ ! -f "$config_file" ]]; then
    echo "$default_value"
    return 1
  fi

  local value
  if value=$(jq -r "$key // \"$default_value\"" "$config_file" 2>/dev/null); then
    echo "$value"
    return 0
  else
    echo "$default_value"
    return 1
  fi
}

# Get secret value
get_secret_value() {
  local key="$1"
  local environment="${2:-$CONFIG_ENVIRONMENT}"
  local default_value="${3:-}"
  local secrets_file="${SECRETS_DIR}/${environment}.secrets.yaml"

  if [[ ! -f "$secrets_file" ]]; then
    echo "$default_value"
    return 1
  fi

  if ! command -v sops >/dev/null 2>&1; then
    echo "$default_value"
    return 1
  fi

  local value
  if value=$(sops --decrypt "$secrets_file" 2>/dev/null | yq eval "$key // \"$default_value\"" - 2>/dev/null); then
    echo "$value"
    return 0
  else
    echo "$default_value"
    return 1
  fi
}

# List available environments
list_environments() {
  log_info "Available environments:"

  if [[ -d "$ENVIRONMENTS_DIR" ]]; then
    find "$ENVIRONMENTS_DIR" -name "*.json" -exec basename {} .json \; | sort | while read -r env; do
      local description
      description=$(get_config_value ".environment.description" "$env" "No description")
      echo "  $env - $description"
    done
  else
    log_warning "Environments directory not found: $ENVIRONMENTS_DIR"
  fi
}

# Show environment configuration
show_environment() {
  local environment="${1:-$CONFIG_ENVIRONMENT}"
  local config_file="${ENVIRONMENTS_DIR}/${environment}.json"

  if [[ ! -f "$config_file" ]]; then
    log_error "Environment configuration not found: $config_file"
    return 1
  fi

  log_info "Environment configuration for: $environment"
  echo

  # Show key configuration
  echo "Basic Info:"
  echo "  Name: $(get_config_value ".environment.name" "$environment")"
  echo "  Type: $(get_config_value ".environment.type" "$environment")"
  echo "  Description: $(get_config_value ".environment.description" "$environment")"
  echo

  echo "Infrastructure:"
  echo "  Platform: $(get_config_value ".infrastructure.platform" "$environment")"
  echo "  Namespace: $(get_config_value ".infrastructure.namespace" "$environment")"
  echo "  Replicas: $(get_config_value ".infrastructure.replicas.default" "$environment")"
  echo

  echo "Deployment:"
  echo "  Strategy: $(get_config_value ".deployment.strategy" "$environment")"
  echo "  Timeout: $(get_config_value ".deployment.timeout_seconds" "$environment")s"
  echo "  Rollback Enabled: $(get_config_value ".deployment.rollback.enabled" "$environment")"
  echo

  echo "Application:"
  echo "  Log Level: $(get_config_value ".application.log_level" "$environment")"
  echo "  Debug: $(get_config_value ".application.debug" "$environment")"
  echo "  Metrics: $(get_config_value ".application.metrics.enabled" "$environment")"
  echo

  echo "Network:"
  echo "  Ingress Host: $(get_config_value ".network.ingress.host" "$environment")"
  echo "  HTTP Port: $(get_config_value ".network.ports.http" "$environment")"
}

# Compare environment configurations
compare_environments() {
  local env1="$1"
  local env2="$2"

  local config_file1="${ENVIRONMENTS_DIR}/${env1}.json"
  local config_file2="${ENVIRONMENTS_DIR}/${env2}.json"

  if [[ ! -f "$config_file1" ]]; then
    log_error "Environment configuration not found: $config_file1"
    return 1
  fi

  if [[ ! -f "$config_file2" ]]; then
    log_error "Environment configuration not found: $config_file2"
    return 1
  fi

  log_info "Comparing environments: $env1 vs $env2"
  echo

  # Use jq to compare configurations
  {
    echo "# Configuration differences between $env1 and $env2"
    echo
    echo "Infrastructure:"
    echo "  Replicas - $env1: $(get_config_value ".infrastructure.replicas.default" "$env1"), $env2: $(get_config_value ".infrastructure.replicas.default" "$env2")"
    echo "  CPU Request - $env1: $(get_config_value ".infrastructure.resources.cpu.request" "$env1"), $env2: $(get_config_value ".infrastructure.resources.cpu.request" "$env2")"
    echo "  Memory Request - $env1: $(get_config_value ".infrastructure.resources.memory.request" "$env1"), $env2: $(get_config_value ".infrastructure.resources.memory.request" "$env2")"
    echo
    echo "Application:"
    echo "  Log Level - $env1: $(get_config_value ".application.log_level" "$env1"), $env2: $(get_config_value ".application.log_level" "$env2")"
    echo "  Debug - $env1: $(get_config_value ".application.debug" "$env1"), $env2: $(get_config_value ".application.debug" "$env2")"
    echo "  Metrics Enabled - $env1: $(get_config_value ".application.metrics.enabled" "$env1"), $env2: $(get_config_value ".application.metrics.enabled" "$env2")"
    echo
    echo "Security:"
    echo "  Rollback Enabled - $env1: $(get_config_value ".deployment.rollback.enabled" "$env1"), $env2: $(get_config_value ".deployment.rollback.enabled" "$env2")"
    echo "  Rate Limiting - $env1: $(get_config_value ".security.rate_limiting.enabled" "$env1"), $env2: $(get_config_value ".security.rate_limiting.enabled" "$env2")"
  } | cat
}

# Export configuration for kubernetes
export_kubernetes_config() {
  local environment="${1:-$CONFIG_ENVIRONMENT}"
  local output_dir="${2:-k8s/overlays/$environment}"

  log_info "Exporting Kubernetes configuration for environment: $environment"

  mkdir -p "$output_dir"

  # Create kustomize overlay
  local kustomization_file="$output_dir/kustomization.yaml"
  cat > "$kustomization_file" << EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
  - ../../base

namespace: $(get_config_value ".infrastructure.namespace" "$environment")

patchesStrategicMerge:
- deployment.yaml
- service.yaml
- ingress.yaml

configMapGenerator:
- name: app-config
  literals:
  - LOG_LEVEL=$(get_config_value ".application.log_level" "$environment")
  - METRICS_ENABLED=$(get_config_value ".application.metrics.enabled" "$environment")
  - ENVIRONMENT=$environment
  - INGRESS_HOST=$(get_config_value ".network.ingress.host" "$environment")

secretGenerator:
- name: app-secrets
  envs:
  - secrets.env

replicas:
- name: app-deployment
  count: $(get_config_value ".infrastructure.replicas.default" "$environment")
EOF

  # Create deployment patch
  local deployment_patch="$output_dir/deployment.yaml"
  cat > "$deployment_patch" << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-deployment
spec:
  template:
    spec:
      containers:
      - name: app
        resources:
          requests:
            cpu: $(get_config_value ".infrastructure.resources.cpu.request" "$environment")
            memory: $(get_config_value ".infrastructure.resources.memory.request" "$environment")
          limits:
            cpu: $(get_config_value ".infrastructure.resources.cpu.limit" "$environment")
            memory: $(get_config_value ".infrastructure.resources.memory.limit" "$environment")
EOF

  log_success "✅ Kubernetes configuration exported to: $output_dir"
}

# Clean configuration cache
clean_cache() {
  log_info "Cleaning configuration cache"

  if [[ -d "$CONFIG_CACHE_DIR" ]]; then
    rm -rf "$CONFIG_CACHE_DIR"
    log_info "Configuration cache cleared"
  fi

  if [[ -d "$SECRETS_CACHE_DIR" ]]; then
    rm -rf "$SECRETS_CACHE_DIR"
    log_info "Secrets cache cleared"
  fi

  log_success "✅ Cache cleaned"
}

# Main configuration setup function
setup_configuration() {
  local environment="${1:-}"

  if [[ -n "$environment" ]]; then
    init_config_environment "$environment"
  fi

  load_environment_config
  load_secrets
  validate_configuration
}

# Export all functions for use in other scripts
export -f init_config_environment
export -f load_environment_config
export -f load_secrets
export -f validate_configuration
export -f get_config_value
export -f get_secret_value
export -f list_environments
export -f show_environment
export -f compare_environments
export -f export_kubernetes_config
export -f clean_cache
export -f setup_configuration