# shellcheck shell=bash
Describe 'ci-08-create-tag.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-08-create-tag.sh"

  It 'exits 1 when no version argument is provided'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 1
    The stderr should include 'Create Tag'
  End
End
