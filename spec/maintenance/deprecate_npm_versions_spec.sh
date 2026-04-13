# shellcheck shell=bash
Describe 'ci-75-deprecate-npm-versions.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/maintenance/ci-75-deprecate-npm-versions.sh"

  Describe 'without NODE_AUTH_TOKEN'
    It 'exits with error when NODE_AUTH_TOKEN is not set'
      export NODE_AUTH_TOKEN=""
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The status should equal 1
      The stderr should include 'NODE_AUTH_TOKEN is not set'
    End
  End

  Describe 'with NODE_AUTH_TOKEN'
    It 'exits successfully'
      export NODE_AUTH_TOKEN="fake-token"
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The status should equal 0
      The stderr should be present
    End

    It 'announces itself'
      export NODE_AUTH_TOKEN="fake-token"
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The stderr should include 'Deprecating NPM Versions'
    End
  End
End
