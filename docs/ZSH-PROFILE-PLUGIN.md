# ZSH Profile Plugin: Architecture & Usage

This document details the internal logic, installation process, and lifecycle of the **CI Excellence ZSH Profile Plugin**. This plugin injects the current deployment profile (e.g., `staging`, `production`) into the ZSH right prompt (`RPROMPT`), providing visual feedback on the active environment.

## 1. Installation Mechanism

The installation is a hybrid process involving automatic symlinking via `mise` and manual configuration by the user.

### Step 1: Automatic Symlinking (Mise Hook)
When you `cd` into the project root, `mise` activates the `[hooks.enter]` script defined in `.config/mise/conf.d/30-profile.toml`.

**Logic:**
1.  **Detection**: Checks if the current shell is ZSH.
2.  **Target Resolution**: identifying the custom plugin directory for Oh-My-Zsh (default: `~/.oh-my-zsh/custom/plugins`).
3.  **Symlink Creation**: Creates a symlink named `ci-excellence` pointing to the in-repo script `scripts/setup/shell/mise-profile.plugin.zsh`.
    *   *Path:* `~/.oh-my-zsh/custom/plugins/ci-excellence/ci-excellence.plugin.zsh` -> `/path/to/repo/scripts/setup/shell/mise-profile.plugin.zsh`

### Step 2: User Activation (.zshrc)
The user must manually register the plugin in their `.zshrc` file to load it during shell startup.

**Configuration:**
```zsh
plugins=(
  ...
  mise          # Recommended to load mise first
  ci-excellence # Our custom plugin
)
```

---

## 2. Initialization Lifecycle

The plugin is designed to be robust against "race conditions" caused by themes (like Powerlevel10k) that aggressively manage the prompt.

### A. First Run (Fresh Terminal Session)
When you open a new terminal:

1.  **Plugin Load**: ZSH sources the plugin file.
2.  **Hook Registration**:
    *   Registers `ci_excellence_install_rprompt` as a `precmd` hook (runs before every prompt).
    *   **Crucial**: It enforces this hook to be the **last** in the `precmd_functions` array to ensure it runs after theme hooks.
3.  **Initial Execution**:
    *   Run 1 (Precmd): The hook runs. It checks `RPROMPT`. If empty/existing, it prepends the `$(mise_profile_prompt)` segment.
    *   **Race Condition Handling**: Themes like Powerlevel10k often overwrite `RPROMPT` asynchronously or late in the init process. To counter this, the plugin schedules a **Fixup Task** using `sched +0`.
    *   **Fixup Task**: Runs *just before* the prompt is actually printed to the screen (after all `precmd` hooks are done). It re-checks and re-injects the prompt segment if the theme wiped it out.

### B. Reload (`source ~/.zshrc`)
When you manually reload the configuration:

1.  The plugin script is re-sourced.
2.  Functions are redefined (updated).
3.  **Idempotency**: The prompt injection logic checks if `$(mise_profile_prompt)` is *already* present in `RPROMPT`.
    *   If present: It does nothing (avoids duplicating the segment like `locks staging staging`).
    *   If missing (e.g. theme reset it): It re-injects it.

### C. Directory Navigation (`cd`)
1.  **Mise Activation**: When entering the project directory, Mise sets the `DEPLOYMENT_PROFILE` environment variable.
2.  **Prompt Update**: 
    *   The `$(mise_profile_prompt)` function runs every time the prompt renders.
    *   It checks checks for:
        *   `DEPLOYMENT_PROFILE` variable.
        *   Git repository root presence.
        *   `environments/` directory existence.
        *   `mise.toml` existence.
    *   If all conditions apply, it renders the profile (e.g., `🔒 production`). Otherwise, it returns nothing, keeping the prompt clean outside the project.

---

## 3. Debugging

If the prompt is not appearing or behaving strangely, you can enable verbose debug logging.

**How to Debug:**
1.  Open `scripts/setup/shell/mise-profile.plugin.zsh`.
2.  Change line 10 to enable debug mode:
    ```bash
    typeset -g MISE_DEBUG="true"
    ```
3.  Run `source ~/.zshrc`.
4.  Observe the `DEBUG:` output in the terminal which will trace:
    *   Hook execution order.
    *   `RPROMPT` content before/after injection.
    *   Variable validation (Profile, PWD, Git Root).

## 4. Summary of Key Variables

| Variable             | Source                  | Purpose                                                  |
| :------------------- | :---------------------- | :------------------------------------------------------- |
| `DEPLOYMENT_PROFILE` | `.env.local` (via Mise) | The name of the active environment (e.g., staging).      |
| `MISE_DEBUG`         | Plugin Script           | Toggles verbose stderr logging.                          |
| `SHOW_MISE_PROMPT`   | User Env                | Set to `false` to globally disable the prompt injection. |
