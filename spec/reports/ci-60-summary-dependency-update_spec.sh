# shellcheck shell=bash
Describe 'ci-60-summary-dependency-update.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/reports/ci-60-summary-dependency-update.sh"

  setup() { : > "$GITHUB_STEP_SUMMARY"; }
  Before 'setup'

  It 'exits successfully'
    export MAINT_HAS_CHANGES=false
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should be present
  End

  It 'announces itself'
    export MAINT_HAS_CHANGES=false
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Generating Dependency Update Summary'
  End

  It 'writes to GITHUB_STEP_SUMMARY'
    export MAINT_HAS_CHANGES=false
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The contents of file "$GITHUB_STEP_SUMMARY" should include 'Dependency Update Summary'
    The status should equal 0
    The stderr should be present
  End
End
