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
    It 'sets status to warning for rollback completed'
      When run bash "$RUN_SCRIPT" "$SCRIPT" unknown unknown unknown success
      The contents of file "$GITHUB_OUTPUT" should include 'status=warning'
      The contents of file "$GITHUB_OUTPUT" should include 'Rollback Completed'
      The status should equal 0
    End
  End

  Describe 'tag stable success'
    It 'sets status to success for version tagged as stable'
      When run bash "$RUN_SCRIPT" "$SCRIPT" unknown success unknown unknown
      The contents of file "$GITHUB_OUTPUT" should include 'status=success'
      The contents of file "$GITHUB_OUTPUT" should include 'Version Tagged as Stable'
      The status should equal 0
    End
  End

  Describe 'verify success'
    It 'sets status to success for deployment verified'
      When run bash "$RUN_SCRIPT" "$SCRIPT" success unknown unknown unknown
      The contents of file "$GITHUB_OUTPUT" should include 'status=success'
      The contents of file "$GITHUB_OUTPUT" should include 'Deployment Verified'
      The status should equal 0
    End
  End

  Describe 'rollback failure'
    It 'sets status to failure for rollback failed'
      When run bash "$RUN_SCRIPT" "$SCRIPT" unknown unknown unknown failure
      The contents of file "$GITHUB_OUTPUT" should include 'status=failure'
      The contents of file "$GITHUB_OUTPUT" should include 'Rollback Failed'
      The status should equal 0
    End
  End

  Describe 'default'
    It 'sets status to info for generic completion'
      When run bash "$RUN_SCRIPT" "$SCRIPT" unknown unknown unknown unknown
      The contents of file "$GITHUB_OUTPUT" should include 'status=info'
      The contents of file "$GITHUB_OUTPUT" should include 'Post-Release Actions Completed'
      The status should equal 0
    End
  End
End
