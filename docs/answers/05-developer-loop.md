# Developer Loop / Day-to-Day FAQ

Practical answers for the daily developer workflow within the CI Excellence framework. Each answer references the actual scripts, workflows, and configuration files in this repository.

> **Extension Model:** CI Excellence uses a hooks system for customization. Rather than editing scripts in `scripts/ci/` directly, create hook scripts in `ci-cd/{step_name}/` directories. Each CI step runs `begin` hooks before its main logic and `end` hooks after. For example, to add custom compilation, create `ci-cd/ci-10-compile/begin-my-build.sh`. Hook scripts are auto-discovered (matching patterns `{hook}-*.sh` or `{hook}_*.sh`) and executed in alphabetical order. Hook scripts can communicate values back via `contract:env:NAME=VALUE` on stdout. See the [Hooks System](../HOOKS.md) for full details.

---

## Local Development

### How do I trigger a pre-release pipeline for a feature or fix branch before opening a PR?

Push your branch to the remote. The pre-release pipeline (`.github/workflows/pre-release.yml`) triggers automatically on pushes to `develop`, `feature/**`, `fix/**`, and `claude/**` branches.

```bash
git push origin feature/my-change
```

The workflow runs immediately without requiring a PR. Only the jobs whose `ENABLE_*` flags are set to `'true'` in GitHub repository variables will execute; all others skip silently.

If you want to trigger it manually without pushing new code, you can re-push the same branch:

```bash
git commit --allow-empty -m "ci: trigger pre-release pipeline"
git push
```

**Note:** The pre-release workflow does not support `workflow_dispatch`, so it cannot be triggered from the GitHub Actions UI. Only push and pull_request events apply.

---

### How do I run lint and tests in CI for my feature branch without enabling every job?

All pre-release jobs are gated by individual `ENABLE_*` GitHub repository variables. Set only the ones you need in **Repository Settings > Secrets and variables > Actions > Variables**:

| Variable | Controls |
|---|---|
| `ENABLE_COMPILE` | Compile/Build job |
| `ENABLE_LINT` | Lint Code job |
| `ENABLE_UNIT_TESTS` | Unit Tests job |
| `ENABLE_INTEGRATION_TESTS` | Integration Tests job |
| `ENABLE_E2E_TESTS` | End-to-End Tests job |
| `ENABLE_BUNDLE` | Bundle and Package job |
| `ENABLE_SECURITY_SCAN` | Security Vulnerability Scan job |

For example, to run only lint and unit tests, set:

```
ENABLE_LINT=true
ENABLE_UNIT_TESTS=true
```

All other flags default to `'false'` and those jobs skip without failing the pipeline.

**Tip:** The `setup` job always runs (it has no feature flag) to install tools and cache dependencies.

---

### How do I re-run only the test stage on an existing workflow run?

This uses standard GitHub Actions functionality:

1. Open the workflow run in the GitHub Actions tab.
2. Click **Re-run jobs**.
3. Select **Re-run failed jobs** to re-run only the jobs that failed, or choose a specific job.

GitHub preserves cached artifacts from the original run, so dependent stages like `setup` use their cached output.

**Limitation:** You cannot re-run a single job in isolation if it depends on an upstream job that was not part of the re-run. The `setup` job always re-runs when its dependents are re-triggered.

---

### How do I auto-apply lint/format/security fixes and push them back?

The auto-fix workflow (`.github/workflows/auto-fix-quality.yml`) runs automatically on pushes to `develop`, `feature/**`, `fix/**`, and `claude/**` branches. It:

1. Runs the security scan (`scripts/ci/build/ci-30-security-scan.sh`).
2. Uploads a SARIF report to GitHub Code Scanning.
3. Uploads security reports as artifacts.

The workflow is controlled by these variables (set in GitHub repository variables):

| Variable | Default | Purpose |
|---|---|---|
| `AUTO_COMMIT` | `true` | Whether to auto-commit fixes |
| `AUTO_APPLY_FIXES` | `true` | Whether to apply discovered fixes |
| `PUSH_CHANGES` | `false` | Whether to push changes back to the branch |

To enable full auto-fix-and-push, set `PUSH_CHANGES=true` in your repository variables.

**For local auto-formatting**, run these mise tasks before pushing:

```bash
mise run format-scripts    # auto-format shell scripts with shfmt
mise run scan-scripts      # lint shell scripts with shellcheck (reports only, no auto-fix)
```

---

### How can I publish from my local developer environment?

The release pipeline (`.github/workflows/release.yml`) is designed for CI-driven releases, not local publishing. However, you can trigger a release from your terminal using the GitHub CLI:

```bash
# Trigger a patch release
gh workflow run release.yml -f release-scope=patch

# Trigger a minor release
gh workflow run release.yml -f release-scope=minor

# Dry run (calculate version only, no tag)
gh workflow run release.yml -f release-scope=patch -f dry-run=true

# Pre-release alpha
gh workflow run release.yml -f release-scope=prerelease -f pre-release-type=alpha
```

The release summary (`scripts/ci/reports/ci-95-summary-release.sh`) also generates one-click `gh workflow run` commands for ops actions like promoting, deploying, and marking releases as stable. These appear in the GitHub Actions job summary after a release completes.

**Direct local publishing is not built in.** The individual publish scripts (`ci-66-publish-npm-release.sh`, `ci-80-publish-docker.sh`) expect CI environment variables that are only available inside GitHub Actions runners.

---

### How can I skip CI jobs for a given change?

**Option 1: Skip the entire workflow** using GitHub's built-in `[skip ci]` directive:

```bash
git commit -m "docs: update readme [skip ci]"
```

This prevents all workflows from triggering on the push. Aliases `[ci skip]`, `[no ci]`, and `[skip actions]` also work.

**Option 2: Disable specific jobs** by leaving their `ENABLE_*` flags at the default `'false'`. Only jobs with their flag set to `'true'` execute.

**Option 3: Use `paths` filters** (requires workflow customization). The pre-release and auto-fix workflows do not currently use `paths` or `paths-ignore` filters, but GitHub Actions supports them natively. To skip CI for documentation-only changes, add to the workflow trigger:

```yaml
on:
  push:
    branches:
      - 'feature/**'
    paths-ignore:
      - 'docs/**'
      - '*.md'
```

This is not configured out of the box -- you would add it to `.github/workflows/pre-release.yml` or `.github/workflows/auto-fix-quality.yml` as needed.

---

### How do I run the same CI steps locally before pushing?

Use the mise tasks that mirror what CI runs:

```bash
# Run all tests (ShellSpec -- same as CI's ci-10-unit-tests.sh)
mise run test

# Run tests in watch mode during development
mise run test:watch

# Run tests with coverage report
mise run test:coverage

# Lint shell scripts (same as CI's ci-20-lint.sh)
mise run scan-scripts

# Format shell scripts
mise run format-scripts

# Validate GitHub Actions workflows
mise run check-workflows

# Scan for secrets (same as CI's ci-30-security-scan.sh uses)
mise run scan-secrets

# Scan git history for leaked credentials
mise run scan-history

# Dry-run the full CI workflow locally using act
mise run test:local-ci
```

The `test:local-ci` task uses [act](https://github.com/nektos/act) to simulate GitHub Actions on your machine. It runs with `--dry-run` by default, which validates the workflow structure without executing the steps.

**Git hooks also run a subset automatically** via Lefthook (`.lefthook.toml`):
- **pre-commit**: `gitleaks protect --staged`, prevent direct commits to main, validate changed workflow files.
- **pre-push**: `gitleaks protect`, `trufflehog` scan, validate all workflow files.
- **commit-msg**: `commitlint` for conventional commit format.

---

### How do I debug a failing CI job on my local machine?

**Step 1: Reproduce with the same script.** Every CI job calls a script from `scripts/ci/`. Run the corresponding script locally:

```bash
# Example: debug a lint failure
./scripts/ci/build/ci-20-lint.sh

# Example: debug a unit test failure
./scripts/ci/test/ci-10-unit-tests.sh

# Example: debug a security scan failure
./scripts/ci/build/ci-30-security-scan.sh
```

**Step 2: Control log verbosity with the DEBUG environment variable.** The e-bash `_logger.sh` module powers the structured logging system. Each CI step creates domain-specific loggers via `logger:init "tag" "prefix" "redirect"`, which generates `echo:Tag` and `printf:Tag` functions. The `DEBUG` environment variable controls which domains are active:

```bash
# Show only build and test logs
DEBUG=build,test ./scripts/ci/build/ci-20-lint.sh

# Show everything
DEBUG=* ./scripts/ci/test/ci-10-unit-tests.sh

# Show everything except setup noise
DEBUG=*,-setup ./scripts/ci/build/ci-10-compile.sh
```

The `DEBUG` filter supports glob patterns and exclusions: `DEBUG=build,test` enables only those domains, `DEBUG=*` enables all, and `DEBUG=*,-setup` enables all except `setup`. This is the same pattern used by the popular Node.js `debug` library. Each domain produces color-coded output to stderr, making it easy to visually distinguish which component is logging.

**Step 3: Simulate the full workflow locally with act:**

```bash
# Dry-run to validate workflow parsing
mise run test:local-ci

# Or run act directly with more control
act push --dry-run                    # simulate a push event
act pull_request --dry-run            # simulate a PR event
act -j lint --dry-run                 # simulate only the lint job
```

**Step 4: Check hooks middleware.** CI scripts use the e-bash hooks system (`scripts/lib/_hooks.sh`). Each script discovers extension scripts in `ci-cd/{step_name}/` directories. If a hook script is failing, check the `HOOKS_DIR` for the failing step.

---

### How do I override CI behavior for experimental branches?

The pre-release workflow triggers on `feature/**`, `fix/**`, and `claude/**` branch patterns. For experimental work, use the `claude/**` namespace:

```bash
git checkout -b claude/experiment-x
```

Since all `ENABLE_*` flags are repository-wide variables, you cannot change them per-branch through the framework alone. Options for branch-specific behavior:

**Option 1: Use `[skip ci]` in commits** to suppress CI entirely on experimental pushes.

**Option 2: Create a separate workflow file** with different triggers and flag names for your experimental branches.

**Option 3: Use GitHub Environments** (requires workflow customization). Define environment-scoped variables with different `ENABLE_*` values and gate your jobs with `environment:` declarations.

**Option 4: Use the hooks system (recommended).** Drop custom scripts into `ci-cd/{step_name}/` directories. The hooks middleware in `_ci-common.sh` auto-discovers and executes `begin-*.sh` and `end-*.sh` files in alphabetical order, letting you inject custom behavior without modifying the core CI scripts. For example, create `ci-cd/ci-10-compile/begin-experimental-flags.sh` to add experimental build flags. Hook scripts can export values back to the parent via `contract:env:NAME=VALUE` on stdout.

---

### How do I customize CI steps for a specific monorepo sub-project/workspace?

The CI Excellence framework does not include built-in monorepo workspace support. The workflow scripts operate at the repository root level. To adapt for monorepos:

**Option 1: `paths` filters in workflow triggers.** Add path-scoped triggers so that changes to `packages/app-a/` only run CI for that package:

```yaml
on:
  push:
    paths:
      - 'packages/app-a/**'
```

This requires duplicating or parameterizing workflow files per workspace.

**Option 2: Matrix builds.** Add a matrix strategy to run CI scripts with different working directories:

```yaml
strategy:
  matrix:
    workspace: [packages/app-a, packages/app-b]
steps:
  - run: cd ${{ matrix.workspace }} && ./scripts/ci/test/ci-10-unit-tests.sh
```

**Option 3: Extend via hooks (recommended).** Place workspace-specific scripts in `ci-cd/{step_name}/` directories. The hooks system in `_ci-common.sh` auto-discovers `begin-*.sh` and `end-*.sh` scripts and runs them in alphabetical order. For example, create `ci-cd/ci-10-unit-tests/begin-workspace-a-tests.sh` to run tests for a specific workspace.

**Option 4: Use the release pipeline's tag pattern.** The release workflow already supports scoped tags (`**/v*`), which matches patterns like `packages/app/v1.0.0`. This is a starting point for per-package releases.

---

### How do I check the CI pipeline changes, enabled feature flags, and enabled env variables?

**Check feature flags (current values):**

Go to **Repository Settings > Secrets and variables > Actions > Variables** in GitHub. All `ENABLE_*` flags are listed there.

Or use the GitHub CLI:

```bash
# List all repository variables
gh variable list
```

**Check what the pre-release pipeline expects:**

Reference `config/.env.template` for the full list of available flags and their purposes. This file documents every `ENABLE_*` flag across all pipelines.

**Check workflow file changes:**

```bash
# See what changed in workflow files
git diff main -- .github/workflows/

# Validate workflow syntax locally
mise run check-workflows
```

**Check enabled flags in a specific workflow run:**

Open the workflow run in GitHub Actions and look at the **Setup and Install Dependencies** step or the **Pipeline Summary** step. The summary job (`scripts/ci/reports/ci-10-summary-pre-release.sh`) logs all flag values.

**Review all environment variables in the pipeline summary:** The summary scripts log every `ENABLE_*` flag and `RESULT_*` outcome to `GITHUB_STEP_SUMMARY`, which appears as a rendered table in the Actions run page.

---

## Pull Request Workflows

### How do I require specific CI checks to pass before PR merge?

This uses standard GitHub branch protection, not a framework-specific feature.

1. Go to **Repository Settings > Branches > Branch protection rules**.
2. Click **Add rule** for `main` (or `develop`).
3. Enable **Require status checks to pass before merging**.
4. Search for and select the specific job names: `Setup and Install Dependencies`, `Lint Code`, `Unit Tests`, etc.

**Important:** Only jobs that have their `ENABLE_*` flag set to `'true'` will report a status. If `ENABLE_LINT` is `'false'`, the `Lint Code` job is skipped and its status check will show as "Expected -- Waiting for status to be reported", which blocks merging if required.

To handle this correctly, either:
- Only require checks for jobs you always run.
- Or set the corresponding `ENABLE_*` flag to `'true'` permanently for any check you require.

---

### How do I run different CI jobs for PRs vs. main branch pushes?

The pre-release workflow already triggers on both `pull_request` (to main/develop) and `push` (to feature/fix/claude branches). All jobs run the same way regardless of trigger type.

To differentiate behavior:

**Option 1: Use GitHub Actions `if` conditions** in the workflow:

```yaml
- name: Run extended tests
  if: github.event_name == 'pull_request'
  run: ./scripts/ci/test/ci-20-integration-tests.sh
```

**Option 2: Create separate workflows.** For example, keep `pre-release.yml` for PRs and create a `branch-ci.yml` with different triggers and flags for push events.

**Option 3: Use different flag values per environment.** Define GitHub Environments (e.g., `pr-checks` vs `branch-checks`) with different variable values and assign them to jobs.

These require workflow customization -- the framework does not differentiate PR vs. push behavior out of the box.

---

### How do I automatically run CI when PR is marked as ready for review?

The pre-release workflow does not currently listen to the `ready_for_review` event type. To add this, modify `.github/workflows/pre-release.yml`:

```yaml
on:
  pull_request:
    branches:
      - main
      - develop
    types: [opened, synchronize, reopened, ready_for_review]
```

This is a standard GitHub Actions feature, not a framework-specific mechanism.

---

### How do I re-run failed jobs without re-running the entire workflow?

Use the GitHub Actions UI:

1. Open the failed workflow run.
2. Click **Re-run jobs** in the top right.
3. Select **Re-run failed jobs**.

Or use the GitHub CLI:

```bash
# List recent workflow runs
gh run list --workflow=pre-release.yml

# Re-run failed jobs for a specific run
gh run rerun <run-id> --failed
```

GitHub caches artifacts and dependencies from the original run, so re-runs are typically faster.

---

### How do I skip CI for WIP/draft PRs?

The pre-release workflow does not currently filter out draft PRs. To skip CI on drafts, add a condition to jobs in `.github/workflows/pre-release.yml`:

```yaml
jobs:
  setup:
    if: github.event.pull_request.draft == false || github.event_name == 'push'
    # ...
```

Alternatively, use `[skip ci]` in your commit messages while the PR is still a draft.

---

### How do I run CI only on changed files/packages?

The framework does not include built-in change detection. To add this, use standard GitHub Actions approaches:

**Option 1: `paths` filters on the workflow trigger** (see the monorepo question above).

**Option 2: Use a change detection action** like `dorny/paths-filter`:

```yaml
- uses: dorny/paths-filter@v3
  id: changes
  with:
    filters: |
      scripts:
        - 'scripts/**'
      workflows:
        - '.github/workflows/**'

- name: Run tests
  if: steps.changes.outputs.scripts == 'true'
  run: mise run test
```

This requires workflow customization.

---

### How do I get CI status notifications on Slack for my PRs?

The framework includes a notification system based on Apprise. To enable Slack notifications:

1. Set `ENABLE_NOTIFICATIONS=true` in GitHub repository variables.
2. Set `APPRISE_URLS` as a GitHub secret with your Slack webhook:

```
slack://T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX/#ci-notifications
```

The notification step runs at the end of every pipeline (`pre-release.yml`, `release.yml`, `post-release.yml`, `maintenance.yml`). It calls `scripts/ci/notification/ci-30-send-notification.sh` using Apprise.

See `docs/NOTIFICATIONS.md` for full setup instructions, including multi-service configuration (Slack + Teams + Discord simultaneously) and filtering to notify only on failures.

---

## Performance and Optimization

### How do I speed up slow CI builds?

The framework already includes these optimizations:

1. **Dependency caching** via `actions/cache@v4` in `pre-release.yml`. The cache key is based on `**/package*.json` and `**/bun.lock` hashes.
2. **Parallel job execution.** Lint, unit tests, and security scan all run in parallel after setup.
3. **Feature flag gating.** Disabled jobs skip instantly with no runner allocation.

Additional strategies (require workflow customization):

- **Reduce checkout depth:** Add `fetch-depth: 1` to `actions/checkout@v4` steps that do not need git history (the security scan already uses `fetch-depth: 0` because trufflehog needs it).
- **Use larger runners:** Change `runs-on: ubuntu-latest` to a larger runner class if your organization has them.
- **Split heavy test suites** across matrix builds (see parallelization question below).
- **Use `actions/cache` with more specific paths** tuned to your project's dependency manager.

---

### How do I parallelize tests across multiple runners?

The pre-release workflow runs lint, unit tests, integration tests, e2e tests, and security scan as separate parallel jobs. To further parallelize within a test suite, add a matrix strategy:

```yaml
unit-tests:
  strategy:
    matrix:
      shard: [1, 2, 3, 4]
  steps:
    - name: Run unit tests (shard ${{ matrix.shard }})
      run: ./scripts/ci/test/ci-10-unit-tests.sh
      env:
        TEST_SHARD: ${{ matrix.shard }}
        TEST_TOTAL_SHARDS: 4
```

Your test script (`scripts/ci/test/ci-10-unit-tests.sh`) would need to read `TEST_SHARD` and `TEST_TOTAL_SHARDS` to split the test files accordingly. This is not built in -- you need to customize both the workflow and the test script.

---

### How do I cache dependencies effectively to reduce build times?

The framework configures caching in `pre-release.yml`:

```yaml
- name: Cache dependencies
  uses: actions/cache@v4
  with:
    path: |
      node_modules
      ~/.cache
      .cache
    key: ${{ runner.os }}-deps-${{ hashFiles('**/package*.json', '**/bun.lock') }}
    restore-keys: |
      ${{ runner.os }}-deps-
```

To improve cache effectiveness:

- **Add project-specific paths.** If your project uses pip, Go modules, or other package managers, add their cache directories to the `path` list.
- **Make cache keys more specific.** Include the tool version in the key (e.g., `node-20-deps-${{ hashFiles(...) }}`).
- **Use `restore-keys`** for partial cache hits (already configured).
- **Cache build outputs.** The compile job uploads `dist/`, `build/`, and `out/` as artifacts. Downstream jobs download these instead of rebuilding.

**Local caching:** Mise caches installed tools automatically in `~/.local/share/mise/`. No additional configuration needed.

---

### How do I identify and fix bottlenecks in the CI pipeline?

**Step 1: Review the workflow run timeline.** In the GitHub Actions UI, open a workflow run and look at the visual timeline. Each job shows its duration, and you can see which jobs are on the critical path.

**Step 2: Check the Pipeline Summary.** The summary job (`scripts/ci/reports/ci-10-summary-pre-release.sh`) generates a table showing the result and duration of each job. Look at the GitHub Actions summary tab for the rendered table.

**Step 3: Profile individual scripts locally.** Use the e-bash `_commons.sh` module's microsecond timing functions for precise step profiling:

```bash
# Quick overall timing
time ./scripts/ci/build/ci-20-lint.sh
time ./scripts/ci/test/ci-10-unit-tests.sh

# For fine-grained timing within a custom hook script:
source scripts/lib/_commons.sh
start=$(time:now)
# ... your operation ...
elapsed=$(time:diff "$start")
echo "Operation took ${elapsed}ms"
```

The `time:now` and `time:diff` functions provide microsecond-precision timing and are useful when writing hook scripts that need to measure individual operations. The `_logger.sh` domain-tagged logging combined with `DEBUG` filtering also helps identify where time is being spent.

**Step 4: Use DEBUG filtering** to see where time is spent in a script:

```bash
DEBUG=* ./scripts/ci/build/ci-10-compile.sh
```

**Common bottlenecks and fixes:**
- **Dependency installation:** Improve cache key specificity.
- **Full git clone:** Use `fetch-depth: 1` where full history is not needed.
- **Sequential test execution:** Add matrix sharding.
- **Unused jobs:** Disable via `ENABLE_*` flags to free up runner capacity.

---

### How do I use matrix builds to test multiple configurations?

Add a `strategy.matrix` block to any job in `.github/workflows/pre-release.yml`. For example, to test across multiple Node.js versions:

```yaml
unit-tests:
  strategy:
    matrix:
      node-version: [18, 20, 22]
  steps:
    - uses: actions/setup-node@v4
      with:
        node-version: ${{ matrix.node-version }}
    - run: ./scripts/ci/test/ci-10-unit-tests.sh
```

Or test across multiple operating systems:

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, macos-latest]
runs-on: ${{ matrix.os }}
```

This is standard GitHub Actions functionality. The framework's CI scripts are portable bash and should work on any runner that has the required tools installed via `scripts/ci/setup/ci-10-install-tools.sh`.

---

### How do I reduce flaky test failures?

**For ShellSpec tests** (what this framework uses):

```bash
# Run tests in verbose mode to identify flaky ones
mise run test:coverage

# Run a specific spec file in isolation
shellspec spec/path/to/flaky_spec.sh
```

**General strategies** (require customization):

- **Add retries to the workflow step:**

```yaml
- name: Run unit tests
  uses: nick-fields/retry@v3
  with:
    max_attempts: 3
    command: ./scripts/ci/test/ci-10-unit-tests.sh
```

- **Quarantine flaky tests.** Move them to a separate spec file and run it as a non-blocking step with `continue-on-error: true`.
- **Upload test artifacts on failure.** The pre-release workflow already does this with `if: always()` on the upload step for test results.

---

### How do I optimize Docker layer caching?

The release workflow's Docker publish job (`scripts/ci/release/ci-80-publish-docker.sh`) uses `docker/setup-buildx-action@v3` which enables BuildKit. To optimize caching:

**Option 1: Use GitHub Actions cache backend** (add to the workflow):

```yaml
- name: Build and push Docker image
  uses: docker/build-push-action@v5
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

**Option 2: Use registry-based caching:**

```yaml
cache-from: type=registry,ref=ghcr.io/your-org/your-app:buildcache
cache-to: type=registry,ref=ghcr.io/your-org/your-app:buildcache,mode=max
```

These require modifying the Docker publish script or workflow step. The framework sets up BuildKit and registry logins but does not configure layer caching by default.

---

## Usability and UX

### Where can I find one-click links for quick actions?

After a release completes, the release summary script (`scripts/ci/reports/ci-95-summary-release.sh`) generates one-click ops commands in the **GitHub Actions job summary**. Navigate to:

1. **Actions** tab in your repository.
2. Select the completed **Release Pipeline** run.
3. Scroll to the **Pipeline Summary** section.

The summary includes ready-to-copy `gh workflow run` commands for:

- **Promote Release:** `gh workflow run ops.yml -f action=promote-release -f version=<VERSION>`
- **Deploy to Staging:** `gh workflow run ops.yml -f action=deploy-staging -f version=<VERSION>`
- **Deploy to Production:** `gh workflow run ops.yml -f action=deploy-production -f version=<VERSION> -f confirm=yes`
- **Mark as Stable:** `gh workflow run ops.yml -f action=mark-stable -f version=<VERSION>`

You can also trigger ops actions directly from the **Actions** tab by selecting the **Ops Pipeline** workflow and clicking **Run workflow** to fill in the action and version interactively.

---

### Where can I find the state machine of the release?

The release lifecycle state machine is documented in two places:

1. **Markdown with Mermaid diagram:** `docs/STATES.md` contains the full state machine in Mermaid syntax, covering all five phases: Development, Artifact Generation, Communication & Lifecycle, Deployment Environments, and Stability Status.

2. **Rendered images:** `docs/images/` contains pre-rendered diagrams:
   - `docs/images/state-diagram-workflows.png` / `.svg` -- the state machine diagram.
   - `docs/images/sequence-diagram-workflows.png` / `.svg` -- the sequence diagram showing workflow interactions.

View the Mermaid diagram directly on GitHub (GitHub renders Mermaid in markdown), or open the PNG/SVG files for a static image.

---

## Documentation Gaps

The following areas are not currently built into the framework and would benefit from dedicated documentation or implementation:

1. **Per-branch feature flag overrides.** All `ENABLE_*` flags are repository-wide. There is no mechanism to set different values per branch, per PR, or per environment without workflow customization.

2. **Draft PR detection.** The pre-release workflow does not skip draft/WIP PRs. A `github.event.pull_request.draft == false` condition would need to be added manually.

3. **Path-based filtering.** Neither `pre-release.yml` nor `auto-fix-quality.yml` uses `paths` or `paths-ignore` filters. Projects that want to skip CI for docs-only changes must add these filters.

4. **Monorepo / workspace support.** The framework operates at the repository root. Multi-package workflows, per-workspace CI, and scoped path triggers are not built in (though the release tag pattern `**/v*` hints at future support).

5. **Change detection for selective testing.** No built-in `dorny/paths-filter` or similar mechanism exists to run only affected test suites.

6. **Test sharding and parallelization.** Matrix strategies are not configured. The test scripts do not read shard environment variables.

7. **Docker layer caching.** BuildKit is set up via `docker/setup-buildx-action@v3` but no cache backend (GHA or registry) is configured.

8. **`act` beyond dry-run.** The `test:local-ci` task only runs `act --dry-run`. Full local execution with secrets and environment variables is not documented.

9. **CI variable audit tooling.** There is no local command to list all current `ENABLE_*` flag values. The `gh variable list` command works but requires the GitHub CLI and repository access.

10. **Flaky test management.** No retry strategy, quarantine mechanism, or flaky test tracking is built into the test workflow or ShellSpec configuration.
