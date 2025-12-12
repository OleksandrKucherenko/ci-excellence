#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ENVIRONMENTS_DIR="$PROJECT_ROOT/environments"
ENV_FILE="$PROJECT_ROOT/.env.local"

if [[ $# -lt 1 ]]; then
  echo "Usage: $(basename "$0") <profile-name>" >&2
  echo "Example: $(basename "$0") staging" >&2
  echo "Available profiles:" >&2
  find "$ENVIRONMENTS_DIR" -mindepth 1 -maxdepth 1 -type d -printf "  - %f\n" >&2
  exit 1
fi

TARGET_PROFILE="${1:-}"

if [[ ! -d "$ENVIRONMENTS_DIR/$TARGET_PROFILE" ]]; then
  echo "Profile '$TARGET_PROFILE' does not exist under $ENVIRONMENTS_DIR" >&2
  exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
  cat > "$ENV_FILE" <<EOF_ENV
# Local environment overrides
DEPLOYMENT_PROFILE="$TARGET_PROFILE"
DEPLOYMENT_REGION=""
EOF_ENV
else
  tmp_file="${ENV_FILE}.tmp"
  awk -v profile="$TARGET_PROFILE" '
    BEGIN { updated=0 }
    /^DEPLOYMENT_PROFILE=/ { print "DEPLOYMENT_PROFILE=\"" profile "\""; updated=1; next }
    { print }
    END { if (updated==0) print "DEPLOYMENT_PROFILE=\"" profile "\"" }
  ' "$ENV_FILE" > "$tmp_file"
  mv "$tmp_file" "$ENV_FILE"
fi

echo "Active profile set to '$TARGET_PROFILE'"
