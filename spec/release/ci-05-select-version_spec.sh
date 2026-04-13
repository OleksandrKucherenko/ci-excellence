# shellcheck shell=bash
Describe 'ci-05-select-version.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-05-select-version.sh"

  # Reset GITHUB_OUTPUT before each example
  setup() { : > "$GITHUB_OUTPUT"; }
  Before 'setup'

  Describe 'release event with tag'
    It 'outputs the release tag as version'
      export CI_EVENT_NAME=release CI_RELEASE_TAG=v2.1.0 CI_VERSION=""
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'version=v2.1.0'
      The status should equal 0
    End
  End

  Describe 'manual dispatch with input version'
    It 'outputs the input version when event is not release'
      export CI_EVENT_NAME=workflow_dispatch CI_RELEASE_TAG="" CI_VERSION=3.0.0-beta.1
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'version=3.0.0-beta.1'
      The status should equal 0
    End

    It 'prefers release tag over input version when event is release'
      export CI_EVENT_NAME=release CI_RELEASE_TAG=v1.5.0 CI_VERSION=9.9.9
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'version=v1.5.0'
      The status should equal 0
    End
  End

  Describe 'missing version'
    It 'exits 1 when no version is provided'
      export CI_EVENT_NAME=workflow_dispatch CI_RELEASE_TAG="" CI_VERSION=""
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The status should equal 1
      The stderr should be present
    End

    It 'exits 1 when all arguments are empty'
      export CI_EVENT_NAME="" CI_RELEASE_TAG="" CI_VERSION=""
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The status should equal 1
      The stderr should be present
    End
  End
End
