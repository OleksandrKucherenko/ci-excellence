# shellcheck shell=bash
Describe 'ci-30-summary-cleanup.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/reports/ci-30-summary-cleanup.sh"

  setup() { : > "$GITHUB_STEP_SUMMARY"; }
  Before 'setup'

  It 'exits successfully'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should be present
  End

  It 'announces itself'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Generating Cleanup Summary'
  End

  It 'writes to GITHUB_STEP_SUMMARY'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The contents of file "$GITHUB_STEP_SUMMARY" should include 'Cleanup Summary'
    The status should equal 0
    The stderr should be present
  End
End
