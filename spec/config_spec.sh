#!/usr/bin/env bash

# Load shellspec helper
# shellcheck source=spec_helper.sh
. "$(dirname "${BASH_SOURCE[0]}")/spec_helper.sh"

Describe "Configuration Management"
  BeforeEach "setup_test_env"
  AfterEach "cleanup_test_env"

  Describe "config-utils.sh"
    Describe "init_config_environment()"
      Context "when initializing with environment name"
        It "sets CONFIG_ENVIRONMENT"
          When call init_config_environment "test"
          The variable "CONFIG_ENVIRONMENT" should equal "test"
        End

        It "creates cache directories"
          When call init_config_environment "test"
          The directory ".cache/config" should exist
          The directory ".cache/secrets" should exist
        End
      End
    End

    Describe "load_environment_config()"
      Context "when loading valid configuration"
        Before create_test_config "test"
        It "loads configuration successfully"
          When call load_environment_config "test"
          The exit status should be success
        End

        It "exports environment variables"
          When call load_environment_config "test"
          The variable "CONFIG_ENVIRONMENT" should equal "test"
          The variable "CONFIG_TYPE" should equal "test"
        End
      End

      Context "when configuration file is missing"
        It "returns error"
          When call load_environment_config "missing"
          The exit status should be error
        End
      End
    End

    Describe "get_config_value()"
      Context "with valid configuration"
        Before create_test_config "test"
        It "retrieves configuration value"
          When call get_config_value ".environment.name" "test"
          The output should equal "test"
        End

        It "returns default value for missing key"
          When call get_config_value ".missing.key" "test" "default"
          The output should equal "default"
        End
      End
    End
  End

  Describe "config-manager.sh"
    Describe "CLI commands"
      Context "when running list command"
        It "lists available environments"
          When run ./scripts/ci/config-manager.sh list
          The output should include "development"
          The output should include "staging"
          The output should include "production"
        End
      End

      Context "when showing environment configuration"
        It "displays environment details"
          When run ./scripts/ci/config-manager.sh show development
          The output should include "development"
          The output should include "Infrastructure"
          The output should include "Application"
        End
      End

      Context "when validating configuration"
        It "validates successfully"
          When run ./scripts/ci/config-manager.sh validate development
          The output should include "validation passed"
          The exit status should be success
        End
      End
    End
  End
End

Describe "Environment Configuration Files"
  Context "development environment"
    It "has valid JSON structure"
      When run jq empty config/environments/development.json
      The exit status should be success
    End

    It "contains required fields"
      When call get_config_value ".environment.name" "development"
      The output should equal "development"
    End
  End

  Context "staging environment"
    It "has valid JSON structure"
      When run jq empty config/environments/staging.json
      The exit status should be success
    End

    It "contains staging-specific configuration"
      When call get_config_value ".environment.type" "staging"
      The output should equal "staging"
    End
  End

  Context "production environment"
    It "has valid JSON structure"
      When run jq empty config/environments/production.json
      The exit status should be success
    End

    It "contains production-specific configuration"
      When call get_config_value ".environment.type" "production"
      The output should equal "production"
    End

    It "has security configuration"
      When call get_config_value ".security.rate_limiting.enabled" "production"
      The output should equal "true"
    End
  End
End