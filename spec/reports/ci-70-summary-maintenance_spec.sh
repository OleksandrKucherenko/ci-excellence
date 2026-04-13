# shellcheck shell=bash
Describe 'ci-70-summary-maintenance.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/reports/ci-70-summary-maintenance.sh"

  setup() { : > "$GITHUB_STEP_SUMMARY"; }
  Before 'setup'

  It 'exits successfully'
    export RESULT_CLEANUP=success RESULT_SYNC=success RESULT_DEPRECATION=success RESULT_SECURITY=success RESULT_DEPENDENCY=success
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should be present
  End

  It 'announces itself'
    export RESULT_CLEANUP=success RESULT_SYNC=success RESULT_DEPRECATION=success RESULT_SECURITY=success RESULT_DEPENDENCY=success
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Generating Maintenance Summary'
  End

  It 'writes to GITHUB_STEP_SUMMARY'
    export RESULT_CLEANUP=success RESULT_SYNC=success RESULT_DEPRECATION=success RESULT_SECURITY=success RESULT_DEPENDENCY=success
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The contents of file "$GITHUB_STEP_SUMMARY" should include 'Maintenance Pipeline Summary'
    The status should equal 0
    The stderr should be present
  End
End
