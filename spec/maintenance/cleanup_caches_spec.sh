# shellcheck shell=bash
Describe 'ci-50-cleanup-caches.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/maintenance/ci-50-cleanup-caches.sh"

  It 'exits successfully'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should be present
  End

  It 'announces itself'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Cleaning Up Old Caches'
  End
End
