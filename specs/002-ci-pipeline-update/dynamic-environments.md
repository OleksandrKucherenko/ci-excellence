# Dynamic Environment Management System - Version 1.0.0

## Overview

A flexible, extensible environment management system that allows users to create custom environments while maintaining staging and production as the default supported environments.

## Requirements

### 1. Default Environment Support
- **Staging**: Development and testing environment
- **Production**: Production environment with enhanced security
- **Validation**: Scripts validate against supported environments only

### 2. Dynamic Environment Creation
- Users can create new environments via Mise tasks
- Inheritance from staging or production base configurations
- Automatic folder structure creation with .gitkeep files
- Environment list discovered by enumerating environments/* directories

### 3. Environment Discovery and Validation
- Scripts dynamically discover supported environments
- Validation ensures only configured environments are used
- Automatic environment detection in deployment scripts

### 4. Secret Management
- JSON format for environment secrets (instead of .enc files)
- Support for comments with JSON (or switch to TOML/YAML if needed)
- Hierarchical secret inheritance from base environments

### 5. Environment Lifecycle
- **Create**: `mise run env create <name> --from <base>`
- **Validate**: Automatic validation before deployment
- **Update**: Configuration updates supported
- **Delete**: Safe deletion with confirmation

## Architecture

### Environment Structure

```
environments/
├── global/                          # Global configuration and secrets
│   ├── config.yml
│   └── secrets.json
├── staging/                         # Default environment
│   ├── config.yml
│   ├── secrets.json
│   └── regions/
│       ├── us-east/
│       │   └── config.yml
│       └── eu-west/
│           └── config.yml
├── production/                      # Default environment
│   ├── config.yml
│   ├── secrets.json
│   └── regions/
│       ├── us-east/
│       │   └── config.yml
│       └── eu-west/
│           └── config.yml
├── custom-app/                      # Dynamic environment
│   ├── config.yml
│   ├── secrets.json
│   ├── .gitkeep
│   └── regions/
│       └── .gitkeep
└── testing/                        # Dynamic environment
    ├── config.yml
    ├── secrets.json
    ├── .gitkeep
    └── .gitkeep
```

### Configuration Inheritance

```yaml
# environments/custom-app/config.yml
extends: staging  # Inherit from staging
environment:
  name: custom-app
  description: "Custom application environment"
  type: development
  inherits:
    - staging-secrets
    - staging-config

overrides:
  deployment:
    strategy: canary
    timeout: 30m
```

### Secret Inheritance Example

```json
{
  "database": {
    "host": "custom-app-db.example.com",
    "port": 5432,
    "name": "custom_app_db"
  },
  "inherited_from_staging": {
    "redis_host": "staging-redis.example.com"
  },
  "custom_values": {
    "feature_flag": "new_feature_enabled"
  }
}
```

## Mise Tasks

### Environment Management Tasks

```bash
# List available environments
mise run env list

# Create new environment (inherits from staging)
mise run env create testing --from staging

# Create production-like environment
mise run env create pre-production --from production

# Validate environment configuration
mise run env validate production

# Update environment configuration
mise run env update testing --key feature_flag --value true

# Delete environment with confirmation
mise run env delete testing

# Show environment details
mise run env show production
```

## Implementation Requirements

### 1. Environment Discovery Script

Location: `scripts/lib/environment.sh`

```bash
# Discover supported environments
discover_environments() {
  local environments=()
  for env_dir in environments/*/; do
    if [[ -d "$env_dir" && -f "$env_dir/config.yml" ]]; then
      env_name=$(basename "$env_dir")
      environments+=("$env_name")
    fi
  done
  echo "${environments[@]}"
}

# Validate environment exists
validate_environment() {
  local env="$1"
  [[ -d "environments/$env" && -f "environments/$env/config.yml" ]]
}

# Get environment configuration
get_env_config() {
  local env="$1"
  cat "environments/$env/config.yml"
}
```

### 2. Environment Management Tasks

Location: `scripts/profile/env-*.sh`

```bash
# scripts/profile/env-create.sh
env_create() {
  local env_name="$1"
  local base_env="${2:-staging}"

  # Validate inputs
  if [[ -z "$env_name" ]]; then
    echo "❌ Environment name is required"
    return 1
  fi

  if [[ -d "environments/$env_name" ]]; then
    echo "❌ Environment $env_name already exists"
    return 1
  fi

  if ! validate_environment "$base_env"; then
    echo "❌ Base environment $base_env does not exist"
    return 1
  fi

  # Create environment structure
  mkdir -p "environments/$env_name"
  mkdir -p "environments/$env_name/regions"
  touch "environments/$env_name/.gitkeep"
  touch "environments/$env_name/regions/.gitkeep"

  # Create configuration with inheritance
  cat > "environments/$env_name/config.yml" << EOF
extends: $base_env

environment:
  name: $env_name
  description: "Environment created from $base_env"
  type: development
  created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
  inherits:
    - $base_env-secrets
    - $base_env-config

overrides:
  deployment:
    created_by: "mise task env create"
    created_at: "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
EOF

  # Create secrets file with inheritance support
  cat > "environments/$env_name/secrets.json" << EOF
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

  echo "✅ Environment $env_name created successfully (inherits from $base_env)"
}

# scripts/profile/env-delete.sh
env_delete() {
  local env_name="$1"

  if [[ -z "$env_name" ]]; then
    echo "❌ Environment name is required"
    return 1
  fi

  if [[ "$env_name" == "staging" || "$env_name" == "production" ]]; then
    echo "❌ Cannot delete default environments: staging, production"
    return 1
  fi

  if [[ ! -d "environments/$env_name" ]]; then
    echo "❌ Environment $env_name does not exist"
    return 1
  fi

  # Safety confirmation
  echo "⚠️  WARNING: This will permanently delete environment $env_name"
  echo "   - All configuration files"
  echo "   - All secrets"
  echo "   - Region configurations"
  echo ""
  read -p "Type 'DELETE' to confirm: " -r confirmation

  if [[ "$confirmation" != "DELETE" ]]; then
    echo "❌ Environment deletion cancelled"
    return 1
  fi

  # Remove environment directory
  rm -rf "environments/$env_name"

  echo "✅ Environment $env_name deleted successfully"
}
```

### 3. Environment Validation

Updated validation scripts to use dynamic discovery:

```bash
# scripts/lib/validation.sh
validate_environment_exists() {
  local env="$1"

  # Check if environment directory exists
  if [[ ! -d "environments/$env" ]]; then
    log_error "❌ Environment '$env' does not exist"
    log_info "Available environments: $(discover_environments | tr '\n' ' ')"
    return 1
  fi

  # Check if configuration exists
  if [[ ! -f "environments/$env/config.yml" ]]; then
    log_error "❌ Environment '$env' configuration not found"
    return 1
  fi

  # Validate configuration YAML syntax
  if command -v yq >/dev/null 2>&1; then
    if ! yq eval "environments/$env/config.yml" >/dev/null 2>&1; then
      log_error "❌ Invalid YAML syntax in environment configuration"
      return 1
    fi
  fi

  return 0
}

get_supported_environments() {
  discover_environments
}
```

### 4. Updated Deployment Scripts

Modified deployment scripts to use dynamic environment validation:

```bash
# scripts/ci/deployment/15-ci-validate-deployment-params.sh
validate_environment() {
    local valid_environments
    valid_environments=($(get_supported_environments))

    local is_valid=false

    for env in "${valid_environments[@]}"; do
        if [[ "$ENVIRONMENT" == "$env" ]]; then
            is_valid=true
            break
        fi
    done

    if [[ "$is_valid" != "true" ]]; then
        log_error "❌ Invalid environment: $ENVIRONMENT"
        log_error "Available environments: ${valid_environments[*]}"
        log_info "Create new environments with: mise run env create <name> --from <base>"
        exit 1
    fi

    log_info "✅ Environment '$ENVIRONMENT' validated"
}
```

### 5. Updated Mise Configuration

Add environment management tasks to `mise.toml`:

```toml
[tasks.env]
# Environment management
list = ["./scripts/profile/env-list.sh"]
show = ["./scripts/profile/env-show.sh \"$@\""]
create = ["./scripts/profile/env-create.sh \"$@\""]
update = ["./scripts/profile/env-update.sh \"$@\""]
delete = ["./scripts/profile/env-delete.sh \"$@\""]
validate = ["./scripts/profile/env-validate.sh \"$@\""]
```

## Security Considerations

### 1. Environment Isolation
- Each environment has isolated configuration and secrets
- No cross-environment secret contamination
- Secure defaults for new environments

### 2. Access Control
- Default environments (staging, production) cannot be deleted
- Environment creation may require elevated permissions
- Audit trail for environment changes

### 3. Secret Management
- JSON format allows structured secrets with comments support
- Inheritance reduces duplication while maintaining security
- Regular secret rotation supported

### 4. Validation
- YAML syntax validation for configurations
- Environment existence validation before operations
- Type checking for configuration values

## Migration Guide

### From Current System

1. **Convert existing secrets**:
   ```bash
   # Convert .enc files to JSON with comments
   mise run env convert-secrets
   ```

2. **Update environment structure**:
   ```bash
   # Ensure proper folder structure
   mise run env validate-all
   ```

3. **Update scripts**:
   - Scripts already support dynamic environment discovery
   - No changes needed for existing functionality

### Validation Checklist

- [ ] Default environments (staging, production) working
- [ ] Dynamic environment creation via Mise tasks
- [ ] Environment discovery in scripts working
- [ ] Secret inheritance functioning correctly
- [ ] Environment validation preventing invalid operations
- [ ] Secure deletion of custom environments
- [ ] Configuration inheritance from base environments

## Testing

### Environment Creation Test
```bash
# Create new environment
mise run env create testing --from staging
validate_environment testing
```

### Environment Validation Test
```bash
# Test invalid environment
validate_environment nonexistent && return 1
validate_environment invalid_name && return 1
```

### Secret Inheritance Test
```bash
# Test that new environment inherits from staging
./scripts/lib/environment-test.sh test_inheritance testing staging
```

This dynamic environment system provides flexibility while maintaining security and consistency across all deployments.