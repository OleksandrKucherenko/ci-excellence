# shellcheck shell=bash
Describe 'ci-20-promote-release.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/ops/ci-20-promote-release.sh"

  It 'exits 0 and includes guidance about Release Pipeline'
    When run bash "$RUN_SCRIPT" "$SCRIPT" 1.0.0
    The status should equal 0
    The stderr should include 'Release Pipeline'
  End
End
