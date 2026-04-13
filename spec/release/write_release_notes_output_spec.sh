# shellcheck shell=bash
Describe 'ci-27-write-release-notes-output.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-27-write-release-notes-output.sh"

  _tmp_dir=""

  setup_stubs() {
    : > "$GITHUB_OUTPUT"
    _tmp_dir=$(mktemp -d)
    # Create a stub ci-25 that outputs release notes to stdout
    mkdir -p "$_tmp_dir/scripts/ci/release"
    printf '#!/usr/bin/env bash\necho "## Release 1.0.0"\necho ""\necho "Release notes stub"\n' > "$_tmp_dir/scripts/ci/release/ci-25-generate-release-notes.sh"
    chmod +x "$_tmp_dir/scripts/ci/release/ci-25-generate-release-notes.sh"
  }

  cleanup_stubs() {
    rm -rf "$_tmp_dir" 2>/dev/null || true
  }

  Before 'setup_stubs'
  After 'cleanup_stubs'

  It 'exits successfully'
    When run bash -c "cd '$_tmp_dir' && bash '$RUN_SCRIPT' '$SCRIPT' 1.0.0"
    The status should equal 0
    The stderr should be present
  End

  It 'writes notes to GITHUB_OUTPUT'
    When run bash -c "cd '$_tmp_dir' && bash '$RUN_SCRIPT' '$SCRIPT' 1.0.0"
    The contents of file "$GITHUB_OUTPUT" should include 'notes'
    The stderr should be present
  End

  It 'announces its title'
    When run bash -c "cd '$_tmp_dir' && bash '$RUN_SCRIPT' '$SCRIPT' 1.0.0"
    The stderr should include 'Writing Release Notes Output'
  End
End
