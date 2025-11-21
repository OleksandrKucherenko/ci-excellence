# User Story 1: Pipeline Reports with Action Links

## Overview

User Story 1 implements comprehensive pipeline completion reports with actionable links for GitHub Actions workflows. This feature provides detailed post-pipeline analysis with contextual action buttons for promotion, rollback, state assignment, and maintenance tasks.

## Features

### 🚀 Pipeline Report Generation

- **Comprehensive Markdown Reports**: Detailed pipeline execution summaries with performance metrics
- **Actionable Links**: One-click GitHub Actions dispatch URLs with pre-filled payloads
- **Context-Aware Actions**: Different action sets based on pipeline type and success/failure status
- **Real-time Status**: Auto-generated status badges and state tag assignments

### 🎯 Action Links by Pipeline Type

#### Pre-Release Pipeline (Success)
- **Promote to Staging**: Deploy version to staging environment
- **Mark as Testing**: Set state tag to testing for quality assurance
- **Security Scan**: Run comprehensive security vulnerability scan

#### Release Pipeline (Success)
- **Promote to Production**: Deploy version to production environment
- **Mark as Stable**: Set state tag to stable for production readiness
- **Rollback Options**: Quick rollback links for production deployments

#### Post-Release Pipeline
- **Cleanup Artifacts**: Remove temporary build artifacts and clean cache
- **Update Dependencies**: Schedule dependency updates and security patches
- **Performance Monitoring**: Generate performance metrics and health checks

#### Maintenance Pipeline
- **Reconcile Security**: Run security audit and vulnerability reconciliation
- **Validate Configuration**: Check configuration consistency and validate secrets
- **Backup Secrets**: Create encrypted backups of sensitive configuration

#### Hotfix Pipeline
- **Mark as Unstable**: Set state tag to unstable for hotfix tracking
- **Security Scan**: Immediate security scan for hotfix validation
- **Regression Test**: Run full regression test suite
- **Rollback Links**: Quick rollback options for production hotfixes

### 🛠️ State Management

#### Automatic State Tag Assignment
- **Testing**: Auto-assigned to successful pre-release pipelines
- **Stable**: Auto-assigned to successful release pipelines
- **Unstable**: Auto-assigned to failed or partial-success pipelines
- **Maintenance**: Manual assignment during maintenance windows
- **Deprecated**: Manual assignment for deprecated versions

#### State Tag Validation
- Enforced state validation (stable, unstable, testing, deprecated, maintenance)
- Integration with MISE profile management
- Git-based state tracking with immutable state tags

## Architecture

### Core Components

#### Report Generator (`scripts/ci/report-generator.sh`)
```bash
# Generate comprehensive pipeline report
./scripts/ci/report-generator.sh PRE_RELEASE SUCCESS 120 v1.2.3 api staging
```

**Key Functions:**
- `generate_report()`: Main report generation with configurable parameters
- `generate_promote_link()`: Create promotion action links with curl commands
- `generate_rollback_link()`: Create rollback action links for failed deployments
- `generate_state_link()`: Create state assignment links
- `generate_maintenance_link()`: Create maintenance task links
- `auto_set_state_tags()`: Automatic state tag assignment based on results

#### Pre-Release Integration (`scripts/ci/build/ci-05-summary-pre-release.sh`)
```bash
# Integrated pre-release summary with action links
./scripts/ci/build/ci-05-summary-pre-release.sh \
  success success success success skipped skipped success success
```

#### Setup Scripts
- **Dependency Installation** (`scripts/setup/10-ci-install-deps.sh`): Multi-language dependency management
- **Environment Validation** (`scripts/setup/20-ci-validate-env.sh`): Comprehensive environment checks

### Testability Framework

#### Behavior Modes
- **EXECUTE**: Normal operation with real actions
- **DRY_RUN**: Simulation mode with logging only
- **PASS**: Simulated success for testing
- **FAIL**: Simulated failure for error handling testing
- **SKIP**: Skip operations entirely
- **TIMEOUT**: Simulate timeout scenarios

#### Environment Variables
```bash
# Global testability
CI_TEST_MODE=DRY_RUN

# Script-specific
CI_REPORT_GENERATOR_BEHAVIOR=PASS
CI_INSTALL_DEPS_BEHAVIOR=EXECUTE
CI_VALIDATE_ENV_BEHAVIOR=FAIL

# Pipeline-level overrides
PIPELINE_SCRIPT_REPORT_GENERATOR_BEHAVIOR=SKIP
```

## Usage Examples

### Basic Report Generation
```bash
# Generate pre-release report
./scripts/ci/report-generator.sh PRE_RELEASE SUCCESS 120 v1.2.3 api staging

# Generate release report with production context
./scripts/ci/report-generator.sh RELEASE SUCCESS 300 v1.3.0 frontend production

# Generate maintenance report
./scripts/ci/report-generator.sh MAINTENANCE SUCCESS 60
```

### Testability Examples
```bash
# Dry run mode - see what would happen
CI_TEST_MODE=DRY_RUN ./scripts/ci/report-generator.sh PRE_RELEASE SUCCESS 120 v1.2.3

# Simulate failure for testing error handling
CI_REPORT_GENERATOR_BEHAVIOR=FAIL ./scripts/ci/report-generator.sh RELEASE SUCCESS 300

# Test timeout scenarios
PIPELINE_SCRIPT_REPORT_GENERATOR_BEHAVIOR=TIMEOUT ./scripts/ci/report-generator.sh
```

### Integration with GitHub Actions
The report generator is integrated into the pre-release workflow:

```yaml
# .github/workflows/pre-release.yml
- name: Generate pipeline summary
  env:
    ENABLE_COMPILE: ${{ vars.ENABLE_COMPILE || 'false' }}
    ENABLE_LINT: ${{ vars.ENABLE_LINT || 'false' }}
    # ... other feature flags
  run: |
    ./scripts/ci/build/ci-05-summary-pre-release.sh \
      "${{ needs.setup.result }}" \
      "${{ needs.compile.result }}" \
      "${{ needs.lint.result }}" \
      "${{ needs.unit-tests.result }}" \
      "${{ needs.integration-tests.result }}" \
      "${{ needs.e2e-tests.result }}" \
      "${{ needs.security-scan.result }}" \
      "${{ needs.bundle.result }}"
```

## Output Example

### Generated Markdown Report
```markdown
# 🚀 Pipeline Completion Report

**Generated**: 2025-11-21T10:30:00Z
**Pipeline Type**: PRE_RELEASE
**Status**: SUCCESS
**Duration**: 120s

## 📊 Execution Summary

| Metric | Value |
|--------|-------|
| Commit | `abc123def456` |
| Version | v1.2.3 |
| Subproject | api |
| Environment | staging |
| Status | ✅ SUCCESS |

## 🎯 Quick Actions

### 🚀 Promote to Release

[**Promote v1.2.3 to staging**](https://github.com/test-org/test-repo/actions/dispatches) on commit `abc123def456`

**Request Body:**
```json
{
  "event_type": "promote-to-release",
  "client_payload": {
    "commit_ish": "abc123def456",
    "environment": "staging",
    "version": "v1.2.3"
  }
}
```

**To execute:**
```bash
curl -X POST \
  -H 'Authorization: Bearer $GH_TOKEN' \
  -H 'Accept: application/vnd.github.eagle-preview+json' \
  -H 'Content-Type: application/json' \
  -d '...' \
  'https://github.com/test-org/test-repo/actions/dispatches'
```

### 🏷️ State Assignment

[**Mark abc123def456 as testing**](https://github.com/test-org/test-repo/actions/dispatches)

### 🔧 Maintenance Task

[**security-scan**](https://github.com/test-org/test-repo/actions/dispatches) on `abc123def456`

## 📈 Performance Metrics

| Metric | Value | Assessment |
|--------|-------|------------|
| Pipeline Duration | 120s | ✅ Excellent |
| Report Generation | < 1s | ✅ Optimal |

## 📋 Next Steps

✅ **Ready for release consideration**
- Review test results and coverage reports
- Create release tag to trigger release pipeline
- Promote to staging environment if needed
```

## Testing

### ShellSpec Tests
Comprehensive test suite covering:
- Report generation functionality
- Action link generation
- State tag management
- Behavior mode handling
- Error conditions and edge cases

```bash
# Run all tests
shellspec

# Run specific test files
shellspec spec/scripts/ci/report-generator_spec.sh
shellspec spec/scripts/setup/10-ci-install-deps_spec.sh
shellspec spec/integration/user-story-1_integration_spec.sh
```

### Integration Testing
The integration tests verify:
- Complete pipeline workflow integration
- Action link generation with correct payloads
- State tag assignment and validation
- Error handling and fallback behaviors

## Configuration

### Required Environment Variables
```bash
# GitHub context
GITHUB_STEP_SUMMARY="/path/to/summary.md"
GITHUB_SERVER_URL="https://github.com"
GITHUB_REPOSITORY="org/repo"
GITHUB_SHA="commit-sha"
GITHUB_REF_NAME="branch-or-tag"
```

### Optional Configuration
```bash
# Webhook integration
WEBHOOK_ENDPOINT="https://hooks.example.com/ci"

# Feature flags
ENABLE_REPORT_ENHANCEMENTS=true
ENABLE_ACTION_LINKS=true
ENABLE_STATE_MANAGEMENT=true
```

## Troubleshooting

### Common Issues

#### Report Generation Fails
```bash
# Check common utilities
./scripts/lib/common.sh --version

# Validate environment
./scripts/setup/20-ci-validate-env.sh all

# Check permissions
ls -la scripts/ci/report-generator.sh
chmod +x scripts/ci/report-generator.sh
```

#### Action Links Not Generated
```bash
# Verify GitHub environment variables
env | grep GITHUB_

# Test in dry run mode
CI_TEST_MODE=DRY_RUN ./scripts/ci/report-generator.sh PRE_RELEASE SUCCESS 120

# Check script behavior mode
PIPELINE_SCRIPT_REPORT_GENERATOR_BEHAVIOR=DRY_RUN ./scripts/ci/report-generator.sh
```

#### State Tag Assignment Fails
```bash
# Test state validation
./scripts/ci/report-generator.sh --test-state stable
./scripts/ci/report-generator.sh --test-state invalid

# Check git repository status
git rev-parse --git-dir

# Verify tag permissions
git tag -l | head -5
```

## Future Enhancements

### Planned Features
- **Slack Integration**: Direct Slack notification links
- **Dashboard Integration**: Links to external monitoring dashboards
- **Advanced Metrics**: Historical performance tracking
- **Custom Action Templates**: Configurable action link templates

### Extension Points
- **Custom Action Generators**: Plugin architecture for custom actions
- **Report Templates**: Customizable report formats and layouts
- **Integration Hooks**: Pre/post report generation hooks
- **Notification Channels**: Multiple notification destination support

## Related Documentation

- [CI Pipeline Architecture](../docs/ci-pipeline-architecture.md)
- [MISE Configuration Guide](../docs/mise-configuration.md)
- [Secret Management with SOPS](../docs/secret-management.md)
- [Testing Framework](../docs/testing-framework.md)