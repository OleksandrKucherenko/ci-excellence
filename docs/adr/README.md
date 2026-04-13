# Architecture Decision Records

This directory contains Architecture Decision Records (ADRs) for the CI Excellence project.

ADRs capture the **why** behind architectural choices, not the implementation details.

## Index

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [ADR-001](ADR-001_Stub_Based_CI_CD_Framework.md) | Stub-Based CI/CD Framework Architecture | Accepted | 2025-12-13 |
| [ADR-002](ADR-002_E_Bash_Library_Foundation.md) | e-bash Library as Script Foundation | Accepted | 2025-12-10 |
| [ADR-003](ADR-003_Variable_Driven_Feature_Activation.md) | Variable-Driven Feature Activation | Accepted | 2025-12-13 |
| [ADR-004](ADR-004_Three_Folder_Script_Organization.md) | Strict Three-Folder Script Organization | Accepted | 2025-12-13 |
| [ADR-005](ADR-005_Spaced_Numbering_Convention.md) | Spaced Numbering Convention for Scripts | Accepted | 2025-12-13 |
| [ADR-006](ADR-006_Hooks_Based_Extensibility.md) | Hooks-Based Script Extensibility | Accepted | 2025-12-19 |
| [ADR-007](ADR-007_Multi_Layer_Security.md) | Multi-Layer Security Architecture | Accepted | 2025-12-07 |
| [ADR-008](ADR-008_Release_State_Machine.md) | Release State Machine with Stability Tags | Accepted | 2025-12-13 |
| [ADR-009](ADR-009_Hierarchical_Configuration.md) | Hierarchical Configuration Override System | Accepted | 2025-12-13 |
| [ADR-010](ADR-010_Mise_Toolchain_Management.md) | Mise as Local Development Toolchain | Accepted | 2025-12-10 |
| [ADR-011](ADR-011_ShellSpec_Test_Framework.md) | ShellSpec as Shell Script Test Framework | Accepted | 2026-01-15 |
| [ADR-012](ADR-012_Conventional_Commits_Enforcement.md) | Conventional Commits with Automated Enforcement | Accepted | 2025-12-07 |
| [ADR-013](ADR-013_Deployment_Pipeline_CD.md) | Deployment Pipeline as Continuous Delivery Extension | Proposed | 2026-04-13 |

## Format

ADRs follow the [MADR](https://adr.github.io/madr/) format. The foundational decision (ADR-001) uses a full format; subsequent decisions use the minimal MADR format.

## Status Lifecycle

```
Proposed -> Accepted -> [Deprecated | Superseded by ADR-XXX]
```

Accepted ADRs are never edited -- mark as superseded and create a new one.
