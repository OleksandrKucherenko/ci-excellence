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
  }

  cleanup_git_repo() {
    rm -rf "$_tmp_repo" 2>/dev/null || true
  }

  Before 'setup_git_repo'
  After 'cleanup_git_repo'

  It 'exits successfully'
    When run bash -c "cd '$_tmp_repo' && bash '$RUN_SCRIPT' '$SCRIPT' main 1.0.0"
    The status should equal 0
  End

  It 'announces its title'
    When run bash -c "cd '$_tmp_repo' && bash '$RUN_SCRIPT' '$SCRIPT' main 1.0.0"
    The stderr should include 'Committing Version Changes'
  End

  It 'exits 1 when version is missing'
    When run bash -c "cd '$_tmp_repo' && bash '$RUN_SCRIPT' '$SCRIPT' main"
    The status should equal 1
    The stderr should include 'Version is required'
  End
End
