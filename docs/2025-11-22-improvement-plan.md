# CI/CD Pipeline Improvement Plan

**Date**: 2025-11-22
**Status**: Draft
**Author**: CI Excellence Team

## 1. Executive Summary

This document outlines a comprehensive plan to address critical weaknesses identified in the current CI/CD framework. The primary focus is on eliminating race conditions in atomic tag movements, ensuring deterministic builds through strict version pinning, and improving platform compatibility. Additionally, we propose leveraging GitHub's native features (Packages, Gists) and a multi-repo strategy to enhance security and modularity.

## 2. Critical Improvements

### 2.1. Atomic Tag Movement & Locking
**Problem**: The current `create_atomic_tag` implementation uses a custom retry loop which is vulnerable to race conditions in high-concurrency scenarios.
**Solution**:
- **Local Locking**: Replace custom retry logic with `git config core.filesRefLockTimeout 100` (or higher) to let Git handle local lock contention automatically.
- **Remote Atomicity**: Implement `git push --atomic` for all tag updates. This ensures that if multiple tags are being pushed (e.g., `env/staging` and `state/staging-success`), either all succeed or all fail, preventing inconsistent states on the remote.
- **Refactoring**: Rewrite `scripts/deployment/40-ci-atomic-tag-movement.sh` to remove the `while` loop and rely on these native features.

### 2.2. Dependency Management & Determinism
**Problem**: `mise.toml` and setup scripts use "latest" for tool versions, leading to non-deterministic builds and potential breakage from upstream updates.
**Solution**:
- **Pin Versions**: Update `mise.toml` to specify exact versions for all tools (e.g., `gitleaks = "8.18.2"`, `node = "20.11.0"`).
- **Lockfiles**: Ensure `package-lock.json` or `bun.lockb` are committed and respected during install.
- **Renovate/Dependabot**: Configure automated dependency updates to manage these pinned versions systematically.

### 2.3. Platform Compatibility
**Problem**: Scripts use Linux-specific flags for `date` and `stat`, causing failures on macOS.
**Solution**:
- **Standardization**: Create a `lib/platform.sh` library to abstract OS-specific commands.
- **Detection**: Detect OS at runtime and alias commands (e.g., `date` -> `gdate` on macOS if available).
- **Testing**: Add a macOS runner to the CI matrix to catch compatibility issues early.

## 3. Strategic Enhancements

### 3.1. GitHub Native Integration
**Objective**: Reduce reliance on external services and simplify the stack.
- **GitHub Packages**:
    - Migrate Docker image storage from Docker Hub to GitHub Container Registry (GHCR).
    - Publish NPM packages to GitHub Packages for internal dependencies.
    - Update `scripts/release/publish-*.sh` to default to GitHub registries.
- **GitHub Gists**:
    - Use private Gists for storing non-sensitive, transient deployment logs or reports that need to be shared but don't belong in the repo history.
    - Implement a `scripts/ci/reporting/gist-uploader.sh` utility.

### 3.2. Multi-Repo Strategy
**Objective**: Separate concerns and improve security by isolating configuration and secrets.
- **Config Repo**: Create a separate `ci-config` repository to store environment-specific configurations (`environments/`) and encrypted secrets.
- **Submodules/Fetch**: The main pipeline will fetch configuration from `ci-config` at runtime based on the target environment.
- **Benefits**:
    - stricter access control on production configs.
    - cleaner main repository history.
    - ability to version configuration independently of code.

### 3.3. Error Handling & Performance
- **Pipefail Safety**: Refactor complex pipelines in `scripts/lib/deployment.sh` to avoid masking errors. Use intermediate variables.
- **Include Guards**: Add guards to all library scripts to prevent re-sourcing overhead.
    ```bash
    if [[ -n "${LIB_COMMON_LOADED:-}" ]]; then return 0; fi
    readonly LIB_COMMON_LOADED=true
    ```

## 4. Implementation Roadmap

### Phase 1: Stability (Week 1)
- [ ] Refactor `40-ci-atomic-tag-movement.sh` to use `git push --atomic` and `core.filesRefLockTimeout`.
- [ ] Pin all versions in `mise.toml`.
- [ ] Implement `lib/platform.sh` and fix `date`/`stat` usage.

### Phase 2: Security & Structure (Week 2)
- [ ] Extract `environments/` to a new private repository.
- [ ] Update deployment scripts to fetch config from the new repo.
- [ ] Implement include guards in all libraries.

### Phase 3: Integration (Week 3)
- [ ] Update publish scripts to target GHCR and GitHub Packages.
- [ ] Add macOS runner to CI workflow.
- [ ] Refactor pipe usage in deployment scripts.

## 5. Conclusion
Executing this plan will transform the CI/CD framework from a robust prototype into a production-grade, enterprise-ready solution. It addresses the immediate risks of race conditions and instability while laying the groundwork for a secure, scalable multi-repo architecture.