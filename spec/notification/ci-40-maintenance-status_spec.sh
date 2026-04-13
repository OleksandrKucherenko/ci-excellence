# shellcheck shell=bash
Describe 'ci-40-maintenance-status.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/notification/ci-40-maintenance-status.sh"

  setup() { : > "$GITHUB_OUTPUT"; }
  Before 'setup'

  It 'announces itself'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Determining Maintenance Status'
  End

  Describe 'security failure'
    It 'sets status to failure when security audit fails'
      export RESULT_CLEANUP=success RESULT_SYNC=success RESULT_DEPRECATION=success RESULT_SECURITY=failure RESULT_DEPENDENCY=success
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'status=failure'
      The contents of file "$GITHUB_OUTPUT" should include 'Security Audit Failed'
      The status should equal 0
      The stderr should be present
    End
  End

  Describe 'dependency success'
    It 'sets status to success when dependencies updated'
      export RESULT_CLEANUP=success RESULT_SYNC=success RESULT_DEPRECATION=success RESULT_SECURITY=success RESULT_DEPENDENCY=success
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'status=success'
      The contents of file "$GITHUB_OUTPUT" should include 'Dependencies Updated'
      The status should equal 0
      The stderr should be present
    End
  End

  Describe 'sync success'
    It 'sets status to success when files synced'
      export RESULT_CLEANUP=success RESULT_SYNC=success RESULT_DEPRECATION=success RESULT_SECURITY=success RESULT_DEPENDENCY=skipped
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'status=success'
      The contents of file "$GITHUB_OUTPUT" should include 'Files Synced'
      The status should equal 0
      The stderr should be present
    End
  End

  Describe 'default'
    It 'sets status to success with default message'
      export RESULT_CLEANUP=success RESULT_SYNC=skipped RESULT_DEPRECATION=success RESULT_SECURITY=success RESULT_DEPENDENCY=skipped
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'status=success'
      The contents of file "$GITHUB_OUTPUT" should include 'Maintenance Completed'
      The status should equal 0
      The stderr should be present
    End
  End
End
