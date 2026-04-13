# shellcheck shell=bash
Describe 'ci-40-cleanup-artifacts.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/maintenance/ci-40-cleanup-artifacts.sh"

  It 'exits successfully'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
  End

  It 'announces itself'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Cleaning Up Old Artifacts'
  End
End
