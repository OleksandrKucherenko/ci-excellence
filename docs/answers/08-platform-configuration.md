# Platform and Configuration

Answers to frequently asked questions about setting up, configuring, and extending CI Excellence for your project.

## How are CI Excellence workflows and scripts deployed or updated?

CI Excellence is a **template repository** -- you clone or fork it, then customize it for your project. Updates are pulled from the upstream repository.

**Initial deployment:**

1. Fork or clone the CI Excellence repository.
2. Install Mise (the only prerequisite). See `docs/INSTALLATION.md` for macOS, Linux, WSL, and multiple shell instructions.
3. Enter the project directory. Mise automatically runs `mise run full-env-prepare` (defined in `.config/mise/conf.d/90-setup.toml`) which executes `scripts/00-setup-project.sh` to verify the environment.
4. Mise also auto-runs `mise run install-githooks` (defined in `.config/mise/conf.d/10-githooks.toml`) which installs Lefthook git hooks.

**Updating from upstream:**

```bash
# Add upstream remote (once)
git remote add upstream https://github.com/ORIGINAL-ORG/ci-excellence.git

# Fetch and merge updates
git fetch upstream
git merge upstream/main

# Resolve any conflicts in customized scripts, then:
mise install   # pick up any new tool versions
```

**What gets deployed:**

- `.github/workflows/*.yml` -- the GitHub Actions workflow definitions
- `scripts/ci/` -- all CI step scripts organized by phase (setup, build, test, release, etc.)
- `.config/mise/conf.d/` -- modular tool and task configuration
- `.lefthook.toml` -- git hook definitions

> **Extension Model:** CI Excellence uses a hooks system for customization. Rather than editing scripts in `scripts/ci/` directly, create hook scripts in `ci-cd/{step_name}/` directories. Each CI step runs `begin` hooks before its main logic and `end` hooks after. For example, to add custom compilation, create `ci-cd/ci-10-compile/begin-my-build.sh`. Hook scripts are auto-discovered (matching patterns `{hook}-*.sh` or `{hook}_*.sh`) and executed in alphabetical order. Hook scripts can communicate values back via `contract:env:NAME=VALUE` on stdout. See the [Hooks System](../HOOKS.md) for full details.

## How should CI Excellence be applied on top of an existing project or monorepo?

CI Excellence is designed to layer on top of existing projects. The stubs in `scripts/ci/` contain commented examples showing what to do for various stacks, but you implement your project-specific logic via hook scripts in `ci-cd/{step_name}/` directories rather than editing the stubs directly.

**Step-by-step:**

1. Copy the CI Excellence structure into your project root:
   - `scripts/ci/` directory (all CI step scripts)
   - `.github/workflows/` directory (workflow definitions)
   - `.config/mise/conf.d/` directory (tool configuration)
   - `mise.toml` (main Mise config)
   - `.lefthook.toml` (git hooks)
   - `config/.env.template` (variable documentation)
   - `config/.env.secrets.json.example` (secrets structure reference)

2. Implement your stack-specific logic via hook scripts. See `docs/CUSTOMIZATION.md` for Node.js, Python, Go, and Rust examples. For each CI step, create hook scripts in the corresponding `ci-cd/{step_name}/` directory:
   - `ci-cd/ci-20-install-dependencies/begin-npm-install.sh` -- your dependency install command
   - `ci-cd/ci-10-compile/begin-tsc-build.sh` -- your build command
   - `ci-cd/ci-20-lint/begin-eslint.sh` -- your linter
   - `ci-cd/ci-10-unit-tests/begin-jest.sh` -- your test runner

3. Set GitHub repository variables (`ENABLE_COMPILE`, `ENABLE_LINT`, etc.) to activate the pipeline stages you need. Leave unused stages as `false` and they are skipped without failure.

4. For monorepos, customize scripts to target specific workspace paths or use path filters in workflow triggers.

**Preserving existing CI:** If you already have workflows, you can adopt CI Excellence incrementally -- start by importing the scripts directory and referencing them from a new workflow file while keeping your existing workflows active.

## How do I migrate from another CI system (Jenkins, CircleCI, Travis)?

CI Excellence runs on GitHub Actions, so migration involves translating your pipeline logic into the CI Excellence script structure.

**General approach:**

1. **Map your stages** to CI Excellence phases: setup (`scripts/ci/setup/`), build (`scripts/ci/build/`), test (`scripts/ci/test/`), release (`scripts/ci/release/`), and so on.

2. **Translate job commands** into hook scripts. Each CI step in `scripts/ci/` auto-discovers extension scripts in `ci-cd/{step_name}/` directories. Create `begin-*.sh` hook scripts in the appropriate directory with your build/test/deploy commands, using the stub's commented examples as reference.

3. **Translate environment variables and secrets.** Document your variables in `config/.env.template` and set them as GitHub repository variables. Move secrets to either GitHub Actions secrets or the SOPS-encrypted `.env.secrets.json`.

4. **Translate triggers.** CI Excellence workflows trigger on PR events and branch pushes. Edit the `on:` section in `.github/workflows/*.yml` to match your branching strategy.

5. **Run both systems in parallel** during migration. Keep your old CI running until the CI Excellence pipeline produces identical results.

For detailed version-to-version migration within CI Excellence itself, see `docs/MIGRATION.md`.

## How do I gradually adopt CI Excellence features without disrupting existing workflows?

CI Excellence uses feature flags (GitHub repository variables) to control which pipeline stages are active. This allows incremental adoption.

**Recommended adoption sequence:**

1. **Week 1 -- Setup only.** Copy the repository structure. Set all `ENABLE_*` flags to `false`. Verify Mise activates and tools install.

2. **Week 2 -- Lint and compile.** Set `ENABLE_COMPILE=true` and `ENABLE_LINT=true`. Customize `scripts/ci/build/ci-10-compile.sh` and `scripts/ci/build/ci-20-lint.sh` for your stack.

3. **Week 3 -- Tests.** Set `ENABLE_UNIT_TESTS=true`. Customize `scripts/ci/test/ci-10-unit-tests.sh`.

4. **Week 4 -- Git hooks.** The `.lefthook.toml` configuration runs secret scanning (gitleaks), workflow validation, and commit message linting. Commit message enforcement can be enabled by uncommenting the `[commit-msg.commands.commitlint]` section.

5. **Week 5 -- Security and notifications.** Set `ENABLE_SECURITY_SCAN=true` and `ENABLE_NOTIFICATIONS=true`. Configure `APPRISE_URLS` in GitHub Secrets.

6. **Week 6+ -- Release pipeline.** Set `ENABLE_GITHUB_RELEASE=true` and optionally `ENABLE_NPM_PUBLISH`, `ENABLE_DOCKER_PUBLISH`. Customize the release scripts.

Each flag is independent. If a stage causes problems, set its flag back to `false` and the workflow skips it cleanly.

## How do I train my team on using CI Excellence?

**Key resources to share with the team:**

| Resource | Path | Purpose |
|---|---|---|
| Quick Start | `docs/QUICKSTART.md` | Get running in minutes |
| Installation | `docs/INSTALLATION.md` | Platform-specific Mise setup |
| Architecture | `docs/ARCHITECTURE.md` | How the system fits together |
| Customization | `docs/CUSTOMIZATION.md` | Stack-specific examples |
| Workflows | `docs/WORKFLOWS.md` | What each pipeline does |
| Git Hooks | `docs/GIT-HOOKS.md` | Local validation explained |
| FAQ | `docs/FAQ.md` | Common questions index |

**Hands-on onboarding steps:**

1. Have each developer install Mise and activate it in their shell (5 minutes, see `docs/INSTALLATION.md`).
2. Clone the repository and enter the directory -- Mise automatically provisions all tools.
3. Run `mise tasks` to see all available commands.
4. Make a test commit to experience the git hooks (secret scanning, commit message validation).
5. Open a PR to see the pre-release pipeline in action.
6. Use `mise run cz` (or `mise run commit`) to practice interactive conventional commits via commitizen.

**For the team lead:**

- Review `config/.env.template` to understand all available configuration variables.
- Decide which `ENABLE_*` flags to activate based on your project's maturity.
- Set up the secrets infrastructure (see credentials questions below).

## How can I update credentials required for CI runs?

Credentials live in two places depending on where they are used.

**For GitHub Actions (CI environment):**

1. Go to your repository on GitHub.
2. Navigate to Settings > Secrets and variables > Actions.
3. Under **Secrets**, click "New repository secret" or update an existing one.
4. Common secrets: `NPM_TOKEN`, `DOCKER_USERNAME`, `DOCKER_PASSWORD`, `APPRISE_URLS`.

**For local development (SOPS-encrypted secrets):**

Secrets are stored in `.env.secrets.json`, encrypted with age via SOPS. The age private key lives at `.secrets/mise-age.txt`.

To update a secret:

```bash
# Option 1: Use the inject-secret script
mise run inject-secret API_KEY "new-value-here"

# Option 2: Edit secrets interactively (opens $EDITOR with decrypted JSON)
mise run secrets-edit
```

The `inject-secret` command (defined in `scripts/setup/inject-secret.sh`) handles encryption automatically -- it decrypts the file, updates the key, and re-encrypts.

**Resolving secrets in custom scripts:** When writing CI scripts or hook scripts that need credentials, use the e-bash `_commons.sh` cascading secret resolution:

```bash
source scripts/lib/_commons.sh
# Check env var API_KEY first, then fall back to file .secrets/api_key
env:variable:or:secret:file value "API_KEY" ".secrets/api_key"
echo "Resolved: $value"
```

This provides a clean pattern for scripts that run both locally (where secrets come from SOPS-decrypted files) and in CI (where secrets come from environment variables).

To view current secrets:

```bash
mise run decrypt-secrets
```

All available secret keys are documented in `config/.env.secrets.json.example`.

## How can I perform scheduled secrets rotation?

CI Excellence does not include a built-in secrets rotation scheduler, but you can implement one using the maintenance workflow pattern.

**Manual rotation procedure:**

1. Generate new credentials from the external service (NPM, Docker Hub, etc.).
2. Update GitHub Actions secrets via Settings > Secrets and variables > Actions.
3. Update local secrets: `mise run inject-secret NPM_TOKEN "new-token-value"`.
4. Commit the re-encrypted `.env.secrets.json`.
5. Distribute the updated file to team members (they decrypt with the shared age key).

**Automated rotation with a scheduled workflow:**

Add a cron-triggered workflow in `.github/workflows/` that calls a rotation script:

```yaml
name: Rotate Secrets
on:
  schedule:
    - cron: '0 0 1 */3 *'  # quarterly, first of the month
  workflow_dispatch: {}

jobs:
  rotate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Rotate credentials
        run: ./scripts/ci/maintenance/ci-rotate-secrets.sh
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Tracking rotation:** Add a `SECRETS_LAST_ROTATED` variable in GitHub repository variables to track when secrets were last updated. Your rotation script can check this and alert if rotation is overdue.

## How do I use different secrets for different environments?

CI Excellence supports environment-specific configuration through the `environments/` directory structure (currently contains `staging/` and `production/`).

**GitHub Actions environments:**

1. In your GitHub repository, go to Settings > Environments.
2. Create environments (e.g., `staging`, `production`).
3. Add environment-specific secrets to each one.
4. Reference the environment in your workflow job:

```yaml
jobs:
  deploy-staging:
    environment: staging
    runs-on: ubuntu-latest
    steps:
      - name: Deploy
        run: ./scripts/ci/ops/ci-30-deploy.sh
        env:
          API_KEY: ${{ secrets.API_KEY }}  # reads from staging environment
```

**Local development with profiles:**

The profile system (`.config/mise/conf.d/30-profile.toml`) manages environment switching locally:

```bash
mise run profile:list       # list available profiles
mise run profile:show       # show current profile
mise run profile:switch staging
mise run profile:switch production
```

Profiles are stored in `.env.local` and override default variables. The `DEPLOYMENT_PROFILE` variable controls which environment configuration is active.

## How do I scope secrets to specific workflows or branches?

**Workflow-level scoping with GitHub environments:**

1. Create a GitHub environment (Settings > Environments) with deployment protection rules.
2. Add secrets to that specific environment.
3. Reference the environment in only the workflows that need those secrets.

**Branch-level scoping:**

GitHub environments support branch protection policies. Configure "Deployment branches" in the environment settings to restrict which branches can access those secrets.

**Job-level scoping within a workflow:**

Only pass secrets to the steps that need them:

```yaml
steps:
  - name: Build (no secrets needed)
    run: ./scripts/ci/build/ci-10-compile.sh

  - name: Publish (needs NPM_TOKEN)
    run: ./scripts/ci/release/ci-65-publish-npm.sh
    env:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

**Local development:** SOPS secrets in `.env.secrets.json` are loaded for all local tasks. To scope secrets locally, use separate encrypted files per environment and conditionally load them based on the active profile.

## How do I share secrets across multiple repositories?

**GitHub organization-level secrets:**

1. Go to your GitHub organization Settings > Secrets and variables > Actions.
2. Create organization secrets.
3. Set repository access policy (all repositories, selected repositories, or private only).

**Sharing the age encryption key for local development:**

The age key pair is generated by `scripts/setup/generate-age-key.sh` and stored at `.secrets/mise-age.txt` (private) and `.secrets/mise-age-pub.txt` (public).

- **To let team members encrypt secrets:** Share only the public key. They can encrypt but not decrypt.
- **To let team members decrypt secrets:** Share the private key through a secure channel (password manager, encrypted email, or in-person). Each developer places it at `.secrets/mise-age.txt` in their local clone.

**For multiple repositories:** Use the same age key pair across repositories so the team maintains a single decryption key. Alternatively, use different key pairs per repository for stronger isolation and share them via your organization's password manager (1Password, Vault, etc.).

## How do I audit secret usage and access?

**GitHub Actions audit log:**

1. Go to your organization Settings > Audit log.
2. Filter by `action:secret` to see secret creation, update, and deletion events.
3. Filter by `action:environment` to see environment secret access.

**Local secret access:**

- The age private key at `.secrets/mise-age.txt` controls who can decrypt local secrets. Track distribution of this key through your password manager's access log.
- The `.secrets/` directory is gitignored, so the private key never enters version control.

**Secret scanning in the pipeline:**

CI Excellence includes multiple secret scanning layers:
- **Pre-commit hook:** gitleaks scans staged files (`gitleaks protect --staged --redact`), configured in `.lefthook.toml`.
- **Pre-push hook:** Both gitleaks and trufflehog scan before push.
- **On-demand scanning:** `mise run scan-secrets` runs gitleaks across the repository. `mise run scan-history` runs trufflehog against git history for verified leaks.

These tools are installed automatically via `.config/mise/conf.d/15-validators.toml`.

## How do I generate a new secrets?

**Generate a new age encryption key pair:**

```bash
mise run generate-age-key
```

This runs `scripts/setup/generate-age-key.sh`, which:
- Creates the `.secrets/` directory with `700` permissions.
- Generates an age key pair using `age-keygen`.
- Writes the private key to `.secrets/mise-age.txt` (mode `600`).
- Extracts the public key to `.secrets/mise-age-pub.txt` (mode `644`).
- If a key already exists, prompts before overwriting and creates a backup.

**Create the encrypted secrets file and add secrets:**

```bash
# Add your first secret (creates .env.secrets.json if it does not exist)
mise run inject-secret NPM_TOKEN "npm_abc123..."

# Add more secrets
mise run inject-secret DOCKER_PASSWORD "my-docker-pass"
mise run inject-secret APPRISE_URLS "slack://T00/B00/XXX"
```

**Edit secrets interactively:**

```bash
mise run secrets-edit
```

This opens `.env.secrets.json` in your editor via SOPS, which transparently decrypts on open and re-encrypts on save.

**Verify your secrets:**

```bash
# List all secret keys (decrypted view)
mise run decrypt-secrets
```

The structure follows `config/.env.secrets.json.example`, which documents all supported keys: `NPM_TOKEN`, `DOCKER_USERNAME`, `DOCKER_PASSWORD`, `APPRISE_URLS`, `SLACK_WEBHOOK`, `TEAMS_WEBHOOK`, `DISCORD_WEBHOOK`, `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`, and `GITHUB_TOKEN`.

## How do I add custom scripts to the CI pipeline?

**Follow the numbering convention.** Scripts use spaced intervals (10, 20, 30...) so you can insert new scripts between existing ones.

- To add between compile (10) and lint (20): name it `ci-15-your-step.sh`
- To add after the last step: use the next available number (e.g., `ci-50-*.sh`)

**Script template:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Source the CI common bootstrap for logging and hooks
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../_ci-common.sh"

# Your logic here
echo:Build "Running custom step..."

echo:Success "Custom step completed"
```

Sourcing `scripts/ci/_ci-common.sh` gives you:
- Domain-specific loggers (`echo:Build`, `echo:Test`, `echo:Release`, etc.) from `_logger.sh`
- The hooks system for extension points via `ci-cd/{step_name}/` directories from `_hooks.sh`
- Helper functions: `ci:param`, `ci:secret`, `ci:output`, `ci:require`

> **e-bash `_arguments.sh` for CLI argument parsing:** If your custom script needs to accept command-line arguments, use the declarative argument parser instead of manual `getopts`/`shift` parsing:
> ```bash
> source scripts/lib/_arguments.sh
> export ARGS_DEFINITION="--verbose --output=file.txt --port=:8080"
> args:d "--verbose" "Enable verbose output"
> args:d "--output" "Output file path"
> args:parse "$@"
> # Variables $VERBOSE, $OUTPUT, $PORT are now set automatically
> print:help  # auto-generated help output
> ```

> **e-bash `_commons.sh` for secret resolution:** Use `env:variable:or:secret:file value "API_KEY" ".secrets/api_key"` for cascading secret resolution -- it checks the environment variable first, then falls back to a file. Also available: `var:l0 "VAR_NAME" "default"` for variable coalescing and `env:resolve "{{env.HOME}}/path"` for template resolution.

**Add to the workflow.** Edit the relevant `.github/workflows/*.yml` file:

```yaml
- name: Run custom step
  run: ./scripts/ci/build/ci-15-custom-step.sh
  env:
    CUSTOM_VAR: ${{ vars.CUSTOM_VAR }}
```

**Make it executable:**

```bash
chmod +x scripts/ci/build/ci-15-custom-step.sh
```

See `docs/CUSTOMIZATION.md` for the full script template with structured header comments.

## How do I integrate third-party tools (Snyk, SonarQube, etc.)?

**Option 1: Add the tool to Mise configuration.**

Create a new config file or add to an existing one in `.config/mise/conf.d/`:

```toml
# .config/mise/conf.d/18-security-scanning.toml
[tools]
snyk = "latest"

[tasks.snyk-test]
description = "Run Snyk security scan"
run = ["snyk test"]
```

**Option 2: Add a CI script that invokes the tool.**

Create a new script following the numbering convention:

```bash
#!/usr/bin/env bash
# scripts/ci/build/ci-35-sonarqube-scan.sh
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../_ci-common.sh"

echo:Security "Running SonarQube analysis..."

sonar-scanner \
  -Dsonar.projectKey="$SONAR_PROJECT_KEY" \
  -Dsonar.host.url="$SONAR_HOST_URL" \
  -Dsonar.token="$SONAR_TOKEN"

echo:Success "SonarQube analysis complete"
```

Then add it to the workflow:

```yaml
- name: SonarQube Scan
  run: ./scripts/ci/build/ci-35-sonarqube-scan.sh
  env:
    SONAR_PROJECT_KEY: ${{ vars.SONAR_PROJECT_KEY }}
    SONAR_HOST_URL: ${{ vars.SONAR_HOST_URL }}
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

**Option 3: Use the hooks system for extension (recommended).**

This is the primary extension model for CI Excellence. Consuming projects drop scripts into `ci-cd/{step_name}/` directories. The `_ci-common.sh` hooks system auto-discovers and executes `begin-*.sh` scripts before the step's main logic and `end-*.sh` scripts after. Scripts run in alphabetical order by filename. Hook scripts can communicate values back to the parent process via `contract:env:NAME=VALUE` on stdout.

## How do I customize notification formats and channels?

Notifications use Apprise, which supports 90+ services. Configuration is documented in `docs/NOTIFICATIONS.md`.

**Change notification channels:**

Set the `APPRISE_URLS` secret in GitHub (Settings > Secrets and variables > Actions > Secrets):

```bash
# Single channel
APPRISE_URLS=slack://T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX

# Multiple channels (space-separated)
APPRISE_URLS=slack://T00/B00/XXX msteams://outlook.office.com/webhook/YYY discord://123456/abcdef
```

**Customize message format:**

The notification scripts in `scripts/ci/notification/` control the message content:
- `ci-10-check-notifications-enabled.sh` -- guards notification execution
- `ci-20-determine-status.sh` -- determines success/failure/warning/info status
- `ci-30-send-notification.sh` -- sends the actual notification
- `ci-40-maintenance-status.sh` through `ci-95-summary-release.sh` -- workflow-specific status messages

To customize, edit the relevant status script in `scripts/ci/notification/` or `scripts/ci/reports/`. You can also call the send script directly with custom content:

```yaml
- name: Custom notification
  env:
    APPRISE_URLS: ${{ secrets.APPRISE_URLS }}
  run: |
    ./scripts/ci/notification/ci-30-send-notification.sh \
      "Deploy Complete" \
      "Version $VERSION deployed to production" \
      "success"
```

**Per-service customization** (username, avatar, channel) is done via URL parameters:

```bash
slack://T00/B00/XXX?user=CI+Bot&avatar=robot_face/#deploy-notifications
```

## How do I add custom validation steps before releases?

**Add a validation script** in the release phase directory. The release scripts in `scripts/ci/release/` run in numerical order:

```bash
#!/usr/bin/env bash
# scripts/ci/release/ci-04-pre-release-validation.sh
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../_ci-common.sh"

echo:Release "Running pre-release validation..."

# Example: check that CHANGELOG has been updated
if ! git diff HEAD~1 --name-only | grep -q "CHANGELOG.md"; then
  echo:Error "CHANGELOG.md was not updated for this release"
  exit 1
fi

# Example: verify all tests pass
mise run test

# Example: check minimum code coverage
COVERAGE=$(mise run test:coverage 2>&1 | grep -oP '\d+\.\d+%' | head -1)
echo:Release "Code coverage: $COVERAGE"

echo:Success "Pre-release validation passed"
```

Add the step to `.github/workflows/release.yml` before the version determination steps.

**Using git hooks for local validation:** The `.lefthook.toml` configuration already validates workflows and scans for secrets on pre-commit and pre-push. Add custom commands to either hook:

```toml
[pre-push.commands.custom-validation]
tags = "validation"
run = "./scripts/ci/release/ci-04-pre-release-validation.sh"
```

## How do I extend workflows for company-specific requirements?

**Three extension mechanisms are available:**

**1. Add new scripts following the numbering convention.**

Place scripts in the appropriate `scripts/ci/` subdirectory. Use numbers between existing scripts (e.g., `ci-25-*` between `ci-20-*` and `ci-30-*`) or after the last script. Add the step to the relevant workflow YAML.

**2. Use the hooks system for non-invasive extensions (recommended).**

This is the primary extension model for CI Excellence. The `_ci-common.sh` bootstrap sets up a hooks directory per script at `ci-cd/{step_name}/`. Consuming projects drop extension scripts there:

```
ci-cd/
  ci-10-compile/
    begin-notify-slack.sh     # runs before compile
    end-upload-metrics.sh     # runs after compile
  ci-20-lint/
    begin-custom-rules.sh     # runs before lint
```

Hook scripts matching `begin-*.sh` or `begin_*.sh` run before the step's main logic, and `end-*.sh` or `end_*.sh` run after. Scripts execute in alphabetical order by their sort key, so you can control ordering via naming (e.g., `begin-01-first.sh`, `begin-02-second.sh`). Hook scripts can communicate values back to the parent process via `contract:env:NAME=VALUE` on stdout, which is processed by the hooks middleware. This lets you extend behavior without modifying the original CI scripts.

> **e-bash library modules available as building blocks:** When writing hook scripts or custom CI steps, the following e-bash modules in `scripts/lib/` are available:
> - **`_semver.sh`** -- Full SemVer 2.0.0: `semver:parse`, `semver:increase:*`, `semver:compare`, `semver:constraints`, `semver:recompose`
> - **`_dryrun.sh`** -- Three-mode execution (normal/dry-run/rollback): `dryrun git docker npm` creates `dry:*`, `rollback:*`, `undo:*` wrappers
> - **`_dependencies.sh`** -- Tool verification with caching: `dependency:exists`, `dependency:version:gte`, `dependency:find`
> - **`_traps.sh`** -- Enhanced signal handling: `trap:on cleanup EXIT`, `trap:push`/`trap:pop` for stack-based scoped cleanup
> - **`_commons.sh`** -- Utilities: `time:now`/`time:diff` for timing, `env:variable:or:secret:file` for secret resolution, `var:l0`/`val:l0` for coalescing
> - **`_arguments.sh`** -- Declarative CLI parser: `ARGS_DEFINITION="--verbose --output=file.txt"` auto-generates variables
> - **`_logger.sh`** -- Domain-specific colored logging: `logger:init`, controlled by `DEBUG` env var
> - **`_hooks.sh`** -- The extension system itself: `hooks:declare`, `hooks:do`, `hooks:register`, `contract:env:NAME=VALUE`

**3. Add entirely new workflows.**

Create a new `.github/workflows/*.yml` file for company-specific pipelines (compliance checks, custom deployments, audit reporting). Reference the existing CI scripts or add new ones under `scripts/ci/`.

**4. Add new Mise configuration modules.**

Create a new file in `.config/mise/conf.d/` following the numbering convention:

```toml
# .config/mise/conf.d/25-company-tools.toml
[tools]
your-internal-tool = "latest"

[tasks.company-audit]
description = "Run company compliance audit"
run = ["your-internal-tool audit --strict"]
```

Mise automatically loads all `.toml` files in `.config/mise/conf.d/` in alphabetical order.

## Documentation Gaps

The following areas would benefit from additional documentation:

- **Secrets rotation automation.** There is no built-in scheduled rotation. A dedicated maintenance script (`scripts/ci/maintenance/ci-rotate-secrets.sh`) and a scheduled workflow template would formalize this process.
- **Environment-specific encrypted secrets.** The current SOPS setup uses a single `.env.secrets.json` for all environments. Documentation or tooling for per-environment encrypted files (e.g., `.env.secrets.staging.json`, `.env.secrets.production.json`) would help teams with strict environment isolation requirements.
- **Cross-repository secret sharing patterns.** While GitHub organization secrets are mentioned, a guide for managing shared age keys across repositories (key distribution, rotation, and revocation) would be valuable.
- **Secret access audit trail.** Local SOPS decryption is not logged. A wrapper script that records who decrypted secrets and when would improve auditability.
- **Third-party tool integration catalog.** A curated list of tested integrations (Snyk, SonarQube, Dependabot, Renovate) with ready-to-use script templates and Mise configuration would accelerate onboarding.
- **Company-specific extension examples.** The hooks system (`ci-cd/{step_name}/`) is referenced in the answer documents and in `_ci-common.sh` but still lacks a dedicated `docs/HOOKS.md` guide with end-to-end examples showing how consuming projects use it.
