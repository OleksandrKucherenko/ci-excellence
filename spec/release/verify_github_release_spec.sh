# shellcheck shell=bash
Describe 'ci-35-verify-github-release.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-35-verify-github-release.sh"

  It 'exits successfully'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0"
    The status should equal 0
  End

  It 'announces its title'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0"
    The stderr should include 'Verifying GitHub Release'
  End

  It 'reports verification complete'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0"
    The stderr should include 'GitHub Release Verification Complete'
  End
End
