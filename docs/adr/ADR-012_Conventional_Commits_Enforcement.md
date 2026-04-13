# ADR-012: Conventional Commits with Automated Enforcement

**Date**: 2025-12-07
**Status**: Accepted

## Context and Problem Statement

Consistent commit messages enable automated changelog generation, semantic version determination, and release note creation. Without enforcement, commit message quality degrades over time, especially in collaborative or AI-assisted development. We need automated validation that prevents non-conforming commits without disrupting developer flow.

## Decision Drivers

- Automated changelog generation from commit history
- Semantic version bumps derived from commit types (feat -> minor, fix -> patch)
- Enforcement at commit time (fast feedback), not at PR review time (slow feedback)
- Support for interactive commit message composition
- Compatibility with AI-assisted development (Claude, Copilot)

## Considered Options

1. **Lefthook + commitlint** (local hook enforcement with linting)
2. **Husky + commitlint** (Node.js-based git hooks)
3. **CI-only validation** (check commit messages in PR pipeline)
4. **No enforcement** (rely on contributor discipline and PR review)

## Decision Outcome

**Chosen option**: "Lefthook + commitlint", because lefthook is a fast, language-agnostic git hook manager (single Go binary, no Node.js runtime needed for the hook itself) and commitlint provides configurable validation rules for the Conventional Commits specification.

Enforcement chain:
1. Developer commits (or uses `mise run cz` for interactive composition via Commitizen)
2. Lefthook `commit-msg` hook triggers commitlint
3. Commitlint validates format: `type(scope): description`
4. Allowed types: `feat`, `fix`, `ci`, `docs`, `chore`, `wip`, `refactor`, `test`, `perf`, `style`, `build`, `revert`
5. Non-conforming commits are rejected with a clear error message

## Consequences

### Positive
- Every commit follows a parseable format, enabling automated changelog and version logic
- Developers get instant feedback (at commit time), not delayed feedback (at PR review)
- Commitizen (`mise run cz`) provides a guided experience for composing valid messages
- Release scripts (`ci-20-generate-changelog.sh`) can reliably parse commit history

### Negative
- `wip:` commits are allowed (by design) but produce noise in changelogs; these should be squashed before merge
- Lefthook installation is a prerequisite (`mise run install-githooks`); developers who skip this step bypass enforcement
- Commitlint configuration must be maintained and kept in sync with team conventions

## Related Decisions

- ADR-007: Multi-Layer Security -- commit-msg hooks are part of the Layer 1 local prevention gate
- ADR-008: Release State Machine -- conventional commits feed the versioning and changelog phases
- ADR-010: Mise Toolchain Management -- lefthook, commitlint, and commitizen are managed via mise
