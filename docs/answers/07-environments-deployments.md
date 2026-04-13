# Environments and Deployments

This document answers frequently asked questions about environment management, deployment strategies, and pre-release channels in the CI Excellence framework.

> **Important context:** Deployment in CI Excellence is intentionally designed as a customization point. The framework provides the orchestration scaffolding (workflows, input validation, stability tagging), but the actual deployment logic in `ci-30-deploy.sh` is a **stub** that you must fill in with your project-specific commands. Stability tagging (`ci-07-apply-stability-tag.sh`) and input validation (`ci-10-validate-inputs.sh`) are fully implemented.

> **Extension Model:** CI Excellence uses a hooks system for customization. Rather than editing scripts in `scripts/ci/` directly, create hook scripts in `ci-cd/{step_name}/` directories. Each CI step runs `begin` hooks before its main logic and `end` hooks after. For example, to add deployment logic, create `ci-cd/ci-30-deploy/begin-kubectl-apply.sh`. Hook scripts are auto-discovered (matching patterns `{hook}-*.sh` or `{hook}_*.sh`) and executed in alphabetical order. Hook scripts can communicate values back via `contract:env:NAME=VALUE` on stdout. See the [Hooks System](../HOOKS.md) for full details.

---

## How can I trigger deploys to different environments (staging, production)?

Deployments are triggered through the **Ops Pipeline** (`Actions > Ops Pipeline > Run workflow`) using `workflow_dispatch`:

1. Navigate to **Actions > Ops Pipeline > Run workflow** in your GitHub repository.
2. Select the **action**: `deploy-staging` or `deploy-production`.
3. Enter the **version** (e.g., `1.2.3`).
4. For production deployments, set **confirm** to `yes` (production requires explicit confirmation).

Under the hood, both actions invoke the same script with different `OPS_ENVIRONMENT` values:

```yaml
# From .github/workflows/ops.yml
- name: Deploy Staging
  if: github.event.inputs.action == 'deploy-staging'
  env:
    OPS_ENVIRONMENT: staging
  run: ./scripts/ci/ops/ci-30-deploy.sh

- name: Deploy Production
  if: github.event.inputs.action == 'deploy-production'
  env:
    OPS_ENVIRONMENT: production
  run: ./scripts/ci/ops/ci-30-deploy.sh
```

**Status:** The deploy script (`scripts/ci/ops/ci-30-deploy.sh`) is a **STUB**. It validates inputs and confirms production deployments, but prints:

```
Stub: deploy-${ENVIRONMENT} is awaiting project-specific implementation.
```

Rather than editing `ci-30-deploy.sh` directly, implement your deployment logic via hook scripts in `ci-cd/ci-30-deploy/` (e.g., `begin-kubectl-apply.sh`, `begin-aws-ecs-update.sh`). The framework gives you `$ENVIRONMENT` and `$VERSION` as inputs to branch on. The stub contains commented examples showing the expected patterns for various platforms -- use these as reference when writing your hook scripts.

You can also trigger deploys via the GitHub CLI without visiting the web UI:

```bash
# Deploy to staging
gh workflow run ops.yml -f action=deploy-staging -f version=1.2.3

# Deploy to production (requires confirmation)
gh workflow run ops.yml -f action=deploy-production -f version=1.2.3 -f confirm=yes
```

---

## How can I create new environments for deploy?

The framework ships with two environment directories under `environments/`:

```
environments/
  staging/
    .gitkeep              # "folder for environment specific configurations"
  production/
    .gitkeep              # "folder for environment specific configurations"
    regions/
      .gitkeep            # "folder for regions of the specific environment"
```

To add a new environment (e.g., `qa` or `sandbox`):

**Step 1: Create the directory structure.**

```bash
mkdir -p environments/qa
echo "# folder for environment specific configurations" > environments/qa/.gitkeep
```

**Step 2: Add a new action to the Ops workflow.** Edit `.github/workflows/ops.yml`:

```yaml
inputs:
  action:
    type: choice
    options:
      - promote-release
      - deploy-staging
      - deploy-production
      - deploy-qa            # Add new option
      - mark-stable
      - mark-deprecated
```

Then add a corresponding step:

```yaml
- name: Deploy QA
  if: github.event.inputs.action == 'deploy-qa'
  env:
    OPS_ENVIRONMENT: qa
  run: ./scripts/ci/ops/ci-30-deploy.sh
```

**Step 3: Implement environment-specific deployment via hooks.** Create hook scripts in `ci-cd/ci-30-deploy/` that handle the new environment. Since the script already receives `$OPS_ENVIRONMENT`, you can branch on it in your hook:

```bash
case "$ENVIRONMENT" in
  staging)  deploy_to_staging "$VERSION" ;;
  production) deploy_to_production "$VERSION" ;;
  qa)       deploy_to_qa "$VERSION" ;;
esac
```

**Step 4 (optional): Use GitHub Environments.** GitHub has a built-in Environments feature (Settings > Environments) that supports approval gates, secrets scoping, and deployment protection rules. The framework does not currently use this feature, but you can add `environment: qa` to the job definition:

```yaml
deploy-qa:
  runs-on: ubuntu-latest
  environment: qa    # GitHub Environment with protection rules
  steps: ...
```

---

## How do I freeze specific versions to prevent deprecation or deletion?

Use the **stability tagging** system to mark a version as `stable`. Stable-tagged versions should be excluded from your deprecation logic.

**Mark a version as stable via the Ops Pipeline:**

1. Go to **Actions > Ops Pipeline > Run workflow**.
2. Set action to `mark-stable`, version to the version you want to freeze (e.g., `1.2.3`).

This runs `ci-40-mark-stability.sh`, which delegates to the **REAL** script `ci-07-apply-stability-tag.sh`. It creates an annotated git tag `v1.2.3-stable` pointing to the same commit as `v1.2.3`.

**Mark a version as stable via the Post-Release Pipeline:**

1. Go to **Actions > Post-Release Pipeline > Run workflow**.
2. Set action to `tag-stable`, version to the target version.
3. Requires `ENABLE_STABILITY_TAGGING=true` in repository variables.

**Via the CLI:**

```bash
# Through Ops Pipeline
gh workflow run ops.yml -f action=mark-stable -f version=1.2.3

# Through Post-Release Pipeline
gh workflow run post-release.yml -f action=tag-stable -f version=1.2.3
```

**How freezing works in practice:** The stability tag (`v1.2.3-stable`) is a git-level marker. Your deprecation and cleanup scripts should check for this tag and skip those versions. The maintenance script `ci-70-identify-deprecated-versions.sh` is where you would add logic like:

```bash
# Skip versions that have a -stable tag
if git tag --list "v${VERSION}-stable" | grep -q .; then
  echo "Skipping $VERSION (marked stable)"
  continue
fi
```

The deprecation script `ci-80-deprecate-github-releases.sh` is currently a **STUB** with commented-out example logic, so you would integrate the stable-tag check when you implement it.

---

## How do I promote a version from staging to production?

The framework provides a `promote-release` action in the Ops Pipeline, but it is currently a **STUB**. When invoked, it prints:

```
Auto-promotion is not yet implemented.
Please use the Release Pipeline to promote a pre-release:
  gh workflow run release.yml -f release-scope=... -f pre-release-type=...
```

**Practical approach today:**

1. Deploy to staging first and verify:
   ```bash
   gh workflow run ops.yml -f action=deploy-staging -f version=1.2.3
   ```

2. Run verification (post-release pipeline):
   ```bash
   gh workflow run post-release.yml -f action=verify-deployment -f version=1.2.3
   ```

3. Once satisfied, deploy the same version to production:
   ```bash
   gh workflow run ops.yml -f action=deploy-production -f version=1.2.3 -f confirm=yes
   ```

4. After production is confirmed healthy, tag as stable:
   ```bash
   gh workflow run ops.yml -f action=mark-stable -f version=1.2.3
   ```

**To implement automated promotion in `ci-20-promote-release.sh`:**

```bash
# Example: promote from staging to production
echo "Verifying version ${VERSION} is deployed to staging..."
# Add your staging health check here

echo "Promoting ${VERSION} to production..."
OPS_ENVIRONMENT=production OPS_CONFIRM=yes ./scripts/ci/ops/ci-30-deploy.sh

echo "Tagging ${VERSION} as stable..."
CI_STABILITY_TAG=stable CI_VERSION="${VERSION}" ./scripts/ci/release/ci-07-apply-stability-tag.sh
```

---

## How do I deploy different packages to different environments?

In a monorepo scenario where different packages target different environments, you need to customize `ci-30-deploy.sh` to handle package-environment mapping.

**Approach 1: Environment variables per package.**

Define which packages deploy where in your environment config:

```bash
# environments/staging/packages.conf
web-frontend
api-server
shared-utils

# environments/production/packages.conf
web-frontend
api-server
```

Then in `ci-30-deploy.sh`:

```bash
PACKAGES_FILE="environments/${ENVIRONMENT}/packages.conf"
if [ -f "$PACKAGES_FILE" ]; then
  while read -r package; do
    echo "Deploying $package v${VERSION} to ${ENVIRONMENT}..."
    # Your package-specific deploy logic here
  done < "$PACKAGES_FILE"
fi
```

**Approach 2: Multiple Ops workflow runs.** Trigger separate deployments for each package using the version input to encode package information:

```bash
gh workflow run ops.yml -f action=deploy-staging -f version="web-frontend@1.2.3"
```

Then parse this in the deploy script. This approach is simpler but requires convention-based coordination.

**Status:** This is entirely a customization point. The framework provides the environment directory structure (`environments/staging/`, `environments/production/`) and the workflow scaffolding, but package-to-environment mapping is project-specific.

---

## How do I handle environment-specific configuration?

The framework provides several layers for environment-specific configuration:

**Layer 1: Environment directory structure.** Place environment-specific config files under `environments/<env>/`:

```
environments/
  staging/
    config.yaml        # Your staging config
    .env.staging       # Staging environment variables
  production/
    config.yaml        # Your production config
    .env.production    # Production environment variables
    regions/
      us-east-1.yaml   # Region-specific overrides
```

**Layer 2: `.env` file with `.env.local` overrides.** The framework supports `.env` for base configuration and `.env.local` for local/environment-specific overrides. The template is at `config/.env.template`. Key variables include:

```bash
# Feature flags that control which pipeline stages run
ENABLE_NPM_PUBLISH=false
ENABLE_GITHUB_RELEASE=true
ENABLE_DOCKER_PUBLISH=false
```

**Layer 3: GitHub repository variables.** Set environment-specific variables in GitHub (Settings > Secrets and Variables > Actions > Variables). These are what the workflows reference via `${{ vars.ENABLE_* }}`. If you use GitHub Environments, you can scope variables per environment.

**Layer 4: GitHub Environments with scoped secrets.** Although the framework does not currently use the GitHub Environments feature in its workflow definitions, you can add it. GitHub Environments let you scope secrets per environment:

```yaml
jobs:
  deploy-production:
    environment: production  # Uses production-scoped secrets
    steps:
      - run: ./scripts/ci/ops/ci-30-deploy.sh
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}  # Different per environment
```

**Layer 5: Inject at deploy time in `ci-30-deploy.sh`.** Load the right config file based on `$ENVIRONMENT`:

```bash
if [ -f "environments/${ENVIRONMENT}/config.yaml" ]; then
  export APP_CONFIG="environments/${ENVIRONMENT}/config.yaml"
fi
```

---

## How do I rollback a deployment in a specific environment?

The framework has two rollback mechanisms:

**1. Registry-level rollback via the Post-Release Pipeline** (partially implemented):

```bash
gh workflow run post-release.yml -f action=rollback -f version=1.2.3
```

This requires `ENABLE_ROLLBACK=true` and will:
- Deprecate the NPM package version (if `ENABLE_NPM_PUBLISH=true`) -- calls `ci-75-rollback-npm.sh`
- Mark the GitHub release as draft (if `ENABLE_GITHUB_RELEASE=true`) -- calls `ci-40-rollback-github.sh`
- Tag Docker images as deprecated (if `ENABLE_DOCKER_PUBLISH=true`) -- calls `ci-90-rollback-docker.sh`

The confirmation script (`ci-77-confirm-rollback.sh`) prints a warning of planned actions. Note: most of these rollback scripts are **STUBS** that need project-specific implementation.

> **e-bash `_dryrun.sh` for safe rollbacks:** When implementing rollback logic in your deploy hooks, the `_dryrun.sh` module provides a three-mode execution system. After calling `dryrun kubectl docker`, you get `rollback:kubectl rollout undo` wrappers that execute only when `UNDO_RUN=true`, and `dry:kubectl apply` wrappers that show commands without executing when `DRY_RUN=true`. This lets you preview rollback actions before running them and write scripts that handle both deployment and rollback in the same file.

**2. Environment-level rollback by redeploying a previous version:**

The simplest and most reliable approach is to redeploy the last known good version:

```bash
# Redeploy previous version to staging
gh workflow run ops.yml -f action=deploy-staging -f version=1.1.0

# Redeploy previous version to production
gh workflow run ops.yml -f action=deploy-production -f version=1.1.0 -f confirm=yes
```

Then mark the bad version as unstable:

```bash
gh workflow run post-release.yml -f action=tag-unstable -f version=1.2.3
```

This creates an annotated git tag `v1.2.3-unstable` via the **REAL** stability tagging script.

**Finding the previous stable version:** Look for the most recent `-stable` tag:

```bash
git tag --list '*-stable' --sort=-version:refname | head -1
```

---

## How do I implement blue-green deployments?

Blue-green deployments are not built into the framework and require customization of `ci-30-deploy.sh`. Here is a practical approach:

**Step 1:** Define two deployment targets (blue and green) in your environment config:

```
environments/
  production/
    blue/
      config.yaml
    green/
      config.yaml
    active-slot.txt    # Contains "blue" or "green"
```

**Step 2:** Customize `ci-30-deploy.sh` to implement the swap:

```bash
ACTIVE_SLOT=$(cat "environments/${ENVIRONMENT}/active-slot.txt" 2>/dev/null || echo "blue")
INACTIVE_SLOT=$( [ "$ACTIVE_SLOT" = "blue" ] && echo "green" || echo "blue" )

echo "Deploying ${VERSION} to ${INACTIVE_SLOT} slot..."
# Deploy to inactive slot (your infrastructure-specific command)
# e.g., kubectl set image deployment/${INACTIVE_SLOT}-app app=myimage:${VERSION}

echo "Running health checks on ${INACTIVE_SLOT}..."
# Verify the inactive slot is healthy

echo "Switching traffic to ${INACTIVE_SLOT}..."
# Update load balancer / ingress / DNS
# e.g., kubectl patch service my-app -p '{"spec":{"selector":{"slot":"'${INACTIVE_SLOT}'"}}}'

echo "$INACTIVE_SLOT" > "environments/${ENVIRONMENT}/active-slot.txt"
```

**Step 3:** For rollback, swap back to the other slot (which still has the previous version).

This is entirely project-specific. The framework's contribution is providing the workflow trigger mechanism and environment structure.

---

## How do I implement canary deployments with gradual rollout?

Canary deployments require customization. The framework does not include canary logic, but you can build it into the deploy script.

**Approach using the Ops Pipeline:**

Create a phased deployment in `ci-30-deploy.sh`:

```bash
CANARY_PERCENTAGE="${CANARY_PERCENTAGE:-10}"

echo "Phase 1: Deploying ${VERSION} to ${CANARY_PERCENTAGE}% of traffic..."
# Infrastructure-specific: update service mesh weights, Istio VirtualService, etc.

echo "Waiting for metrics to stabilize (5 minutes)..."
sleep 300

echo "Checking error rates..."
# Query your monitoring system (Datadog, Prometheus, CloudWatch)
ERROR_RATE=$(curl -s "https://monitoring.example.com/api/error-rate?service=myapp&version=${VERSION}")

if (( $(echo "$ERROR_RATE > 1.0" | bc -l) )); then
  echo "Error rate too high ($ERROR_RATE%), rolling back canary..."
  # Revert traffic weights
  exit 1
fi

echo "Phase 2: Promoting to 100%..."
# Full rollout
```

**Alternative: Use separate Ops actions.** Add workflow actions like `canary-staging` and `promote-canary` for more manual control over each rollout phase.

The key point: canary logic depends heavily on your infrastructure (Kubernetes + Istio, AWS ALB weighted targets, Cloudflare Workers, etc.). The framework gives you the trigger mechanism; you supply the rollout logic.

---

## How do I run smoke tests after deployment?

The framework includes a smoke test script at `scripts/ci/test/ci-40-smoke-tests.sh`. It is called automatically by the **Post-Release Pipeline** after a release is published:

```yaml
# From .github/workflows/post-release.yml
- name: Run smoke tests
  env:
    CI_VERSION: ${{ steps.version.outputs.version }}
  run: ./scripts/ci/test/ci-40-smoke-tests.sh
```

**Status:** The script is a **STUB** with commented-out examples. Implement your smoke tests via hook scripts in `ci-cd/ci-40-smoke-tests/` (e.g., `begin-health-check.sh`). The stub's commented examples show the expected patterns:

```bash
# Example patterns already in the script (commented out):

# Health check endpoint
curl -f https://api.example.com/health || EXIT_CODE=$?

# Version endpoint
DEPLOYED_VERSION=$(curl -s https://api.example.com/version | jq -r '.version')
if [ "$DEPLOYED_VERSION" != "$VERSION" ]; then
    echo "Version mismatch: expected $VERSION, got $DEPLOYED_VERSION"
    EXIT_CODE=1
fi

# NPM package availability
npm view mypackage@$VERSION version || EXIT_CODE=$?

# Docker image availability
docker pull myorg/myapp:$VERSION || EXIT_CODE=$?
```

**To run smoke tests manually after an Ops deploy**, add a smoke test step to your customized `ci-30-deploy.sh`:

```bash
echo "Deploying ${VERSION} to ${ENVIRONMENT}..."
# Your deploy logic here

echo "Running post-deploy smoke tests..."
CI_VERSION="$VERSION" ./scripts/ci/test/ci-40-smoke-tests.sh
```

Or trigger the post-release verification separately:

```bash
gh workflow run post-release.yml -f action=verify-deployment -f version=1.2.3
```

This runs NPM verification, GitHub release verification, Docker verification, and smoke tests depending on which `ENABLE_*` flags are set.

---

## How do I automatically rollback on failed health checks?

This requires combining smoke tests with deployment rollback logic. The framework does not do this automatically, but you can build it into `ci-30-deploy.sh`:

```bash
# Deploy
echo "Deploying ${VERSION} to ${ENVIRONMENT}..."
# Your deploy command here

# Health check with retry
MAX_RETRIES=5
RETRY_INTERVAL=30
for i in $(seq 1 $MAX_RETRIES); do
  if curl -sf "https://${ENVIRONMENT}.example.com/health"; then
    echo "Health check passed on attempt $i"
    break
  fi
  if [ "$i" -eq "$MAX_RETRIES" ]; then
    echo "Health check failed after $MAX_RETRIES attempts. Rolling back..."

    # Find previous stable version
    PREVIOUS_VERSION=$(git tag --list '*-stable' --sort=-version:refname | head -1 | sed 's/v//' | sed 's/-stable//')

    # Redeploy previous version
    OPS_VERSION="$PREVIOUS_VERSION" OPS_ENVIRONMENT="$ENVIRONMENT" OPS_CONFIRM=yes \
      ./scripts/ci/ops/ci-30-deploy.sh

    # Mark failed version as unstable
    CI_STABILITY_TAG=unstable CI_VERSION="$VERSION" \
      ./scripts/ci/release/ci-07-apply-stability-tag.sh

    exit 1
  fi
  echo "Health check failed (attempt $i/$MAX_RETRIES), retrying in ${RETRY_INTERVAL}s..."
  sleep $RETRY_INTERVAL
done
```

This is entirely custom logic. The framework provides the building blocks (stability tagging, deploy script structure) but not the automated rollback wiring.

---

## How do I deploy to multiple regions/availability zones?

The framework includes a `regions/` subdirectory under `environments/production/` with a `.gitkeep` noting "folder for regions of the specific environment." This is a placeholder for you to define region-specific configurations.

**Approach:**

```
environments/
  production/
    regions/
      us-east-1.yaml
      eu-west-1.yaml
      ap-southeast-1.yaml
```

Customize `ci-30-deploy.sh` to iterate over regions:

```bash
REGIONS_DIR="environments/${ENVIRONMENT}/regions"
if [ -d "$REGIONS_DIR" ]; then
  for region_config in "$REGIONS_DIR"/*.yaml; do
    REGION=$(basename "$region_config" .yaml)
    echo "Deploying ${VERSION} to ${ENVIRONMENT}/${REGION}..."
    # Region-specific deploy command
    # e.g., AWS_DEFAULT_REGION=$REGION aws ecs update-service ...
  done
else
  echo "No region configs found, deploying to default region..."
  # Single-region deploy
fi
```

For safety, consider deploying to one region first, running health checks, then proceeding to the next (rolling regional deployment).

---

## How do I handle database migrations during deployment?

Database migrations are not part of the framework. They are a common customization point in `ci-30-deploy.sh`. Here is a recommended pattern:

```bash
echo "Running database migrations for ${ENVIRONMENT}..."

# Option 1: Run migrations as a pre-deploy step
DATABASE_URL="${DATABASE_URLS[$ENVIRONMENT]}" npx prisma migrate deploy
# or: flyway -url="$DATABASE_URL" migrate
# or: alembic upgrade head
# or: rails db:migrate

echo "Migrations complete. Deploying application..."
# Your deploy logic here
```

**Important considerations:**
- Run migrations **before** deploying new code (if the new code requires schema changes).
- Ensure migrations are backward-compatible (old code can run against new schema) for zero-downtime deployments.
- Consider a separate migration job/step that runs with its own confirmation gate.
- Store migration state in your database, not in CI.

---

## How do I run pre-releases as alpha, beta, or release-candidate (rc)?

This is **fully implemented** in the Release Pipeline. The workflow accepts a `pre-release-type` input with options `alpha`, `beta`, and `rc`, combined with pre-release scopes.

**To create a pre-release:**

1. Go to **Actions > Release Pipeline > Run workflow**.
2. Set `release-scope` to one of: `premajor`, `preminor`, `prepatch`, or `prerelease`.
3. Set `pre-release-type` to `alpha`, `beta`, or `rc`.

**Examples via CLI:**

```bash
# Create a pre-minor alpha: e.g., 1.3.0-alpha
gh workflow run release.yml -f release-scope=preminor -f pre-release-type=alpha

# Increment to next alpha: e.g., 1.3.0-alpha.1
gh workflow run release.yml -f release-scope=prerelease -f pre-release-type=alpha

# Promote alpha to beta: e.g., 1.3.0-beta
gh workflow run release.yml -f release-scope=prerelease -f pre-release-type=beta

# Promote beta to rc: e.g., 1.3.0-rc
gh workflow run release.yml -f release-scope=prerelease -f pre-release-type=rc
```

**How version calculation works** (from `ci-10-determine-version.sh`, **REAL**):

| Current Version | Scope | Pre-release Type | Result |
|---|---|---|---|
| `1.2.3` | `preminor` | `alpha` | `1.3.0-alpha` |
| `1.3.0-alpha` | `prerelease` | `alpha` | `1.3.0-alpha.1` |
| `1.3.0-alpha.1` | `prerelease` | `alpha` | `1.3.0-alpha.2` |
| `1.3.0-alpha.2` | `prerelease` | `beta` | `1.3.0-beta` |
| `1.3.0-beta` | `prerelease` | `rc` | `1.3.0-rc` |
| `1.3.0-rc` | `prerelease` | `rc` | `1.3.0-rc.1` |

> **e-bash `_semver.sh` powers all pre-release arithmetic.** The version calculation uses `semver:parse` to decompose version strings (including pre-release identifiers and numeric suffixes), `semver:increase:*` to bump components, `semver:compare` for ordering, and `semver:recompose` to reconstruct the final version string. This is a full SemVer 2.0.0 implementation in pure bash -- no external tools like `node-semver` are involved. The `semver:constraints` function can also validate that a version satisfies range expressions (e.g., `>=1.0.0 <2.0.0`), and `semver:constraints:complex` expands tilde/caret ranges (`~1.2.3`, `^1.2.3`) into simple constraints.

Pre-releases are published to NPM with the `next` tag (not `latest`) via `ci-66-publish-npm-release.sh`, and GitHub Releases are marked as `prerelease: true`.

---

## How do I publish nightly builds automatically?

The framework does not include a nightly build workflow out of the box, but you can add one easily:

**Create `.github/workflows/nightly.yml`:**

```yaml
name: Nightly Build

on:
  schedule:
    - cron: '0 2 * * *'  # 2 AM UTC daily
  workflow_dispatch: {}   # Allow manual trigger

jobs:
  nightly:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Setup environment
        run: ./scripts/ci/setup/ci-10-install-tools.sh
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Create nightly pre-release
        env:
          CI_RELEASE_SCOPE: prerelease
          CI_PRE_RELEASE_TYPE: alpha
        run: |
          VERSION=$(./scripts/ci/release/ci-10-determine-version.sh)
          # Append nightly date suffix
          NIGHTLY_VERSION="${VERSION}.nightly.$(date +%Y%m%d)"
          echo "Creating nightly: $NIGHTLY_VERSION"
          CI_VERSION="$NIGHTLY_VERSION" ./scripts/ci/release/ci-08-create-tag.sh
```

This leverages the existing version determination logic and tag creation scripts. The tag push will trigger the release pipeline's tag-based job to build and publish.

---

## How do I create per-PR preview deployments?

This is not built into the framework. It requires adding a step to the pre-release (PR) pipeline. Here is an approach:

**Add to `.github/workflows/pre-release.yml`** (or create a dedicated workflow):

```yaml
preview-deploy:
  if: github.event_name == 'pull_request'
  runs-on: ubuntu-latest
  environment:
    name: pr-${{ github.event.pull_request.number }}
    url: https://pr-${{ github.event.pull_request.number }}.preview.example.com
  steps:
    - uses: actions/checkout@v4

    - name: Deploy preview
      env:
        PR_NUMBER: ${{ github.event.pull_request.number }}
      run: |
        echo "Deploying preview for PR #${PR_NUMBER}..."
        # Your preview deployment logic:
        # - Deploy to a unique URL/namespace
        # - e.g., Vercel, Netlify, or a Kubernetes namespace per PR
```

**Add a cleanup workflow** that tears down preview environments when PRs are closed:

```yaml
on:
  pull_request:
    types: [closed]

jobs:
  cleanup-preview:
    runs-on: ubuntu-latest
    steps:
      - name: Destroy preview environment
        run: |
          echo "Cleaning up preview for PR #${{ github.event.pull_request.number }}"
          # Tear down the preview
```

The framework's environment directory structure (`environments/`) could hold a `preview/` template for these ephemeral environments.

---

## How do I manage multiple pre-release channels (alpha, beta, next)?

The Release Pipeline natively supports three pre-release channels: `alpha`, `beta`, and `rc`. All pre-release tags follow the `v{semver}-{stage}` pattern (e.g., `v1.3.0-alpha`, `v1.3.0-beta.2`, `v1.3.0-rc.1`).

**Channel progression:** The intended flow is:

```
alpha  -->  beta  -->  rc  -->  stable release
```

Each channel is managed through the `pre-release-type` input:

```bash
# Start alpha channel
gh workflow run release.yml -f release-scope=preminor -f pre-release-type=alpha

# Iterate on alpha
gh workflow run release.yml -f release-scope=prerelease -f pre-release-type=alpha

# Move to beta channel
gh workflow run release.yml -f release-scope=prerelease -f pre-release-type=beta

# Move to rc channel
gh workflow run release.yml -f release-scope=prerelease -f pre-release-type=rc
```

**Custom stages (hotfix, canary, nightly, etc.):** The version calculation in `ci-10-determine-version.sh` uses the e-bash `_semver.sh` library to handle arbitrary pre-release type strings, not just `alpha`/`beta`/`rc`. The `semver:parse` function decomposes any valid SemVer pre-release identifier, `semver:compare` correctly orders them per SemVer 2.0.0 precedence rules, and the increment logic handles numeric suffix bumping. Custom stages like `hotfix`, `canary`, and `nightly` all follow the same `v{semver}-{stage}` pattern:

- **Hotfix:** `v1.2.3-hotfix`, `v1.2.3-hotfix.1`, `v1.2.3-hotfix.2`
- **Canary:** `v1.2.3-canary`, `v1.2.3-canary.1`
- **Nightly:** `v1.2.3-nightly.20260413`

To use custom stages via the workflow UI, add them to the `pre-release-type` choices in `.github/workflows/release.yml`:

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

> **Implementation gap:** The `pre-release-type` input is currently limited to `alpha`, `beta`, and `rc`. Adding new stages requires editing the `release.yml` choices list. The underlying version calculation script will handle them correctly once they are passed through.

**NPM distribution tags:** Pre-releases are published with `--tag next` (see `ci-66-publish-npm-release.sh`). If you want separate NPM tags per channel (e.g., `alpha`, `beta`, `hotfix`), modify `ci-66-publish-npm-release.sh`:

```bash
if [ "$IS_PRERELEASE" == "true" ]; then
  # Extract channel from version string
  if [[ "$CI_VERSION" == *"-alpha"* ]]; then
    export CI_NPM_TAG="--tag alpha"
  elif [[ "$CI_VERSION" == *"-beta"* ]]; then
    export CI_NPM_TAG="--tag beta"
  elif [[ "$CI_VERSION" == *"-rc"* ]]; then
    export CI_NPM_TAG="--tag rc"
  elif [[ "$CI_VERSION" == *"-hotfix"* ]]; then
    export CI_NPM_TAG="--tag hotfix"
  elif [[ "$CI_VERSION" == *"-canary"* ]]; then
    export CI_NPM_TAG="--tag canary"
  else
    export CI_NPM_TAG="--tag next"
  fi
fi
```

**Adding a `next` channel:** If you want a `next` channel separate from the semver pre-release types, add it to the `pre-release-type` options in `release.yml` following the same pattern above. The version calculation in `ci-10-determine-version.sh` handles it the same way as other pre-release types.

---

## How do I promote a pre-release to stable?

Release a new stable version with the same major.minor.patch:

**Method 1: Cut a stable release.** If your current version is `1.3.0-rc.2`, run:

```bash
# This creates version 1.3.0 (strips the pre-release suffix by bumping patch from 1.2.x)
gh workflow run release.yml -f release-scope=minor
```

The version determination logic in `ci-10-determine-version.sh` will calculate the next minor version. If the current tag is `v1.3.0-rc.2`, a `patch` scope would yield `1.3.1` (since it strips the pre-release and increments patch). To get exactly `1.3.0`, you may need to ensure the latest non-pre-release tag is `v1.2.x` and use `minor`.

**Method 2: Stability tag an existing pre-release.** If a pre-release has been deployed and verified, you can mark it as stable without creating a new version:

```bash
gh workflow run post-release.yml -f action=tag-stable -f version=1.3.0-rc.2
```

This creates `v1.3.0-rc.2-stable` via the **REAL** `ci-07-apply-stability-tag.sh` script. However, this marks the pre-release as stable rather than promoting it to a non-pre-release version.

**Recommended approach:** Use Method 1 for public-facing promotions (creates a clean `1.3.0` release). Use Method 2 for internal tracking of which pre-releases have been verified.

---

## Hard to Implement

Several deployment-related features require significant customization because they depend heavily on your specific infrastructure. Here is an honest assessment:

### Deployment Scripts Are Stubs

The single biggest gap is that `ci-30-deploy.sh` is a stub. Every deployment question ultimately requires you to fill in this script with your infrastructure-specific logic. The framework provides:

- **Workflow triggers** (manual dispatch with environment selection and confirmation gates)
- **Input validation** (version required, production requires `confirm=yes`)
- **Stability tagging** (annotated git tags for stable/unstable)
- **Environment directory structure** (placeholder directories for config)
- **Smoke test scaffolding** (script exists with commented-out examples)

But it does **not** provide:

- Actual deployment commands for any platform
- Health check / readiness probe implementations
- Traffic shifting or load balancer updates
- Database migration orchestration
- Rollback automation (auto-rollback on failure)
- Multi-region coordination logic
- Blue-green or canary traffic management
- Preview environment lifecycle management

### Promote Release Is a Stub

`ci-20-promote-release.sh` explicitly states "Auto-promotion is not yet implemented" and directs users to manually use the Release Pipeline. Implementing true automated promotion (staging verified --> auto-deploy production) would require:

- Integration with your monitoring/observability stack
- Automated health check verification
- Configurable promotion criteria (error rate thresholds, latency budgets)
- A state machine tracking which version is in which environment

### GitHub Environments Not Used

The workflows do not use GitHub's Environments feature, which provides:

- Deployment protection rules (required reviewers before production)
- Environment-scoped secrets (different database URLs per environment)
- Deployment history and status tracking in the GitHub UI
- Wait timers before deployment proceeds

Adding `environment: production` to the deploy job would unlock these features and is a straightforward enhancement.

### No Deployment State Tracking

There is no persistent record of "version X is currently deployed to environment Y." The git tags track stability (stable/unstable) but not current deployment state. To know what is deployed where, you would need to:

- Query your infrastructure directly
- Maintain a deployment log (file, database, or GitHub deployment API)
- Use GitHub Environments (which track deployment history natively)

### Nightly and Preview Builds Require New Workflows

These are not included and must be created from scratch, though the existing version determination and tag creation scripts can be reused as building blocks.

---

## Documentation Gaps

The following areas lack documentation or have incomplete coverage:

1. **No deployment guide.** There is no dedicated document explaining how to implement `ci-30-deploy.sh` for common platforms (Kubernetes, AWS ECS, Vercel, Netlify, bare metal). A `docs/DEPLOYMENT.md` with platform-specific examples would be valuable.

2. **Environment configuration patterns.** The `environments/` directory structure exists but has no documentation explaining the intended conventions. The `.gitkeep` files say "folder for environment specific configurations" but do not describe what config files to place there or what format to use.

3. **Stability tag lifecycle.** `docs/STATES.md` describes the state machine including stability tags and deploy tags, but there is no operational guide explaining the day-to-day workflow of tagging versions as stable/unstable and how that interacts with deployments and deprecation.

4. **Promotion workflow.** The `promote-release` action exists in the Ops workflow but the underlying script is a stub with no documentation about the intended promotion flow or how to implement it.

5. **Rollback procedures.** The Post-Release Pipeline has a rollback action, and `ci-77-confirm-rollback.sh` describes what the rollback will do, but there is no runbook-style document covering: how to identify a bad release, which rollback method to use, how to verify the rollback succeeded, and how to communicate the rollback to stakeholders.

6. **Pre-release channel management.** The version determination script handles alpha/beta/rc channels with sophisticated increment logic, but there is no documentation explaining the recommended progression from alpha through rc to stable, or how NPM distribution tags map to pre-release channels.

7. **GitHub Environments integration.** The workflows could benefit from using GitHub Environments for deployment protection and secret scoping, but there is no documentation about this or plans to adopt it.

8. **Multi-region deployment.** The `environments/production/regions/` directory exists as a placeholder but has no documentation on intended usage patterns.
