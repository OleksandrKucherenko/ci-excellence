# shellcheck shell=bash
Describe 'ci-60-summary-dependency-update.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/reports/ci-60-summary-dependency-update.sh"

  setup() { : > "$GITHUB_STEP_SUMMARY"; }
  Before 'setup'

  It 'exits successfully'
    When run bash "$RUN_SCRIPT" "$SCRIPT" false
    The status should equal 0
  End

  It 'announces itself'
    When run bash "$RUN_SCRIPT" "$SCRIPT" false
    The stderr should include 'Generating Dependency Update Summary'
  End

  It 'writes to GITHUB_STEP_SUMMARY'
    When run bash "$RUN_SCRIPT" "$SCRIPT" false
    The contents of file "$GITHUB_STEP_SUMMARY" should include 'Dependency Update Summary'
    The status should equal 0
  End
End
