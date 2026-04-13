# shellcheck shell=bash
Describe 'ci-20-summary-sync.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/reports/ci-20-summary-sync.sh"

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
    The stderr should include 'Generating Sync Summary'
  End

  It 'writes to GITHUB_STEP_SUMMARY'
    export MAINT_HAS_CHANGES=false
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The contents of file "$GITHUB_STEP_SUMMARY" should include 'File Sync Summary'
    The status should equal 0
    The stderr should be present
  End

  It 'reports files in sync when no changes'
    export MAINT_HAS_CHANGES=false
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The contents of file "$GITHUB_STEP_SUMMARY" should include 'All files are in sync'
    The status should equal 0
    The stderr should be present
  End

  It 'reports PR created when changes exist'
    export MAINT_HAS_CHANGES=true
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The contents of file "$GITHUB_STEP_SUMMARY" should include 'PR created for review'
    The status should equal 0
    The stderr should be present
  End
End
