# Project State Machine

This document illustrates the release lifecycle of the project, strictly following the flow from local development to production deployment and stability management.

## Release State Machine

```mermaid
stateDiagram-v2
    direction LR

    state "1. Development" as DevFlow {
        LocalChanges: Commit
        Commited: Branch
        Pushed: Remote Branch
        PR: Pull Request
        
        [*] --> LocalChanges
        LocalChanges --> Commited: Conventional Commit Message
        Commited --> Pushed: Push
        Pushed --> PR: Open PR
    }

    state "2. Artifact Generation" as GenFlow {
        RC: Release Candidate<br>(Canary)
        Deployable: **DEPLOYABLE**<br>(In Registry)
        
        RC --> Deployable
    }

    state "3. Communication & Lifecycle" as CommFlow {
        PreRelease: GitHub Pre-Release (Announced)
        Release: GitHub Release (Announced)
        Old: Old Version
        LifecycleDeprecated: Deprecated
    }
    
    note right of CommFlow
        Deployable = Registry Artifact (Internal/PR)
        Release = Communicated Availability
    end note

    state "4. Deployment Environments" as EnvFlow {
        Staging: Staging
        Production: Production
    }

    state "5. Stability Status (Sticky Tags)" as TagFlow {
        ReleaseStatus: Release<br>[path/]v{SemVer}
        Staged: Stable<br>[path/]v{SemVer}-stable
        Unstaged: Unstable<br>[path/]v{SemVer}-unstable
        Environment: Deploy Tag<br>[path/]staging
        
        ReleaseStatus --> Environment: deploy to environment
        Environment --> Staged: confirmed
        ReleaseStatus --> Staged: manually assigned
        ReleaseStatus --> Unstaged: manually assigned
        Environment --> Unstaged: rollback
    }
    
    note right of TagFlow
        Stability tags: `[path/]v{Ver}-stable`<br>`[path/]v{Ver}-unstable`
    end note

    note left of TagFlow
        Deploy tags: `[path/]staging`<br>`[path/]production`
    end note

    %% Cross-State Transitions
    Pushed --> ReleaseStatus: manually assigned
    PR --> RC: CI/CD Trigger
    
    Deployable --> PreRelease: Announce (Pre)
    Deployable --> Release: Announce (Stable)
    
    PreRelease --> Release: Promote
    Release --> Old: Superseded
    Old --> LifecycleDeprecated: EOL

    Deployable --> Staging
    Deployable --> Production

    EnvFlow --> Environment
    PreRelease --> ReleaseStatus: assigned -alpha,-beta,-rc
    Release --> ReleaseStatus: assigned
```

## State Descriptions

### 1. Development
- **Local Changes**: Work in progress on a developer's machine.
- **Pushed to Branch**: Changes committed (using specific conventional commit messages) and pushed to the repository.
- **Pull Request**: Code is ready for review and integration.

### 2. Artifact Generation
- **Release Candidate (Canary)**: A temporary build generated from a PR or development branch for testing.
- **Deployable**: An immutable artifact published to the registry (NPM, Docker). This is an internal state; the artifact exists but is not yet publicly announced as a "Release".

### 3. Communication & Lifecycle
- **GitHub Pre-Release**: The artifact is announced as a beta/alpha release on GitHub.
- **GitHub Release**: The artifact is officially released and announced as stable.
- **Old / Deprecated**: As new releases come out, older ones move to "Old" and eventually "Deprecated".

### 4. Deployment Environments
- **Staging**: The deployable is running in the staging environment.
- **Production**: The deployable is live in production.

### 5. Stability Status (Sticky)
- **Release (Neutral)**: The default state of a new release.
- **Staged (Stable)**: Explicitly tagged as stable/verified.
- **Unstaged (Unstable)**: Explicitly tagged as unstable (e.g., after a rollback or critical bug).
- These states form a loop: a release can move between Neutral, Stable, and Unstable as its status changes.
