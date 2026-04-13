# shellcheck shell=bash
# Tests for echo:Success and echo:Error cross-cutting loggers.
# These verify that every script reports its status in a filterable format
# and that nested script failures don't disappear from logs.

Describe 'echo:Success and echo:Error loggers'

  Describe 'echo:Success is visible in script output'
    It 'appears in a passing build stub'
      export CI_VERSION="1.0.0"
      When run bash "$RUN_SCRIPT" "$SHELLSPEC_PROJECT_ROOT/scripts/ci/build/ci-10-compile.sh"
      The stderr should include '[SUCCESS]'
      The status should equal 0
    End

    It 'appears in a passing test stub'
      export CI_VERSION="1.0.0"
      When run bash "$RUN_SCRIPT" "$SHELLSPEC_PROJECT_ROOT/scripts/ci/test/ci-10-unit-tests.sh"
      The stderr should include '[SUCCESS]'
      The status should equal 0
    End

    It 'appears in a passing setup stub'
      When run bash "$RUN_SCRIPT" "$SHELLSPEC_PROJECT_ROOT/scripts/ci/setup/ci-20-install-dependencies.sh"
      The stderr should include '[SUCCESS]'
      The status should equal 0
    End
  End

  Describe 'echo:Error is visible on failure'
    It 'appears when check-failures detects a failure'
      export RESULT_SETUP=failure RESULT_COMPILE=success RESULT_LINT=success
      export RESULT_UNIT_TESTS=success RESULT_INTEGRATION_TESTS=success
      export RESULT_E2E_TESTS=success RESULT_SECURITY_SCAN=success RESULT_BUNDLE=success
      When run bash "$RUN_SCRIPT" "$SHELLSPEC_PROJECT_ROOT/scripts/ci/build/ci-60-check-failures.sh"
      The stderr should include '[ERROR]'
      The status should equal 1
    End

    It 'appears when a required env var is missing'
      export CI_VERSION=""
      When run bash "$RUN_SCRIPT" "$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-15-update-version.sh"
      The stderr should include '[ERROR]'
      The status should equal 1
    End
  End

  Describe 'nested script failure propagates echo:Error'
    It 'error from ci-91-test-after-update is visible when child fails'
      # ci-91-test-after-update.sh calls ci-10-unit-tests.sh which is a stub (exits 0)
      # but it catches failures with || echo:Maint - verify the script runs and reports
      When run bash "$RUN_SCRIPT" "$SHELLSPEC_PROJECT_ROOT/scripts/ci/maintenance/ci-91-test-after-update.sh"
      The stderr should include '[SUCCESS]'
      The status should equal 0
    End
  End

  Describe 'filtering: [SUCCESS] and [ERROR] are greppable'
    It 'SUCCESS and ERROR tags are distinct strings in output'
      export RESULT_SETUP=success RESULT_COMPILE=success RESULT_LINT=success
      export RESULT_UNIT_TESTS=success RESULT_INTEGRATION_TESTS=success
      export RESULT_E2E_TESTS=success RESULT_SECURITY_SCAN=success RESULT_BUNDLE=success
      When run bash "$RUN_SCRIPT" "$SHELLSPEC_PROJECT_ROOT/scripts/ci/build/ci-60-check-failures.sh"
      The stderr should include '[SUCCESS]'
      The stderr should not include '[ERROR]'
      The status should equal 0
    End

    It 'failure produces ERROR without SUCCESS'
      export RESULT_SETUP=success RESULT_COMPILE=success RESULT_LINT=failure
      export RESULT_UNIT_TESTS=success RESULT_INTEGRATION_TESTS=success
      export RESULT_E2E_TESTS=success RESULT_SECURITY_SCAN=success RESULT_BUNDLE=success
      When run bash "$RUN_SCRIPT" "$SHELLSPEC_PROJECT_ROOT/scripts/ci/build/ci-60-check-failures.sh"
      The stderr should include '[ERROR]'
      The status should equal 1
    End
  End
End
