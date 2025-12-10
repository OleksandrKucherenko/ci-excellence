#!/bin/bash
# Secrets Key Rotation Script
# Rotates encryption keys for all encrypted secrets

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
readonly KEY_ROTATION_VERSION="1.0.0"
readonly ENVIRONMENTS_DIR="$PROJECT_ROOT/environments"
readonly SUPPORTED_ENVIRONMENTS=("global" "staging" "production" "canary" "sandbox" "performance")

# Testability configuration
get_behavior_mode() {
  local script_name="secrets_rotation"
  get_script_behavior "$script_name" "EXECUTE"
}

# Backup current key and configuration
backup_current_setup() {
  local backup_dir="$PROJECT_ROOT/.secrets/backup-$(date +%Y%m%d-%H%M%S)"

  log_info "Creating backup of current setup: $backup_dir"
  ensure_directory "$backup_dir"

  # Backup age key file
  local age_key_file
  age_key_file=$(get_age_key_file)
  if [[ -f "$age_key_file" ]]; then
    cp "$age_key_file" "$backup_dir/mise-age.txt"
    log_success "✅ Age key file backed up"
  fi

  # Backup SOPS configuration
  local sops_config="$PROJECT_ROOT/.sops.yaml"
  if [[ -f "$sops_config" ]]; then
    cp "$sops_config" "$backup_dir/sops.yaml"
    log_success "✅ SOPS configuration backed up"
  fi

  # Create rotation manifest
  cat > "$backup_dir/rotation-manifest.txt" << EOF
Key Rotation Backup
Created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
Original Key File: $age_key_file
Original SOPS Config: $sops_config

To restore:
1. cp mise-age.txt "$age_key_file"
2. cp sops.yaml "$sops_config"
3. Re-encrypt all secrets files
EOF

  echo "$backup_dir"
}

# Generate new encryption key
generate_new_key() {
  log_info "Generating new encryption key pair"

  local behavior
  behavior=$(get_behavior_mode)

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would generate new encryption key"
      return 0
      ;;
    "PASS")
      log_success "PASS MODE: New key generation simulated successfully"
      return 0
      ;;
    "FAIL")
      log_error "FAIL MODE: Simulating new key generation failure"
      return 1
      ;;
    "SKIP")
      log_info "SKIP MODE: New key generation skipped"
      return 0
      ;;
    "TIMEOUT")
      log_info "TIMEOUT MODE: Simulating new key generation timeout"
      sleep 3
      return 124
      ;;
  esac

  # EXECUTE mode - Actual key generation
  check_age

  local age_key_file
  age_key_file=$(get_age_key_file)

  local new_key_file="${age_key_file}.new"
  if age-keygen -o "$new_key_file" >/dev/null 2>&1; then
    log_success "✅ New key pair generated: $new_key_file"
    chmod 600 "$new_key_file"
    return 0
  else
    log_error "Failed to generate new key pair"
    return 1
  fi
}

# Extract public key from age key file
extract_public_key() {
  local key_file="$1"

  if [[ -f "$key_file" ]]; then
    grep "AGE-SECRET-KEY-1" "$key_file" | cut -d' ' -f2 | age -d -i - 2>/dev/null
  fi
}

# Update SOPS configuration with new key
update_sops_configuration() {
  local new_key_file="$1"
  local backup_dir="$2"

  log_info "Updating SOPS configuration"

  local behavior
  behavior=$(get_behavior_mode)

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would update SOPS configuration"
      return 0
      ;;
    "PASS")
      log_success "PASS MODE: SOPS configuration update simulated successfully"
      return 0
      ;;
    "FAIL")
      log_error "FAIL MODE: Simulating SOPS configuration update failure"
      return 1
      ;;
    "SKIP")
      log_info "SKIP MODE: SOPS configuration update skipped"
      return 0
      ;;
    "TIMEOUT")
      log_info "TIMEOUT MODE: Simulating SOPS configuration update timeout"
      sleep 3
      return 124
      ;;
  esac

  # EXECUTE mode - Actual configuration update
  local sops_config="$PROJECT_ROOT/.sops.yaml"
  local temp_config="${sops_config}.new"

  if [[ ! -f "$sops_config" ]]; then
    log_error "SOPS configuration file not found: $sops_config"
    return 1
  fi

  # Extract new public key
  local new_public_key
  new_public_key=$(extract_public_key "$new_key_file")

  if [[ -z "$new_public_key" ]]; then
    log_error "Failed to extract public key from new key file"
    return 1
  fi

  log_info "New public key: $new_public_key"

  # Create updated SOPS configuration
  # This is a simplified version - real implementation would be more complex
  cp "$sops_config" "$temp_config"

  # Add comment about key rotation
  cat >> "$temp_config" << EOF

# Key rotation performed on $(date -u +"%Y-%m-%dT%H:%M:%SZ")
# New public key: $new_public_key
# Backup location: $backup_dir
EOF

  # Replace the old key with new key in the configuration
  # This is a simplified approach - real implementation would need to handle multiple keys
  sed -i.bak "s|age1y8l0yvdvpzcyphwr29ua8pwwm6uw8t2t7g4df3awfgcrdla5d3dq9ldk2n|$new_public_key|g" "$temp_config"

  log_success "✅ SOPS configuration updated: $temp_config"
  return 0
}

# Re-encrypt all secrets files
re_encrypt_secrets() {
  local new_key_file="$1"

  log_info "Re-encrypting all secrets files"

  local behavior
  behavior=$(get_behavior_mode)

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would re-encrypt all secrets files"
      return 0
      ;;
    "PASS")
      log_success "PASS MODE: Secrets re-encryption simulated successfully"
      return 0
      ;;
    "FAIL")
      log_error "FAIL MODE: Simulating secrets re-encryption failure"
      return 1
      ;;
    "SKIP")
      log_info "SKIP MODE: Secrets re-encryption skipped"
      return 0
      ;;
    "TIMEOUT")
      log_info "TIMEOUT MODE: Simulating secrets re-encryption timeout"
      sleep 5
      return 124
      ;;
  esac

  # EXECUTE mode - Actual re-encryption
  check_sops

  local failed_count=0
  local total_count=0

  # Find all .enc files
  while IFS= read -r -d '' secrets_file; do
    ((total_count++))

    log_info "Re-encrypting: $secrets_file"

    # Create temporary decrypted file
    local temp_file
    temp_file=$(mktemp)

    # Decrypt with old key
    if decrypt_file "$secrets_file" "$temp_file"; then
      # Encrypt with new key
      if encrypt_file "$temp_file" "$secrets_file"; then
        log_success "✅ Re-encrypted: $secrets_file"
      else
        log_error "❌ Failed to re-encrypt: $secrets_file"
        ((failed_count++))
      fi
    else
      log_error "❌ Failed to decrypt: $secrets_file"
      ((failed_count++))
    fi

    # Cleanup temporary file
    rm -f "$temp_file"
  done < <(find "$PROJECT_ROOT" -name "*.enc" -print0 2>/dev/null || true)

  # Also check for .env.secrets.json
  local env_secrets_file="$PROJECT_ROOT/.env.secrets.json"
  if [[ -f "$env_secrets_file" ]]; then
    ((total_count++))
    log_info "Re-encrypting: $env_secrets_file"

    if sops --encrypt --config-file "$PROJECT_ROOT/.sops.yaml.new" "$env_secrets_file" > "${env_secrets_file}.new"; then
      mv "${env_secrets_file}.new" "$env_secrets_file"
      log_success "✅ Re-encrypted: $env_secrets_file"
    else
      log_error "❌ Failed to re-encrypt: $env_secrets_file"
      ((failed_count++))
    fi
  fi

  if [[ $failed_count -eq 0 ]]; then
    log_success "✅ All $total_count secrets files re-encrypted successfully"
    return 0
  else
    log_error "❌ Failed to re-encrypt $failed_count out of $total_count files"
    return 1
  fi
}

# Activate new key
activate_new_key() {
  local new_key_file="$1"

  log_info "Activating new encryption key"

  local behavior
  behavior=$(get_behavior_mode)

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would activate new encryption key"
      return 0
      ;;
    "PASS")
      log_success "PASS MODE: New key activation simulated successfully"
      return 0
      ;;
    "FAIL")
      log_error "FAIL MODE: Simulating new key activation failure"
      return 1
      ;;
    "SKIP")
      log_info "SKIP MODE: New key activation skipped"
      return 0
      ;;
    "TIMEOUT")
      log_info "TIMEOUT MODE: Simulating new key activation timeout"
      sleep 3
      return 124
      ;;
  esac

  # EXECUTE mode - Actual key activation
  local age_key_file
  age_key_file=$(get_age_key_file)
  local sops_config="$PROJECT_ROOT/.sops.yaml"

  # Backup old files before replacement
  mv "$age_key_file" "${age_key_file}.old"
  mv "$sops_config" "${sops_config}.old"

  # Activate new files
  mv "$new_key_file" "$age_key_file"
  mv "${sops_config}.new" "$sops_config"

  log_success "✅ New encryption key activated"
  log_info "Old files saved with .old extension"
  return 0
}

# Validate key rotation
validate_rotation() {
  log_info "Validating key rotation"

  check_age
  check_sops
  validate_age_key_file

  # Test decryption of a sample secrets file
  local sample_file
  sample_file=$(find "$PROJECT_ROOT" -name "*.enc" -print0 2>/dev/null | head -z -1 | tr -d '\0' || echo "")

  if [[ -n "$sample_file" ]]; then
    log_info "Testing decryption of: $sample_file"
    if decrypt_file "$sample_file" "/tmp/test-decrypt" >/dev/null 2>&1; then
      log_success "✅ Decryption test passed"
      rm -f "/tmp/test-decrypt"
    else
      log_error "❌ Decryption test failed"
      return 1
    fi
  else
    log_warn "No secrets files found to test decryption"
  fi

  log_success "✅ Key rotation validation completed successfully"
}

# Main key rotation workflow
rotate_keys() {
  log_info "Starting encryption key rotation process"

  # Step 1: Backup current setup
  local backup_dir
  backup_dir=$(backup_current_setup)

  # Step 2: Generate new key
  local new_key_file="${backup_dir}/mise-age-new.txt"
  if ! generate_new_key; then
    log_error "Key rotation failed at key generation step"
    return 1
  fi

  # Move new key to project location temporarily
  local age_key_file
  age_key_file=$(get_age_key_file)
  mv "${backup_dir}/mise-age-new.txt" "$age_key_file.new"

  # Step 3: Update SOPS configuration
  if ! update_sops_configuration "$age_key_file.new" "$backup_dir"; then
    log_error "Key rotation failed at SOS configuration step"
    return 1
  fi

  # Step 4: Re-encrypt all secrets
  if ! re_encrypt_secrets "$age_key_file.new"; then
    log_error "Key rotation failed at re-encryption step"
    return 1
  fi

  # Step 5: Activate new key
  if ! activate_new_key "$age_key_file.new"; then
    log_error "Key rotation failed at key activation step"
    return 1
  fi

  # Step 6: Validate rotation
  if ! validate_rotation; then
    log_error "Key rotation failed at validation step"
    return 1
  fi

  log_success "✅ Key rotation completed successfully"
  log_info "Backup location: $backup_dir"
  log_info "Keep the backup for at least 30 days before deletion"

  # Show summary
  echo ""
  echo "🔑 Key Rotation Summary:"
  echo "  Backup Directory: $backup_dir"
  echo "  New Key Active: Yes"
  echo "  Secrets Re-encrypted: Yes"
  echo "  Validation Passed: Yes"
  echo ""
  echo "⚠️  Important:"
  echo "  • Keep the backup for at least 30 days"
  echo "  • Update any external systems that use the old key"
  echo "  • Test decryption with the new key"
  echo "  • Document the rotation in your change log"
}

# Main execution
main() {
  local action="${1:-help}"
  shift || true

  case "$action" in
    "rotate")
      rotate_keys "$@"
      ;;
    "backup")
      backup_current_setup
      ;;
    "generate")
      generate_new_key
      ;;
    "validate")
      validate_rotation
      ;;
    "help"|"--help"|"-h")
      cat << EOF
Secrets Key Rotation Script v$KEY_ROTATION_VERSION

Usage: $0 <action> [options]

Actions:
  rotate                                Complete key rotation workflow
  backup                                Backup current key and configuration
  generate                              Generate new encryption key
  validate                              Validate current key setup
  help                                  Show this help message

Key Rotation Process:
  1. Backup current setup
  2. Generate new encryption key
  3. Update SOPS configuration
  4. Re-encrypt all secrets files
  5. Activate new key
  6. Validate rotation

Security Notes:
  • Keep backups for at least 30 days
  • Test thoroughly before production deployment
  • Update external systems that use the old key
  • Document the rotation in change logs

Examples:
  $0 rotate                              # Complete key rotation
  $0 backup                               # Backup current setup only
  $0 validate                             # Validate current key setup

Testability Examples:
  CI_TEST_MODE=DRY_RUN $0 rotate
  CI_SECRETS_ROTATION_BEHAVIOR=FAIL $0 generate
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