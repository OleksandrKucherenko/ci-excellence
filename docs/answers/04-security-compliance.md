# Security and Compliance FAQ

Answers to common questions about security scanning, secret management, incident response, and compliance within the CI Excellence framework.

## How do I enforce a forced upgrade to a security-fixed dependency version?

**Status: Stub -- requires project-specific customization.**

The framework does not ship an automatic forced-upgrade mechanism, but the maintenance pipeline provides the scaffolding:

1. **Edit the dependency audit script** to add a version constraint check.
   Open `scripts/ci/maintenance/ci-60-security-audit.sh` and uncomment or add the audit command for your ecosystem:

   ```bash
   # npm
   npm audit fix --force

   # pip
   pip-audit -r requirements.txt --fix

   # cargo
   cargo update -p vulnerable-crate
   ```

2. **Run the maintenance pipeline on demand** to apply the fix across the project:

   ```bash
   gh workflow run maintenance.yml -f action=security-audit
   ```

   This triggers the `security-audit` job in `.github/workflows/maintenance.yml`, which runs `ci-60-security-audit.sh` followed by `ci-30-security-scan.sh`.

3. **For an immediate lockfile pin**, manually edit your lockfile or use an override:

   ```bash
   # npm: add override in package.json
   "overrides": { "vulnerable-package": ">=2.1.0" }

   # pip: pin in requirements.txt
   vulnerable-package>=2.1.0
   ```

4. **Fail the build on outdated dependencies** by enabling `ENABLE_SECURITY_SCAN=true` in your GitHub repository variables. The pre-release pipeline (`pre-release.yml`) runs `ci-30-security-scan.sh` in the `security-scan` job and will fail the pipeline if issues are detected.

5. **Verify security tools are installed and at the required version** using the e-bash `_dependencies.sh` module. Before running audits, check that tools meet minimum version requirements:
   ```bash
   source scripts/lib/_dependencies.sh
   dependency:exists gitleaks || { echo "gitleaks not found"; exit 1; }
   dependency:version:gte "$(gitleaks version)" "8.0.0" || { echo "gitleaks >= 8.0.0 required"; exit 1; }
   dependency:find "node" "18.0.0"  # find node matching minimum version
   ```
   The module includes built-in alias resolution (e.g., `rust` resolves to `rustc`) and disk-backed caching for fast repeated checks.

**Limitation:** `ci-60-security-audit.sh` is a stub with commented-out examples. You must uncomment and adapt the commands for your language ecosystem.

## How do I handle and patch a newly discovered security leak in the repository?

**Status: Implemented -- gitleaks and trufflehog are fully operational.**

### Step 1: Confirm the leak exists

Run the security scan locally:

```bash
# Scan the full repository with gitleaks
mise x -- gitleaks detect --redact --verbose --report-path gitleaks-report.json --report-format json

# Scan with trufflehog (only verified/active credentials)
mise x -- trufflehog git file://. --only-verified --fail --json
```

### Step 2: Rotate the exposed credential immediately

Do this before any cleanup. See the next FAQ entry for rotation steps.

### Step 3: Remove the secret from the current codebase

Replace the hardcoded value with an environment variable or SOPS-encrypted secret (see `docs/MISE-SETUP.md` for the full SOPS + age workflow):

```bash
# Edit the encrypted secrets file
mise run edit-secrets

# Add the replacement secret, save, and SOPS re-encrypts automatically
```

### Step 4: Remove the secret from git history

If the secret was pushed to a remote:

```bash
# Option A: BFG Repo Cleaner (recommended for simplicity)
bfg --replace-text passwords.txt .

# Option B: git filter-repo
git filter-repo --invert-paths --path path/to/file-with-secret

# After rewriting history
git push --force --all
```

Coordinate with the team before force-pushing, as this rewrites commit hashes.

### Step 5: Verify the cleanup

```bash
# Re-scan to confirm the secret is gone
mise x -- gitleaks detect --redact --verbose
mise x -- trufflehog git file://. --only-verified --fail --json
```

### Step 6: Add a custom gitleaks rule (if the pattern is new)

Edit `.gitleaks.toml` to catch similar secrets in the future:

```toml
[[rules]]
id = "my-new-pattern"
description = "Description of the new secret pattern"
regex = '''pattern-regex-here'''
tags = ["key", "custom"]
```

The existing `.gitleaks.toml` already covers GitHub tokens (`ghp_`, `ghu_`, `ghs_`, `ghr_`), Slack webhooks/tokens, NPM tokens, Docker Hub tokens, age secret keys, and generic API keys.

## How do I rotate tokens/secrets after a security incident?

**Status: Implemented -- SOPS + age encryption is fully operational.**

### Step 1: Revoke the compromised token at the provider

Examples:
- **GitHub PAT**: Settings > Developer Settings > Personal access tokens > Delete and regenerate
- **NPM token**: npmjs.com > Access Tokens > Delete and create new
- **Slack webhook**: Slack admin > Incoming Webhooks > Regenerate URL
- **Docker Hub token**: Hub > Account Settings > Security > Regenerate

### Step 2: Update the encrypted secrets file

```bash
# Open the SOPS-encrypted secrets file in your editor
mise run edit-secrets

# Replace the old token value with the new one
# Save and exit -- SOPS re-encrypts automatically
```

The secrets file structure follows `config/.env.secrets.json.example`:

```json
{
  "NPM_TOKEN": "new_token_value",
  "GITHUB_TOKEN": "ghp_new_token",
  "SLACK_WEBHOOK": "https://hooks.slack.com/services/NEW/WEBHOOK/URL"
}
```

### Step 3: Update CI/CD secrets in GitHub

```bash
# Update a repository secret via the GitHub CLI
gh secret set NPM_TOKEN --body "new_token_value"
gh secret set SLACK_WEBHOOK --body "https://hooks.slack.com/services/NEW/WEBHOOK/URL"
```

### Step 4: Verify the new secrets work

```bash
# Decrypt locally to confirm the update
mise run decrypt-secrets

# Trigger a pipeline run to confirm CI still passes
gh workflow run pre-release.yml
```

### Step 5: Commit the updated encrypted file

```bash
git add .env.secrets.json
git commit -m "chore: rotate compromised tokens"
```

The encrypted file is safe to commit. The `.gitleaks.toml` allowlist includes a regex for SOPS-encrypted values (`ENC[AES256_GCM,data:...,iv:...,tag:...]`), so gitleaks will not flag the encrypted content.

## How do I run a full security audit (secret scan and dependency scan) on demand?

**Status: Partially implemented -- secret scanning is real; dependency audit is a stub.**

### Option 1: Trigger the maintenance workflow from GitHub

```bash
gh workflow run maintenance.yml -f action=security-audit
```

This runs the `security-audit` job in `.github/workflows/maintenance.yml`, which executes:
1. `scripts/ci/maintenance/ci-60-security-audit.sh` -- dependency audit (stub, must be customized)
2. `scripts/ci/build/ci-30-security-scan.sh` -- gitleaks + trufflehog (real, working)
3. Uploads `security-results.sarif` to the GitHub Security tab

Make sure `ENABLE_SECURITY_AUDIT` is set to `true` in your GitHub repository variables, otherwise the scan steps are skipped.

### Option 2: Run locally

```bash
# Secret detection with gitleaks
mise x -- gitleaks detect --redact --verbose --report-path gitleaks-report.json --report-format json

# Credential detection with trufflehog
mise x -- trufflehog git file://. --only-verified --fail --json

# Dependency audit (adapt to your ecosystem)
npm audit --audit-level=moderate   # Node.js
pip-audit -r requirements.txt      # Python
cargo audit                        # Rust
```

### Option 3: Let it run automatically

The auto-fix workflow (`.github/workflows/auto-fix-quality.yml`) runs `ci-30-security-scan.sh` on every push to `develop`, `feature/**`, `fix/**`, and `claude/**` branches. Results are uploaded as artifacts (`gitleaks-report.json`, `trufflehog-report.json`, `security-results.sarif`) with 30-day retention, and SARIF is uploaded to the GitHub Security tab.

The pre-release pipeline (`pre-release.yml`) also includes a `security-scan` job gated behind the `ENABLE_SECURITY_SCAN` variable.

## How do I audit who has access to which secrets?

**Status: Not implemented -- requires manual tracking or external tooling.**

The framework uses SOPS + age encryption for local secrets. Access control is based on who possesses the age private key (`.secrets/mise-age.txt`).

### Current state

- **Local secrets (SOPS):** Anyone with the age private key can decrypt `.env.secrets.json`. There is no built-in mechanism to track who holds the key.
- **CI/CD secrets (GitHub):** Access is governed by GitHub repository permissions. Only users with repository admin or write access can view/modify repository secrets.

### Steps you can take today

1. **Audit GitHub secret access:**

   ```bash
   # List repository collaborators and their permission levels
   gh api repos/{owner}/{repo}/collaborators --jq '.[] | "\(.login): \(.permissions)"'

   # List teams with access
   gh api repos/{owner}/{repo}/teams --jq '.[] | "\(.name): \(.permission)"'
   ```

2. **Audit SOPS recipients:** Check which age public keys are authorized to decrypt. Look at the `sops` metadata section in `.env.secrets.json`:

   ```bash
   # View SOPS recipients without decrypting the file
   sops --decrypt --extract '["sops"]' .env.secrets.json 2>/dev/null || \
     grep -A5 '"age"' .env.secrets.json
   ```

3. **Track key distribution manually:** Maintain a record of which team members received the age private key and when.

**Recommendation:** For production systems, consider migrating to a centralized secrets manager (HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager) that provides built-in access logging and role-based access control.

## How do I detect and remove accidentally committed secrets from git history?

**Status: Implemented (detection) -- removal requires external tools.**

### Detection

The framework catches secrets at multiple layers:

1. **Pre-commit hook** (`.lefthook.toml`): gitleaks scans staged files before every commit.
2. **Pre-push hook** (`.lefthook.toml`): gitleaks performs a full scan and trufflehog scans commits since the upstream ref.
3. **CI pipeline**: `ci-30-security-scan.sh` runs gitleaks and trufflehog against the entire repository.

To scan for secrets already in history:

```bash
# Scan all historical commits with gitleaks
mise x -- gitleaks detect --redact --verbose --report-path gitleaks-report.json --report-format json

# Scan history with trufflehog (checks if credentials are still active)
mise x -- trufflehog git file://. --only-verified --json
```

### Removal

Once detected, remove secrets from git history using one of these approaches:

```bash
# Option A: BFG Repo Cleaner (fast, simple)
# Install: brew install bfg
echo "leaked-secret-value" > passwords.txt
bfg --replace-text passwords.txt .
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push --force --all

# Option B: git filter-repo (more flexible)
# Install: pip install git-filter-repo
git filter-repo --invert-paths --path path/to/file-with-secret
git push --force --all
```

**Critical steps after removal:**

1. **Rotate the secret immediately** -- removing it from history does not revoke access. Assume the secret is compromised.
2. **Notify the team** about the force-push so they can re-clone or rebase.
3. **Re-run the scan** to confirm the secret is gone from history.
4. **Add a gitleaks rule** in `.gitleaks.toml` if the pattern is not already covered.

## How do I generate a compliance report for all releases in a time period?

**Status: Not implemented -- requires custom scripting.**

The framework does not include a compliance report generator, but you can build one using the existing GitHub data:

```bash
# List all releases in a date range
gh release list --limit 100 | while read -r line; do
  tag=$(echo "$line" | awk '{print $1}')
  date=$(gh release view "$tag" --json publishedAt --jq '.publishedAt')
  # Filter by date range
  if [[ "$date" > "2025-01-01" && "$date" < "2025-07-01" ]]; then
    echo "Release: $tag | Date: $date"
    gh release view "$tag" --json body --jq '.body'
    echo "---"
  fi
done

# List all workflow runs for the release pipeline in a date range
gh run list --workflow=release.yml --limit 200 \
  --json createdAt,headBranch,conclusion,url \
  --jq '.[] | select(.createdAt > "2025-01-01" and .createdAt < "2025-07-01")'
```

For a more structured report, you could write a script that:
1. Queries all releases via `gh release list`
2. Queries all security scan artifacts via `gh run list --workflow=maintenance.yml`
3. Checks SARIF uploads in the GitHub Security tab via the API
4. Outputs a formatted report (CSV, JSON, or Markdown)

**Recommendation:** For regulated environments, consider integrating a purpose-built compliance tool (e.g., Drata, Vanta, or a custom GitHub App) that continuously tracks releases, approvals, and scan results.

## How do I track which versions are deployed to which environments?

**Status: Stub -- the Ops pipeline provides the structure but deployment is not implemented.**

The Ops pipeline (`.github/workflows/ops.yml`) supports `deploy-staging` and `deploy-production` actions:

```bash
# Deploy a version to staging
gh workflow run ops.yml -f action=deploy-staging -f version=1.2.3

# Deploy a version to production (requires confirmation)
gh workflow run ops.yml -f action=deploy-production -f version=1.2.3 -f confirm=yes
```

However, `scripts/ci/ops/ci-30-deploy.sh` is a stub that prints a message and exits. It does not actually deploy or record the deployment.

### Building a deployment tracking mechanism

1. **Tag deployments with GitHub Deployments API:**

   Add to `ci-30-deploy.sh`:
   ```bash
   gh api repos/{owner}/{repo}/deployments \
     -f ref="v${VERSION}" \
     -f environment="${ENVIRONMENT}" \
     -f description="Deployed v${VERSION} to ${ENVIRONMENT}"
   ```

2. **Query deployment history:**

   ```bash
   # List all deployments to production
   gh api repos/{owner}/{repo}/deployments \
     --jq '.[] | select(.environment == "production") | "\(.ref): \(.created_at)"'
   ```

3. **Use GitHub Environments** (Settings > Environments) to enforce deployment rules per environment (required reviewers, wait timers, branch restrictions).

**Recommendation:** When you implement actual deployments in `ci-30-deploy.sh`, record each deployment using the GitHub Deployments API or an external deployment tracker.

## How do I enforce required approvals before production releases?

**Status: Partially supported -- infrastructure exists but requires GitHub configuration.**

### GitHub branch protection rules (recommended)

Configure branch protection for `main`:

1. Go to Settings > Branches > Add rule for `main`
2. Enable:
   - **Require a pull request before merging**
   - **Require approvals** (set minimum reviewers, e.g., 2)
   - **Require review from Code Owners** (requires a `CODEOWNERS` file)
   - **Require status checks to pass** (select the pre-release pipeline jobs)
   - **Require conversation resolution before merging**

### Production deployment confirmation

The Ops pipeline already requires manual confirmation for production deployments. In `scripts/ci/ops/ci-30-deploy.sh`:

```bash
if [ "$ENVIRONMENT" == "production" ] && [ "$CONFIRM" != "yes" ]; then
  echo "Error: Production deployment requires confirmation 'yes'"
  exit 1
fi
```

This means you must explicitly pass `-f confirm=yes` when triggering a production deploy.

### GitHub Environments (additional layer)

Configure a `production` environment in Settings > Environments with:
- **Required reviewers**: Specify team members who must approve
- **Wait timer**: Add a delay before deployment proceeds
- **Deployment branches**: Restrict to `main` only

### Release pipeline controls

The release pipeline (`.github/workflows/release.yml`) is `workflow_dispatch` only, meaning releases must be manually triggered. Combined with branch protection on `main`, this ensures:
1. Code must be reviewed and approved via PR
2. Status checks (lint, tests, security scan) must pass
3. A team member must manually trigger the release
4. Production deployment requires explicit confirmation

## How do I maintain an audit log of all pipeline executions?

**Status: Partially implemented -- GitHub provides the data; aggregation is not built in.**

### What already exists

GitHub Actions automatically records every workflow run, including:
- Who triggered it (actor)
- What branch/tag/PR it ran on
- Every step's output, duration, and exit code
- Uploaded artifacts (security reports, SARIF files, build outputs)

The framework's summary scripts (`scripts/ci/reports/ci-*-summary-*.sh`) generate GitHub Step Summaries for each pipeline, which are visible on the workflow run page.

### Querying the audit log

```bash
# List recent workflow runs
gh run list --limit 50

# Filter by workflow
gh run list --workflow=release.yml --limit 50
gh run list --workflow=maintenance.yml --limit 50

# Get details of a specific run
gh run view <run-id> --log

# Export all runs as JSON for archiving
gh run list --workflow=release.yml --limit 500 \
  --json createdAt,headBranch,conclusion,url,actor,event \
  > release-pipeline-audit-log.json

# GitHub organization audit log (requires admin access)
gh api orgs/{org}/audit-log --jq '.[] | select(.action | startswith("workflows"))'
```

### Retention

- **Workflow run logs**: Retained per your GitHub plan settings (default 90 days for public repos, configurable up to 400 days for enterprise).
- **Artifacts**: Retention is configured in each workflow. The framework uses `REPORT_RETENTION_DAYS` (default 30), `ARTIFACT_RETENTION_DAYS` (default 7), and `DELIVERABLE_RETENTION_DAYS` (default 14).
- **SARIF security results**: Uploaded to the GitHub Security tab and retained indefinitely.

**Recommendation:** For long-term audit requirements, set up a scheduled job that exports workflow run data to durable storage (S3, GCS, or a log aggregation system) before GitHub's retention window expires.

## How do I verify license compliance for all dependencies?

**Status: Not implemented -- requires adding license scanning tools.**

The framework does not include license compliance checking. Here is how to add it:

### Option 1: Add to the security audit script

Edit `scripts/ci/maintenance/ci-60-security-audit.sh`:

```bash
# Node.js: license-checker
npx license-checker --production --failOn "GPL-3.0;AGPL-3.0" --json > license-report.json

# Python: pip-licenses
pip-licenses --format=json --output-file=license-report.json

# Rust: cargo-deny
cargo deny check licenses

# Multi-language: FOSSA CLI or Snyk
fossa analyze
fossa test
```

### Option 2: Use a GitHub Action

Add a new job to `pre-release.yml` or `maintenance.yml`:

```yaml
license-check:
  name: License Compliance
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - name: Check licenses
      run: npx license-checker --production --failOn "GPL-3.0;AGPL-3.0"
```

### Option 3: Use GitHub's built-in dependency graph

Enable the dependency graph and Dependabot alerts in your repository settings (Settings > Code security and analysis). GitHub will flag licenses on dependencies automatically if you are on a GitHub Enterprise plan.

**Recommendation:** For regulated projects, use a dedicated tool like FOSSA, Snyk, or WhiteSource that maintains a database of license obligations and can generate compliance attestation documents.

## How do I verify the history of versions deployed to each environment?

**Status: Not implemented -- depends on deployment tracking being built.**

Since `scripts/ci/ops/ci-30-deploy.sh` is a stub, there is no deployment history recorded yet. Once you implement actual deployments, use one of these approaches:

### Approach 1: GitHub Deployments API

If you record deployments via the GitHub API (see the deployment tracking question above):

```bash
# List all deployments with their environment and status
gh api repos/{owner}/{repo}/deployments --paginate \
  --jq '.[] | "\(.environment) | v\(.ref) | \(.created_at) | \(.creator.login)"'

# Filter by environment
gh api repos/{owner}/{repo}/deployments --paginate \
  --jq '.[] | select(.environment == "production") | "\(.ref): \(.created_at)"'

# Get deployment statuses (success, failure, etc.)
gh api repos/{owner}/{repo}/deployments/{deployment-id}/statuses \
  --jq '.[] | "\(.state): \(.created_at)"'
```

### Approach 2: Git tags for deployment tracking

Add tagging to `ci-30-deploy.sh`:

```bash
git tag "deploy/${ENVIRONMENT}/v${VERSION}" -m "Deployed v${VERSION} to ${ENVIRONMENT}"
git push origin "deploy/${ENVIRONMENT}/v${VERSION}"
```

Then query the history:

```bash
# List all production deployments
git tag -l "deploy/production/*" --sort=-creatordate

# List all staging deployments
git tag -l "deploy/staging/*" --sort=-creatordate
```

### Approach 3: Ops pipeline run history

Since all deployments go through the Ops pipeline, you can query workflow runs:

```bash
gh run list --workflow=ops.yml --limit 100 \
  --json createdAt,conclusion,displayTitle \
  --jq '.[] | select(.displayTitle | contains("production"))'
```

**Limitation:** This only works for deployments triggered through the Ops workflow and does not capture manual or out-of-band deployments.

## Documentation Gaps

The following areas lack implementation or documentation in the current framework:

1. **Dependency audit (`ci-60-security-audit.sh`)**: The script is a stub with commented-out examples. It must be customized per project to run `npm audit`, `pip-audit`, `cargo audit`, or equivalent tools. No language ecosystem is wired up by default.

2. **Deployment tracking**: The Ops pipeline (`ops.yml` and `ci-30-deploy.sh`) provides the workflow structure but does not implement actual deployments or record deployment history. There is no integration with the GitHub Deployments API.

3. **Secret access auditing**: There is no mechanism to track who holds the age private key or when it was distributed. SOPS + age is a file-based encryption model without centralized access logging.

4. **License compliance**: No license scanning tools are configured. The framework has no `license-checker`, `cargo-deny`, or equivalent integration.

5. **Compliance reporting**: No automated report generation for releases, deployments, or security scan results over time. Data exists in GitHub (workflow runs, releases, SARIF uploads) but must be queried and aggregated manually.

6. **SARIF generation completeness**: The `ci-30-security-scan.sh` script generates a SARIF file, but it always contains an empty `results` array. Actual gitleaks and trufflehog findings are written to separate JSON files (`gitleaks-report.json`, `trufflehog-report.json`) but are not merged into the SARIF output. This means the GitHub Security tab may show an empty scan even when issues are found.

7. **Git history rewriting tooling**: The framework references BFG Repo Cleaner and `git filter-repo` in documentation (`docs/GIT-HOOKS.md`) but neither tool is installed via `mise.toml`. Teams must install them separately.

8. **Environment-specific approval gates**: The Ops pipeline requires a `confirm=yes` string for production deploys, but there are no GitHub Environment protection rules configured by default. These must be set up manually in repository settings.
