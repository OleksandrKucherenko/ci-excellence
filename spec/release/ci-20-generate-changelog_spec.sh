# shellcheck shell=bash
Describe 'ci-20-generate-changelog.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-20-generate-changelog.sh"

  It 'exits successfully with version arg'
    export CI_VERSION="1.0.0"
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should be present
  End

  It 'announces its title'
    export CI_VERSION="1.0.0"
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Generating Changelog'
  End

  It 'reports changelog generated'
    export CI_VERSION="1.0.0"
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Changelog Generated'
  End
End
