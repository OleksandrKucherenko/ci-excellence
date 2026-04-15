# shellcheck shell=bash
Describe 'ci-75-deprecate-npm-versions.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/maintenance/ci-75-deprecate-npm-versions.sh"

  It 'exits 0 and announces itself'
    export NODE_AUTH_TOKEN="fake-token"
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should include 'Deprecating NPM Versions'
    The stderr should include 'NPM Deprecation Complete'
  End
End
