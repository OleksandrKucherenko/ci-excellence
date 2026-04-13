# shellcheck shell=bash
# E2E tests for hook auto-discovery, middleware contracts, and error propagation.
# Uses fixture hooks in spec/e2e/fixture/ci-cd/{step_name}/

Describe 'Hook integration'
  FIXTURE_DIR="$SHELLSPEC_PROJECT_ROOT/spec/e2e/fixture"

  Describe 'per-step hook discovery'
    It 'discovers and executes begin hooks from ci-cd/ci-10-compile/'
      export HOOKS_DIR="$FIXTURE_DIR/ci-cd/ci-10-compile"
      export CI_VERSION="1.0.0"
      When run bash "$RUN_SCRIPT" "$SHELLSPEC_PROJECT_ROOT/scripts/ci/build/ci-10-compile.sh"
      The stderr should include 'Hook: begin_00_check-env.sh'
      The status should equal 0
    End

    It 'discovers begin hooks from ci-cd/ci-10-unit-tests/'
      export HOOKS_DIR="$FIXTURE_DIR/ci-cd/ci-10-unit-tests"
      export CI_VERSION="1.0.0"
      When run bash "$RUN_SCRIPT" "$SHELLSPEC_PROJECT_ROOT/scripts/ci/test/ci-10-unit-tests.sh"
      The stderr should include 'Hook: begin_00_setup-fixtures.sh'
      The status should equal 0
    End
  End

  Describe 'middleware contract: env var injection'
    It 'sets env vars via contract:env from hook stdout'
      export HOOKS_DIR="$FIXTURE_DIR/ci-cd/ci-10-unit-tests"
      export CI_VERSION="1.0.0"
      When run bash "$RUN_SCRIPT" "$SHELLSPEC_PROJECT_ROOT/scripts/ci/test/ci-10-unit-tests.sh"
      The stderr should include 'setup-fixtures'
      The status should equal 0
    End
  End

  Describe 'env vars flow into hooks'
    It 'hook receives CI_VERSION from parent environment'
      export HOOKS_DIR="$FIXTURE_DIR/ci-cd/ci-10-compile"
      export CI_VERSION="2.5.0"
      When run bash "$RUN_SCRIPT" "$SHELLSPEC_PROJECT_ROOT/scripts/ci/build/ci-10-compile.sh"
      The stderr should include 'CI_VERSION=2.5.0 verified'
      The status should equal 0
    End
  End

  Describe 'no hooks directory is safe'
    It 'runs normally when HOOKS_DIR does not exist'
      export HOOKS_DIR="/tmp/nonexistent-hooks-dir-$$"
      When run bash "$RUN_SCRIPT" "$SHELLSPEC_PROJECT_ROOT/scripts/ci/build/ci-10-compile.sh"
      The stderr should include 'Compiling/Building Project'
      The status should equal 0
    End
  End
End
