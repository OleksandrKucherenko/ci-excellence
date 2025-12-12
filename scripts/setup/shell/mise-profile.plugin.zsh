#!/usr/bin/env zsh
# CI Excellence MISE profile prompt plugin for Zsh.
#
# Shows DEPLOYMENT_PROFILE in the right prompt when:
# 1. Inside a git repo whose root contains `environments/`
# 2. DEPLOYMENT_PROFILE is set
# 3. Repo root contains `mise.toml`

typeset -g MISE_PLUGIN_VERSION="1.0.1"
typeset -g MISE_DEBUG="${MISE_DEBUG:-false}"
typeset -g CI_ZSH_PLUGIN_TEST_MODE="${CI_ZSH_PLUGIN_TEST_MODE:-false}"
typeset -g CI_EXCELLENCE_RPROMPT_SEPARATOR="${CI_EXCELLENCE_RPROMPT_SEPARATOR:- }"

typeset -g CI_EXCELLENCE_ENV_DIR_NAME="environments"
typeset -g CI_EXCELLENCE_MISE_FILE_NAME="mise.toml"

typeset -gA PROFILE_COLORS=(
    [staging]="green"
    [production]="red"
    [prod]="red"
    [canary]="magenta"
    [performance]="cyan"
    [sandbox]="blue"
    [local]="green"
    [development]="green"
    [default]="blue"
    [unknown]="white"
)

typeset -gA PROFILE_SYMBOLS=(
    [staging]="🧪"
    [production]="🔒"
    [prod]="🔒"
    [canary]="🐤"
    [performance]="⚡"
    [sandbox]="🥪"
    [local]=""
    [development]="🛠️"
    [default]="💼"
    [unknown]=""
)

typeset -gA STATUS_SYMBOLS=(
    [healthy]=""
    [warning]=""
    [error]=""
    [unknown]=""
)

typeset -gA PROFILE_STATUSES=(
    [production]="warning"
    [staging]="healthy"
    [development]="healthy"
    [local]="healthy"
)

# Return the root directory of the git repository, or empty string if not inside a git repo.
# This is used to determine if the current working directory is inside a git repository.
# Output is the root directory of the git repository, or empty string if not inside a git repo.
ci_excellence_repo_root() {
    git rev-parse --show-toplevel 2>/dev/null
}

# Returns 0 if the MISE profile prompt should be displayed, and 1 otherwise.
# The MISE profile prompt is displayed when:
# 1. DEPLOYMENT_PROFILE is set
# 2. The current working directory is inside a git repository
# 3. The git repository root contains the environments/ directory
# 4. The git repository root contains the mise.toml file
ci_excellence_prompt_enabled() {
    if [[ "$MISE_DEBUG" == "true" ]]; then
        echo "DEBUG: [ci_excellence_prompt_enabled] Checking..." >&2
        echo "DEBUG:   DEPLOYMENT_PROFILE='${DEPLOYMENT_PROFILE-}'" >&2
        echo "DEBUG:   PWD='$PWD'" >&2
    fi

    [[ -n "${DEPLOYMENT_PROFILE-}" ]] || { [[ "$MISE_DEBUG" == "true" ]] && echo "DEBUG:   FAILED: DEPLOYMENT_PROFILE missing" >&2; return 1; }

    local repo_root
    repo_root="$(ci_excellence_repo_root)" || { [[ "$MISE_DEBUG" == "true" ]] && echo "DEBUG:   FAILED: not a git repo" >&2; return 1; }
    
    if [[ "$MISE_DEBUG" == "true" ]]; then
       echo "DEBUG:   repo_root='$repo_root'" >&2
       echo "DEBUG:   checking dir: $repo_root/$CI_EXCELLENCE_ENV_DIR_NAME" >&2
       echo "DEBUG:   checking file: $repo_root/$CI_EXCELLENCE_MISE_FILE_NAME" >&2
    fi

    [[ -d "$repo_root/$CI_EXCELLENCE_ENV_DIR_NAME" ]] || { [[ "$MISE_DEBUG" == "true" ]] && echo "DEBUG:   FAILED: environments dir missing" >&2; return 1; }
    [[ -f "$repo_root/$CI_EXCELLENCE_MISE_FILE_NAME" ]] || { [[ "$MISE_DEBUG" == "true" ]] && echo "DEBUG:   FAILED: mise.toml missing" >&2; return 1; }

    [[ "$MISE_DEBUG" == "true" ]] && echo "DEBUG:   SUCCESS: prompt enabled" >&2
    return 0
}

ci_excellence_current_profile() {
    local profile="${DEPLOYMENT_PROFILE:-}"
    profile="${profile:l}"
    case "$profile" in
        prod) echo "production" ;;
        *) echo "$profile" ;;
    esac
}

get_profile_color() {
    local profile="$1"
    local color="${PROFILE_COLORS[$profile]:-${PROFILE_COLORS[default]}}"
    echo "%F{$color}"
}

get_profile_symbol() {
    local profile="$1"
    echo "${PROFILE_SYMBOLS[$profile]:-${PROFILE_SYMBOLS[unknown]}}"
}

get_environment_status() {
    local profile="$1"
    local profile_status="${PROFILE_STATUSES[$profile]:-unknown}"
    echo "${STATUS_SYMBOLS[$profile_status]:-${STATUS_SYMBOLS[unknown]}}"
}

mise_profile_prompt() {
    [[ "$MISE_DEBUG" == "true" ]] && echo "DEBUG: [mise_profile_prompt] TRIGGERED in PWD=$PWD" >&2
    [[ "$PWD" != ~ ]] || { [[ "$MISE_DEBUG" == "true" ]] && echo "DEBUG: [mise_profile_prompt] ignored (HOME)" >&2; return; }

    if [[ "$CI_ZSH_PLUGIN_TEST_MODE" == "true" ]]; then
        echo "(test-mode)"
        return
    fi

    ci_excellence_prompt_enabled || { [[ "$MISE_DEBUG" == "true" ]] && echo "DEBUG: [mise_profile_prompt] prompt NOT enabled" >&2; return; }

    local profile
    profile="$(ci_excellence_current_profile)"
    [[ -n "$profile" ]] || { [[ "$MISE_DEBUG" == "true" ]] && echo "DEBUG: [mise_profile_prompt] current_profile returned empty" >&2; return; }

    local profile_color profile_symbol status_symbol
    profile_color="$(get_profile_color "$profile")"
    profile_symbol="$(get_profile_symbol "$profile")"
    status_symbol="$(get_environment_status "$profile")"

    local -a parts=()
    [[ -n "$profile_symbol" ]] && parts+=("$profile_symbol")
    parts+=("$profile")
    [[ -n "$status_symbol" ]] && parts+=("$status_symbol")

    local joined="${(j: :)parts}"
    local prompt_str="%{$profile_color%}$joined%f"

    if [[ "$MISE_DEBUG" == "true" ]]; then
        echo "DEBUG: Generated prompt: $prompt_str" >&2
    fi

    echo "$prompt_str"
}

_ci_excellence_apply_rprompt() {
    [[ "${SHOW_MISE_PROMPT:-true}" != "false" ]] || return

    local existing="${RPROMPT:-}"
    if [[ "$existing" != *'$(mise_profile_prompt)'* ]]; then
        if [[ "$MISE_DEBUG" == "true" ]]; then
            echo "DEBUG:   Injecting \$(mise_profile_prompt) into RPROMPT" >&2
        fi
        local prefix='$(mise_profile_prompt)'
        local sep="${CI_EXCELLENCE_RPROMPT_SEPARATOR}"
        if [[ -n "$existing" ]]; then
            RPROMPT="${prefix}${sep}${existing}"
        else
            RPROMPT="${prefix}"
        fi
        if [[ "$MISE_DEBUG" == "true" ]]; then
             echo "DEBUG:   New RPROMPT: $RPROMPT" >&2
        fi
    else
        if [[ "$MISE_DEBUG" == "true" ]]; then
             echo "DEBUG:   Prompt already contains hook. Skipping injection." >&2
        fi
    fi
}

_ci_excellence_sched_fixup() {
    if [[ "$MISE_DEBUG" == "true" ]]; then
        echo "DEBUG: [_ci_excellence_sched_fixup] Late fixup running." >&2
    fi
    _ci_excellence_apply_rprompt
}

ci_excellence_install_rprompt() {
    if [[ "$MISE_DEBUG" == "true" ]]; then
        echo "DEBUG: [ci_excellence_install_rprompt] Precmd hook running." >&2
        echo "DEBUG:   Current precmd_functions: ${precmd_functions[*]}" >&2
    fi

    # Ensure this hook is always the last precmd function so it runs after themes (like p10k).
    if [[ "${precmd_functions[-1]}" != "ci_excellence_install_rprompt" ]]; then
        if [[ "$MISE_DEBUG" == "true" ]]; then
            echo "DEBUG:   Moving ci_excellence_install_rprompt to end of precmd_functions" >&2
        fi
        precmd_functions=(${precmd_functions:#ci_excellence_install_rprompt} ci_excellence_install_rprompt)
    fi

    # Apply immediately
    _ci_excellence_apply_rprompt

    # Schedule a late fixup incase another precmd (like p10k) overwrites RPROMPT later in this cycle
    # 'sched' runs just before the prompt is printed, after all precmd hooks.
    sched +0 _ci_excellence_sched_fixup
}

# Ensure prompt segment survives themes that overwrite RPROMPT after plugin load.
if [[ -z "${CI_EXCELLENCE_MISE_PROFILE_HOOKS_LOADED-}" ]]; then
    autoload -U add-zsh-hook
    add-zsh-hook precmd ci_excellence_install_rprompt
    typeset -g CI_EXCELLENCE_MISE_PROFILE_HOOKS_LOADED=1
fi

# Prime RPROMPT immediately.
if [[ "$MISE_DEBUG" == "true" ]]; then
    echo "DEBUG: Priming RPROMPT immediately..." >&2
fi
ci_excellence_install_rprompt

if [[ "$MISE_DEBUG" == "true" ]]; then
    echo "MISE profile plugin v$MISE_PLUGIN_VERSION loaded" >&2
fi
