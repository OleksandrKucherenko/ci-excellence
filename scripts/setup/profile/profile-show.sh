#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env.local"
ALT_ENV_FILE="$PROJECT_ROOT/config/.env.local"

current_profile="staging"

if [[ -f "$ENV_FILE" ]] && grep -q '^DEPLOYMENT_PROFILE=' "$ENV_FILE"; then
  current_profile=$(grep '^DEPLOYMENT_PROFILE=' "$ENV_FILE" | tail -n1 | cut -d'=' -f2- | tr -d '"')
elif [[ -f "$ALT_ENV_FILE" ]] && grep -q '^DEPLOYMENT_PROFILE=' "$ALT_ENV_FILE"; then
  current_profile=$(grep '^DEPLOYMENT_PROFILE=' "$ALT_ENV_FILE" | tail -n1 | cut -d'=' -f2- | tr -d '"')
fi

echo "Current profile: $current_profile"
