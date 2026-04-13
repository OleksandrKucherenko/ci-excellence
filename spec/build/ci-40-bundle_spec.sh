# shellcheck shell=bash
Describe 'ci-40-bundle.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/build/ci-40-bundle.sh"

  It 'exits 0 and prints bundle messages'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should include 'Creating Bundle/Package'
    The stderr should include 'Bundling Complete'
  End
End
