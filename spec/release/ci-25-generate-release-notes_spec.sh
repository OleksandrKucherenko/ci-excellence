# shellcheck shell=bash
Describe 'ci-25-generate-release-notes.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-25-generate-release-notes.sh"

  It 'exits successfully with version arg'
    export CI_VERSION="1.0.0"
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stdout should be present
    The stderr should be present
  End

  It 'outputs release notes to stdout'
    export CI_VERSION="1.0.0"
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The output should include 'Release'
    The stderr should be present
  End

  It 'announces its title'
    export CI_VERSION="1.0.0"
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Generating Release Notes'
    The stdout should be present
  End
End
