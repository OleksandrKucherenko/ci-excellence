# shellcheck shell=bash
Describe 'ci-30-cleanup-workflow-runs.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/maintenance/ci-30-cleanup-workflow-runs.sh"

  It 'exits successfully'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
  End

  It 'announces itself'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Cleaning Up Old Workflow Runs'
  End
End
