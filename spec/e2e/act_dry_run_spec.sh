# shellcheck shell=bash
# E2E tests: validate all workflow files with act --dry-run.
# Skipped gracefully when act is not available.

Describe 'Act workflow validation'

  Skip if 'act is not installed' "! command -v act >/dev/null 2>&1"

  It 'validates pre-release.yml'
    When run command act --dry-run -W "$SHELLSPEC_PROJECT_ROOT/.github/workflows/pre-release.yml"
    The status should equal 0
  End

  It 'validates release.yml'
    When run command act --dry-run -W "$SHELLSPEC_PROJECT_ROOT/.github/workflows/release.yml"
    The status should equal 0
  End

  It 'validates post-release.yml'
    When run command act --dry-run -W "$SHELLSPEC_PROJECT_ROOT/.github/workflows/post-release.yml"
    The status should equal 0
  End

  It 'validates maintenance.yml'
    When run command act --dry-run -W "$SHELLSPEC_PROJECT_ROOT/.github/workflows/maintenance.yml"
    The status should equal 0
  End

  It 'validates auto-fix-quality.yml'
    When run command act --dry-run -W "$SHELLSPEC_PROJECT_ROOT/.github/workflows/auto-fix-quality.yml"
    The status should equal 0
  End

  It 'validates ops.yml'
    When run command act --dry-run -W "$SHELLSPEC_PROJECT_ROOT/.github/workflows/ops.yml"
    The status should equal 0
  End
End
