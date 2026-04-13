# shellcheck shell=bash
Describe 'ci-75-deprecate-npm-versions.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/maintenance/ci-75-deprecate-npm-versions.sh"

  Describe 'with NODE_AUTH_TOKEN set'
    It 'exits successfully'
      export NODE_AUTH_TOKEN="fake-token"
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The status should equal 0
    End

    It 'announces itself'
      export NODE_AUTH_TOKEN="fake-token"
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The stderr should include 'Deprecating NPM Versions'
    End
  End

  Describe 'without NODE_AUTH_TOKEN'
    It 'exits with error when NODE_AUTH_TOKEN is not set'
      unset NODE_AUTH_TOKEN 2>/dev/null || true
      export NODE_AUTH_TOKEN=""
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The status should equal 1
    End
  End
End
