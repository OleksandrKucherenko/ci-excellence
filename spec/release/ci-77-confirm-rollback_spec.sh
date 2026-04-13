# shellcheck shell=bash
Describe 'ci-77-confirm-rollback.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-77-confirm-rollback.sh"

  It 'exits 0 and announces confirming rollback'
    export CI_VERSION="1.0.0"
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should include 'Confirming Rollback'
    The stderr should include 'Rollback Confirmed'
  End
End
