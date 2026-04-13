# shellcheck shell=bash
Describe 'ci-07-apply-stability-tag.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-07-apply-stability-tag.sh"

  Describe 'missing arguments'
    It 'exits 1 when no arguments are provided'
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The status should equal 1
      The stderr should include 'Applying Stability Tag'
    End

    It 'exits 1 when only tag name is provided'
      When run bash "$RUN_SCRIPT" "$SCRIPT" stable
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
    }

    cleanup_git_repo() {
      rm -rf "$_tmp_repo" 2>/dev/null || true
    }

    Before 'setup_git_repo'
    After 'cleanup_git_repo'

    It 'exits 1 when version tag does not exist'
      When run bash -c "GIT_DIR='$_tmp_repo/.git' GIT_WORK_TREE='$_tmp_repo' bash '$RUN_SCRIPT' '$SCRIPT' stable 9.9.9"
      The status should equal 1
      The stderr should include 'not found'
    End
  End
End
