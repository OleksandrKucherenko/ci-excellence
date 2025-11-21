#!/usr/bin/env bash
# ShellSpec tests for CI Script Testability Framework
# Tests hierarchical testability control and all CI_TEST_* modes

set -euo pipefail

# Test data and helpers
setup_test_environment() {
  # Create test directory
  mkdir -p "/tmp/testability-test"
  cd "/tmp/testability-test"

  # Create test script with full testability support
  cat > test-ci-script.sh << 'EOF'
#!/bin/bash
# Test CI Script with Full Testability Support
# Demonstrates hierarchical testability control

set -euo pipefail

# Source common utilities (will be mocked)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../scripts/lib/common.sh" 2>/dev/null || true

# Script configuration
readonly TEST_SCRIPT_VERSION="1.0.0"

# Testability functions
get_script_behavior() {
  local script_name="${1:-test_ci_script}"
  local default_behavior="${2:-EXECUTE}"

  # Priority order: PIPELINE_SCRIPT_MODE > SCRIPT_MODE > CI_TEST_MODE > default
  local behavior

  # 1. Pipeline-specific override (highest priority)
  if [[ -n "${PIPELINE_TEST_SCRIPT_MODE:-}" ]]; then
    behavior="$PIPELINE_TEST_SCRIPT_MODE"
    log_debug "Using PIPELINE_TEST_SCRIPT_MODE: $behavior"
  # 2. Script-specific override
  elif [[ -n "${TEST_CI_SCRIPT_MODE:-}" ]]; then
    behavior="$TEST_CI_SCRIPT_MODE"
    log_debug "Using TEST_CI_SCRIPT_MODE: $behavior"
  # 3. Global testability mode
  elif [[ -n "${CI_TEST_MODE:-}" ]]; then
    behavior="$CI_TEST_MODE"
    log_debug "Using CI_TEST_MODE: $behavior"
  # 4. Default behavior
  else
    behavior="$default_behavior"
    log_debug "Using default behavior: $behavior"
  fi

  echo "$behavior"
}

# Mock action function
perform_test_action() {
  local action="${1:-default_action}"

  case "$action" in
    "compile")
      echo "Compiling project..."
      echo "Build artifacts created"
      ;;
    "test")
      echo "Running tests..."
      echo "All tests passed"
      ;;
    "deploy")
      echo "Deploying to production..."
      echo "Deployment successful"
      ;;
    *)
      echo "Performing default action: $action"
      ;;
  esac
}

# Main execution function
main() {
  local action="${1:-default_action}"
  local behavior
  behavior=$(get_script_behavior)

  echo "Test Script v$TEST_SCRIPT_VERSION"
  echo "Action: $action"
  echo "Behavior Mode: $behavior"

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would perform action '$action'"
      perform_test_action "$action" | sed 's/^/  Would: /'
      return 0
      ;;
    "PASS")
      echo "✅ PASS MODE: Simulated successful execution"
      return 0
      ;;
    "FAIL")
      echo "❌ FAIL MODE: Simulated execution failure"
      return 1
      ;;
    "SKIP")
      echo "⏭️ SKIP MODE: Execution skipped"
      return 0
      ;;
    "TIMEOUT")
      echo "⏰ TIMEOUT MODE: Simulating execution timeout"
      sleep 2  # Short sleep for testing
      return 124  # TIMEOUT exit code
      ;;
    "EXECUTE")
      echo "🚀 EXECUTE: Performing actual action"
      perform_test_action "$action"
      return 0
      ;;
    *)
      echo "❓ UNKNOWN MODE: $behavior"
      return 1
      ;;
  esac
}

# CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
EOF

  chmod +x test-ci-script.sh
}

# Cleanup test environment
cleanup_test_environment() {
  cd - >/dev/null
  rm -rf "/tmp/testability-test"
}

# Mock common utilities
mock_common_utilities() {
  # Create mock common.sh
  mkdir -p scripts/lib
  cat > scripts/lib/common.sh << 'EOF'
#!/bin/bash
# Mock common utilities for testing

log_debug() {
  echo "[DEBUG] $*" >&2
}

log_info() {
  echo "[INFO] $*"
}

log_success() {
  echo "[SUCCESS] $*"
}

log_error() {
  echo "[ERROR] $*" >&2
}

log_warn() {
  echo "[WARN] $*" >&2
}
EOF
}

Describe "Testability Framework"
  BeforeEach "setup_test_environment"
  BeforeEach "mock_common_utilities"
  AfterEach "cleanup_test_environment"

  Describe "Default behavior (EXECUTE mode)"
    Context "when no testability variables are set"
      It "should execute with default EXECUTE behavior"
        When run ./test-ci-script.sh compile
        The status should be success
        The output should include "Behavior Mode: EXECUTE"
        The output should include "🚀 EXECUTE: Performing actual action"
        The output should include "Compiling project..."
      End

      It "should support different actions"
        When run ./test-ci-script.sh test
        The status should be success
        The output should include "Running tests..."
        The output should include "All tests passed"
      End
    End

    Context "when default behavior is overridden"
      It "should use the provided default behavior"
        When run ./test-ci-script.sh deploy
        The status should be success
        The output should include "Performing default action: deploy"
      End
    End
  End

  Describe "Global CI_TEST_MODE"
    Context "when CI_TEST_MODE is set"
      BeforeEach "export CI_TEST_MODE=DRY_RUN"

      It "should use DRY_RUN behavior"
        When run ./test-ci-script.sh compile
        The status should be success
        The output should include "Behavior Mode: DRY_RUN"
        The output should include "🔍 DRY RUN: Would perform action 'compile'"
        The output should include "Would: Compiling project..."
        The output should not include "Compiling project..."
      End

      It "should respect PASS mode"
        BeforeEach "export CI_TEST_MODE=PASS"

        When run ./test-ci-script.sh test
        The status should be success
        The output should include "Behavior Mode: PASS"
        The output should include "✅ PASS MODE: Simulated successful execution"
        The output should not include "Running tests..."
      End

      It "should respect FAIL mode"
        BeforeEach "export CI_TEST_MODE=FAIL"

        When run ./test-ci-script.sh deploy
        The status should be failure
        The output should include "Behavior Mode: FAIL"
        The output should include "❌ FAIL MODE: Simulated execution failure"
        The output should not include "Deploying to production..."
      End

      It "should respect SKIP mode"
        BeforeEach "export CI_TEST_MODE=SKIP"

        When run ./test-ci-script.sh compile
        The status should be success
        The output should include "Behavior Mode: SKIP"
        The output should include "⏭️ SKIP MODE: Execution skipped"
        The output should not include "Compiling project..."
      End

      It "should respect TIMEOUT mode"
        BeforeEach "export CI_TEST_MODE=TIMEOUT"

        When run ./test-ci-script.sh test
        The status should equal 124  # TIMEOUT exit code
        The output should include "Behavior Mode: TIMEOUT"
        The output should include "⏰ TIMEOUT MODE: Simulating execution timeout"
      End
    End
  End

  Describe "Script-specific mode override"
    Context "when script-specific mode is set"
      BeforeEach "export TEST_CI_SCRIPT_MODE=PASS"

      It "should use script-specific mode over global mode"
        BeforeEach "export CI_TEST_MODE=FAIL"

        When run ./test-ci-script.sh compile
        The status should be success
        The output should include "Behavior Mode: PASS"
        The output should include "Using TEST_CI_SCRIPT_MODE: PASS"
      End

      It "should use script-specific mode over default"
        When run ./test-ci-script.sh test
        The status should be success
        The output should include "Behavior Mode: PASS"
        The output should include "Using TEST_CI_SCRIPT_MODE: PASS"
      End
    End
  End

  Describe "Pipeline-specific mode override (highest priority)"
    Context "when pipeline-specific mode is set"
      BeforeEach "export PIPELINE_TEST_SCRIPT_MODE=DRY_RUN"

      It "should use pipeline mode over script-specific mode"
        BeforeEach "export TEST_CI_SCRIPT_MODE=FAIL"

        When run ./test-ci-script.sh compile
        The status should be success
        The output should include "Behavior Mode: DRY_RUN"
        The output should include "Using PIPELINE_TEST_SCRIPT_MODE: DRY_RUN"
        The output should include "Would: Compiling project..."
        The output should not include "Compiling project..."
      End

      It "should use pipeline mode over global mode"
        BeforeEach "export CI_TEST_MODE=EXECUTE"

        When run ./test-ci-script.sh test
        The status should be success
        The output should include "Behavior Mode: DRY_RUN"
        The output should include "Using PIPELINE_TEST_SCRIPT_MODE: DRY_RUN"
        The output should not include "Running tests..."
      End

      It "should use pipeline mode as highest priority"
        BeforeEach "export CI_TEST_MODE=FAIL"
        BeforeEach "export TEST_CI_SCRIPT_MODE=SKIP"

        When run ./test-ci-script.sh deploy
        The status should be success
        The output should include "Behavior Mode: DRY_RUN"
        The output should include "Using PIPELINE_TEST_SCRIPT_MODE: DRY_RUN"
      End
    End
  End

  Describe "Priority hierarchy validation"
    Context "when all modes are set"
      BeforeEach "export CI_TEST_MODE=FAIL"
      BeforeEach "export TEST_CI_SCRIPT_MODE=SKIP"
      BeforeEach "export PIPELINE_TEST_SCRIPT_MODE=PASS"

      It "should use pipeline mode (highest priority)"
        When run ./test-ci-script.sh compile
        The status should be success
        The output should include "Using PIPELINE_TEST_SCRIPT_MODE: PASS"
        The output should include "Behavior Mode: PASS"
      End
    End

    Context "when script-specific and global modes are set"
      BeforeEach "export CI_TEST_MODE=FAIL"
      BeforeEach "export TEST_CI_SCRIPT_MODE=DRY_RUN"

      It "should use script-specific mode (middle priority)"
        When run ./test-ci-script.sh test
        The status should be success
        The output should include "Using TEST_CI_SCRIPT_MODE: DRY_RUN"
        The output should include "Behavior Mode: DRY_RUN"
      End
    End
  End

  Describe "Debug logging"
    Context "when executing with debug logging"
      It "should log which mode source was used"
        When run ./test-ci-script.sh compile 2>&1
        The stderr should include "Using default behavior: EXECUTE"
      End

      It "should log global mode usage"
        BeforeEach "export CI_TEST_MODE=DRY_RUN"

        When run ./test-ci-script.sh test 2>&1
        The stderr should include "Using CI_TEST_MODE: DRY_RUN"
      End

      It "should log script-specific mode usage"
        BeforeEach "export TEST_CI_SCRIPT_MODE=PASS"

        When run ./test-ci-script.sh deploy 2>&1
        The stderr should include "Using TEST_CI_SCRIPT_MODE: PASS"
      End

      It "should log pipeline mode usage"
        BeforeEach "export PIPELINE_TEST_SCRIPT_MODE=FAIL"

        When run ./test-ci-script.sh compile 2>&1
        The stderr should include "Using PIPELINE_TEST_SCRIPT_MODE: FAIL"
      End
    End
  End

  Describe "Error handling"
    Context "when unknown mode is specified"
      It "should handle unknown behavior gracefully"
        BeforeEach "export CI_TEST_MODE=UNKNOWN"

        When run ./test-ci-script.sh test
        The status should be failure
        The output should include "Behavior Mode: UNKNOWN"
        The output should include "❓ UNKNOWN MODE: UNKNOWN"
      End
    End

    Context "when script execution fails"
      It "should propagate script failures"
        BeforeEach "export CI_TEST_MODE=EXECUTE"

        # Create a script that fails
        cat > failing-script.sh << 'EOF'
#!/bin/bash
set -euo pipefail
echo "This script will fail"
exit 1
EOF
        chmod +x failing-script.sh

        When run ./failing-script.sh
        The status should be failure
      End
    End
  End

  Describe "Mode switching scenarios"
    Context "when testing mode switching"
      It "should switch between different modes correctly"
        # Test EXECUTE → DRY_RUN
        When run env CI_TEST_MODE=EXECUTE ./test-ci-script.sh compile
        The output should include "🚀 EXECUTE: Performing actual action"

        When run env CI_TEST_MODE=DRY_RUN ./test-ci-script.sh compile
        The output should include "🔍 DRY RUN: Would perform action"

        # Test DRY_RUN → PASS
        When run env CI_TEST_MODE=PASS ./test-ci-script.sh test
        The output should include "✅ PASS MODE: Simulated successful execution"

        # Test PASS → FAIL
        When run env CI_TEST_MODE=FAIL ./test-ci-script.sh deploy
        The status should be failure
        The output should include "❌ FAIL MODE: Simulated execution failure"
      End
    End
  End
End