# shellcheck shell=bash
Describe 'ci-10-compile.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/build/ci-10-compile.sh"

  It 'exits 0 and prints build messages'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should include 'Compiling/Building Project'
    The stderr should include 'Build Complete'
  End
End
