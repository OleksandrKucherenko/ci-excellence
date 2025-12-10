# Atomic Task Plan for Universal CI System

## Phase 0 — Repository Foundation
- [ ] Create `/scripts` folder
- [ ] Create `/ci` or `.github/workflows` folder
- [ ] Add `.mise.toml` and minimal tool config
- [ ] Add `.gitignore` baseline
- [ ] Add SECURITY.md
- [ ] Add VERSION file or placeholder

## Phase 1 — Release Candidate System
- [ ] Implement conventional-commit parser
- [ ] Implement next-version generator
- [ ] Implement RC generator with hash
- [ ] Implement RC tag create/delete scripts
- [ ] Publish RCs (mock/real)
- [ ] Create `pre-release.yml`
- [ ] Add staging deploy + rollback scripts
- [ ] Implement RC cleanup

## Phase 2 — Pre-release System
- [ ] Implement pre-release tag patterns
- [ ] Add tag validation
- [ ] Create pre-release section in `release.yml`
- [ ] Implement stability tag scripts

## Phase 3 — Release System
- [ ] Implement clean SemVer tags
- [ ] Implement next-release calculator
- [ ] Publish to NPM/GH Packages/Docker
- [ ] Create `post-release.yml`
- [ ] Add deployment verification

## Phase 4 — Environment Deployment
- [ ] Implement environment tag patterns
- [ ] Tag movement logic (promotion)
- [ ] Tag deletion logic
- [ ] Environment validation
- [ ] Implement promotion flows
- [ ] Add environment workflows

## Phase 5 — Stability & Rollback
- [ ] Stability tag read/write
- [ ] Previous-stable lookup
- [ ] Rollback workflow

## Phase 6 — Deprecation & Maintenance
- [ ] Deprecation tag logic
- [ ] Add deprecate mode to maintenance
- [ ] Deprecated cleanup
- [ ] Add sync-files, security-audit, dependency-update modes

## Phase 7 — One-Click Actions API
- [ ] Action link builder
- [ ] Rotating secret generator
- [ ] URL dispatch handler
- [ ] Expiration logic
- [ ] PR comment generator
- [ ] Notification formatting

## Phase 8 — Web UI (gh-pages)
- [ ] Create static HTML shell
- [ ] GitHub API fetch wrapper
- [ ] Environments panel
- [ ] Versions panel
- [ ] JSON data generation scripts
- [ ] Create `ui-build.yml`
- [ ] Add GitHub OAuth

## Phase 9 — CLI Tool
- [ ] Pipeline trigger command
- [ ] Step trigger command
- [ ] Execution modes
- [ ] Scenario execution
- [ ] Git simulator
- [ ] ACT integration
- [ ] UI preview

## Phase 10 — Testing Matrix
- [ ] Define YAML scenario format
- [ ] Implement matrix engine
- [ ] Reporting engine

## Phase 11 — Telemetry
- [ ] Step telemetry
- [ ] Aggregate telemetry
- [ ] Telemetry storage + export
- [ ] Telemetry UI integration
