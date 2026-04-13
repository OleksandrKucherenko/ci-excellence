# Maintenance and Operations

> Answers to frequently asked questions about the maintenance workflow, cleanup, version management, and dependency updates in the CI Excellence framework.

The maintenance pipeline is defined in `.github/workflows/maintenance.yml`. It runs daily at **2 AM UTC** via cron schedule and can also be triggered manually through `workflow_dispatch` with a specific action choice.

> **Extension Model:** CI Excellence uses a hooks system for customization. Rather than editing scripts in `scripts/ci/` directly, create hook scripts in `ci-cd/{step_name}/` directories. Each CI step runs `begin` hooks before its main logic and `end` hooks after. For example, to add custom cleanup logic, create `ci-cd/ci-30-cleanup-workflow-runs/begin-archive-logs.sh`. Hook scripts are auto-discovered (matching patterns `{hook}-*.sh` or `{hook}_*.sh`) and executed in alphabetical order. Hook scripts can communicate values back via `contract:env:NAME=VALUE` on stdout. See the [Hooks System](../HOOKS.md) for full details.

---

## How do I trigger all maintenance tasks in one run?

Use the GitHub Actions manual dispatch (workflow_dispatch) and select **all** from the action dropdown:

1. Go to **Actions** > **Maintenance Pipeline** in your repository.
2. Click **Run workflow**.
3. Select `all` from the "Maintenance action to perform" dropdown.
4. Click **Run workflow**.

This executes every job in sequence: `cleanup`, `sync-files`, `deprecate-old-versions`, `security-audit`, and `dependency-update`. Each job is gated by its own `ENABLE_*` repository variable, so even with `all` selected, only jobs whose flags are set to `'true'` will perform real work. The `notify` job always runs at the end and aggregates results from all jobs.

Alternatively, the daily cron schedule (`0 2 * * *`) triggers all jobs automatically since the workflow condition for each job includes `github.event_name == 'schedule'`.

**Required repository variables (set to `'true'` to activate):**

| Variable | Controls |
|---|---|
| `ENABLE_CLEANUP` | Workflow run, artifact, and cache cleanup |
| `ENABLE_FILE_SYNC` | Version file synchronization |
| `ENABLE_DEPRECATION` | Version deprecation (NPM + GitHub) |
| `ENABLE_SECURITY_AUDIT` | Security scanning and dependency audit |
| `ENABLE_DEPENDENCY_UPDATE` | Automated dependency upgrades |

---

## How do I clean up old workflow runs, caches, and artifacts?

Trigger the maintenance workflow with the `cleanup` action. This runs three scripts in order:

1. **`scripts/ci/maintenance/ci-30-cleanup-workflow-runs.sh`** (STUB) -- Deletes old workflow runs. The stub contains a commented `gh run list` / `gh run delete` example that filters runs older than 30 days.
2. **`scripts/ci/maintenance/ci-40-cleanup-artifacts.sh`** (STUB) -- Deletes old artifacts. The stub contains a commented `gh api` example that queries `repos/:owner/:repo/actions/artifacts` and deletes entries older than a configurable `RETENTION_DAYS` (defaulting to 7).
3. **`scripts/ci/maintenance/ci-50-cleanup-caches.sh`** (STUB) -- Deletes stale caches. The stub contains a commented `gh api` example that queries `repos/:owner/:repo/actions/caches` and deletes entries not accessed in 7 days.

**All three scripts are stubs.** To activate them:

1. Set the repository variable `ENABLE_CLEANUP` to `'true'`.
2. Implement your cleanup logic via hook scripts in the appropriate `ci-cd/{step_name}/` directories (e.g., `ci-cd/ci-30-cleanup-workflow-runs/begin-delete-old-runs.sh`, `ci-cd/ci-40-cleanup-artifacts/begin-prune-artifacts.sh`). The stubs contain commented `gh` CLI examples to use as implementation reference.
3. The `cleanup` job requires `actions: write` and `contents: read` permissions, which are already declared in the workflow.

After cleanup, `scripts/ci/reports/ci-30-summary-cleanup.sh` generates a summary report regardless of success or failure.

---

## How do I delete temporary canary or bug-fix artifacts after testing?

Canary and bug-fix artifacts are uploaded with the standard retention configured through `ARTIFACT_RETENTION_DAYS` (default: 7 days). They will expire automatically after that period.

To delete them immediately:

1. **Manual via GitHub UI:** Go to the workflow run, scroll to the Artifacts section, and delete individual artifacts.
2. **Via gh CLI:**
   ```bash
   # List artifacts for a specific run
   gh run view <run-id> --json artifacts

   # Delete a specific artifact by ID
   gh api -X DELETE "repos/:owner/:repo/actions/artifacts/<artifact-id>"
   ```
3. **Via the cleanup job:** Customize `scripts/ci/maintenance/ci-40-cleanup-artifacts.sh` to filter artifacts by name pattern (e.g., names containing `canary` or `bugfix`) and delete them proactively.

---

## How do I set retention days for build artifacts, deliverables, and reports?

Retention is controlled by three repository variables defined in the workflow environment (see `.github/workflows/pre-release.yml` for their declarations):

| Variable | Default | Purpose |
|---|---|---|
| `ARTIFACT_RETENTION_DAYS` | 7 | Short-lived build artifacts (test results, coverage) |
| `DELIVERABLE_RETENTION_DAYS` | 14 | Publishable outputs (bundles, packages) |
| `REPORT_RETENTION_DAYS` | 30 | Audit reports, security scans, summaries |

To change these values:

1. Go to **Settings** > **Secrets and variables** > **Actions** > **Variables** tab.
2. Create or update the variable with the desired number of days.
3. Workflows reference these as `${{ vars.ARTIFACT_RETENTION_DAYS || 7 }}`, so the default applies if no variable is set.

The `retention-days` parameter on each `actions/upload-artifact` step uses the appropriate variable. The maintenance cleanup scripts do not currently enforce these thresholds -- they are independent of the upload-time retention. If you need cleanup to respect the same values, pass them as environment variables to the cleanup scripts.

---

## How do I clean up workflow runs older than X days across all branches?

The stub script `scripts/ci/maintenance/ci-30-cleanup-workflow-runs.sh` contains a commented example that does exactly this:

```bash
RETENTION_DAYS=30
CUTOFF_DATE=$(date -d "$RETENTION_DAYS days ago" +%Y-%m-%d)

gh run list --limit 1000 --json databaseId,createdAt \
    --jq ".[] | select(.createdAt < \"$CUTOFF_DATE\") | .databaseId" | \
while read -r run_id; do
    gh run delete "$run_id" || true
done
```

To customize:

1. Create a hook script in `ci-cd/ci-30-cleanup-workflow-runs/` (e.g., `begin-delete-old-runs.sh`) with the cleanup logic from the stub's commented examples.
2. Adjust `RETENTION_DAYS` to your desired threshold, or read it from an environment variable.
3. Note that `gh run list` returns runs across all branches by default. To filter by branch, add `--branch <name>`. To include all workflows, you may need to loop over `gh workflow list`.
4. The `--limit 1000` cap means very large repositories may need pagination or multiple runs to clean everything.
5. Set `ENABLE_CLEANUP` to `'true'` in repository variables.

---

## How do I archive important workflow runs before cleanup?

There is no built-in archival mechanism in the framework. Before enabling automated cleanup, consider these approaches:

1. **Export logs manually:**
   ```bash
   gh run view <run-id> --log > "archive/run-<run-id>.log"
   ```
2. **Download artifacts before expiry:**
   ```bash
   gh run download <run-id> -D "archive/run-<run-id>/"
   ```
3. **Add an archival step to the cleanup script:** Before the deletion loop in `ci-30-cleanup-workflow-runs.sh`, add logic to download logs/artifacts for runs matching specific criteria (e.g., release runs, failed runs) to an external storage location (S3, GCS, or a separate repository).
4. **Tag important runs:** Use GitHub's "pin" feature on workflow runs you want to preserve, and modify the cleanup script to skip pinned runs.

This is a gap in the current framework -- you will need to implement archival logic yourself.

---

## How do I monitor and alert on high storage usage in GitHub Actions?

The framework does not include built-in storage monitoring. Here are practical approaches:

1. **Check current usage via the GitHub API:**
   ```bash
   gh api /repos/:owner/:repo/actions/cache/usage
   gh api /repos/:owner/:repo/actions/artifacts --jq '.total_count'
   ```
2. **Add a monitoring step to the cleanup job:** Before cleanup runs, query the API for cache and artifact counts/sizes, then compare against thresholds. If storage exceeds a limit, send a notification using the existing notification scripts (`scripts/ci/notification/ci-30-send-notification.sh`).
3. **Use the notify job:** The maintenance workflow's `notify` job already aggregates results and sends notifications. Extend the cleanup report script (`scripts/ci/reports/ci-30-summary-cleanup.sh`) to include storage metrics.
4. **External monitoring:** Export metrics to Datadog, Prometheus, or similar by adding API calls to the maintenance workflow.

---

## How do I sync package.json and CHANGELOG.md with the latest published release?

Trigger the maintenance workflow with the `sync-files` action. The sync job runs two scripts:

1. **`scripts/ci/maintenance/ci-10-sync-files.sh`** (STUB) -- Contains commented examples for:
   - Querying the latest published NPM version via `npm view <package> version`.
   - Comparing it to the local `package.json` version.
   - Updating `package.json` with `jq` if they differ.
   - Creating a `CHANGELOG.md` if one does not exist.

2. **`scripts/ci/maintenance/ci-20-check-changes.sh`** (REAL) -- Runs `git diff --quiet` to detect whether the sync produced any changes and sets the `has-changes` output.

If changes are detected, the workflow automatically creates a PR via `peter-evans/create-pull-request@v5` on the branch `maintenance/sync-files` with the commit message `chore: sync version files with published releases`. The PR is auto-cleaned up when merged (`delete-branch: true`).

**To activate:**

1. Set `ENABLE_FILE_SYNC` to `'true'`.
2. Implement your sync logic via a hook script in `ci-cd/ci-10-sync-files/` (e.g., `begin-sync-package-version.sh`). The stub contains commented examples to use as reference for matching your package registry and changelog format.
3. The job requires `contents: write` and `pull-requests: write` permissions (already declared).

---

## How do I deprecate NPM versions older than a specific baseline?

Trigger the maintenance workflow with the `deprecate-old-versions` action. The deprecation pipeline runs three scripts:

1. **`scripts/ci/maintenance/ci-70-identify-deprecated-versions.sh`** (STUB) -- Contains commented examples for listing versions older than 1 year and identifying superseded pre-release versions via `npm view`.
2. **`scripts/ci/maintenance/ci-75-deprecate-npm-versions.sh`** (STUB with validation) -- Validates that `NODE_AUTH_TOKEN` is set (exits with error if missing), then contains a commented example using `npm deprecate` to mark old alpha/beta versions.
3. The NPM deprecation step only runs when **both** `ENABLE_DEPRECATION` and `ENABLE_NPM_PUBLISH` are set to `'true'`.

**To activate:**

1. Set `ENABLE_DEPRECATION` and `ENABLE_NPM_PUBLISH` to `'true'` in repository variables.
2. Store your NPM token as the `NPM_TOKEN` secret (the workflow passes it as `NODE_AUTH_TOKEN`).
3. Implement your deprecation policy via a hook script in `ci-cd/ci-70-identify-deprecated-versions/` (e.g., `begin-find-old-versions.sh`) defining age thresholds and version patterns. The stub has commented examples for reference.
4. Implement the NPM deprecation via a hook script in `ci-cd/ci-75-deprecate-npm-versions/` (e.g., `begin-deprecate-old.sh`) with your `npm deprecate` logic and custom message.

Example deprecation command for versions below a baseline:

```bash
PACKAGE_NAME=$(jq -r '.name' package.json)
npm deprecate "${PACKAGE_NAME}@<1.0.0" \
    "This version is deprecated. Please upgrade to >=1.0.0."
```

> **e-bash `_semver.sh` for deprecation logic:** When writing your deprecation hook script, use `semver:constraints` to identify versions outside acceptable ranges. For example, `semver:constraints "$VERSION" ">=1.0.0"` returns non-zero for versions that should be deprecated. You can also use `semver:compare "$VERSION" "$BASELINE"` to compare against a minimum acceptable version, and `semver:parse "$VERSION" "parsed"` to inspect pre-release components (e.g., deprecate all alpha/beta versions older than 6 months).

---

## How do I deprecate GitHub releases for superseded versions?

The script `scripts/ci/maintenance/ci-80-deprecate-github-releases.sh` (STUB) handles this. It contains a commented example that:

1. Lists all pre-releases via `gh release list --limit 100`.
2. Checks each release's body for an existing `DEPRECATED` notice.
3. Prepends a deprecation warning to the release notes via `gh release edit`.

**To activate:**

1. Set `ENABLE_DEPRECATION` and `ENABLE_GITHUB_RELEASE` to `'true'`.
2. Implement your deprecation logic via a hook script in `ci-cd/ci-80-deprecate-github-releases/` (e.g., `begin-deprecate-prereleases.sh`). The stub contains commented examples for reference.
3. The `GITHUB_TOKEN` is already passed by the workflow.

You can extend the stub to also mark releases as pre-release (demoting them) or to delete draft releases:

```bash
# Mark a release as pre-release
gh release edit "$tag" --prerelease

# Delete a draft release
gh release delete "$tag" --yes
```

---

## How do I bulk update version numbers across multiple package.json files in a monorepo?

The framework does not include a dedicated monorepo bulk-version script. The `sync-files` job (`ci-10-sync-files.sh`) is a stub designed for single-package repositories.

For monorepos, customize `ci-10-sync-files.sh` or create a new script. Approaches:

1. **Using npm workspaces:**
   ```bash
   npm version <new-version> --workspaces --no-git-tag-version
   ```
2. **Using jq across all package.json files:**
   ```bash
   find . -name "package.json" -not -path "*/node_modules/*" | while read -r pkg; do
       jq --arg v "$NEW_VERSION" '.version = $v' "$pkg" > "${pkg}.tmp"
       mv "${pkg}.tmp" "$pkg"
   done
   ```
3. **Using dedicated tools:** `lerna version`, `changeset version`, or `nx release` handle monorepo versioning with dependency graph awareness.

Wire your chosen approach into the `sync-files` job so it creates a PR automatically when versions change.

---

## How do I prevent accidental version downgrades?

The framework does not enforce version ordering by default, but the e-bash `_semver.sh` library provides all the tools needed to implement it. To add protection:

1. **In the sync-files script:** Before updating `package.json`, use the e-bash `semver:compare` function to reject downgrades:
   ```bash
   source scripts/lib/_semver.sh
   CURRENT=$(jq -r '.version' package.json)
   CANDIDATE="1.3.0"
   RESULT=$(semver:compare "$CANDIDATE" "$CURRENT")
   if [ "$RESULT" -eq 2 ]; then
     echo "ERROR: Version downgrade detected: $CANDIDATE < $CURRENT"
     exit 1
   fi
   ```
   `semver:compare` returns `0` (equal), `1` (first is greater), or `2` (first is less). You can also use `semver:constraints "$CANDIDATE" ">=$CURRENT"` for range-based validation.

2. **In a pre-commit hook or CI check:**
   ```bash
   source scripts/lib/_semver.sh
   CURRENT=$(jq -r '.version' package.json)
   PUBLISHED=$(npm view "$(jq -r '.name' package.json)" version 2>/dev/null || echo "0.0.0")
   if [ "$(semver:compare "$CURRENT" "$PUBLISHED")" -eq 2 ]; then
     echo "ERROR: package.json version $CURRENT is older than published $PUBLISHED"
     exit 1
   fi
   ```
3. **Branch protection rules:** Require status checks that validate version numbers are non-decreasing compared to the base branch.
4. **In the release workflow:** The release pipeline (`scripts/ci/release/ci-10-determine-version.sh` and `ci-05-select-version.sh`) already uses `_semver.sh` for version computation -- add a `semver:compare` guard before tag creation to reject downgrades automatically.

---

## How to avoid version conflicts between different PRs?

Version conflicts arise when multiple PRs modify `package.json` or changelog files simultaneously. Strategies:

1. **Defer version bumps to the release workflow:** Do not bump versions in feature PRs. Let the release pipeline compute the next version from conventional commits at release time (this is the design intent of the `ci-10-determine-version.sh` script).
2. **Use the maintenance sync job:** After a release publishes, the `sync-files` job creates a single PR to update version files, avoiding concurrent edits.
3. **Branch protection:** Enable "Require branches to be up to date before merging" so PRs must rebase against the latest main before merge.
4. **Lock files:** If using tools like changesets, each PR adds a changeset file (not a version bump), and a single "Version Packages" PR aggregates them.

The key principle: version numbers should be computed at release time, not during feature development.

---

## How do I run automated dependency upgrades and open a PR?

Trigger the maintenance workflow with the `dependency-update` action. The job runs three scripts:

1. **`scripts/ci/maintenance/ci-90-update-dependencies.sh`** (STUB) -- Contains commented examples for updating dependencies across multiple ecosystems: `npm update`, `yarn upgrade`, `pip install -U`, `go get -u ./...`, `cargo update`. Implement your update logic via a hook script in `ci-cd/ci-90-update-dependencies/` (e.g., `begin-npm-update.sh`). The stub's commented examples serve as reference.
2. **`scripts/ci/maintenance/ci-91-test-after-update.sh`** (REAL) -- Runs unit tests via `scripts/ci/test/ci-10-unit-tests.sh` to validate the updates. Test failures are caught but do not block the PR creation -- they are noted in the PR description.
3. **`scripts/ci/maintenance/ci-20-check-changes.sh`** (REAL) -- Checks `git diff --quiet` to detect whether any files changed.

If changes are detected, the workflow creates a PR via `peter-evans/create-pull-request@v5`:
- Branch: `maintenance/dependency-updates`
- Title: `chore(deps): automated dependency updates`
- Label: `dependencies`
- The branch is auto-deleted on merge.

**To activate:**

1. Set `ENABLE_DEPENDENCY_UPDATE` to `'true'`.
2. Create a hook script in `ci-cd/ci-90-update-dependencies/` (e.g., `begin-npm-update.sh`) with the update commands for your package manager. The stub's commented examples serve as reference.
3. The job requires `contents: write` and `pull-requests: write` permissions (already declared).

> **e-bash `_dependencies.sh` for tool verification:** Before running dependency updates, use the e-bash `_dependencies.sh` module to verify required tools are available and at the correct version. For example, `dependency:exists npm` checks if npm is in PATH, and `dependency:version:gte "$(npm --version)" "9.0.0"` confirms it meets a minimum version. The `dependency:find "node" "18.0.0"` function finds a tool matching a minimum version requirement. These checks include built-in alias resolution (e.g., `rust` resolves to `rustc`) and disk-backed caching for fast repeated checks.

---

## How do I pin specific dependency versions across the monorepo?

The framework does not provide a dedicated pinning mechanism. Standard approaches:

1. **Lock files:** Use `package-lock.json`, `pnpm-lock.yaml`, or `yarn.lock` and install with `--frozen-lockfile` / `npm ci` to ensure reproducible installs. The setup script `scripts/ci/setup/ci-20-install-dependencies.sh` contains (stubbed) examples of frozen-lockfile installs for each package manager.
2. **Exact versions in package.json:** Use exact version specifiers (no `^` or `~`):
   ```json
   "dependencies": {
     "lodash": "4.17.21"
   }
   ```
3. **Overrides/resolutions:** Force a specific version across all workspaces:
   - npm: `"overrides"` field in root `package.json`
   - yarn: `"resolutions"` field
   - pnpm: `"pnpm.overrides"` field
4. **Renovate/Dependabot configuration:** Pin versions via your dependency bot config and disable auto-merge for pinned packages.

When customizing `ci-90-update-dependencies.sh`, you can add logic to skip pinned dependencies or to restore pinned versions after a bulk update.

---

## How do I update a dependency in all workspace packages at once?

This depends on your package manager:

1. **npm workspaces:**
   ```bash
   npm install <package>@latest --workspaces
   ```
2. **pnpm:**
   ```bash
   pnpm update <package> --recursive
   ```
3. **yarn workspaces:**
   ```bash
   yarn upgrade <package> --latest
   # or with yarn berry:
   yarn up <package>
   ```

To integrate this into the maintenance workflow, customize `scripts/ci/maintenance/ci-90-update-dependencies.sh` with the appropriate command. The dependency-update job will then detect changes via `ci-20-check-changes.sh` and create a PR automatically.

---

## How do I test dependency updates in isolation before merging?

The maintenance workflow already includes a testing step:

1. **`scripts/ci/maintenance/ci-91-test-after-update.sh`** (REAL) runs `scripts/ci/test/ci-10-unit-tests.sh` immediately after updates are applied. If tests fail, the script logs the failure but does not abort -- the PR is still created with the note that tests failed.

2. The PR created by the dependency-update job includes the warning: **"Please review changes carefully and run tests before merging."**

For stronger isolation:

1. **Branch-scoped CI:** The auto-created PR on `maintenance/dependency-updates` will trigger your PR workflow (if configured), running the full build-and-test pipeline against the updated dependencies.
2. **Matrix testing:** Add a step in `ci-91-test-after-update.sh` to run integration and e2e tests as well (`ci-20-integration-tests.sh`, `ci-30-e2e-tests.sh`).
3. **Require status checks:** Configure branch protection to require the PR workflow to pass before the dependency PR can be merged.
4. **Manual review:** Do not enable auto-merge for dependency PRs. Review the diff, check for breaking changes in dependency changelogs, and run smoke tests.

---

## How do I handle conflicting dependency versions in a monorepo?

Conflicting versions occur when different workspace packages require incompatible versions of the same dependency. Strategies:

1. **Package manager resolutions:** Force a single version across all workspaces:
   - npm: `"overrides": { "conflicting-pkg": "^2.0.0" }` in root `package.json`
   - pnpm: `"pnpm": { "overrides": { "conflicting-pkg": "^2.0.0" } }`
   - yarn: `"resolutions": { "conflicting-pkg": "^2.0.0" }`

2. **Peer dependency alignment:** Hoist shared dependencies to the root `package.json` so all workspaces use the same resolved version.

3. **Audit with `npm ls` or `pnpm why`:**
   ```bash
   npm ls <package> --all     # shows version tree
   pnpm why <package>         # shows why a version is installed
   ```

4. **Integrate into CI:** Add a conflict detection step to `ci-90-update-dependencies.sh` that runs `npm ls --all 2>&1 | grep "ERESOLVE\|peer dep"` and fails if conflicts are found.

5. **Use the security audit job:** The `security-audit` action runs `scripts/ci/maintenance/ci-60-security-audit.sh` (STUB) which can be extended to include `npm audit` or `pnpm audit` as a way to catch vulnerable conflicting versions.

---

## Documentation Gaps

The following areas require additional implementation or documentation:

1. **All cleanup scripts are stubs.** `ci-30-cleanup-workflow-runs.sh`, `ci-40-cleanup-artifacts.sh`, and `ci-50-cleanup-caches.sh` contain only commented examples. They must be customized before they perform any real cleanup.

2. **The sync-files script is a stub.** `ci-10-sync-files.sh` contains commented examples for NPM-based projects but performs no actual synchronization until customized.

3. **All deprecation scripts are stubs.** `ci-70-identify-deprecated-versions.sh`, `ci-75-deprecate-npm-versions.sh`, and `ci-80-deprecate-github-releases.sh` require customization. The NPM deprecation script does validate that `NODE_AUTH_TOKEN` is present.

4. **The security audit script is a stub.** `ci-60-security-audit.sh` contains commented examples for npm, yarn, pip, and cargo audits but performs no real auditing. The companion script `ci-30-security-scan.sh` (in `scripts/ci/build/`) is real and runs gitleaks + trufflehog.

5. **The dependency update script is a stub.** `ci-90-update-dependencies.sh` contains commented examples for multiple ecosystems. The companion `ci-91-test-after-update.sh` is real and runs unit tests.

6. **No archival mechanism exists.** There is no script or workflow step to archive workflow runs or artifacts before cleanup.

7. **No storage monitoring exists.** There is no built-in mechanism to track or alert on GitHub Actions storage consumption.

8. **No monorepo bulk-versioning support.** The sync-files job is designed for single-package repos. Monorepo version management requires custom implementation.

9. **No version downgrade protection.** There is no automated guard against version regressions, though the e-bash `_semver.sh` library provides `semver:compare` and `semver:constraints` functions that make implementing one straightforward.

10. **No dependency conflict detection.** The framework does not detect or report conflicting dependency versions in monorepo workspaces.
