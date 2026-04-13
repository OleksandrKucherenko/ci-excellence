# shellcheck shell=bash
Describe 'ci-20-generate-changelog.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-20-generate-changelog.sh"

  It 'exits successfully with version arg'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0"
    The status should equal 0
  End

  It 'announces its title'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0"
    The stderr should include 'Generating Changelog'
  End

  It 'reports changelog generated'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0"
    The stderr should include 'Changelog Generated'
  End
End
