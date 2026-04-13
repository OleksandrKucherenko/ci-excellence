# shellcheck shell=bash
Describe 'ci-60-release-status.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/notification/ci-60-release-status.sh"

  setup() { : > "$GITHUB_OUTPUT"; }
  Before 'setup'

  It 'announces itself'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Determining Release Status'
  End

  Describe 'all success'
    It 'sets status to success'
      export CI_VERSION=1.0.0 RESULT_PREPARE=success RESULT_PUBLISH_NPM=success RESULT_PUBLISH_GITHUB=success RESULT_PUBLISH_DOCKER=success
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'status=success'
      The contents of file "$GITHUB_OUTPUT" should include 'Release 1.0.0 Published'
      The status should equal 0
      The stderr should be present
    End
  End

  Describe 'prepare failure'
    It 'sets status to failure'
      export CI_VERSION=1.0.0 RESULT_PREPARE=failure RESULT_PUBLISH_NPM=success RESULT_PUBLISH_GITHUB=success RESULT_PUBLISH_DOCKER=success
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'status=failure'
      The contents of file "$GITHUB_OUTPUT" should include 'Release 1.0.0 Failed'
      The status should equal 0
      The stderr should be present
    End
  End

  Describe 'npm failure'
    It 'sets status to failure'
      export CI_VERSION=2.0.0 RESULT_PREPARE=success RESULT_PUBLISH_NPM=failure RESULT_PUBLISH_GITHUB=success RESULT_PUBLISH_DOCKER=success
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'status=failure'
      The contents of file "$GITHUB_OUTPUT" should include 'Release 2.0.0 Failed'
      The status should equal 0
      The stderr should be present
    End
  End

  Describe 'github failure'
    It 'sets status to failure'
      export CI_VERSION=1.0.0 RESULT_PREPARE=success RESULT_PUBLISH_NPM=success RESULT_PUBLISH_GITHUB=failure RESULT_PUBLISH_DOCKER=success
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'status=failure'
      The status should equal 0
      The stderr should be present
    End
  End

  Describe 'docker failure'
    It 'sets status to failure'
      export CI_VERSION=1.0.0 RESULT_PREPARE=success RESULT_PUBLISH_NPM=success RESULT_PUBLISH_GITHUB=success RESULT_PUBLISH_DOCKER=failure
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'status=failure'
      The status should equal 0
      The stderr should be present
    End
  End
End
