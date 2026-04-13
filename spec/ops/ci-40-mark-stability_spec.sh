# shellcheck shell=bash
Describe 'ci-40-mark-stability.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/ops/ci-40-mark-stability.sh"

  Describe 'missing arguments'
    It 'exits 1 when no arguments are provided'
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The status should equal 1
      The stderr should include 'Mark Stability'
    End
  End

  Describe 'unknown action'
    It 'exits 1 for an unknown action'
      When run bash "$RUN_SCRIPT" "$SCRIPT" bogus 1.0.0
      The status should equal 1
      The stderr should include "Unknown action"
    End
  End
End
