#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Pipeline Stub: Generate Release Notes
# Purpose: Generate release notes for GitHub release
# Customize this script based on your release notes format

VERSION="${CI_VERSION:?CI_VERSION is required}"

echo:Release "Generating Release Notes"
ci:param release "CI_VERSION" "$VERSION"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply


# Example: Extract from CHANGELOG.md
# if [ -f "CHANGELOG.md" ]; then
#     # Extract the section for this version
#     sed -n "/## \[$VERSION\]/,/## \[/p" CHANGELOG.md | sed '$ d'
# fi

# Example: Generate from git commits
# PREVIOUS_TAG=$(git describe --tags --abbrev=0 HEAD^ 2>/dev/null || echo "")
# if [ -n "$PREVIOUS_TAG" ]; then
#     echo "## Changes since $PREVIOUS_TAG"
#     echo ""
#     git log "$PREVIOUS_TAG"..HEAD --pretty=format:"- %s (%h)" --reverse
# else
#     echo "## Changes in $VERSION"
#     echo ""
#     git log --pretty=format:"- %s (%h)" --reverse
# fi

# Stub release notes
cat <<EOF
## Release $VERSION

### What's New

- This is a stub release
- Customize release notes in scripts/ci/release/ci-25-generate-release-notes.sh

### Installation

\`\`\`bash
npm install mypackage@$VERSION
\`\`\`

### Full Changelog

See [CHANGELOG.md](CHANGELOG.md) for detailed changes.
EOF

echo:Success "Release Notes Generated"
