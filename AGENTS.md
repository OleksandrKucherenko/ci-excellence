# Repository Guidelines

CI Excellence is a self‑configuring, testable CI/CD framework (v2) that helps validate and control the release cycle. It ships workflows for pre‑release, release, post‑release, maintenance, and deploy plus numbered Bash stubs; feature toggles exist to simplify testing and customization. The only prerequisite is Mise installed and activated in your shell—on first `cd`, Mise installs tools, sets up folders, and git hooks.

## Project Structure & Module Organization

- `.github/workflows/`: GitHub Actions pipelines for pre‑release, release, post‑release, maintenance, and deploy, plus ops/auto‑fix utilities. Use `ENABLE_*` flags to exercise or skip steps while customizing.
- `scripts/ci/`: numbered Bash stubs executed by workflows, grouped by domain: `build/`, `test/`, `release/`, `maintenance/`, `notification/`, `setup/`, `reports/`. Naming: `ci-{NN}-{purpose}.sh` with spaced steps (10, 20, 30…) to leave room for future inserts.
- `scripts/lib/`: shared Bash helpers sourced by CI scripts.
- `.config/mise/conf.d/` and `mise.toml`: Mise tool/task definitions split by concern (secrets, hooks, validators, commit tools, testing). A temporary `mise.tasks.toml` may appear during refactors; use `mise run <task>` rather than editing it directly.
- `config/`: templates and examples (e.g., `config/.env.secrets.json.example`).
- `docs/`: architecture, customization, workflows, quickstart, migration, troubleshooting. Workflow design diagrams (state/sequence) live in `docs/images/`.
- `environments/`: example environment layouts (`production/`, `staging/`, regions).

## Build, Test, and Development Commands

Key Mise tasks:

- Setup/hooks: `mise run full-env-prepare`, `mise run install-githooks`, `mise run uninstall-hooks`.
- Security/validation: `mise run scan-secrets`, `mise run scan-history`, `mise run check-workflows`, `mise run scan-scripts`, `mise run format-scripts`.
- Tests/local CI: `mise run test`, `mise run test:watch`, `mise run test:coverage`, `mise run test:local-ci` (runs workflows via `act` in dry‑run).
- Secrets: `mise run generate-age-key`, `mise run encrypt-secrets`, `mise run decrypt-secrets`, `mise run edit-secrets`.

## Coding Style & Naming Conventions

- Bash only. Use `#!/usr/bin/env bash`, `set -euo pipefail`, and keep the “stub + examples” pattern.
- Follow numbering blocks in `scripts/ci/README.md` when adding steps; keep paired actions within +5 where relevant.
- Format with `shfmt` and lint with `shellcheck` via Mise tasks.

## Testing Guidelines

ShellSpec is the preferred harness. Add tests as `spec/*_spec.sh` (ShellSpec format) and ensure scripts return non‑zero on failures.

## Commit & Pull Request Guidelines

- Conventional Commits are enforced by lefthook + commitlint. Allowed types include `feat`, `fix`, `ci`, `docs`, `chore`, `wip`, etc.
- Use `mise run cz` (alias `mise run commit`) for interactive commit messages.
- PRs should explain affected workflows/scripts, any new required `ENABLE_*` flags or secrets, and include logs/screenshots for behavior changes.
