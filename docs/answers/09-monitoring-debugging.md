# Monitoring and Debugging

Answers to frequently asked questions about pipeline visibility, troubleshooting failures, and tracking CI/CD metrics within the CI Excellence framework.

## How do I view the status of all running workflows?

GitHub provides several built-in ways to see workflow status, and the `gh` CLI is the fastest from a terminal.

**List all active runs for your repository:**

```bash
# All in-progress runs
gh run list --status in_progress

# All runs (includes completed, queued, etc.)
gh run list --limit 20

# Filter by workflow name
gh run list --workflow pre-release.yml --limit 10
```

**View a specific run in detail:**

```bash
# Watch a run in real time
gh run watch

# View a completed or running run
gh run view <run-id>
```

**In the GitHub UI**, navigate to the **Actions** tab of your repository. You can filter by workflow (Pre-Release Pipeline, Maintenance, Release, etc.), branch, actor, and status.

CI Excellence also writes **Job Summary tables** directly to `GITHUB_STEP_SUMMARY` at the end of each pipeline. These appear on the run's summary page and show every job's status alongside its `ENABLE_*` flag:

- `scripts/ci/reports/ci-10-summary-pre-release.sh` -- table of Setup, Compile, Lint, Unit Tests, Integration Tests, E2E Tests, Security Scan, and Bundle with status and enabled columns.
- `scripts/ci/reports/ci-70-summary-maintenance.sh` -- table of Cleanup, File Sync, Deprecation, Security Audit, and Dependency Update.
- `scripts/ci/reports/ci-90-summary-post-release.sh` -- table of Verify Deployment, Tag Stable, Tag Unstable, and Rollback.
- `scripts/ci/reports/ci-95-summary-release.sh` -- comprehensive table with version info, publish targets (NPM, GitHub, Docker, Docs), and one-click ops commands for promoting, deploying, and marking stable.

## How do I get alerts when workflows fail?

CI Excellence has a **fully implemented notification system** built on [Apprise](https://github.com/caronc/apprise), which supports 90+ services (Slack, Teams, Discord, Telegram, email, PagerDuty, and many more).

**Setup steps:**

1. Set the `ENABLE_NOTIFICATIONS` repository variable to `true` in **Settings > Secrets and variables > Actions > Variables**.
2. Add the `APPRISE_URLS` secret with one or more Apprise-format URLs separated by spaces:

   ```
   slack://token_a/token_b/token_c
   msteams://webhook_url
   discord://webhook_id/webhook_token
   tgram://bot_token/chat_id
   mailto://user:pass@domain.com
   ```

   Alternatively, set `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` secrets, and the framework will automatically convert them to Apprise format.

**How it works:**

- `scripts/ci/notification/ci-10-check-notifications-enabled.sh` auto-detects available credentials and resolves which service to use.
- `scripts/ci/notification/ci-20-determine-status.sh` maps pipeline `RESULT_SUMMARY` into `success`, `failure`, or `warning` with a human-readable message including build number, branch, and commit SHA.
- `scripts/ci/notification/ci-30-send-notification.sh` sends the notification via Apprise with emoji tags, repository info, workflow name, and a direct link to the run logs.

**Test locally:**

```bash
pip install apprise
apprise -b "Test notification" "your-apprise-url"
```

For GitHub-native alerts without Apprise, you can also configure email notifications in your GitHub profile settings under **Notifications > Actions**.

## How do I track workflow execution time trends?

GitHub does not expose a built-in execution time dashboard, but you can extract timing data with the CLI.

**Quick check of recent run durations:**

```bash
# List runs with timing info
gh run list --workflow pre-release.yml --limit 30 --json databaseId,startedAt,updatedAt,conclusion

# View detailed timing for a specific run
gh run view <run-id> --json jobs --jq '.jobs[] | {name, startedAt, completedAt}'
```

**For fine-grained step timing within scripts**, use the e-bash `_commons.sh` timing functions:

```bash
source scripts/lib/_commons.sh
start=$(time:now)
# ... your operation ...
elapsed=$(time:diff "$start")
echo "Operation took ${elapsed}ms"
```

The `time:now` and `time:diff` functions provide microsecond-precision timing and can be used in custom hook scripts to measure individual operations. This is useful for identifying bottlenecks within a CI step (e.g., which part of the build is slow), complementing the job-level timing available from GitHub.

**For trends over time**, export the data and process it:

```bash
gh run list --workflow pre-release.yml --limit 100 --json databaseId,startedAt,updatedAt,conclusion \
  | jq -r '.[] | [.databaseId, .startedAt, .updatedAt, .conclusion] | @csv' \
  > run-timing.csv
```

**External tooling required for real dashboards.** Consider:
- [GitHub Actions Metrics](https://github.com/marketplace?type=actions&query=metrics) actions that post timing data to Datadog, Prometheus, or similar.
- The GitHub REST API endpoint `GET /repos/{owner}/{repo}/actions/runs` for programmatic access.
- Billing usage CSV exports (see the Actions minutes question below).

This is not built into CI Excellence today.

## How do I identify which workflows are consuming the most Actions minutes?

**Organization-level billing:**

```bash
# Org-level Actions usage (requires admin access)
gh api /orgs/{org}/settings/billing/actions
```

**Repository-level approach with the CLI:**

```bash
# List all workflow runs and their durations
gh run list --limit 50 --json workflowName,startedAt,updatedAt,conclusion \
  | jq 'group_by(.workflowName) | map({workflow: .[0].workflowName, count: length})'
```

**In the GitHub UI**, organization owners can view billing breakdowns at **Settings > Billing > Actions**. Per-repository minute breakdowns are available there.

**Tips specific to CI Excellence:**
- Jobs gated behind `ENABLE_*` flags that remain `false` skip immediately and consume near-zero minutes.
- The maintenance workflow (`maintenance.yml`) runs on a schedule -- check if any maintenance tasks you do not need are enabled.
- Bundle and E2E test jobs tend to be the most expensive; disable them on feature branches if not needed by keeping `ENABLE_BUNDLE` and `ENABLE_E2E_TESTS` as `false`.

## How do I debug why a workflow didn't trigger when expected?

Work through this checklist:

1. **Check the workflow's `on:` triggers.** For example, `pre-release.yml` triggers on `pull_request` to `main`/`develop` and `push` to `develop`, `feature/**`, `fix/**`, `claude/**`. If your branch does not match these patterns, the workflow will not run.

   ```bash
   # View the workflow file's triggers
   head -15 .github/workflows/pre-release.yml
   ```

2. **Confirm the workflow file exists on the target branch.** GitHub reads workflow files from the branch that triggered the event. If you added a workflow on a feature branch but are pushing to `main`, and `main` does not have the file yet, it will not trigger.

3. **Check if the workflow is disabled.** Go to **Actions > (workflow name)** and look for a "disabled" banner.

4. **Check for path filters.** Some workflows use `paths:` or `paths-ignore:` filters. If your commit only touches files outside those paths, the workflow will not trigger.

5. **Check repository-level Actions permissions.** Go to **Settings > Actions > General** and confirm actions are allowed to run.

6. **Review audit log:**
   ```bash
   # Check recent events (org-level)
   gh api /orgs/{org}/audit-log --jq '.[] | select(.action | startswith("workflows"))'
   ```

7. **For `workflow_dispatch` triggers**, ensure you are on the correct branch and the workflow is present on that branch.

## How do I view workflow logs for completed runs?

```bash
# List recent completed runs
gh run list --status completed --limit 10

# View a run (shows job-level overview)
gh run view <run-id>

# View full logs for a specific run
gh run view <run-id> --log

# View logs for a failed run's failed jobs only
gh run view <run-id> --log-failed

# Download log archive
gh run download <run-id> --name <artifact-name>
```

**In the GitHub UI**, click any run in the Actions tab, then click a job name to expand step-level logs.

**CI Excellence logger output (powered by e-bash `_logger.sh`):** All CI scripts write structured logs to stderr using colored domain tags (`[build]`, `[test]`, `[security]`, `[notify]`, etc.). The `_logger.sh` module creates domain-specific loggers via `logger:init "tag" "prefix" "redirect"`, which generates `echo:Tag` and `printf:Tag` functions for each domain. The `DEBUG` environment variable controls which domains are active:

- `DEBUG=build,test` -- show only build and test logs
- `DEBUG=*` -- show all domains
- `DEBUG=*,-setup` -- show all except setup

Look for `[SUCCESS]` and `[ERROR]` tags to quickly scan pass/fail outcomes across any pipeline. The `ci:param` and `ci:secret` helpers log every input parameter (with secrets masked) at the start of each script, making it easy to verify what values a script received.

When writing custom scripts or hooks, create your own logger domain:
```bash
source scripts/lib/_logger.sh
logger:init "deploy" "DEPLOY" "stderr"
echo:Deploy "Starting deployment..."  # outputs [deploy] Starting deployment...
```

## What do I do when a workflow is stuck or running too long?

1. **Cancel the run:**
   ```bash
   gh run cancel <run-id>
   ```

2. **Check for hung steps.** In the UI, click into the running job to see which step is active. Common causes:
   - Waiting for an approval gate (environments with required reviewers).
   - An external service call that is timing out.
   - An infinite loop in a script.

3. **Set timeouts to prevent future hangs.** GitHub Actions supports `timeout-minutes` at both the job and step level:
   ```yaml
   jobs:
     build:
       timeout-minutes: 30
       steps:
         - name: Run tests
           timeout-minutes: 15
           run: ./scripts/ci/test/ci-10-unit-tests.sh
   ```

4. **Re-run the failed or stuck job:**
   ```bash
   gh run rerun <run-id> --failed
   ```

5. **Check GitHub Status** at [githubstatus.com](https://www.githubstatus.com) -- runner availability issues can cause jobs to remain queued.

## How do I debug "workflow not found" errors?

This typically means the workflow YAML file is missing, malformed, or on the wrong branch.

1. **Verify the file exists in `.github/workflows/`:**
   ```bash
   ls -la .github/workflows/
   ```

2. **Validate YAML syntax:**
   ```bash
   # Using the mise task (uses action-validator)
   mise run validate-workflows

   # Or directly
   action-validator .github/workflows/*.yml
   ```

3. **Check that the file is committed and pushed.** Untracked or uncommitted workflow files will not be recognized by GitHub.

4. **For `workflow_dispatch` calls**, the workflow name must match exactly:
   ```bash
   # This uses the filename, not the 'name:' field
   gh workflow run ops.yml -f action=promote-release
   ```

5. **Check for YAML parse errors.** Even a single tab character or indentation error can cause GitHub to silently ignore the file.

See also: `docs/TROUBLESHOOTING.md` section on "Workflow Validation Fails" for local validation steps.

## How do I fix "script permission denied" errors?

CI scripts must have the executable bit set in Git.

**Fix it:**

```bash
# Make all CI scripts executable
find scripts -type f -name "*.sh" -exec chmod +x {} \;

# Commit the permission change
git add scripts/
git commit -m "fix: make scripts executable"
git push
```

**Verify permissions:**

```bash
git ls-files -s scripts/ci/ | head -20
# Executable files show mode 100755
# Non-executable files show mode 100644
```

**Prevent recurrence:** When creating new scripts, always `chmod +x` before committing.

This is documented in detail in `docs/TROUBLESHOOTING.md` under "Script Permission Denied".

## How do I resolve cache corruption issues?

GitHub Actions caches (used for `node_modules`, `~/.cache`, etc.) can occasionally become stale or corrupted.

1. **Delete the cache and let it rebuild:**
   ```bash
   # List caches
   gh cache list

   # Delete a specific cache by key
   gh cache delete <cache-key>

   # Delete all caches for the repo
   gh cache list --json key --jq '.[].key' | xargs -I {} gh cache delete {}
   ```

2. **Bust the cache by changing the key.** CI Excellence uses cache keys based on file hashes:
   ```yaml
   key: ${{ runner.os }}-deps-${{ hashFiles('**/package*.json', '**/bun.lock') }}
   ```
   Any change to `package.json` or `bun.lock` will naturally generate a new key. To force a bust, add a version suffix to the key in the workflow file.

3. **Re-run without cache** by cancelling and re-running, or by temporarily commenting out the cache step.

## How do I handle rate limiting from external services?

Rate limiting most commonly affects:
- **GitHub API** (used by `gh` CLI, actions, and GITHUB_TOKEN operations)
- **NPM registry** (during installs and publishes)
- **Docker Hub** (image pulls)

**Diagnose the issue:**

```bash
# Check your GitHub API rate limit
gh api /rate_limit --jq '.resources.core'
```

**Mitigations:**
- **GitHub API:** Use `GITHUB_TOKEN` (5,000 requests/hour) rather than unauthenticated requests (60/hour). For higher limits, use a GitHub App token.
- **NPM:** Use a registry cache or mirror. Add retry logic around `npm install`.
- **Docker Hub:** Authenticate pulls (`docker login`), use GitHub Container Registry (`ghcr.io`) as an alternative, or cache base images.
- **General:** Add exponential backoff/retry in scripts. Cache aggressively to reduce repeated fetches.

## How do I debug network connectivity issues in CI?

GitHub-hosted runners have internet access, but external services may be unreachable.

**In-workflow debugging steps:**

```bash
# Test DNS resolution
nslookup registry.npmjs.org

# Test HTTP connectivity
curl -sI https://registry.npmjs.org

# Check available network interfaces
ip addr show

# Test specific ports
nc -zv registry.npmjs.org 443
```

**Enable verbose runner logging** by setting the `ACTIONS_RUNNER_DEBUG` repository secret to `true`. This produces detailed output for every step including network-related operations.

**Common causes:**
- External service outage (check service status pages).
- Corporate proxy or firewall rules on self-hosted runners.
- DNS resolution failures (transient -- retrying usually helps).

## How do I investigate why a job was skipped?

In CI Excellence, jobs are **expected to skip** when their `ENABLE_*` variable is not set to `true`. This is by design -- the framework uses feature flags to let you progressively enable pipeline stages.

**Check the feature flag:**

1. Go to **Settings > Secrets and variables > Actions > Variables**.
2. Look for the relevant `ENABLE_*` variable (e.g., `ENABLE_UNIT_TESTS`, `ENABLE_LINT`, `ENABLE_COMPILE`).
3. If it is missing or set to `false`, the job will skip.

**Check via CLI:**

```bash
# List repository variables
gh variable list
```

**Check conditional expressions.** Each job in CI Excellence workflows has a condition like:

```yaml
if: env.ENABLE_UNIT_TESTS == 'true'
```

If the condition evaluates to `false`, the job skips. In the run's UI, skipped jobs appear greyed out.

**Check `needs:` dependencies.** If a job depends on another job that failed, it will be skipped unless it has `if: always()`.

**The summary report scripts** (`ci-10-summary-pre-release.sh`, `ci-70-summary-maintenance.sh`, etc.) include the `Enabled` column in their output tables, making it immediately visible which jobs were enabled for a given run.

## How do I track deployment frequency and lead time?

These are DORA metrics. CI Excellence does not include a built-in DORA dashboard, but you can derive the data from GitHub.

**Deployment frequency:**

```bash
# Count releases per time period
gh release list --limit 100 --json publishedAt,tagName \
  | jq 'group_by(.publishedAt[:7]) | map({month: .[0].publishedAt[:7], count: length})'

# Count successful release pipeline runs
gh run list --workflow release.yml --status completed --json conclusion,createdAt --limit 100 \
  | jq '[.[] | select(.conclusion == "success")] | length'
```

**Lead time for changes** (time from commit to production deploy):

```bash
# Compare commit timestamp to release timestamp
gh release view <tag> --json createdAt,targetCommitish
git log -1 --format=%cI <commit-sha>
```

**For proper DORA tracking**, consider tools like:
- [Four Keys](https://github.com/dora-team/fourkeys) (open-source DORA metrics project)
- LinearB, Sleuth, or Faros AI for SaaS dashboards
- Custom GitHub webhook listeners that record deployment events

## How do I measure CI pipeline success rate?

**Quick calculation from the CLI:**

```bash
# Get success/failure counts for a workflow
gh run list --workflow pre-release.yml --limit 100 --json conclusion \
  | jq 'group_by(.conclusion) | map({status: .[0].conclusion, count: length})'
```

**Calculate a success rate:**

```bash
gh run list --workflow pre-release.yml --limit 100 --json conclusion \
  | jq '{
      total: length,
      success: [.[] | select(.conclusion == "success")] | length,
      failure: [.[] | select(.conclusion == "failure")] | length
    } | . + {rate: (.success / .total * 100 | round)}'
```

**Built-in visibility:** The `scripts/ci/build/ci-60-check-failures.sh` script reads all `RESULT_*` environment variables and fails the pipeline if any job reported `failure`. Combined with the summary report scripts that record every job's status in `GITHUB_STEP_SUMMARY`, you get per-run pass/fail breakdowns without external tooling.

## How do I generate weekly/monthly CI usage reports?

GitHub does not provide automated periodic reports out of the box.

**Manual report via CLI:**

```bash
# Runs in the last 7 days
gh run list --limit 200 --json workflowName,conclusion,createdAt \
  | jq --arg since "$(date -d '7 days ago' -Iseconds)" \
    '[.[] | select(.createdAt > $since)] | group_by(.workflowName) | map({
      workflow: .[0].workflowName,
      total: length,
      success: [.[] | select(.conclusion == "success")] | length,
      failure: [.[] | select(.conclusion == "failure")] | length
    })'
```

**Automate with a scheduled workflow:** Create a GitHub Actions workflow that runs on a cron schedule, gathers the data using `gh`, and posts it to Slack/email via Apprise (the notification infrastructure is already in place).

**Billing/minutes usage:**

```bash
# Organization-level billing data
gh api /orgs/{org}/settings/billing/actions
```

## How do I track test flakiness over time?

CI Excellence does not include a built-in flakiness tracker. Test flakiness tracking requires test-framework-level reporting.

**Approaches:**

1. **JUnit XML reports + external analysis.** If your test runner outputs JUnit XML, upload it as an artifact and use a service like Datadog CI Visibility, BuildPulse, or Trunk Flaky Tests to analyze patterns.

2. **Re-run and compare.** GitHub Actions supports re-running failed jobs. If a test fails on first run but passes on re-run, it is likely flaky:
   ```bash
   gh run rerun <run-id> --failed
   ```

3. **Manual tracking.** Search for tests that fail intermittently:
   ```bash
   # List recent failures
   gh run list --workflow pre-release.yml --status failure --limit 20
   # Then inspect logs for the specific test names
   gh run view <run-id> --log-failed | grep -i "FAIL\|ERROR"
   ```

4. **ShellSpec** (used by CI Excellence for its own tests) outputs structured results. Run with `shellspec --format junit` to produce JUnit XML for external analysis.

## How do I measure code coverage trends?

CI Excellence provides the `mise run test:coverage` task (defined in `.config/mise/conf.d/17-testing.toml`) which runs `shellspec --format documentation --coverage`. For your project's own coverage, the approach depends on your language/framework.

**General pattern for GitHub Actions:**

1. Generate a coverage report in your test step (lcov, Cobertura, etc.).
2. Upload it as an artifact.
3. Use a coverage service (Codecov, Coveralls, or SonarCloud) that tracks trends over time.

**Example with Codecov:**

```yaml
- name: Upload coverage
  uses: codecov/codecov-action@v4
  with:
    files: coverage/lcov.info
    token: ${{ secrets.CODECOV_TOKEN }}
```

**Without external services**, you can parse coverage reports in CI and post them to `GITHUB_STEP_SUMMARY`:

```bash
# Example: extract line coverage percentage and append to summary
echo "## Code Coverage: ${COVERAGE_PCT}%" >> "$GITHUB_STEP_SUMMARY"
```

Trend analysis across runs requires an external store (database, S3, or a coverage service).

## How do I export CI metrics to external monitoring systems?

CI Excellence does not include built-in integrations with external monitoring systems, but the architecture makes it straightforward to add.

**Using the notification system:** The Apprise-based notification pipeline (`scripts/ci/notification/`) already supports 90+ services. Some of these (e.g., PagerDuty, Pushover, custom webhooks) can feed into monitoring systems.

**Custom webhook approach:**

```bash
# Post metrics to a custom endpoint at the end of a pipeline
curl -X POST https://your-metrics-endpoint.example.com/ci \
  -H "Content-Type: application/json" \
  -d "{
    \"workflow\": \"$GITHUB_WORKFLOW\",
    \"run_id\": \"$GITHUB_RUN_ID\",
    \"conclusion\": \"success\",
    \"duration_seconds\": $DURATION,
    \"branch\": \"$GITHUB_REF_NAME\"
  }"
```

**GitHub webhooks:** Configure repository webhooks (**Settings > Webhooks**) for `workflow_run` events to push data to Datadog, Grafana, Prometheus Pushgateway, or any HTTP endpoint.

**Structured data sources already available:**
- `GITHUB_STEP_SUMMARY` markdown tables (written by all report scripts)
- `RESULT_*` environment variables (machine-readable job statuses)
- SARIF files from security scans (`security-results.sarif`), uploadable to GitHub Security tab
- Apprise notifications with structured message bodies (build number, branch, commit, run URL)

**Enabling verbose debug logging for deeper metrics:** Set `DEBUG=*` to enable all logger domains, or use `DEBUG=build,test` to enable specific domains. All output goes to stderr with colored domain tags, making it easy to parse programmatically.

## Documentation Gaps

The following monitoring and debugging capabilities are **not currently built into CI Excellence** and would require external tooling or new development:

- **Execution time trend dashboards.** Run duration data is available via `gh run list` and the GitHub API, but there is no built-in visualization or historical tracking.
- **DORA metrics dashboard.** Deployment frequency, lead time, change failure rate, and MTTR can be derived from GitHub data but are not automatically calculated or displayed.
- **Test flakiness tracking.** No built-in mechanism to detect, record, or report flaky tests across runs.
- **Code coverage trend tracking.** The framework supports running coverage (`mise run test:coverage`), but does not store or compare results across runs.
- **CI usage/billing reports.** Organization billing data is accessible via the API, but there are no scheduled reports or summaries.
- **External monitoring integrations.** While the Apprise notification system can reach many services, there are no pre-built integrations for pushing structured metrics to Datadog, Prometheus, Grafana, or similar observability platforms.
- **Alerting on duration regressions.** No mechanism to detect when a workflow's execution time increases significantly compared to historical averages.

What **is** built in and production-ready:
- **Job summary reports** for every pipeline stage (pre-release, maintenance, post-release, release) written to `GITHUB_STEP_SUMMARY`.
- **Failure detection** via `ci-60-check-failures.sh` reading `RESULT_*` variables.
- **Multi-service notifications** via Apprise (90+ services) with auto-detection of credentials.
- **Structured logging** via e-bash `_logger.sh` with domain-tagged, color-coded output to stderr and `DEBUG` variable filtering (`DEBUG=build,test`, `DEBUG=*,-setup`). Custom domains can be created via `logger:init`.
- **Microsecond step timing** via e-bash `_commons.sh` functions `time:now` and `time:diff` for profiling individual operations within scripts.
- **SARIF upload** for security scan findings visible in the GitHub Security tab.
- **Local CI testing** via `mise run test:local-ci` using `act` in dry-run mode.
- **Debug mode** via `ACTIONS_RUNNER_DEBUG=true` secret for verbose GitHub runner output.
