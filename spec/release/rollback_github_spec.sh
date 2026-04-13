# shellcheck shell=bash
Describe 'ci-40-rollback-github.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-40-rollback-github.sh"

  It 'exits successfully'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0"
    The status should equal 0
    The stderr should be present
  End

  It 'announces its title'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0"
    The stderr should include 'Rolling Back GitHub Release'
  End

  It 'reports rollback complete'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0"
    The stderr should include 'GitHub Rollback Complete'
  End
End
