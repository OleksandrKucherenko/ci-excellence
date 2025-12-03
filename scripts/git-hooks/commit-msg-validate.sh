#!/usr/bin/env bash
# Validate commit message against Conventional Commits standard
# https://www.conventionalcommits.org/

set -euo pipefail

COMMIT_MSG_FILE="$1"
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Skip validation for merge commits
if echo "$COMMIT_MSG" | grep -qE "^Merge (branch|remote)"; then
    echo -e "${GREEN}✓ Merge commit detected, skipping validation${NC}"
    exit 0
fi

# Skip validation for revert commits
if echo "$COMMIT_MSG" | grep -qE "^Revert "; then
    echo -e "${GREEN}✓ Revert commit detected, skipping validation${NC}"
    exit 0
fi

# Conventional Commits pattern
# Format: <type>[optional scope]: <description>
#
# [optional body]
#
# [optional footer(s)]
#
# Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
PATTERN='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?(!)?:\s.{1,}'

# Extract first line (subject)
FIRST_LINE=$(echo "$COMMIT_MSG" | head -n 1)

# Validate commit message format
if ! echo "$FIRST_LINE" | grep -qE "$PATTERN"; then
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}✗ Invalid commit message format${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}Your commit message:${NC}"
    echo -e "  ${FIRST_LINE}"
    echo ""
    echo -e "${BLUE}Expected format:${NC}"
    echo -e "  ${BLUE}<type>[optional scope]: <description>${NC}"
    echo ""
    echo -e "${BLUE}Valid types:${NC}"
    echo -e "  ${GREEN}feat${NC}     - A new feature"
    echo -e "  ${GREEN}fix${NC}      - A bug fix"
    echo -e "  ${GREEN}docs${NC}     - Documentation only changes"
    echo -e "  ${GREEN}style${NC}    - Changes that don't affect code meaning (formatting, etc.)"
    echo -e "  ${GREEN}refactor${NC} - Code change that neither fixes a bug nor adds a feature"
    echo -e "  ${GREEN}perf${NC}     - Performance improvement"
    echo -e "  ${GREEN}test${NC}     - Adding or updating tests"
    echo -e "  ${GREEN}build${NC}    - Changes to build system or dependencies"
    echo -e "  ${GREEN}ci${NC}       - Changes to CI configuration files and scripts"
    echo -e "  ${GREEN}chore${NC}    - Other changes that don't modify src or test files"
    echo -e "  ${GREEN}revert${NC}   - Reverts a previous commit"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo -e "  ${GREEN}feat: add user authentication${NC}"
    echo -e "  ${GREEN}fix(api): resolve timeout issue${NC}"
    echo -e "  ${GREEN}docs: update installation guide${NC}"
    echo -e "  ${GREEN}feat!: breaking change in API${NC}"
    echo ""
    echo -e "${YELLOW}Tip: Use 'cz commit' or 'git cz' for guided commit message creation${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 1
fi

# Validate subject line length (recommended max 72 characters, warning at 50)
SUBJECT_LENGTH=${#FIRST_LINE}
if [ "$SUBJECT_LENGTH" -gt 72 ]; then
    echo -e "${YELLOW}⚠️  Warning: Commit subject is ${SUBJECT_LENGTH} characters (recommended max: 72)${NC}"
    echo -e "${YELLOW}   Consider making it more concise${NC}"
fi

# Check for proper capitalization (description should be lowercase)
if echo "$FIRST_LINE" | grep -qE '^[a-z]+(\(.+\))?(!)?:\s+[A-Z]'; then
    echo -e "${YELLOW}⚠️  Warning: Commit description should start with lowercase${NC}"
    echo -e "${YELLOW}   Example: 'feat: add feature' not 'feat: Add feature'${NC}"
fi

# Check for period at the end (should not have one)
if echo "$FIRST_LINE" | grep -qE '\.$'; then
    echo -e "${YELLOW}⚠️  Warning: Commit subject should not end with a period${NC}"
fi

echo -e "${GREEN}✓ Commit message follows Conventional Commits standard${NC}"
exit 0
