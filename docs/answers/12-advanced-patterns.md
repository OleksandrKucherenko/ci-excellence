# Advanced Patterns

Answers to common questions about cross-repository workflows, dynamic configuration, and cost optimization within CI Excellence.

> **Notation:** Items marked **(GitHub Platform)** are native GitHub Actions features with no CI Excellence-specific implementation. Items marked **(CI Excellence)** involve project workflows or scripts. Items marked **(Combined)** require changes in both places.

---

## How do I trigger workflows in other repositories?

**(GitHub Platform)**

CI Excellence workflows are single-repository. Cross-repository triggering uses GitHub's `repository_dispatch` event or the `workflow_dispatch` API.

**Option 1 -- repository_dispatch event:**

Add a step to any CI Excellence workflow that sends a dispatch to another repository:

```yaml
- name: Trigger downstream repository
  uses: peter-evans/repository-dispatch@v3
  with:
    token: ${{ secrets.CROSS_REPO_PAT }}
    repository: your-org/downstream-repo
    event-type: upstream-release
    client-payload: '{"version": "${{ needs.prepare.outputs.version }}"}'
```

The downstream repository needs a workflow that listens for this event:

```yaml
on:
  repository_dispatch:
    types: [upstream-release]

jobs:
  handle:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Upstream released version ${{ github.event.client_payload.version }}"
```

**Option 2 -- Call workflow_dispatch via gh CLI or API:**

```bash
# Trigger a workflow in another repository
gh workflow run deploy.yml \
  --repo your-org/downstream-repo \
  -f version=1.2.3
```

In a workflow step:

```yaml
- name: Trigger downstream deploy
  env:
    GH_TOKEN: ${{ secrets.CROSS_REPO_PAT }}
  run: |
    gh workflow run deploy.yml \
      --repo your-org/downstream-repo \
      -f version="${{ needs.prepare.outputs.version }}"
```

**Important:** Both approaches require a Personal Access Token (PAT) with `repo` scope (classic) or `actions:write` permission (fine-grained) stored as a repository secret (`CROSS_REPO_PAT`). The default `GITHUB_TOKEN` cannot trigger workflows in other repositories.

**Where to add this in CI Excellence:** The most natural place is the `notify` job at the end of the Release Pipeline (`release.yml`), after all publish jobs have completed. Add a step before or after the notification send.

---

## How do I coordinate releases across multiple repositories?

**(GitHub Platform + Process)**

CI Excellence does not include multi-repository release orchestration. Here are workable patterns:

**Pattern 1 -- Sequential dispatch chain:**

Repository A releases, then triggers Repository B, which triggers Repository C:

```
repo-a (release.yml) → repository_dispatch → repo-b (release.yml) → repository_dispatch → repo-c
```

Add a dispatch step to the `notify` job of each repository's `release.yml`:

```yaml
# In repo-a's release.yml notify job
- name: Trigger repo-b release
  if: needs.prepare.result == 'success'
  uses: peter-evans/repository-dispatch@v3
  with:
    token: ${{ secrets.CROSS_REPO_PAT }}
    repository: your-org/repo-b
    event-type: upstream-release
    client-payload: '{"version": "${{ needs.prepare.outputs.version }}", "source": "repo-a"}'
```

**Pattern 2 -- Central orchestrator repository:**

Create a dedicated `release-orchestrator` repository with a workflow that dispatches to all downstream repos in the correct order:

```yaml
on:
  workflow_dispatch:
    inputs:
      version:
        required: true
        type: string

jobs:
  release-core:
    runs-on: ubuntu-latest
    steps:
      - name: Release core library
        env:
          GH_TOKEN: ${{ secrets.CROSS_REPO_PAT }}
        run: gh workflow run release.yml --repo your-org/core-lib -f release-scope=patch

  release-dependents:
    needs: release-core
    runs-on: ubuntu-latest
    strategy:
      matrix:
        repo: [frontend-app, backend-api, docs-site]
    steps:
      - name: Release ${{ matrix.repo }}
        env:
          GH_TOKEN: ${{ secrets.CROSS_REPO_PAT }}
        run: gh workflow run release.yml --repo your-org/${{ matrix.repo }} -f release-scope=patch
```

**Pattern 3 -- Git tag convention:**

Use a shared tag naming convention across repos. When `core-lib` publishes `v2.0.0`, downstream repos create corresponding tags like `v2.0.0-core-update`. Each repository's CI Excellence release workflow triggers on its own tag pattern.

---

## How do I share artifacts between repositories?

**(GitHub Platform)**

GitHub Actions artifacts (`actions/upload-artifact` / `actions/download-artifact`) are scoped to a single workflow run within a single repository. They cannot be directly shared across repositories.

**Option 1 -- GitHub Releases as artifact storage:**

Publish artifacts as GitHub Release assets in the source repository, then download them in the consuming repository:

```yaml
# In consuming repository's workflow
- name: Download artifact from upstream
  env:
    GH_TOKEN: ${{ secrets.CROSS_REPO_PAT }}
  run: |
    gh release download v1.2.3 \
      --repo your-org/upstream-repo \
      --pattern "*.tar.gz" \
      --dir ./vendor
```

CI Excellence already uploads release assets via `scripts/ci/release/ci-30-upload-assets.sh` **(STUB)** in the `publish-github` job of `release.yml`.

**Option 2 -- GitHub Packages / Container Registry:**

Publish npm packages or Docker images to GitHub Packages (ghcr.io) and consume them in other repositories. CI Excellence supports this through:

- NPM: `scripts/ci/release/ci-66-publish-npm-release.sh` **(STUB)**
- Docker: `scripts/ci/release/ci-80-publish-docker.sh` **(STUB)** (which already logs into both Docker Hub and `ghcr.io` in `release.yml`)

**Option 3 -- External storage (S3, GCS, Azure Blob):**

For large artifacts, upload to cloud storage in one workflow and download in another. This requires adding cloud CLI tools and credentials but handles artifacts of any size.

**Option 4 -- actions/download-artifact@v4 cross-workflow (same repo only):**

Within the same repository, you can download artifacts from other workflow runs using the `run-id` parameter. This does not work across repositories.

---

## How do I implement repository dispatch for cross-repo automation?

**(GitHub Platform)**

Repository dispatch is the foundation for cross-repo automation in GitHub Actions. Here is a complete implementation pattern.

**Step 1 -- Set up the receiver:**

In the target repository, create a workflow that listens for dispatch events:

```yaml
name: Handle Upstream Event
on:
  repository_dispatch:
    types: [deploy-request, sync-config, upstream-release]

jobs:
  handle:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Process event
        env:
          EVENT_TYPE: ${{ github.event.action }}
          PAYLOAD: ${{ toJSON(github.event.client_payload) }}
        run: |
          echo "Received event: $EVENT_TYPE"
          echo "Payload: $PAYLOAD"
          # Route to appropriate handler based on event type
```

**Step 2 -- Set up the sender:**

In any CI Excellence workflow, add a dispatch step:

```yaml
- name: Dispatch to downstream
  run: |
    curl -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: token ${{ secrets.CROSS_REPO_PAT }}" \
      https://api.github.com/repos/your-org/target-repo/dispatches \
      -d '{
        "event_type": "upstream-release",
        "client_payload": {
          "version": "${{ needs.prepare.outputs.version }}",
          "repository": "${{ github.repository }}",
          "sha": "${{ github.sha }}"
        }
      }'
```

Or use the `gh` CLI (simpler):

```yaml
- name: Dispatch to downstream
  env:
    GH_TOKEN: ${{ secrets.CROSS_REPO_PAT }}
  run: |
    gh api repos/your-org/target-repo/dispatches \
      -f event_type=upstream-release \
      -f 'client_payload[version]=${{ needs.prepare.outputs.version }}'
```

**Step 3 -- Create a PAT with appropriate scope:**

- Classic PAT: needs `repo` scope.
- Fine-grained PAT: needs `actions:write` and `contents:read` permissions on the target repository.

Store this as a secret (e.g., `CROSS_REPO_PAT`) in the sending repository.

**Practical example -- Trigger post-deployment smoke tests in a QA repository after the Ops workflow deploys to staging:**

Add this to `ops.yml` after the deploy step:

```yaml
- name: Trigger QA smoke tests
  if: github.event.inputs.action == 'deploy-staging'
  env:
    GH_TOKEN: ${{ secrets.CROSS_REPO_PAT }}
  run: |
    gh api repos/your-org/qa-tests/dispatches \
      -f event_type=run-smoke-tests \
      -f "client_payload[environment]=staging" \
      -f "client_payload[version]=${{ github.event.inputs.version }}"
```

---

## How do I generate workflow steps dynamically based on repository content?

**(GitHub Platform)**

GitHub Actions supports dynamic job/step generation using output variables and `fromJSON()`. CI Excellence does not use this pattern in its default workflows, but you can add it.

**Pattern -- Discover packages in a monorepo and build each one:**

```yaml
jobs:
  discover:
    runs-on: ubuntu-latest
    outputs:
      packages: ${{ steps.find.outputs.packages }}
    steps:
      - uses: actions/checkout@v4
      - name: Find packages
        id: find
        run: |
          # Generate a JSON array of package directories
          PACKAGES=$(ls -d packages/*/package.json 2>/dev/null | \
            xargs -I{} dirname {} | \
            jq -R -s -c 'split("\n") | map(select(length > 0))')
          echo "packages=$PACKAGES" >> "$GITHUB_OUTPUT"

  build:
    needs: discover
    runs-on: ubuntu-latest
    strategy:
      matrix:
        package: ${{ fromJSON(needs.discover.outputs.packages) }}
    steps:
      - uses: actions/checkout@v4
      - name: Build ${{ matrix.package }}
        run: cd ${{ matrix.package }} && npm run build
```

**Where to integrate with CI Excellence:** The `setup` job in `pre-release.yml` is the best place to add a discovery step that outputs a package list. Downstream jobs (`compile`, `lint`, `unit-tests`) can then use a matrix strategy based on that output.

**Limitations:**
- The matrix array must be valid JSON and cannot be empty (use `["default"]` as a fallback).
- Dynamic matrices are evaluated at job start time, not step time.
- Maximum matrix size is 256 entries.

---

## How do I use matrix strategies for complex test combinations?

**(GitHub Platform)**

Matrix strategies are a native GitHub Actions feature. CI Excellence workflows do not currently use matrix builds, but you can add them to any job.

**Basic matrix -- test across Node.js versions and operating systems:**

Edit the `unit-tests` job in `.github/workflows/pre-release.yml`:

```yaml
unit-tests:
  name: Unit Tests (${{ matrix.node-version }}, ${{ matrix.os }})
  runs-on: ${{ matrix.os }}
  needs: setup
  if: ${{ vars.ENABLE_UNIT_TESTS == 'true' }}
  strategy:
    fail-fast: false
    matrix:
      node-version: ['18', '20', '22']
      os: [ubuntu-latest, macos-latest]
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with:
        node-version: ${{ matrix.node-version }}
    - run: npm ci
    - run: ./scripts/ci/test/ci-10-unit-tests.sh
```

**Advanced matrix with include/exclude:**

```yaml
strategy:
  matrix:
    node-version: ['18', '20', '22']
    os: [ubuntu-latest, macos-latest, windows-latest]
    exclude:
      # Skip Node 18 on Windows (not supported)
      - node-version: '18'
        os: windows-latest
    include:
      # Add a special configuration for nightly Node
      - node-version: 'nightly'
        os: ubuntu-latest
        experimental: true
  fail-fast: false
```

**Matrix for monorepo packages:**

```yaml
strategy:
  matrix:
    package: [core, frontend, backend, cli]
steps:
  - run: cd packages/${{ matrix.package }} && npm test
```

**Key settings:**
- `fail-fast: false` -- Keep running other matrix combinations even if one fails. Recommended for CI to get full test results.
- `max-parallel: 4` -- Limit concurrent jobs to control runner consumption.

---

## How do I conditionally include/exclude jobs based on runtime conditions?

**(GitHub Platform + CI Excellence)**

CI Excellence already uses this pattern extensively via `ENABLE_*` feature flags. Here are additional runtime condition techniques.

**Pattern 1 -- Use `if:` with GitHub context expressions (already used in CI Excellence):**

```yaml
# From pre-release.yml -- job runs only when flag is set
compile:
  if: ${{ vars.ENABLE_COMPILE == 'true' }}
```

**Pattern 2 -- Use output variables from an earlier job:**

```yaml
jobs:
  check:
    runs-on: ubuntu-latest
    outputs:
      should-deploy: ${{ steps.decide.outputs.deploy }}
    steps:
      - id: decide
        run: |
          if [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
            echo "deploy=true" >> "$GITHUB_OUTPUT"
          else
            echo "deploy=false" >> "$GITHUB_OUTPUT"
          fi

  deploy:
    needs: check
    if: needs.check.outputs.should-deploy == 'true'
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying..."
```

**Pattern 3 -- Detect changed files to skip irrelevant jobs:**

```yaml
jobs:
  changes:
    runs-on: ubuntu-latest
    outputs:
      src: ${{ steps.filter.outputs.src }}
      docs: ${{ steps.filter.outputs.docs }}
    steps:
      - uses: dorny/paths-filter@v3
        id: filter
        with:
          filters: |
            src:
              - 'src/**'
              - 'package.json'
            docs:
              - 'docs/**'
              - '*.md'

  build:
    needs: changes
    if: needs.changes.outputs.src == 'true'
    # Only build when source files changed

  deploy-docs:
    needs: changes
    if: needs.changes.outputs.docs == 'true'
    # Only deploy docs when documentation changed
```

**Pattern 4 -- Handle skipped dependencies gracefully (already used in CI Excellence):**

The `bundle` job in `pre-release.yml` demonstrates this pattern:

```yaml
bundle:
  needs: [compile, lint, unit-tests]
  if: |
    always() &&
    (needs.compile.result == 'success' || needs.compile.result == 'skipped') &&
    (needs.lint.result == 'success' || needs.lint.result == 'skipped') &&
    (needs.unit-tests.result == 'success' || needs.unit-tests.result == 'skipped') &&
    vars.ENABLE_BUNDLE == 'true'
```

This `always() + skipped-check` pattern is a CI Excellence convention. It ensures a job runs when its dependencies were intentionally skipped (disabled via flags) but does not run when dependencies actually failed.

---

## How do I use reusable workflows and composite actions?

**(GitHub Platform)**

CI Excellence does not currently use reusable workflows or composite actions. Here is how to refactor toward them.

**Reusable workflow -- extract the setup pattern:**

Every CI Excellence workflow repeats the same setup steps (checkout, install tools, install dependencies, restore cache). This can be extracted into a reusable workflow:

```yaml
# .github/workflows/reusable-setup.yml
name: Reusable Setup
on:
  workflow_call:
    secrets:
      github-token:
        required: true

jobs:
  setup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup environment
        run: ./scripts/ci/setup/ci-10-install-tools.sh
        env:
          GITHUB_TOKEN: ${{ secrets.github-token }}
      - name: Install dependencies
        run: ./scripts/ci/setup/ci-20-install-dependencies.sh
      - uses: actions/cache@v4
        with:
          path: |
            node_modules
            ~/.cache
            .cache
          key: ${{ runner.os }}-deps-${{ hashFiles('**/package*.json', '**/bun.lock') }}
```

Call it from `pre-release.yml`:

```yaml
jobs:
  setup:
    uses: ./.github/workflows/reusable-setup.yml
    secrets:
      github-token: ${{ secrets.GITHUB_TOKEN }}
```

**Composite action -- extract the notification pattern:**

Every workflow's `notify` job repeats the same three steps (check enabled, determine status, send). This is a good candidate for a composite action:

```yaml
# .github/actions/notify/action.yml
name: Send CI Notification
description: Check if notifications are enabled and send via Apprise

inputs:
  title:
    required: true
  apprise-urls:
    required: true
  enable-notifications:
    required: true

runs:
  using: composite
  steps:
    - name: Check if notifications enabled
      id: check
      shell: bash
      env:
        APPRISE_URLS: ${{ inputs.apprise-urls }}
        ENABLE_NOTIFICATIONS: ${{ inputs.enable-notifications }}
      run: ./scripts/ci/notification/ci-10-check-notifications-enabled.sh
    - name: Send notification
      if: steps.check.outputs.enabled == 'true'
      shell: bash
      env:
        APPRISE_URLS: ${{ steps.check.outputs.apprise_urls }}
        NOTIFY_TITLE: ${{ inputs.title }}
      run: ./scripts/ci/notification/ci-30-send-notification.sh
```

**Reusable workflow limitations:**
- Maximum nesting depth of 4 (a reusable workflow can call another reusable workflow, up to 4 levels).
- A reusable workflow called with `workflow_call` cannot also use `workflow_dispatch` in the same file.
- Secrets must be explicitly passed (unless `secrets: inherit` is used).
- Reusable workflows run in the caller's context but cannot access the caller's `env:` block.

---

## How do I reduce GitHub Actions minutes usage?

**(Combined)**

CI Excellence's variable-driven design already helps reduce minutes by letting you disable unnecessary jobs. Here are additional strategies.

**1. Disable unused jobs via feature flags:**

Every `ENABLE_*` flag that is `false` means the corresponding job is skipped and consumes zero minutes. Review your current flags:

```bash
gh variable list
```

If you are not publishing Docker images, ensure `ENABLE_DOCKER_PUBLISH` is `false` (or unset, which defaults to `false`).

**2. Add path filters to workflows:**

The Pre-Release pipeline currently triggers on every push to matching branches regardless of what files changed. Add path filters to `.github/workflows/pre-release.yml`:

```yaml
on:
  pull_request:
    branches: [main, develop]
    paths:
      - 'src/**'
      - 'packages/**'
      - 'package.json'
      - '.github/workflows/pre-release.yml'
    paths-ignore:
      - 'docs/**'
      - '*.md'
      - 'LICENSE'
```

This prevents documentation-only changes from triggering the full CI pipeline.

**3. Use concurrency controls to cancel redundant runs:**

Add to the top of `pre-release.yml`:

```yaml
concurrency:
  group: pre-release-${{ github.ref }}
  cancel-in-progress: true
```

When a new push arrives on a branch that already has a running workflow, the old run is cancelled. This prevents queueing multiple runs for a branch that is being actively worked on.

**4. Skip CI for trivial changes:**

GitHub Actions supports skip directives in commit messages:

```bash
git commit -m "docs: update README [skip ci]"
```

Adding `[skip ci]` or `[ci skip]` to the commit message prevents all workflows from triggering.

**5. Use the maintenance workflow to clean up caches:**

Stale caches consume storage (not minutes, but storage quota). The maintenance pipeline's cleanup job (`scripts/ci/maintenance/ci-50-cleanup-caches.sh`) handles this when `ENABLE_CLEANUP=true`.

---

## How do I identify and eliminate unnecessary workflow runs?

**(GitHub Platform + CI Excellence)**

**Step 1 -- Audit current usage:**

```bash
# List all workflow runs from the past 30 days with their minutes
gh run list --limit 100 --json name,status,createdAt,updatedAt \
  --jq '.[] | "\(.name) | \(.status) | \(.createdAt)"'

# Count runs per workflow
gh run list --limit 200 --json name \
  --jq 'group_by(.name) | map({name: .[0].name, count: length}) | sort_by(.count) | reverse | .[]'
```

**Step 2 -- Identify waste patterns:**

| Pattern | Symptom | Fix |
|---|---|---|
| Docs-only PRs trigger full CI | Pre-Release runs on every push | Add `paths-ignore: ['docs/**', '*.md']` |
| Multiple runs per PR | Each push triggers a new run | Add `concurrency: { group: ..., cancel-in-progress: true }` |
| Scheduled maintenance runs with all flags disabled | Maintenance workflow runs daily but all jobs skip | Disable the workflow via `gh workflow disable maintenance.yml` or set at least one `ENABLE_*` flag |
| Auto-Fix runs on branches with no source changes | Every push to `feature/**` triggers security scan | Add path filters to `auto-fix-quality.yml` |

**Step 3 -- Disable the maintenance workflow schedule if not needed:**

The maintenance workflow runs daily via cron (`0 2 * * *`). If all maintenance flags are `false`, the workflow still starts (consuming a few seconds of runner time per job for setup). To eliminate this entirely:

```bash
gh workflow disable maintenance.yml
```

Re-enable when you are ready to use maintenance features:

```bash
gh workflow enable maintenance.yml
```

---

## How do I optimize runner selection (ubuntu vs. macos vs. self-hosted)?

**(GitHub Platform)**

All CI Excellence workflows use `ubuntu-latest`. This is the cheapest option for GitHub-hosted runners.

**GitHub Actions pricing (as of 2025):**

| Runner | Rate multiplier |
|---|---|
| Ubuntu (Linux) | 1x |
| macOS | 10x |
| Windows | 2x |
| Larger runners | Varies (2x to 64x) |

**When to use each:**

- **`ubuntu-latest`:** Default for all CI Excellence workflows. Use for builds, tests, linting, publishing, and any task that does not require a specific OS.
- **`macos-latest`:** Required for iOS/macOS builds, Xcode projects, and macOS-specific tests. Use sparingly due to 10x cost.
- **`windows-latest`:** Required for Windows-specific builds (.NET, Win32 APIs, Windows installer packaging).
- **Self-hosted runners:** Use for tasks requiring specialized hardware (GPUs, ARM), access to internal networks, or to avoid per-minute billing. Requires managing your own infrastructure.

**To switch a job to a different runner, edit the workflow:**

```yaml
# Change from ubuntu to self-hosted
compile:
  runs-on: [self-hosted, linux, x64]
```

**Cost optimization pattern -- run expensive jobs only when necessary:**

```yaml
e2e-tests:
  runs-on: ${{ github.event_name == 'pull_request' && 'ubuntu-latest' || 'macos-latest' }}
```

This runs E2E tests on cheap Linux runners for PRs but on macOS for the final merge to main (if macOS testing is required).

---

## How do I implement smart caching to reduce costs?

**(Combined)**

CI Excellence already includes caching in the `setup` and downstream jobs of `pre-release.yml`. Here are ways to improve it.

**Current caching in CI Excellence:**

The `setup` job in `pre-release.yml` caches `node_modules`, `~/.cache`, and `.cache` with a key based on lockfile hashes:

```yaml
- uses: actions/cache@v4
  with:
    path: |
      node_modules
      ~/.cache
      .cache
    key: ${{ runner.os }}-deps-${{ hashFiles('**/package*.json', '**/bun.lock') }}
    restore-keys: |
      ${{ runner.os }}-deps-
```

**Improvement 1 -- Cache mise tool installations:**

Add mise's installation directory to the cache:

```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.local/share/mise
      ~/.cache/mise
    key: ${{ runner.os }}-mise-${{ hashFiles('.config/mise/**/*.toml', 'mise.toml') }}
```

This avoids re-downloading tools like lefthook, commitlint, gitleaks, etc. on every run.

**Improvement 2 -- Cache Docker layers:**

For the `publish-docker` job in `release.yml`:

```yaml
- uses: docker/build-push-action@v5
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

The `type=gha` cache backend uses GitHub Actions cache, keeping Docker layer caches across runs.

**Improvement 3 -- Use exact key matches where possible:**

The `restore-keys` fallback (`${{ runner.os }}-deps-`) will restore a stale cache when the lockfile changes, which may include outdated packages. For strict reproducibility, omit `restore-keys` to force a fresh install when dependencies change.

**Improvement 4 -- Stale cache cleanup:**

The maintenance workflow's `ci-50-cleanup-caches.sh` **(STUB)** can be customized to clean up old caches. GitHub automatically evicts caches that have not been accessed in 7 days, but explicit cleanup prevents hitting the 10 GB per-repository cache limit.

---

## How do I use concurrency controls to avoid parallel runs?

**(GitHub Platform)**

CI Excellence workflows do not currently use GitHub's `concurrency` feature. Adding it is a one-line change per workflow.

**Add to `pre-release.yml` to cancel stale runs:**

```yaml
name: Pre-Release Pipeline

concurrency:
  group: pre-release-${{ github.ref }}
  cancel-in-progress: true
```

This means: for any given branch, only the latest push triggers an active run. Previous in-progress runs are cancelled.

**Add to `release.yml` to prevent concurrent releases:**

```yaml
concurrency:
  group: release
  cancel-in-progress: false
```

Note `cancel-in-progress: false` -- for releases, you do **not** want to cancel an in-progress release. Instead, the second release attempt will queue until the first completes.

**Add to `maintenance.yml` to prevent overlapping maintenance runs:**

```yaml
concurrency:
  group: maintenance
  cancel-in-progress: false
```

**Per-job concurrency (more granular):**

```yaml
jobs:
  publish-npm:
    concurrency:
      group: npm-publish
      cancel-in-progress: false
```

This prevents two NPM publishes from running simultaneously across different workflow runs, even if the workflow-level concurrency allows parallel runs.

**Recommended concurrency settings for CI Excellence:**

| Workflow | Group | Cancel in progress |
|---|---|---|
| `pre-release.yml` | `pre-release-${{ github.ref }}` | `true` (cancel stale PRs) |
| `release.yml` | `release` | `false` (never cancel a release) |
| `post-release.yml` | `post-release` | `false` |
| `maintenance.yml` | `maintenance` | `false` |
| `auto-fix-quality.yml` | `auto-fix-${{ github.ref }}` | `true` (cancel stale scans) |
| `ops.yml` | `ops-${{ github.event.inputs.action }}` | `false` (never cancel ops) |

---

## Documentation Gaps

The following areas related to advanced patterns are not addressed by CI Excellence and would benefit from implementation or documentation:

1. **No concurrency controls in any workflow.** None of the six workflow files use the `concurrency:` key. Multiple pushes to the same branch will queue and run sequentially, wasting minutes. Adding concurrency controls is a simple but impactful improvement.

2. **No cross-repository dispatch support.** There are no PAT secrets, dispatch steps, or receiver workflows configured. Cross-repo automation requires adding `CROSS_REPO_PAT` as a secret and adding dispatch steps to the relevant workflows.

3. **No matrix builds configured.** All jobs run on a single configuration (`ubuntu-latest` with a single tool version). There is no multi-OS, multi-version, or multi-package testing.

4. **No path-filter configuration.** All workflows trigger on all file changes within matching branches. Adding `paths:` / `paths-ignore:` filters or `dorny/paths-filter` would significantly reduce unnecessary runs.

5. **No mise tool cache.** The `setup` job caches `node_modules` but not mise tool installations (`~/.local/share/mise`). Every run re-downloads tools like gitleaks, trufflehog, commitlint, etc.

6. **No Docker layer caching.** The `publish-docker` job does not use GitHub Actions cache for Docker layers. Each release rebuilds all layers from scratch.

7. **No reusable workflows or composite actions.** The setup and notification patterns are duplicated across all six workflows. Extracting them into reusable components would reduce maintenance overhead and ensure consistency.

8. **No runner optimization guidance.** All workflows hardcode `ubuntu-latest`. There is no documentation on when to use other runner types or how to integrate self-hosted runners.

9. **Maintenance workflow runs on schedule even when all flags are disabled.** The cron trigger starts the workflow regardless of `ENABLE_*` flag state, consuming runner time for jobs that immediately skip.
