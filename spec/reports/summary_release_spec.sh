# shellcheck shell=bash
Describe 'ci-95-summary-release.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/reports/ci-95-summary-release.sh"

  setup() {
    : > "$GITHUB_STEP_SUMMARY"
    export GITHUB_SHA="abc1234567890"
  }
  Before 'setup'

  It 'exits successfully'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0" false success success success success
    The status should equal 0
  End

  It 'announces itself'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0" false success success success success
    The stderr should include 'Generating Release Summary'
  End

  It 'writes to GITHUB_STEP_SUMMARY'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0" false success success success success
    The contents of file "$GITHUB_STEP_SUMMARY" should include 'Release Summary'
    The status should equal 0
  End
End
