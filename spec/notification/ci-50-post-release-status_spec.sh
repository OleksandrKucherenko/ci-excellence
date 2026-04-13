# shellcheck shell=bash
Describe 'ci-50-post-release-status.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/notification/ci-50-post-release-status.sh"

  setup() { : > "$GITHUB_OUTPUT"; }
  Before 'setup'

  It 'announces itself'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Determining Post-Release Status'
  End

  Describe 'rollback success'
    It 'sets status to warning'
      export RESULT_VERIFY=success RESULT_TAG_STABLE=skipped RESULT_TAG_UNSTABLE=skipped RESULT_ROLLBACK=success
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'status=warning'
      The contents of file "$GITHUB_OUTPUT" should include 'Rollback Completed'
      The status should equal 0
      The stderr should be present
    End
  End

  Describe 'tag stable success'
    It 'sets status to success with stable tag message'
      export RESULT_VERIFY=success RESULT_TAG_STABLE=success RESULT_TAG_UNSTABLE=skipped RESULT_ROLLBACK=skipped
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'status=success'
      The contents of file "$GITHUB_OUTPUT" should include 'Version Tagged as Stable'
      The status should equal 0
      The stderr should be present
    End
  End

  Describe 'verify success only'
    It 'sets status to success with verify message'
      export RESULT_VERIFY=success RESULT_TAG_STABLE=skipped RESULT_TAG_UNSTABLE=skipped RESULT_ROLLBACK=skipped
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'status=success'
      The contents of file "$GITHUB_OUTPUT" should include 'Deployment Verified'
      The status should equal 0
      The stderr should be present
    End
  End

  Describe 'rollback failure'
    It 'sets status to failure'
      export RESULT_VERIFY=skipped RESULT_TAG_STABLE=skipped RESULT_TAG_UNSTABLE=skipped RESULT_ROLLBACK=failure
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'status=failure'
      The contents of file "$GITHUB_OUTPUT" should include 'Rollback Failed'
      The status should equal 0
      The stderr should be present
    End
  End

  Describe 'default'
    It 'sets status to info'
      export RESULT_VERIFY=skipped RESULT_TAG_STABLE=skipped RESULT_TAG_UNSTABLE=skipped RESULT_ROLLBACK=skipped
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'status=info'
      The contents of file "$GITHUB_OUTPUT" should include 'Post-Release Actions Completed'
      The status should equal 0
      The stderr should be present
    End
  End
End
