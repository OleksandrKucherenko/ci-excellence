#!/usr/bin/env bash
set -euo pipefail

# CI Excellence: Build distribution branch
# Purpose: Generate/update the `dist` branch with only distributable files
# Usage: ./scripts/setup/ci-dist.sh [--push]
#
# The dist branch is an orphan branch containing only the files
# that consumers need for CI Excellence integration.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DIST_BRANCH="dist"
PUSH="${1:-}"

cd "$REPO_ROOT"

# Files to include in distribution
DIST_FILES=(
  .github/workflows/
  scripts/ci/
  scripts/lib/
  scripts/setup/ci-integrate.sh
  scripts/setup/ci-upgrade.sh
  scripts/setup/ci-rollback.sh
  scripts/setup/ci-status.sh
  .env
  .actrc
  .shellspec
  .lefthook.toml
  .commitlintrc.yaml
  .cz.yaml
  .ebashrc
  mise.toml
  .config/mise/
)

# Record source commit
SOURCE_COMMIT="$(git rev-parse HEAD)"
SOURCE_SHORT="$(git rev-parse --short HEAD)"
SOURCE_MSG="$(git log -1 --format='%s' HEAD)"

echo "Building dist from main @ $SOURCE_SHORT ($SOURCE_MSG)"

# Create a temporary worktree for the dist branch
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

# Check if dist branch exists
if git show-ref --verify --quiet "refs/heads/$DIST_BRANCH"; then
  git worktree add "$WORK_DIR" "$DIST_BRANCH" 2>/dev/null
else
  # Create orphan branch
  git worktree add --detach "$WORK_DIR" 2>/dev/null
  cd "$WORK_DIR"
  git checkout --orphan "$DIST_BRANCH"
  git rm -rf . 2>/dev/null || true
  cd "$REPO_ROOT"
fi

# Clean the worktree
cd "$WORK_DIR"
git rm -rf . 2>/dev/null || true

# Copy distributable files from main
for path in "${DIST_FILES[@]}"; do
  src="$REPO_ROOT/$path"
  if [ -d "$src" ]; then
    mkdir -p "$WORK_DIR/$path"
    cp -a "$src"/. "$WORK_DIR/$path" 2>/dev/null || true
  elif [ -f "$src" ]; then
    mkdir -p "$(dirname "$WORK_DIR/$path")"
    cp "$src" "$WORK_DIR/$path"
  else
    echo "  SKIP: $path (not found)"
  fi
done

# Create a default .ci-excellence.yml template for consumers
cat > "$WORK_DIR/.ci-excellence.yml.template" << 'YAML'
# CI Excellence Integration Config
# Copy this to .ci-excellence.yml in your project root and customize.
remote: https://github.com/OleksandrKucherenko/ci-excellence.git
branch: dist

# Files to include during integration/upgrade
include:
  - .github/workflows/
  - scripts/ci/
  - scripts/lib/
  - scripts/setup/ci-integrate.sh
  - scripts/setup/ci-upgrade.sh
  - scripts/setup/ci-rollback.sh
  - scripts/setup/ci-status.sh
  - .env
  - .actrc
  - .lefthook.toml
  - .commitlintrc.yaml

# Files to exclude (subset of include, for fine-grained control)
# exclude:
#   - .github/workflows/auto-fix-quality.yml
#   - .github/workflows/maintenance.yml
YAML

# Stage and commit
cd "$WORK_DIR"
git add -A
if git diff --cached --quiet; then
  echo "No changes to distribute."
else
  LEFTHOOK=0 git commit --no-verify -m "dist: ci-excellence @ $SOURCE_SHORT

Source: $SOURCE_COMMIT
Message: $SOURCE_MSG"
  echo "Distribution branch updated."
fi

# Push if requested
if [ "$PUSH" = "--push" ]; then
  git push origin "$DIST_BRANCH"
  echo "Pushed to origin/$DIST_BRANCH"
fi

# Cleanup worktree
cd "$REPO_ROOT"
git worktree remove "$WORK_DIR" 2>/dev/null || true

echo "Done. Source: main @ $SOURCE_SHORT -> dist branch"
