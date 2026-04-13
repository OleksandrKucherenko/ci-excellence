# shellcheck shell=bash
Describe 'ci-25-generate-release-notes.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-25-generate-release-notes.sh"

  It 'exits successfully with version arg'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0"
    The status should equal 0
  End

  It 'outputs release notes to stdout'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0"
    The output should include 'Release'
  End

  It 'announces its title'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0"
    The stderr should include 'Generating Release Notes'
  End
End
