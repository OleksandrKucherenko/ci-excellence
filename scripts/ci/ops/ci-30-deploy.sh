#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

ENVIRONMENT="${OPS_ENVIRONMENT:?OPS_ENVIRONMENT is required}"
VERSION="${OPS_VERSION:?OPS_VERSION is required}"
CONFIRM="${OPS_CONFIRM:-no}"

echo:Ops "Deploy"
ci:param ops "OPS_ENVIRONMENT" "$ENVIRONMENT"
ci:param ops "OPS_VERSION" "$VERSION"
ci:param ops "OPS_CONFIRM" "$CONFIRM"

if [ "$ENVIRONMENT" == "production" ] && [ "$CONFIRM" != "yes" ]; then
  echo:Error "Error: Production deployment requires confirmation 'yes'"
  exit 1
fi

echo:Ops "Deploying ${VERSION} to ${ENVIRONMENT}..."
echo:Ops "Stub: deploy-${ENVIRONMENT} is awaiting project-specific implementation."

echo:Success "Deploy Done"
