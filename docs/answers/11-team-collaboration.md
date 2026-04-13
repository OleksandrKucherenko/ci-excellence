# Team Collaboration

Answers to common questions about access control, workflow management, and team coordination within CI Excellence. Most of these capabilities rely on **GitHub platform features** rather than CI Excellence-specific code. This document makes the distinction explicit.

> **Notation:** Items marked **(GitHub Platform)** are configured entirely through the GitHub UI or API. Items marked **(CI Excellence)** involve project scripts or workflow files. Items marked **(Combined)** require configuration in both places.

---

## How do I grant/revoke access to trigger workflows?

**(GitHub Platform)**

Workflow trigger permissions are governed by GitHub's repository access model, not by CI Excellence configuration.

**For `workflow_dispatch` workflows (Release, Ops, Post-Release, Maintenance):**

Access to the "Run workflow" button requires **write** access to the repository. This is controlled through:

1. **Repository Settings > Collaborators and teams:** Add or remove individuals/teams with `Write`, `Maintain`, or `Admin` roles. Users with `Read` or `Triage` roles cannot trigger `workflow_dispatch` workflows.

2. **Organization-level teams:** If your repository is in a GitHub Organization, manage team membership at the org level and assign the team a repository role.

**Using gh CLI:**

```bash
# Add a collaborator with write access
gh api repos/{owner}/{repo}/collaborators/{username} -X PUT -f permission=push

# Remove a collaborator
gh api repos/{owner}/{repo}/collaborators/{username} -X DELETE

# List current collaborators
gh api repos/{owner}/{repo}/collaborators --jq '.[].login'
```

**For automatically triggered workflows (Pre-Release, Auto-Fix Quality):**

These trigger on `push` and `pull_request` events. Anyone who can push to a matching branch or open a PR can trigger them. Restrict this through branch protection rules (see next answer).

**CI Excellence does not add any additional access control layer** on top of what GitHub provides. The `ops.yml` workflow has a `confirm` input for critical actions (`deploy-production`), but this is a safety prompt, not an access control mechanism.

---

## How do I require approvals for production deployments?

**(GitHub Platform + CI Excellence)**

This uses GitHub Environments, which provide approval gates, and the Ops workflow, which handles deployment actions.

**Step 1 -- Create a GitHub Environment:**

1. Go to **Settings > Environments > New environment**.
2. Name it `production`.
3. Under **Environment protection rules**, check **Required reviewers**.
4. Add the users or teams who must approve production deployments.
5. Optionally restrict which branches can deploy to this environment (e.g., only `main`).

**Step 2 -- Reference the environment in the workflow:**

Edit `.github/workflows/ops.yml` to add the environment to the production deploy step. Currently the ops workflow does **not** reference any GitHub Environment. You need to add it:

```yaml
jobs:
  ops-handler:
    name: Handle Ops Action
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.action == 'deploy-production' && 'production' || '' }}
```

Or, for a dedicated production deployment job:

```yaml
  deploy-production:
    name: Deploy to Production
    runs-on: ubuntu-latest
    if: github.event.inputs.action == 'deploy-production'
    environment:
      name: production
      url: https://your-production-url.example.com
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      - name: Deploy
        env:
          OPS_VERSION: ${{ github.event.inputs.version }}
          OPS_ENVIRONMENT: production
        run: ./scripts/ci/ops/ci-30-deploy.sh
```

When a workflow job references an environment with required reviewers, GitHub will pause the job and notify the designated reviewers. The job proceeds only after approval.

**Step 3 -- Configure environment-scoped secrets (optional):**

Production secrets (e.g., production database credentials, API keys) can be scoped to the `production` environment so they are only available to jobs running in that environment. Add these under **Settings > Environments > production > Environment secrets**.

**Note:** The current `ops.yml` workflow does not use GitHub Environments. The `deploy-staging` and `deploy-production` actions are stubs (`scripts/ci/ops/ci-30-deploy.sh`) that need project-specific implementation. Adding the environment reference is a one-line change to the workflow file.

---

## How do I restrict who can override CI checks?

**(GitHub Platform)**

This is controlled entirely through GitHub branch protection rules. CI Excellence does not implement its own check-override mechanism.

**Configure branch protection:**

1. Go to **Settings > Branches > Branch protection rules**.
2. Click **Add rule** (or edit the existing rule for `main`).
3. Configure:
   - **Require status checks to pass before merging:** Select the jobs that must pass (e.g., `setup`, `compile`, `lint`, `unit-tests` from the Pre-Release pipeline).
   - **Do not allow bypassing the above settings:** This prevents even administrators from merging without passing checks.
   - **Restrict who can dismiss pull request reviews:** Limit this to a small set of maintainers.

**Using gh CLI:**

```bash
# View current branch protection
gh api repos/{owner}/{repo}/branches/main/protection

# Require specific status checks
gh api repos/{owner}/{repo}/branches/main/protection -X PUT \
  -F "required_status_checks[strict]=true" \
  -F "required_status_checks[contexts][]=compile" \
  -F "required_status_checks[contexts][]=lint" \
  -F "required_status_checks[contexts][]=unit-tests" \
  -F "enforce_admins=true" \
  -F "required_pull_request_reviews[required_approving_review_count]=1"
```

**Key setting:** `enforce_admins=true` is what prevents administrators from bypassing checks. Without this, admins and users with the "bypass branch protections" permission can merge regardless of check status.

**With GitHub rulesets (newer alternative):** GitHub repository rulesets offer more granular control than branch protection rules, including the ability to specify bypass actors explicitly. Navigate to **Settings > Rules > Rulesets** to configure.

---

## How do I audit who triggered which workflows?

**(GitHub Platform)**

GitHub provides audit data through multiple channels. CI Excellence does not maintain its own audit log.

**Option 1 -- Workflow run metadata (available to all plans):**

Every workflow run records who triggered it. View this in the Actions tab or via API:

```bash
# List recent workflow runs with actor information
gh run list --limit 20 --json databaseId,name,actor,createdAt,status \
  --jq '.[] | "\(.createdAt) | \(.actor.login) | \(.name) | \(.status)"'

# Get details for a specific run
gh run view <run-id> --json actor,triggeredBy,event
```

**Option 2 -- GitHub Audit Log (Enterprise/Organization plans):**

Organizations on GitHub Enterprise have access to the audit log, which records all `workflow_dispatch` events:

```bash
# Via gh CLI (requires org admin)
gh api /orgs/{org}/audit-log?phrase=action:workflows \
  --jq '.[] | "\(.created_at) | \(.actor) | \(.action) | \(.workflow_id)"'
```

Navigate to **Organization Settings > Audit log** for the web interface.

**Option 3 -- Custom audit logging (CI Excellence extension):**

If you need audit logging beyond what GitHub provides, you could add a step to your workflows that posts to an external system. For example, add this to the `ops-handler` job in `ops.yml`:

```yaml
- name: Audit log
  run: |
    echo "$(date -u +%FT%TZ) | ${{ github.actor }} | ${{ github.event.inputs.action }} | ${{ github.event.inputs.version }}" \
      >> audit.log
    # Or post to an external webhook/database
```

---

## How do I set up CODEOWNERS for different parts of the monorepo?

**(GitHub Platform)**

CODEOWNERS is a GitHub feature that automatically requests reviews from designated owners when a PR touches files they own. CI Excellence does not generate or manage this file.

**Create `.github/CODEOWNERS`:**

```
# Global owners (fallback for everything)
* @your-org/platform-team

# CI/CD pipeline ownership
.github/workflows/          @your-org/devops-team
scripts/ci/                 @your-org/devops-team
.lefthook.toml              @your-org/devops-team
.commitlintrc.yaml          @your-org/devops-team

# Documentation
docs/                       @your-org/docs-team

# Configuration
.config/mise/               @your-org/devops-team
config/                     @your-org/platform-team

# Package-specific owners (monorepo)
packages/frontend/          @your-org/frontend-team
packages/backend/           @your-org/backend-team
packages/shared/            @your-org/platform-team

# Sensitive files require senior review
.github/workflows/release.yml   @your-org/senior-engineers
.github/workflows/ops.yml       @your-org/senior-engineers
```

**Enable CODEOWNERS enforcement:**

In **Settings > Branches > Branch protection rules** for `main`:
- Check **Require review from Code Owners**.

This means PRs that touch files listed in CODEOWNERS cannot be merged until the designated owner approves.

**Important notes:**
- CODEOWNERS uses the last matching pattern, so more specific patterns should come after less specific ones.
- Teams referenced in CODEOWNERS must have **write** access to the repository.
- The file can live at `.github/CODEOWNERS`, `CODEOWNERS` (repo root), or `docs/CODEOWNERS`.

---

## How do I communicate CI changes to the team?

**(Process + CI Excellence notifications)**

CI Excellence does not have a built-in mechanism for announcing CI configuration changes. Here are recommended approaches:

**1. Use conventional commits to make changes visible:**

Since CI Excellence enforces conventional commits via commitlint, CI changes get clear commit messages:

```bash
git commit -m "ci: add path filters to pre-release workflow"
git commit -m "ci!: require ENABLE_E2E_TESTS for all PRs"
```

The `ci:` prefix (and especially `ci!:` for breaking changes) signals to the team that pipeline behavior changed. If you use a changelog generator (currently a stub in `ci-20-generate-changelog.sh`), these commits will appear in the changelog.

**2. Use GitHub Discussions or Issues for planned changes:**

Before making significant CI changes (e.g., adding required checks, changing branch protection), create a GitHub Discussion or Issue to give the team visibility.

**3. Use PR descriptions for CI changes:**

When modifying files in `.github/workflows/` or `scripts/ci/`, the PR description should explain what changed and what the team should expect. If CODEOWNERS is configured (see above), the DevOps team will be automatically requested for review.

**4. Leverage existing notifications:**

If `ENABLE_NOTIFICATIONS=true` and `APPRISE_URLS` is configured, pipeline failures caused by CI changes will immediately surface through your notification channels (Slack, Teams, etc.). This is not a proactive announcement mechanism, but it ensures breakage is noticed quickly.

---

## How do I document custom workflow configurations?

**(Process recommendation)**

CI Excellence stores documentation in `docs/` and workflow-specific information in the workflow YAML comments. There is no auto-generated documentation tool.

**Recommended approach:**

1. **Comment your workflow YAML files.** The existing workflows in `.github/workflows/` use descriptive `name:` fields and `description:` fields on `workflow_dispatch` inputs. Follow this pattern when adding custom jobs or inputs.

2. **Document in `docs/CUSTOMIZATION.md`.** This file already explains how to customize scripts for different technology stacks (Node.js, Python, Go, Rust). Add your project-specific customizations there.

3. **Use the script header convention.** All CI scripts follow a header convention (visible in `scripts/ci/_ci-common.sh`) that documents purpose, usage, environment variables, and exit codes. Maintain this when adding custom scripts.

4. **Document feature flag expectations.** When adding a new `ENABLE_*` variable, document it alongside the existing flags. The complete flag-to-job mapping is documented in `docs/WORKFLOWS.md` under the "Activation Variables" sections for each workflow.

---

## How do I share CI templates across multiple repositories?

**(GitHub Platform + CI Excellence)**

GitHub provides two mechanisms for sharing workflow logic across repositories. CI Excellence is designed as a template/fork-based framework, not a reusable workflow library.

**Option 1 -- Template repository:**

1. Make your CI Excellence repository a GitHub template: **Settings > General > Template repository**.
2. New projects create their repository from this template, inheriting all workflows and scripts.
3. Updates require manually pulling changes from the template (there is no automatic sync).

**Option 2 -- Reusable workflows (GitHub-native):**

Create reusable workflows in a central repository and call them from other repositories:

```yaml
# In the central repo: .github/workflows/reusable-pre-release.yml
on:
  workflow_call:
    inputs:
      enable-lint:
        type: boolean
        default: true
    secrets:
      npm-token:
        required: false

jobs:
  lint:
    if: ${{ inputs.enable-lint }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm run lint
```

```yaml
# In consuming repos:
jobs:
  ci:
    uses: your-org/ci-excellence/.github/workflows/reusable-pre-release.yml@main
    with:
      enable-lint: true
    secrets:
      npm-token: ${{ secrets.NPM_TOKEN }}
```

**Important:** Reusable workflows require the calling repository to have access to the workflow repository (either public, or in the same organization with appropriate visibility settings). Reusable workflows have limitations -- they cannot use `workflow_dispatch` inputs of the caller, and they run in the context of the called workflow's repository for permissions.

**Option 3 -- Composite actions for shared script logic:**

Package common script steps as composite actions in a shared repository. This is more granular than reusable workflows.

**CI Excellence does not currently provide reusable workflows or composite actions.** Its design assumes you fork/template the repository and customize in place. Cross-repo sharing would require refactoring the workflows into `workflow_call` triggers.

---

## How do I standardize CI practices across teams?

**(Process + GitHub Platform)**

**1. Use CI Excellence as the baseline:**

CI Excellence is designed for exactly this purpose. Its variable-driven activation model means every team starts with the same pipeline structure and enables features as needed. The `ENABLE_*` flags provide a common vocabulary across repositories.

**2. Create an organization-level variable set:**

GitHub Organizations can define variables at the organization level. These apply to all repositories (or a subset). Set your baseline `ENABLE_*` flags at the org level so new repositories inherit them:

Navigate to **Organization Settings > Secrets and variables > Actions > Variables** to manage organization-level variables.

**3. Enforce common branch protection via rulesets:**

GitHub Organization rulesets (available on Team and Enterprise plans) let you apply branch protection rules across multiple repositories:

Navigate to **Organization Settings > Rules > Rulesets** and create a ruleset targeting all repositories. Require status checks for `compile`, `lint`, and `unit-tests`.

**4. Use a shared CODEOWNERS pattern:**

Standardize the `.github/CODEOWNERS` file structure across repositories so that CI/workflow changes always require review from the DevOps team.

**5. Pin tool versions via mise:**

CI Excellence uses mise for tool management with versions pinned in `.config/mise/conf.d/` files. Keeping these consistent across repositories ensures teams use the same linter versions, test runners, and security scanners.

---

## How do I handle CI issues during on-call rotations?

**(Process recommendation)**

CI Excellence does not include an on-call management system. Here are recommended patterns:

**1. Route failure notifications to the on-call channel:**

Configure `APPRISE_URLS` (stored as a GitHub Secret) to include your on-call notification channel. For PagerDuty or OpsGenie integration, Apprise supports both:

```bash
# PagerDuty
APPRISE_URLS=pagerduty://integration_key/

# OpsGenie
APPRISE_URLS=opsgenie://api_key/
```

See `docs/NOTIFICATIONS.md` for the full list of supported services.

**2. Use the maintenance workflow for known issues:**

The maintenance workflow (`maintenance.yml`) runs daily at 2 AM UTC and can detect common issues (stale caches, dependency vulnerabilities). If the on-call engineer sees maintenance failures, they can re-run specific actions:

```bash
gh workflow run maintenance.yml -f action=cleanup
gh workflow run maintenance.yml -f action=security-audit
```

**3. Triage workflow failures by type:**

| Failure location | Likely cause | First step |
|---|---|---|
| `setup` job | Tool installation issue | Check `ci-10-install-tools.sh` logs, verify mise config |
| `compile` / `lint` | Code issue, not CI | Notify the PR author |
| `security-scan` | New vulnerability detected | Check Security tab, assess severity |
| `publish-*` jobs | Registry credentials expired | Rotate secrets, re-run |
| `notify` job | Notification URL invalid | Update `APPRISE_URLS` secret |

**4. Document runbooks in your repository:**

Create a `docs/RUNBOOK.md` or similar file with step-by-step instructions for common CI failures. CI Excellence provides `docs/TROUBLESHOOTING.md` as a starting point.

---

## Documentation Gaps

The following areas related to team collaboration are not directly addressed by CI Excellence and would benefit from additional tooling or documentation:

1. **No GitHub Environment configuration in workflows.** The `ops.yml` workflow does not reference GitHub Environments, so the `deploy-production` action has no approval gate. Users must manually add the `environment:` key to enable required reviewers for deployments.

2. **No CODEOWNERS file is shipped.** CI Excellence does not include a default `.github/CODEOWNERS` file or guidance on which directories should be owned by which roles.

3. **No organization-level variable management tooling.** There is no script or documentation for setting up organization-level `ENABLE_*` variables to standardize across repositories.

4. **No reusable workflow support.** The workflows use `workflow_dispatch` and `push`/`pull_request` triggers but not `workflow_call`. Sharing CI logic across repositories requires refactoring.

5. **No CI change announcement mechanism.** There is no built-in way to notify the team about CI configuration changes beyond the standard commit/PR flow.

6. **No audit log integration.** Workflow trigger events are only recorded in GitHub's native audit log (Enterprise only). There is no lightweight audit trail for teams on Free/Pro plans.

7. **No on-call integration documentation.** While Apprise supports PagerDuty and OpsGenie, there is no documented pattern for routing critical CI failures to on-call systems vs. informational notifications to team channels.
