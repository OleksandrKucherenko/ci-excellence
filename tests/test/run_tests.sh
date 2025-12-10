#!/usr/bin/env bash
# Test Orchestration Runner Script
# Convenience wrapper that calls the unified test runner for test domain

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
UNIFIED_RUNNER="$TESTS_DIR/run_all_tests.sh"

# Check if unified runner exists
if [[ ! -f "$UNIFIED_RUNNER" ]]; then
    echo -e "${RED}Error: Unified test runner not found: $UNIFIED_RUNNER${NC}" >&2
    exit 1
fi

echo -e "${BLUE}=== CI Test Orchestration Runner ===${NC}"
echo -e "${YELLOW}This script now delegates to the unified test runner.${NC}"
echo -e "${YELLOW}Use '$0 --help' to see available options.${NC}"
echo

# Forward all arguments to the unified runner with test domain
exec "$UNIFIED_RUNNER" test "$@"