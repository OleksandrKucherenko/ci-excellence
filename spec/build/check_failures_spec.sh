#!/usr/bin/env bash
# Tests for scripts/ci/build/ci-60-check-failures.sh

Describe 'ci-60-check-failures.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/build/ci-60-check-failures.sh"

  Describe 'all success results'
    It 'exits 0 when every job succeeded'
      When run bash "$SCRIPT" success success success success success success success success
      The status should equal 0
    End
  End

  Describe 'one failure result'
    It 'exits 1 when SETUP_RESULT is failure'
      When run bash "$SCRIPT" failure success success success success success success success
      The output should include 'One or more pipeline jobs failed'
      The status should equal 1
    End

    It 'exits 1 when LINT_RESULT is failure'
      When run bash "$SCRIPT" success success failure success success success success success
      The output should include 'One or more pipeline jobs failed'
      The status should equal 1
    End

    It 'exits 1 when BUNDLE_RESULT (last arg) is failure'
      When run bash "$SCRIPT" success success success success success success success failure
      The output should include 'One or more pipeline jobs failed'
      The status should equal 1
    End
  End

  Describe 'skipped results'
    It 'exits 0 when results contain skipped (not failure)'
      When run bash "$SCRIPT" success skipped success skipped success success success success
      The status should equal 0
    End

    It 'exits 0 when results contain cancelled (not failure)'
      When run bash "$SCRIPT" success cancelled success success success success success success
      The status should equal 0
    End
  End
End
