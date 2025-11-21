# Quickstart Guide: CI Pipeline Comprehensive Upgrade

**Feature**: 001-ci-pipeline-upgrade
**Date**: 2025-11-21
**Audience**: Developers adopting this CI/CD framework

## Overview

This guide walks you through setting up and using the comprehensive GitHub Actions CI/CD pipeline with advanced deployment control, multi-environment management, and testable scripts.

**What You'll Get**:
- ✅ Four-stage GitHub Actions pipeline (pre-release, release, post-release, maintenance)
- ✅ Git tag-based deployment control with environment suffixes
- ✅ Deployment queuing and rollback capabilities
- ✅ SOPS-encrypted secrets managed via MISE
- ✅ Testable CI scripts with DRY_RUN mode
- ✅ Actionable links in pipeline reports

**Time to Complete**: 30-45 minutes for initial setup

---

## Prerequisites

Before starting, ensure you have:

- [ ] Git repository on GitHub
- [ ] GitHub Actions enabled (included in all GitHub plans)
- [ ] Local development machine with Bash (Linux, macOS, or WSL on Windows)
- [ ] Admin access to repository settings

**Optional but Recommended**:
- Node.js project (for npm publishing features)
- Docker installed (for container publishing features)
- Cloud provider CLI tools (for deployment features)

---

## Setup Steps

### Step 1: Install MISE (2 minutes)

MISE is the tool manager that will automatically install and manage all other required tools.

```bash
# Install MISE
curl https://mise.run | sh

# Activate MISE in your shell (choose your shell)
echo 'eval "$(mise activate bash)"' >> ~/.bashrc  # For Bash
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc    # For ZSH

# Reload your shell
source ~/.bashrc  # or source ~/.zshrc
```

### Step 2: Clone and Enter Repository (1 minute)

```bash
git clone https://github.com/your-org/your-repo.git
cd your-repo
```

**What happens**: MISE automatically reads `mise.toml` and installs all required tools (SOPS, age, Lefthook, Gitleaks, Trufflehog, etc.)

### Step 3: Run Initial Setup (5 minutes)

```bash
# Run the setup task defined in mise.toml
mise run setup
```

**What this does**:
- Installs git hooks via Lefthook (secret scanning, commit message validation)
- Generates age encryption keys if you don't have them
- Creates initial environment configuration folders
- Sets up SOPS configuration for secret encryption

**Expected Output**:
```
✓ Git hooks installed
✓ Age keys found at ~/.config/sops/age/keys.txt
✓ Created environments/staging/
✓ Created environments/production/
✓ SOPS configuration ready
```

### Step 4: Configure GitHub Variables (5 minutes)

Navigate to your repository settings: **Settings → Secrets and variables → Actions → Variables**

Create these variables to enable optional features:

| Variable Name | Value | Purpose |
|---------------|-------|---------|
| `ENABLE_E2E_TESTS` | `true` | Enable end-to-end testing |
| `ENABLE_BUNDLING` | `true` | Enable asset bundling |
| `ENABLE_NPM_PUBLISH` | `true` | Enable npm publishing |
| `ENABLE_DOCKER_PUBLISH` | `true` | Enable Docker publishing |
| `ENABLE_NOTIFICATIONS` | `true` | Enable Apprise notifications |

**Note**: Start with minimal features enabled, add more later as needed.

### Step 5: Configure GitHub Secrets (10 minutes)

Navigate to: **Settings → Secrets and variables → Actions → Secrets**

#### Required Secrets

| Secret Name | Purpose | How to Get |
|-------------|---------|------------|
| `SOPS_AGE_KEY` | Decrypt environment secrets in CI | Copy from `~/.config/sops/age/keys.txt` (your private key) |

#### Optional Secrets (enable features as needed)

| Secret Name | Required If | How to Get |
|-------------|-------------|------------|
| `NPM_TOKEN` | Publishing to npm | Create at npmjs.com → Access Tokens |
| `DOCKER_USERNAME` | Publishing to Docker Hub | Your Docker Hub username |
| `DOCKER_PASSWORD` | Publishing to Docker Hub | Docker Hub access token |
| `APPRISE_URL` | Notifications enabled | See [Apprise documentation](https://github.com/caronc/apprise) |
| `AWS_ACCESS_KEY_ID` | Deploying to AWS | IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | Deploying to AWS | IAM user secret key |

**Security Tip**: Use access tokens with minimal required permissions, rotate regularly.

### Step 6: Create Environment Secrets (5 minutes)

Store environment-specific configuration in SOPS-encrypted files:

```bash
# Edit staging secrets (opens in your $EDITOR)
mise run edit-secrets staging

# In the editor, add your secrets in YAML format:
# database_url: postgres://user:pass@host/db
# api_key: abc123
# Save and exit - file is automatically encrypted

# Repeat for production
mise run edit-secrets production
```

**What gets created**:
- `environments/staging/secrets.enc` - SOPS-encrypted file (safe to commit)
- `environments/production/secrets.enc` - SOPS-encrypted file (safe to commit)

### Step 7: Customize CI Scripts (10 minutes)

The framework provides stub scripts with commented examples. Customize for your project:

```bash
# Example: Customize compilation script
nano scripts/build/10-ci-compile.sh
```

**What you'll see**:
```bash
#!/usr/bin/env bash
# Purpose: Compile project artifacts
# Testability: Responds to CI_TEST_COMPILE_BEHAVIOR or CI_TEST_MODE

# CUSTOMIZE: Uncomment and adjust for your project

# For Node.js/TypeScript projects:
# npm run build

# For Go projects:
# go build -o bin/app ./cmd/app

# For Rust projects:
# cargo build --release

# ... more examples in comments ...
```

**Uncomment** the relevant section and adjust as needed. Repeat for other scripts:
- `scripts/test/10-ci-unit-tests.sh` - Run your unit tests
- `scripts/release/30-ci-publish-npm.sh` - Publish to npm (if applicable)
- `scripts/deployment/20-ci-deploy-production.sh` - Deploy to production

### Step 8: Test Locally (5 minutes)

Test your CI scripts locally before pushing:

```bash
# Test in DRY_RUN mode (prints commands without executing)
CI_TEST_MODE=DRY_RUN ./scripts/build/10-ci-compile.sh

# Test actual execution
CI_TEST_MODE=EXECUTE ./scripts/build/10-ci-compile.sh

# Test failure behavior
CI_TEST_MODE=FAIL ./scripts/build/10-ci-compile.sh
```

**Expected DRY_RUN Output**:
```
[INFO] Starting ci-compile (DRY_RUN mode)
[DRY_RUN] Would execute: npm run build
[SUCCESS] Dry run completed
```

### Step 9: Commit and Push (2 minutes)

```bash
# Commit your changes (commitizen will guide you)
git add .
git commit

# Commitizen prompt appears:
# ? Select the type of change: feat
# ? What is the scope: ci-setup
# ? Short description: add comprehensive CI/CD pipeline
# ? Longer description: [optional]
# ? Breaking changes: No
# ? Issues closed: [optional]

git push origin main
```

**What happens**:
- Lefthook runs pre-commit hooks (secret scanning, action validation)
- Commit message validated against conventional commits format
- Pre-release pipeline triggers on GitHub Actions

### Step 10: Verify Pipeline (3 minutes)

1. Go to your repository on GitHub
2. Click **Actions** tab
3. Find the "Pre-Release Pipeline" workflow run
4. Verify all jobs complete successfully (some may skip if features disabled)

**Expected Results**:
- ✅ Setup job: Success
- ✅ Security-scan job: Success (always runs)
- ⏭️ E2E-tests job: Skipped (if not enabled)
- ✅ Notify-pre-release job: Success

5. Click on **Summary** to see actionable links:
   - "Promote to Release" - create a release
   - "Self-Healing" - auto-fix formatting/linting
   - "Maintenance Tasks" - trigger cleanup, audits, etc.

---

## Understanding Git Tags

This CI/CD system uses a three-tier git tag architecture:

### Tag Types

**1. Version Tags** (immutable)
- Pattern: `<path>/v<semver>` (e.g., `api/v1.2.3`, `v2.0.0`)
- Purpose: Mark release versions
- Created: During release pipeline
- Never moved or deleted

**2. Environment Tags** (movable)
- Pattern: `<path>/<environment>` (e.g., `api/production`, `staging`)
- Purpose: Point to currently deployed commit for each environment
- Created/Moved: Via tag assignment workflow or deployment links
- Act like symbolic links - can be moved to different commits

**3. State Tags** (immutable)
- Pattern: `<path>/v<semver>-<state>` (e.g., `api/v1.2.3-stable`)
- Purpose: Mark version quality for rollback prioritization
- Created: After deployment validation
- States: `stable`, `unstable`, `deprecated`
- Never moved or deleted

### Tag Architecture Example

```
Commit Timeline:

  Commit DEF789 (latest):
    - api/v1.2.0         (version tag)
    - api/staging        (environment tag - points here)

  Commit ABC123:
    - api/v1.1.5         (version tag)
    - api/v1.1.5-stable  (state tag)
    - api/production     (environment tag - points here)

  Commit XYZ456:
    - api/v1.1.4         (version tag)
    - api/v1.1.4-stable  (state tag)

  Commit OLD999:
    - api/v1.0.0              (version tag)
    - api/v1.0.0-deprecated   (state tag - excluded from rollbacks)
```

**Key Benefits**:
- **Easy to see deployments**: `git tag -l '*/production'` shows what's in production
- **Clean tag history**: Environment tags move, version tags stay (no tag clutter)
- **Rollback intelligence**: System prioritizes stable versions automatically
- **Audit trail**: Git log shows when environment tags moved
- **No coordination required**: Pipelines are stateless and concurrent-safe

### Pipeline Independence (Important!)

All pipelines in this system are **stateless and independent**:
- ✅ Multiple pipelines can run concurrently without conflicts
- ✅ Each pipeline run is reproducible (same commit + inputs = same result)
- ✅ No external databases, message queues, or coordination services
- ✅ Git tags are the single source of truth
- ✅ Deployment queue uses GitHub Actions native concurrency (no external state)

**What this means for you**:
- Pipelines derive state from git tags on every run (no caching)
- Re-running a failed pipeline is safe (idempotent operations)
- You can test pipelines in isolation without affecting others
- No shared state files like `.deployment-lock` or `current-version.json`
- Configuration files and secrets are read-only inputs

---

## Common Workflows

### Creating a Release

**Option 1: Via Git Tag**

```bash
# Create version tag
git tag v1.0.0
git push origin v1.0.0
```

**What happens**: Release pipeline triggers automatically, publishes artifacts, creates GitHub Release.

**Option 2: Via GitHub Actions UI**

1. Go to **Actions** → **Release Pipeline**
2. Click **Run workflow**
3. Enter version: `v1.0.0`
4. Click **Run workflow**

---

### Deploying to Environment

Deployments are triggered by creating or moving environment tags.

**Option 1: Via Pipeline Link**

After a successful release, click "Deploy to Staging" link in the pipeline summary (automatically creates/moves environment tag).

**Option 2: Via Tag Assignment Workflow**

1. First, ensure your version tag exists:
   - Version tag `v1.0.0` should already exist from release
   - If deploying sub-project: `api/v1.0.0` should exist

2. Go to **Actions** → **Tag Assignment**
3. Click **Run workflow**
4. Fill in:
   - **Tag type**: `environment`
   - **Environment**: `staging`
   - **Sub-project**: `api` (or leave empty for root)
   - **Commit SHA**: [the commit with version tag `v1.0.0`]
5. Click **Run workflow**

**What happens**:
- Environment tag `staging` (or `api/staging`) is created/moved to the specified commit
- Deployment workflow triggers automatically
- System detects version by finding version tag on same commit
- If another deployment to staging is running, this one queues
- Pipeline summary shows queue position and deployed version

---

### Rolling Back a Deployment

**From Pipeline Link** (easiest):

After a failed deployment, click "Rollback" link in the pipeline summary.

**Manual Trigger**:

1. Go to **Actions** → **Rollback Workflow**
2. Click **Run workflow**
3. Select environment: `production`
4. Target version: `auto` (or specify version)
5. Click **Run workflow**

**What happens**:
- System scans git tags for previous version
- Prioritizes `-stable` tagged versions
- Excludes `-deprecated` versions
- Deploys identified version
- Shows which version was selected and why

---

### Marking a Version as Stable

After verifying a deployment is healthy, mark the version as stable so rollbacks prioritize it.

**From Pipeline Link**:

Click "Mark as Stable" in the post-deployment summary.

**Manual**:

1. Go to **Actions** → **Tag Assignment**
2. Fill in:
   - **Tag type**: `state`
   - **Version**: `v1.0.0` (or `api/v1.0.0` for sub-project)
   - **State**: `stable`
   - **Sub-project**: `api` (or leave empty for root)
3. Click **Run workflow**

**What happens**:
- State tag `v1.0.0-stable` (or `api/v1.0.0-stable`) is created on the same commit as the version tag
- Future rollbacks prioritize this version over non-stable versions
- Version remains immutable (stable tag is separate from version tag)

**Example Tag Structure After Marking Stable**:
```
Commit ABC123:
  - api/v1.0.0        (version tag - immutable)
  - api/v1.0.0-stable (state tag - immutable)
  - api/production    (environment tag - movable, points here after deployment)
```

---

### Running Maintenance Tasks

**From Pipeline Link**:

Click "Maintenance Tasks" → Select mode in the pipeline summary.

**Manual**:

1. Go to **Actions** → **Maintenance Pipeline**
2. Click **Run workflow**
3. Select **task_mode**: `cleanup` (or other modes)
4. **Dry run**: `true` (to preview)
5. Click **Run workflow**
6. Review dry-run results
7. Re-run with **dry run**: `false` to apply

---

## Testing the Pipeline

This system uses **hierarchical testability variables** - feature flags for CI/CD scripts. This enables safe testing in production without affecting real operations.

### Variable Precedence (Most Specific Wins)

1. `CI_TEST_<PIPELINE>_<SCRIPT>_BEHAVIOR` - pipeline + script specific
2. `CI_TEST_<SCRIPT>_BEHAVIOR` - script specific (all pipelines)
3. `CI_TEST_MODE` - global default
4. `EXECUTE` - hardcoded default

### Testing in Production (Recommended Workflow)

**Scenario: Test new deployment script without affecting production**

1. **Set GitHub Variable** (Settings → Secrets and variables → Actions → Variables):
   ```
   Name: CI_TEST_DEPLOYMENT_PRODUCTION_DEPLOY_BEHAVIOR
   Value: DRY_RUN
   ```

2. **Trigger production deployment**:
   - Deployment runs in DRY_RUN mode (prints commands, doesn't execute)
   - Staging still deploys normally

3. **Review logs**:
   - Check what commands would have been executed
   - Verify parameters, paths, credentials are correct

4. **Gradually roll out**:
   ```bash
   # Week 1: Test in staging
   CI_TEST_DEPLOYMENT_STAGING_DEPLOY_BEHAVIOR=DRY_RUN

   # Week 2: Test in production
   CI_TEST_DEPLOYMENT_PRODUCTION_DEPLOY_BEHAVIOR=DRY_RUN

   # Week 3: Full rollout (remove variables)
   ```

5. **Remove variable when confident**

### Common Testing Patterns

**Pattern 1: Test single script across all pipelines**
```bash
# Set in GitHub Variables:
CI_TEST_PUBLISH_NPM_BEHAVIOR=DRY_RUN

# Result: npm publishing in DRY_RUN everywhere
```

**Pattern 2: Test entire pipeline except critical steps**
```bash
# Set in GitHub Variables:
CI_TEST_MODE=DRY_RUN
CI_TEST_SECURITY_SCAN_BEHAVIOR=EXECUTE

# Result: Everything in DRY_RUN except security (must always run)
```

**Pattern 3: Test specific script in specific pipeline**
```bash
# Set in GitHub Variables:
CI_TEST_PRE_RELEASE_COMPILE_BEHAVIOR=DRY_RUN

# Result: Only pre-release compile in DRY_RUN, release compile runs normally
```

**Pattern 4: Simulate failures for testing**
```bash
# Set in GitHub Variables:
CI_TEST_DEPLOYMENT_STAGING_DEPLOY_BEHAVIOR=FAIL

# Result: Staging deployment always fails (test rollback procedures)
```

### Test All Execution Paths (CI Matrix)

Use GitHub Actions matrix testing to verify all code paths:

```yaml
# In .github/workflows/test-ci-scripts.yml
strategy:
  matrix:
    test_mode: [EXECUTE, DRY_RUN, PASS, FAIL, SKIP]
    script:
      - scripts/build/10-ci-compile.sh
      - scripts/test/10-ci-unit-tests.sh
      # ... more scripts
```

### Test Locally

```bash
# Test all scripts in DRY_RUN mode
for script in scripts/**/*ci-*.sh; do
  echo "Testing $script"
  CI_TEST_MODE=DRY_RUN "$script"
done

# Test specific script in specific pipeline context
GITHUB_WORKFLOW="Pre-Release Pipeline" \
  CI_TEST_PRE_RELEASE_COMPILE_BEHAVIOR=DRY_RUN \
  scripts/build/10-ci-compile.sh
```

### Viewing Active Test Variables

Check which test variables are currently set:

1. Go to **Settings → Secrets and variables → Actions → Variables**
2. Look for variables starting with `CI_TEST_`
3. Document what each one is testing and when to remove it

**Pro Tip**: Use variable names as documentation:
- Include date: `CI_TEST_DEPLOY_BEHAVIOR__TESTING_UNTIL_2025_12_01`
- Include reason: `CI_TEST_PUBLISH_NPM_BEHAVIOR__NEW_REGISTRY`

---

## Customization Guide

### Adding a New Environment

1. **Create folder structure**:
```bash
mkdir -p environments/canary/regions/{us-east,eu-west}
```

2. **Create secrets file**:
```bash
mise run edit-secrets canary
# Add environment-specific secrets
```

3. **Create configuration**:
```bash
cat > environments/canary/config.yml <<EOF
environment: canary
replicas: 2
health_check_interval: 30s
EOF
```

4. **Update tag assignment workflow**:
Add `canary` to environment choices in `.github/workflows/tag-assignment.yml`.

5. **Create deployment script**:
Copy `scripts/deployment/10-ci-deploy-staging.sh` to `scripts/deployment/15-ci-deploy-canary.sh` and customize.

### Adding a New CI Script

1. **Create script file**:
```bash
nano scripts/build/50-ci-custom-step.sh
```

2. **Add testability template**:
```bash
#!/usr/bin/env bash
set -euo pipefail

# Purpose: [describe what this does]
# Testability: Responds to CI_TEST_CUSTOM_STEP_BEHAVIOR or CI_TEST_MODE

MODE="${CI_TEST_CUSTOM_STEP_BEHAVIOR:-${CI_TEST_MODE:-EXECUTE}}"

case "$MODE" in
  DRY_RUN)
    echo "[DRY_RUN] Would execute: <command>"
    exit 0
    ;;
  PASS)
    echo "[PASS] Simulated success"
    exit 0
    ;;
  FAIL)
    echo "[FAIL] Simulated failure"
    exit 1
    ;;
  SKIP)
    echo "[SKIP] Step skipped"
    exit 0
    ;;
  TIMEOUT)
    echo "[TIMEOUT] Simulating hang"
    sleep infinity
    ;;
  EXECUTE)
    # Your actual implementation here
    echo "[INFO] Starting custom-step"
    # ... commands ...
    echo "[SUCCESS] Custom step completed"
    ;;
esac
```

3. **Make executable**:
```bash
chmod +x scripts/build/50-ci-custom-step.sh
```

4. **Add to workflow**:
Edit `.github/workflows/pre-release.yml` to call your script.

### Configuring Multi-Region Deployment

1. **Define regions**:
```bash
mkdir -p environments/production/regions/{us-east,us-west,eu-west,ap-south}
```

2. **Create region configs**:
```bash
cat > environments/production/regions/us-east/config.yml <<EOF
region: us-east
cloud_mappings:
  aws: us-east-1
  azure: eastus
  gcp: us-east1
endpoint: https://api-us-east.example.com
EOF
```

3. **Update deployment script**:
Modify `scripts/deployment/20-ci-deploy-production.sh` to loop over regions:
```bash
REGIONS="${DEPLOY_REGIONS:-all}"
if [ "$REGIONS" = "all" ]; then
  REGIONS="us-east us-west eu-west ap-south"
fi

for region in $REGIONS; do
  echo "[INFO] Deploying to $region"
  # ... region-specific deployment ...
done
```

---

## Troubleshooting

### Pipeline Fails with "Protected tag creation blocked"

**Cause**: Attempted to manually push environment tag (e.g., `-production`)

**Solution**: Use Tag Assignment workflow instead:
```bash
# Don't do this:
git tag v1.0.0-production  # Blocked by git hooks

# Do this instead:
# Use GitHub Actions Tag Assignment workflow
```

### Secret Decryption Fails in CI

**Cause**: `SOPS_AGE_KEY` secret not configured or incorrect

**Solution**:
1. Get your age private key: `cat ~/.config/sops/age/keys.txt`
2. Copy the entire key (including `AGE-SECRET-KEY-1...`)
3. Add to GitHub Secrets as `SOPS_AGE_KEY`

### Deployment Stuck in Queue

**Cause**: Previous deployment to same environment hasn't completed

**Solution**:
1. Check **Actions** → **Deployment Workflow** for running jobs
2. Wait for current deployment to complete, or
3. Cancel stuck deployment (if safe to do so)
4. Your deployment will automatically start

### Script Fails Locally but Passes in CI

**Cause**: Tool versions differ between local and CI

**Solution**: Use MISE to ensure consistent tool versions:
```bash
# Install exact versions from mise.toml
mise install

# Verify versions match
mise list
```

### Pipeline Summary Missing Action Links

**Cause**: Report generator script not executed or failed

**Solution**:
1. Check notify job logs for errors
2. Verify `scripts/ci/report-generator.sh` is executable
3. Ensure `$GITHUB_STEP_SUMMARY` is writable in workflow

---

## Next Steps

After completing the quickstart:

1. **Review the spec** ([spec.md](./spec.md)) for comprehensive feature details
2. **Explore contracts** ([contracts/](./contracts/)) for workflow interface specifications
3. **Read data model** ([data-model.md](./data-model.md)) for entity definitions
4. **Customize scripts** in `scripts/` for your specific needs
5. **Enable advanced features** by setting additional GitHub Variables
6. **Set up notifications** with Apprise URL for Slack, Teams, Discord, etc.
7. **Configure branch protection** to require status checks before merge

---

## Getting Help

- **Documentation**: Read comprehensive spec in `specs/001-ci-pipeline-upgrade/spec.md`
- **Issues**: Open an issue in the repository with `[CI]` prefix
- **Logs**: Check GitHub Actions logs for detailed execution traces
- **Local Testing**: Use `CI_TEST_MODE=DRY_RUN` to preview commands before execution

---

**Quickstart Complete**: You now have a production-ready CI/CD pipeline!

**Last Updated**: 2025-11-21
