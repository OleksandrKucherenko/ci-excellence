# shellcheck shell=bash
Describe 'ci-91-test-after-update.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/maintenance/ci-91-test-after-update.sh"

  It 'exits 0'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should be present
  End

  It 'announces its title'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Test After Update'
  End
End
