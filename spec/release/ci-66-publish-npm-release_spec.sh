# shellcheck shell=bash
Describe 'ci-66-publish-npm-release.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-66-publish-npm-release.sh"

  # Stub ci-65-publish-npm.sh so the script does not actually publish
  setup_stub() {
    _orig_ci65="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-65-publish-npm.sh"
    _backup_ci65="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-65-publish-npm.sh.bak"
    cp "$_orig_ci65" "$_backup_ci65"
    printf '#!/usr/bin/env bash\nexit 0\n' > "$_orig_ci65"
    chmod +x "$_orig_ci65"
  }

  cleanup_stub() {
    mv "$_backup_ci65" "$_orig_ci65"
  }

  Before 'setup_stub'
  After 'cleanup_stub'

  It 'exits 0 when called with default (non-prerelease)'
    When run bash "$RUN_SCRIPT" "$SCRIPT" false
    The status should equal 0
  End

  It 'announces its title'
    When run bash "$RUN_SCRIPT" "$SCRIPT" false
    The stderr should include 'Publish NPM Release'
  End
End
