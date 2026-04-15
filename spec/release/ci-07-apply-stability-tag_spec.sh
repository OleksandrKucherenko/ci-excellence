# shellcheck shell=bash
Describe 'ci-07-apply-stability-tag.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-07-apply-stability-tag.sh"

  It 'exits 0 and prints stability tag messages'
    export CI_STABILITY_TAG=stable CI_VERSION=1.0.0
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should include 'Applying Stability Tag'
    The stderr should include 'Stability Tag Applied'
  End
End
