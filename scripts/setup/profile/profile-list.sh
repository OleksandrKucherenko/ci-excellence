#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ENVIRONMENTS_DIR="$PROJECT_ROOT/environments"

if [[ ! -d "$ENVIRONMENTS_DIR" ]]; then
  echo "No environments directory found at $ENVIRONMENTS_DIR" >&2
  exit 1
fi

echo "Available profiles:"
echo "  (default) staging"
echo "  production"

while IFS= read -r -d '' dir; do
  name="$(basename "$dir")"
  if [[ "$name" == "staging" || "$name" == "production" ]]; then
    continue
  fi
  echo "  $name"
done < <(find "$ENVIRONMENTS_DIR" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
