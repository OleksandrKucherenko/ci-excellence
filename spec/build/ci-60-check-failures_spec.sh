# shellcheck shell=bash
Describe 'ci-60-check-failures.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/build/ci-60-check-failures.sh"

  It 'exits 0 and prints check messages'
    export RESULT_SETUP=success RESULT_COMPILE=success RESULT_LINT=success RESULT_UNIT_TESTS=success
    export RESULT_INTEGRATION_TESTS=success RESULT_E2E_TESTS=success RESULT_SECURITY_SCAN=success RESULT_BUNDLE=success
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should include 'Checking Pipeline Results'
    The stderr should include 'Pipeline Check Complete'
  End
End
