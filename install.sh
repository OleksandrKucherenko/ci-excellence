#!/usr/bin/env bash
set -euo pipefail

# CI Excellence: Web installer (curl-able bootstrap)
# Purpose: Apply the CI Excellence CI/CD framework on top of any existing project.
#
# Quick start (run from your project root):
#   curl -fsSL https://raw.githubusercontent.com/OleksandrKucherenko/ci-excellence/main/install.sh | bash
#
# With options:
#   curl -fsSL https://raw.githubusercontent.com/OleksandrKucherenko/ci-excellence/main/install.sh | bash -s -- --dry-run
#
# Modes:
#   git  - default inside a git repository. Integrates the `dist` branch via the
#          canonical scripts/setup/ci-integrate.sh (executed from the fetched
#          dist branch, so installer and payload never drift). Re-running on an
#          already integrated project delegates to scripts/setup/ci-upgrade.sh.
#   copy - default outside a git repository. Downloads the `dist` branch
#          (GitHub tarball, falls back to `git clone`) and copies files into
#          place. Existing files are never overwritten unless --force is given.
#
# After installation see docs/QUICKSTART.md and docs/CUSTOMIZATION.md in
# https://github.com/OleksandrKucherenko/ci-excellence

# --- Configuration (overridable via environment) ---
CI_REMOTE_URL="${CI_REMOTE_URL:-https://github.com/OleksandrKucherenko/ci-excellence.git}"
CI_REMOTE_NAME="${CI_REMOTE_NAME:-ci}"
CI_BRANCH="${CI_BRANCH:-dist}"
CONFIG_FILE=".ci-excellence.yml"
USER_AGENT="ci-excellence-installer"

TARGET_DIR="."
MODE="auto"
DRY_RUN=false
FORCE=false
ASSUME_YES=false

# --- Colors (honor NO_COLOR and non-TTY output) ---
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  R='\033[0;31m' G='\033[0;32m' Y='\033[0;33m' C='\033[0;36m'
  W='\033[1;37m' D='\033[0;90m' N='\033[0m'
else
  R='' G='' Y='' C='' W='' D='' N=''
fi

say() { printf '%b\n' "$*"; }
kv() { printf '  %b%-9s%b %b\n' "$D" "$1" "$N" "$2"; }
ok() { say "  ${G}\xe2\x9c\x93${N} $*"; }
warn() { printf '%b\n' "  ${Y}warning:${N} $*" >&2; }
die() {
  printf '%b\n' "  ${R}error:${N} $*" >&2
  exit 1
}

have() { command -v "$1" > /dev/null 2>&1; }

usage() {
  cat << 'USAGE'
ci-excellence installer - apply the CI/CD framework on top of an existing project.

Usage:
  curl -fsSL https://raw.githubusercontent.com/OleksandrKucherenko/ci-excellence/main/install.sh | bash
  curl -fsSL https://raw.githubusercontent.com/OleksandrKucherenko/ci-excellence/main/install.sh | bash -s -- [options]
  ./install.sh [options]

Options:
  --dir PATH      Target project directory (default: current directory)
  --mode MODE     Integration mode: auto | git | copy (default: auto)
                    git  - merge the dist branch with upgrade/rollback lineage
                    copy - plain file copy, never overwrites without --force
  --remote URL    Source repository (default: ci-excellence on GitHub)
  --branch NAME   Source branch (default: dist)
  --name NAME     Git remote name to register in git mode (default: ci)
  --dry-run       Show what would happen without changing anything
  --force         git mode:  bypass the clean-worktree guard
                  copy mode: overwrite existing files
  --yes, -y       Skip the confirmation prompt
  --help, -h      Show this help

Behavior:
  * In git mode, re-running the installer on an already integrated project
    performs an upgrade (delegates to scripts/setup/ci-upgrade.sh).
  * The set of managed files is controlled by .ci-excellence.yml; edit it and
    re-run ./scripts/setup/ci-upgrade.sh to include or exclude paths.

Environment overrides: CI_REMOTE_URL, CI_REMOTE_NAME, CI_BRANCH
USAGE
}

# Normalize a repository URL/path for identity comparison:
# https://github.com/o/r.git, git@github.com:o/r and ssh://git@github.com/o/r
# all reduce to "github.com/o/r".
normalize_repo() {
  local u="${1%/}"
  u="${u%.git}"
  u="${u#ssh://}"
  u="${u#https://}"
  u="${u#http://}"
  u="${u#*@}" # drop userinfo: git@..., x-access-token:...@...
  # git@github.com:owner/repo -> github.com/owner/repo
  printf '%s' "$u" | sed 's|:|/|' | tr '[:upper:]' '[:lower:]'
}

# Last two path segments ("owner/repo") of a normalized repository URL.
# Used to recognize the same repository behind proxies or mirrors.
repo_tail() {
  normalize_repo "$1" | awk -F/ 'NF >= 2 { print $(NF - 1) "/" $NF }'
}

# Build a GitHub codeload tarball URL from a github.com remote.
# Returns non-zero for non-GitHub remotes (caller falls back to git clone).
github_tarball_url() {
  local repo
  repo="$(normalize_repo "$1")"
  case "$repo" in
    github.com/*/*)
      printf 'https://codeload.%s/tar.gz/refs/heads/%s' "$repo" "$2"
      ;;
    *)
      return 1
      ;;
  esac
}

confirm() {
  local prompt="$1" reply=""
  [ "$ASSUME_YES" = true ] && return 0
  [ "$DRY_RUN" = true ] && return 0
  if [ -t 0 ]; then
    printf '%b [y/N] ' "  ${C}?${N} $prompt"
    read -r reply
  elif { : > /dev/tty; } 2> /dev/null && [ -r /dev/tty ]; then
    # stdin is the piped script (curl | bash) - talk to the terminal directly
    printf '%b [y/N] ' "  ${C}?${N} $prompt" > /dev/tty
    read -r reply < /dev/tty
  else
    say "  ${D}no interactive terminal detected - proceeding (pass --yes to make this explicit)${N}"
    return 0
  fi
  case "$reply" in
    y | Y | yes | YES | Yes) return 0 ;;
    *) die "aborted by user" ;;
  esac
}

# Parse "include:" list entries from a .ci-excellence.yml document on stdin.
parse_include_list() {
  local line in_include=false
  while IFS= read -r line; do
    if [[ "$line" =~ ^include: ]]; then
      in_include=true
      continue
    fi
    if [[ "$line" =~ ^[a-z] ]] && [ "$in_include" = true ]; then
      break
    fi
    if [ "$in_include" = true ] && [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.*) ]]; then
      printf '%s\n' "${BASH_REMATCH[1]}"
    fi
  done
}

check_platform() {
  case "$(uname -s)" in
    MINGW* | MSYS* | CYGWIN*)
      say ""
      say "  ${W}ci-excellence${N} ${D}installer${N}"
      say ""
      say "  ${Y}Windows detected${N} - CI Excellence targets bash environments."
      say "  Run this inside ${G}WSL2${N} instead (see docs/INSTALLATION.md):"
      say ""
      say "    ${C}wsl curl -fsSL https://raw.githubusercontent.com/OleksandrKucherenko/ci-excellence/main/install.sh | bash${N}"
      say ""
      exit 0
      ;;
  esac
}

check_mise() {
  if have mise; then
    ok "mise ${D}$(mise --version 2> /dev/null | head -1)${N}"
    return 0
  fi
  warn "mise is not installed - it is the only prerequisite of CI Excellence"
  warn "  install:  ${C}curl https://mise.run | sh${N}"
  warn "  activate: ${C}eval \"\$(mise activate bash)\"${N}  ${D}# or zsh/fish${N}"
  warn "  details:  docs/INSTALLATION.md in the ci-excellence repository"
}

# --- git mode -------------------------------------------------------------------

preflight_git_mode() {
  have git || die "git is required for git mode (or re-run with --mode copy)"

  git rev-parse --is-inside-work-tree > /dev/null 2>&1 ||
    die "not a git repository: $PWD (run 'git init' first, or use --mode copy)"

  # Refuse to integrate ci-excellence into itself (match owner/repo so the
  # guard also works behind git proxies and mirrors)
  local origin_url origin_tail
  origin_url="$(git remote get-url origin 2> /dev/null || true)"
  origin_tail="$(repo_tail "$origin_url")"
  if [ -n "$origin_tail" ] && [ "$origin_tail" = "$(repo_tail "$CI_REMOTE_URL")" ] && [ "$FORCE" != true ]; then
    die "this looks like the ci-excellence repository itself (origin: $origin_url) - nothing to install"
  fi

  git rev-parse -q --verify HEAD > /dev/null 2>&1 ||
    die "repository has no commits yet - create one first: ${C}git commit --allow-empty -m 'chore: initial commit'${N}"

  if [ -z "$(git config user.email 2> /dev/null || true)" ] || [ -z "$(git config user.name 2> /dev/null || true)" ]; then
    die "git identity is not configured - run: ${C}git config user.name 'Your Name' && git config user.email 'you@example.com'${N}"
  fi

  if [ -n "$(git status --porcelain)" ] && [ "$FORCE" != true ]; then
    die "working tree is not clean - commit or stash your changes first (or pass --force)"
  fi
}

dry_run_git_integrate() {
  local dist_files path marker
  dist_files="$(git ls-tree -r --name-only "$CI_REMOTE_NAME/$CI_BRANCH" | wc -l | tr -d ' ')"
  say ""
  say "  ${W}dry run${N} ${D}- initial integration${N}"
  say "  would integrate ci-excellence ${D}@ $(git rev-parse --short "$CI_REMOTE_NAME/$CI_BRANCH") ($dist_files files in $CI_BRANCH branch)${N}"
  say "  managed paths ${D}(defaults written to $CONFIG_FILE on a real run)${N}:"
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    if ! git cat-file -e "$CI_REMOTE_NAME/$CI_BRANCH:${path%/}" 2> /dev/null; then
      marker="${D}(not in $CI_BRANCH, skipped)${N}"
    elif [ -e "$path" ]; then
      marker="${Y}(exists - would be updated)${N}"
    else
      marker="${G}(new)${N}"
    fi
    say "    ${D}-${N} $path $marker"
  done < <(git show "$CI_REMOTE_NAME/$CI_BRANCH:$CONFIG_FILE.template" 2> /dev/null | parse_include_list)
  say "  a real run executes scripts/setup/ci-integrate.sh and commits the merge"
}

install_git_mode() {
  preflight_git_mode

  # Register the remote and fetch the distribution branch
  if git remote get-url "$CI_REMOTE_NAME" > /dev/null 2>&1; then
    git remote set-url "$CI_REMOTE_NAME" "$CI_REMOTE_URL"
  else
    git remote add "$CI_REMOTE_NAME" "$CI_REMOTE_URL"
  fi
  git fetch --quiet "$CI_REMOTE_NAME" "$CI_BRANCH" ||
    die "failed to fetch '$CI_BRANCH' from $CI_REMOTE_URL"

  local version
  version="$(git rev-parse --short "$CI_REMOTE_NAME/$CI_BRANCH")"
  ok "fetched $CI_REMOTE_NAME/$CI_BRANCH ${D}@ $version${N}"

  git cat-file -e "$CI_REMOTE_NAME/$CI_BRANCH:scripts/setup/ci-integrate.sh" 2> /dev/null ||
    die "branch '$CI_BRANCH' of $CI_REMOTE_URL is not a ci-excellence distribution (scripts/setup/ci-integrate.sh missing)"

  if [ -f "$CONFIG_FILE" ]; then
    # Already integrated - delegate to the canonical upgrade script
    ok "found $CONFIG_FILE ${D}- already integrated, switching to upgrade${N}"
    local upgrade_args=()
    [ "$DRY_RUN" = true ] && upgrade_args+=(--dry-run)
    [ "$FORCE" = true ] && upgrade_args+=(--force)
    git show "$CI_REMOTE_NAME/$CI_BRANCH:scripts/setup/ci-upgrade.sh" |
      bash -s -- ${upgrade_args[@]+"${upgrade_args[@]}"} ||
      die "upgrade failed - to abort a half-finished merge: ${C}git merge --abort${N}"
    return 0
  fi

  if [ "$DRY_RUN" = true ]; then
    dry_run_git_integrate
    return 0
  fi

  confirm "integrate ci-excellence @ $version into $PWD (creates a merge commit)?"

  # Run the canonical integration script from the fetched branch itself,
  # so the executed logic always matches the version being installed.
  git show "$CI_REMOTE_NAME/$CI_BRANCH:scripts/setup/ci-integrate.sh" |
    bash -s -- --remote "$CI_REMOTE_URL" --branch "$CI_BRANCH" --name "$CI_REMOTE_NAME" ||
    die "integration failed - to abort a half-finished merge: ${C}git merge --abort${N}"

  # Older distributions lost the merge parent (merge ran against a dirty
  # index); without it ci-upgrade/ci-rollback/ci-status cannot track versions.
  if ! git rev-parse -q --verify HEAD^2 > /dev/null 2>&1; then
    warn "integration commit has no merge lineage to $CI_REMOTE_NAME/$CI_BRANCH"
    warn "  upgrade tracking will be limited until the next successful ${C}./scripts/setup/ci-upgrade.sh${N}"
  fi
}

# --- copy mode ------------------------------------------------------------------

fetch_distribution() {
  # Populates $SRC_DIR with the distribution payload and $SRC_VERSION (best effort).
  local workdir="$1" url tarball="$1/dist.tar.gz"

  SRC_DIR=""
  SRC_VERSION="$CI_BRANCH"

  if url="$(github_tarball_url "$CI_REMOTE_URL" "$CI_BRANCH")"; then
    mkdir -p "$workdir/unpack"
    if { have curl && curl -fsSL --retry 2 -A "$USER_AGENT" "$url" -o "$tarball"; } ||
      { have wget && wget -q -U "$USER_AGENT" "$url" -O "$tarball"; }; then
      tar -xzf "$tarball" -C "$workdir/unpack"
      SRC_DIR="$(find "$workdir/unpack" -mindepth 1 -maxdepth 1 -type d | head -1)"
      ok "downloaded ${D}$url${N}"
    else
      warn "tarball download failed, falling back to git clone"
    fi
  fi

  if [ -z "$SRC_DIR" ]; then
    have git || die "neither a GitHub tarball download nor git clone is possible (install curl, wget or git)"
    git clone --quiet --depth 1 --branch "$CI_BRANCH" "$CI_REMOTE_URL" "$workdir/clone" ||
      die "failed to clone branch '$CI_BRANCH' from $CI_REMOTE_URL"
    SRC_VERSION="$(git -C "$workdir/clone" rev-parse --short HEAD)"
    rm -rf "$workdir/clone/.git"
    SRC_DIR="$workdir/clone"
    ok "cloned $CI_REMOTE_URL ${D}@ $SRC_VERSION ($CI_BRANCH)${N}"
  fi

  [ -n "$SRC_DIR" ] && [ -d "$SRC_DIR" ] || die "failed to obtain the distribution payload"
}

install_copy_mode() {
  local workdir
  workdir="$(mktemp -d)"
  # shellcheck disable=SC2064 -- expand workdir now, it is gone when the trap runs
  trap "rm -rf '$workdir'" EXIT

  fetch_distribution "$workdir"

  confirm "copy ci-excellence @ $SRC_VERSION into $PWD (existing files are kept unless --force)?"

  local rel copied=0 skipped=0
  while IFS= read -r rel; do
    case "$rel" in
      "$CONFIG_FILE.template") continue ;;
    esac
    if [ -e "./$rel" ] && [ "$FORCE" != true ]; then
      say "  ${D}= $rel (exists, kept)${N}"
      skipped=$((skipped + 1))
      continue
    fi
    if [ "$DRY_RUN" = true ]; then
      say "  ${G}+${N} $rel"
    else
      mkdir -p "$(dirname "./$rel")"
      cp -p "$SRC_DIR/$rel" "./$rel"
      case "$rel" in
        *.sh) chmod +x "./$rel" ;;
      esac
    fi
    copied=$((copied + 1))
  done < <(cd "$SRC_DIR" && find . -type f | sed 's|^\./||' | sort)

  # Seed the integration config so a later git-based upgrade can take over
  if [ ! -f "$CONFIG_FILE" ] && [ -f "$SRC_DIR/$CONFIG_FILE.template" ]; then
    if [ "$DRY_RUN" = true ]; then
      say "  ${G}+${N} $CONFIG_FILE ${D}(from template)${N}"
    else
      cp "$SRC_DIR/$CONFIG_FILE.template" "./$CONFIG_FILE"
    fi
  fi

  say ""
  if [ "$DRY_RUN" = true ]; then
    say "  ${W}dry run${N} ${D}- $copied file(s) would be copied, $skipped kept as-is${N}"
  else
    ok "copied $copied file(s), kept $skipped existing file(s)"
  fi
}

# --- next steps -------------------------------------------------------------------

print_next_steps() {
  say ""
  say "  ${W}done!${N} next steps ${D}(docs/QUICKSTART.md)${N}"
  say ""
  if ! have mise; then
    say "  0. install mise (the only prerequisite):"
    say "       ${C}curl https://mise.run | sh${N}"
    say "       ${C}eval \"\$(mise activate bash)\"${N}  ${D}# or zsh/fish${N}"
  fi
  say "  1. trust and install the toolchain:"
  say "       ${C}mise trust && mise install${N}"
  say "  2. enable features via GitHub repository variables"
  say "     ${D}(Settings > Secrets and variables > Actions > Variables)${N}:"
  say "       ${C}ENABLE_COMPILE=true  ENABLE_LINT=true  ENABLE_UNIT_TESTS=true  ENABLE_GITHUB_RELEASE=true${N}"
  say "  3. customize the stub scripts for your tech stack ${D}(docs/CUSTOMIZATION.md)${N}:"
  say "       ${D}scripts/ci/build/ci-10-compile.sh, scripts/ci/build/ci-20-lint.sh,${N}"
  say "       ${D}scripts/ci/test/ci-10-unit-tests.sh, ...${N}"
  if [ "$MODE" = "git" ]; then
    say "  4. review the integration commit:  ${C}git show --stat HEAD${N}"
    say "  5. push to activate the pipelines: ${C}git push${N}"
  elif git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    say "  4. review, commit and push:"
    say "       ${C}git add -A && git commit -m 'chore: add CI/CD pipeline' && git push${N}"
  else
    say "  4. put the project under git and push:"
    say "       ${C}git init && git add -A && git commit -m 'chore: add CI/CD pipeline'${N}"
  fi
  say ""
  say "  manage the integration later:"
  say "    ${C}./scripts/setup/ci-status.sh${N}    ${D}# show installed/available versions${N}"
  say "    ${C}./scripts/setup/ci-upgrade.sh${N}   ${D}# selective upgrade (respects $CONFIG_FILE)${N}"
  say "    ${C}./scripts/setup/ci-rollback.sh${N}  ${D}# revert the last integration/upgrade${N}"
  say ""
  say "  ${D}documentation: $CI_REMOTE_URL${N}"
  say ""
}

# --- main ------------------------------------------------------------------------

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --remote)
        CI_REMOTE_URL="$2"
        shift 2
        ;;
      --branch)
        CI_BRANCH="$2"
        shift 2
        ;;
      --name)
        CI_REMOTE_NAME="$2"
        shift 2
        ;;
      --dir)
        TARGET_DIR="$2"
        shift 2
        ;;
      --mode)
        MODE="$2"
        shift 2
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --force)
        FORCE=true
        shift
        ;;
      --yes | -y)
        ASSUME_YES=true
        shift
        ;;
      --help | -h)
        usage
        exit 0
        ;;
      *)
        die "unknown option: $1 (see --help)"
        ;;
    esac
  done

  case "$MODE" in auto | git | copy) ;; *) die "invalid --mode: $MODE (expected auto, git or copy)" ;; esac
  [ -d "$TARGET_DIR" ] || die "target is not a directory: $TARGET_DIR"

  check_platform
  cd "$TARGET_DIR"

  if [ "$MODE" = "auto" ]; then
    if have git && git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
      MODE="git"
    else
      MODE="copy"
    fi
  fi

  local dry_label=""
  [ "$DRY_RUN" = true ] && dry_label=" ${Y}(dry run)${N}"

  say ""
  say "  ${W}ci-excellence${N} ${D}installer${N}"
  say ""
  kv "target" "$PWD"
  kv "source" "$CI_REMOTE_URL ${D}($CI_BRANCH)${N}"
  kv "mode" "$MODE$dry_label"
  say ""

  if [ "$MODE" = "copy" ] && ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    say "  ${D}not a git repository - using copy mode${N}"
    say "  ${D}(for upgrade/rollback support: git init, commit, then re-run this installer)${N}"
    say ""
  fi

  check_mise

  if [ "$MODE" = "git" ]; then
    install_git_mode
  else
    install_copy_mode
  fi

  [ "$DRY_RUN" = true ] || print_next_steps
}

main "$@"
