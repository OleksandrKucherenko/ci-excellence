# Frequently Asked Questions

> This document contains common questions organized by workflow stage and use case. For answers, see the detailed documentation.

## Release Management

**Version Control:**
- How do I cut a major release from main?
- How do I cut a minor/feature release from main?
- How do I cut a patch release from main?
- How do I create a canary/pre-release build from main with a prerelease tag?
- How do I run a dry-run release to validate the pipeline without publishing?
- How do I update the version files and changelog without publishing a release?
- How do I regenerate release notes for a given tag?
- How do I release a specific commit hash or branch instead of the latest main?
- How do I create a hotfix release from a previous version?

**Feature Flags and Pipeline Control:**
- How do CI feature flags (ENABLE_*) change which jobs run in each workflow?
- How do I publish release artifacts when compile/build is disabled via feature flags?
- How do I conditionally enable/disable workflows based on file changes (path filters)?
- How do I temporarily disable a workflow without deleting it?
- How do I set different feature flags for different branches?

## Post-Release and Verification

**Deployment Verification:**
- How do I verify that a released version is available on NPM, GitHub Releases, and Docker?
- How do I tag an existing version as stable?
- How do I tag an existing version as unstable/next?
- How do I run the post-release verification step separately from tagging?
- How do I verify a release deployed to multiple registries (NPM + Docker + PyPI)?
- How do I validate that release artifacts match the source code?
- How do I check if a release is accessible from different regions/CDNs?

**Rollback and Recovery:**
- How do I rollback a bad release version across NPM, GitHub Releases, and Docker?
- How do I rollback only NPM/Docker/GitHub while keeping others published?
- How do I restore a deleted release or tag?
- How do I unpublish a specific version from a registry?
- What happens to dependent projects when I rollback a release?

**Documentation and Notifications:**
- How do I publish documentation for a released version?
- How do I re-trigger notifications for a completed pipeline?
- How do I send release notifications to multiple channels (Slack + Teams + Email)?
- How do I customize notification messages for different release types?

## Maintenance and Operations

**Cleanup and Storage:**
- How do I trigger all maintenance tasks in one run?
- How do I clean up old workflow runs, caches, and artifacts?
- How do I delete temporary canary or bug-fix artifacts after testing?
- How do I set retention days for build artifacts, deliverables, and reports?
- How do I clean up workflow runs older than X days across all branches?
- How do I archive important workflow runs before cleanup?
- How do I monitor and alert on high storage usage in GitHub Actions?

**Version Management:**
- How do I sync package.json and CHANGELOG.md with the latest published release?
- How do I deprecate NPM versions older than a specific baseline?
- How do I deprecate GitHub releases for superseded versions?
- How do I bulk update version numbers across multiple package.json files in a monorepo?
- How do I prevent accidental version downgrades?

**Dependency Management:**
- How do I run automated dependency upgrades and open a PR?
- How do I pin specific dependency versions across the monorepo?
- How do I update a dependency in all workspace packages at once?
- How do I test dependency updates in isolation before merging?
- How do I handle conflicting dependency versions in a monorepo?

## Security and Compliance

**Security Incidents:**
- How do I enforce a forced upgrade to a security-fixed dependency version?
- How do I handle and patch a newly discovered security leak in the repository?
- How do I rotate tokens/secrets after a security incident?
- How do I run a full security audit (secret scan and dependency scan) on demand?
- How do I audit who has access to which secrets?
- How do I detect and remove accidentally committed secrets from git history?

**Compliance and Auditing:**
- How do I generate a compliance report for all releases in a time period?
- How do I track which versions are deployed to which environments?
- How do I enforce required approvals before production releases?
- How do I maintain an audit log of all pipeline executions?
- How do I ensure SBOM (Software Bill of Materials) is generated for each release?
- How do I verify license compliance for all dependencies?

## Developer Loop / Day-to-Day

**Local Development:**
- How do I trigger a pre-release pipeline for a feature or fix branch before opening a PR?
- How do I run lint and tests in CI for my feature branch without enabling every job?
- How do I re-run only the test stage on an existing workflow run?
- How do I auto-apply lint/format/security fixes and push them back?
- How can I publish from my local developer environment?
- How can I skip CI jobs for a given change?
- How do I run the same CI steps locally before pushing?
- How do I debug a failing CI job on my local machine?
- How do I override CI behavior for experimental branches?

**Pull Request Workflows:**
- How do I require specific CI checks to pass before PR merge?
- How do I run different CI jobs for PRs vs. main branch pushes?
- How do I automatically run CI when PR is marked as ready for review?
- How do I re-run failed jobs without re-running the entire workflow?
- How do I skip CI for WIP/draft PRs?
- How do I run CI only on changed files/packages?
- How do I get CI status notifications on Slack for my PRs?

**Performance and Optimization:**
- How do I speed up slow CI builds?
- How do I parallelize tests across multiple runners?
- How do I cache dependencies effectively to reduce build times?
- How do I identify and fix bottlenecks in the CI pipeline?
- How do I use matrix builds to test multiple configurations?
- How do I reduce flaky test failures?
- How do I optimize Docker layer caching?

## Monorepo-Specific Questions

**Workspace Management:**
- What should I do if my monorepo sub-project needs custom build steps?
- How do I run CI only for changed packages in a monorepo?
- How do I handle dependencies between packages in the same monorepo?
- How do I version packages independently vs. unified versioning?
- How do I publish only changed packages to NPM?
- How do I run tests for affected packages based on file changes?
- How do I handle shared configuration across monorepo packages?

**Build Orchestration:**
- How do I build packages in the correct dependency order?
- How do I parallelize builds for independent packages?
- How do I cache build outputs per package?
- How do I handle circular dependencies in the build graph?
- How do I build only what's needed for a specific deployment?

**Testing and Quality:**
- How do I run different test suites for different packages?
- How do I aggregate test coverage across all packages?
- How do I enforce code quality standards per package vs. globally?
- How do I run integration tests that span multiple packages?
- How do I handle different test frameworks in different packages?

**Release Coordination:**
- How do I coordinate releases across multiple packages?
- How do I create a release with some packages bumped and others unchanged?
- How do I handle breaking changes in one package affecting others?
- How do I generate changelogs per package vs. monorepo-wide?
- How do I tag releases in a monorepo (single tag vs. per-package tags)?

## Environments and Deployments

**Environment Management:**
- How can I trigger deploys to different environments (staging, production)?
- How can I create new environments for deploy?
- How do I freeze specific versions to prevent deprecation or deletion?
- How do I promote a version from staging to production?
- How do I deploy different packages to different environments?
- How do I handle environment-specific configuration?
- How do I rollback a deployment in a specific environment?

**Deployment Strategies:**
- How do I implement blue-green deployments?
- How do I implement canary deployments with gradual rollout?
- How do I run smoke tests after deployment?
- How do I automatically rollback on failed health checks?
- How do I deploy to multiple regions/availability zones?
- How do I handle database migrations during deployment?

**Pre-release Channels:**
- How do I run pre-releases as alpha, beta, or release-candidate (rc)?
- How do I publish nightly builds automatically?
- How do I create per-PR preview deployments?
- How do I manage multiple pre-release channels (alpha, beta, next)?
- How do I promote a pre-release to stable?

## Platform and Configuration

**Setup and Onboarding:**
- How are CI Excellence workflows and scripts deployed or updated?
- How should CI Excellence be applied on top of an existing project or monorepo?
- How do I migrate from another CI system (Jenkins, CircleCI, Travis)?
- How do I gradually adopt CI Excellence features without disrupting existing workflows?
- How do I train my team on using CI Excellence?

**Credentials and Secrets:**
- How can I update credentials required for CI runs?
- How can I perform scheduled secrets rotation?
- How do I use different secrets for different environments?
- How do I scope secrets to specific workflows or branches?
- How do I share secrets across multiple repositories?
- How do I audit secret usage and access?

**Customization and Extension:**
- How do I add custom scripts to the CI pipeline?
- How do I integrate third-party tools (Snyk, SonarQube, etc.)?
- How do I customize notification formats and channels?
- How do I add custom validation steps before releases?
- How do I extend workflows for company-specific requirements?

## Monitoring and Debugging

**Pipeline Visibility:**
- How do I view the status of all running workflows?
- How do I get alerts when workflows fail?
- How do I track workflow execution time trends?
- How do I identify which workflows are consuming the most Actions minutes?
- How do I debug why a workflow didn't trigger when expected?
- How do I view workflow logs for completed runs?

**Troubleshooting:**
- What do I do when a workflow is stuck or running too long?
- How do I debug "workflow not found" errors?
- How do I fix "script permission denied" errors?
- How do I resolve cache corruption issues?
- How do I handle rate limiting from external services?
- How do I debug network connectivity issues in CI?
- How do I investigate why a job was skipped?

**Metrics and Reporting:**
- How do I track deployment frequency and lead time?
- How do I measure CI pipeline success rate?
- How do I generate weekly/monthly CI usage reports?
- How do I track test flakiness over time?
- How do I measure code coverage trends?
- How do I export CI metrics to external monitoring systems?

## Observability and Performance Analysis

**Pipeline Observability:**
- How do I instrument CI pipelines with distributed tracing (OpenTelemetry)?
- How do I correlate traces across multiple workflow jobs and steps?
- How do I visualize the critical path through my CI pipeline?
- How do I track and alert on CI pipeline SLOs (build time, success rate, deployment frequency)?
- How do I integrate CI metrics with observability platforms (Datadog, New Relic, Honeycomb)?
- How do I create custom dashboards for CI/CD metrics?
- How do I trace a deployment from commit to production?
- How do I implement structured logging across all CI scripts?

**Performance Profiling:**
- How do I profile build performance to identify slow steps?
- How do I measure and optimize test execution time per test file?
- How do I identify memory leaks during CI runs?
- How do I profile Docker build performance layer by layer?
- How do I benchmark CI performance over time to detect regressions?
- How do I use flame graphs to visualize build performance?
- How do I measure network I/O impact on build times?
- How do I profile npm/yarn/pnpm install performance?

**Application Performance Monitoring (APM):**
- How do I integrate APM agents into CI-built artifacts?
- How do I capture performance metrics during integration/E2E tests?
- How do I detect performance regressions before they reach production?
- How do I run load tests as part of CI and track results over time?
- How do I measure application startup time in CI?
- How do I profile memory usage of the application during CI tests?
- How do I track database query performance in integration tests?
- How do I monitor API response times during smoke tests?

**Resource Monitoring:**
- How do I monitor CPU and memory usage of CI runners?
- How do I track disk space usage and prevent out-of-space failures?
- How do I monitor network bandwidth consumption in CI?
- How do I identify resource-intensive jobs that need optimization?
- How do I set resource limits (CPU, memory) for individual jobs?
- How do I monitor and optimize container resource allocation?
- How do I track GitHub Actions runner queue times?

**Real-time Monitoring:**
- How do I set up real-time alerts for CI failures?
- How do I monitor long-running workflows and set timeout alerts?
- How do I create PagerDuty/OpsGenie incidents for critical CI failures?
- How do I stream CI logs to external log aggregation systems (ELK, Splunk)?
- How do I implement health checks for CI infrastructure?
- How do I monitor third-party service dependencies (NPM registry, Docker Hub)?
- How do I track and alert on elevated error rates across all workflows?

**Trace Analysis and Debugging:**
- How do I capture and analyze traces from failed test runs?
- How do I correlate application logs with CI pipeline logs?
- How do I implement request tracing through microservices during E2E tests?
- How do I debug performance issues that only occur in CI (not locally)?
- How do I capture heap dumps or core dumps from CI failures?
- How do I trace dependency resolution performance issues?
- How do I analyze why cache hits are low or ineffective?

**Performance Benchmarking:**
- How do I run performance benchmarks as part of CI?
- How do I compare benchmark results against baseline/previous commits?
- How do I fail CI if performance degrades beyond threshold?
- How do I track bundle size and prevent bloat?
- How do I measure cold start vs. warm start performance?
- How do I benchmark parallel vs. sequential job execution?
- How do I create performance comparison reports across branches?

**Observability Platform Integration:**
- How do I send CI events to Datadog with custom tags?
- How do I create New Relic deployments from CI?
- How do I send traces to Honeycomb from CI workflows?
- How do I integrate with Prometheus/Grafana for CI metrics?
- How do I push metrics to CloudWatch/Azure Monitor/Google Cloud Monitoring?
- How do I use Lightstep for distributed tracing of deployments?
- How do I integrate with Sentry for error tracking in CI?

**Cost and Resource Analytics:**
- How do I track cost per build/deployment?
- How do I analyze which jobs consume the most runner minutes?
- How do I identify opportunities for runner consolidation?
- How do I track cost trends over time?
- How do I allocate CI costs to teams/projects in a monorepo?
- How do I optimize cost by scheduling non-urgent builds during off-peak hours?
- How do I track ROI of CI performance optimizations?

## Team Collaboration

**Access Control:**
- How do I grant/revoke access to trigger workflows?
- How do I require approvals for production deployments?
- How do I restrict who can override CI checks?
- How do I audit who triggered which workflows?
- How do I set up CODEOWNERS for different parts of the monorepo?

**Workflow Management:**
- How do I communicate CI changes to the team?
- How do I document custom workflow configurations?
- How do I share CI templates across multiple repositories?
- How do I standardize CI practices across teams?
- How do I handle CI issues during on-call rotations?

## Advanced Patterns

**Cross-Repository Workflows:**
- How do I trigger workflows in other repositories?
- How do I coordinate releases across multiple repositories?
- How do I share artifacts between repositories?
- How do I implement repository dispatch for cross-repo automation?

**Dynamic Configuration:**
- How do I generate workflow steps dynamically based on repository content?
- How do I use matrix strategies for complex test combinations?
- How do I conditionally include/exclude jobs based on runtime conditions?
- How do I use reusable workflows and composite actions?

**Cost Optimization:**
- How do I reduce GitHub Actions minutes usage?
- How do I identify and eliminate unnecessary workflow runs?
- How do I optimize runner selection (ubuntu vs. macos vs. self-hosted)?
- How do I implement smart caching to reduce costs?
- How do I use concurrency controls to avoid parallel runs?

## Migration and Upgrades

**Version Upgrades:**
- How do I upgrade from CI Excellence vX.x to vY.y?
- How do I test workflow changes before deploying to production?
- How do I rollback a workflow update if it breaks?
- How do I maintain backward compatibility during upgrades?

**Data Migration:**
- How do I migrate existing artifacts to new storage?
- How do I preserve workflow history during migration?
- How do I migrate from GitHub Packages to Docker Hub (or vice versa)?
- How do I migrate secrets from one GitHub organization to another?

---

**For detailed answers and implementation guides, see:**
- [Workflows Documentation](WORKFLOWS.md)
- [Customization Guide](CUSTOMIZATION.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)
- [Architecture Documentation](ARCHITECTURE.md)
