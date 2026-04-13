# shellcheck shell=bash
Describe 'ci-12-set-version-outputs.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-12-set-version-outputs.sh"

  # This script calls ci-10-determine-version.sh which needs a git repo with tags.
  # We create a stub for ci-10 to avoid pop_var_context issues in subprocesses.
  _tmp_repo=""

  setup_git_repo() {
    : > "$GITHUB_OUTPUT"
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
    # Create a stub ci-10 that prints a version to stdout
    mkdir -p "$_tmp_repo/scripts/ci/release"
    printf '#!/usr/bin/env bash\necho "1.0.1"\n' > "$_tmp_repo/scripts/ci/release/ci-10-determine-version.sh"
    chmod +x "$_tmp_repo/scripts/ci/release/ci-10-determine-version.sh"
  }

  cleanup_git_repo() {
    rm -rf "$_tmp_repo" 2>/dev/null || true
  }

  Before 'setup_git_repo'
  After 'cleanup_git_repo'

  It 'writes version to GITHUB_OUTPUT'
    When run bash -c "cd '$_tmp_repo' && bash '$RUN_SCRIPT' '$SCRIPT' patch false"
    The status should equal 0
    The contents of file "$GITHUB_OUTPUT" should include 'version='
    The stderr should be present
  End

  It 'writes is-prerelease to GITHUB_OUTPUT'
    When run bash -c "cd '$_tmp_repo' && bash '$RUN_SCRIPT' '$SCRIPT' patch false"
    The status should equal 0
    The contents of file "$GITHUB_OUTPUT" should include 'is-prerelease='
    The stderr should be present
  End

  It 'announces its title'
    When run bash -c "cd '$_tmp_repo' && bash '$RUN_SCRIPT' '$SCRIPT' patch false"
    The status should equal 0
    The stderr should include 'Setting Version Outputs'
  End
End
