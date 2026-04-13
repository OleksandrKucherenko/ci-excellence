# shellcheck shell=bash
Describe 'ci-18-commit-version-changes.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-18-commit-version-changes.sh"

  _tmp_repo=""

  setup_git_repo() {
    _tmp_repo=$(mktemp -d)
    git -C "$_tmp_repo" init -q
    git -C "$_tmp_repo" config user.email "test@test.com"
    git -C "$_tmp_repo" config user.name "Test"
    git -C "$_tmp_repo" config commit.gpgsign false
    git -C "$_tmp_repo" config tag.gpgsign false
    touch "$_tmp_repo/README"
    git -C "$_tmp_repo" add README
    git -C "$_tmp_repo" commit -q -m "initial"
    # Create stub for the bot setup script so relative path resolves
    mkdir -p "$_tmp_repo/scripts/ci/setup"
    printf '#!/usr/bin/env bash\ntrue\n' > "$_tmp_repo/scripts/ci/setup/ci-30-github-actions-bot.sh"
    chmod +x "$_tmp_repo/scripts/ci/setup/ci-30-github-actions-bot.sh"
  }

  cleanup_git_repo() {
    rm -rf "$_tmp_repo" 2>/dev/null || true
  }

  Before 'setup_git_repo'
  After 'cleanup_git_repo'

  It 'exits successfully'
    export CI_TARGET_BRANCH=main CI_VERSION=1.0.0
    When run bash -c "cd '$_tmp_repo' && bash '$RUN_SCRIPT' '$SCRIPT'"
    The status should equal 0
    The stderr should include 'Committing Version Changes'
    The stdout should be present
  End

  It 'announces its title'
    export CI_TARGET_BRANCH=main CI_VERSION=1.0.0
    When run bash -c "cd '$_tmp_repo' && bash '$RUN_SCRIPT' '$SCRIPT'"
    The stderr should include 'Committing Version Changes'
    The stdout should be present
  End

  It 'exits 1 when version is missing'
    export CI_TARGET_BRANCH=main CI_VERSION=""
    When run bash -c "cd '$_tmp_repo' && bash '$RUN_SCRIPT' '$SCRIPT'"
    The status should equal 1
    The stderr should include 'Version is required'
  End
End
