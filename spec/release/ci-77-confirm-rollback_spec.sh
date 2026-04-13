# shellcheck shell=bash
Describe 'ci-77-confirm-rollback.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-77-confirm-rollback.sh"

  It 'exits successfully'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0"
    The status should equal 0
    The stdout should be present
    The stderr should be present
  End

  It 'prints rollback warning to stdout'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0"
    The output should include 'WARNING: Rolling back version'
    The stderr should be present
  End

  It 'announces confirming rollback'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0"
    The stderr should include 'Confirming Rollback'
    The stdout should be present
  End
End
