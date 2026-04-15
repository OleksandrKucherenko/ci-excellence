# shellcheck shell=bash
# Tests for echo:Success and echo:Error cross-cutting loggers.
# These verify that every script reports its status in a filterable format.

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
    It 'appears when a required env var is missing'
      export CI_VERSION=""
      When run bash "$RUN_SCRIPT" "$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-15-update-version.sh"
      The status should equal 1
    End
  End

  Describe 'filtering: [SUCCESS] tags are greppable'
    It 'SUCCESS tag is present in check-failures output'
      export RESULT_SETUP=success RESULT_COMPILE=success RESULT_LINT=success
      export RESULT_UNIT_TESTS=success RESULT_INTEGRATION_TESTS=success
      export RESULT_E2E_TESTS=success RESULT_SECURITY_SCAN=success RESULT_BUNDLE=success
      When run bash "$RUN_SCRIPT" "$SHELLSPEC_PROJECT_ROOT/scripts/ci/build/ci-60-check-failures.sh"
      The stderr should include '[SUCCESS]'
      The status should equal 0
    End
  End
End
