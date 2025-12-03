#!/usr/bin/env bash
# Local CI Test Runner
# Execute CI workflows locally with different scenarios and mock states

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKFLOWS_DIR="${PROJECT_ROOT}/.github/workflows"
SCENARIOS_DIR="${PROJECT_ROOT}/test/scenarios"
RESULTS_DIR="${PROJECT_ROOT}/.ci-test-results"

# Source mock framework
# shellcheck source=lib/mock-framework.sh
source "${SCRIPT_DIR}/lib/mock-framework.sh"

# ============================================================================
# Colors and Output
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${BOLD}  $*${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $*${NC}"
}

print_error() {
    echo -e "${RED}❌ $*${NC}" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠️  $*${NC}" >&2
}

print_info() {
    echo -e "${BLUE}ℹ️  $*${NC}"
}

print_job() {
    echo -e "\n${BOLD}▶ $*${NC}"
}

# ============================================================================
# Usage
# ============================================================================

usage() {
    cat <<EOF
Local CI Test Runner

Usage:
  $0 [OPTIONS] <workflow> [scenario]

Arguments:
  workflow              Workflow name (pre-release, release, post-release, maintenance)
  scenario              Scenario file name (without .yml) or inline scenario

Options:
  -l, --list            List available workflows and scenarios
  -v, --verbose         Enable verbose output
  -m, --mock            Enable mock mode (default: true in test mode)
  -t, --timeout <sec>   Global timeout for all jobs (default: 3600)
  -j, --job <name>      Run only specific job(s) (can specify multiple)
  -s, --state <state>   Override all job states (ok, failed, stuck, random)
  -d, --delay <sec>     Add delay to all jobs (default: 0)
  -o, --output <dir>    Output directory for results (default: .ci-test-results)
  -h, --help            Show this help message

Examples:
  # List available workflows and scenarios
  $0 --list

  # Run pre-release workflow with all jobs succeeding
  $0 pre-release happy-path

  # Run pre-release workflow with unit tests failing
  $0 pre-release --state failed --job unit-tests

  # Run release workflow with specific scenario
  $0 release major-release

  # Run specific job with stuck state
  $0 pre-release --job lint --state stuck

  # Run all jobs with random states
  $0 maintenance --state random

EOF
}

# ============================================================================
# Workflow and Scenario Discovery
# ============================================================================

list_workflows() {
    print_header "Available Workflows"
    for workflow in "${WORKFLOWS_DIR}"/*.yml; do
        local name
        name=$(basename "$workflow" .yml)
        echo "  • ${name}"
    done
}

list_scenarios() {
    print_header "Available Scenarios"
    if [[ -d "$SCENARIOS_DIR" ]]; then
        for scenario in "${SCENARIOS_DIR}"/*.yml; do
            if [[ -f "$scenario" ]]; then
                local name
                name=$(basename "$scenario" .yml)
                echo "  • ${name}"
            fi
        done
    else
        print_warning "No scenarios directory found at: ${SCENARIOS_DIR}"
    fi
}

# ============================================================================
# Workflow Parsing
# ============================================================================

# Extract jobs from workflow file
get_workflow_jobs() {
    local workflow_file="$1"

    # Simple YAML parsing for jobs section
    # This is a basic implementation - for production, consider using yq
    awk '
        /^jobs:/ { in_jobs=1; next }
        in_jobs && /^[[:space:]]*[a-zA-Z0-9_-]+:/ {
            match($0, /^[[:space:]]*([a-zA-Z0-9_-]+):/, arr)
            print arr[1]
        }
        in_jobs && /^[a-zA-Z]/ && !/^[[:space:]]/ { in_jobs=0 }
    ' "$workflow_file"
}

# Get script for a specific job
get_job_script() {
    local workflow="$1"
    local job="$2"

    # Map common job names to script paths
    case "$job" in
        setup)
            echo "${SCRIPT_DIR}/ci/setup/ci-01-install-tools.sh"
            ;;
        compile|build)
            echo "${SCRIPT_DIR}/ci/build/ci-01-compile.sh"
            ;;
        lint)
            echo "${SCRIPT_DIR}/ci/build/ci-02-lint.sh"
            ;;
        unit-tests)
            echo "${SCRIPT_DIR}/ci/test/ci-01-unit-tests.sh"
            ;;
        integration-tests)
            echo "${SCRIPT_DIR}/ci/test/ci-02-integration-tests.sh"
            ;;
        e2e-tests)
            echo "${SCRIPT_DIR}/ci/test/ci-03-e2e-tests.sh"
            ;;
        security-scan)
            echo "${SCRIPT_DIR}/ci/build/ci-03-security-scan.sh"
            ;;
        bundle)
            echo "${SCRIPT_DIR}/ci/build/ci-04-bundle.sh"
            ;;
        summary)
            echo "${SCRIPT_DIR}/ci/build/ci-05-summary-pre-release.sh"
            ;;
        notify)
            echo "${SCRIPT_DIR}/ci/notification/send-notifications.sh"
            ;;
        prepare|determine-version)
            echo "${SCRIPT_DIR}/ci/release/ci-01-determine-version.sh"
            ;;
        publish-npm|publish-github|publish-docker|publish-documentation)
            echo "${SCRIPT_DIR}/ci/release/publish-npm.sh"  # Example
            ;;
        cleanup)
            echo "${SCRIPT_DIR}/ci/maintenance/cleanup.sh"
            ;;
        *)
            echo ""  # Unknown job
            ;;
    esac
}

# ============================================================================
# Scenario Loading
# ============================================================================

load_scenario() {
    local scenario_name="$1"
    local scenario_file="${SCENARIOS_DIR}/${scenario_name}.yml"

    if [[ ! -f "$scenario_file" ]]; then
        print_warning "Scenario file not found: ${scenario_file}"
        return 1
    fi

    # Parse scenario file and export environment variables
    print_info "Loading scenario: ${scenario_name}"

    # Simple YAML parser for mock configurations
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue

        # Parse key-value pairs
        if [[ "$line" =~ ^[[:space:]]*([A-Z_]+):[[:space:]]*(.+) ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            export "${key}=${value}"
            print_info "  ${key}=${value}"
        fi
    done < "$scenario_file"
}

# ============================================================================
# Job Execution
# ============================================================================

run_job() {
    local workflow="$1"
    local job="$2"
    local timeout="${3:-600}"

    print_job "Running job: ${job}"

    local script
    script=$(get_job_script "$workflow" "$job")

    if [[ -z "$script" || ! -f "$script" ]]; then
        print_warning "Script not found for job: ${job}"
        return 0  # Skip unknown jobs
    fi

    local start_time
    start_time=$(date +%s)

    # Create job-specific log file
    local log_file="${RESULTS_DIR}/job-${job}.log"
    mkdir -p "$(dirname "$log_file")"

    # Run the script with timeout
    local exit_code=0
    if with_timeout "$timeout" bash "$script" > "$log_file" 2>&1; then
        exit_code=0
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_success "Job '${job}' completed successfully (${duration}s)"
    else
        exit_code=$?
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))

        if [[ $exit_code -eq 124 ]]; then
            print_error "Job '${job}' timed out after ${timeout}s"
        else
            print_error "Job '${job}' failed with exit code ${exit_code} (${duration}s)"
        fi

        # Show last 20 lines of log
        if [[ -s "$log_file" ]]; then
            print_info "Last 20 lines of output:"
            tail -n 20 "$log_file" | sed 's/^/  /'
        fi
    fi

    # Save result metadata
    cat > "${RESULTS_DIR}/job-${job}.json" <<EOF
{
  "job": "${job}",
  "workflow": "${workflow}",
  "exit_code": ${exit_code},
  "duration": ${duration},
  "log_file": "${log_file}",
  "timestamp": "$(date -Iseconds)"
}
EOF

    return $exit_code
}

# ============================================================================
# Workflow Execution
# ============================================================================

run_workflow() {
    local workflow="$1"
    local workflow_file="${WORKFLOWS_DIR}/${workflow}.yml"

    if [[ ! -f "$workflow_file" ]]; then
        print_error "Workflow file not found: ${workflow_file}"
        return 1
    fi

    print_header "Running Workflow: ${workflow}"
    print_info "Workflow file: ${workflow_file}"
    print_info "Results directory: ${RESULTS_DIR}"

    # Clean results directory
    rm -rf "${RESULTS_DIR}"
    mkdir -p "${RESULTS_DIR}"

    # Get all jobs
    local jobs
    mapfile -t jobs < <(get_workflow_jobs "$workflow_file")

    if [[ ${#jobs[@]} -eq 0 ]]; then
        print_warning "No jobs found in workflow"
        return 0
    fi

    print_info "Found ${#jobs[@]} jobs to execute"

    # Filter jobs if specific ones requested
    if [[ ${#SPECIFIC_JOBS[@]} -gt 0 ]]; then
        local filtered_jobs=()
        for job in "${jobs[@]}"; do
            for specific in "${SPECIFIC_JOBS[@]}"; do
                if [[ "$job" == "$specific" ]]; then
                    filtered_jobs+=("$job")
                    break
                fi
            done
        done
        jobs=("${filtered_jobs[@]}")
        print_info "Running ${#jobs[@]} specific jobs: ${jobs[*]}"
    fi

    # Run jobs
    local failed_jobs=()
    local successful_jobs=()
    local total_duration=0

    local workflow_start
    workflow_start=$(date +%s)

    for job in "${jobs[@]}"; do
        if run_job "$workflow" "$job" "$JOB_TIMEOUT"; then
            successful_jobs+=("$job")
        else
            failed_jobs+=("$job")
            if [[ "${FAIL_FAST:-false}" == "true" ]]; then
                print_error "Failing fast due to job failure"
                break
            fi
        fi
    done

    local workflow_end
    workflow_end=$(date +%s)
    total_duration=$((workflow_end - workflow_start))

    # Print summary
    print_header "Workflow Summary"
    echo "  Workflow: ${workflow}"
    echo "  Total Duration: ${total_duration}s"
    echo "  Successful Jobs: ${#successful_jobs[@]}"
    echo "  Failed Jobs: ${#failed_jobs[@]}"

    if [[ ${#successful_jobs[@]} -gt 0 ]]; then
        echo -e "\n${GREEN}Successful:${NC}"
        for job in "${successful_jobs[@]}"; do
            echo "  ✅ ${job}"
        done
    fi

    if [[ ${#failed_jobs[@]} -gt 0 ]]; then
        echo -e "\n${RED}Failed:${NC}"
        for job in "${failed_jobs[@]}"; do
            echo "  ❌ ${job}"
        done
        return 1
    fi

    print_success "Workflow completed successfully!"
    return 0
}

# ============================================================================
# Main
# ============================================================================

main() {
    # Default values
    MOCK_ENABLED=true
    MOCK_VERBOSE=false
    JOB_TIMEOUT=3600
    SPECIFIC_JOBS=()
    WORKFLOW=""
    SCENARIO=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -l|--list)
                list_workflows
                list_scenarios
                exit 0
                ;;
            -v|--verbose)
                MOCK_VERBOSE=true
                export MOCK_VERBOSE
                shift
                ;;
            -m|--mock)
                MOCK_ENABLED=true
                shift
                ;;
            -t|--timeout)
                JOB_TIMEOUT="$2"
                shift 2
                ;;
            -j|--job)
                SPECIFIC_JOBS+=("$2")
                shift 2
                ;;
            -s|--state)
                export MOCK_MODE="$2"
                shift 2
                ;;
            -d|--delay)
                export MOCK_DELAY="$2"
                shift 2
                ;;
            -o|--output)
                RESULTS_DIR="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                if [[ -z "$WORKFLOW" ]]; then
                    WORKFLOW="$1"
                elif [[ -z "$SCENARIO" ]]; then
                    SCENARIO="$1"
                else
                    print_error "Too many arguments"
                    usage
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Validate workflow
    if [[ -z "$WORKFLOW" ]]; then
        print_error "Workflow name required"
        usage
        exit 1
    fi

    # Export mock settings
    export MOCK_ENABLED

    # Load scenario if specified
    if [[ -n "$SCENARIO" ]]; then
        load_scenario "$SCENARIO" || true
    fi

    # Print mock configuration
    print_mock_config

    # Run the workflow
    run_workflow "$WORKFLOW"
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
