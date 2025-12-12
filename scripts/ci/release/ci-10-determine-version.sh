#!/usr/bin/env bash
# set -euo pipefail # strict mode disabled for e-bash compatibility

# CI Script: Determine Version
# Purpose: Calculate next version based on release type using e-bash semver lib

RELEASE_TYPE="${1:-patch}"
PRE_RELEASE_TYPE="${2:-alpha}" 

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../" && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"

# Setup e-bash environment
if [ -z "${E_BASH:-}" ]; then
  export E_BASH="$LIB_DIR"
fi

# Source semver library
set +u
# shellcheck disable=SC1090
source "$LIB_DIR/_semver.sh"
set -u

# Get current version details
# Find the latest tag that looks like a semver version v*.*.*
# We use 'git describe' to find the closest reachable tag
if ! CURRENT_TAG=$(git describe --tags --match "v*" --abbrev=0 2>/dev/null); then
    echo "Warning: No existing tags found. Defaulting to 0.0.1-alpha" >&2
    CURRENT_TAG="v0.0.1-alpha"
fi

# Strip 'v' prefix if present
CURRENT_VERSION="${CURRENT_TAG#v}"

echo "Current Version: $CURRENT_VERSION" >&2
echo "Release Type: $RELEASE_TYPE" >&2

# Parse current version
semver:parse "$CURRENT_VERSION" "PARSED"

# Helper to reconstruct base version (major.minor.patch)
function get_base_version() {
    echo "${PARSED["major"]}.${PARSED["minor"]}.${PARSED["patch"]}"
}

NEW_VERSION=""

case "$RELEASE_TYPE" in
    major)
        NEW_VERSION=$(semver:increase:major "$CURRENT_VERSION")
        ;;
    minor)
        NEW_VERSION=$(semver:increase:minor "$CURRENT_VERSION")
        ;;
    patch)
        NEW_VERSION=$(semver:increase:patch "$CURRENT_VERSION")
        ;;
    premajor)
        # 1. Increment major
        NEXT_MAJOR=$(semver:increase:major "$CURRENT_VERSION")
        # 2. Append pre-release type (e.g. 1.0.0-alpha, not 1.0.0-alpha.1 per preference)
        NEW_VERSION="${NEXT_MAJOR}-${PRE_RELEASE_TYPE}"
        ;;
    preminor)
        NEXT_MINOR=$(semver:increase:minor "$CURRENT_VERSION")
        NEW_VERSION="${NEXT_MINOR}-${PRE_RELEASE_TYPE}"
        ;;
    prepatch)
        NEXT_PATCH=$(semver:increase:patch "$CURRENT_VERSION")
        NEW_VERSION="${NEXT_PATCH}-${PRE_RELEASE_TYPE}"
        ;;
    prerelease)
        # Handle existing pre-release increment
        CURRENT_PRE="${PARSED["pre-release"]}" # Includes leading dash e.g. "-alpha.1" or "-alpha"
        
        if [ -z "$CURRENT_PRE" ]; then
            # Not currently a pre-release, so start one (e.g. 1.2.3 -> 1.2.4-alpha)
            NEXT_PATCH=$(semver:increase:patch "$CURRENT_VERSION")
            NEW_VERSION="${NEXT_PATCH}-${PRE_RELEASE_TYPE}"
        else
            # Remove leading dash
            clean_pre="${CURRENT_PRE#-}"
            
            # Logic: 
            # If PRE_RELEASE_TYPE matches current (e.g. alpha -> alpha), increment number.
            # If different (e.g. alpha -> beta), keep version core, switch type, reset.
            
            if [[ "$clean_pre" == "${PRE_RELEASE_TYPE}" || "$clean_pre" == "${PRE_RELEASE_TYPE}."* ]]; then
                # Same type, increment number
                # Extract number. Assuming format "type.number" or just "type"
                prefix="${PRE_RELEASE_TYPE}."
                if [[ "$clean_pre" == "$PRE_RELEASE_TYPE" ]]; then
                   # "alpha" -> "alpha.1"
                   NEW_VERSION="$(get_base_version)-${PRE_RELEASE_TYPE}.1"
                else
                   number="${clean_pre#$prefix}"
                   if [[ "$number" =~ ^[0-9]+$ ]]; then
                       new_number=$((number + 1))
                       NEW_VERSION="$(get_base_version)-${PRE_RELEASE_TYPE}.${new_number}"
                   else
                       echo "Error: Cannot auto-increment complex pre-release identifier: $clean_pre" >&2
                       exit 1
                   fi
                fi
            else
                # Different type (e.g. alpha -> beta)
                # alpha -> beta (no .1)
                NEW_VERSION="$(get_base_version)-${PRE_RELEASE_TYPE}"
            fi
        fi
        ;;
    *)
        echo "Error: Unknown release type '$RELEASE_TYPE'" >&2
        exit 1
        ;;
esac

echo "Calculated Version: $NEW_VERSION" >&2
echo "$NEW_VERSION"
