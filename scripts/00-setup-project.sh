#!/usr/bin/env bash

# Exit on error, undefined variable - error, pipefail - error in pipes
set -e -u -o pipefail

# Mise Setup: Pre-configure project folders
# Purpose: Create necessary directories for local development, verify project setup
# Called automatically when entering the project directory

export FOUND_ERRORS=0

# Check if age key exists
[ ! -f ".secrets/mise-age.txt" ] && export FOUND_ERRORS=$(( FOUND_ERRORS+1 )) \
    && echo "⚠️  No age encryption key found! expected: $(pwd)/.secrets/mise-age.txt"

# Check if .env.secrets.json exists
[ ! -f ".env.secrets.json" ] && export FOUND_ERRORS=$(( FOUND_ERRORS+1 )) \
    && echo "⚠️  No encrypted secrets file found! expected: $(pwd)/.env.secrets.json"

# in case of detected errors, print path to the documentation
if [ $FOUND_ERRORS -gt 0 ]; then
    echo ""
    echo "Read: $(pwd)/docs/QUICKSTART.md"
else
    echo "✅ Project is ready for development!"
fi

exit 0