#!/usr/bin/env bash
set -euo pipefail

# CI Excellence: Upgrade to latest version
# Purpose: Fetch latest ci-excellence and selectively merge
# Usage: ./scripts/setup/ci-upgrade.sh [--force] [--dry-run]
#
# Normal mode: merge with review (shows diff before committing)
# Force mode:  override all included files, auto-commit
# Dry-run:     show what would change without applying

CONFIG_FILE=".ci-excellence.yml"
FORCE=false
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)   FORCE=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# --- Validate ---
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: $CONFIG_FILE not found."
  echo "Run ci-integrate.sh first."
  exit 1
fi

# --- Read config ---
CI_REMOTE_NAME="ci"
CI_BRANCH="dist"

# Parse remote name from git remotes (find one pointing to ci-excellence)
if git remote get-url ci &>/dev/null; then
  CI_REMOTE_NAME="ci"
elif git remote get-url ci-excellence &>/dev/null; then
  CI_REMOTE_NAME="ci-excellence"
else
  echo "Error: no ci-excellence remote found."
  echo "Run ci-integrate.sh first."
  exit 1
fi

# Parse branch from config
branch_line="$(grep '^branch:' "$CONFIG_FILE" 2>/dev/null || true)"
if [ -n "$branch_line" ]; then
  CI_BRANCH="$(echo "$branch_line" | sed 's/branch:[[:space:]]*//')"
fi

# Parse include/exclude (same parser as ci-integrate.sh)
INCLUDES=()
in_include=false
while IFS= read -r line; do
  if [[ "$line" =~ ^include: ]]; then in_include=true; continue; fi
  if [[ "$line" =~ ^[a-z] ]] && [ "$in_include" = true ]; then break; fi
  if [ "$in_include" = true ] && [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.*) ]]; then
    INCLUDES+=("${BASH_REMATCH[1]}")
  fi
done < "$CONFIG_FILE"

EXCLUDES=()
in_exclude=false
while IFS= read -r line; do
  if [[ "$line" =~ ^exclude: ]]; then in_exclude=true; continue; fi
  if [[ "$line" =~ ^[a-z] ]] && [ "$in_exclude" = true ]; then break; fi
  if [ "$in_exclude" = true ] && [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.*) ]]; then
    EXCLUDES+=("${BASH_REMATCH[1]}")
  fi
done < "$CONFIG_FILE"

# --- Current state ---
CURRENT_MERGE="$(git log --merges --format='%H' --grep='ci-excellence' -1 2>/dev/null || true)"
if [ -n "$CURRENT_MERGE" ]; then
  CURRENT_VERSION="$(git log -1 --format='%s' "$CURRENT_MERGE" | grep -oP '@ \K[a-f0-9]+')"
  echo "Current ci-excellence version: ${CURRENT_VERSION:-unknown}"
else
  echo "Current ci-excellence version: (initial integration)"
fi

# --- Fetch latest ---
echo "Fetching $CI_REMOTE_NAME/$CI_BRANCH..."
git fetch "$CI_REMOTE_NAME" "$CI_BRANCH"

NEW_VERSION="$(git rev-parse --short "$CI_REMOTE_NAME/$CI_BRANCH")"
NEW_FULL="$(git rev-parse "$CI_REMOTE_NAME/$CI_BRANCH")"
echo "Latest available: $NEW_VERSION"

# Check if already up to date
if [ -n "$CURRENT_MERGE" ]; then
  if git merge-base --is-ancestor "$CI_REMOTE_NAME/$CI_BRANCH" HEAD 2>/dev/null; then
    echo "Already up to date."
    exit 0
  fi
fi

# --- Show changelog ---
echo ""
echo "Changes since last integration:"
if [ -n "$CURRENT_MERGE" ]; then
  git log --oneline "$CURRENT_MERGE".."$CI_REMOTE_NAME/$CI_BRANCH" 2>/dev/null || echo "  (unable to determine changes)"
else
  git log --oneline "$CI_REMOTE_NAME/$CI_BRANCH" -10 2>/dev/null
  echo "  ... (showing last 10 commits)"
fi
echo ""

# --- Dry run: show what would change ---
if [ "$DRY_RUN" = true ]; then
  echo "=== DRY RUN: Files that would be updated ==="
  for path in "${INCLUDES[@]}"; do
    if git diff HEAD "$CI_REMOTE_NAME/$CI_BRANCH" -- "$path" --stat 2>/dev/null | head -5; then
      true
    fi
  done
  echo "=== End dry run ==="
  exit 0
fi

# --- Merge ---
echo "Merging ci-excellence @ $NEW_VERSION..."

# Record merge lineage but keep local files
git merge -s ours --no-commit "$CI_REMOTE_NAME/$CI_BRANCH" 2>/dev/null || true

# Checkout included files from upstream
for path in "${INCLUDES[@]}"; do
  git checkout "$CI_REMOTE_NAME/$CI_BRANCH" -- "$path" 2>/dev/null || true
done

# Remove excluded files from staging
for path in "${EXCLUDES[@]}"; do
  git reset HEAD -- "$path" 2>/dev/null || true
  git checkout -- "$path" 2>/dev/null || true
done

# --- Review or force commit ---
echo ""
echo "=== Changes to be applied ==="
git diff --cached --stat
echo ""

if [ "$FORCE" = true ]; then
  echo "Force mode: auto-committing..."
  git commit -m "ci: upgrade ci-excellence to $NEW_VERSION

Source: $NEW_FULL
Mode: force (all included files overwritten)"
  echo "Upgrade complete (forced)."
else
  echo "Review the changes above."
  echo "  To see full diff: git diff --cached"
  echo "  To commit:        git commit -m 'ci: upgrade ci-excellence to $NEW_VERSION'"
  echo "  To abort:         git merge --abort"
fi
