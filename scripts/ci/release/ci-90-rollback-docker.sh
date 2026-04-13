#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Pipeline Stub: Rollback Docker Release
# Purpose: Tag Docker images as deprecated
# Customize this script based on your rollback strategy

VERSION="${CI_VERSION:?CI_VERSION is required}"

echo:Release "Rolling Back Docker Release"
ci:param release "CI_VERSION" "$VERSION"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply


# Example: Tag image as deprecated
# IMAGE_NAME="myorg/myapp"
#
# echo "Tagging image as deprecated..."
# docker pull "$IMAGE_NAME:$VERSION"
# docker tag "$IMAGE_NAME:$VERSION" "$IMAGE_NAME:deprecated-$VERSION"
# docker push "$IMAGE_NAME:deprecated-$VERSION"
#
# # Note: You cannot delete tags from Docker Hub directly,
# # but you can create a deprecated tag and update the README

# Example: Update image description to warn users
# This typically requires using Docker Hub API or web interface

# Add your Docker rollback commands here
echo:Success "✓ Docker rollback stub executed"
echo:Release "  Customize this script in scripts/ci/release/ci-90-rollback-docker.sh"
echo:Release "  Note: Docker tags cannot be deleted from registries"
echo:Release "  Consider updating image description or documentation"

echo:Success "Docker Rollback Complete"
