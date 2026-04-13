# shellcheck shell=bash
Describe 'ci-20-determine-status.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/notification/ci-20-determine-status.sh"

  # Reset GITHUB_OUTPUT before each example
  setup() { : > "$GITHUB_OUTPUT"; }
  Before 'setup'

  Describe 'failure input'
    It 'sets status to failure'
      When run bash "$RUN_SCRIPT" "$SCRIPT" failure
      The contents of file "$GITHUB_OUTPUT" should include 'status=failure'
      The contents of file "$GITHUB_OUTPUT" should include 'Pre-Release Pipeline Failed'
      The status should equal 0
    End
  End

  Describe 'success input'
    It 'sets status to success'
      When run bash "$RUN_SCRIPT" "$SCRIPT" success
      The contents of file "$GITHUB_OUTPUT" should include 'status=success'
      The contents of file "$GITHUB_OUTPUT" should include 'Pre-Release Pipeline Passed'
      The status should equal 0
    End
  End

  Describe 'other input'
    It 'sets status to warning for cancelled'
      When run bash "$RUN_SCRIPT" "$SCRIPT" cancelled
      The contents of file "$GITHUB_OUTPUT" should include 'status=warning'
      The contents of file "$GITHUB_OUTPUT" should include 'Pre-Release Pipeline Completed with Issues'
      The status should equal 0
    End

    It 'sets status to warning for unknown'
      When run bash "$RUN_SCRIPT" "$SCRIPT" unknown
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
