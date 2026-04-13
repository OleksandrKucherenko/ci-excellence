#!/usr/bin/env bash
set -euo pipefail

# CI Excellence: First-time integration
# Purpose: Add ci-excellence as a remote and perform initial merge
# Usage: curl -sSL <raw-url>/ci-integrate.sh | bash
#    or: ./scripts/setup/ci-integrate.sh [--remote URL] [--branch BRANCH]
#
# This script:
# 1. Adds the ci-excellence remote
# 2. Fetches the dist branch
# 3. Creates .ci-excellence.yml config (if missing)
# 4. Performs initial selective merge
# 5. Commits with merge lineage to ci-excellence

# --- Configuration ---
CI_REMOTE_URL="${CI_REMOTE_URL:-https://github.com/OleksandrKucherenko/ci-excellence.git}"
CI_REMOTE_NAME="${CI_REMOTE_NAME:-ci}"
CI_BRANCH="${CI_BRANCH:-dist}"
CONFIG_FILE=".ci-excellence.yml"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --remote) CI_REMOTE_URL="$2"; shift 2 ;;
    --branch) CI_BRANCH="$2"; shift 2 ;;
    --name)   CI_REMOTE_NAME="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo "=== CI Excellence Integration ==="
echo "  Remote: $CI_REMOTE_URL"
echo "  Branch: $CI_BRANCH"
echo ""

# --- Step 1: Add remote ---
if git remote get-url "$CI_REMOTE_NAME" &>/dev/null; then
  echo "[1/5] Remote '$CI_REMOTE_NAME' already exists, updating URL..."
  git remote set-url "$CI_REMOTE_NAME" "$CI_REMOTE_URL"
else
  echo "[1/5] Adding remote '$CI_REMOTE_NAME'..."
  git remote add "$CI_REMOTE_NAME" "$CI_REMOTE_URL"
fi

# --- Step 2: Fetch ---
echo "[2/5] Fetching $CI_REMOTE_NAME/$CI_BRANCH..."
git fetch "$CI_REMOTE_NAME" "$CI_BRANCH"

# --- Step 3: Create config ---
if [ ! -f "$CONFIG_FILE" ]; then
  echo "[3/5] Creating $CONFIG_FILE..."
  cat > "$CONFIG_FILE" << YAML
# CI Excellence Integration Config
# Controls which files are included during ci-upgrade.sh
remote: $CI_REMOTE_URL
branch: $CI_BRANCH

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

# Uncomment to exclude specific files:
# exclude:
#   - .github/workflows/auto-fix-quality.yml
#   - .github/workflows/maintenance.yml
YAML
  git add "$CONFIG_FILE"
else
  echo "[3/5] $CONFIG_FILE already exists, skipping."
fi

# --- Step 4: Selective merge ---
echo "[4/5] Merging ci-excellence (selective)..."

# Record merge but keep all local files unchanged
git merge -s ours --no-commit --allow-unrelated-histories "$CI_REMOTE_NAME/$CI_BRANCH" 2>/dev/null || true

# Read include paths from config (simple grep, no yaml parser needed)
INCLUDES=()
in_include=false
while IFS= read -r line; do
  if [[ "$line" =~ ^include: ]]; then
    in_include=true
    continue
  fi
  if [[ "$line" =~ ^[a-z] ]] && [ "$in_include" = true ]; then
    break
  fi
  if [ "$in_include" = true ] && [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.*) ]]; then
    INCLUDES+=("${BASH_REMATCH[1]}")
  fi
done < "$CONFIG_FILE"

# Read exclude paths
EXCLUDES=()
in_exclude=false
while IFS= read -r line; do
  if [[ "$line" =~ ^exclude: ]]; then
    in_exclude=true
    continue
  fi
  if [[ "$line" =~ ^[a-z] ]] && [ "$in_exclude" = true ]; then
    break
  fi
  if [ "$in_exclude" = true ] && [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.*) ]]; then
    EXCLUDES+=("${BASH_REMATCH[1]}")
  fi
done < "$CONFIG_FILE"

# Checkout included files from ci remote
for path in "${INCLUDES[@]}"; do
  echo "  + $path"
  git checkout "$CI_REMOTE_NAME/$CI_BRANCH" -- "$path" 2>/dev/null || echo "    (not found, skipping)"
done

# Remove excluded files from staging
for path in "${EXCLUDES[@]}"; do
  echo "  - $path (excluded)"
  git reset HEAD -- "$path" 2>/dev/null || true
  git checkout -- "$path" 2>/dev/null || true
done

# --- Step 5: Commit ---
CI_VERSION="$(git rev-parse --short "$CI_REMOTE_NAME/$CI_BRANCH")"
echo "[5/5] Committing integration..."
git add "$CONFIG_FILE" 2>/dev/null || true
git commit -m "ci: integrate ci-excellence @ $CI_VERSION

Source: $(git rev-parse "$CI_REMOTE_NAME/$CI_BRANCH")
Files: ${#INCLUDES[@]} paths included, ${#EXCLUDES[@]} excluded"

echo ""
echo "=== Integration Complete ==="
echo "  CI Excellence version: $CI_VERSION"
echo "  Config: $CONFIG_FILE"
echo "  Included: ${#INCLUDES[@]} paths"
echo ""
echo "Next steps:"
echo "  1. Review changes: git diff HEAD~1"
echo "  2. Customize stubs in scripts/ci/ for your project"
echo "  3. Set ENABLE_* flags in GitHub repo variables"
echo "  4. Push to trigger pipelines"
echo ""
echo "To upgrade later: ./scripts/setup/ci-upgrade.sh"
echo "To rollback:      ./scripts/setup/ci-rollback.sh"
