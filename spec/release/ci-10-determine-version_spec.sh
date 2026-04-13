# shellcheck shell=bash
# Tests for scripts/ci/release/ci-10-determine-version.sh
#
# This script uses `git describe --tags` to find the current version, then
# applies semver increments via the e-bash semver library.  To make tests
# deterministic we create a temporary git repo with a known tag.

Describe 'ci-10-determine-version.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-10-determine-version.sh"

  # -------------------------------------------------------------------
  # Fixture: lightweight git repo with a single tagged commit
  # -------------------------------------------------------------------
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

  # Helper: tag the fixture repo, then run the script inside it.
  run_determine_version() {
    local tag="$1"; shift
    git -C "$_tmp_repo" tag "$tag"
    # Run inside the temp repo so `git describe` finds our tag
    (cd "$_tmp_repo" && bash "$RUN_SCRIPT" "$SCRIPT" "$@")
  }

  Describe 'patch increment'
    It 'increments 1.0.0 -> 1.0.1'
      When call run_determine_version "v1.0.0" patch
      The output should include '1.0.1'
      The status should equal 0
      The stderr should be present
    End
  End

  Describe 'minor increment'
    It 'increments 1.0.0 -> 1.1.0'
      When call run_determine_version "v1.0.0" minor
      The output should include '1.1.0'
      The status should equal 0
      The stderr should be present
    End
  End

  Describe 'major increment'
    It 'increments 1.0.0 -> 2.0.0'
      When call run_determine_version "v1.0.0" major
      The output should include '2.0.0'
      The status should equal 0
      The stderr should be present
    End
  End

  Describe 'prerelease increment'
    It 'increments 1.0.0-alpha -> 1.0.0-alpha.1'
      When call run_determine_version "v1.0.0-alpha" prerelease alpha
      The output should include '1.0.0-alpha.1'
      The status should equal 0
      The stderr should be present
    End
  End
End
