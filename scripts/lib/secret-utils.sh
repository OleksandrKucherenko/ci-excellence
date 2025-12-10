#!/bin/bash
# Secret Management Utilities
# Provides utilities for SOPS decryption wrapper and environment variable loading

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common utilities" >&2
  exit 1
}

# Configuration
readonly SECRET_UTILS_VERSION="1.0.0"

# Check if SOPS is available
check_sops() {
  if ! command -v sops >/dev/null 2>&1; then
    log_error "SOPS is not installed. Install with: mise install sops"
    return 1
  fi
}

# Check if age is available
check_age() {
  if ! command -v age >/dev/null 2>&1; then
    log_error "Age is not installed. Install with: mise install age"
    return 1
  fi
}

# Get SOPS age key file path
get_age_key_file() {
  local key_file="${MISE_SOPS_AGE_KEY_FILE:-.secrets/mise-age.txt}"
  local sops_key_file="${SOPS_AGE_KEY_FILE:-$key_file}"

  # Check if path is relative or absolute
  if [[ "$sops_key_file" != /* ]]; then
    echo "$PROJECT_ROOT/$sops_key_file"
  else
    echo "$sops_key_file"
  fi
}

# Validate age key file
validate_age_key_file() {
  local key_file
  key_file=$(get_age_key_file)

  if [[ ! -f "$key_file" ]]; then
    log_error "Age key file not found: $key_file"
    log_info "Generate one with: mise run generate-age-key"
    return 1
  fi

  # Basic validation - check if it contains age keys
  if ! grep -q "AGE-SECRET-KEY-1" "$key_file" 2>/dev/null; then
    log_error "Invalid age key file format: $key_file"
    return 1
  fi

  log_debug "Age key file validated: $key_file"
}

# Decrypt SOPS file
decrypt_file() {
  local input_file="$1"
  local output_file="${2:-}"
  local format="${3:-auto}"

  log_info "Decrypting file: $input_file"

  # Check prerequisites
  check_sops
  validate_age_key_file

  if [[ ! -f "$input_file" ]]; then
    log_error "Input file not found: $input_file"
    return 1
  fi

  # Set output file if not provided
  if [[ -z "$output_file" ]]; then
    output_file="${input_file%.enc}"
  fi

  # Decrypt file
  local sops_args=()
  sops_args+=("--decrypt")
  sops_args+=("--config-file" "$PROJECT_ROOT/.sops.yaml")

  if [[ "$format" != "auto" ]]; then
    sops_args+=("--input-type" "$format")
    sops_args+=("--output-type" "$format")
  fi

  if sops "${sops_args[@]}" "$input_file" >"$output_file" 2>/dev/null; then
    log_success "✅ File decrypted successfully: $output_file"
    return 0
  else
    log_error "Failed to decrypt file: $input_file"
    return 1
  fi
}

# Encrypt SOPS file
encrypt_file() {
  local input_file="$1"
  local output_file="${2:-}"
  local format="${3:-auto}"

  log_info "Encrypting file: $input_file"

  # Check prerequisites
  check_sops
  validate_age_key_file

  if [[ ! -f "$input_file" ]]; then
    log_error "Input file not found: $input_file"
    return 1
  fi

  # Set output file if not provided
  if [[ -z "$output_file" ]]; then
    output_file="${input_file}.enc"
  fi

  # Encrypt file
  local sops_args=()
  sops_args+=("--encrypt")
  sops_args+=("--config-file" "$PROJECT_ROOT/.sops.yaml")

  if [[ "$format" != "auto" ]]; then
    sops_args+=("--input-type" "$format")
    sops_args+=("--output-type" "$format")
  fi

  if sops "${sops_args[@]}" "$input_file" >"$output_file" 2>/dev/null; then
    log_success "✅ File encrypted successfully: $output_file"
    return 0
  else
    log_error "Failed to encrypt file: $input_file"
    return 1
  fi
}

# Edit encrypted file
edit_file() {
  local file="$1"
  local editor="${2:-${EDITOR:-vim}}"

  log_info "Editing encrypted file: $file"

  # Check prerequisites
  check_sops
  validate_age_key_file

  if [[ ! -f "$file" ]]; then
    log_error "File not found: $file"
    return 1
  fi

  # Edit file with SOPS
  if SOPS_EDITOR="$editor" sops --config-file "$PROJECT_ROOT/.sops.yaml" "$file"; then
    log_success "✅ File edited successfully: $file"
    return 0
  else
    log_error "Failed to edit file: $file"
    return 1
  fi
}

# Load environment from encrypted file
load_env_file() {
  local env_file="$1"
  local prefix="${2:-}"

  log_info "Loading environment from: $env_file"

  if [[ ! -f "$env_file" ]]; then
    log_error "Environment file not found: $env_file"
    return 1
  fi

  # Determine if file is encrypted
  local is_encrypted=false
  if [[ "$env_file" == *.enc ]] || head -n1 "$env_file" | grep -q "sops:"; then
    is_encrypted=true
  fi

  local temp_env_file
  if [[ "$is_encrypted" == "true" ]]; then
    temp_env_file=$(mktemp)
    if ! decrypt_file "$env_file" "$temp_env_file" "dotenv"; then
      rm -f "$temp_env_file"
      return 1
    fi
    env_file="$temp_env_file"
  fi

  # Load environment variables
  local loaded_count=0
  while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// /}" ]] && continue

    # Parse key-value pairs
    if [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
      local key="${BASH_REMATCH[1]}"
      local value="${BASH_REMATCH[2]}"

      # Remove surrounding quotes
      value=$(echo "$value" | sed 's/^["'\'']//' | sed 's/["'\'']$//')

      # Apply prefix if provided
      if [[ -n "$prefix" && ! "$key" =~ ^$prefix ]]; then
        key="${prefix}${key}"
      fi

      # Export the variable
      export "$key=$value"
      ((loaded_count++))
      log_debug "Loaded: $key"
    fi
  done <"$env_file"

  # Cleanup temp file
  if [[ -n "${temp_env_file:-}" ]]; then
    rm -f "$temp_env_file"
  fi

  log_success "✅ Loaded $loaded_count environment variables"
}

# Get secret value from encrypted file
get_secret() {
  local file="$1"
  local key="$2"
  local default="${3:-}"

  if [[ ! -f "$file" ]]; then
    echo "$default"
    return 1
  fi

  local is_encrypted=false
  if [[ "$file" == *.enc ]] || head -n1 "$file" | grep -q "sops:"; then
    is_encrypted=true
  fi

  local temp_file
  if [[ "$is_encrypted" == "true" ]]; then
    temp_file=$(mktemp)
    if ! decrypt_file "$file" "$temp_file"; then
      rm -f "$temp_file"
      echo "$default"
      return 1
    fi
    file="$temp_file"
  fi

  local value
  case "$file" in
  *.json)
    value=$(get_json_value "$(cat "$file")" "$key" || echo "$default")
    ;;
  *.yaml | *.yml)
    if command -v yq >/dev/null 2>&1; then
      value=$(yq ".$key" "$file" 2>/dev/null || echo "$default")
    else
      log_warn "yq not available, cannot parse YAML file"
      value="$default"
    fi
    ;;
  *)
    # Treat as simple key=value file
    value=$(grep "^${key}=" "$file" 2>/dev/null | cut -d'=' -f2- | tr -d '"' || echo "$default")
    ;;
  esac

  # Cleanup temp file
  if [[ -n "${temp_file:-}" ]]; then
    rm -f "$temp_file"
  fi

  echo "$value"
}

# Set secret in encrypted file
set_secret() {
  local file="$1"
  local key="$2"
  local value="$3"

  log_info "Setting secret in: $file"

  if [[ ! -f "$file" ]]; then
    log_error "File not found: $file"
    return 1
  fi

  local is_encrypted=false
  if [[ "$file" == *.enc ]] || head -n1 "$file" | grep -q "sops:"; then
    is_encrypted=true
  fi

  local temp_file
  if [[ "$is_encrypted" == "true" ]]; then
    temp_file=$(mktemp)
    if ! decrypt_file "$file" "$temp_file"; then
      rm -f "$temp_file"
      return 1
    fi
    file="$temp_file"
  fi

  case "$file" in
  *.json)
    # Update JSON file
    if command -v jq >/dev/null 2>&1; then
      jq ".${key} = \"${value}\"" "$file" >"${file}.tmp" && mv "${file}.tmp" "$file"
    else
      log_error "jq not available, cannot update JSON file"
      return 1
    fi
    ;;
  *)
    # Update simple key=value file
    if grep -q "^${key}=" "$file" 2>/dev/null; then
      # Update existing key
      sed -i.bak "s|^${key}=.*|${key}=\"${value}\"|" "$file"
      rm -f "${file}.bak"
    else
      # Add new key
      echo "${key}=\"${value}\"" >>"$file"
    fi
    ;;
  esac

  # Re-encrypt if needed
  if [[ "$is_encrypted" == "true" ]]; then
    local original_file="${file%.enc}"
    if ! encrypt_file "$file" "$original_file.enc"; then
      rm -f "$temp_file"
      return 1
    fi
    rm -f "$temp_file"
  fi

  log_success "✅ Secret set: $key"
}

# List all secrets in encrypted file
list_secrets() {
  local file="$1"
  local show_values="${2:-false}"

  log_info "Listing secrets in: $file"

  if [[ ! -f "$file" ]]; then
    log_error "File not found: $file"
    return 1
  fi

  local is_encrypted=false
  if [[ "$file" == *.enc ]] || head -n1 "$file" | grep -q "sops:"; then
    is_encrypted=true
  fi

  local temp_file
  if [[ "$is_encrypted" == "true" ]]; then
    temp_file=$(mktemp)
    if ! decrypt_file "$file" "$temp_file"; then
      rm -f "$temp_file"
      return 1
    fi
    file="$temp_file"
  fi

  case "$file" in
  *.json)
    if command -v jq >/dev/null 2>&1; then
      if [[ "$show_values" == "true" ]]; then
        jq -r 'to_entries[] | "\(.key): \(.value)"' "$file"
      else
        jq -r 'keys[]' "$file"
      fi
    else
      log_warn "jq not available, cannot parse JSON file"
    fi
    ;;
  *.yaml | *.yml)
    if command -v yq >/dev/null 2>&1; then
      if [[ "$show_values" == "true" ]]; then
        yq 'to_entries | .[] | "\(.key): \(.value)"' "$file"
      else
        yq 'keys[]' "$file"
      fi
    else
      log_warn "yq not available, cannot parse YAML file"
    fi
    ;;
  *)
    # Simple key=value file
    while IFS= read -r line; do
      if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
        local key="${line%%=*}"
        if [[ "$show_values" == "true" ]]; then
          local value="${line#*=}"
          echo "$key: $(echo "$value" | sed 's/^["'\'']*//' | sed 's/["'\'']*$//')"
        else
          echo "$key"
        fi
      fi
    done <"$file"
    ;;
  esac

  # Cleanup temp file
  if [[ -n "${temp_file:-}" ]]; then
    rm -f "$temp_file"
  fi
}

# Rotate encryption keys
rotate_keys() {
  log_info "Rotating encryption keys"

  check_age
  check_sops

  local key_file
  key_file=$(get_age_key_file)

  # Backup current key
  local backup_file
  backup_file="${key_file}.backup.$(date +%s)"
  cp "$key_file" "$backup_file"
  log_info "Backup key saved: $backup_file"

  # Generate new key pair
  local new_key_file="${key_file}.new"
  age-keygen -o "$new_key_file" >/dev/null 2>&1

  # Extract public key
  local new_public_key
  new_public_key=$(grep "AGE-SECRET-KEY-1" "$new_key_file" | cut -d' ' -f2 | age -d -i -)

  # Update SOPS configuration
  local sops_config="$PROJECT_ROOT/.sops.yaml"
  if [[ -f "$sops_config" ]]; then
    # Add new key to SOPS config (implementation would be more complex)
    log_warn "Manual update of SOPS configuration required to add new key"
    log_info "New public key: $new_public_key"
  fi

  log_success "✅ Key rotation prepared. Update .sops.yaml and re-encrypt secrets."
}

# Main execution
main() {
  local action="${1:-help}"
  shift || true

  case "$action" in
  "decrypt")
    decrypt_file "$@"
    ;;
  "encrypt")
    encrypt_file "$@"
    ;;
  "edit")
    edit_file "$@"
    ;;
  "load-env")
    load_env_file "$@"
    ;;
  "get")
    get_secret "$@"
    ;;
  "set")
    set_secret "$@"
    ;;
  "list")
    list_secrets "$@"
    ;;
  "rotate")
    rotate_keys "$@"
    ;;
  "validate")
    validate_age_key_file
    ;;
  "help" | "--help" | "-h")
    cat <<EOF
Secret Utilities v$SECRET_UTILS_VERSION

Usage: $0 <action> [options]

Actions:
  decrypt <input_file> [output_file] [format]   Decrypt SOPS file
  encrypt <input_file> [output_file] [format]   Encrypt file with SOPS
  edit <file> [editor]                           Edit encrypted file
  load-env <env_file> [prefix]                  Load environment variables
  get <file> <key> [default]                   Get secret value
  set <file> <key> <value>                      Set secret value
  list <file> [show_values]                     List secrets in file
  rotate                                         Rotate encryption keys
  validate                                       Validate age key file

Examples:
  $0 decrypt environments/production/secrets.enc
  $0 edit .env.secrets.json
  $0 load-env environments/production/secrets.enc PROD_
  $0 get .env.secrets.json DATABASE_URL
  $0 set .env.secrets.json API_KEY "new-value"
  $0 list .env.secrets.json true
EOF
    exit 0
    ;;
  *)
    log_error "Unknown action: $action"
    echo "Use '$0 help' for usage information" >&2
    exit 1
    ;;
  esac
}

# CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
