# shellcheck shell=bash
Describe 'ci-30-upload-assets.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-30-upload-assets.sh"

  It 'exits successfully'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "v1.0.0"
    The status should equal 0
  End

  It 'announces its title'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "v1.0.0"
    The stderr should include 'Uploading Release Assets'
  End

  It 'reports assets uploaded'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "v1.0.0"
    The stderr should include 'Release Assets Uploaded'
  End
End
