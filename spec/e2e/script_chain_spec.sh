# shellcheck shell=bash
# E2E tests for env var propagation through script-to-script calls.

Describe 'Script chain env var propagation'

  Describe 'ci-27 -> ci-25 chain (release notes)'
    It 'passes CI_VERSION through to child script'
      export CI_VERSION="3.0.0"
      export HOOKS_DIR="/tmp/no-hooks-$$"
      When run bash "$RUN_SCRIPT" "$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-27-write-release-notes-output.sh"
      The stderr should include 'Writing Release Notes Output'
      The status should equal 0
    End
  End

  Describe 'ci-66 -> ci-65 chain (npm publish)'
    It 'sets CI_NPM_TAG based on CI_IS_PRERELEASE and calls ci-65'
      export CI_IS_PRERELEASE="true"
      export HOOKS_DIR="/tmp/no-hooks-$$"
      When run bash "$RUN_SCRIPT" "$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-66-publish-npm-release.sh"
      The stderr should include 'NPM Release'
      The status should equal 0
    End
  End
End
