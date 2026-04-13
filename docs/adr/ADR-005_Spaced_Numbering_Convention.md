# ADR-005: Spaced Numbering Convention for Scripts

**Date**: 2025-12-13
**Status**: Accepted

## Context and Problem Statement

CI scripts execute in a defined order within each domain (build, test, release, etc.). We need a naming convention that makes execution order obvious, allows inserting new scripts between existing ones without renaming, and supports paired operations (publish/verify, publish/rollback) that are visually grouped.

## Decision Drivers

- Execution order must be self-evident from file listing (`ls` sorts correctly)
- Must allow insertion without renaming existing scripts
- Paired operations (e.g., publish at 65, verify at 70, rollback at 75) should be visually adjacent
- Convention must scale to 20+ scripts per domain

## Considered Options

1. **Spaced numbering (10, 20, 30...)** with `ci-NN-name.sh` pattern
2. **Sequential numbering (01, 02, 03...)** with renaming on insertion
3. **Alphabetical naming** with no numbers
4. **Priority-based** (e.g., `ci-high-compile.sh`, `ci-low-cleanup.sh`)

## Decision Outcome

**Chosen option**: "Spaced numbering", because intervals of 10 provide 9 insertion slots between any two scripts. The naming pattern `ci-{NN}-{purpose}.sh` sorts correctly in directory listings and makes execution order self-documenting.

Numbering conventions by domain:
- **05-40**: Core operations (version, build, verify, rollback)
- **50-60**: Secondary operations (docs)
- **65-90**: Publishing operations (NPM at 65-75, Docker at 80-90)
- **+5 offsets**: Paired scripts (publish at X5, verify at X0+10, rollback at X5+10)

## Consequences

### Positive
- `ls scripts/ci/release/` immediately reveals execution order
- Inserting `ci-15-type-check.sh` between `ci-10-compile.sh` and `ci-20-lint.sh` requires no renaming
- Paired operations cluster visually (e.g., `ci-65-publish-npm.sh`, `ci-70-verify-npm.sh`, `ci-75-rollback-npm.sh`)

### Negative
- Numbers are meaningful but not self-explanatory; documentation must explain the ranges
- Gap exhaustion is theoretically possible (inserting 10 scripts between adjacent numbers), though unlikely in practice

## Related Decisions

- ADR-004: Three-Folder Script Organization -- numbering applies within the `scripts/ci/` sub-directories
- ADR-001: Stub-Based CI/CD Framework -- "reserve space for growth" is a core design principle
