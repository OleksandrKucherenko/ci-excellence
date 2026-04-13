# shellcheck shell=bash
Describe 'ci-30-upload-assets.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-30-upload-assets.sh"

  It 'exits successfully'
    export CI_VERSION="v1.0.0"
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should be present
  End

  It 'announces its title'
    export CI_VERSION="v1.0.0"
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Uploading Release Assets'
  End

  It 'reports assets uploaded'
    export CI_VERSION="v1.0.0"
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Release Assets Uploaded'
  End
End
