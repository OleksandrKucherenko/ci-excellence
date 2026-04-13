# shellcheck shell=bash
Describe 'ci-70-summary-maintenance.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/reports/ci-70-summary-maintenance.sh"

  setup() { : > "$GITHUB_STEP_SUMMARY"; }
  Before 'setup'

  It 'exits successfully'
    When run bash "$RUN_SCRIPT" "$SCRIPT" success success success success success
    The status should equal 0
    The stderr should be present
  End

  It 'announces itself'
    When run bash "$RUN_SCRIPT" "$SCRIPT" success success success success success
    The stderr should include 'Generating Maintenance Summary'
  End

  It 'writes to GITHUB_STEP_SUMMARY'
    When run bash "$RUN_SCRIPT" "$SCRIPT" success success success success success
    The contents of file "$GITHUB_STEP_SUMMARY" should include 'Maintenance Pipeline Summary'
    The status should equal 0
    The stderr should be present
  End
End
