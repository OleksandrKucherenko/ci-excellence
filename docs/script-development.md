# CI Script Development Guide

This guide provides comprehensive instructions for developing, maintaining, and extending CI scripts in the ci-excellence framework.

## 📋 Table of Contents

1. [Script Structure](#script-structure)
2. [Development Guidelines](#development-guidelines)
3. [Testability Framework](#testability-framework)
4. [Library Integration](#library-integration)
5. [Error Handling](#error-handling)
6. [Logging and Monitoring](#logging-and-monitoring)
7. [Security Considerations](#security-considerations)
8. [Examples by Language](#examples-by-language)
9. [Extension Points](#extension-points)
10. [Testing Strategy](#testing-strategy)

## 🏗️ Script Structure

### Required Elements

Every CI script must include:

1. **Shebang and Strict Mode**
   ```bash
   #!/bin/bash
   set -euo pipefail
   ```

2. **Script Metadata**
   ```bash
   SCRIPT_NAME="$(basename "$0" .sh)"
   SCRIPT_VERSION="1.0.0"
   SCRIPT_MODE="${SCRIPT_MODE:-${CI_TEST_MODE:-default}}"
   ```

3. **Library Imports**
   ```bash
   source "${SCRIPT_DIR}/../lib/config.sh"
   source "${SCRIPT_DIR}/../lib/logging.sh"
   source "${SCRIPT_DIR}/../lib/validation.sh"
   ```

4. **Comprehensive Header Documentation**
   - Purpose description
   - Usage examples
   - Testability variables
   - Extension points
   - Dependencies

### Size Guidelines

- **Maximum 50 lines of code** (excluding comments and documentation)
- **Extract to libraries** if script exceeds this limit
- **Use shared utilities** for common operations

## 🎯 Development Guidelines

### Naming Conventions

- **Script files**: Use kebab-case with descriptive names
  - `10-ci-compile.sh` (prefix with sequence number)
  - `deploy-staging.sh` (clear purpose)
  - `security-scan.sh` (specific function)

- **Functions**: Use descriptive verb-noun combinations
  ```bash
  validate_prerequisites()
  execute_deployment()
  cleanup_resources()
  ```

- **Variables**: Use uppercase for globals, lowercase for locals
  ```bash
  DEFAULT_TIMEOUT=30      # Global constant
  local retry_count=0     # Local variable
  ```

### Code Organization

1. **Configuration Section** (top of script)
2. **Library Imports**
3. **Core Functions** (main logic)
4. **Helper Functions** (utilities)
5. **Main Function** (entry point)
6. **Error Handling** (bottom)

### Best Practices

```bash
# ✅ Good: Use local variables in functions
process_target() {
    local target="$1"
    local timeout="${2:-30}"

    log_info "Processing $target with timeout $timeout"
}

# ❌ Bad: Global variables in functions
target="$1"
timeout="${2:-30}"
```

```bash
# ✅ Good: Proper error handling
if ! validate_prerequisites; then
    log_error "Validation failed"
    return 1
fi

# ❌ Bad: Ignoring errors
validate_prerequisites
```

## 🧪 Testability Framework

### Environment Variables

All scripts must support these testability variables:

```bash
# Core testability variables
CI_TEST_MODE="${CI_TEST_MODE:-default}"      # dry_run, test, production
SCRIPT_MODE="${SCRIPT_MODE:-${CI_TEST_MODE}}" # Script-specific override
DRY_RUN="${DRY_RUN:-false}"                  # Simulate operations
LOG_LEVEL="${LOG_LEVEL:-info}"               # debug, info, warn, error

# Force mode for testing
FORCE_MODE="${FORCE_MODE:-false}"            # Skip safety checks
SKIP_TESTS="${SKIP_TESTS:-false}"            # Skip test execution
```

### Test Mode Implementation

```bash
execute_operation() {
    local operation="$1"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would execute: $operation"
        return 0
    fi

    # Real implementation
    log_info "Executing: $operation"
    # ... actual operation code
}
```

### Testing Functions

Create corresponding test files in `spec/` directory:

```bash
# spec/scripts/your-script_spec.sh
Describe "Your Script"
  It "should validate prerequisites"
    When call source "./scripts/your-script.sh"
    The function "validate_prerequisites" should be defined
  End

  It "should handle dry run mode"
    DRY_RUN=true
    When call execute_operation "test"
    The output should contain "[DRY RUN]"
  End
End
```

## 📚 Library Integration

### Available Libraries

1. **config.sh** - Configuration and deployment management
2. **logging.sh** - Centralized logging with multiple levels
3. **validation.sh** - Input validation and security checks
4. **environment.sh** - Environment-specific operations
5. **deployment.sh** - Deployment orchestration utilities
6. **security.sh** - Security scanning and alerting
7. **git.sh** - Git utilities and tag management

### Using Libraries

```bash
# Source libraries
source "${SCRIPT_DIR}/../lib/config.sh"
source "${SCRIPT_DIR}/../lib/logging.sh"

# Use library functions
validate_environment_variables "API_KEY" "DATABASE_URL"
log_info "Starting deployment"
create_deployment_record "$deployment_id" "$environment" "$region" "$commit"
```

### Creating Custom Libraries

```bash
# scripts/lib/custom.sh
#!/bin/bash

custom_operation() {
    local input="$1"

    log_debug "Performing custom operation on: $input"

    # Your custom logic here

    log_success "Custom operation completed"
}
```

## ⚠️ Error Handling

### Signal Trapping

```bash
# Set up error handling
trap 'handle_error $LINENO' ERR
trap 'cleanup_resources' EXIT

handle_error() {
    local exit_code=$?
    local line_number=$1

    log_error "Script failed at line $line_number with exit code $exit_code"
    cleanup_resources
    exit $exit_code
}
```

### Graceful Failures

```bash
# ✅ Good: Handle failures gracefully
if ! critical_operation; then
    log_error "Critical operation failed"
    send_alert "deployment_failure"
    return 1
fi

# ✅ Good: Provide fallbacks
if command -v aws &> /dev/null; then
    deploy_to_aws
else
    log_warn "AWS CLI not found, using fallback"
    deploy_generic
fi
```

## 📊 Logging and Monitoring

### Logging Levels

```bash
log_debug "Detailed debugging information"    # Only in debug mode
log_info "General information"              # Default level
log_warn "Warning messages"                 # Attention needed
log_error "Error messages"                  # Failed operations
log_success "Success messages"              # Completed operations
```

### Structured Logging

```bash
# Create audit trails
log_info "Operation started" \
    "operation=deployment" \
    "environment=$environment" \
    "version=$version" \
    "user=$USER"

# Performance monitoring
start_time=$(date +%s)
# ... operation
end_time=$(date +%s)
duration=$((end_time - start_time))
log_info "Operation completed" "duration=${duration}s"
```

### Health Checks

```bash
check_script_health() {
    # Check dependencies
    local missing_tools=()
    for tool in git curl jq; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing tools: ${missing_tools[*]}"
        return 1
    fi

    return 0
}
```

## 🔒 Security Considerations

### Input Validation

```bash
validate_input() {
    local input="$1"
    local input_type="$2"

    case "$input_type" in
        "filename")
            # Prevent directory traversal
            if [[ "$input" =~ \.\./ ]]; then
                log_error "Invalid filename: $input"
                return 1
            fi
            ;;
        "url")
            # Validate URL format
            if [[ ! "$input" =~ ^https?:// ]]; then
                log_error "Invalid URL: $input"
                return 1
            fi
            ;;
    esac

    return 0
}
```

### Secret Handling

```bash
# Never log secrets
process_secret() {
    local secret="$1"

    # ✅ Good: Don't log the actual secret
    log_info "Processing secret of length: ${#secret}"

    # ❌ Bad: Logging secrets
    # log_info "Processing secret: $secret"
}
```

### Permissions

```bash
# Check file permissions before operations
if [[ -f "$config_file" ]]; then
    if [[ ! -r "$config_file" ]]; then
        log_error "Cannot read configuration file: $config_file"
        return 1
    fi
fi
```

## 💻 Examples by Language

### Node.js/TypeScript Scripts

```bash
# Build script for Node.js projects
build_nodejs() {
    log_info "Building Node.js application"

    # Install dependencies
    if [[ "$DRY_RUN" != "true" ]]; then
        npm ci --silent

        # Run build
        npm run build

        log_success "Node.js build completed"
    else
        log_info "[DRY RUN] Would build Node.js application"
    fi
}

# Test script for Node.js projects
test_nodejs() {
    log_info "Running Node.js tests"

    local test_cmd="npm test"
    if [[ "$COVERAGE" == "true" ]]; then
        test_cmd="npm run test-coverage"
    fi

    if [[ "$DRY_RUN" != "true" ]]; then
        eval "$test_cmd"
        log_success "Node.js tests completed"
    else
        log_info "[DRY RUN] Would run: $test_cmd"
    fi
}
```

### Python Scripts

```bash
# Build script for Python projects
build_python() {
    log_info "Building Python application"

    if [[ "$DRY_RUN" != "true" ]]; then
        # Install dependencies
        pip install -r requirements.txt

        # Build package
        python -m build

        log_success "Python build completed"
    else
        log_info "[DRY RUN] Would build Python application"
    fi
}

# Test script for Python projects
test_python() {
    log_info "Running Python tests"

    if [[ "$DRY_RUN" != "true" ]]; then
        # Run unit tests
        python -m pytest tests/ -v

        # Run linting
        flake8 src/

        log_success "Python tests completed"
    else
        log_info "[DRY RUN] Would run Python tests"
    fi
}
```

### Go Scripts

```bash
# Build script for Go projects
build_go() {
    log_info "Building Go application"

    if [[ "$DRY_RUN" != "true" ]]; then
        # Download dependencies
        go mod download

        # Build application
        go build -o bin/app ./cmd/main.go

        log_success "Go build completed"
    else
        log_info "[DRY RUN] Would build Go application"
    fi
}

# Test script for Go projects
test_go() {
    log_info "Running Go tests"

    if [[ "$DRY_RUN" != "true" ]]; then
        # Run unit tests
        go test ./... -v

        # Run race condition tests
        go test ./... -race

        log_success "Go tests completed"
    else
        log_info "[DRY RUN] Would run Go tests"
    fi
}
```

## 🔧 Extension Points

### Custom Validation

```bash
# Add your custom validation logic
validate_custom_rules() {
    # Check project-specific requirements
    if [[ ! -f "package.json" ]]; then
        log_error "package.json not found"
        return 1
    fi

    # Validate custom environment variables
    if [[ -z "${CUSTOM_API_KEY:-}" ]]; then
        log_error "CUSTOM_API_KEY not set"
        return 1
    fi

    return 0
}
```

### Plugin Architecture

```bash
# Support for custom plugins
load_plugins() {
    local plugin_dir="${SCRIPT_DIR}/../plugins"

    if [[ -d "$plugin_dir" ]]; then
        for plugin in "$plugin_dir"/*.sh; do
            if [[ -f "$plugin" ]]; then
                log_info "Loading plugin: $(basename "$plugin")"
                source "$plugin"
            fi
        done
    fi
}
```

### Configuration Hooks

```bash
# Before/after hooks for operations
execute_with_hooks() {
    local operation="$1"

    # Run before hook
    if command -v "before_${operation}" &> /dev/null; then
        "before_${operation}"
    fi

    # Execute main operation
    "$operation"

    # Run after hook
    if command -v "after_${operation}" &> /dev/null; then
        "after_${operation}"
    fi
}
```

## 🧪 Testing Strategy

### Unit Testing

```bash
# Test individual functions
test_validation() {
    # Test valid input
    if validate_input "test.txt" "filename"; then
        echo "✅ Valid filename test passed"
    else
        echo "❌ Valid filename test failed"
        return 1
    fi

    # Test invalid input
    if ! validate_input "../etc/passwd" "filename"; then
        echo "✅ Invalid filename test passed"
    else
        echo "❌ Invalid filename test failed"
        return 1
    fi
}
```

### Integration Testing

```bash
# Test complete workflows
test_deployment_workflow() {
    # Setup test environment
    export CI_TEST_MODE="test"
    export DRY_RUN="true"

    # Run deployment
    if ./scripts/deployment/10-ci-deploy-staging.sh deploy; then
        echo "✅ Deployment workflow test passed"
    else
        echo "❌ Deployment workflow test failed"
        return 1
    fi
}
```

### Performance Testing

```bash
# Measure script performance
benchmark_script() {
    local iterations=10
    local total_time=0

    for ((i=1; i<=iterations; i++)); do
        start_time=$(date +%s.%N)

        # Run script
        ./scripts/your-script.sh validate > /dev/null

        end_time=$(date +%s.%N)
        duration=$(echo "$end_time - $start_time" | bc)
        total_time=$(echo "$total_time + $duration" | bc)
    done

    average_time=$(echo "scale=3; $total_time / $iterations" | bc)
    echo "Average execution time: ${average_time}s"
}
```

## 📝 Checklist

Before submitting a new CI script:

- [ ] Script follows the template structure
- [ ] Under 50 lines of code (excluding comments)
- [ ] Comprehensive header documentation
- [ ] Supports CI_TEST_MODE environment variables
- [ ] Proper error handling with traps
- [ ] Uses appropriate logging levels
- [ ] Includes input validation
- [ ] Has corresponding test file
- [ ] Follows naming conventions
- [ ] Documents all dependencies
- [ ] Includes usage examples
- [ ] Handles secrets appropriately
- [ ] Includes extension points

## 🚀 Getting Started

1. **Copy the template**:
   ```bash
   cp templates/ci-script-template.sh scripts/your-new-script.sh
   chmod +x scripts/your-new-script.sh
   ```

2. **Customize the script**:
   - Update the header documentation
   - Implement your specific logic
   - Add validation rules
   - Create test cases

3. **Create tests**:
   ```bash
   # Create corresponding test file
   touch spec/scripts/your-new-script_spec.sh
   ```

4. **Run tests**:
   ```bash
   mise run test
   ```

5. **Validate the script**:
   ```bash
   ./scripts/your-new-script.sh validate
   ```

For more examples and advanced usage, see the existing scripts in the `scripts/` directory.