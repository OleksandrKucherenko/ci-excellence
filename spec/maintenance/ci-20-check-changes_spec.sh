# shellcheck shell=bash
Describe 'ci-20-check-changes.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/maintenance/ci-20-check-changes.sh"

  It 'exits 0 and announces itself'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should include 'Checking for Changes'
    The stderr should include 'Change Check Complete'
  End
End
