#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

echo:Ops "Deploy"
ci:param ops "ENVIRONMENT" "${1:?Environment is required}"
ci:param ops "VERSION" "${2:?Version is required}"
ci:param ops "CONFIRM" "${3:-no}"

ENVIRONMENT="${1:?Environment is required}"
VERSION="${2:?Version is required}"
CONFIRM="${3:-no}"

if [ "$ENVIRONMENT" == "production" ] && [ "$CONFIRM" != "yes" ]; then
  echo:Ops "Error: Production deployment requires confirmation 'yes'"
  exit 1
fi

echo:Ops "Deploying ${VERSION} to ${ENVIRONMENT}..."
echo:Ops "Stub: deploy-${ENVIRONMENT} is awaiting project-specific implementation."

echo:Ops "Deploy Done"
