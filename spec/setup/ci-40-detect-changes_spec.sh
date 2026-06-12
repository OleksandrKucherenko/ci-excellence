# shellcheck shell=bash
Describe 'ci-40-detect-changes.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/setup/ci-40-detect-changes.sh"

  sandbox_setup() {
    SANDBOX="$(mktemp -d)"
    OUT_FILE="$SANDBOX/github_output"
    : >"$OUT_FILE"
    RULES="$SANDBOX/detect-changes.rules"
    git -C "$SANDBOX" init -q -b main
  }

  sandbox_cleanup() {
    rm -rf "$SANDBOX"
  }

  sandbox_commit() {
    git -C "$SANDBOX" add -A
    git -C "$SANDBOX" -c user.email=ci@test -c user.name=ci -c commit.gpgsign=false \
      commit -qm "${1:-change}"
  }

  # Run the script inside the sandbox with a clean GitHub context.
  # Knobs: BASE_SHA, DETECT_FLAG, FORCE_FLAG, DISCOVER (default: no discovery).
  run_detect() {
    cd "$SANDBOX" &&
      GITHUB_OUTPUT="$OUT_FILE" \
        CI_CHANGES_RULES="$RULES" \
        CI_CHANGES_DISCOVER="${DISCOVER:-none}" \
        CI_BASE_SHA="${BASE_SHA:-}" \
        CI_FORCE_ALL_GATES="${FORCE_FLAG:-false}" \
        ENABLE_DETECT_CHANGES="${DETECT_FLAG:-true}" \
        GITHUB_BASE_REF="" GITHUB_EVENT_BEFORE="" GITHUB_REF="" \
        bash "$RUN_SCRIPT" "$SCRIPT"
  }

  BeforeEach sandbox_setup
  AfterEach sandbox_cleanup

  It 'fires a gate when files under its patterns change'
    printf 'app: app/ *.cfg\n' >"$RULES"
    mkdir -p "$SANDBOX/app" && echo base >"$SANDBOX/app/main.sh" && echo doc >"$SANDBOX/readme.md"
    sandbox_commit base
    BASE_SHA="$(git -C "$SANDBOX" rev-parse HEAD)"
    echo change >>"$SANDBOX/app/main.sh"
    sandbox_commit change
    When run run_detect
    The status should equal 0
    The stderr should include 'Detect Changes Done'
    The contents of file "$OUT_FILE" should include 'app=true'
    The contents of file "$OUT_FILE" should include 'any=true'
  End

  It 'keeps gates off when nothing under their patterns changed'
    printf 'app: app/\n' >"$RULES"
    mkdir -p "$SANDBOX/app" && echo base >"$SANDBOX/app/main.sh" && echo doc >"$SANDBOX/readme.md"
    sandbox_commit base
    BASE_SHA="$(git -C "$SANDBOX" rev-parse HEAD)"
    echo change >>"$SANDBOX/readme.md"
    sandbox_commit change
    When run run_detect
    The status should equal 0
    The stderr should be present
    The contents of file "$OUT_FILE" should include 'app=false'
    The contents of file "$OUT_FILE" should include 'any=false'
  End

  It 'follows @gate dependency edges transitively'
    printf 'shared: lib/\nmid: mid/ @shared\ntop: top/ @mid\n' >"$RULES"
    mkdir -p "$SANDBOX/lib" "$SANDBOX/mid" "$SANDBOX/top"
    echo a >"$SANDBOX/lib/a.sh" && echo b >"$SANDBOX/mid/b.sh" && echo c >"$SANDBOX/top/c.sh"
    sandbox_commit base
    BASE_SHA="$(git -C "$SANDBOX" rev-parse HEAD)"
    echo change >>"$SANDBOX/lib/a.sh"
    sandbox_commit change
    When run run_detect
    The status should equal 0
    The stderr should be present
    The contents of file "$OUT_FILE" should include 'shared=true'
    The contents of file "$OUT_FILE" should include 'mid=true'
    The contents of file "$OUT_FILE" should include 'top=true'
  End

  It 'discovers workspaces and runtime dependency edges from metadata files'
    Skip if 'jq is not installed' [ -z "$(command -v jq)" ]
    DISCOVER="packages/ services/"
    : >"$RULES"
    mkdir -p "$SANDBOX/packages/shared" "$SANDBOX/services/auth" "$SANDBOX/services/bff" "$SANDBOX/services/email"
    echo '{"name":"@acme/shared"}' >"$SANDBOX/packages/shared/graph-metadata.json"
    echo '{"name":"@acme/auth","dependencies":{"@acme/shared":"workspace:*","express":"^4.0.0"}}' >"$SANDBOX/services/auth/package.json"
    echo '{"name":"@acme/bff","dependencies":{"@acme/auth":"*"},"runtimeDependencies":["@acme/email"]}' >"$SANDBOX/services/bff/graph-metadata.json"
    echo '{"name":"@acme/email","dependencies":{"lodash":"^4.17.0"}}' >"$SANDBOX/services/email/package.json"
    sandbox_commit base
    BASE_SHA="$(git -C "$SANDBOX" rev-parse HEAD)"
    echo change >"$SANDBOX/services/email/handler.ts"
    sandbox_commit change
    When run run_detect
    The status should equal 0
    The stderr should include 'discovered 4 workspace(s)'
    The contents of file "$OUT_FILE" should include 'email=true'
    The contents of file "$OUT_FILE" should include 'bff=true'
    The contents of file "$OUT_FILE" should include 'auth=false'
    The contents of file "$OUT_FILE" should include 'shared=false'
  End

  It 'turns every gate on when forced'
    printf 'app: app/\ndocs: docs/\n' >"$RULES"
    FORCE_FLAG="true"
    When run run_detect
    The status should equal 0
    The stderr should include 'forced'
    The contents of file "$OUT_FILE" should include 'app=true'
    The contents of file "$OUT_FILE" should include 'docs=true'
    The contents of file "$OUT_FILE" should include 'any=true'
  End

  It 'turns every gate on when detection is disabled'
    printf 'app: app/\n' >"$RULES"
    DETECT_FLAG="false"
    When run run_detect
    The status should equal 0
    The stderr should include 'detection disabled'
    The contents of file "$OUT_FILE" should include 'app=true'
  End

  It 'fails open when no diff base is resolvable'
    printf 'app: app/\n' >"$RULES"
    mkdir -p "$SANDBOX/app" && echo base >"$SANDBOX/app/main.sh"
    sandbox_commit base
    When run run_detect
    The status should equal 0
    The stderr should include 'no diff base resolvable'
    The contents of file "$OUT_FILE" should include 'app=true'
  End

  It 'emits only aggregate outputs when no gates are defined'
    RULES="$SANDBOX/does-not-exist.rules"
    When run run_detect
    The status should equal 0
    The stderr should include 'No gates defined'
    The contents of file "$OUT_FILE" should include 'any=true'
    The contents of file "$OUT_FILE" should include 'gates_json=[]'
  End
End
