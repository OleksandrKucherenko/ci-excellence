#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $(basename "$0") <profile-name> [--from <base-profile>]" >&2
  echo "Examples:" >&2
  echo "  $(basename "$0") sandbox --from staging" >&2
  echo "  $(basename "$0") canary --from production" >&2
}

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ENVIRONMENTS_DIR="$PROJECT_ROOT/environments"
DEFAULT_BASE="staging"

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

TARGET_NAME="$1"
shift || true
BASE_NAME="$DEFAULT_BASE"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from)
      BASE_NAME="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$TARGET_NAME" ]]; then
  echo "Profile name is required" >&2
  exit 1
fi

if [[ "$TARGET_NAME" == "staging" || "$TARGET_NAME" == "production" ]]; then
  echo "Creation of default profiles (staging/production) is not allowed" >&2
  exit 1
fi

BASE_DIR="$ENVIRONMENTS_DIR/$BASE_NAME"
TARGET_DIR="$ENVIRONMENTS_DIR/$TARGET_NAME"

if [[ ! -d "$BASE_DIR" ]]; then
  echo "Base profile '$BASE_NAME' not found under $ENVIRONMENTS_DIR" >&2
  exit 1
fi

if [[ -d "$TARGET_DIR" ]]; then
  echo "Profile '$TARGET_NAME' already exists" >&2
  exit 1
fi

mkdir -p "$ENVIRONMENTS_DIR"
cp -a "$BASE_DIR" "$TARGET_DIR"

# Ensure regions directory exists even if base lacked it
mkdir -p "$TARGET_DIR/regions"

echo "Profile '$TARGET_NAME' created from '$BASE_NAME' at $TARGET_DIR"
