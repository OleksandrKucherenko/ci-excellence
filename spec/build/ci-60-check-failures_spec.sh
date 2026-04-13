# shellcheck shell=bash
Describe 'ci-60-check-failures.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/build/ci-60-check-failures.sh"

  Describe 'all success results'
    setup() {
      export RESULT_SETUP=success RESULT_COMPILE=success RESULT_LINT=success RESULT_UNIT_TESTS=success
      export RESULT_INTEGRATION_TESTS=success RESULT_E2E_TESTS=success RESULT_SECURITY_SCAN=success RESULT_BUNDLE=success
    }
    Before 'setup'

    It 'exits 0 when every job succeeded'
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The status should equal 0
    End
  End

  Describe 'one failure result'
    It 'exits 1 when SETUP_RESULT is failure'
      export RESULT_SETUP=failure RESULT_COMPILE=success RESULT_LINT=success RESULT_UNIT_TESTS=success
      export RESULT_INTEGRATION_TESTS=success RESULT_E2E_TESTS=success RESULT_SECURITY_SCAN=success RESULT_BUNDLE=success
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The output should include 'One or more pipeline jobs failed'
      The status should equal 1
    End

    It 'exits 1 when LINT_RESULT is failure'
      export RESULT_SETUP=success RESULT_COMPILE=success RESULT_LINT=failure RESULT_UNIT_TESTS=success
      export RESULT_INTEGRATION_TESTS=success RESULT_E2E_TESTS=success RESULT_SECURITY_SCAN=success RESULT_BUNDLE=success
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The output should include 'One or more pipeline jobs failed'
      The status should equal 1
    End

    It 'exits 1 when BUNDLE_RESULT (last arg) is failure'
      export RESULT_SETUP=success RESULT_COMPILE=success RESULT_LINT=success RESULT_UNIT_TESTS=success
      export RESULT_INTEGRATION_TESTS=success RESULT_E2E_TESTS=success RESULT_SECURITY_SCAN=success RESULT_BUNDLE=failure
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The output should include 'One or more pipeline jobs failed'
      The status should equal 1
    End
  End

  Describe 'skipped results (not failure)'
    It 'exits 0 when results contain skipped'
      export RESULT_SETUP=success RESULT_COMPILE=skipped RESULT_LINT=success RESULT_UNIT_TESTS=skipped
      export RESULT_INTEGRATION_TESTS=success RESULT_E2E_TESTS=success RESULT_SECURITY_SCAN=success RESULT_BUNDLE=success
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The status should equal 0
    End

    It 'exits 0 when results contain cancelled'
      export RESULT_SETUP=success RESULT_COMPILE=cancelled RESULT_LINT=success RESULT_UNIT_TESTS=success
      export RESULT_INTEGRATION_TESTS=success RESULT_E2E_TESTS=success RESULT_SECURITY_SCAN=success RESULT_BUNDLE=success
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The status should equal 0
    End
  End
End
