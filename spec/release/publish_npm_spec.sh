# shellcheck shell=bash
Describe 'ci-65-publish-npm.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-65-publish-npm.sh"

  It 'exits 1 when NODE_AUTH_TOKEN is not set'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 1
    The stderr should include 'NODE_AUTH_TOKEN is not set'
  End

  It 'announces its title'
    When run bash -c "export NODE_AUTH_TOKEN=fake-token && bash '$RUN_SCRIPT' '$SCRIPT'"
    The stderr should include 'Publishing to NPM'
  End

  It 'exits successfully when NODE_AUTH_TOKEN is set'
    When run bash -c "export NODE_AUTH_TOKEN=fake-token && bash '$RUN_SCRIPT' '$SCRIPT'"
    The status should equal 0
  End
End
