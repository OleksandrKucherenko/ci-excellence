#!/usr/bin/env zsh
# MISE Profile Plugin for ZSH - Version 1.0.0
#
# PURPOSE: Enhanced ZSH integration for MISE profiles and CI environment management
#
# USAGE:
#   # Add to ~/.zshrc or .zprofile
#   source /path/to/ci-excellence/scripts/shell/mise-profile.plugin.zsh
#
# FEATURES:
#   - Profile visualization with enhanced indicators
#   - Auto-completion for MISE commands
#   - Profile switching shortcuts
#   - Environment status indicators
#   - Integration with CI workflows
#
# TESTABILITY:
#   - Set MISE_DEBUG=true for debug output
#   - Set CI_ZSH_PLUGIN_TEST_MODE=true for testing mode
#
# EXTENSION POINTS:
#   - Add custom profile indicators in customize_profile_prompt()
#   - Extend auto-completion in setup_autocompletion()
#   - Add custom shortcuts in define_custom_aliases()
#
# DEPENDENCIES:
#   - Required: mise, zsh, git
#   - Optional: jq (for JSON parsing), aws-cli (for AWS profiles)

# MISE Profile Plugin Configuration
MISE_PLUGIN_VERSION="1.0.0"
MISE_DEBUG="${MISE_DEBUG:-false}"
CI_ZSH_PLUGIN_TEST_MODE="${CI_ZSH_PLUGIN_TEST_MODE:-false}"

# Colors and symbols for profile visualization
typeset -gA PROFILE_COLORS=(
    [staging]="yellow"
    [production]="red"
    [development]="green"
    [default]="blue"
    [unknown]="magenta"
)

typeset -gA PROFILE_SYMBOLS=(
    [staging]="🚀"
    [production]="🔒"
    [development]="🛠️"
    [default]="💼"
    [unknown]="❓"
)

typeset -gA STATUS_SYMBOLS=(
    [healthy]="✅"
    [warning]="⚠️"
    [error]="❌"
    [unknown]="❓"
)

# Initialize plugin
mise_profile_plugin_init() {
    if [[ "$MISE_DEBUG" == "true" ]]; then
        echo "MISE Profile Plugin v$MISE_PLUGIN_VERSION initializing..."
    fi

    # Setup aliases
    define_mise_aliases

    # Setup auto-completion
    setup_mise_autocompletion

    # Setup hooks
    setup_mise_hooks

    if [[ "$MISE_DEBUG" == "true" ]]; then
        echo "MISE Profile Plugin initialized successfully"
    fi
}

# Define MISE aliases for convenience
define_mise_aliases() {
    # Profile management aliases
    alias mp='mise profile'
    alias mps='mise profile show'
    alias mpa='mise profile activate'
    alias mpl='mise profile list'
    alias mpc='mise profile create'
    alias mpd='mise profile delete'
    alias mpr='mise profile remove'

    # Quick profile switching
    alias mdev='mise profile activate development'
    alias mstg='mise profile activate staging'
    alias mprod='mise profile activate production'

    # Environment management
    alias menv='mise env'
    alias me='mise exec'
    alias mr='mise run'
    alias mt='mise task'

    # CI workflow shortcuts
    alias mcia='mise run ci-test'
    alias mcib='mise run ci-build'
    alias mcic='mise run ci-compile'
    alias mciu='mise run ci-upload'

    # Security and validation
    alias ms='mise run scan-secrets'
    alias mv='mise run validate-workflows'

    # Project management
    alias mset='mise run setup'
    alias mtest='mise run test'
    alias mlint='mise run lint'
    alias mformat='mise run format'
}

# Setup auto-completion for MISE commands
setup_mise_autocompletion() {
    # Enable MISE completion
    if command -v mise &> /dev/null; then
        eval "$(mise completion zsh)"
    fi

    # Custom completions for aliases
    compdef _mise_profile_commands mpa mpc mpd mpl
    compdef _mise_task_commands mcia mcib mcic mciu
}

# Custom completion for profile commands
_mise_profile_commands() {
    local -a profiles
    profiles=($(mise profile list 2>/dev/null | grep -E '^\s*\w+' | awk '{print $1}' | grep -v 'PROFILE' || echo "development staging production"))

    _arguments \
        '1: :_profiles' \
        '*:: :->args' && return 0

    case $state in
        args)
            _arguments '*:file:_files'
            ;;
    esac
}

# Custom completion for task commands
_mise_task_commands() {
    local -a tasks
    tasks=($(mise tasks --list 2>/dev/null | grep -E '^\s*\w+' | awk '{print $1}' | grep -v 'TASK' || echo "test lint format validate"))

    _arguments \
        '1: :_tasks' \
        '*:: :->args' && return 0
}

# Setup ZSH hooks for profile management
setup_mise_hooks() {
    # Hook to show profile on directory change
    autoload -U add-zsh-hook
    add-zsh-hook chpwd chpwd_mise_profile_check

    # Hook to update profile indicator on prompt
    add-zsh-hook precmd precmd_mise_profile_update
}

# Check for MISE profile in current directory
chpwd_mise_profile_check() {
    if [[ -f ".mise.toml" ]] || [[ -f ".config/mise/config.toml" ]]; then
        if [[ "$MISE_DEBUG" == "true" ]]; then
            echo "MISE configuration found in $(pwd)"
        fi

        # Auto-detect and suggest profile activation
        local suggested_profile
        suggested_profile=$(detect_mise_profile)

        if [[ -n "$suggested_profile" ]] && [[ "$CURRENT_MISE_PROFILE" != "$suggested_profile" ]]; then
            echo "💡 Suggested MISE profile: $suggested_profile (use 'mpa $suggested_profile' to activate)"
        fi
    fi
}

# Update profile indicator in prompt
precmd_mise_profile_update() {
    # Update current profile information
    update_current_mise_profile
}

# Detect appropriate MISE profile for current directory
detect_mise_profile() {
    local current_dir
    current_dir="$(pwd)"

    # Check directory name against known patterns
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
            # Check for environment indicators in file structure
            if [[ -d ".env/production" ]] || [[ -f ".env.production" ]]; then
                echo "production"
            elif [[ -d ".env/staging" ]] || [[ -f ".env.staging" ]]; then
                echo "staging"
            elif [[ -d ".env/development" ]] || [[ -f ".env.development" ]]; then
                echo "development"
            else
                echo "default"
            fi
            ;;
    esac
}

# Update current MISE profile information
update_current_mise_profile() {
    # Try to get active profile from MISE
    if command -v mise &> /dev/null; then
        CURRENT_MISE_PROFILE=$(mise profile current 2>/dev/null || echo "unknown")
        export CURRENT_MISE_PROFILE
    else
        CURRENT_MISE_PROFILE="unknown"
        export CURRENT_MISE_PROFILE
    fi
}

# Get profile color
get_profile_color() {
    local profile="$1"
    local color="${PROFILE_COLORS[$profile]:-${PROFILE_COLORS[default]}}"

    case "$color" in
        "red") echo "%F{red}" ;;
        "green") echo "%F{green}" ;;
        "yellow") echo "%F{yellow}" ;;
        "blue") echo "%F{blue}" ;;
        "magenta") echo "%F{magenta}" ;;
        "cyan") echo "%F{cyan}" ;;
        "white") echo "%F{white}" ;;
        *) echo "%F{default}" ;;
    esac
}

# Get profile symbol
get_profile_symbol() {
    local profile="$1"
    echo "${PROFILE_SYMBOLS[$profile]:-${PROFILE_SYMBOLS[unknown]}}"
}

# Get environment status
get_environment_status() {
    local profile="$1"

    # Check health status based on environment
    case "$profile" in
        "production")
            # Check production health indicators
            if command -v curl &> /dev/null; then
                if curl -f -s "https://api.example.com/health" &> /dev/null; then
                    echo "${STATUS_SYMBOLS[healthy]}"
                else
                    echo "${STATUS_SYMBOLS[warning]}"
                fi
            else
                echo "${STATUS_SYMBOLS[unknown]}"
            fi
            ;;
        "staging")
            # Staging environment check
            echo "${STATUS_SYMBOLS[healthy]}"
            ;;
        "development")
            # Development is always healthy in this context
            echo "${STATUS_SYMBOLS[healthy]}"
            ;;
        *)
            echo "${STATUS_SYMBOLS[unknown]}"
            ;;
    esac
}

# Enhanced profile prompt
mise_profile_prompt() {
    if [[ "$CI_ZSH_PLUGIN_TEST_MODE" == "true" ]]; then
        echo "(test-mode)"
        return
    fi

    local profile_color
    local profile_symbol
    local profile_name
    local status_symbol

    profile_color=$(get_profile_color "$CURRENT_MISE_PROFILE")
    profile_symbol=$(get_profile_symbol "$CURRENT_MISE_PROFILE")
    profile_name="$CURRENT_MISE_PROFILE"
    status_symbol=$(get_environment_status "$CURRENT_MISE_PROFILE")

    echo "%{$profile_color%}$profile_symbol $profile_name $status_symbol%f"
}

# Quick profile info
mise_profile_info() {
    echo "MISE Profile Information:"
    echo "  Current Profile: $CURRENT_MISE_PROFILE"
    echo "  Profile Color: $(get_profile_color "$CURRENT_MISE_PROFILE" | sed 's/%F{\([^}]*)}/\1/')"
    echo "  Profile Symbol: $(get_profile_symbol "$CURRENT_MISE_PROFILE")"
    echo "  Environment Status: $(get_environment_status "$CURRENT_MISE_PROFILE")"

    if command -v mise &> /dev/null; then
        echo "  Available Profiles:"
        mise profile list | sed 's/^/    /'
    fi
}

# Quick profile switch with validation
mise_quick_switch() {
    local target_profile="$1"

    if [[ -z "$target_profile" ]]; then
        echo "Usage: mise_quick_switch <profile>"
        return 1
    fi

    # Validate profile exists
    if ! mise profile list | grep -q "$target_profile"; then
        echo "❌ Profile '$target_profile' not found"
        echo "Available profiles:"
        mise profile list | sed 's/^/    /'
        return 1
    fi

    # Switch profile
    echo "🔄 Switching to profile: $target_profile"
    mise profile activate "$target_profile"

    # Update current profile
    update_current_mise_profile

    echo "✅ Switched to profile: $CURRENT_MISE_PROFILE"
}

# Profile health check
mise_profile_health_check() {
    local profile="${1:-$CURRENT_MISE_PROFILE}"

    echo "🔍 Checking health for profile: $profile"

    # Check profile configuration
    if mise profile show "$profile" &> /dev/null; then
        echo "✅ Profile configuration valid"
    else
        echo "❌ Profile configuration invalid"
        return 1
    fi

    # Check environment variables
    local required_vars=("CI_ENVIRONMENT" "PROJECT_ROOT")
    for var in "$required_vars[@]"; do
        if [[ -z "${(P)var}" ]]; then
            echo "⚠️  Missing environment variable: $var"
        else
            echo "✅ Environment variable set: $var"
        fi
    done

    # Check tools availability
    local required_tools=("git" "mise")
    for tool in "$required_tools[@]"; do
        if command -v "$tool" &> /dev/null; then
            echo "✅ Tool available: $tool"
        else
            echo "❌ Tool not found: $tool"
        fi
    done
}

# Custom prompt setup (extension point)
customize_profile_prompt() {
    # Override this function to customize the profile prompt
    # Example: add additional indicators, change format, etc.

    # Default implementation uses mise_profile_prompt
    RPROMPT='$(mise_profile_prompt) '"$RPROMPT"'
}

# Initialize the plugin
mise_profile_plugin_init

# Export useful functions
if [[ "$CI_ZSH_PLUGIN_TEST_MODE" != "true" ]]; then
    export -f mise_profile_prompt
    export -f mise_profile_info
    export -f mise_quick_switch
    export -f mise_profile_health_check
    export -f get_profile_color
    export -f get_profile_symbol
fi