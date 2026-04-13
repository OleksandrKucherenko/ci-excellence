# Frequently Asked Questions

> This document contains common questions organized by workflow stage and use case. Each question links to a detailed answer in the [`docs/answers/`](answers/) directory.

## Release Management

> **Answers:** [01-release-management.md](answers/01-release-management.md)

**Version Control:**
- [How do I cut a major release from main?](answers/01-release-management.md#how-do-i-cut-a-major-release-from-main)
- [How do I cut a minor/feature release from main?](answers/01-release-management.md#how-do-i-cut-a-minorfeature-release-from-main)
- [How do I cut a patch release from main?](answers/01-release-management.md#how-do-i-cut-a-patch-release-from-main)
- [How do I create a canary/pre-release build from main with a prerelease tag?](answers/01-release-management.md#how-do-i-create-a-canarypre-release-build-from-main-with-a-prerelease-tag)
- [How do I run a dry-run release to validate the pipeline without publishing?](answers/01-release-management.md#how-do-i-run-a-dry-run-release-to-validate-the-pipeline-without-publishing)
- [How do I update the version files and changelog without publishing a release?](answers/01-release-management.md#how-do-i-update-the-version-files-and-changelog-without-publishing-a-release)
- [How do I regenerate release notes for a given tag?](answers/01-release-management.md#how-do-i-regenerate-release-notes-for-a-given-tag)
- [How do I release a specific commit hash or branch instead of the latest main?](answers/01-release-management.md#how-do-i-release-a-specific-commit-hash-or-branch-instead-of-the-latest-main)
- [How do I create a hotfix release from a previous version?](answers/01-release-management.md#how-do-i-create-a-hotfix-release-from-a-previous-version)
- [How do I compute which version should be next for release from conventional commits?](answers/01-release-management.md#how-do-i-compute-which-version-should-be-next-for-release-from-conventional-commits)

**Feature Flags and Pipeline Control:**
- [How do CI feature flags (ENABLE_\*) change which jobs run in each workflow?](answers/01-release-management.md#how-do-ci-feature-flags-enable_-change-which-jobs-run-in-each-workflow)
- [How do I get list of all available ENABLE_\* flags/env variables?](answers/01-release-management.md#how-do-i-get-list-of-all-available-enable_-flagsenv-variables)
- [How do I publish release artifacts when compile/build is disabled via feature flags?](answers/01-release-management.md#how-do-i-publish-release-artifacts-when-compilebuild-is-disabled-via-feature-flags)
- [How do I conditionally enable/disable workflows based on file changes (path filters)?](answers/01-release-management.md#how-do-i-conditionally-enabledisable-workflows-based-on-file-changes-path-filters)
- [How do I temporarily disable a workflow without deleting it?](answers/01-release-management.md#how-do-i-temporarily-disable-a-workflow-without-deleting-it)
- [How do I set different feature flags for different branches?](answers/01-release-management.md#how-do-i-set-different-feature-flags-for-different-branches)
- [How can I apply CI environment variable on server side? Like disable Lint step for all workflows?](answers/01-release-management.md#how-can-i-apply-ci-environment-variable-on-server-side-like-disable-lint-step-for-all-workflows)

## Post-Release and Verification

> **Answers:** [02-post-release-verification.md](answers/02-post-release-verification.md)

**Deployment Verification:**
- [How do I verify that a released version is available on NPM, GitHub Releases, and Docker?](answers/02-post-release-verification.md#how-do-i-verify-that-a-released-version-is-available-on-npm-github-releases-and-docker)
- [How do I tag an existing version as stable?](answers/02-post-release-verification.md#how-do-i-tag-an-existing-version-as-stable)
- [How do I tag an existing version as unstable/next?](answers/02-post-release-verification.md#how-do-i-tag-an-existing-version-as-unstablenext)
- [How do I run the post-release verification step separately from tagging?](answers/02-post-release-verification.md#how-do-i-run-the-post-release-verification-step-separately-from-tagging)
- [How do I verify a release deployed to multiple registries (NPM + Docker)?](answers/02-post-release-verification.md#how-do-i-verify-a-release-deployed-to-multiple-registries-npm--docker)
- [How do I validate that release artifacts match the source code? How to compare SHA of release artifacts?](answers/02-post-release-verification.md#how-do-i-validate-that-release-artifacts-match-the-source-code-how-to-compare-sha-of-release-artifacts)

**Rollback and Recovery:**
- [How do I rollback a bad release version across NPM, GitHub Releases, and Docker?](answers/02-post-release-verification.md#how-do-i-rollback-a-bad-release-version-across-npm-github-releases-and-docker)
- [How do I rollback only NPM/Docker/GitHub while keeping others published?](answers/02-post-release-verification.md#how-do-i-rollback-only-npmdockergithub-while-keeping-others-published)
- [How do I restore a deleted release or tag?](answers/02-post-release-verification.md#how-do-i-restore-a-deleted-release-or-tag)
- [How do I unpublish a specific version from a registry?](answers/02-post-release-verification.md#how-do-i-unpublish-a-specific-version-from-a-registry)
- [What happens to dependent projects when I rollback a release?](answers/02-post-release-verification.md#what-happens-to-dependent-projects-when-i-rollback-a-release)

**Documentation and Notifications:**
- [How do I publish documentation for a released version?](answers/02-post-release-verification.md#how-do-i-publish-documentation-for-a-released-version)
- [How do I re-trigger notifications for a completed pipeline?](answers/02-post-release-verification.md#how-do-i-re-trigger-notifications-for-a-completed-pipeline)
- [How do I send release notifications to multiple channels (Slack + Teams + Email)?](answers/02-post-release-verification.md#how-do-i-send-release-notifications-to-multiple-channels-slack--teams--email)
- [How do I customize notification messages for different release types?](answers/02-post-release-verification.md#how-do-i-customize-notification-messages-for-different-release-types)
- [How to produce changes log between two releases (or current state and last known stable release)?](answers/02-post-release-verification.md#how-to-produce-changes-log-between-two-releases-or-current-state-and-last-known-stable-release)

## Maintenance and Operations

> **Answers:** [03-maintenance-operations.md](answers/03-maintenance-operations.md)

**Cleanup and Storage:**
- [How do I trigger all maintenance tasks in one run?](answers/03-maintenance-operations.md#how-do-i-trigger-all-maintenance-tasks-in-one-run)
- [How do I clean up old workflow runs, caches, and artifacts?](answers/03-maintenance-operations.md#how-do-i-clean-up-old-workflow-runs-caches-and-artifacts)
- [How do I delete temporary canary or bug-fix artifacts after testing?](answers/03-maintenance-operations.md#how-do-i-delete-temporary-canary-or-bug-fix-artifacts-after-testing)
- [How do I set retention days for build artifacts, deliverables, and reports?](answers/03-maintenance-operations.md#how-do-i-set-retention-days-for-build-artifacts-deliverables-and-reports)
- [How do I clean up workflow runs older than X days across all branches?](answers/03-maintenance-operations.md#how-do-i-clean-up-workflow-runs-older-than-x-days-across-all-branches)
- [How do I archive important workflow runs before cleanup?](answers/03-maintenance-operations.md#how-do-i-archive-important-workflow-runs-before-cleanup)
- [How do I monitor and alert on high storage usage in GitHub Actions?](answers/03-maintenance-operations.md#how-do-i-monitor-and-alert-on-high-storage-usage-in-github-actions)

**Version Management:**
- [How do I sync package.json and CHANGELOG.md with the latest published release?](answers/03-maintenance-operations.md#how-do-i-sync-packagejson-and-changelogmd-with-the-latest-published-release)
- [How do I deprecate NPM versions older than a specific baseline?](answers/03-maintenance-operations.md#how-do-i-deprecate-npm-versions-older-than-a-specific-baseline)
- [How do I deprecate GitHub releases for superseded versions?](answers/03-maintenance-operations.md#how-do-i-deprecate-github-releases-for-superseded-versions)
- [How do I bulk update version numbers across multiple package.json files in a monorepo?](answers/03-maintenance-operations.md#how-do-i-bulk-update-version-numbers-across-multiple-packagejson-files-in-a-monorepo)
- [How do I prevent accidental version downgrades?](answers/03-maintenance-operations.md#how-do-i-prevent-accidental-version-downgrades)
- [How to avoid versions conflicts between different PRs?](answers/03-maintenance-operations.md#how-to-avoid-versions-conflicts-between-different-prs)

**Dependency Management:**
- [How do I run automated dependency upgrades and open a PR?](answers/03-maintenance-operations.md#how-do-i-run-automated-dependency-upgrades-and-open-a-pr)
- [How do I pin specific dependency versions across the monorepo?](answers/03-maintenance-operations.md#how-do-i-pin-specific-dependency-versions-across-the-monorepo)
- [How do I update a dependency in all workspace packages at once?](answers/03-maintenance-operations.md#how-do-i-update-a-dependency-in-all-workspace-packages-at-once)
- [How do I test dependency updates in isolation before merging?](answers/03-maintenance-operations.md#how-do-i-test-dependency-updates-in-isolation-before-merging)
- [How do I handle conflicting dependency versions in a monorepo?](answers/03-maintenance-operations.md#how-do-i-handle-conflicting-dependency-versions-in-a-monorepo)

## Security and Compliance

> **Answers:** [04-security-compliance.md](answers/04-security-compliance.md)

**Security Incidents:**
- [How do I enforce a forced upgrade to a security-fixed dependency version?](answers/04-security-compliance.md#how-do-i-enforce-a-forced-upgrade-to-a-security-fixed-dependency-version)
- [How do I handle and patch a newly discovered security leak in the repository?](answers/04-security-compliance.md#how-do-i-handle-and-patch-a-newly-discovered-security-leak-in-the-repository)
- [How do I rotate tokens/secrets after a security incident?](answers/04-security-compliance.md#how-do-i-rotate-tokenssecrets-after-a-security-incident)
- [How do I run a full security audit (secret scan and dependency scan) on demand?](answers/04-security-compliance.md#how-do-i-run-a-full-security-audit-secret-scan-and-dependency-scan-on-demand)
- [How do I audit who has access to which secrets?](answers/04-security-compliance.md#how-do-i-audit-who-has-access-to-which-secrets)
- [How do I detect and remove accidentally committed secrets from git history?](answers/04-security-compliance.md#how-do-i-detect-and-remove-accidentally-committed-secrets-from-git-history)

**Compliance and Auditing:**
- [How do I generate a compliance report for all releases in a time period?](answers/04-security-compliance.md#how-do-i-generate-a-compliance-report-for-all-releases-in-a-time-period)
- [How do I track which versions are deployed to which environments?](answers/04-security-compliance.md#how-do-i-track-which-versions-are-deployed-to-which-environments)
- [How do I enforce required approvals before production releases?](answers/04-security-compliance.md#how-do-i-enforce-required-approvals-before-production-releases)
- [How do I maintain an audit log of all pipeline executions?](answers/04-security-compliance.md#how-do-i-maintain-an-audit-log-of-all-pipeline-executions)
- [How do I verify license compliance for all dependencies?](answers/04-security-compliance.md#how-do-i-verify-license-compliance-for-all-dependencies)
- [How do I verify the history of versions deployed to each environment?](answers/04-security-compliance.md#how-do-i-verify-the-history-of-versions-deployed-to-each-environment)

## Developer Loop / Day-to-Day

> **Answers:** [05-developer-loop.md](answers/05-developer-loop.md)

**Local Development:**
- [How do I trigger a pre-release pipeline for a feature or fix branch before opening a PR?](answers/05-developer-loop.md#how-do-i-trigger-a-pre-release-pipeline-for-a-feature-or-fix-branch-before-opening-a-pr)
- [How do I run lint and tests in CI for my feature branch without enabling every job?](answers/05-developer-loop.md#how-do-i-run-lint-and-tests-in-ci-for-my-feature-branch-without-enabling-every-job)
- [How do I re-run only the test stage on an existing workflow run?](answers/05-developer-loop.md#how-do-i-re-run-only-the-test-stage-on-an-existing-workflow-run)
- [How do I auto-apply lint/format/security fixes and push them back?](answers/05-developer-loop.md#how-do-i-auto-apply-lintformatsecurity-fixes-and-push-them-back)
- [How can I publish from my local developer environment?](answers/05-developer-loop.md#how-can-i-publish-from-my-local-developer-environment)
- [How can I skip CI jobs for a given change?](answers/05-developer-loop.md#how-can-i-skip-ci-jobs-for-a-given-change)
- [How do I run the same CI steps locally before pushing?](answers/05-developer-loop.md#how-do-i-run-the-same-ci-steps-locally-before-pushing)
- [How do I debug a failing CI job on my local machine?](answers/05-developer-loop.md#how-do-i-debug-a-failing-ci-job-on-my-local-machine)
- [How do I override CI behavior for experimental branches?](answers/05-developer-loop.md#how-do-i-override-ci-behavior-for-experimental-branches)
- [How do I customize CI steps for a specific monorepo sub-project/workspace?](answers/05-developer-loop.md#how-do-i-customize-ci-steps-for-a-specific-monorepo-sub-projectworkspace)
- [How do I check the CI pipelines changes? enabled feature flags? enabled env variables?](answers/05-developer-loop.md#how-do-i-check-the-ci-pipelines-changes-enabled-feature-flags-enabled-env-variables)

**Pull Request Workflows:**
- [How do I require specific CI checks to pass before PR merge?](answers/05-developer-loop.md#how-do-i-require-specific-ci-checks-to-pass-before-pr-merge)
- [How do I run different CI jobs for PRs vs. main branch pushes?](answers/05-developer-loop.md#how-do-i-run-different-ci-jobs-for-prs-vs-main-branch-pushes)
- [How do I automatically run CI when PR is marked as ready for review?](answers/05-developer-loop.md#how-do-i-automatically-run-ci-when-pr-is-marked-as-ready-for-review)
- [How do I re-run failed jobs without re-running the entire workflow?](answers/05-developer-loop.md#how-do-i-re-run-failed-jobs-without-re-running-the-entire-workflow)
- [How do I skip CI for WIP/draft PRs?](answers/05-developer-loop.md#how-do-i-skip-ci-for-wipdraft-prs)
- [How do I run CI only on changed files/packages?](answers/05-developer-loop.md#how-do-i-run-ci-only-on-changed-filespackages)
- [How do I get CI status notifications on Slack for my PRs?](answers/05-developer-loop.md#how-do-i-get-ci-status-notifications-on-slack-for-my-prs)

**Performance and Optimization:**
- [How do I speed up slow CI builds?](answers/05-developer-loop.md#how-do-i-speed-up-slow-ci-builds)
- [How do I parallelize tests across multiple runners?](answers/05-developer-loop.md#how-do-i-parallelize-tests-across-multiple-runners)
- [How do I cache dependencies effectively to reduce build times?](answers/05-developer-loop.md#how-do-i-cache-dependencies-effectively-to-reduce-build-times)
- [How do I identify and fix bottlenecks in the CI pipeline?](answers/05-developer-loop.md#how-do-i-identify-and-fix-bottlenecks-in-the-ci-pipeline)
- [How do I use matrix builds to test multiple configurations?](answers/05-developer-loop.md#how-do-i-use-matrix-builds-to-test-multiple-configurations)
- [How do I reduce flaky test failures?](answers/05-developer-loop.md#how-do-i-reduce-flaky-test-failures)
- [How do I optimize Docker layer caching?](answers/05-developer-loop.md#how-do-i-optimize-docker-layer-caching)

**Usability and UX:**
- [Where can I find one-click links for quick actions?](answers/05-developer-loop.md#where-can-i-find-one-click-links-for-quick-actions)
- [Where can I find the state machine of the release?](answers/05-developer-loop.md#where-can-i-find-the-state-machine-of-the-release)

## Monorepo-Specific Questions

> **Answers:** [06-monorepo.md](answers/06-monorepo.md)
>
> **Note:** Monorepo is not a first-class feature in CI Excellence. See the [Hard to Implement](answers/06-monorepo.md#hard-to-implement) section for analysis and recommended tooling.

**Workspace Management:**
- [What should I do if my monorepo sub-project needs custom build steps?](answers/06-monorepo.md#what-should-i-do-if-my-monorepo-sub-project-needs-custom-build-steps)
- [How do I run CI only for changed packages in a monorepo?](answers/06-monorepo.md#how-do-i-run-ci-only-for-changed-packages-in-a-monorepo)
- [How do I handle dependencies between packages in the same monorepo?](answers/06-monorepo.md#how-do-i-handle-dependencies-between-packages-in-the-same-monorepo)
- [How do I version packages independently vs. unified versioning?](answers/06-monorepo.md#how-do-i-version-packages-independently-vs-unified-versioning)
- [How do I publish only changed packages to NPM?](answers/06-monorepo.md#how-do-i-publish-only-changed-packages-to-npm)
- [How do I run tests for affected packages based on file changes?](answers/06-monorepo.md#how-do-i-run-tests-for-affected-packages-based-on-file-changes)
- [How do I handle shared configuration across monorepo packages?](answers/06-monorepo.md#how-do-i-handle-shared-configuration-across-monorepo-packages)

**Build Orchestration:**
- [How do I build packages in the correct dependency order?](answers/06-monorepo.md#how-do-i-build-packages-in-the-correct-dependency-order)
- [How do I parallelize builds for independent packages?](answers/06-monorepo.md#how-do-i-parallelize-builds-for-independent-packages)
- [How do I cache build outputs per package?](answers/06-monorepo.md#how-do-i-cache-build-outputs-per-package)
- [How do I handle circular dependencies in the build graph?](answers/06-monorepo.md#how-do-i-handle-circular-dependencies-in-the-build-graph)
- [How do I build only what's needed for a specific deployment?](answers/06-monorepo.md#how-do-i-build-only-whats-needed-for-a-specific-deployment)

**Testing and Quality:**
- [How do I run different test suites for different packages?](answers/06-monorepo.md#how-do-i-run-different-test-suites-for-different-packages)
- [How do I aggregate test coverage across all packages?](answers/06-monorepo.md#how-do-i-aggregate-test-coverage-across-all-packages)
- [How do I enforce code quality standards per package vs. globally?](answers/06-monorepo.md#how-do-i-enforce-code-quality-standards-per-package-vs-globally)
- [How do I run integration tests that span multiple packages?](answers/06-monorepo.md#how-do-i-run-integration-tests-that-span-multiple-packages)
- [How do I handle different test frameworks in different packages?](answers/06-monorepo.md#how-do-i-handle-different-test-frameworks-in-different-packages)

**Release Coordination:**
- [How do I coordinate releases across multiple packages?](answers/06-monorepo.md#how-do-i-coordinate-releases-across-multiple-packages)
- [How do I create a release with some packages bumped and others unchanged?](answers/06-monorepo.md#how-do-i-create-a-release-with-some-packages-bumped-and-others-unchanged)
- [How do I handle breaking changes in one package affecting others?](answers/06-monorepo.md#how-do-i-handle-breaking-changes-in-one-package-affecting-others)
- [How do I generate changelogs per package vs. monorepo-wide?](answers/06-monorepo.md#how-do-i-generate-changelogs-per-package-vs-monorepo-wide)
- [How do I tag releases in a monorepo (single tag vs. per-package tags)?](answers/06-monorepo.md#how-do-i-tag-releases-in-a-monorepo-single-tag-vs-per-package-tags)

## Environments and Deployments

> **Answers:** [07-environments-deployments.md](answers/07-environments-deployments.md)

**Environment Management:**
- [How can I trigger deploys to different environments (staging, production)?](answers/07-environments-deployments.md#how-can-i-trigger-deploys-to-different-environments-staging-production)
- [How can I create new environments for deploy?](answers/07-environments-deployments.md#how-can-i-create-new-environments-for-deploy)
- [How do I freeze specific versions to prevent deprecation or deletion?](answers/07-environments-deployments.md#how-do-i-freeze-specific-versions-to-prevent-deprecation-or-deletion)
- [How do I promote a version from staging to production?](answers/07-environments-deployments.md#how-do-i-promote-a-version-from-staging-to-production)
- [How do I deploy different packages to different environments?](answers/07-environments-deployments.md#how-do-i-deploy-different-packages-to-different-environments)
- [How do I handle environment-specific configuration?](answers/07-environments-deployments.md#how-do-i-handle-environment-specific-configuration)
- [How do I rollback a deployment in a specific environment?](answers/07-environments-deployments.md#how-do-i-rollback-a-deployment-in-a-specific-environment)

**Deployment Strategies:**
- [How do I implement blue-green deployments?](answers/07-environments-deployments.md#how-do-i-implement-blue-green-deployments)
- [How do I implement canary deployments with gradual rollout?](answers/07-environments-deployments.md#how-do-i-implement-canary-deployments-with-gradual-rollout)
- [How do I run smoke tests after deployment?](answers/07-environments-deployments.md#how-do-i-run-smoke-tests-after-deployment)
- [How do I automatically rollback on failed health checks?](answers/07-environments-deployments.md#how-do-i-automatically-rollback-on-failed-health-checks)
- [How do I deploy to multiple regions/availability zones?](answers/07-environments-deployments.md#how-do-i-deploy-to-multiple-regionsavailability-zones)
- [How do I handle database migrations during deployment?](answers/07-environments-deployments.md#how-do-i-handle-database-migrations-during-deployment)

**Pre-release Channels:**
- [How do I run pre-releases as alpha, beta, or release-candidate (rc)?](answers/07-environments-deployments.md#how-do-i-run-pre-releases-as-alpha-beta-or-release-candidate-rc)
- [How do I publish nightly builds automatically?](answers/07-environments-deployments.md#how-do-i-publish-nightly-builds-automatically)
- [How do I create per-PR preview deployments?](answers/07-environments-deployments.md#how-do-i-create-per-pr-preview-deployments)
- [How do I manage multiple pre-release channels (alpha, beta, next)?](answers/07-environments-deployments.md#how-do-i-manage-multiple-pre-release-channels-alpha-beta-next)
- [How do I promote a pre-release to stable?](answers/07-environments-deployments.md#how-do-i-promote-a-pre-release-to-stable)

## Platform and Configuration

> **Answers:** [08-platform-configuration.md](answers/08-platform-configuration.md)

**Setup and Onboarding:**
- [How are CI Excellence workflows and scripts deployed or updated?](answers/08-platform-configuration.md#how-are-ci-excellence-workflows-and-scripts-deployed-or-updated)
- [How should CI Excellence be applied on top of an existing project or monorepo?](answers/08-platform-configuration.md#how-should-ci-excellence-be-applied-on-top-of-an-existing-project-or-monorepo)
- [How do I migrate from another CI system (Jenkins, CircleCI, Travis)?](answers/08-platform-configuration.md#how-do-i-migrate-from-another-ci-system-jenkins-circleci-travis)
- [How do I gradually adopt CI Excellence features without disrupting existing workflows?](answers/08-platform-configuration.md#how-do-i-gradually-adopt-ci-excellence-features-without-disrupting-existing-workflows)
- [How do I train my team on using CI Excellence?](answers/08-platform-configuration.md#how-do-i-train-my-team-on-using-ci-excellence)

**Credentials and Secrets:**
- [How can I update credentials required for CI runs?](answers/08-platform-configuration.md#how-can-i-update-credentials-required-for-ci-runs)
- [How can I perform scheduled secrets rotation?](answers/08-platform-configuration.md#how-can-i-perform-scheduled-secrets-rotation)
- [How do I use different secrets for different environments?](answers/08-platform-configuration.md#how-do-i-use-different-secrets-for-different-environments)
- [How do I scope secrets to specific workflows or branches?](answers/08-platform-configuration.md#how-do-i-scope-secrets-to-specific-workflows-or-branches)
- [How do I share secrets across multiple repositories?](answers/08-platform-configuration.md#how-do-i-share-secrets-across-multiple-repositories)
- [How do I audit secret usage and access?](answers/08-platform-configuration.md#how-do-i-audit-secret-usage-and-access)
- [How do I generate new secrets?](answers/08-platform-configuration.md#how-do-i-generate-new-secrets)

**Customization and Extension:**
- [How do I add custom scripts to the CI pipeline?](answers/08-platform-configuration.md#how-do-i-add-custom-scripts-to-the-ci-pipeline)
- [How do I integrate third-party tools (Snyk, SonarQube, etc.)?](answers/08-platform-configuration.md#how-do-i-integrate-third-party-tools-snyk-sonarqube-etc)
- [How do I customize notification formats and channels?](answers/08-platform-configuration.md#how-do-i-customize-notification-formats-and-channels)
- [How do I add custom validation steps before releases?](answers/08-platform-configuration.md#how-do-i-add-custom-validation-steps-before-releases)
- [How do I extend workflows for company-specific requirements?](answers/08-platform-configuration.md#how-do-i-extend-workflows-for-company-specific-requirements)

## Monitoring and Debugging

> **Answers:** [09-monitoring-debugging.md](answers/09-monitoring-debugging.md)

**Pipeline Visibility:**
- [How do I view the status of all running workflows?](answers/09-monitoring-debugging.md#how-do-i-view-the-status-of-all-running-workflows)
- [How do I get alerts when workflows fail?](answers/09-monitoring-debugging.md#how-do-i-get-alerts-when-workflows-fail)
- [How do I track workflow execution time trends?](answers/09-monitoring-debugging.md#how-do-i-track-workflow-execution-time-trends)
- [How do I identify which workflows are consuming the most Actions minutes?](answers/09-monitoring-debugging.md#how-do-i-identify-which-workflows-are-consuming-the-most-actions-minutes)
- [How do I debug why a workflow didn't trigger when expected?](answers/09-monitoring-debugging.md#how-do-i-debug-why-a-workflow-didnt-trigger-when-expected)
- [How do I view workflow logs for completed runs?](answers/09-monitoring-debugging.md#how-do-i-view-workflow-logs-for-completed-runs)

**Troubleshooting:**
- [What do I do when a workflow is stuck or running too long?](answers/09-monitoring-debugging.md#what-do-i-do-when-a-workflow-is-stuck-or-running-too-long)
- [How do I debug "workflow not found" errors?](answers/09-monitoring-debugging.md#how-do-i-debug-workflow-not-found-errors)
- [How do I fix "script permission denied" errors?](answers/09-monitoring-debugging.md#how-do-i-fix-script-permission-denied-errors)
- [How do I resolve cache corruption issues?](answers/09-monitoring-debugging.md#how-do-i-resolve-cache-corruption-issues)
- [How do I handle rate limiting from external services?](answers/09-monitoring-debugging.md#how-do-i-handle-rate-limiting-from-external-services)
- [How do I debug network connectivity issues in CI?](answers/09-monitoring-debugging.md#how-do-i-debug-network-connectivity-issues-in-ci)
- [How do I investigate why a job was skipped?](answers/09-monitoring-debugging.md#how-do-i-investigate-why-a-job-was-skipped)

**Metrics and Reporting:**
- [How do I track deployment frequency and lead time?](answers/09-monitoring-debugging.md#how-do-i-track-deployment-frequency-and-lead-time)
- [How do I measure CI pipeline success rate?](answers/09-monitoring-debugging.md#how-do-i-measure-ci-pipeline-success-rate)
- [How do I generate weekly/monthly CI usage reports?](answers/09-monitoring-debugging.md#how-do-i-generate-weeklymonthly-ci-usage-reports)
- [How do I track test flakiness over time?](answers/09-monitoring-debugging.md#how-do-i-track-test-flakiness-over-time)
- [How do I measure code coverage trends?](answers/09-monitoring-debugging.md#how-do-i-measure-code-coverage-trends)
- [How do I export CI metrics to external monitoring systems?](answers/09-monitoring-debugging.md#how-do-i-export-ci-metrics-to-external-monitoring-systems)

## Observability and Performance Analysis

> **Answers:** [10-observability-performance.md](answers/10-observability-performance.md)
>
> **Note:** Most observability capabilities require external tools. CI Excellence provides structured logging, notifications, and summaries as building blocks. See the [Hard to Implement](answers/10-observability-performance.md#hard-to-implement) section.

**Pipeline Observability:**
- [How do I instrument CI pipelines with distributed tracing (OpenTelemetry)?](answers/10-observability-performance.md#how-do-i-instrument-ci-pipelines-with-distributed-tracing-opentelemetry)
- [How do I correlate traces across multiple workflow jobs and steps?](answers/10-observability-performance.md#how-do-i-correlate-traces-across-multiple-workflow-jobs-and-steps)
- [How do I visualize the critical path through my CI pipeline?](answers/10-observability-performance.md#how-do-i-visualize-the-critical-path-through-my-ci-pipeline)
- [How do I track and alert on CI pipeline SLOs (build time, success rate, deployment frequency)?](answers/10-observability-performance.md#how-do-i-track-and-alert-on-ci-pipeline-slos-build-time-success-rate-deployment-frequency)
- [How do I integrate CI metrics with observability platforms (Datadog, New Relic, Honeycomb)?](answers/10-observability-performance.md#how-do-i-integrate-ci-metrics-with-observability-platforms-datadog-new-relic-honeycomb)
- [How do I create custom dashboards for CI/CD metrics?](answers/10-observability-performance.md#how-do-i-create-custom-dashboards-for-cicd-metrics)
- [How do I trace a deployment from commit to production?](answers/10-observability-performance.md#how-do-i-trace-a-deployment-from-commit-to-production)
- [How do I implement structured logging across all CI scripts?](answers/10-observability-performance.md#how-do-i-implement-structured-logging-across-all-ci-scripts)

**Performance Profiling:**
- [How do I profile build performance to identify slow steps?](answers/10-observability-performance.md#how-do-i-profile-build-performance-to-identify-slow-steps)
- [How do I measure and optimize test execution time per test file?](answers/10-observability-performance.md#how-do-i-measure-and-optimize-test-execution-time-per-test-file)
- [How do I identify memory leaks during CI runs?](answers/10-observability-performance.md#how-do-i-identify-memory-leaks-during-ci-runs)
- [How do I profile Docker build performance layer by layer?](answers/10-observability-performance.md#how-do-i-profile-docker-build-performance-layer-by-layer)
- [How do I benchmark CI performance over time to detect regressions?](answers/10-observability-performance.md#how-do-i-benchmark-ci-performance-over-time-to-detect-regressions)
- [How do I use flame graphs to visualize build performance?](answers/10-observability-performance.md#how-do-i-use-flame-graphs-to-visualize-build-performance)
- [How do I measure network I/O impact on build times?](answers/10-observability-performance.md#how-do-i-measure-network-io-impact-on-build-times)
- [How do I profile npm/yarn/pnpm install performance?](answers/10-observability-performance.md#how-do-i-profile-npmyarnpnpm-install-performance)

**Application Performance Monitoring (APM):**
- [How do I integrate APM agents into CI-built artifacts?](answers/10-observability-performance.md#how-do-i-integrate-apm-agents-into-ci-built-artifacts)
- [How do I capture performance metrics during integration/E2E tests?](answers/10-observability-performance.md#how-do-i-capture-performance-metrics-during-integratione2e-tests)
- [How do I detect performance regressions before they reach production?](answers/10-observability-performance.md#how-do-i-detect-performance-regressions-before-they-reach-production)
- [How do I run load tests as part of CI and track results over time?](answers/10-observability-performance.md#how-do-i-run-load-tests-as-part-of-ci-and-track-results-over-time)
- [How do I measure application startup time in CI?](answers/10-observability-performance.md#how-do-i-measure-application-startup-time-in-ci)
- [How do I profile memory usage of the application during CI tests?](answers/10-observability-performance.md#how-do-i-profile-memory-usage-of-the-application-during-ci-tests)
- [How do I track database query performance in integration tests?](answers/10-observability-performance.md#how-do-i-track-database-query-performance-in-integration-tests)
- [How do I monitor API response times during smoke tests?](answers/10-observability-performance.md#how-do-i-monitor-api-response-times-during-smoke-tests)

**Resource Monitoring:**
- [How do I monitor CPU and memory usage of CI runners?](answers/10-observability-performance.md#how-do-i-monitor-cpu-and-memory-usage-of-ci-runners)
- [How do I track disk space usage and prevent out-of-space failures?](answers/10-observability-performance.md#how-do-i-track-disk-space-usage-and-prevent-out-of-space-failures)
- [How do I monitor network bandwidth consumption in CI?](answers/10-observability-performance.md#how-do-i-monitor-network-bandwidth-consumption-in-ci)
- [How do I identify resource-intensive jobs that need optimization?](answers/10-observability-performance.md#how-do-i-identify-resource-intensive-jobs-that-need-optimization)
- [How do I set resource limits (CPU, memory) for individual jobs?](answers/10-observability-performance.md#how-do-i-set-resource-limits-cpu-memory-for-individual-jobs)
- [How do I monitor and optimize container resource allocation?](answers/10-observability-performance.md#how-do-i-monitor-and-optimize-container-resource-allocation)
- [How do I track GitHub Actions runner queue times?](answers/10-observability-performance.md#how-do-i-track-github-actions-runner-queue-times)

**Real-time Monitoring:**
- [How do I set up real-time alerts for CI failures?](answers/10-observability-performance.md#how-do-i-set-up-real-time-alerts-for-ci-failures)
- [How do I monitor long-running workflows and set timeout alerts?](answers/10-observability-performance.md#how-do-i-monitor-long-running-workflows-and-set-timeout-alerts)
- [How do I create PagerDuty/OpsGenie incidents for critical CI failures?](answers/10-observability-performance.md#how-do-i-create-pagerdutyopsgenie-incidents-for-critical-ci-failures)
- [How do I stream CI logs to external log aggregation systems (ELK, Splunk)?](answers/10-observability-performance.md#how-do-i-stream-ci-logs-to-external-log-aggregation-systems-elk-splunk)
- [How do I implement health checks for CI infrastructure?](answers/10-observability-performance.md#how-do-i-implement-health-checks-for-ci-infrastructure)
- [How do I monitor third-party service dependencies (NPM registry, Docker Hub)?](answers/10-observability-performance.md#how-do-i-monitor-third-party-service-dependencies-npm-registry-docker-hub)
- [How do I track and alert on elevated error rates across all workflows?](answers/10-observability-performance.md#how-do-i-track-and-alert-on-elevated-error-rates-across-all-workflows)

**Trace Analysis and Debugging:**
- [How do I capture and analyze traces from failed test runs?](answers/10-observability-performance.md#how-do-i-capture-and-analyze-traces-from-failed-test-runs)
- [How do I correlate application logs with CI pipeline logs?](answers/10-observability-performance.md#how-do-i-correlate-application-logs-with-ci-pipeline-logs)
- [How do I implement request tracing through microservices during E2E tests?](answers/10-observability-performance.md#how-do-i-implement-request-tracing-through-microservices-during-e2e-tests)
- [How do I debug performance issues that only occur in CI (not locally)?](answers/10-observability-performance.md#how-do-i-debug-performance-issues-that-only-occur-in-ci-not-locally)
- [How do I capture heap dumps or core dumps from CI failures?](answers/10-observability-performance.md#how-do-i-capture-heap-dumps-or-core-dumps-from-ci-failures)
- [How do I trace dependency resolution performance issues?](answers/10-observability-performance.md#how-do-i-trace-dependency-resolution-performance-issues)
- [How do I analyze why cache hits are low or ineffective?](answers/10-observability-performance.md#how-do-i-analyze-why-cache-hits-are-low-or-ineffective)

**Performance Benchmarking:**
- [How do I run performance benchmarks as part of CI?](answers/10-observability-performance.md#how-do-i-run-performance-benchmarks-as-part-of-ci)
- [How do I compare benchmark results against baseline/previous commits?](answers/10-observability-performance.md#how-do-i-compare-benchmark-results-against-baselineprevious-commits)
- [How do I fail CI if performance degrades beyond threshold?](answers/10-observability-performance.md#how-do-i-fail-ci-if-performance-degrades-beyond-threshold)
- [How do I track bundle size and prevent bloat?](answers/10-observability-performance.md#how-do-i-track-bundle-size-and-prevent-bloat)
- [How do I measure cold start vs. warm start performance?](answers/10-observability-performance.md#how-do-i-measure-cold-start-vs-warm-start-performance)
- [How do I benchmark parallel vs. sequential job execution?](answers/10-observability-performance.md#how-do-i-benchmark-parallel-vs-sequential-job-execution)
- [How do I create performance comparison reports across branches?](answers/10-observability-performance.md#how-do-i-create-performance-comparison-reports-across-branches)

**Observability Platform Integration:**
- [How do I send CI events to Datadog with custom tags?](answers/10-observability-performance.md#how-do-i-send-ci-events-to-datadog-with-custom-tags)
- [How do I create New Relic deployments from CI?](answers/10-observability-performance.md#how-do-i-create-new-relic-deployments-from-ci)
- [How do I send traces to Honeycomb from CI workflows?](answers/10-observability-performance.md#how-do-i-send-traces-to-honeycomb-from-ci-workflows)
- [How do I integrate with Prometheus/Grafana for CI metrics?](answers/10-observability-performance.md#how-do-i-integrate-with-prometheusgrafana-for-ci-metrics)
- [How do I push metrics to CloudWatch/Azure Monitor/Google Cloud Monitoring?](answers/10-observability-performance.md#how-do-i-push-metrics-to-cloudwatchazure-monitorgoogle-cloud-monitoring)
- [How do I use Lightstep for distributed tracing of deployments?](answers/10-observability-performance.md#how-do-i-use-lightstep-for-distributed-tracing-of-deployments)
- [How do I integrate with Sentry for error tracking in CI?](answers/10-observability-performance.md#how-do-i-integrate-with-sentry-for-error-tracking-in-ci)

**Cost and Resource Analytics:**
- [How do I track cost per build/deployment?](answers/10-observability-performance.md#how-do-i-track-cost-per-builddeployment)
- [How do I analyze which jobs consume the most runner minutes?](answers/10-observability-performance.md#how-do-i-analyze-which-jobs-consume-the-most-runner-minutes)
- [How do I identify opportunities for runner consolidation?](answers/10-observability-performance.md#how-do-i-identify-opportunities-for-runner-consolidation)
- [How do I track cost trends over time?](answers/10-observability-performance.md#how-do-i-track-cost-trends-over-time)
- [How do I allocate CI costs to teams/projects in a monorepo?](answers/10-observability-performance.md#how-do-i-allocate-ci-costs-to-teamprojects-in-a-monorepo)
- [How do I optimize cost by scheduling non-urgent builds during off-peak hours?](answers/10-observability-performance.md#how-do-i-optimize-cost-by-scheduling-non-urgent-builds-during-off-peak-hours)
- [How do I track ROI of CI performance optimizations?](answers/10-observability-performance.md#how-do-i-track-roi-of-ci-performance-optimizations)

## Team Collaboration

> **Answers:** [11-team-collaboration.md](answers/11-team-collaboration.md)

**Access Control:**
- [How do I grant/revoke access to trigger workflows?](answers/11-team-collaboration.md#how-do-i-grantrevoke-access-to-trigger-workflows)
- [How do I require approvals for production deployments?](answers/11-team-collaboration.md#how-do-i-require-approvals-for-production-deployments)
- [How do I restrict who can override CI checks?](answers/11-team-collaboration.md#how-do-i-restrict-who-can-override-ci-checks)
- [How do I audit who triggered which workflows?](answers/11-team-collaboration.md#how-do-i-audit-who-triggered-which-workflows)
- [How do I set up CODEOWNERS for different parts of the monorepo?](answers/11-team-collaboration.md#how-do-i-set-up-codeowners-for-different-parts-of-the-monorepo)

**Workflow Management:**
- [How do I communicate CI changes to the team?](answers/11-team-collaboration.md#how-do-i-communicate-ci-changes-to-the-team)
- [How do I document custom workflow configurations?](answers/11-team-collaboration.md#how-do-i-document-custom-workflow-configurations)
- [How do I share CI templates across multiple repositories?](answers/11-team-collaboration.md#how-do-i-share-ci-templates-across-multiple-repositories)
- [How do I standardize CI practices across teams?](answers/11-team-collaboration.md#how-do-i-standardize-ci-practices-across-teams)
- [How do I handle CI issues during on-call rotations?](answers/11-team-collaboration.md#how-do-i-handle-ci-issues-during-on-call-rotations)

## Advanced Patterns

> **Answers:** [12-advanced-patterns.md](answers/12-advanced-patterns.md)

**Cross-Repository Workflows:**
- [How do I trigger workflows in other repositories?](answers/12-advanced-patterns.md#how-do-i-trigger-workflows-in-other-repositories)
- [How do I coordinate releases across multiple repositories?](answers/12-advanced-patterns.md#how-do-i-coordinate-releases-across-multiple-repositories)
- [How do I share artifacts between repositories?](answers/12-advanced-patterns.md#how-do-i-share-artifacts-between-repositories)
- [How do I implement repository dispatch for cross-repo automation?](answers/12-advanced-patterns.md#how-do-i-implement-repository-dispatch-for-cross-repo-automation)

**Dynamic Configuration:**
- [How do I generate workflow steps dynamically based on repository content?](answers/12-advanced-patterns.md#how-do-i-generate-workflow-steps-dynamically-based-on-repository-content)
- [How do I use matrix strategies for complex test combinations?](answers/12-advanced-patterns.md#how-do-i-use-matrix-strategies-for-complex-test-combinations)
- [How do I conditionally include/exclude jobs based on runtime conditions?](answers/12-advanced-patterns.md#how-do-i-conditionally-includeexclude-jobs-based-on-runtime-conditions)
- [How do I use reusable workflows and composite actions?](answers/12-advanced-patterns.md#how-do-i-use-reusable-workflows-and-composite-actions)

**Cost Optimization:**
- [How do I reduce GitHub Actions minutes usage?](answers/12-advanced-patterns.md#how-do-i-reduce-github-actions-minutes-usage)
- [How do I identify and eliminate unnecessary workflow runs?](answers/12-advanced-patterns.md#how-do-i-identify-and-eliminate-unnecessary-workflow-runs)
- [How do I optimize runner selection (ubuntu vs. macos vs. self-hosted)?](answers/12-advanced-patterns.md#how-do-i-optimize-runner-selection-ubuntu-vs-macos-vs-self-hosted)
- [How do I implement smart caching to reduce costs?](answers/12-advanced-patterns.md#how-do-i-implement-smart-caching-to-reduce-costs)
- [How do I use concurrency controls to avoid parallel runs?](answers/12-advanced-patterns.md#how-do-i-use-concurrency-controls-to-avoid-parallel-runs)

## Migration and Upgrades

> **Answers:** [13-migration-upgrades.md](answers/13-migration-upgrades.md)

**Version Upgrades:**
- [How do I upgrade from CI Excellence vX.x to vY.y?](answers/13-migration-upgrades.md#how-do-i-upgrade-from-ci-excellence-vxx-to-vyy)
- [How do I test workflow changes before deploying to production?](answers/13-migration-upgrades.md#how-do-i-test-workflow-changes-before-deploying-to-production)
- [How do I rollback a workflow update if it breaks?](answers/13-migration-upgrades.md#how-do-i-rollback-a-workflow-update-if-it-breaks)
- [How do I maintain backward compatibility during upgrades?](answers/13-migration-upgrades.md#how-do-i-maintain-backward-compatibility-during-upgrades)

**Data Migration:**
- [How do I migrate existing artifacts to new storage?](answers/13-migration-upgrades.md#how-do-i-migrate-existing-artifacts-to-new-storage)
- [How do I preserve workflow history during migration?](answers/13-migration-upgrades.md#how-do-i-preserve-workflow-history-during-migration)
- [How do I migrate from GitHub Packages to Docker Hub (or vice versa)?](answers/13-migration-upgrades.md#how-do-i-migrate-from-github-packages-to-docker-hub-or-vice-versa)
- [How do I migrate secrets from one GitHub organization to another?](answers/13-migration-upgrades.md#how-do-i-migrate-secrets-from-one-github-organization-to-another)

---

**For detailed implementation guides, see:**
- [Architecture Documentation](ARCHITECTURE.md)
- [Workflows Documentation](WORKFLOWS.md)
- [Customization Guide](CUSTOMIZATION.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)
- [Notifications Setup](NOTIFICATIONS.md)
- [Mise Setup](MISE-SETUP.md)
- [Git Hooks](GIT-HOOKS.md)
- [Installation](INSTALLATION.md)
- [Migration Guide](MIGRATION.md)
