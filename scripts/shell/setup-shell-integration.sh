#!/bin/bash
# Shell Integration Setup Script - Version 1.0.0
#
# PURPOSE: Set up shell integration for CI Excellence framework
#
# USAGE:
#   ./scripts/shell/setup-shell-integration.sh [shell] [options]
#
# EXAMPLES:
#   # Setup ZSH integration
#   ./scripts/shell/setup-shell-integration.sh zsh
#
#   # Setup Bash integration with auto-prompt
#   ./scripts/shell/setup-shell-integration.sh bash --prompt
#
#   # Remove integration
#   ./scripts/shell/setup-shell-integration.sh --remove
#
# TESTABILITY ENVIRONMENT VARIABLES:
#   - CI_TEST_MODE: Set to "dry_run" to simulate setup
#   - SHELL_INTEGRATION_HOME: Override integration home directory
#   - LOG_LEVEL: Set logging level (debug, info, warn, error)
#
# EXTENSION POINTS:
#   - Add custom shell configurations in setup_shell_config()
#   - Extend integration features in setup_additional_features()
#   - Add environment-specific setups in setup_environment_integration()
#
# SIZE GUIDELINES:
#   - Keep script under 50 lines of code (excluding comments and documentation)
#   - Extract complex setup logic to helper functions
#   - Use shared utilities for file operations
#
# DEPENDENCIES:
#   - Required: bash, grep, sed, awk
#   - Optional: zsh, mise, git

set -euo pipefail

# Script configuration
SCRIPT_NAME="$(basename "$0" .sh)"
SCRIPT_VERSION="1.0.0"
SCRIPT_MODE="${SCRIPT_MODE:-${CI_TEST_MODE:-default}}"
LOG_LEVEL="${LOG_LEVEL:-info}"
SHELL_INTEGRATION_HOME="${SHELL_INTEGRATION_HOME:-$HOME/.ci-excellence}"

# Source libraries and utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/config.sh"
source "${SCRIPT_DIR}/../lib/logging.sh"

# Shell type to setup
SHELL_TYPE="${1:-}"
SETUP_PROMPT="${2:-false}"
REMOVE_INTEGRATION="${2:-false}"

# Main setup function
main_setup() {
    log_info "Setting up shell integration"
    log_info "Shell type: $SHELL_TYPE"
    log_info "Setup prompt: $SETUP_PROMPT"
    log_info "Integration home: $SHELL_INTEGRATION_HOME"

    # Validate inputs
    validate_setup_inputs

    # Create integration directory
    create_integration_directory

    # Setup shell based on type
    case "$SHELL_TYPE" in
        "zsh")
            setup_zsh_integration
            ;;
        "bash")
            setup_bash_integration
            ;;
        "remove"|"--remove")
            remove_shell_integration
            ;;
        *)
            log_error "Unsupported shell type: $SHELL_TYPE"
            show_usage
            exit 1
            ;;
    esac

    log_success "Shell integration setup completed"
}

# Validate setup inputs
validate_setup_inputs() {
    log_info "Validating setup inputs"

    if [[ -z "$SHELL_TYPE" && "$REMOVE_INTEGRATION" != "true" ]]; then
        log_error "Shell type is required"
        show_usage
        exit 1
    fi

    # Validate shell is available
    case "$SHELL_TYPE" in
        "zsh")
            if ! command -v zsh &> /dev/null; then
                log_error "ZSH is not installed"
                exit 1
            fi
            ;;
        "bash")
            if ! command -v bash &> /dev/null; then
                log_error "Bash is not installed"
                exit 1
            fi
            ;;
    esac

    log_success "Setup inputs validation passed"
}

# Create integration directory
create_integration_directory() {
    log_info "Creating integration directory"

    mkdir -p "$SHELL_INTEGRATION_HOME"
    mkdir -p "$SHELL_INTEGRATION_HOME/bin"
    mkdir -p "$SHELL_INTEGRATION_HOME/config"

    log_debug "Integration directory created: $SHELL_INTEGRATION_HOME"
}

# Setup ZSH integration
setup_zsh_integration() {
    log_info "Setting up ZSH integration"

    local zshrc="$HOME/.zshrc"
    local zsh_plugin_dir="$SHELL_INTEGRATION_HOME/plugins"

    # Create plugin directory
    mkdir -p "$zsh_plugin_dir"

    # Copy MISE profile plugin
    if [[ -f "${SCRIPT_DIR}/mise-profile.plugin.zsh" ]]; then
        cp "${SCRIPT_DIR}/mise-profile.plugin.zsh" "$zsh_plugin_dir/"
        log_debug "MISE profile plugin copied to $zsh_plugin_dir"
    fi

    # Add integration to .zshrc if not already present
    if ! grep -q "# CI Excellence Shell Integration" "$zshrc" 2>/dev/null; then
        log_info "Adding integration to .zshrc"

        cat >> "$zshrc" << 'EOF'

# CI Excellence Shell Integration
if [[ -f "$HOME/.ci-excellence/plugins/mise-profile.plugin.zsh" ]]; then
    source "$HOME/.ci-excellence/plugins/mise-profile.plugin.zsh"
fi

# MISE environment setup
if command -v mise &> /dev/null; then
    eval "$(mise activate zsh)"
fi

# CI Excellence aliases
if [[ -f "$HOME/.ci-excellence/config/aliases.sh" ]]; then
    source "$HOME/.ci-excellence/config/aliases.sh"
fi

EOF

        log_debug "Integration added to .zshrc"
    else
        log_info "Integration already present in .zshrc"
    fi

    # Setup additional features
    setup_additional_features "zsh"
}

# Setup Bash integration
setup_bash_integration() {
    log_info "Setting up Bash integration"

    local bashrc="$HOME/.bashrc"

    # Add integration to .bashrc if not already present
    if ! grep -q "# CI Excellence Shell Integration" "$bashrc" 2>/dev/null; then
        log_info "Adding integration to .bashrc"

        cat >> "$bashrc" << 'EOF'

# CI Excellence Shell Integration
# MISE environment setup
if command -v mise &> /dev/null; then
    eval "$(mise activate bash)"
fi

# CI Excellence aliases
if [[ -f "$HOME/.ci-excellence/config/aliases.sh" ]]; then
    source "$HOME/.ci-excellence/config/aliases.sh"
fi

# Enhanced prompt setup
if [[ "${CI_SHELL_PROMPT:-false}" == "true" ]]; then
    source "$HOME/.ci-excellence/config/prompt.sh" 2>/dev/null || true
fi

EOF

        log_debug "Integration added to .bashrc"
    else
        log_info "Integration already present in .bashrc"
    fi

    # Setup additional features
    setup_additional_features "bash"
}

# Setup additional features
setup_additional_features() {
    local shell_type="$1"

    log_info "Setting up additional features for $shell_type"

    # Create aliases file
    local aliases_file="$SHELL_INTEGRATION_HOME/config/aliases.sh"
    cat > "$aliases_file" << 'EOF'
# CI Excellence Framework Aliases
# Generated by shell integration setup

# Profile management aliases
alias mdev='mise profile activate development'
alias mstg='mise profile activate staging'
alias mprod='mise profile activate production'
alias mp='mise profile'
alias mps='mise profile show'

# CI workflow aliases
alias mcia='mise run ci-test'
alias mcib='mise run ci-build'
alias mcic='mise run ci-compile'
alias mciu='mise run ci-upload'

# Security and validation aliases
alias ms='mise run scan-secrets'
alias mv='mise run validate-workflows'

# Project management aliases
alias mset='mise run setup'
alias mtest='mise run test'
alias mlint='mise run lint'
alias mformat='mise run format'

# Environment status aliases
alias mstatus='mise profile status'
alias menv='mise env'
alias mrefresh='mise cache clear'

EOF

    log_debug "Aliases file created: $aliases_file"

    # Create completion setup
    if [[ "$shell_type" == "zsh" ]]; then
        local completion_file="$SHELL_INTEGRATION_HOME/config/completion.zsh"
        cat > "$completion_file" << 'EOF'
# CI Excellence Framework Completion Setup
# Generated by shell integration setup

# Enable MISE completion
if command -v mise &> /dev/null; then
    eval "$(mise completion zsh)"
fi

# Custom completions
compdef _mise_profile_commands mdev mstg mprod mp mps
EOF
        log_debug "ZSH completion file created: $completion_file"
    fi

    # Setup prompt if requested
    if [[ "$SETUP_PROMPT" == "true" ]]; then
        setup_prompt_integration "$shell_type"
    fi

    log_success "Additional features setup completed"
}

# Setup prompt integration
setup_prompt_integration() {
    local shell_type="$1"

    log_info "Setting up prompt integration for $shell_type"

    local prompt_file="$SHELL_INTEGRATION_HOME/config/prompt.sh"

    case "$shell_type" in
        "zsh")
            cat > "$prompt_file" << 'EOF'
# CI Excellence Framework Prompt Setup for ZSH
# Generated by shell integration setup

# Custom prompt function
ci_excellence_prompt() {
    local profile="%F{blue}["
    if [[ -n "${CURRENT_MISE_PROFILE:-}" ]]; then
        profile+="mise: ${CURRENT_MISE_PROFILE}"
    else
        profile+="env: unknown"
    fi
    profile+="]%f"

    echo "$profile "
}

# Add to prompt
autoload -Uz promptinit
promptinit
prompt='$(ci_excellence_prompt)'"$prompt"'
EOF
            ;;
        "bash")
            cat > "$prompt_file" << 'EOF'
# CI Excellence Framework Prompt Setup for Bash
# Generated by shell integration setup

# Custom prompt function
ci_excellence_prompt() {
    local profile="["
    if [[ -n "${CURRENT_MISE_PROFILE:-}" ]]; then
        profile+="mise: ${CURRENT_MISE_PROFILE}"
    else
        profile+="env: unknown"
    fi
    profile+="]"

    echo -e "\033[36m$profile\033[0m "
}

# Custom PS1
if [[ -z "${CI_ORIGINAL_PS1:-}" ]]; then
    export CI_ORIGINAL_PS1="$PS1"
fi
export PS1="$(ci_excellence_prompt)$CI_ORIGINAL_PS1"
EOF
            ;;
    esac

    log_debug "Prompt file created: $prompt_file"
}

# Setup environment-specific integration
setup_environment_integration() {
    log_info "Setting up environment-specific integration"

    # Create environment detection script
    local env_file="$SHELL_INTEGRATION_HOME/bin/env-detect"
    cat > "$env_file" << 'EOF'
#!/bin/bash
# Environment Detection Script
# Generated by shell integration setup

detect_ci_environment() {
    local current_dir
    current_dir="$(pwd)"

    # Check for CI indicators
    if [[ -n "${CI:-}" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        echo "ci"
        return 0
    fi

    # Check directory patterns
    case "$(basename "$current_dir")" in
        *prod*|*production*|*live*)
            echo "production"
            ;;
        *stg*|*staging*|*qa*|*test*)
            echo "staging"
            ;;
        *dev*|*develop*|*local*)
            echo "development"
            ;;
        *)
            echo "default"
            ;;
    esac
}

# Export function for shell use
export -f detect_ci_environment
EOF

    chmod +x "$env_file"
    log_debug "Environment detection script created: $env_file"
}

# Remove shell integration
remove_shell_integration() {
    log_info "Removing shell integration"

    # Remove integration directory
    if [[ -d "$SHELL_INTEGRATION_HOME" ]]; then
        rm -rf "$SHELL_INTEGRATION_HOME"
        log_debug "Integration directory removed: $SHELL_INTEGRATION_HOME"
    fi

    # Remove from .zshrc
    local zshrc="$HOME/.zshrc"
    if [[ -f "$zshrc" ]]; then
        # Remove CI Excellence section
        sed -i '/# CI Excellence Shell Integration/,/^$/d' "$zshrc" 2>/dev/null || true
        log_debug "Integration removed from .zshrc"
    fi

    # Remove from .bashrc
    local bashrc="$HOME/.bashrc"
    if [[ -f "$bashrc" ]]; then
        # Remove CI Excellence section
        sed -i '/# CI Excellence Shell Integration/,/^$/d' "$bashrc" 2>/dev/null || true
        log_debug "Integration removed from .bashrc"
    fi

    log_success "Shell integration removed"
}

# Show usage information
show_usage() {
    echo
    echo "Usage: $0 [shell] [options]"
    echo
    echo "Shells:"
    echo "  zsh           Setup ZSH integration"
    echo "  bash          Setup Bash integration"
    echo
    echo "Options:"
    echo "  --prompt       Setup enhanced prompt"
    echo "  --remove       Remove existing integration"
    echo
    echo "Environment Variables:"
    echo "  SHELL_INTEGRATION_HOME  Set integration directory"
    echo "  LOG_LEVEL=debug            Enable debug logging"
    echo
    echo "Examples:"
    echo "  $0 zsh                    # Setup ZSH integration"
    echo "  $0 bash --prompt           # Setup Bash with prompt"
    echo "  $0 --remove               # Remove integration"
}

# Show integration status
show_integration_status() {
    echo "Shell Integration Status:"
    echo "  Integration Home: $SHELL_INTEGRATION_HOME"
    echo "  Integration Exists: $([[ -d "$SHELL_INTEGRATION_HOME" ]] && echo "Yes" || echo "No")"
    echo "  ZSH Integration: $([[ -f "$HOME/.zshrc" ]] && grep -q "CI Excellence Shell Integration" "$HOME/.zshrc" && echo "Yes" || echo "No")"
    echo "  Bash Integration: $([[ -f "$HOME/.bashrc" ]] && grep -q "CI Excellence Shell Integration" "$HOME/.bashrc" && echo "Yes" || echo "No")"
}

# Main function
main() {
    local command="${1:-status}"

    # Initialize logging and configuration
    initialize_logging "$LOG_LEVEL" "$SCRIPT_NAME"
    load_project_config

    case "$command" in
        "zsh"|"bash")
            SHELL_TYPE="$1"
            SETUP_PROMPT="${2:-false}"
            main_setup
            ;;
        "--remove"|"remove")
            REMOVE_INTEGRATION=true
            remove_shell_integration
            ;;
        "--status"|"status")
            show_integration_status
            ;;
        "--help"|"-h")
            show_usage
            ;;
        "")
            show_usage
            ;;
        *)
            log_error "Unknown option: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"