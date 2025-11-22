#!/bin/bash
# CI Cloud Region Mapping Script - Version 1.0.0
#
# PURPOSE: Provide cloud-agnostic region mapping and validation for multi-cloud deployments
#
# USAGE:
#   ./scripts/ci/security/03-ci-cloud-region-mapping.sh <cloud_provider> <region_code>
#
# EXAMPLES:
#   # Map AWS region
#   ./scripts/ci/security/03-ci-cloud-region-mapping.sh "aws" "us-east-1"
#
#   # Map GCP region
#   ./scripts/ci/security/03-ci-cloud-region-mapping.sh "gcp" "us-central1"
#
#   # Map Azure region
#   ./scripts/ci/security/03-ci-cloud-region-mapping.sh "azure" "eastus"
#
#   # Validate all regions
#   ./scripts/ci/security/03-ci-cloud-region-mapping.sh "validate" "all"
#
# TESTABILITY ENVIRONMENT VARIABLES:
#   - CI_TEST_MODE: Set to "dry_run" to simulate region validation
#   - CLOUD_REGION_MODE: Override cloud region behavior
#
# EXTENSION POINTS:
#   - Add custom cloud providers in configure_custom_providers()
#   - Extend region validation in validate_custom_regions()
#   - Customize compliance checks in configure_compliance_rules()
#
# SIZE GUIDELINES:
#   - Keep script under 50 lines (excluding comments and documentation)
#   - Extract complex mapping logic to helper functions
#   - Use shared utilities for common operations
#
# DEPENDENCIES:
#   - Required: bash, jq
#   - Optional: aws-cli, gcloud, az-cli

set -euo pipefail

# Script configuration
SCRIPT_NAME="$(basename "$0" .sh)"
SCRIPT_VERSION="1.0.0"
SCRIPT_MODE="${SCRIPT_MODE:-${CI_TEST_MODE:-default}}"

# Source libraries and utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/config.sh"
source "${SCRIPT_DIR}/../../lib/logging.sh"

# Cloud provider and region
CLOUD_PROVIDER="${1:-}"
REGION_CODE="${2:-}"

# Compliance and security settings
REQUIRE_GDPR_COMPLIANCE="${REQUIRE_GDPR_COMPLIANCE:-true}"
REQUIRE_SOC2_COMPLIANCE="${REQUIRE_SOC2_COMPLIANCE:-false}"
REQUIRE_HIPAA_COMPLIANCE="${REQUIRE_HIPAA_COMPLIANCE:-false}"

# Main cloud region mapping function
map_cloud_region() {
    if [[ -z "$CLOUD_PROVIDER" ]]; then
        log_error "❌ Cloud provider is required"
        exit 1
    fi

    log_info "Mapping cloud region for provider: $CLOUD_PROVIDER, region: $REGION_CODE"

    case "$CLOUD_PROVIDER" in
        "aws")
            map_aws_region
            ;;
        "gcp")
            map_gcp_region
            ;;
        "azure")
            map_azure_region
            ;;
        "validate")
            validate_all_regions
            ;;
        *)
            log_error "❌ Unsupported cloud provider: $CLOUD_PROVIDER"
            log_info "Supported providers: aws, gcp, azure"
            exit 1
            ;;
    esac
}

# Map AWS region
map_aws_region() {
    log_info "Mapping AWS region: $REGION_CODE"

    if [[ "$SCRIPT_MODE" == "dry_run" ]]; then
        log_info "[DRY RUN] Would map AWS region: $REGION_CODE"
        return 0
    fi

    # AWS region mapping database
    local aws_regions=(
        "us-east-1:US-East (N. Virginia):North America:GDPR,SOCS"
        "us-west-2:US-West (Oregon):North America:GDPR,SOCS"
        "eu-west-1:EU-West (Ireland):Europe:GDPR,SOCS,HIPAA"
        "eu-central-1:EU-Central (Frankfurt):Europe:GDPR,SOCS,HIPAA"
        "ap-southeast-1:Asia-Pacific (Singapore):Asia-Pacific:GDPR,SOCS"
        "ap-northeast-1:Asia-Pacific (Tokyo):Asia-Pacific:GDPR,SOCS"
    )

    for region_info in "${aws_regions[@]}"; do
        IFS=':' read -r region_name location compliance <<< "$region_info"
        if [[ "$REGION_CODE" == "$region_name" ]]; then
            validate_region_compliance "$region_name" "$location" "$compliance"
            output_region_mapping "$CLOUD_PROVIDER" "$region_name" "$location" "$compliance"
            return 0
        fi
    done

    log_error "❌ Unknown AWS region: $REGION_CODE"
    exit 1
}

# Map GCP region
map_gcp_region() {
    log_info "Mapping GCP region: $REGION_CODE"

    if [[ "$SCRIPT_MODE" == "dry_run" ]]; then
        log_info "[DRY RUN] Would map GCP region: $REGION_CODE"
        return 0
    fi

    # GCP region mapping database
    local gcp_regions=(
        "us-east1:US-East (South Carolina):North America:GDPR,SOCS"
        "us-west1:US-West (Oregon):North America:GDPR,SOCS"
        "europe-west1:Europe-West (Belgium):Europe:GDPR,SOCS,HIPAA"
        "europe-west3:Europe-West (Frankfurt):Europe:GDPR,SOCS,HIPAA"
        "asia-southeast1:Asia-Pacific (Singapore):Asia-Pacific:GDPR,SOCS"
        "asia-northeast1:Asia-Pacific (Tokyo):Asia-Pacific:GDPR,SOCS"
    )

    for region_info in "${gcp_regions[@]}"; do
        IFS=':' read -r region_name location compliance <<< "$region_info"
        if [[ "$REGION_CODE" == "$region_name" ]]; then
            validate_region_compliance "$region_name" "$location" "$compliance"
            output_region_mapping "$CLOUD_PROVIDER" "$region_name" "$location" "$compliance"
            return 0
        fi
    done

    log_error "❌ Unknown GCP region: $REGION_CODE"
    exit 1
}

# Map Azure region
map_azure_region() {
    log_info "Mapping Azure region: $REGION_CODE"

    if [[ "$SCRIPT_MODE" == "dry_run" ]]; then
        log_info "[DRY RUN] Would map Azure region: $REGION_CODE"
        return 0
    fi

    # Azure region mapping database
    local azure_regions=(
        "eastus:US-East (Virginia):North America:GDPR,SOCS"
        "westus2:US-West (Washington):North America:GDPR,SOCS"
        "westeurope:Europe-West (Netherlands):Europe:GDPR,SOCS,HIPAA"
        "germanywestcentral:Germany-West Central:Europe:GDPR,SOCS,HIPAA"
        "southeastasia:Asia-Pacific (Singapore):Asia-Pacific:GDPR,SOCS"
        "japaneast:Asia-Pacific (Tokyo):Asia-Pacific:GDPR,SOCS"
    )

    for region_info in "${azure_regions[@]}"; do
        IFS=':' read -r region_name location compliance <<< "$region_info"
        if [[ "$REGION_CODE" == "$region_name" ]]; then
            validate_region_compliance "$region_name" "$location" "$compliance"
            output_region_mapping "$CLOUD_PROVIDER" "$region_name" "$location" "$compliance"
            return 0
        fi
    done

    log_error "❌ Unknown Azure region: $REGION_CODE"
    exit 1
}

# Validate region compliance
validate_region_compliance() {
    local region="$1"
    local location="$2"
    local compliance="$3"

    log_info "Validating compliance for region: $region"

    # Parse compliance requirements
    IFS=',' read -ra compliance_array <<< "$compliance"

    # Check GDPR compliance
    if [[ "$REQUIRE_GDPR_COMPLIANCE" == "true" ]]; then
        if [[ " ${compliance_array[*]} " =~ " GDPR " ]]; then
            log_success "✅ GDPR compliance verified for $region"
        else
            log_error "❌ GDPR compliance required but not supported in $region"
            exit 1
        fi
    fi

    # Check SOC2 compliance
    if [[ "$REQUIRE_SOC2_COMPLIANCE" == "true" ]]; then
        if [[ " ${compliance_array[*]} " =~ " SOCS " ]]; then
            log_success "✅ SOC2 compliance verified for $region"
        else
            log_error "❌ SOC2 compliance required but not supported in $region"
            exit 1
        fi
    fi

    # Check HIPAA compliance
    if [[ "$REQUIRE_HIPAA_COMPLIANCE" == "true" ]]; then
        if [[ " ${compliance_array[*]} " =~ " HIPAA " ]]; then
            log_success "✅ HIPAA compliance verified for $region"
        else
            log_error "❌ HIPAA compliance required but not supported in $region"
            exit 1
        fi
    fi

    log_success "✅ Compliance validation passed for $region"
}

# Output region mapping
output_region_mapping() {
    local provider="$1"
    local region="$2"
    local location="$3"
    local compliance="$4"

    if [[ "$SCRIPT_MODE" == "dry_run" ]]; then
        echo "[DRY RUN] Would output region mapping:"
        echo "provider=$provider"
        echo "region=$region"
        echo "location=$location"
        echo "compliance=$compliance"
        return 0
    fi

    # Output to GitHub Actions
    echo "cloud_provider=$provider" >> "$GITHUB_OUTPUT"
    echo "cloud_region=$region" >> "$GITHUB_OUTPUT"
    echo "cloud_location=$location" >> "$GITHUB_OUTPUT"
    echo "cloud_compliance=$compliance" >> "$GITHUB_OUTPUT"

    log_info "Region mapping output: $provider/$region ($location) [$compliance]"
}

# Validate all regions
validate_all_regions() {
    log_info "Validating all configured regions"

    local providers=("aws" "gcp" "azure")
    local validation_passed=true

    for provider in "${providers[@]}"; do
        log_info "Validating $provider regions..."

        # Test a few regions from each provider
        case "$provider" in
            "aws")
                CLOUD_PROVIDER="aws" REGION_CODE="us-east-1" map_aws_region || validation_passed=false
                CLOUD_PROVIDER="aws" REGION_CODE="eu-west-1" map_aws_region || validation_passed=false
                ;;
            "gcp")
                CLOUD_PROVIDER="gcp" REGION_CODE="us-east1" map_gcp_region || validation_passed=false
                CLOUD_PROVIDER="gcp" REGION_CODE="europe-west1" map_gcp_region || validation_passed=false
                ;;
            "azure")
                CLOUD_PROVIDER="azure" REGION_CODE="eastus" map_azure_region || validation_passed=false
                CLOUD_PROVIDER="azure" REGION_CODE="westeurope" map_azure_region || validation_passed=false
                ;;
        esac
    done

    if [[ "$validation_passed" == "true" ]]; then
        log_success "✅ All region validations passed"
    else
        log_error "❌ Some region validations failed"
        exit 1
    fi
}

# Custom cloud providers extension point
configure_custom_providers() {
    # Override this function to add custom cloud provider configurations
    log_debug "Custom cloud providers (no additional providers defined)"
}

# Custom region validation extension point
validate_custom_regions() {
    # Override this function to add custom region validation logic
    log_debug "Custom region validation (no additional validation defined)"
}

# Compliance configuration extension point
configure_compliance_rules() {
    # Override this function to add custom compliance rule configurations
    log_debug "Custom compliance rules (no additional rules defined)"
}

# Main function
main() {
    log_info "$SCRIPT_NAME v$SCRIPT_VERSION - Cloud Region Mapping"

    # Initialize project configuration
    load_project_config

    # Map cloud region
    map_cloud_region

    # Run custom extensions if defined
    if command -v configure_custom_providers >/dev/null 2>&1; then
        configure_custom_providers
    fi

    if command -v validate_custom_regions >/dev/null 2>&1; then
        validate_custom_regions
    fi

    if command -v configure_compliance_rules >/dev/null 2>&1; then
        configure_compliance_rules
    fi

    log_success "✅ Cloud region mapping completed"
}

# Run main function with all arguments
main "$@"