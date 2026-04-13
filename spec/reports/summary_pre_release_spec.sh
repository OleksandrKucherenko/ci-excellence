# shellcheck shell=bash
Describe 'ci-10-summary-pre-release.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/reports/ci-10-summary-pre-release.sh"

  setup() { : > "$GITHUB_STEP_SUMMARY"; }
  Before 'setup'

  It 'exits successfully'
    When run bash "$RUN_SCRIPT" "$SCRIPT" success success success success success success success success
    The status should equal 0
  End

  It 'announces itself'
    When run bash "$RUN_SCRIPT" "$SCRIPT" success success success success success success success success
    The stderr should include 'Generating Pre-Release Summary'
  End

  It 'writes to GITHUB_STEP_SUMMARY'
    When run bash "$RUN_SCRIPT" "$SCRIPT" success success success success success success success success
    The contents of file "$GITHUB_STEP_SUMMARY" should include 'Pre-Release Pipeline Summary'
    The status should equal 0
  End
End
