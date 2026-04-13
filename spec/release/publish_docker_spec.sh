# shellcheck shell=bash
Describe 'ci-80-publish-docker.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-80-publish-docker.sh"

  It 'exits successfully'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0"
    The status should equal 0
  End

  It 'announces its title'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0"
    The stderr should include 'Publishing Docker Image'
  End

  It 'reports publishing complete'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0"
    The stderr should include 'Docker Publishing Complete'
  End
End
