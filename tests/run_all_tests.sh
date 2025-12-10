#!/bin/bash
# Unified Test Runner for CI Excellence Test Suite
# Consolidated runner supporting all test domains with mock system integration

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Configuration
readonly TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"

# Test domains
declare -A TEST_DOMAINS=(
    ["build"]="build"
    ["deployment"]="deployment"
    ["hooks"]="hooks"
    ["setup"]="setup"
    ["test"]="test"
    ["mise"]="."
)

# Default options
VERBOSE=false
PARALLEL_JOBS=1
FILTER_PATTERN=""
REPORT_FORMAT="pretty"
OUTPUT_DIR="$TEST_DIR/test-results"
GENERATE_COVERAGE=false
KEEP_TMP=false
DEBUG=false
FOCUS=false
TIMING=false
DOMAIN="all"
SPECIFIC_TESTS=()

# Show usage information
show_help() {
    cat << EOF
Unified Test Runner for CI Excellence

Usage: $0 [OPTIONS] [DOMAIN] [TEST_FILES...]

DOMAINS:
    all            Run all test domains (default)
    build          Build script tests
    deployment     Deployment and release tests
    hooks          Git hooks tests
    setup          Setup script tests
    test           CI orchestration tests
    mise           MISE profile management tests

OPTIONS:
    -v, --verbose           Show verbose output
    -j, --parallel N        Run tests in parallel with N jobs (default: 4)
    -f, --filter PATTERN    Run tests matching pattern
    -t, --timing            Show timing information
    -p, --preserve          Preserve temporary directories on failure
    -F, --focus             Run only tests marked with # bats:focus
    -r, --report-format FORMAT Report format (pretty, tap, junit)
    -o, --output DIR        Output directory for reports
    -c, --coverage          Generate test coverage report
    -k, --keep-tmp          Keep temporary test directories
    -d, --debug             Enable debug mode
    -h, --help              Show this help message

EXAMPLES:
    # Run all tests
    $0

    # Run specific domain
    $0 build
    $0 deployment

    # Run with options
    $0 -v -j 4 --timing all
    $0 build -f "compile"

    # Run specific test file
    $0 build build/compile_spec.bats

    # Focus on specific tests
    $0 -F

ENVIRONMENT VARIABLES:
    DEBUG=true              Enable debug output
    DEBUG_MOCKS=true        Show mock command calls
    CI_TEST_MODE           Set test behavior (DRY_RUN, PASS, FAIL, etc.)
    BATSLIB_TEMP_PRESERVE_ON_FAILURE=1  Preserve temp dirs on failure

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                VERBOSE=true
                export BATS_VERBOSE_LEVEL=2
                shift
                ;;
            -j|--parallel)
                PARALLEL_JOBS="${2:-4}"
                shift 2
                ;;
            -f|--filter)
                FILTER_PATTERN="$2"
                shift 2
                ;;
            -t|--timing)
                TIMING=true
                shift
                ;;
            -p|--preserve)
                KEEP_TMP=true
                export BATSLIB_TEMP_PRESERVE_ON_FAILURE=1
                shift
                ;;
            -F|--focus)
                FOCUS=true
                export BATS_NO_FAIL_FOCUS_RUN=1
                shift
                ;;
            -r|--report-format)
                REPORT_FORMAT="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -c|--coverage)
                GENERATE_COVERAGE=true
                shift
                ;;
            -k|--keep-tmp)
                KEEP_TMP=true
                shift
                ;;
            -d|--debug)
                DEBUG=true
                export BATS_DEBUG=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                echo -e "${RED}Error: Unknown option $1${NC}" >&2
                echo "Use -h or --help for usage information" >&2
                exit 1
                ;;
            *)
                # Check if it's a domain
                if [[ -n "${TEST_DOMAINS[$1]:-}" ]]; then
                    DOMAIN="$1"
                    shift
                # Otherwise, treat as test file
                else
                    SPECIFIC_TESTS+=("$1")
                    shift
                fi
                ;;
        esac
    done
}

# Check if BATS is installed
check_bats() {
    if ! command -v bats >/dev/null 2>&1; then
        echo -e "${RED}Error: BATS is not installed${NC}" >&2
        echo "Install BATS using your package manager or from https://github.com/bats-core/bats-core" >&2
        exit 1
    fi
}

# Get test directory for domain
get_test_dir() {
    local domain="$1"
    if [[ "$domain" == "mise" ]]; then
        echo "$TEST_DIR"
    else
        echo "$TEST_DIR/${TEST_DOMAINS[$domain]}"
    fi
}

# Get test files for domain
get_test_files() {
    local domain="$1"
    local test_dir
    test_dir=$(get_test_dir "$domain")

    if [[ ! -d "$test_dir" ]]; then
        echo -e "${YELLOW}Warning: Test directory not found: $test_dir${NC}" >&2
        return
    fi

    if [[ ${#SPECIFIC_TESTS[@]} -gt 0 ]]; then
        # Use specific test files
        for test_file in "${SPECIFIC_TESTS[@]}"; do
            if [[ -f "$test_dir/$test_file" ]]; then
                echo "$test_dir/$test_file"
            elif [[ -f "$test_file" ]]; then
                echo "$test_file"
            else
                echo -e "${YELLOW}Warning: Test file not found: $test_file${NC}" >&2
            fi
        done
    else
        # Find all .bats files in the domain directory
        find "$test_dir" -name "*.bats" -type f | sort
    fi
}

# Build BATS command
build_bats_command() {
    local test_files=("$@")
    local bats_cmd="bats"

    # Add options
    if [[ "$VERBOSE" == true ]]; then
        bats_cmd="$bats_cmd --verbose"
    fi

    if [[ "$PARALLEL_JOBS" -gt 1 ]]; then
        bats_cmd="$bats_cmd --jobs $PARALLEL_JOBS"
    fi

    if [[ -n "$FILTER_PATTERN" ]]; then
        bats_cmd="$bats_cmd --filter \"$FILTER_PATTERN\""
    fi

    if [[ "$TIMING" == true ]]; then
        bats_cmd="$bats_cmd --timing"
    fi

    # Add report format
    case "$REPORT_FORMAT" in
        "junit")
            bats_cmd="$bats_cmd --report-formatter junit --output \"$OUTPUT_DIR\""
            ;;
        "tap")
            bats_cmd="$bats_cmd --tap"
            ;;
        "pretty"|"")
            # Default formatter
            ;;
        *)
            echo -e "${YELLOW}Warning: Unknown report format: $REPORT_FORMAT, using pretty format${NC}" >&2
            ;;
    esac

    # Add test files
    if [[ ${#test_files[@]} -gt 0 ]]; then
        bats_cmd="$bats_cmd ${test_files[*]}"
    fi

    echo "$bats_cmd"
}

# Setup test environment
setup_test_environment() {
    echo -e "${BLUE}=== Setting up test environment ===${NC}"

    # Create output directories
    mkdir -p "$OUTPUT_DIR"

    # Set environment variables for mock system
    export PROJECT_ROOT="$PROJECT_ROOT"
    export TESTS_DIR="$TEST_DIR"

    # Load mock system if available
    if [[ -f "$TEST_DIR/mocks/mock-loader.bash" ]]; then
        export MOCK_SYSTEM_AVAILABLE=true
    fi

    echo -e "${GREEN}✅ Test environment ready${NC}"
}

# Run tests for a domain
run_domain_tests() {
    local domain="$1"
    local test_dir
    test_dir=$(get_test_dir "$domain")

    if [[ ! -d "$test_dir" ]]; then
        echo -e "${YELLOW}Skipping domain '$domain': directory not found${NC}"
        return 0
    fi

    echo -e "${BLUE}=== Running $domain tests ===${NC}"

    # Get test files
    local test_files
    readarray -t test_files < <(get_test_files "$domain")

    if [[ ${#test_files[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No test files found for domain: $domain${NC}"
        return 0
    fi

    # Build and execute BATS command
    local bats_cmd
    bats_cmd=$(build_bats_command "${test_files[@]}")

    echo "Command: $bats_cmd"
    echo

    # Execute tests
    if eval "$bats_cmd"; then
        echo -e "${GREEN}✅ $domain tests passed!${NC}"
        return 0
    else
        local exit_code=$?
        echo -e "${RED}❌ $domain tests failed!${NC}"
        return $exit_code
    fi
}

# Generate coverage report
generate_coverage_report() {
    if [[ "$GENERATE_COVERAGE" != "true" ]]; then
        return 0
    fi

    echo -e "${BLUE}=== Generating coverage report ===${NC}"

    local coverage_file="$OUTPUT_DIR/coverage-report.txt"
    echo "CI Excellence Test Coverage Report" > "$coverage_file"
    echo "Generated: $(date)" >> "$coverage_file"
    echo "" >> "$coverage_file"

    local total_tests=0

    for domain in "${!TEST_DOMAINS[@]}"; do
        local test_dir
        test_dir=$(get_test_dir "$domain")

        if [[ -d "$test_dir" ]]; then
            local domain_tests
            domain_tests=$(find "$test_dir" -name "*.bats" -exec grep -c "^@test " {} \; 2>/dev/null | awk '{sum += $1} END {print sum}')
            total_tests=$((total_tests + domain_tests))
            echo "$domain: $domain_tests test cases" >> "$coverage_file"
        fi
    done

    echo "" >> "$coverage_file"
    echo "Total Test Cases: $total_tests" >> "$coverage_file"

    echo -e "${GREEN}✅ Coverage report generated: $coverage_file${NC}"
}

# Show final summary
show_summary() {
    local overall_exit_code=$1

    echo
    echo -e "${BLUE}=== Test Summary ===${NC}"

    if [[ $overall_exit_code -eq 0 ]]; then
        echo -e "${GREEN}🎉 All tests passed!${NC}"
    else
        echo -e "${RED}❌ Some tests failed!${NC}"
    fi

    echo
    echo "Test results directory: $OUTPUT_DIR"
    echo "Project root: $PROJECT_ROOT"

    if [[ "$GENERATE_COVERAGE" == "true" ]]; then
        echo "Coverage report: $OUTPUT_DIR/coverage-report.txt"
    fi

    if [[ -n "$FILTER_PATTERN" ]]; then
        echo "Filter pattern: $FILTER_PATTERN"
    fi
}

# Main function
main() {
    # Parse arguments
    parse_args "$@"

    # Check dependencies
    check_bats

    # Setup environment
    setup_test_environment

    # Run tests
    local overall_exit_code=0

    if [[ "$DOMAIN" == "all" ]]; then
        # Run all domains
        for domain in "${!TEST_DOMAINS[@]}"; do
            if ! run_domain_tests "$domain"; then
                overall_exit_code=1
            fi
        done
    else
        # Run specific domain
        if ! run_domain_tests "$DOMAIN"; then
            overall_exit_code=1
        fi
    fi

    # Generate coverage report if requested
    generate_coverage_report

    # Show summary
    show_summary $overall_exit_code

    exit $overall_exit_code
}

# Run main function with all arguments
main "$@"