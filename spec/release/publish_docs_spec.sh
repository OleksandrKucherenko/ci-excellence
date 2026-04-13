# shellcheck shell=bash
Describe 'ci-55-publish-docs.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-55-publish-docs.sh"

  It 'exits successfully'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
  End

  It 'announces its title'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Publishing Documentation'
  End

  It 'reports publishing complete'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Documentation Publishing Complete'
  End
End
