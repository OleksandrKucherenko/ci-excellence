# shellcheck shell=bash
Describe 'ci-07-apply-stability-tag.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-07-apply-stability-tag.sh"

  Describe 'missing arguments'
    It 'exits 1 when no arguments are provided'
      export CI_STABILITY_TAG="" CI_VERSION=""
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The status should equal 1
      The stderr should include 'Applying Stability Tag'
    End

    It 'exits 1 when only tag name is provided'
      export CI_STABILITY_TAG=stable CI_VERSION=""
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The status should equal 1
      The stderr should include 'Usage:'
    End
  End

  Describe 'with git repo'
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
      git -C "$_tmp_repo" tag "v1.0.0"
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

    It 'exits 1 when version tag does not exist'
      export CI_STABILITY_TAG=stable CI_VERSION=9.9.9
      When run bash -c "cd '$_tmp_repo' && bash '$RUN_SCRIPT' '$SCRIPT'"
      The status should equal 1
      The stderr should include 'not found'
    End
  End
End
