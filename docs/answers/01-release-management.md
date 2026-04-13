# Release Management

Answers to common questions about versioning, releasing, feature flags, and pipeline control in the CI Excellence framework.

> **Notation:** Steps marked **(REAL)** use fully implemented scripts. Steps marked **(STUB)** require you to customize the script body before they do real work. Steps marked **(PARTIAL)** have template logic but need project-specific tuning.

> **Extension Model:** CI Excellence uses a hooks system for customization. Rather than editing scripts in `scripts/ci/` directly, create hook scripts in `ci-cd/{step_name}/` directories. Each CI step runs `begin` hooks before its main logic and `end` hooks after. For example, to add custom version-file updates, create `ci-cd/ci-15-update-version/begin-update-package-json.sh`. Hook scripts are auto-discovered by the framework (matching patterns `{hook}-*.sh` or `{hook}_*.sh`) and executed in alphabetical order. Hook scripts can communicate values back to the parent process via `contract:env:NAME=VALUE` on stdout. See the [Hooks System](../HOOKS.md) for full details.

---

## How do I cut a major release from main?

Trigger the **Release Pipeline** manually via `workflow_dispatch` with these inputs:

| Input | Value |
|---|---|
| `release-scope` | `major` |
| `pre-release-type` | *(leave default, ignored for stable releases)* |
| `dry-run` | `false` |

**What happens:**

1. The `tag-version` job runs on `ubuntu-latest`.
2. `scripts/ci/release/ci-12-set-version-outputs.sh` **(REAL)** calls `ci-10-determine-version.sh` **(REAL)**, which uses the e-bash semver library to find the latest `v*` tag and compute the next major version (e.g., `v1.2.3` becomes `2.0.0`).
3. `scripts/ci/release/ci-08-create-tag.sh` **(REAL)** creates an annotated git tag `v2.0.0` and pushes it to origin.
4. The pushed tag triggers the second half of the release workflow (the `prepare` job and downstream publish jobs) via the `push: tags: '**/v*'` trigger.

**GitHub Actions UI path:** Actions tab > Release Pipeline > Run workflow > select `major` > Run.

**gh CLI equivalent:**

```bash
gh workflow run release.yml \
  -f release-scope=major \
  -f pre-release-type=alpha \
  -f dry-run=false
```

---

## How do I cut a minor/feature release from main?

Same as above but set `release-scope` to `minor`.

```bash
gh workflow run release.yml \
  -f release-scope=minor \
  -f pre-release-type=alpha \
  -f dry-run=false
```

The version calculation in `ci-10-determine-version.sh` **(REAL)** will bump the minor component (e.g., `1.2.3` becomes `1.3.0`).

---

## How do I cut a patch release from main?

Set `release-scope` to `patch` (the default).

```bash
gh workflow run release.yml \
  -f release-scope=patch \
  -f pre-release-type=alpha \
  -f dry-run=false
```

The version calculation bumps only the patch component (e.g., `1.2.3` becomes `1.2.4`).

---

## How do I create a canary/pre-release build from main with a prerelease tag?

Use one of the `pre*` scopes combined with the `pre-release-type` input. All tags follow the `[{path}/]v{semver}` pattern, where the pre-release stage is part of the semver string (e.g., `v1.2.4-beta`, `v1.2.4-hotfix.1`).

**Example -- create `2.0.0-beta` (premajor with beta):**

```bash
gh workflow run release.yml \
  -f release-scope=premajor \
  -f pre-release-type=beta \
  -f dry-run=false
```

**Available scope/type combinations:**

| Scope | Current tag | Result |
|---|---|---|
| `premajor` + `alpha` | `v1.2.3` | `2.0.0-alpha` |
| `preminor` + `rc` | `v1.2.3` | `1.3.0-rc` |
| `prepatch` + `beta` | `v1.2.3` | `1.2.4-beta` |
| `prerelease` + `alpha` | `v1.2.4-alpha` | `1.2.4-alpha.1` |
| `prerelease` + `beta` | `v1.2.4-alpha.1` | `1.2.4-beta` (switches type) |

The `prerelease` scope is the incremental one: if the current tag already has the same pre-release identifier, it bumps the numeric suffix (e.g., `alpha` to `alpha.1`, `alpha.1` to `alpha.2`). If the identifier changes (alpha to beta), it resets to just `beta` with no numeric suffix.

**Custom pre-release stages:** The same `v{semver}-{stage}` pattern works for any stage name, not just `alpha`/`beta`/`rc`. Examples:

- **Hotfix:** `v1.2.3-hotfix`, `v1.2.3-hotfix.1`, `v1.2.3-hotfix.2`
- **Canary:** `v1.2.3-canary`, `v1.2.3-canary.1`
- **Nightly:** `v1.2.3-nightly.20260413`

The version calculation in `ci-10-determine-version.sh` handles arbitrary pre-release type strings correctly. To use custom stages via the workflow UI, add them to the `pre-release-type` choices in `.github/workflows/release.yml`:

```yaml
pre-release-type:
  options:
    - alpha
    - beta
    - rc
    - hotfix     # Add custom stages as needed
    - canary
    - nightly
```

The downstream `publish-github` job will mark the GitHub Release as `prerelease: true` because `ci-09-parse-tag.sh` **(REAL)** sets `is-prerelease=true` when the version contains a `-`.

**Scripts involved (all REAL):**
- `scripts/ci/release/ci-10-determine-version.sh` -- version arithmetic
- `scripts/ci/release/ci-12-set-version-outputs.sh` -- exposes `version` and `is-prerelease` to the workflow
- `scripts/ci/release/ci-08-create-tag.sh` -- creates and pushes the tag
- `scripts/ci/release/ci-09-parse-tag.sh` -- parses the tag in the second phase

---

## How do I run a dry-run release to validate the pipeline without publishing?

Set `dry-run` to `true`:

```bash
gh workflow run release.yml \
  -f release-scope=minor \
  -f pre-release-type=alpha \
  -f dry-run=true
```

**What happens:**

1. The `tag-version` job runs.
2. `ci-12-set-version-outputs.sh` **(REAL)** computes the next version and prints it to the workflow summary.
3. The "Create and Push Tag" step is **skipped** because the workflow has `if: ${{ github.event.inputs.dry-run != 'true' }}` on that step.
4. No tag is pushed, so the `prepare` job and all downstream publish jobs never trigger.

This lets you verify that version calculation is correct and the pipeline setup succeeds without any side effects.

> **e-bash `_dryrun.sh` module:** For scripts that perform destructive operations (git push, npm publish, docker push), the e-bash library provides a three-mode execution system via `_dryrun.sh`. By calling `dryrun git docker npm`, you get wrapper functions like `dry:git push` that print the command without executing when `DRY_RUN=true`. This is useful when building custom release or deployment hooks that need dry-run support beyond the workflow-level skip. You can also use per-command overrides like `DRY_RUN_GIT=true` to selectively dry-run specific tools while letting others execute normally.

---

## How do I update the version files and changelog without publishing a release?

This is a **two-step manual process** because these scripts are not wired into the release workflow by default.

**Step 1 -- Update version files (STUB):**

```bash
export CI_VERSION="1.3.0"
./scripts/ci/release/ci-15-update-version.sh
```

This script is a **stub**. Rather than editing the stub directly, implement your version-update logic as a hook script in `ci-cd/ci-15-update-version/` (e.g., `begin-update-package-json.sh`). The stub contains commented examples showing what to do for various project types (package.json, setup.py, Cargo.toml, etc.) -- use these as reference when writing your hook script.

**Step 2 -- Generate changelog (STUB):**

```bash
export CI_VERSION="1.3.0"
./scripts/ci/release/ci-20-generate-changelog.sh
```

This script is also a **stub**. Implement your changelog generation via a hook script in `ci-cd/ci-20-generate-changelog/` (e.g., `begin-git-cliff.sh`). The stub contains commented examples for conventional-changelog, git-cliff, and standard-version that you can use as reference.

**Step 3 -- Commit the changes (REAL):**

```bash
export CI_VERSION="1.3.0"
export CI_TARGET_BRANCH="main"
./scripts/ci/release/ci-18-commit-version-changes.sh
```

This script **(REAL)** stages all changes, commits with message `chore(release): bump version to 1.3.0`, and pushes to the target branch. It configures the git user as the GitHub Actions bot via `ci-30-github-actions-bot.sh`.

**Note:** The release workflow itself does NOT call `ci-15-update-version.sh` or `ci-18-commit-version-changes.sh`. If you want version files updated as part of every release, you need to add those steps to the `tag-version` job in `.github/workflows/release.yml` before the tag creation step.

---

## How do I regenerate release notes for a given tag?

Release notes are generated by `scripts/ci/release/ci-25-generate-release-notes.sh` **(PARTIAL)**, which currently outputs a stub template. To regenerate for a specific tag:

**Locally:**

```bash
export CI_VERSION="1.2.3"
./scripts/ci/release/ci-25-generate-release-notes.sh
```

**To update an existing GitHub Release with new notes:**

```bash
# Generate the notes
export CI_VERSION="1.2.3"
NOTES=$(./scripts/ci/release/ci-25-generate-release-notes.sh)

# Update the GitHub Release via gh CLI
gh release edit "v1.2.3" --notes "$NOTES"
```

**Important:** The release notes script is **PARTIAL** -- it outputs a static template. To get meaningful release notes, create a hook script in `ci-cd/ci-25-generate-release-notes/` (e.g., `begin-extract-changelog.sh`) that extracts content from CHANGELOG.md or generates it from git log. The commented-out examples in the stub show both approaches and serve as implementation reference.

The workflow uses `scripts/ci/release/ci-27-write-release-notes-output.sh` **(REAL)** as a wrapper that calls `ci-25-generate-release-notes.sh` and writes the output to `GITHUB_OUTPUT` for consumption by the `softprops/action-gh-release` action.

---

## How do I release a specific commit hash or branch instead of the latest main?

**This is NOT directly supported** by the current release workflow. The `workflow_dispatch` trigger in `release.yml` always runs on the branch selected in the GitHub UI (defaulting to `main`), and there is no `ref` or `commit` input.

**Tag pattern:** All tags follow the `[{path}/]v{semver}` convention, where the optional `{path}/` prefix maps to a monorepo sub-folder (e.g., `v1.2.4`, `packages/app/v1.2.4`).

**Workarounds:**

1. **Create a branch at the desired commit and dispatch from it:**

   ```bash
   git checkout -b release/hotfix-1.2.4 <commit-sha>
   git push origin release/hotfix-1.2.4
   ```

   Then trigger the workflow from the GitHub Actions UI selecting `release/hotfix-1.2.4` as the branch. Note: the `tag-version` job checks out whatever branch the workflow runs on, so the tag will point to the tip of that branch.

2. **Create the tag manually and let the push trigger handle it:**

   ```bash
   git tag -a v1.2.4 <commit-sha> -m "Release v1.2.4"
   git push origin v1.2.4
   ```

   This bypasses the `tag-version` job entirely and goes straight to the `prepare` job (tag push trigger). The version is parsed from the tag by `ci-09-parse-tag.sh` **(REAL)**. For monorepo sub-packages, use a path-prefixed tag:

   ```bash
   git tag -a packages/app/v1.2.4 <commit-sha> -m "Release packages/app v1.2.4"
   git push origin packages/app/v1.2.4
   ```

   The `push: tags: '**/v*'` trigger matches both plain and path-prefixed tags. The parse script extracts the version via `VERSION="${TAG##*v}"`, stripping the path prefix.

3. **Add a `ref` input to the workflow** (requires modifying `.github/workflows/release.yml`):

   ```yaml
   inputs:
     ref:
       description: 'Git ref to release (commit SHA or branch)'
       required: false
       default: ''
   ```

   Then update the checkout step to use `ref: ${{ github.event.inputs.ref || github.ref }}`.

---

## How do I create a hotfix release from a previous version?

**Partially supported.** The intended strategy is to use the pre-release stage mechanism with a `hotfix` type, following the version tag pattern `[{path}/]v{semver}`. Hotfixes use the pre-release suffix rather than a branch prefix: `v1.2.3-hotfix.1`, `v1.2.3-hotfix.2`, etc.

**Method 1 (recommended): Use the `hotfix` pre-release stage.**

The version calculation in `ci-10-determine-version.sh` correctly handles arbitrary pre-release types including `hotfix`. If passed `CI_PRE_RELEASE_TYPE=hotfix`, it produces versions like `1.2.3-hotfix`, `1.2.3-hotfix.1`, `1.2.3-hotfix.2`, etc.

```bash
# Create first hotfix: e.g., 1.2.3-hotfix
gh workflow run release.yml \
  -f release-scope=prerelease \
  -f pre-release-type=hotfix \
  -f dry-run=false

# Increment hotfix: e.g., 1.2.3-hotfix.1
gh workflow run release.yml \
  -f release-scope=prerelease \
  -f pre-release-type=hotfix \
  -f dry-run=false
```

> **Implementation gap:** The `pre-release-type` input in `release.yml` is currently limited to `alpha`, `beta`, and `rc` choices. You must add `hotfix` to the `pre-release-type` options in `.github/workflows/release.yml` before this works:
>
> ```yaml
> pre-release-type:
>   options:
>     - alpha
>     - beta
>     - rc
>     - hotfix    # Add this
> ```

**Method 2: Create the hotfix tag manually.**

If you need to hotfix from a specific commit rather than the branch tip:

1. **Check out the tag you want to hotfix:**

   ```bash
   git checkout v1.2.3
   git checkout -b hotfix/1.2.4
   ```

2. **Apply your fix and push the branch:**

   ```bash
   # make changes, commit
   git push origin hotfix/1.2.4
   ```

3. **Create and push the tag manually:**

   ```bash
   git tag -a v1.2.3-hotfix.1 -m "Hotfix release v1.2.3-hotfix.1"
   git push origin v1.2.3-hotfix.1
   ```

4. The tag push triggers the `prepare` job in the release workflow, which calls `ci-09-parse-tag.sh` **(REAL)** to extract the version `1.2.3-hotfix.1` from the tag. Since the version contains a `-`, it is correctly marked as `is-prerelease=true`.

5. Downstream jobs (build, test, publish) proceed normally.

**Important:** Remember to merge or cherry-pick your hotfix back into `main`/`develop` so the fix is not lost in future releases.

---

## How do I compute which version should be next for release from conventional commits?

**Built in via e-bash.** The complete pipeline for computing the next version from conventional commits exists across the e-bash library:

1. **Version arithmetic** -- `ci-10-determine-version.sh` uses e-bash `_semver.sh` for parsing (`semver:parse`), bumping (`semver:increase:major/minor/patch`), comparison (`semver:compare`), and recomposition (`semver:recompose`). Fully tested SemVer 2.0.0 in pure bash.

2. **Conventional commit parsing** -- The e-bash library provides [`git.conventional-commits.sh`](https://github.com/OleksandrKucherenko/e-bash/blob/master/bin/git.conventional-commits.sh), which can be sourced and provides:
   - `conventional:parse "feat(auth): add login"` → populates `__conventional_parse_result` with `type`, `scope`, `breaking`, `description`, `body`, `footer`
   - `conventional:is_valid_commit <hash>` → validates commit against conventional format
   - `conventional:is_version_commit <hash>` → detects if commit triggers a version bump (feat, fix, perf, BREAKING CHANGE)
   - `conventional:recompose` → reconstructs commit message from parsed parts
   - Configurable via `CONVENTIONAL_COMMIT_TYPES` array and `.version-commit-config` file

3. **Full semantic version calculator** -- [`git.semantic-version.sh`](https://github.com/OleksandrKucherenko/e-bash/blob/master/bin/git.semantic-version.sh) analyzes the conventional commit history and calculates the next semantic version automatically. It walks commits since the last tag, classifies each using `conventional:parse`, determines the highest-priority bump (breaking → major, feat → minor, fix → patch), and outputs the next version.

4. **Commit verification** -- [`git.verify-all-commits.sh`](https://github.com/OleksandrKucherenko/e-bash/blob/master/bin/git.verify-all-commits.sh) verifies all commits in the repository for conventional commit compliance. Supports `--branch` (only current branch) and `--patch` (interactive mode to fix non-compliant messages).

**To wire this into the release pipeline,** create a hook script in `ci-cd/ci-10-determine-version/begin-detect-scope.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Source the conventional commits library from e-bash
source "$E_BASH/../bin/git.conventional-commits.sh"

LAST_TAG=$(git describe --tags --match "v*" --abbrev=0 2>/dev/null || echo "")
SCOPE="patch"

if [ -n "$LAST_TAG" ]; then
  while IFS= read -r hash; do
    [ -z "$hash" ] && continue
    if conventional:is_valid_commit "$hash"; then
      type="${__conventional_parse_result[type]}"
      breaking="${__conventional_parse_result[breaking]}"
      if [ "$breaking" = "!" ]; then
        SCOPE="major"; break  # breaking wins, stop scanning
      elif [ "$type" = "feat" ] && [ "$SCOPE" != "major" ]; then
        SCOPE="minor"
      fi
    fi
  done < <(git log "$LAST_TAG"..HEAD --format=%H)
fi

# Communicate scope back to the parent CI script
echo "contract:env:CI_RELEASE_SCOPE=$SCOPE"
```

The hook communicates the scope back via `contract:env:CI_RELEASE_SCOPE=VALUE` and the existing `ci-10-determine-version.sh` receives it. All downstream version arithmetic is already handled by `_semver.sh`.

> **Note:** The e-bash `bin/` scripts (`git.semantic-version.sh`, `git.conventional-commits.sh`, `git.verify-all-commits.sh`) live in the [upstream e-bash repository](https://github.com/OleksandrKucherenko/e-bash/tree/master/bin) and are not currently included in the CI Excellence `scripts/lib/` subtree. To use them, either copy them into your project or add the e-bash `bin/` directory to your PATH.

---

## How do CI feature flags (ENABLE_*) change which jobs run in each workflow?

Every `ENABLE_*` flag is a **GitHub Repository Variable** (not a secret) that defaults to `'false'` when unset. Each workflow reads them in its top-level `env:` block using the pattern:

```yaml
ENABLE_COMPILE: ${{ vars.ENABLE_COMPILE || 'false' }}
```

Individual jobs use `if:` conditions to check these values. When a flag is `'false'` or unset, the corresponding job is **skipped** (not failed). Downstream jobs that depend on a skipped job use `always()` combined with result checks like `needs.build.result == 'skipped'` to continue running.

**Complete flag-to-job mapping:**

### Pre-Release (`pre-release.yml`)

| Flag | Controls Job |
|---|---|
| `ENABLE_COMPILE` | `compile` -- Build/compile step |
| `ENABLE_LINT` | `lint` -- Code linting |
| `ENABLE_UNIT_TESTS` | `unit-tests` -- Unit test execution |
| `ENABLE_INTEGRATION_TESTS` | `integration-tests` -- Integration tests |
| `ENABLE_E2E_TESTS` | `e2e-tests` -- End-to-end tests |
| `ENABLE_BUNDLE` | `bundle` -- Bundle/package creation |
| `ENABLE_SECURITY_SCAN` | `security-scan` -- Vulnerability scanning |

### Release (`release.yml`)

| Flag | Controls Job |
|---|---|
| `ENABLE_COMPILE` | `build` -- Build release artifacts |
| `ENABLE_TESTS` | `test` -- Test release build |
| `ENABLE_NPM_PUBLISH` | `publish-npm` -- Publish to NPM registry |
| `ENABLE_GITHUB_RELEASE` | `publish-github` -- Create GitHub Release |
| `ENABLE_DOCKER_PUBLISH` | `publish-docker` -- Build and push Docker image |
| `ENABLE_DOCUMENTATION` | `publish-documentation` -- Build and publish docs |

### Post-Release (`post-release.yml`)

| Flag | Controls Job/Step |
|---|---|
| `ENABLE_ROLLBACK` | `rollback` -- Rollback a bad release |
| `ENABLE_DEPLOYMENT_VERIFICATION` | `verify-deployment` -- Verify published artifacts |
| `ENABLE_STABILITY_TAGGING` | `tag-stable` / `tag-unstable` -- Apply stability tags |

### Maintenance (`maintenance.yml`)

| Flag | Controls Job/Steps |
|---|---|
| `ENABLE_CLEANUP` | Steps within `cleanup` job |
| `ENABLE_FILE_SYNC` | Steps within `sync-files` job |
| `ENABLE_DEPRECATION` | Steps within `deprecate-old-versions` job |
| `ENABLE_SECURITY_AUDIT` | Steps within `security-audit` job |
| `ENABLE_DEPENDENCY_UPDATE` | Steps within `dependency-update` job |

### Auto-Fix (`auto-fix-quality.yml`)

| Flag | Default | Purpose |
|---|---|---|
| `AUTO_COMMIT` | `'true'` | Allow auto-commit of fixes |
| `AUTO_APPLY_FIXES` | `'true'` | Apply fixes automatically |
| `PUSH_CHANGES` | `'false'` | Push auto-committed changes back |

### All Workflows

| Flag | Purpose |
|---|---|
| `ENABLE_NOTIFICATIONS` | Gate notification delivery (checked in every workflow's `notify` job) |

---

## How do I get a list of all available ENABLE_* flags/env variables?

**Option 1 -- Read the env template:**

The canonical reference is `config/.env.template`. However, as of this writing it only contains the CHANGELOG template, not the env vars.

**Option 2 -- Extract from workflow files directly:**

```bash
grep -h 'ENABLE_\|AUTO_COMMIT\|AUTO_APPLY\|PUSH_CHANGES' .github/workflows/*.yml | \
  grep 'vars\.' | \
  sed 's/.*vars\.\([A-Z_]*\).*/\1/' | \
  sort -u
```

**Option 3 -- Refer to the table in the previous answer**, which is the complete list derived from all six workflow files.

**Option 4 -- Check the GitHub UI:**

Go to your repository > Settings > Secrets and variables > Actions > Variables tab. This shows all currently-set variables but will not show variables that have never been set.

---

## How do I publish release artifacts when compile/build is disabled via feature flags?

When `ENABLE_COMPILE` is `false`, the `build` job in `release.yml` is skipped. The publish jobs (`publish-npm`, `publish-github`, `publish-docker`) are designed to handle this gracefully:

```yaml
# From publish-npm job
if: |
  always() &&
  needs.prepare.result == 'success' &&
  (needs.build.result == 'success' || needs.build.result == 'skipped') &&
  (needs.test.result == 'success' || needs.test.result == 'skipped') &&
  vars.ENABLE_NPM_PUBLISH == 'true'
```

The `needs.build.result == 'skipped'` clause allows the publish job to proceed even when build was skipped. Similarly, the "Download build artifacts" step in publish jobs is conditional:

```yaml
- name: Download build artifacts
  if: ${{ vars.ENABLE_COMPILE == 'true' }}
  uses: actions/download-artifact@v4
```

**In practice this means:**

- If your project does not need a compile step (e.g., publishing raw source as an npm package), you can leave `ENABLE_COMPILE=false` and the publish jobs will run without build artifacts.
- If your publish scripts **require** compiled artifacts (e.g., Docker images that need a `dist/` directory), the publish scripts themselves will fail when they cannot find the expected files. You must ensure your publish scripts (stubs like `ci-66-publish-npm-release.sh`, `ci-80-publish-docker.sh`) handle the absence of build artifacts or you must enable `ENABLE_COMPILE`.

---

## How do I conditionally enable/disable workflows based on file changes (path filters)?

**This is NOT currently implemented** in the CI Excellence workflows. None of the workflow files use `paths:` or `paths-ignore:` filters.

**To add path filtering, edit the workflow trigger in the relevant `.yml` file:**

```yaml
# Example: Only run pre-release on source changes
on:
  pull_request:
    branches: [main, develop]
    paths:
      - 'src/**'
      - 'package.json'
      - 'tsconfig.json'
    paths-ignore:
      - 'docs/**'
      - '*.md'
```

**Alternative -- use dorny/paths-filter action** for per-job filtering:

```yaml
jobs:
  changes:
    runs-on: ubuntu-latest
    outputs:
      src: ${{ steps.filter.outputs.src }}
    steps:
      - uses: dorny/paths-filter@v3
        id: filter
        with:
          filters: |
            src:
              - 'src/**'

  build:
    needs: changes
    if: needs.changes.outputs.src == 'true'
    # ...
```

---

## How do I temporarily disable a workflow without deleting it?

There are several approaches, from least to most invasive:

**1. Disable via GitHub UI (recommended):**

Go to Actions tab > select the workflow > click the `...` menu (top right) > "Disable workflow". This stops all triggers. Re-enable the same way.

**2. Disable via gh CLI:**

```bash
gh workflow disable release.yml
# Re-enable later:
gh workflow enable release.yml
```

**3. Add `workflow_dispatch` as the only trigger temporarily:**

Replace all triggers with just `workflow_dispatch` so the workflow only runs when manually triggered:

```yaml
on:
  workflow_dispatch: {}
  # push:           # commented out
  # pull_request:   # commented out
```

**4. Add a global condition:**

Add an `if:` condition to every job (or to a single initial job that all others depend on):

```yaml
jobs:
  gate:
    if: ${{ vars.ENABLE_RELEASE_PIPELINE == 'true' }}
    # ...
```

---

## How do I set different feature flags for different branches?

**GitHub Variables are repository-scoped** and apply uniformly to all branches. There is no built-in per-branch variable override.

**Workarounds:**

**1. Use GitHub Environments (recommended):**

Create GitHub Environments (e.g., `development`, `production`) with different variable values. Reference the environment in your workflow jobs:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    environment: ${{ github.ref == 'refs/heads/main' && 'production' || 'development' }}
```

Environment-scoped variables override repository-scoped ones.

**2. Use branch-name conditions in the workflow:**

```yaml
env:
  ENABLE_LINT: ${{ github.ref == 'refs/heads/main' && 'true' || vars.ENABLE_LINT || 'false' }}
```

**3. Use a config file checked into the repo:**

Create branch-specific `.ci-config` files and source them in your scripts. Since each branch can have different file contents, this gives you per-branch control.

---

## How can I apply CI environment variable on server side? Like disable Lint step for all workflows?

**Set the variable in GitHub Repository Settings:**

1. Navigate to your repository on GitHub.
2. Go to **Settings > Secrets and variables > Actions > Variables** tab.
3. Click **New repository variable**.
4. Set name to `ENABLE_LINT` and value to `false`.
5. Click **Add variable**.

**Using gh CLI:**

```bash
# Set a variable
gh variable set ENABLE_LINT --body "false"

# Verify
gh variable list

# Set multiple at once
gh variable set ENABLE_COMPILE --body "true"
gh variable set ENABLE_LINT --body "false"
gh variable set ENABLE_UNIT_TESTS --body "true"
gh variable set ENABLE_INTEGRATION_TESTS --body "false"
```

This takes effect immediately for all future workflow runs. Any workflow that references `${{ vars.ENABLE_LINT }}` will pick up the new value.

**To disable a flag globally**, either set it to `false` or delete it entirely (since all workflows default to `'false'` when the variable is unset):

```bash
# These are equivalent:
gh variable set ENABLE_LINT --body "false"
gh variable delete ENABLE_LINT
```

**Important:** These are **Variables**, not **Secrets**. Variables are visible in workflow logs. Do not use them for sensitive values.

---

## Documentation Gaps

The following areas are poorly documented or missing from the project and would benefit from improvement:

1. **No `config/.env.template` for feature flags.** The `config/.env.template` file contains only a CHANGELOG template, not a reference list of all `ENABLE_*` variables with descriptions and defaults. A dedicated `config/variables.env.example` or a table in the config directory would be valuable.

2. **Version file update is not wired into the release workflow.** The `ci-15-update-version.sh` (STUB) and `ci-18-commit-version-changes.sh` (REAL) exist but are never called by `release.yml`. There is no documented recommended integration point for these scripts.

3. **Changelog generation is a stub with no default implementation.** The `ci-20-generate-changelog.sh` script runs in the release pipeline but does nothing. There is no guidance on which tool to choose (conventional-changelog vs. git-cliff vs. standard-version) or how to integrate it.

4. **Release notes are a static template.** The `ci-25-generate-release-notes.sh` script outputs hardcoded text. It does not extract from CHANGELOG.md or git log, making every GitHub Release have identical notes.

5. **No conventional-commit-based version detection.** The `CI_RELEASE_SCOPE` must always be specified manually. There is no script or integration to infer the scope from commit messages.

6. **No hotfix workflow or branching strategy documentation.** Hotfix releases require manual tag creation. There is no documented branching model (e.g., git-flow, trunk-based) or hotfix procedure.

7. **No path-filter configuration.** Workflows trigger on all changes to matching branches regardless of which files changed. No `paths:` filters are configured.

8. **No per-branch or per-environment variable documentation.** The framework does not document how to use GitHub Environments for branch-specific flag overrides.

9. **No way to release a specific commit.** The `workflow_dispatch` trigger lacks a `ref` or `commit` input, forcing users to create temporary branches or manual tags for non-tip releases.

10. **The auto-fix workflow flags default to `true` unlike all other flags.** `AUTO_COMMIT` and `AUTO_APPLY_FIXES` default to `'true'` while every `ENABLE_*` flag defaults to `'false'`. This inconsistency is not documented and could surprise users.
