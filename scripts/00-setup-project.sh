#!/usr/bin/env bash

# Exit on error, undefined variable - error, pipefail - error in pipes
set -e -u -o pipefail

# Mise Setup: Pre-configure project folders
# Purpose: Create necessary directories for local development, verify project setup
# Called automatically when entering the project directory

export FOUND_ERRORS=0

# Check for CRLF line endings in shell scripts (causes ZSH parsing errors)
check_crlf_line_endings() {
    local has_crlf=0
    local affected_files=()
    
    # Find shell scripts and ZSH plugins with CRLF line endings
    while IFS= read -r -d '' file; do
        if grep -q $'\r' "$file" 2>/dev/null; then
            affected_files+=("$file")
            has_crlf=1
        fi
    done < <(find . -type f \( -name "*.sh" -o -name "*.bash" -o -name "*.zsh" \) -not -path "./.git/*" -print0 2>/dev/null)
    
    if [ $has_crlf -eq 1 ]; then
        echo "⚠️  CRLF line endings detected in shell scripts!"
        echo "   This causes ZSH errors like: 'bad [key]=value syntax' or 'command not found:'"
        echo ""
        echo "   Affected files:"
        for f in "${affected_files[@]}"; do
            echo "     - $f"
        done
        echo ""
        echo "   To fix, run one of:"
        echo "     sed -i 's/\\r\$//' <file>           # Linux"
        echo "     sed -i '' 's/\\r\$//' <file>        # macOS"
        echo "     dos2unix <file>                    # if dos2unix is installed"
        echo ""
        echo "   Or renormalize the entire repo:"
        echo "     git add --renormalize . && git checkout -- ."
        echo ""
        export FOUND_ERRORS=$(( FOUND_ERRORS+1 ))
    fi
}

check_crlf_line_endings

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
    : echo "✅ Project is ready for development!"
fi

exit 0