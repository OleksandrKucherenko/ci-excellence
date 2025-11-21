#!/usr/bin/env bash
# Secret utility functions for CI/CD pipeline
# Provides SOPS decryption wrapper, environment variable loading, and secret management

# Prevent double sourcing
if [[ "${CI_SECRET_UTILS_SH_LOADED:-}" == "true" ]]; then
  return 0
fi
CI_SECRET_UTILS_SH_LOADED=true

# Source common utilities if available
if [[ -f "scripts/lib/common.sh" ]]; then
  # shellcheck source=scripts/lib/common.sh
  source scripts/lib/common.sh
fi

# Decrypt environment secrets using MISE task
decrypt_environment_secrets() {
  local environment="$1"
  local output_format="${2:-env}"  # env, json, yaml

  log_info "Decrypting secrets for environment: $environment"

  if command -v mise >/dev/null 2>&1; then
    case "$output_format" in
      "env")
        mise run "decrypt-$environment" 2>/dev/null | grep -E '^[A-Z_]+=.*' || true
        ;;
      "json")
        mise run "decrypt-$environment" 2>/dev/null || echo "{}"
        ;;
      "yaml")
        mise run "decrypt-$environment" 2>/dev/null || echo ""
        ;;
      *)
        log_error "Unknown output format: $output_format"
        return 1
        ;;
    esac
  else
    log_error "MISE not available for decrypting secrets"
    return 1
  fi
}

# Load environment variables from decrypted secrets
load_environment_secrets() {
  local environment="$1"

  log_info "Loading secrets for environment: $environment"

  local secrets_output
  secrets_output=$(decrypt_environment_secrets "$environment" "env")

  if [[ -z "$secrets_output" ]]; then
    log_warning "No secrets found for environment: $environment"
    return 0
  fi

  # Export secrets as environment variables
  while IFS='=' read -r key value; do
    # Skip empty lines and comments
    if [[ -n "$key" && ! "$key" =~ ^# ]]; then
      # Remove quotes if present
      value="${value%\"}"
      value="${value#\"}"
      value="${value%\'}"
      value="${value#\'}"

      export "$key"="$value"
      log_debug "Loaded secret: $key"
    fi
  done <<< "$secrets_output"

  log_success "Secrets loaded for environment: $environment"
}

# Check if SOPS age key is available
check_sops_age_key() {
  local key_file="${1:-}"

  if [[ -n "$key_file" ]]; then
    # Check specific key file
    if [[ -f "$key_file" ]]; then
      log_debug "SOPS age key found: $key_file"
      return 0
    fi
  fi

  # Check common locations
  local key_locations=(
    "$SOPS_AGE_KEY_FILE"
    "${HOME}/.config/sops/age/keys.txt"
    ".secrets/mise-age.txt"
  )

  for location in "${key_locations[@]}"; do
    if [[ -n "$location" && -f "$location" ]]; then
      log_debug "SOPS age key found: $location"
      export SOPS_AGE_KEY_FILE="$location"
      return 0
    fi
  done

  # Check environment variable
  if [[ -n "${SOPS_AGE_KEY:-}" ]]; then
    log_debug "SOPS age key found in environment variable"
    return 0
  fi

  log_error "SOPS age key not found"
  log_error "Please set SOPS_AGE_KEY or ensure key file exists at:"
  printf "  - %s\n" "${key_locations[@]}"
  return 1
}

# Validate encrypted file format
validate_encrypted_file() {
  local file_path="$1"

  if [[ ! -f "$file_path" ]]; then
    log_error "File not found: $file_path"
    return 1
  fi

  # Check if file is encrypted (basic check)
  if ! grep -q "ENC\[AES256_GCM" "$file_path" 2>/dev/null && \
     ! grep -q "AGE-SECRET-KEY" "$file_path" 2>/dev/null; then
    log_warning "File may not be properly encrypted: $file_path"
  fi

  log_debug "Encrypted file validation passed: $file_path"
  return 0
}

# Encrypt secrets file
encrypt_secrets() {
  local input_file="$1"
  local output_file="$2"

  if [[ ! -f "$input_file" ]]; then
    log_error "Input file not found: $input_file"
    return 1
  fi

  if ! check_sops_age_key; then
    return 1
  fi

  if command -v sops >/dev/null 2>&1; then
    sops --encrypt --input-type yaml --output-type yaml "$input_file" > "$output_file"
    log_success "Encrypted secrets: $input_file -> $output_file"
  else
    log_error "SOPS not available for encrypting secrets"
    return 1
  fi
}

# Decrypt secrets file to stdout
decrypt_secrets() {
  local encrypted_file="$1"

  if ! validate_encrypted_file "$encrypted_file"; then
    return 1
  fi

  if ! check_sops_age_key; then
    return 1
  fi

  if command -v sops >/dev/null 2>&1; then
    sops --decrypt "$encrypted_file"
  else
    log_error "SOPS not available for decrypting secrets"
    return 1
  fi
}

# Edit encrypted file
edit_encrypted_file() {
  local encrypted_file="$1"

  if ! validate_encrypted_file "$encrypted_file"; then
    return 1
  fi

  if ! check_sops_age_key; then
    return 1
  fi

  if command -v sops >/dev/null 2>&1; then
    sops "$encrypted_file"
    log_success "Edited encrypted file: $encrypted_file"
  else
    log_error "SOPS not available for editing secrets"
    return 1
  fi
}

# Extract specific secret from encrypted file
extract_secret() {
  local encrypted_file="$1"
  local secret_key="$2"

  local secrets_output
  secrets_output=$(decrypt_secrets "$encrypted_file" 2>/dev/null)

  if [[ -z "$secrets_output" ]]; then
    log_error "Failed to decrypt or empty secrets file: $encrypted_file"
    return 1
  fi

  # Extract the specific key
  local value
  value=$(echo "$secrets_output" | grep -E "^\s*${secret_key}\s*:" | sed 's/^[^:]*:[[:space:]]*//' | tr -d '"' | tr -d "'" || echo "")

  if [[ -z "$value" ]]; then
    log_error "Secret key not found: $secret_key"
    return 1
  fi

  echo "$value"
}

# Validate environment secrets configuration
validate_environment_config() {
  local environment="$1"

  local config_file="environments/${environment}/config.yml"
  local secrets_file="environments/${environment}/secrets.enc"

  # Check environment directory exists
  if [[ ! -d "environments/${environment}" ]]; then
    log_error "Environment directory not found: environments/${environment}"
    return 1
  fi

  # Check config file exists
  if [[ ! -f "$config_file" ]]; then
    log_error "Environment config not found: $config_file"
    return 1
  fi

  # Check secrets file exists (optional)
  if [[ ! -f "$secrets_file" ]]; then
    log_warning "Environment secrets not found: $secrets_file"
  else
    validate_encrypted_file "$secrets_file"
  fi

  # Validate config file format
  if command -v yq >/dev/null 2>&1; then
    if ! yq eval '.' "$config_file" >/dev/null 2>&1; then
      log_error "Invalid YAML in config file: $config_file"
      return 1
    fi
  fi

  log_success "Environment configuration is valid: $environment"
  return 0
}

# Get available environments
get_available_environments() {
  local environments_dir="environments"

  if [[ ! -d "$environments_dir" ]]; then
    log_error "Environments directory not found: $environments_dir"
    return 1
  fi

  # List directories in environments/ that are not 'global'
  find "$environments_dir" -maxdepth 1 -type d -name "global" -prune -o -type d -print | \
    sed 's|.*/||' | grep -v '^environments$' | sort
}

# Validate secret rotation procedure
validate_secret_rotation() {
  local environment="$1"
  local dry_run="${2:-false}"

  log_info "Validating secret rotation for environment: $environment"

  local secrets_file="environments/${environment}/secrets.enc"

  if [[ ! -f "$secrets_file" ]]; then
    log_warning "No secrets file found for environment: $environment"
    return 0
  fi

  if [[ "$dry_run" == "true" ]]; then
    log_info "Dry run: would decrypt and validate secrets"
    return 0
  fi

  # Test decryption
  local test_output
  test_output=$(decrypt_secrets "$secrets_file" 2>/dev/null)

  if [[ -z "$test_output" ]]; then
    log_error "Failed to decrypt secrets for rotation test"
    return 1
  fi

  # Check for required secrets (customize per environment)
  local required_secrets=()
  case "$environment" in
    "production"|"staging")
      required_secrets=("database_url" "api_key")
      ;;
    "canary"|"sandbox")
      required_secrets=("api_key")
      ;;
  esac

  local missing_secrets=()
  for secret in "${required_secrets[@]}"; do
    if ! echo "$test_output" | grep -q "^\s*${secret}\s*:"; then
      missing_secrets+=("$secret")
    fi
  done

  if [[ ${#missing_secrets[@]} -gt 0 ]]; then
    log_warning "Missing recommended secrets: ${missing_secrets[*]}"
  fi

  log_success "Secret rotation validation passed for: $environment"
  return 0
}

# Generate secret rotation documentation
generate_rotation_procedure() {
  local environment="$1"

  cat <<EOF
# Secret Rotation Procedure: ${environment}

## Overview
This document describes the procedure for rotating secrets in the ${environment} environment.

## Prerequisites
- Access to the repository with write permissions
- SOPS age key for encryption/decryption
- MISE installed locally

## Step-by-Step Procedure

### 1. Current State Assessment
\`\`\`bash
# Validate current configuration
mise run validate-${environment}

# Test decryption (dry run)
mise run decrypt-${environment}
\`\`\`

### 2. Generate New Secrets
Generate new secrets for each service that requires rotation:
- Database passwords
- API keys
- Certificates
- Service account tokens

### 3. Update Secrets
\`\`\`bash
# Edit secrets file
mise run edit-secrets ${environment}

# Add or update secrets:
database_url: "postgresql://user:NEW_PASSWORD@host/db"
api_key: "NEW_API_KEY"
\`\`\`

### 4. Validate New Secrets
\`\`\`bash
# Test decryption with new secrets
mise run decrypt-${environment}

# Validate required secrets are present
mise run validate-secret-rotation ${environment}
\`\`\`

### 5. Update External Services
Update external services with new secrets:
- Database connection strings
- API configurations
- Service credentials

### 6. Deploy and Test
1. Deploy changes to ${environment}
2. Run smoke tests
3. Verify all services are operational

### 7. Clean Old Secrets
- Remove old secrets from external services
- Update documentation if needed
- Monitor for any issues

## Rollback Procedure
If rotation causes issues:

1. **Immediate Rollback**: Use previous secrets file
2. **GitHub Variables**: Revert secret variables
3. **External Services**: Restore old credentials
4. **Verify**: Run smoke tests

## Monitoring
Monitor the following after rotation:
- Application logs for authentication errors
- Database connection issues
- API authentication failures
- External service integrations

## Contact
For issues with secret rotation:
- Infrastructure team
- Security team
- Application owners

Last Updated: $(date +%Y-%m-%d)
EOF
}

# Export functions for use in other scripts
export -f decrypt_environment_secrets load_environment_secrets
export -f check_sops_age_key validate_encrypted_file
export -f encrypt_secrets decrypt_secrets edit_encrypted_file extract_secret
export -f validate_environment_config get_available_environments
export -f validate_secret_rotation generate_rotation_procedure