# shellcheck shell=bash
Describe 'ci-80-deprecate-github-releases.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/maintenance/ci-80-deprecate-github-releases.sh"

  It 'exits successfully'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
  End

  It 'announces itself'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Deprecating GitHub Releases'
  End
End
