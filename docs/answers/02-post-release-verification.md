# Post-Release and Verification

Answers to common questions about deployment verification, rollback, recovery, documentation publishing, and notifications in the CI Excellence post-release pipeline.

All post-release operations are managed by `.github/workflows/post-release.yml`, which triggers automatically on `release` events (published) or manually via `workflow_dispatch`.

> **Extension Model:** CI Excellence uses a hooks system for customization. Rather than editing scripts in `scripts/ci/` directly, create hook scripts in `ci-cd/{step_name}/` directories. Each CI step runs `begin` hooks before its main logic and `end` hooks after. For example, to add custom deployment verification, create `ci-cd/ci-35-verify-github-release/begin-check-assets.sh`. Hook scripts are auto-discovered (matching patterns `{hook}-*.sh` or `{hook}_*.sh`) and executed in alphabetical order. Hook scripts can communicate values back via `contract:env:NAME=VALUE` on stdout. See the [Hooks System](../HOOKS.md) for full details.

---

## How do I verify that a released version is available on NPM, GitHub Releases, and Docker?

The post-release workflow runs a `verify-deployment` job automatically whenever a GitHub release is published. You can also trigger it manually.

**Automatic (on release publish):** No action needed. The workflow fires on the `release: [published]` event and runs verification for every enabled registry.

**Manual trigger:**

```bash
gh workflow run post-release.yml -f version=1.2.3 -f action=verify-deployment
```

**What runs:**

1. `scripts/ci/release/ci-05-select-version.sh` (REAL) -- resolves the version from the release tag or manual input.
2. `scripts/ci/release/ci-70-verify-npm-deployment.sh` (STUB) -- runs only when `ENABLE_NPM_PUBLISH=true`.
3. `scripts/ci/release/ci-35-verify-github-release.sh` (STUB) -- runs only when `ENABLE_GITHUB_RELEASE=true`.
4. `scripts/ci/release/ci-85-verify-docker-deployment.sh` (STUB) -- runs only when `ENABLE_DOCKER_PUBLISH=true`.
5. `scripts/ci/test/ci-40-smoke-tests.sh` (STUB) -- runs unconditionally.
6. `scripts/ci/reports/ci-80-summary-post-release-verify.sh` -- generates the GitHub Actions step summary.

**Required customization:** The verification scripts (steps 2-5) are stubs. Each contains commented-out example code showing the expected pattern. Rather than editing the stubs directly, implement your verification logic via hook scripts in the appropriate `ci-cd/{step_name}/` directory. For example, to verify NPM deployment, create `ci-cd/ci-70-verify-npm-deployment/begin-check-npm.sh` with your `npm view` logic. The stub's commented examples serve as implementation reference.

**Required repository variables:** Set `ENABLE_NPM_PUBLISH`, `ENABLE_GITHUB_RELEASE`, and/or `ENABLE_DOCKER_PUBLISH` to `true` in your repository variables (Settings > Secrets and variables > Actions > Variables) for the corresponding verification steps to execute.

---

## How do I tag an existing version as stable?

Stability tagging follows the convention defined in `docs/STATES.md`: a version gets a Git tag in the format `v{SemVer}-stable`.

**Via post-release workflow:**

```bash
gh workflow run post-release.yml -f version=1.2.3 -f action=tag-stable
```

**Via ops workflow (alternative):**

```bash
gh workflow run ops.yml -f action=mark-stable -f version=1.2.3
```

**What runs:** `scripts/ci/release/ci-07-apply-stability-tag.sh` (REAL, fully implemented). This script:

1. Strips the `v` prefix from the input to normalize it.
2. Configures the GitHub Actions bot identity for the commit.
3. Resolves the tag `v1.2.3` to its commit SHA via `git rev-list`.
4. Creates (or force-updates) the tag `v1.2.3-stable` pointing at that commit.
5. Force-pushes the tag to origin.
6. Writes a summary to `GITHUB_STEP_SUMMARY`.

**Prerequisite:** The repository variable `ENABLE_STABILITY_TAGGING` must be set to `true`. If it is not, the job's `if` condition will prevent it from running.

**No stub customization required.** This script is fully implemented.

---

## How do I tag an existing version as unstable/next?

Same mechanism as stable tagging, but creates a `v{SemVer}-unstable` tag.

**Via post-release workflow:**

```bash
gh workflow run post-release.yml -f version=1.2.3 -f action=tag-unstable
```

**What runs:** The same `scripts/ci/release/ci-07-apply-stability-tag.sh` script, but with `CI_STABILITY_TAG=unstable`. This creates the tag `v1.2.3-unstable`.

**Prerequisite:** `ENABLE_STABILITY_TAGGING=true` must be set.

**No stub customization required.** This script is fully implemented.

**Note:** You can move a version between stable and unstable at any time. The tags use `git tag -f` (force), so re-tagging overwrites the previous stability tag for that version. A version can have both a `-stable` and `-unstable` tag simultaneously if you tag it as stable and then later tag it as unstable without removing the old tag. To remove a stale stability tag, use `git push origin :refs/tags/v1.2.3-stable` manually.

---

## How do I run the post-release verification step separately from tagging?

Use the `verify-deployment` action:

```bash
gh workflow run post-release.yml -f version=1.2.3 -f action=verify-deployment
```

This runs only the `verify-deployment` job. The `tag-stable`, `tag-unstable`, and `rollback` jobs will be skipped because their `if` conditions check for their respective action values.

The `notify` job always runs (via `if: always()`) and will report the verification result.

---

## How do I verify a release deployed to multiple registries (NPM + Docker)?

The `verify-deployment` job already checks all enabled registries in a single run. Each registry verification step is gated by its own `ENABLE_*` flag:

- NPM: runs when `ENABLE_NPM_PUBLISH=true`
- GitHub Releases: runs when `ENABLE_GITHUB_RELEASE=true`
- Docker: runs when `ENABLE_DOCKER_PUBLISH=true`

To verify NPM and Docker together, ensure both `ENABLE_NPM_PUBLISH` and `ENABLE_DOCKER_PUBLISH` are set to `true`, then trigger:

```bash
gh workflow run post-release.yml -f version=1.2.3 -f action=verify-deployment
```

All verification steps run sequentially within the same job, so a failure in one step does not prevent the summary report from running (the report step uses `if: always()`).

**Required customization:** Both `ci-70-verify-npm-deployment.sh` and `ci-85-verify-docker-deployment.sh` are stubs. Implement your verification logic via hook scripts in `ci-cd/ci-70-verify-npm-deployment/` and `ci-cd/ci-85-verify-docker-deployment/` respectively, rather than editing the stubs directly.

---

## How do I validate that release artifacts match the source code? How to compare SHA of release artifacts?

There is no built-in script for artifact SHA validation. This requires customization of the verification stubs.

**Recommended approach for NPM:**

Create a hook script in `ci-cd/ci-70-verify-npm-deployment/` (e.g., `begin-verify-sha.sh`) with:

```bash
# Download the published tarball and compare its shasum
PACKAGE_NAME=$(jq -r '.name' package.json)
npm pack "$PACKAGE_NAME@$VERSION" --pack-destination /tmp
PUBLISHED_SHA=$(shasum -a 256 /tmp/*.tgz | awk '{print $1}')

# Build locally from the tagged source and compare
git checkout "v$VERSION"
npm pack --pack-destination /tmp/local
LOCAL_SHA=$(shasum -a 256 /tmp/local/*.tgz | awk '{print $1}')

if [ "$PUBLISHED_SHA" != "$LOCAL_SHA" ]; then
    echo "SHA mismatch: published=$PUBLISHED_SHA local=$LOCAL_SHA"
    exit 1
fi
```

**Recommended approach for Docker:**

Create a hook script in `ci-cd/ci-85-verify-docker-deployment/` (e.g., `begin-verify-digest.sh`) with:

```bash
# Compare the image digest from the registry with the expected digest
IMAGE_NAME="myorg/myapp"
DIGEST=$(docker manifest inspect "$IMAGE_NAME:$VERSION" | jq -r '.config.digest')
echo "Image digest: $DIGEST"
# Compare with a stored digest from the build step (passed via artifact or output)
```

**Recommended approach for GitHub Releases:**

Create a hook script in `ci-cd/ci-35-verify-github-release/` (e.g., `begin-verify-checksums.sh`) with:

```bash
# Download release assets and verify checksums
gh release download "v$VERSION" --dir /tmp/release-assets
# Compare against a checksums file generated during the build
sha256sum -c /tmp/release-assets/SHA256SUMS
```

**Limitation:** The framework does not currently generate or store checksums during the build/publish phase. To make artifact validation work end-to-end, you would also need to modify your release pipeline to generate and upload a `SHA256SUMS` file as a release asset.

> **e-bash utilities for scripting:** When writing verification hook scripts, the `_commons.sh` module provides helpful utilities: `time:now` and `time:diff "$start"` for microsecond timing of verification steps, `env:variable:or:secret:file value "API_KEY" ".secrets/api_key"` for cascading secret resolution (check env var, then fallback to file), and `val:l0 "$value" "default"` for value coalescing with defaults. These are available in any script that sources `_ci-common.sh`.

---

## How do I rollback a bad release version across NPM, GitHub Releases, and Docker?

Use the `rollback` action in the post-release workflow:

```bash
gh workflow run post-release.yml -f version=1.2.3 -f action=rollback
```

**Prerequisites:**
- `ENABLE_ROLLBACK=true` must be set as a repository variable.
- `NPM_TOKEN` must be set as a secret (for NPM rollback).
- `GITHUB_TOKEN` is provided automatically (for GitHub release rollback).
- `ENABLE_NPM_PUBLISH`, `ENABLE_GITHUB_RELEASE`, and `ENABLE_DOCKER_PUBLISH` control which rollback steps run.

**What runs:**

1. `scripts/ci/release/ci-77-confirm-rollback.sh` (REAL) -- prints a warning describing the planned rollback actions. Runs unconditionally.
2. `scripts/ci/release/ci-75-rollback-npm.sh` (STUB with validation) -- runs when `ENABLE_NPM_PUBLISH=true`. Validates that `NODE_AUTH_TOKEN` is set (real check), but the actual `npm deprecate`/`npm unpublish` commands are commented out.
3. `scripts/ci/release/ci-40-rollback-github.sh` (STUB) -- runs when `ENABLE_GITHUB_RELEASE=true`. Contains commented-out examples for `gh release edit --draft`, `gh release delete`, and adding a warning note to the release.
4. `scripts/ci/release/ci-90-rollback-docker.sh` (STUB with advisory) -- runs when `ENABLE_DOCKER_PUBLISH=true`. Notes that Docker tags cannot be deleted from most registries; suggests tagging as `deprecated-{version}` instead.
5. `scripts/ci/reports/ci-85-summary-rollback.sh` -- generates the rollback summary.

**Required customization:** Steps 2-4 are stubs. Implement your rollback logic via hook scripts in the appropriate `ci-cd/{step_name}/` directories (e.g., `ci-cd/ci-75-rollback-npm/begin-deprecate.sh`). The stubs contain commented examples to use as reference.

> **e-bash `_dryrun.sh` rollback mode:** When implementing rollback hook scripts, consider using the e-bash `_dryrun.sh` module's three-mode execution system. After calling `dryrun git docker npm`, you get `rollback:*` and `undo:*` wrapper functions that execute only when `UNDO_RUN=true`. This lets you write scripts that handle both the forward action and its rollback in the same file: `dry:npm publish` for the publish path and `rollback:npm unpublish` for the rollback path. The `DRY_RUN=true` mode also lets you preview rollback actions before executing them.

Key decisions to make:

- **NPM:** Choose between `npm deprecate` (adds a warning but keeps the package installable) and `npm unpublish` (removes entirely, only available within 72 hours of publishing and requires special permissions).
- **GitHub:** Choose between marking as draft, deleting entirely, or adding a warning note.
- **Docker:** Docker Hub and most registries do not support tag deletion via API. The recommended pattern is to re-tag as `deprecated-{version}` and update documentation.

After rollback completes, consider also tagging the version as unstable:

```bash
gh workflow run post-release.yml -f version=1.2.3 -f action=tag-unstable
```

---

## How do I rollback only NPM/Docker/GitHub while keeping others published?

The rollback steps are independently gated by `ENABLE_*` flags:

- NPM rollback runs only when `ENABLE_NPM_PUBLISH=true`
- GitHub rollback runs only when `ENABLE_GITHUB_RELEASE=true`
- Docker rollback runs only when `ENABLE_DOCKER_PUBLISH=true`

**To rollback only NPM (keeping GitHub and Docker):**

1. Temporarily set `ENABLE_GITHUB_RELEASE=false` and `ENABLE_DOCKER_PUBLISH=false` in repository variables.
2. Run: `gh workflow run post-release.yml -f version=1.2.3 -f action=rollback`
3. Restore the original variable values after the rollback completes.

**Alternative (recommended for one-off cases):** Instead of toggling repository variables, run the rollback commands directly from the CLI without using the workflow:

```bash
# NPM only
npm deprecate "@myorg/mypackage@1.2.3" "Rolled back due to critical bug"

# GitHub only
gh release edit v1.2.3 --draft --repo myorg/myrepo

# Docker only (re-tag as deprecated)
docker pull myorg/myapp:1.2.3
docker tag myorg/myapp:1.2.3 myorg/myapp:deprecated-1.2.3
docker push myorg/myapp:deprecated-1.2.3
```

**Limitation:** The workflow does not support per-registry rollback selection as an input parameter. You must either toggle the `ENABLE_*` flags or run commands manually.

---

## How do I restore a deleted release or tag?

**Restoring a deleted GitHub release:**

If the Git tag still exists (which is the default -- the rollback stub marks releases as draft rather than deleting them):

```bash
# Re-create the release from the existing tag
gh release create v1.2.3 --title "v1.2.3" --notes "Restored release"
```

If the tag was also deleted:

```bash
# Find the commit SHA from reflog or CI logs
git reflog | grep v1.2.3

# Re-create the tag
git tag v1.2.3 <commit-sha>
git push origin v1.2.3

# Re-create the release
gh release create v1.2.3 --title "v1.2.3" --notes "Restored release"
```

**Restoring a deleted Git tag:**

```bash
# If the tag was deleted recently, check the reflog
git reflog | grep v1.2.3

# Or find it via the GitHub API
gh api repos/{owner}/{repo}/git/refs/tags/v1.2.3

# Re-create and push
git tag v1.2.3 <commit-sha>
git push origin v1.2.3
```

**Restoring a deprecated NPM package:**

```bash
# Remove the deprecation message
npm deprecate "@myorg/mypackage@1.2.3" ""
```

**Limitation:** If a package was fully unpublished from NPM (via `npm unpublish`), it cannot be restored. NPM also blocks re-publishing the exact same version+name within 24 hours of unpublishing. There is no framework script for release restoration; these are manual operations.

---

## How do I unpublish a specific version from a registry?

This is a manual operation. The framework stubs provide guidance but no automated implementation.

**NPM:**

```bash
# Deprecate (recommended -- keeps package installable but shows warning)
npm deprecate "@myorg/mypackage@1.2.3" "This version has known issues, use 1.2.4"

# Unpublish (only within 72 hours, requires special permissions)
npm unpublish "@myorg/mypackage@1.2.3"
```

**GitHub Releases:**

```bash
# Delete the release (keeps the Git tag)
gh release delete v1.2.3 --yes

# Delete both the release and the tag
gh release delete v1.2.3 --yes --cleanup-tag
```

**Docker Hub:**

Docker Hub does not support tag deletion via the standard Docker API. Options:

- Use the Docker Hub web UI to delete specific tags.
- Use the Docker Hub API: `curl -X DELETE https://hub.docker.com/v2/repositories/{namespace}/{repo}/tags/{tag}/` (requires authentication).
- Re-tag as deprecated (as shown in `ci-90-rollback-docker.sh`).

**GHCR (GitHub Container Registry):**

```bash
# List package versions
gh api user/packages/container/{package}/versions

# Delete a specific version
gh api --method DELETE user/packages/container/{package}/versions/{version_id}
```

---

## What happens to dependent projects when I rollback a release?

The framework itself does not track or notify downstream dependents. Here is what happens per registry:

**NPM `npm deprecate`:** Dependents can still install the deprecated version. They will see a warning during `npm install`. No builds break, but developers are alerted. This is the safest rollback option.

**NPM `npm unpublish`:** Dependents with exact version pins (`"mypackage": "1.2.3"`) will fail to install. Dependents with ranges (`"^1.2.0"`) will resolve to the next available version. Lockfile-based installs (`package-lock.json`, `yarn.lock`) will fail if the exact version is gone.

**GitHub release deletion:** Dependents using GitHub release asset download URLs will get 404 errors. Dependents using Git tags are unaffected (tags survive release deletion by default).

**Docker tag re-tagging:** Dependents pulling `myapp:1.2.3` are unaffected (the tag still exists). Only if the tag is deleted will pulls fail.

**Recommendations:**
1. Prefer `npm deprecate` over `npm unpublish`.
2. Prefer marking GitHub releases as draft over deleting them.
3. After rollback, send a notification to dependent teams (the `notify` job in the post-release workflow runs automatically).
4. Tag the version as unstable so it is clearly marked in Git history: `gh workflow run post-release.yml -f version=1.2.3 -f action=tag-unstable`.

---

## How do I publish documentation for a released version?

Documentation build and publish are handled in the **release pipeline** (not the post-release pipeline), gated by `ENABLE_DOCUMENTATION=true`.

**Scripts:**
- `scripts/ci/release/ci-50-build-docs.sh` (STUB) -- builds documentation.
- `scripts/ci/release/ci-55-publish-docs.sh` (STUB) -- publishes to a hosting platform.

Both are stubs with commented-out examples for Sphinx, JSDoc, TypeDoc, Docusaurus, MkDocs, Rustdoc (build) and GitHub Pages, Netlify, Vercel, Read the Docs (publish).

**To enable:**

1. Set the repository variable `ENABLE_DOCUMENTATION=true`.
2. Implement your documentation build via a hook script in `ci-cd/ci-50-build-docs/` (e.g., `begin-build-mkdocs.sh`).
3. Implement your documentation publish via a hook script in `ci-cd/ci-55-publish-docs/` (e.g., `begin-deploy-pages.sh`).

**To re-publish docs for an already-released version:** There is no dedicated re-publish workflow. Options:

- Re-run the release workflow's documentation job from the GitHub Actions UI (if the release workflow is still accessible).
- Run the build and publish scripts manually:
  ```bash
  git checkout v1.2.3
  CI_VERSION=1.2.3 ./scripts/ci/release/ci-50-build-docs.sh
  ./scripts/ci/release/ci-55-publish-docs.sh
  ```

---

## How do I re-trigger notifications for a completed pipeline?

The `notify` job in `post-release.yml` runs automatically after every post-release action (it uses `if: always()`). To re-trigger it, re-run the entire workflow:

**From the GitHub UI:**
1. Go to Actions > Post-Release Pipeline.
2. Find the completed run.
3. Click "Re-run all jobs" or "Re-run failed jobs".

**From the CLI:**

```bash
# Re-run a specific workflow run
gh run rerun <run-id>

# Or trigger a fresh post-release run (which will send a new notification)
gh workflow run post-release.yml -f version=1.2.3 -f action=verify-deployment
```

**Sending a standalone notification (without running a full pipeline):**

There is no dedicated "notify-only" workflow. However, you can call the notification script directly if you have Apprise installed locally:

```bash
pip install apprise
export APPRISE_URLS="slack://T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX"
apprise --title "Release v1.2.3" --body "Manual notification: release verified" $APPRISE_URLS
```

**No stub customization required.** All notification scripts are fully implemented.

---

## How do I send release notifications to multiple channels (Slack + Teams + Email)?

Set the `APPRISE_URLS` secret to a space-separated list of notification URLs:

```
slack://T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX msteams://outlook.office.com/webhook/xxxxx mailto://user:pass@smtp.gmail.com?to=team@company.com
```

The notification script (`scripts/ci/notification/ci-30-send-notification.sh`) splits the space-separated URLs and passes each as an argument to the `apprise` CLI. All configured services receive the same notification in a single invocation.

**Supported services include:** Slack (`slack://`), Microsoft Teams (`msteams://`), Discord (`discord://`), Telegram (`tgram://`), Email (`mailto://`), Google Chat (`gchat://`), Pushover (`pover://`), Matrix (`matrix://`), and 90+ more via the Apprise library.

**Per-channel customization examples:**

```bash
# Slack with custom bot name and channel
slack://T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX/#ci-releases?user=CI+Bot

# Discord with custom username
discord://webhook_id/webhook_token?username=CI+Bot

# Email to multiple recipients
mailto://user:pass@smtp.gmail.com?to=dev@company.com,ops@company.com
```

See `docs/NOTIFICATIONS.md` for the full setup guide and URL format reference.

**No stub customization required.** The notification pipeline is fully implemented.

---

## How do I customize notification messages for different release types?

Notification messages are determined by `scripts/ci/notification/ci-50-post-release-status.sh` (REAL, fully implemented). The script checks the result of each post-release job and sets an appropriate message:

| Condition | Status | Message |
|-----------|--------|---------|
| Rollback succeeded | `warning` | "Rollback Completed" |
| Stable tag succeeded | `success` | "Version Tagged as Stable" |
| Verification succeeded | `success` | "Deployment Verified" |
| Rollback failed | `failure` | "Rollback Failed" |
| Default | `info` | "Post-Release Actions Completed" |

**To customize messages:**

Edit `scripts/ci/notification/ci-50-post-release-status.sh` and modify the `ci:output` calls. For example, to include the version number:

```bash
if [ "$ROLLBACK_RESULT" == "success" ]; then
  ci:output notify "status" "warning"
  ci:output notify "message" "Rollback of v${CI_VERSION:-unknown} Completed"
fi
```

**To add entirely new notification types:** The notification send script (`ci-30-send-notification.sh`) accepts any `NOTIFY_TITLE`, `NOTIFY_MESSAGE`, and `NOTIFY_STATUS` (info/success/warning/failure) environment variables. You can add custom steps in the workflow that call this script directly with any message content.

**Notification format:** Messages are sent as HTML (via `--input-format=html`). The script automatically appends repository name, workflow name, run URL, and triggering actor to every notification. These additions are built into `ci-30-send-notification.sh`.

---

## How to produce a changes log between two releases (or current state and last known stable release)?

The framework includes a changelog generation stub and a release notes generation stub, both in the **release pipeline**:

- `scripts/ci/release/ci-20-generate-changelog.sh` (STUB) -- generates or updates `CHANGELOG.md`.
- `scripts/ci/release/ci-25-generate-release-notes.sh` (STUB) -- generates release notes for a specific version.

**Quick manual approach using Git:**

```bash
# Changes between two tags
git log v1.2.0..v1.3.0 --pretty=format:"- %s (%h)" --reverse

# Changes between last stable tag and current HEAD
LAST_STABLE=$(git tag -l '*-stable' --sort=-v:refname | head -1)
git log "$LAST_STABLE"..HEAD --pretty=format:"- %s (%h)" --reverse

# Using conventional commits format
git log v1.2.0..v1.3.0 --pretty=format:"%s" | grep -E "^(feat|fix|docs|chore|refactor|test|perf|ci)(\(.*\))?:"
```

**Using tooling (customize the stubs):**

The stubs contain commented-out examples for three popular tools:

1. **conventional-changelog:** `conventional-changelog -p angular -i CHANGELOG.md -s`
2. **git-cliff:** `git-cliff --tag "$VERSION" -o CHANGELOG.md`
3. **standard-version:** `standard-version --release-as "$VERSION"`

To enable one of these, create a hook script in `ci-cd/ci-20-generate-changelog/` (e.g., `begin-git-cliff.sh`) that runs your chosen tool, and ensure the tool is installed in `scripts/ci/setup/ci-10-install-tools.sh`. The stub's commented examples serve as implementation reference.

**Using GitHub's built-in release notes:**

```bash
# Generate release notes via GitHub API (compares against previous tag)
gh api repos/{owner}/{repo}/releases/generate-notes \
  -f tag_name=v1.3.0 \
  -f previous_tag_name=v1.2.0 \
  --jq '.body'
```

**Limitation:** The framework does not automatically track which version is the "last known stable." Stable versions are identified by the `v{SemVer}-stable` Git tag convention (see `docs/STATES.md`). You can find the latest stable tag with:

```bash
git tag -l '*-stable' --sort=-v:refname | head -1
```

---

## Documentation Gaps

The following areas are not yet covered by the framework and would require additional implementation:

1. **Artifact SHA checksums:** No script generates or stores checksums during the build/publish phase. Artifact validation (comparing published artifacts against source) requires both a checksum-generation step in the release pipeline and a checksum-verification step in the post-release pipeline.

2. **Per-registry rollback selection:** The rollback workflow rolls back all enabled registries. There is no input parameter to select specific registries for rollback. Users must toggle `ENABLE_*` flags or run commands manually for selective rollback.

3. **Dependent project notification:** The framework does not discover or notify downstream dependents when a version is rolled back or deprecated. Consider integrating with GitHub's dependency graph API or maintaining an explicit list of dependent repositories.

4. **Release restoration workflow:** There is no automated workflow for restoring a deleted release or tag. Restoration is a manual process using Git and `gh` CLI commands.

5. **Notification re-trigger without re-running jobs:** There is no "notify-only" action in the post-release workflow. Re-triggering a notification requires re-running the entire workflow or calling Apprise directly outside the pipeline.

6. **Changelog diffing between arbitrary versions:** The changelog stubs exist but are not wired to a post-release action. Generating a changelog between two arbitrary versions (especially "current state vs. last stable") requires either manual Git commands or customizing the stubs and invoking them outside the release pipeline.

7. **Documentation re-publishing:** There is no post-release action to re-publish documentation for a previously released version. The documentation build/publish scripts live in the release pipeline and must be invoked manually for re-publication.

8. **Smoke test implementation:** `scripts/ci/test/ci-40-smoke-tests.sh` is a stub. It runs unconditionally during verification but performs no actual checks until customized.
