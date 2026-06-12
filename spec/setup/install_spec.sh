# shellcheck shell=bash
# Offline-safe checks for the web installer (no network, no git mutations).
Describe 'install.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/install.sh"

  It 'prints usage with --help'
    When run bash "$SCRIPT" --help
    The output should include 'ci-excellence installer'
    The output should include '--dry-run'
    The output should include '--mode'
    The output should include 'rollback'
    The status should be success
  End

  It 'prints usage for the help command'
    When run bash "$SCRIPT" help
    The output should include 'ci-excellence installer'
    The status should be success
  End

  It 'rejects unknown options'
    When run bash "$SCRIPT" --bogus
    The stderr should include 'unknown option'
    The status should be failure
  End

  It 'rejects unknown commands'
    When run bash "$SCRIPT" frobnicate
    The stderr should include 'unknown command'
    The status should be failure
  End

  It 'rejects an invalid mode'
    When run bash "$SCRIPT" --mode wrong
    The stderr should include 'invalid --mode'
    The status should be failure
  End

  It 'fails when the target directory does not exist'
    When run bash "$SCRIPT" --dir /nonexistent-ci-excellence-target
    The stderr should include 'not a directory'
    The status should be failure
  End
End
