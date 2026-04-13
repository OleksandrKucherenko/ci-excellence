# ADR-007: Multi-Layer Security Architecture

**Date**: 2025-12-07
**Status**: Accepted

## Context and Problem Statement

Secret leaks in CI pipelines are a common and high-impact security failure. A single layer of defense (e.g., only CI-side scanning) misses secrets committed locally before they reach the pipeline. We need defense-in-depth that catches secrets at multiple stages of the development lifecycle while not disrupting developer flow.

## Decision Drivers

- Prevent secrets from entering git history (prevention over detection)
- Multiple independent layers so a bypass in one does not compromise the system
- Developer-friendly (fast local hooks, clear error messages)
- Integration with GitHub Security tab for organizational visibility
- Encrypted local secret storage for development parity with CI

## Considered Options

1. **Three-layer defense** (local hooks + CI scanning + periodic audit)
2. **CI-only scanning** (scan on push, no local enforcement)
3. **Pre-commit only** (local hooks, no CI verification)
4. **External secret management** (vault-based, no local secrets)

## Decision Outcome

**Chosen option**: "Three-layer defense", because each layer catches different failure modes and they operate independently.

**Layer 1 -- Local Prevention (Git Hooks via lefthook)**:
- Pre-commit: Gitleaks and Trufflehog scan staged files
- Pre-push: Workflow validation and policy checks
- Commit-msg: Conventional commit format enforcement
- Blocked commits produce clear error messages with remediation steps

**Layer 2 -- CI Detection (GitHub Actions)**:
- Full repository scan on every push
- SARIF upload to GitHub Security tab
- Auto-fix quality pipeline on development branches

**Layer 3 -- Periodic Audit (Maintenance Pipeline)**:
- Daily cron (2 AM UTC) runs security audit
- Dependency vulnerability scanning
- Results reported via notification system

**Secret Storage**: Local secrets encrypted via SOPS + age (`config/.env.secrets.json`), published to GitHub Secrets for CI use.

## Consequences

### Positive
- Secrets caught before they enter git history (Layer 1), before they reach main (Layer 2), and in ongoing monitoring (Layer 3)
- SARIF integration provides GitHub Security tab visibility for the organization
- SOPS/age encryption allows committing encrypted secrets for development parity
- Each layer is independently testable and disableable via feature flags

### Negative
- Three scanning tools (lefthook + gitleaks + trufflehog) add complexity to the local development setup
- False positives in local hooks can block commits; requires `.gitleaksignore` maintenance
- SOPS/age key distribution adds an onboarding step for new developers

## Related Decisions

- ADR-010: Mise Toolchain Management -- mise installs and configures security tools (lefthook, gitleaks, trufflehog, sops, age)
- ADR-012: Conventional Commits Enforcement -- commit-msg hooks are part of the Layer 1 security gate
- ADR-003: Variable-Driven Feature Activation -- security features use `ENABLE_SECURITY_SCAN` and `ENABLE_SECURITY_AUDIT` flags
