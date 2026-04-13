# shellcheck shell=bash
Describe 'ci-05-select-version.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-05-select-version.sh"

  # Reset GITHUB_OUTPUT before each example
  setup() { : > "$GITHUB_OUTPUT"; }
  Before 'setup'

  Describe 'release event with tag'
    It 'outputs the release tag as version'
      When run bash "$RUN_SCRIPT" "$SCRIPT" release v2.1.0 ""
      The contents of file "$GITHUB_OUTPUT" should include 'version=v2.1.0'
      The status should equal 0
    End
  End

  Describe 'manual dispatch with input version'
    It 'outputs the input version when event is not release'
      When run bash "$RUN_SCRIPT" "$SCRIPT" workflow_dispatch "" 3.0.0-beta.1
      The contents of file "$GITHUB_OUTPUT" should include 'version=3.0.0-beta.1'
      The status should equal 0
    End

    It 'prefers release tag over input version when event is release'
      When run bash "$RUN_SCRIPT" "$SCRIPT" release v1.5.0 9.9.9
      The contents of file "$GITHUB_OUTPUT" should include 'version=v1.5.0'
      The status should equal 0
    End
  End

  Describe 'missing version'
    It 'exits 1 when no version is provided'
      When run bash "$RUN_SCRIPT" "$SCRIPT" workflow_dispatch "" ""
      The status should equal 1
      The stderr should be present
    End

    It 'exits 1 when all arguments are empty'
      When run bash "$RUN_SCRIPT" "$SCRIPT" "" "" ""
      The status should equal 1
      The stderr should be present
    End
  End
End
