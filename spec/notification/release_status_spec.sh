# shellcheck shell=bash
Describe 'ci-60-release-status.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/notification/ci-60-release-status.sh"

  setup() { : > "$GITHUB_OUTPUT"; }
  Before 'setup'

  It 'announces itself'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0" success success success success
    The stderr should include 'Determining Release Status'
  End

  Describe 'all success'
    It 'sets status to success'
      When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0" success success success success
      The contents of file "$GITHUB_OUTPUT" should include 'status=success'
      The contents of file "$GITHUB_OUTPUT" should include 'Release 1.0.0 Published'
      The status should equal 0
    End
  End

  Describe 'prepare failure'
    It 'sets status to failure when prepare fails'
      When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0" failure success success success
      The contents of file "$GITHUB_OUTPUT" should include 'status=failure'
      The contents of file "$GITHUB_OUTPUT" should include 'Release 1.0.0 Failed'
      The status should equal 0
    End
  End

  Describe 'npm failure'
    It 'sets status to failure when npm fails'
      When run bash "$RUN_SCRIPT" "$SCRIPT" "2.0.0" success failure success success
      The contents of file "$GITHUB_OUTPUT" should include 'status=failure'
      The contents of file "$GITHUB_OUTPUT" should include 'Release 2.0.0 Failed'
      The status should equal 0
    End
  End

  Describe 'github failure'
    It 'sets status to failure when github release fails'
      When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0" success success failure success
      The contents of file "$GITHUB_OUTPUT" should include 'status=failure'
      The contents of file "$GITHUB_OUTPUT" should include 'Release 1.0.0 Failed'
      The status should equal 0
    End
  End

  Describe 'docker failure'
    It 'sets status to failure when docker fails'
      When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0" success success success failure
      The contents of file "$GITHUB_OUTPUT" should include 'status=failure'
      The contents of file "$GITHUB_OUTPUT" should include 'Release 1.0.0 Failed'
      The status should equal 0
    End
  End
End
