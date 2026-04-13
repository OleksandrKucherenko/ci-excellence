# shellcheck shell=bash
Describe 'ci-10-summary-pre-release.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/reports/ci-10-summary-pre-release.sh"

  setup() { : > "$GITHUB_STEP_SUMMARY"; }
  Before 'setup'

  It 'exits successfully'
    export RESULT_SETUP=success RESULT_COMPILE=success RESULT_LINT=success RESULT_UNIT_TESTS=success
    export RESULT_INTEGRATION_TESTS=success RESULT_E2E_TESTS=success RESULT_SECURITY_SCAN=success RESULT_BUNDLE=success
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should be present
  End

  It 'announces itself'
    export RESULT_SETUP=success RESULT_COMPILE=success RESULT_LINT=success RESULT_UNIT_TESTS=success
    export RESULT_INTEGRATION_TESTS=success RESULT_E2E_TESTS=success RESULT_SECURITY_SCAN=success RESULT_BUNDLE=success
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Generating Pre-Release Summary'
  End

  It 'writes to GITHUB_STEP_SUMMARY'
    export RESULT_SETUP=success RESULT_COMPILE=success RESULT_LINT=success RESULT_UNIT_TESTS=success
    export RESULT_INTEGRATION_TESTS=success RESULT_E2E_TESTS=success RESULT_SECURITY_SCAN=success RESULT_BUNDLE=success
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The contents of file "$GITHUB_STEP_SUMMARY" should include 'Pre-Release Pipeline Summary'
    The status should equal 0
    The stderr should be present
  End
End
