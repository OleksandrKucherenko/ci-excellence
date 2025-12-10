#!/bin/bash
# Secrets Initialization Script
# Initializes encrypted secrets for different environments

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_ROOT/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common utilities" >&2
  exit 1
}

# Source secret utilities
source "$PROJECT_ROOT/scripts/lib/secret-utils.sh" 2>/dev/null || {
  echo "Failed to source secret utilities" >&2
  exit 1
}

# Configuration
readonly SECRETS_INIT_VERSION="1.0.0"
readonly ENVIRONMENTS_DIR="$PROJECT_ROOT/environments"
readonly SUPPORTED_ENVIRONMENTS=("global" "staging" "production" "canary" "sandbox" "performance")

# Testability configuration
get_behavior_mode() {
  local script_name="secrets_init"
  get_script_behavior "$script_name" "EXECUTE"
}

# Validate environment
validate_environment() {
  local environment="$1"

  if ! array_contains "$environment" "${SUPPORTED_ENVIRONMENTS[@]}"; then
    log_error "Invalid environment: $environment"
    log_info "Supported environments: ${SUPPORTED_ENVIRONMENTS[*]}"
    return 1
  fi

  return 0
}

# Create environment secrets template
create_secrets_template() {
  local environment="$1"
  local secrets_file="$ENVIRONMENTS_DIR/$environment/secrets.enc"

  log_info "Creating secrets template for: $environment"

  local behavior
  behavior=$(get_behavior_mode)

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would create secrets template for $environment"
      return 0
      ;;
    "PASS")
      log_success "PASS MODE: Secrets template creation simulated successfully"
      return 0
      ;;
    "FAIL")
      log_error "FAIL MODE: Simulating secrets template creation failure"
      return 1
      ;;
    "SKIP")
      log_info "SKIP MODE: Secrets template creation skipped"
      return 0
      ;;
    "TIMEOUT")
      log_info "TIMEOUT MODE: Simulating secrets template creation timeout"
      sleep 3
      return 124
      ;;
  esac

  # EXECUTE mode - Actual template creation
  if [[ -f "$secrets_file" ]]; then
    log_warn "Secrets file already exists: $secrets_file"
    read -p "Overwrite? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      log_info "Skipping secrets template creation"
      return 0
    fi
  fi

  # Create environment directory if needed
  ensure_directory "$ENVIRONMENTS_DIR/$environment"

  # Create temporary template file
  local temp_template
  temp_template=$(mktemp)

  # Generate template content based on environment type
  cat > "$temp_template" << EOF
# Secrets configuration for $environment environment
# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
#
# This file is encrypted with SOPS + age
# Edit with: mise run edit-secrets
#
# Common patterns:
# - API keys and tokens
# - Database connection strings
# - External service credentials
# - Third-party integration secrets

# Application Configuration
APP_NAME="ci-excellence"
APP_ENVIRONMENT="$environment"
APP_VERSION="latest"

# Database Configuration
# DATABASE_URL="postgresql://user:password@localhost:5432/dbname"
# DATABASE_HOST="localhost"
# DATABASE_PORT="5432"
# DATABASE_NAME="ci_excellence_$environment"
# DATABASE_USER="ci_user"
# DATABASE_PASSWORD="change-me"

# External Service APIs
# API_KEY_EXTERNAL_SERVICE="your-api-key-here"
# WEBHOOK_SECRET="your-webhook-secret"
# THIRD_PARTY_TOKEN="your-third-party-token"

# Cloud Provider Configuration
# AWS_ACCESS_KEY_ID="your-aws-access-key"
# AWS_SECRET_ACCESS_KEY="your-aws-secret-key"
# AWS_REGION="us-east-1"

# Azure Configuration
# AZURE_CLIENT_ID="your-azure-client-id"
# AZURE_CLIENT_SECRET="your-azure-client-secret"
# AZURE_TENANT_ID="your-azure-tenant-id"

# Google Cloud Configuration
# GOOGLE_APPLICATION_CREDENTIALS="path/to/service-account.json"
# GCP_PROJECT_ID="your-gcp-project-id"

# Notification Services
# SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
# DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/YOUR/DISCORD/WEBHOOK"
# EMAIL_SMTP_HOST="smtp.example.com"
# EMAIL_SMTP_PORT="587"
# EMAIL_USERNAME="your-email@example.com"
# EMAIL_PASSWORD="your-email-password"

# Monitoring and Observability
# SENTRY_DSN="https://your-sentry-dsn@sentry.io/project-id"
# DATADOG_API_KEY="your-datadog-api-key"
# DATADOG_APP_KEY="your-datadog-app-key"

# Security Configuration
# JWT_SECRET="your-jwt-secret-key"
# ENCRYPTION_KEY="your-encryption-key"
# SESSION_SECRET="your-session-secret"

# Feature Flags
# ENABLE_EXPERIMENTAL_FEATURE="false"
# ENABLE_DEBUG_LOGGING="$([ "$environment" = "development" ] && echo "true" || echo "false")"
EOF

  # Environment-specific additions
  case "$environment" in
    "production")
      cat >> "$temp_template" << EOF

# Production-specific settings
PRODUCTION_BACKUP_ENABLED="true"
PRODUCTION_MONITORING_ENABLED="true"
PRODUCTION_RATE_LIMITING_ENABLED="true"
PRODUCTION_SECURITY_HEADERS_ENABLED="true"
EOF
      ;;
    "staging")
      cat >> "$temp_template" << EOF

# Staging-specific settings
STAGING_DEBUG_ENABLED="true"
STAGING_MOCK_EXTERNAL_APIS="false"
STAGING_RATE_LIMITING_ENABLED="false"
EOF
      ;;
    "development"|"local")
      cat >> "$temp_template" << EOF

# Development-specific settings
DEV_DEBUG_ENABLED="true"
DEV_MOCK_EXTERNAL_APIS="true"
DEV_RATE_LIMITING_ENABLED="false"
DEV_SELF_SIGNED_CERTS_ALLOWED="true"
EOF
      ;;
  esac

  # Encrypt the template
  log_info "Encrypting secrets template for $environment"
  if encrypt_file "$temp_template" "$secrets_file" "dotenv"; then
    log_success "✅ Secrets template created: $secrets_file"
    log_info "Edit with: mise run edit-secrets"
  else
    log_error "Failed to encrypt secrets template"
    rm -f "$temp_template"
    return 1
  fi

  # Cleanup temporary file
  rm -f "$temp_template"

  return 0
}

# Initialize all environment secrets
init_all_environments() {
  log_info "Initializing secrets for all environments"

  local failed_count=0

  for environment in "${SUPPORTED_ENVIRONMENTS[@]}"; do
    log_info "Processing environment: $environment"
    if ! create_secrets_template "$environment"; then
      ((failed_count++))
      log_error "Failed to initialize secrets for: $environment"
    fi
  done

  if [[ $failed_count -eq 0 ]]; then
    log_success "✅ All environment secrets initialized successfully"
  else
    log_error "❌ Failed to initialize $failed_count environments"
    return 1
  fi
}

# Check secrets status
check_secrets_status() {
  local environment="${1:-}"

  log_info "Checking secrets status"

  local environments=()
  if [[ -n "$environment" ]]; then
    environments=("$environment")
  else
    environments=("${SUPPORTED_ENVIRONMENTS[@]}")
  fi

  echo ""
  echo "🔒 Secrets Status:"
  printf "%-15s %-10s %s\n" "Environment" "Status" "File"
  printf "%-15s %-10s %s\n" "-----------" "------" "----"

  for env in "${environments[@]}"; do
    local secrets_file="$ENVIRONMENTS_DIR/$env/secrets.enc"
    local status="❌"
    local file_path="Not found"

    if [[ -f "$secrets_file" ]]; then
      status="✅"
      file_path="$secrets_file"

      # Check if we can decrypt it
      if command -v sops >/dev/null 2>&1 && validate_age_key_file >/dev/null 2>&1; then
        if sops --decrypt "$secrets_file" >/dev/null 2>&1; then
          status="🔓"
          file_path+=" (decryptable)"
        else
          file_path+=" (encrypted)"
        fi
      else
        file_path+=" (key unavailable)"
      fi
    fi

    printf "%-15s %-10s %s\n" "$env" "$status" "$file_path"
  done
  echo ""

  # Check age key file status
  local age_key_file
  age_key_file=$(get_age_key_file)
  printf "%-15s %-10s %s\n" "Age Key File" "$([[ -f "$age_key_file" ]] && echo "✅" || echo "❌")" "$age_key_file"

  # Check SOPS configuration
  local sops_config="$PROJECT_ROOT/.sops.yaml"
  printf "%-15s %-10s %s\n" "SOPS Config" "$([[ -f "$sops_config" ]] && echo "✅" || echo "❌")" "$sops_config"
  echo ""
}

# Generate age key pair
generate_age_key() {
  log_info "Generating age encryption key pair"

  local behavior
  behavior=$(get_behavior_mode)

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would generate age key pair"
      return 0
      ;;
    "PASS")
      log_success "PASS MODE: Age key generation simulated successfully"
      return 0
      ;;
    "FAIL")
      log_error "FAIL MODE: Simulating age key generation failure"
      return 1
      ;;
    "SKIP")
      log_info "SKIP MODE: Age key generation skipped"
      return 0
      ;;
    "TIMEOUT")
      log_info "TIMEOUT MODE: Simulating age key generation timeout"
      sleep 3
      return 124
      ;;
  esac

  # EXECUTE mode - Actual key generation
  check_age

  local key_file
  key_file=$(get_age_key_file)

  # Ensure .secrets directory exists
  ensure_directory "$(dirname "$key_file")"

  if [[ -f "$key_file" ]]; then
    log_warn "Age key file already exists: $key_file"
    read -p "Generate new key? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      log_info "Keeping existing key file"
      return 0
    fi

    # Backup existing key
    local backup_file="${key_file}.backup.$(date +%s)"
    cp "$key_file" "$backup_file"
    log_info "Backup saved: $backup_file"
  fi

  # Generate new key pair
  if age-keygen -o "$key_file" >/dev/null 2>&1; then
    log_success "✅ Age key pair generated: $key_file"
    log_info "Public key: $(grep 'AGE-SECRET-KEY-1' "$key_file" | cut -d' ' -f2 | age -d -i -)"

    # Set appropriate permissions
    chmod 600 "$key_file"

    log_info "Key file permissions set to 600"
    return 0
  else
    log_error "Failed to generate age key pair"
    return 1
  fi
}

# Main execution
main() {
  local action="${1:-help}"
  shift || true

  case "$action" in
    "init")
      if [[ $# -lt 1 ]]; then
        log_error "Usage: $0 init <environment>"
        exit 1
      fi
      local environment="$1"
      validate_environment "$environment"
      create_secrets_template "$environment"
      ;;
    "init-all")
      init_all_environments
      ;;
    "status")
      check_secrets_status "$@"
      ;;
    "generate-key")
      generate_age_key
      ;;
    "validate")
      validate_age_key_file
      ;;
    "help"|"--help"|"-h")
      cat << EOF
Secrets Initialization Script v$SECRETS_INIT_VERSION

Usage: $0 <action> [options]

Actions:
  init <environment>                      Initialize secrets for specific environment
  init-all                                Initialize secrets for all environments
  status [environment]                    Check secrets status
  generate-key                            Generate new age encryption key pair
  validate                                Validate age key file
  help                                    Show this help message

Supported Environments:
  ${SUPPORTED_ENVIRONMENTS[*]}

Examples:
  $0 init production                       # Initialize production secrets
  $0 init-all                             # Initialize all environment secrets
  $0 status                               # Check all secrets status
  $0 generate-key                         # Generate new encryption key

Testability Examples:
  CI_TEST_MODE=DRY_RUN $0 init production
  CI_SECRETS_INIT_BEHAVIOR=FAIL $0 generate-key
EOF
      exit 0
      ;;
    *)
      log_error "Unknown action: $action"
      echo "Use '$0 help' for usage information"
      exit 1
      ;;
  esac
}

# CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi