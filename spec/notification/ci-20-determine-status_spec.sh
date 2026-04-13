# shellcheck shell=bash
Describe 'ci-20-determine-status.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/notification/ci-20-determine-status.sh"

  # Reset GITHUB_OUTPUT before each example
  setup() { : > "$GITHUB_OUTPUT"; }
  Before 'setup'

  Describe 'failure input'
    It 'sets status to failure'
      export RESULT_SUMMARY=failure
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'status=failure'
      The contents of file "$GITHUB_OUTPUT" should include 'Pre-Release Pipeline Failed'
      The status should equal 0
    End
  End

  Describe 'success input'
    It 'sets status to success'
      export RESULT_SUMMARY=success
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'status=success'
      The contents of file "$GITHUB_OUTPUT" should include 'Pre-Release Pipeline Passed'
      The status should equal 0
    End
  End

  Describe 'other input'
    It 'sets status to warning for cancelled'
      export RESULT_SUMMARY=cancelled
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'status=warning'
      The contents of file "$GITHUB_OUTPUT" should include 'Pre-Release Pipeline Completed with Issues'
      The status should equal 0
    End

    It 'sets status to warning for unknown'
      export RESULT_SUMMARY=unknown
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'status=warning'
      The status should equal 0
    End

    It 'sets status to warning for default (no arg)'
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'status=warning'
      The status should equal 0
    End
  End
End
