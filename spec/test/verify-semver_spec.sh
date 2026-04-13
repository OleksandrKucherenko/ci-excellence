# shellcheck shell=bash
Describe 'verify-semver.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/test/verify-semver.sh"

  It 'exits 0 and verifies semver library'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The output should include 'e-bash semver library verified successfully'
    The stderr should be present
  End
End
