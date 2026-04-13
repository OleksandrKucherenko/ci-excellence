# Migration and Upgrades

Answers to common questions about upgrading CI Excellence versions, testing workflow changes, rollback procedures, and data migration. The primary migration reference is `docs/MIGRATION.md`, which covers the v1-to-v2 upgrade in detail.

> **Notation:** Steps marked **(REAL)** use fully implemented scripts. Steps marked **(STUB)** require you to customize the script body before they do real work. Items marked **(GitHub Platform)** are native GitHub features. Items marked **(Process)** are recommended procedures with no framework-specific tooling.

---

## How do I upgrade from CI Excellence vX.x to vY.y?

**(Process + CI Excellence)**

CI Excellence does not have a built-in auto-upgrade mechanism. Upgrades are performed via git merge or cherry-pick from the upstream repository. The detailed procedure for v1-to-v2 is documented in `docs/MIGRATION.md`.

**General upgrade procedure:**

**Step 1 -- Backup your current state:**

```bash
git checkout -b backup-before-upgrade
git push origin backup-before-upgrade
git checkout main
```

**Step 2 -- Fetch upstream changes:**

If you forked CI Excellence:

```bash
git remote add upstream https://github.com/ORIGINAL-OWNER/ci-excellence.git  # if not already added
git fetch upstream
git log --oneline upstream/main ^main  # review what's new
```

If you used CI Excellence as a template (no fork relationship):

```bash
# Add the original repo as a remote
git remote add ci-excellence https://github.com/ORIGINAL-OWNER/ci-excellence.git
git fetch ci-excellence
```

**Step 3 -- Merge or cherry-pick:**

```bash
# Option A: Merge all upstream changes
git merge upstream/main --no-commit
# Review changes, resolve conflicts
git commit -m "chore: upgrade CI Excellence to vX.Y"

# Option B: Cherry-pick specific commits
git cherry-pick <commit-sha>
```

**Step 4 -- Handle breaking changes:**

For the v1-to-v2 migration, the breaking changes are documented in `docs/MIGRATION.md`:

| Change | What broke | Fix |
|---|---|---|
| Script renumbering (01-04 to 10-40) | Custom workflows referencing old paths | `grep -r "ci-0[1-4]-" .github/workflows/` and update paths |
| `lefthook.yml` to `.lefthook.toml` | Custom lefthook hooks | Convert YAML to TOML format |
| `mise.toml` to `.config/mise/conf.d/` | Custom tool configurations | Move customizations to appropriate `conf.d/*.toml` file |
| TypeScript notifiers removed | Custom notification scripts | Rewrite using shell-based Apprise notifications |
| Conventional commits required | Non-conventional commit messages | All future commits must use `type(scope): subject` format |
| New git hooks via Lefthook | Old hook scripts in `.git/hooks/` | Run `lefthook install` (handled by mise setup) |

**Step 5 -- Verify:**

```bash
# Validate workflow files
mise run validate-workflows
# Or manually:
action-validator .github/workflows/*.yml

# Test git hooks
lefthook run pre-commit

# Test a workflow with dry-run
gh workflow run release.yml -f release-scope=patch -f dry-run=true
```

**Step 6 -- Run the post-migration checklist from `docs/MIGRATION.md`:**

Verify mise is working (`mise doctor`), git hooks are installed, workflows validate, conventional commits are enforced, CI pipeline runs successfully, GitHub Variables and Secrets are still set, and notifications work.

---

## How do I test workflow changes before deploying to production?

**(Process + GitHub Platform)**

There is no staging environment for GitHub Actions workflows. Here are the recommended testing approaches, from safest to most realistic.

**Approach 1 -- Use a feature branch with `workflow_dispatch`:**

Temporarily add a `workflow_dispatch` trigger to the workflow you are modifying (if it does not already have one). Push your changes to a feature branch and trigger the workflow from the Actions tab, selecting your branch:

```yaml
on:
  workflow_dispatch: {}  # Add temporarily for testing
  push:
    branches: [develop, 'feature/**']
```

GitHub runs the workflow version from the branch you select, so your changes are used.

**Approach 2 -- Use `act` for local testing:**

[`act`](https://github.com/nektos/act) runs GitHub Actions workflows locally using Docker:

```bash
# Install act
brew install act   # macOS
# or: curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Run the pre-release workflow locally
act push -W .github/workflows/pre-release.yml

# Run with specific event
act workflow_dispatch -W .github/workflows/release.yml \
  --input release-scope=patch --input dry-run=true

# Run a specific job
act -j compile -W .github/workflows/pre-release.yml
```

**Limitations of `act`:** It does not perfectly replicate GitHub's runner environment. Caching, secrets, GitHub context variables, and some actions may behave differently. Use it for basic syntax and logic validation, not for full integration testing.

**Approach 3 -- Use a fork or test repository:**

1. Fork or clone the repository.
2. Push your workflow changes to the fork.
3. Set up the necessary GitHub Variables (`ENABLE_COMPILE=true`, etc.) and Secrets in the fork.
4. Trigger workflows in the fork to validate behavior.
5. Once verified, apply the changes to the main repository.

**Approach 4 -- Use the dry-run input (Release workflow only):**

The Release Pipeline has a built-in `dry-run` input:

```bash
gh workflow run release.yml -f release-scope=patch -f dry-run=true
```

This runs the version calculation logic without creating tags or publishing anything.

**Approach 5 -- Create a test branch that matches workflow triggers:**

The Pre-Release and Auto-Fix Quality workflows trigger on pushes to `feature/**` branches. Push your workflow changes to a `feature/test-ci-changes` branch to trigger them:

```bash
git checkout -b feature/test-ci-changes
# Edit workflow files
git add .github/workflows/
git commit -m "ci: test workflow changes"
git push origin feature/test-ci-changes
```

The pre-release pipeline will run using the workflow definition from your branch.

---

## How do I rollback a workflow update if it breaks?

**(Process)**

Workflow files are tracked in git like any other code. Rolling back a broken workflow change is a standard git operation.

**Option 1 -- Revert the commit (recommended):**

```bash
# Find the commit that broke the workflow
gh run list --limit 5 --json name,status,headSha,createdAt \
  --jq '.[] | select(.status == "failure") | "\(.headSha) | \(.createdAt) | \(.name)"'

# Identify the workflow change commit
git log --oneline -- .github/workflows/

# Revert it
git revert <commit-sha>
git push origin main
```

This creates a new commit that undoes the change, preserving history.

**Option 2 -- Restore a specific file from a previous commit:**

```bash
# Restore pre-release.yml from the previous commit
git checkout HEAD~1 -- .github/workflows/pre-release.yml
git commit -m "ci: revert pre-release.yml to previous version"
git push origin main
```

**Option 3 -- Restore from the backup branch:**

If you created a backup branch before the upgrade (as recommended in `docs/MIGRATION.md`):

```bash
# Restore all workflow files from backup
git checkout backup-before-upgrade -- .github/workflows/
git commit -m "ci: restore workflows from backup"
git push origin main
```

**Option 4 -- Disable the broken workflow immediately:**

If you need to stop the bleeding before investigating:

```bash
# Disable the broken workflow
gh workflow disable pre-release.yml

# Fix the issue
# ...

# Re-enable
gh workflow enable pre-release.yml
```

**Important:** Workflow changes take effect immediately on push to the trigger branch. There is no deployment or propagation delay. If you push a fix to `main`, the next workflow trigger will use the fixed version.

---

## How do I maintain backward compatibility during upgrades?

**(Process + CI Excellence)**

The v1-to-v2 upgrade included breaking changes (script renumbering, config format changes). Here is how to mitigate compatibility issues during future upgrades.

**1. Use symlinks for renamed scripts:**

When scripts are renumbered (e.g., `ci-01-compile.sh` to `ci-10-compile.sh`), create symlinks at the old paths:

```bash
# In scripts/ci/build/
ln -s ci-10-compile.sh ci-01-compile.sh
ln -s ci-20-lint.sh ci-02-lint.sh
ln -s ci-30-security-scan.sh ci-03-security-scan.sh
ln -s ci-40-bundle.sh ci-04-bundle.sh
```

This allows old custom workflows or scripts to continue working while you migrate references. Remove the symlinks once all references are updated.

**2. Keep old config files during transition:**

When migrating from `lefthook.yml` to `.lefthook.toml`, keep the old file with a deprecation notice:

```yaml
# lefthook.yml - DEPRECATED: Migrate to .lefthook.toml
# This file will be removed in the next major version.
# See docs/MIGRATION.md for migration instructions.
```

**3. Use feature flags for new behavior:**

CI Excellence's `ENABLE_*` pattern is inherently backward-compatible. New features are disabled by default (`|| 'false'`), so upgrading the workflow files does not change behavior until you explicitly enable new flags.

**4. Test the upgrade on a branch first:**

Before merging upstream changes to `main`:

```bash
git checkout -b upgrade/ci-excellence-v2
git merge upstream/main
# Resolve conflicts
git push origin upgrade/ci-excellence-v2
```

The pre-release pipeline will run on this branch, validating that the new workflow files work with your codebase.

**5. Audit custom script references:**

```bash
# Find all references to CI scripts in your workflows
grep -r 'scripts/ci/' .github/workflows/ | grep -v '^#' | sort

# Compare with actual script paths
find scripts/ci/ -name '*.sh' | sort

# Find orphaned references (scripts referenced but not present)
comm -23 \
  <(grep -roh 'scripts/ci/[^ "]*\.sh' .github/workflows/ | sort -u) \
  <(find scripts/ci/ -name '*.sh' -printf '%P\n' | sed 's|^|scripts/ci/|' | sort -u)
```

---

## How do I migrate existing artifacts to new storage?

**(Process)**

GitHub Actions artifacts have a maximum retention period (default 90 days, configurable up to 400 days on enterprise plans). They are not designed for long-term storage. Migration scenarios typically involve moving artifacts to a more permanent location.

**Scenario 1 -- Download artifacts before they expire:**

```bash
# List artifacts for a specific workflow run
gh api repos/{owner}/{repo}/actions/runs/{run-id}/artifacts \
  --jq '.artifacts[] | "\(.id) | \(.name) | \(.expires_at)"'

# Download a specific artifact
gh run download <run-id> --name release-artifacts --dir ./archive/

# Bulk download recent artifacts
for run_id in $(gh run list --workflow release.yml --limit 10 --json databaseId --jq '.[].databaseId'); do
  gh run download "$run_id" --dir "./archive/$run_id/" 2>/dev/null || true
done
```

**Scenario 2 -- Move artifacts to GitHub Releases:**

GitHub Releases are permanent (no retention limit). Upload important artifacts as release assets:

```bash
# Upload an artifact to an existing release
gh release upload v1.2.3 ./archive/build-output.tar.gz
```

CI Excellence already does this via `scripts/ci/release/ci-30-upload-assets.sh` **(STUB)** in the `publish-github` job.

**Scenario 3 -- Move artifacts to external storage:**

Add a step to your workflow to upload artifacts to S3, GCS, or Azure Blob:

```yaml
- name: Archive to S3
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
  run: |
    aws s3 cp dist/ s3://your-bucket/releases/v${{ needs.prepare.outputs.version }}/ --recursive
```

**Note:** CI Excellence controls artifact retention through variables in `pre-release.yml`:

```yaml
ARTIFACT_RETENTION_DAYS: ${{ vars.ARTIFACT_RETENTION_DAYS || 7 }}
DELIVERABLE_RETENTION_DAYS: ${{ vars.DELIVERABLE_RETENTION_DAYS || 14 }}
REPORT_RETENTION_DAYS: ${{ vars.REPORT_RETENTION_DAYS || 30 }}
```

Adjust these values to keep artifacts longer before they are automatically deleted.

---

## How do I preserve workflow history during migration?

**(GitHub Platform)**

GitHub Actions workflow run history is tied to the workflow file's `name:` field, not its filename. Here is what happens during different migration scenarios.

**Scenario 1 -- Renaming a workflow file:**

If you rename `.github/workflows/ci.yml` to `.github/workflows/pre-release.yml` but keep the same `name: Pre-Release Pipeline`, GitHub treats it as the same workflow. Run history is preserved.

If you change the `name:` field, GitHub creates a new workflow and the old one appears as inactive with its full history still accessible.

**Scenario 2 -- Migrating from another CI system (Jenkins, CircleCI, Travis):**

Run history from external CI systems cannot be imported into GitHub Actions. History from the old system remains in that system.

**What to preserve before migration:**

1. **Build artifacts:** Download important artifacts from the old system and upload to GitHub Releases or external storage.
2. **Test reports:** Archive test coverage trends, performance benchmarks, etc.
3. **Deployment history:** Record which versions were deployed to which environments.

**Scenario 3 -- Forking or templating CI Excellence:**

When you create a new repository from the CI Excellence template, you start with zero workflow history. The template's history stays in the template repository.

When you fork CI Excellence, you get the full commit history but zero workflow run history (runs are per-repository, not inherited via fork).

**Practical recommendation:** Workflow run history in GitHub Actions is primarily useful for debugging recent failures. Historical trends (deployment frequency, lead time, success rate) should be tracked in an external system (Datadog, Grafana, etc.) rather than relying on GitHub Actions history.

---

## How do I migrate from GitHub Packages to Docker Hub (or vice versa)?

**(Combined)**

The Release Pipeline's `publish-docker` job in `release.yml` already logs into both Docker Hub **and** GitHub Container Registry (ghcr.io):

```yaml
# From release.yml
- name: Login to Docker Hub
  uses: docker/login-action@v3
  with:
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}

- name: Login to GitHub Container Registry
  uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

The actual push logic is in `scripts/ci/release/ci-80-publish-docker.sh` **(STUB)**. To migrate, you need to modify this script.

**Migrate from GitHub Packages (ghcr.io) to Docker Hub:**

Edit `scripts/ci/release/ci-80-publish-docker.sh` to push to Docker Hub:

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

IMAGE_NAME="your-dockerhub-org/your-app"
VERSION="${CI_VERSION:?CI_VERSION is required}"

echo:Release "Building Docker image: $IMAGE_NAME:$VERSION"

docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag "$IMAGE_NAME:$VERSION" \
  --tag "$IMAGE_NAME:latest" \
  --push \
  .

echo:Release "Published to Docker Hub: $IMAGE_NAME:$VERSION"
```

**Migrate existing images:**

To copy existing images from ghcr.io to Docker Hub (or vice versa), use `crane` or `skopeo`:

```bash
# Install crane
go install github.com/google/go-containerregistry/cmd/crane@latest

# Copy image from ghcr.io to Docker Hub
crane copy ghcr.io/your-org/your-app:v1.2.3 docker.io/your-org/your-app:v1.2.3

# Copy all tags
for tag in $(crane ls ghcr.io/your-org/your-app); do
  crane copy "ghcr.io/your-org/your-app:$tag" "docker.io/your-org/your-app:$tag"
done
```

**Publish to both registries simultaneously:**

Modify `ci-80-publish-docker.sh` to push to multiple registries:

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag "docker.io/your-org/your-app:$VERSION" \
  --tag "ghcr.io/your-org/your-app:$VERSION" \
  --push \
  .
```

**Update pull instructions for consumers:**

After migration, update your README or documentation to reference the new registry. If you maintain both, document both pull commands.

**Secrets required:**

- Docker Hub: `DOCKER_USERNAME` and `DOCKER_PASSWORD` (already referenced in `release.yml`)
- ghcr.io: Uses `GITHUB_TOKEN` automatically (already configured in `release.yml`)

---

## How do I migrate secrets from one GitHub organization to another?

**(GitHub Platform + Process)**

GitHub does not provide an API to read secret values (only names). Migrating secrets requires re-creating them in the target organization from your source of truth.

**Step 1 -- List secrets in the source organization/repository:**

```bash
# Repository-level secrets (names only)
gh secret list --repo source-org/repo-name

# Organization-level secrets (names only, requires org admin)
gh api /orgs/source-org/actions/secrets --jq '.secrets[].name'

# Environment-level secrets
gh api repos/source-org/repo-name/environments/production/secrets \
  --jq '.secrets[].name'
```

**Step 2 -- Retrieve actual values from your secret management system:**

GitHub will never return secret values via API. Retrieve them from your original source:
- SOPS-encrypted files (CI Excellence uses SOPS+age for local secret management)
- Password manager (1Password, Vault, etc.)
- The person who originally set them

If you use CI Excellence's SOPS-based secret management, your secrets are stored encrypted in `.env.secrets.json`:

```bash
# Decrypt to view current secret values
sops -d .env.secrets.json
```

**Step 3 -- Set secrets in the target organization/repository:**

```bash
# Set repository-level secrets
gh secret set NPM_TOKEN --repo target-org/repo-name --body "npm_token_value"
gh secret set DOCKER_USERNAME --repo target-org/repo-name --body "docker_user"
gh secret set DOCKER_PASSWORD --repo target-org/repo-name --body "docker_pass"
gh secret set APPRISE_URLS --repo target-org/repo-name --body "slack://T00/B00/XXX"

# Set organization-level secrets (available to all repos or selected repos)
gh secret set NPM_TOKEN --org target-org --visibility all --body "npm_token_value"

# Set environment-level secrets
gh secret set PROD_API_KEY --repo target-org/repo-name --env production --body "key_value"
```

**Step 4 -- Set GitHub Variables (these are readable, so migration is simpler):**

```bash
# Export variables from source
gh variable list --repo source-org/repo-name --json name,value \
  --jq '.[] | "gh variable set \(.name) --repo target-org/repo-name --body \"\(.value)\""' \
  | bash
```

**Step 5 -- Verify the migration:**

```bash
# List secrets in target (verify names are present)
gh secret list --repo target-org/repo-name

# List variables in target (verify names and values)
gh variable list --repo target-org/repo-name

# Run a dry-run release to verify secrets work
gh workflow run release.yml --repo target-org/repo-name \
  -f release-scope=patch -f dry-run=true
```

**Important security considerations:**

- Rotate secrets during migration. Use the migration as an opportunity to generate new tokens rather than copying old ones.
- Audit access. Verify that the new organization's team membership matches intended access for the secrets.
- If using SOPS+age, ensure the age key is securely transferred to the new team and the `.sops.yaml` configuration file is updated with the correct key fingerprints.
- Delete secrets from the source organization after confirming the target is working, to avoid stale credentials.

---

## Documentation Gaps

The following areas related to migration and upgrades are not directly addressed by CI Excellence and would benefit from improvement:

1. **No automated upgrade mechanism.** Upgrades are performed via manual git merge. There is no `ci-excellence upgrade` command, version check script, or update notification. Users must manually track upstream releases.

2. **No version pinning or compatibility matrix.** CI Excellence does not version its workflows or scripts independently. There is no way to pin to a specific version of the framework while accepting only patch-level updates.

3. **No migration for GitHub Variables.** The migration guide (`docs/MIGRATION.md`) covers script paths and config files but does not mention whether `ENABLE_*` variables need to change between versions. A variable compatibility table per version would be valuable.

4. **No artifact archival tooling.** There is no script to bulk-download artifacts before they expire or to upload them to long-term storage. The maintenance workflow handles cleanup (deletion) but not archival.

5. **No rollback testing.** The migration guide documents rollback procedures (restore from backup, revert merge, cherry-pick) but there is no way to validate that a rollback will work before you need it.

6. **SOPS key migration is undocumented.** The migration guide does not cover how to transfer SOPS age keys when moving to a new organization or team. If the age private key is lost, encrypted secrets in `.env.secrets.json` become unrecoverable.

7. **No cross-CI migration guide.** There is no documentation for migrating from Jenkins, CircleCI, GitLab CI, or Travis CI to CI Excellence. The `docs/MIGRATION.md` only covers v1-to-v2 within CI Excellence itself.

8. **Docker image migration is not covered.** There is no script or documentation for copying existing images between registries (ghcr.io to Docker Hub or vice versa) as part of a migration. The `publish-docker` job in `release.yml` is a stub.

9. **Environment-scoped secret migration is undocumented.** The migration guide does not mention GitHub Environments or how to migrate secrets that are scoped to specific environments (e.g., `production`, `staging`).
