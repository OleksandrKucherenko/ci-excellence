# shellcheck shell=bash
Describe 'ci-25-generate-release-notes.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-25-generate-release-notes.sh"

  It 'exits 0 and announces its title'
    export CI_VERSION="1.0.0"
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should include 'Generating Release Notes'
    The stderr should include 'Release Notes Generated'
  End

  It 'exits 1 when CI_VERSION is missing'
    export CI_VERSION=""
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 1
  End
End
