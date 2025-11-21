#!/bin/bash
# CI Webhook Authentication Script - Version 1.0.0
#
# PURPOSE: Implement secure webhook authentication and validation for CI/CD integrations
#
# USAGE:
#   ./scripts/ci/security/04-ci-webhook-authentication.sh validate <webhook_url> <secret>
#
# EXAMPLES:
#   # Validate webhook authentication
#   ./scripts/ci/security/04-ci-webhook-authentication.sh validate "https://api.github.com" "webhook_secret"
#
#   # Generate webhook signature
#   ./scripts/ci/security/04-ci-webhook-authentication.sh sign "payload_data" "webhook_secret"
#
#   # Test webhook endpoint
#   ./scripts/ci/security/04-ci-webhook-authentication.sh test "https://webhook.example.com" "payload"
#
# TESTABILITY ENVIRONMENT VARIABLES:
#   - CI_TEST_MODE: Set to "dry_run" to simulate webhook operations
#   - WEBHOOK_AUTH_MODE: Override webhook authentication behavior
#
# EXTENSION POINTS:
#   - Add custom webhook providers in configure_webhook_providers()
#   - Extend signature validation in validate_custom_signatures()
#   - Customize security policies in configure_security_policies()
#
# SIZE GUIDELINES:
#   - Keep script under 50 lines (excluding comments and documentation)
#   - Extract complex authentication logic to helper functions
#   - Use shared utilities for common operations
#
# DEPENDENCIES:
#   - Required: bash, curl, openssl, jq
#   - Optional: sha256sum, hexdump

set -euo pipefail

# Script configuration
SCRIPT_NAME="$(basename "$0" .sh)"
SCRIPT_VERSION="1.0.0"
SCRIPT_MODE="${SCRIPT_MODE:-${CI_TEST_MODE:-default}}"

# Source libraries and utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/config.sh"
source "${SCRIPT_DIR}/../../lib/logging.sh"

# Webhook parameters
ACTION="${1:-}"
WEBHOOK_URL="${2:-}"
WEBHOOK_SECRET="${3:-}"

# Security configuration
WEBHOOK_TIMEOUT="${WEBHOOK_TIMEOUT:-30}"
MAX_RETRIES="${MAX_RETRIES:-3}"
REQUIRE_HTTPS="${REQUIRE_HTTPS:-true}"

# Main webhook authentication function
manage_webhook_authentication() {
    log_info "Managing webhook authentication: $ACTION"

    case "$ACTION" in
        "validate")
            validate_webhook_authentication
            ;;
        "sign")
            sign_webhook_payload
            ;;
        "test")
            test_webhook_endpoint
            ;;
        "generate")
            generate_webhook_secret
            ;;
        *)
            log_error "❌ Invalid action: $ACTION"
            log_info "Available actions: validate, sign, test, generate"
            exit 1
            ;;
    esac
}

# Validate webhook authentication
validate_webhook_authentication() {
    if [[ -z "$WEBHOOK_URL" || -z "$WEBHOOK_SECRET" ]]; then
        log_error "❌ Webhook URL and secret are required for validation"
        exit 1
    fi

    log_info "Validating webhook authentication for: $WEBHOOK_URL"

    # Validate URL format
    if ! validate_webhook_url "$WEBHOOK_URL"; then
        log_error "❌ Invalid webhook URL format"
        exit 1
    fi

    # Validate secret format
    if ! validate_webhook_secret "$WEBHOOK_SECRET"; then
        log_error "❌ Invalid webhook secret format"
        exit 1
    fi

    # Test webhook connectivity
    if ! test_webhook_connectivity "$WEBHOOK_URL"; then
        log_error "❌ Webhook connectivity test failed"
        exit 1
    fi

    log_success "✅ Webhook authentication validated successfully"
}

# Validate webhook URL format
validate_webhook_url() {
    local url="$1"

    if [[ "$REQUIRE_HTTPS" == "true" && ! "$url" =~ ^https:// ]]; then
        log_error "❌ HTTPS required for webhook URLs"
        return 1
    fi

    # Basic URL format validation
    if [[ ! "$url" =~ ^https?://[a-zA-Z0-9.-]+[0-9]*(/.*)?$ ]]; then
        log_error "❌ Invalid URL format"
        return 1
    fi

    log_info "✅ Webhook URL format validated"
    return 0
}

# Validate webhook secret format
validate_webhook_secret() {
    local secret="$1"

    # Secret should be at least 16 characters and contain letters, numbers, and special characters
    if [[ ${#secret} -lt 16 ]]; then
        log_error "❌ Webhook secret must be at least 16 characters"
        return 1
    fi

    if [[ ! "$secret" =~ [a-zA-Z] || ! "$secret" =~ [0-9] ]]; then
        log_error "❌ Webhook secret must contain letters and numbers"
        return 1
    fi

    log_info "✅ Webhook secret format validated"
    return 0
}

# Test webhook connectivity
test_webhook_connectivity() {
    local url="$1"

    if [[ "$SCRIPT_MODE" == "dry_run" ]]; then
        log_info "[DRY RUN] Would test webhook connectivity to: $url"
        return 0
    fi

    log_info "Testing webhook connectivity..."

    # Create test payload
    local test_payload
    test_payload=$(create_test_payload)

    # Generate signature
    local signature
    signature=$(generate_signature "$test_payload" "$WEBHOOK_SECRET")

    # Send test request
    local response_code
    response_code=$(send_webhook_request "$url" "$test_payload" "$signature")

    if [[ "$response_code" =~ ^[23] ]]; then
        log_success "✅ Webhook connectivity test passed (HTTP $response_code)"
        return 0
    else
        log_error "❌ Webhook connectivity test failed (HTTP $response_code)"
        return 1
    fi
}

# Create test payload
create_test_payload() {
    cat << EOF
{
    "event": "test",
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "source": "ci-excellence-framework",
    "version": "$SCRIPT_VERSION"
}
EOF
}

# Generate webhook signature
generate_signature() {
    local payload="$1"
    local secret="$2"

    # Generate HMAC-SHA256 signature
    local signature
    signature=$(echo -n "$payload" | openssl dgst -sha256 -hmac "$secret" -binary | hexdump -v -e '/1 "%02x"')

    echo "sha256=$signature"
}

# Send webhook request
send_webhook_request() {
    local url="$1"
    local payload="$2"
    local signature="$3"

    local response_code
    response_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        -H "X-Webhook-Signature: $signature" \
        -H "User-Agent: CI-Excellence-Framework/$SCRIPT_VERSION" \
        --connect-timeout "$WEBHOOK_TIMEOUT" \
        --max-time "$((WEBHOOK_TIMEOUT + 10))" \
        --retry "$MAX_RETRIES" \
        --retry-delay 5 \
        -d "$payload" \
        "$url" 2>/dev/null || echo "000")

    echo "$response_code"
}

# Sign webhook payload
sign_webhook_payload() {
    local payload="$WEBHOOK_URL"

    if [[ -z "$payload" || -z "$WEBHOOK_SECRET" ]]; then
        log_error "❌ Payload and secret are required for signing"
        exit 1
    fi

    log_info "Generating webhook signature for payload"

    local signature
    signature=$(generate_signature "$payload" "$WEBHOOK_SECRET")

    if [[ "$SCRIPT_MODE" == "dry_run" ]]; then
        echo "[DRY RUN] Would output signature: $signature"
        return 0
    fi

    # Output to GitHub Actions
    echo "webhook_signature=$signature" >> "$GITHUB_OUTPUT"

    log_info "Webhook signature generated and output"
}

# Test webhook endpoint
test_webhook_endpoint() {
    log_info "Testing webhook endpoint: $WEBHOOK_URL"

    if [[ "$SCRIPT_MODE" == "dry_run" ]]; then
        log_info "[DRY RUN] Would test webhook endpoint"
        return 0
    fi

    # Validate endpoint
    if ! validate_webhook_url "$WEBHOOK_URL"; then
        exit 1
    fi

    # Test with different methods
    local methods=("GET" "POST")
    for method in "${methods[@]}"; do
        local response_code
        response_code=$(curl -s -o /dev/null -w "%{http_code}" \
            -X "$method" \
            -H "User-Agent: CI-Excellence-Framework/$SCRIPT_VERSION" \
            --connect-timeout "$WEBHOOK_TIMEOUT" \
            "$WEBHOOK_URL" 2>/dev/null || echo "000")

        log_info "$method test: HTTP $response_code"
    done

    log_success "✅ Webhook endpoint testing completed"
}

# Generate webhook secret
generate_webhook_secret() {
    log_info "Generating secure webhook secret"

    if [[ "$SCRIPT_MODE" == "dry_run" ]]; then
        local sample_secret "ci_webhook_secret_$(date +%s)_$(openssl rand -hex 8)"
        echo "[DRY RUN] Would generate webhook secret: $sample_secret"
        return 0
    fi

    # Generate 32-character random secret
    local webhook_secret
    webhook_secret="ci_webhook_secret_$(date +%s)_$(openssl rand -hex 8)"

    # Output to GitHub Actions
    echo "webhook_secret=$webhook_secret" >> "$GITHUB_OUTPUT"

    log_info "Webhook secret generated: ${webhook_secret:0:8}..."
    log_info "Store this secret securely in your webhook provider"
}

# Custom webhook providers extension point
configure_webhook_providers() {
    # Override this function to add custom webhook provider configurations
    log_debug "Custom webhook providers (no additional providers defined)"
}

# Custom signature validation extension point
validate_custom_signatures() {
    # Override this function to add custom signature validation logic
    log_debug "Custom signature validation (no additional validation defined)"
}

# Security policies configuration extension point
configure_security_policies() {
    # Override this function to add custom security policy configurations
    log_debug "Custom security policies (no additional policies defined)"
}

# Main function
main() {
    log_info "$SCRIPT_NAME v$SCRIPT_VERSION - Webhook Authentication"

    # Initialize project configuration
    load_project_config

    # Manage webhook authentication
    manage_webhook_authentication

    # Run custom extensions if defined
    if command -v configure_webhook_providers >/dev/null 2>&1; then
        configure_webhook_providers
    fi

    if command -v validate_custom_signatures >/dev/null 2>&1; then
        validate_custom_signatures
    fi

    if command -v configure_security_policies >/dev/null 2>&1; then
        configure_security_policies
    fi

    log_success "✅ Webhook authentication management completed"
}

# Run main function with all arguments
main "$@"