#!/usr/bin/env bash
# Mock Loader System for BATS Testing
# Provides centralized management and loading of mock libraries

# Global variables for mock management
declare -a MOCK_LOADED_LIBRARIES=()
declare -A MOCK_CONFIGURATIONS
declare MOCK_BIN_DIR=""
declare MOCK_MODE="success"

# Initialize the mock loader system
init_mock_loader() {
    local mock_bin_dir="${1:-$BATS_TEST_TMPDIR/bin}"

    MOCK_BIN_DIR="$mock_bin_dir"
    mkdir -p "$MOCK_BIN_DIR"

    # Add mock bin directory to PATH
    export PATH="$MOCK_BIN_DIR:$PATH"

    # Initialize default configuration
    MOCK_CONFIGURATIONS=(
        ["mode"]="success"
        ["git_version"]="git version 2.42.0"
        ["npm_version"]="9.8.7"
        ["yarn_version"]="1.22.19"
        ["mise_version"]="2024.1.1"
        ["gitleaks_version"]="v8.18.2"
        ["trufflehog_version"]="3.81.0"
        ["shellcheck_version"]="ShellCheck - v0.9.0"
    )

    # Set environment variables from configuration
    for key in "${!MOCK_CONFIGURATIONS[@]}"; do
        export "MOCK_${key^^}"="${MOCK_CONFIGURATIONS[$key]}"
    done
}

# Load a specific mock library
load_mock_library() {
    local library_name="$1"
    local library_path=""

    # Determine library path
    if [[ -f "$library_name" ]]; then
        library_path="$library_name"
    elif [[ -f "${BATS_TEST_DIRNAME}/../mocks/${library_name}" ]]; then
        library_path="${BATS_TEST_DIRNAME}/../mocks/${library_name}"
    elif [[ -f "/mnt/wsl/workspace/ci-excellence/tests/mocks/${library_name}" ]]; then
        library_path="/mnt/wsl/workspace/ci-excellence/tests/mocks/${library_name}"
    else
        echo "Error: Mock library not found: $library_name" >&2
        return 1
    fi

    # Check if library is already loaded
    if [[ " ${MOCK_LOADED_LIBRARIES[*]} " =~ " ${library_name} " ]]; then
        return 0
    fi

    # Source the library
    source "$library_path"
    MOCK_LOADED_LIBRARIES+=("$library_name")

    return 0
}

# Load multiple mock libraries
load_mock_libraries() {
    local libraries=("$@")

    for library in "${libraries[@]}"; do
        load_mock_library "$library" || return 1
    done

    return 0
}

# Load all mock libraries
load_all_mock_libraries() {
    local libraries=(
        "git-mocks.bash"
        "package-manager-mocks.bash"
        "build-tool-mocks.bash"
        "cicd-tool-mocks.bash"
        "security-tool-mocks.bash"
        "filesystem-mocks.bash"
    )

    load_mock_libraries "${libraries[@]}"
}

# Create all mocks for loaded libraries
create_all_loaded_mocks() {
    local mode="${1:-$MOCK_MODE}"

    for library in "${MOCK_LOADED_LIBRARIES[@]}"; do
        case "$library" in
            "git-mocks.bash")
                create_git_mock "$MOCK_BIN_DIR" "$mode"
                ;;
            "package-manager-mocks.bash")
                create_all_package_manager_mocks "$MOCK_BIN_DIR" "$mode"
                ;;
            "build-tool-mocks.bash")
                create_all_build_tool_mocks "$MOCK_BIN_DIR" "$mode"
                ;;
            "cicd-tool-mocks.bash")
                create_all_cicd_tool_mocks "$MOCK_BIN_DIR" "$mode"
                ;;
            "security-tool-mocks.bash")
                create_all_security_tool_mocks "$MOCK_BIN_DIR" "$mode"
                ;;
            "filesystem-mocks.bash")
                create_all_filesystem_tool_mocks "$MOCK_BIN_DIR" "$mode"
                ;;
        esac
    done
}

# Set mock mode globally
set_mock_mode() {
    local mode="$1"
    MOCK_MODE="$mode"
    MOCK_CONFIGURATIONS["mode"]="$mode"
    export MOCK_MODE="$mode"
}

# Configure mock settings
configure_mock() {
    local key="$1"
    local value="$2"

    case "$key" in
        "mode"|"git_version"|"npm_version"|"yarn_version"|"mise_version"|"gitleaks_version"|"trufflehog_version"|"shellcheck_version")
            MOCK_CONFIGURATIONS["$key"]="$value"
            export "MOCK_${key^^}"="$value"
            ;;
        "profile"|"environment")
            # Special configurations for mise and other tools
            export "MOCK_${key^^}"="$value"
            ;;
        *)
            echo "Warning: Unknown mock configuration key: $key" >&2
            return 1
            ;;
    esac
}

# Get mock configuration value
get_mock_config() {
    local key="$1"

    if [[ -n "${MOCK_CONFIGURATIONS[$key]:-}" ]]; then
        echo "${MOCK_CONFIGURATIONS[$key]}"
    elif [[ -n "MOCK_${key^^:-}" ]]; then
        echo "${!MOCK_${key^^}}"
    else
        return 1
    fi
}

# Set mocks to failure mode
set_mocks_failure() {
    set_mock_mode "fail"

    # Update all loaded libraries to failure mode
    if [[ " ${MOCK_LOADED_LIBRARIES[*]} " =~ " git-mocks.bash " ]]; then
        set_git_mock_failure
    fi

    if [[ " ${MOCK_LOADED_LIBRARIES[*]} " =~ " package-manager-mocks.bash " ]]; then
        set_package_manager_mocks_failure
    fi

    if [[ " ${MOCK_LOADED_LIBRARIES[*]} " =~ " build-tool-mocks.bash " ]]; then
        set_build_tool_mocks_failure
    fi

    if [[ " ${MOCK_LOADED_LIBRARIES[*]} " =~ " cicd-tool-mocks.bash " ]]; then
        set_cicd_tool_mocks_failure
    fi

    if [[ " ${MOCK_LOADED_LIBRARIES[*]} " =~ " security-tool-mocks.bash " ]]; then
        set_security_tool_mocks_failure
    fi

    if [[ " ${MOCK_LOADED_LIBRARIES[*]} " =~ " filesystem-mocks.bash " ]]; then
        set_filesystem_tool_mocks_failure
    fi
}

# Clean up all mocks
cleanup_mocks() {
    # Clean up each loaded library
    if [[ " ${MOCK_LOADED_LIBRARIES[*]} " =~ " git-mocks.bash " ]]; then
        cleanup_git_mock
    fi

    if [[ " ${MOCK_LOADED_LIBRARIES[*]} " =~ " package-manager-mocks.bash " ]]; then
        cleanup_package_manager_mocks
    fi

    if [[ " ${MOCK_LOADED_LIBRARIES[*]} " =~ " build-tool-mocks.bash " ]]; then
        cleanup_build_tool_mocks
    fi

    if [[ " ${MOCK_LOADED_LIBRARIES[*]} " =~ " cicd-tool-mocks.bash " ]]; then
        cleanup_cicd_tool_mocks
    fi

    if [[ " ${MOCK_LOADED_LIBRARIES[*]} " =~ " security-tool-mocks.bash " ]]; then
        cleanup_security_tool_mocks
    fi

    if [[ " ${MOCK_LOADED_LIBRARIES[*]} " =~ " filesystem-mocks.bash " ]]; then
        cleanup_filesystem_tool_mocks
    fi

    # Clear global state
    MOCK_LOADED_LIBRARIES=()
    MOCK_CONFIGURATIONS=()

    # Clean up mock bin directory
    if [[ -d "$MOCK_BIN_DIR" ]]; then
        rm -rf "$MOCK_BIN_DIR"
    fi

    unset MOCK_MODE MOCK_BIN_DIR
}

# Show loaded libraries
show_loaded_mocks() {
    echo "Loaded Mock Libraries:"
    printf "  %s\n" "${MOCK_LOADED_LIBRARIES[@]}"
    echo ""
    echo "Mock Configuration:"
    for key in "${!MOCK_CONFIGURATIONS[@]}"; do
        printf "  %s: %s\n" "$key" "${MOCK_CONFIGURATIONS[$key]}"
    done
}

# Preset configurations for common scenarios
setup_mocks_for_git_operations() {
    load_mock_library "git-mocks.bash"
    load_mock_library "filesystem-mocks.bash"

    set_mock_mode "success"
    create_git_mock "$MOCK_BIN_DIR" "success"
    create_all_filesystem_tool_mocks "$MOCK_BIN_DIR" "success"
}

setup_mocks_for_nodejs_development() {
    load_mock_library "package-manager-mocks.bash"
    load_mock_library "git-mocks.bash"
    load_mock_library "filesystem-mocks.bash"

    setup_package_manager_for_nodejs_project
    create_all_filesystem_tool_mocks "$MOCK_BIN_DIR" "success"
}

setup_mocks_for_python_development() {
    load_mock_library "package-manager-mocks.bash"
    load_mock_library "git-mocks.bash"
    load_mock_library "filesystem-mocks.bash"

    # Configure for Python
    configure_mock "npm_version" "not-applicable"
    configure_mock "yarn_version" "not-applicable"
    create_all_filesystem_tool_mocks "$MOCK_BIN_DIR" "success"
}

setup_mocks_for_rust_development() {
    load_mock_library "build-tool-mocks.bash"
    load_mock_library "git-mocks.bash"
    load_mock_library "filesystem-mocks.bash"

    setup_build_tools_for_rust_project
    create_all_filesystem_tool_mocks "$MOCK_BIN_DIR" "success"
}

setup_mocks_for_go_development() {
    load_mock_library "build-tool-mocks.bash"
    load_mock_library "git-mocks.bash"
    load_mock_library "filesystem-mocks.bash"

    setup_build_tools_for_go_project
    create_all_filesystem_tool_mocks "$MOCK_BIN_DIR" "success"
}

setup_mocks_for_java_development() {
    load_mock_library "build-tool-mocks.bash"
    load_mock_library "git-mocks.bash"
    load_mock_library "filesystem-mocks.bash"

    setup_build_tools_for_java_project
    create_all_filesystem_tool_mocks "$MOCK_BIN_DIR" "success"
}

setup_mocks_for_ci_cd_pipeline() {
    load_all_mock_libraries

    setup_cicd_tools_for_development
    setup_security_tools_for_clean_scan

    create_all_loaded_mocks "success"
}

setup_mocks_for_security_scanning() {
    load_mock_library "security-tool-mocks.bash"
    load_mock_library "git-mocks.bash"
    load_mock_library "filesystem-mocks.bash"

    setup_security_tools_for_clean_scan
    create_all_filesystem_tool_mocks "$MOCK_BIN_DIR" "success"
}

setup_mocks_for_deployment() {
    load_mock_library "cicd-tool-mocks.bash"
    load_mock_library "git-mocks.bash"
    load_mock_library "build-tool-mocks.bash"
    load_mock_library "filesystem-mocks.bash"

    setup_cicd_tools_for_production
    create_all_loaded_mocks "success"
}

# Helper functions for BATS test integration
bats_setup_with_mocks() {
    local preset="${1:-default}"

    # Initialize mock loader
    init_mock_loader

    # Apply preset configuration
    case "$preset" in
        "git")
            setup_mocks_for_git_operations
            ;;
        "nodejs")
            setup_mocks_for_nodejs_development
            ;;
        "python")
            setup_mocks_for_python_development
            ;;
        "rust")
            setup_mocks_for_rust_development
            ;;
        "go")
            setup_mocks_for_go_development
            ;;
        "java")
            setup_mocks_for_java_development
            ;;
        "cicd")
            setup_mocks_for_ci_cd_pipeline
            ;;
        "security")
            setup_mocks_for_security_scanning
            ;;
        "deployment")
            setup_mocks_for_deployment
            ;;
        "all")
            load_all_mock_libraries
            create_all_loaded_mocks "success"
            ;;
        *)
            echo "Unknown preset: $preset" >&2
            echo "Available presets: git, nodejs, python, rust, go, java, cicd, security, deployment, all" >&2
            return 1
            ;;
    esac
}

bats_teardown_with_mocks() {
    cleanup_mocks
}

# Export functions for use in BATS tests
export -f init_mock_loader
export -f load_mock_library
export -f load_mock_libraries
export -f load_all_mock_libraries
export -f create_all_loaded_mocks
export -f set_mock_mode
export -f configure_mock
export -f get_mock_config
export -f set_mocks_failure
export -f cleanup_mocks
export -f show_loaded_mocks
export -f setup_mocks_for_git_operations
export -f setup_mocks_for_nodejs_development
export -f setup_mocks_for_python_development
export -f setup_mocks_for_rust_development
export -f setup_mocks_for_go_development
export -f setup_mocks_for_java_development
export -f setup_mocks_for_ci_cd_pipeline
export -f setup_mocks_for_security_scanning
export -f setup_mocks_for_deployment
export -f bats_setup_with_mocks
export -f bats_teardown_with_mocks