# CI Excellence Framework - Developer Guide

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Development Workflow](#development-workflow)
- [Script Development](#script-development)
- [Testing Strategy](#testing-strategy)
- [Configuration Management](#configuration-management)
- [Security Best Practices](#security-best-practices)
- [Deployment Process](#deployment-process)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

The CI Excellence Framework is designed with developer productivity and operational excellence in mind. This guide will help you understand the architecture, development workflow, and best practices for contributing to and extending the framework.

## 🏗️ Architecture

### System Components

```
ci-excellence/
├── scripts/                    # Core CI/CD scripts
│   ├── build/               # Build and compilation
│   ├── ci/                  # CI pipeline orchestration
│   ├── deployment/          # Deployment automation
│   ├── maintenance/         # Maintenance operations
│   └── security/            # Security scanning
├── environments/               # Environment configurations
│   ├── staging/            # Staging environment
│   ├── production/         # Production environment
│   └── global/             # Shared configuration
├── lib/                       # Shared libraries
├── tests/                     # Test suites
├── docs/                      # Documentation
└── templates/                  # Code templates
```

### Key Principles

1. **Modularity**: Each script has a single responsibility
2. **Testability**: All scripts support dry-run and test modes
3. **DRY Principle**: Common functionality is abstracted to libraries
4. **Security-First**: Built-in security scanning and validation
5. **Observability**: Comprehensive logging and reporting

### Data Flow

```
Code Change → Git Hooks → CI Pipeline → Scripts → Deployment
     ↓              ↓            ↓          ↓
  Validation → Pre-commit → Build → Test → Deploy → Monitor
```

## 🔧 Development Workflow

### 1. Setup Development Environment

```bash
# Clone and setup
git clone <repository>
cd ci-excellence
mise run dev-setup

# Set up shell integration
./scripts/shell/setup-shell-integration.sh zsh --prompt
source ~/.zshrc
```

### 2. Development Process

```bash
# Create feature branch
git checkout -b feature/your-feature

# Work on changes
# Make your modifications...

# Run pre-commit checks (automatic)
git add .
git commit -m "feat: implement your feature"

# Run local CI
mise run test:local-ci
```

### 3. Testing Before Pushing

```bash
# Run all tests
mise run test

# Run with coverage
mise run test:coverage

# Run security scan
mise run scan-secrets
mise run scan-history

# Validate workflows
mise run validate-workflows
```

### 4. Code Review and Merge

```bash
# Push changes
git push origin feature/your-feature

# Create pull request
# Wait for CI pipeline to pass
# Address any feedback
# Merge to main branch
```

## 📝 Script Development

### Script Structure

Every script should follow this structure:

```bash
#!/bin/bash
# Script Header - Version, Purpose, Usage, Testability

set -euo pipefail

# Configuration
SCRIPT_NAME="$(basename "$0" .sh)"
SCRIPT_VERSION="1.0.0"
SCRIPT_MODE="${SCRIPT_MODE:-${CI_TEST_MODE:-default}}"

# Source libraries
source "${SCRIPT_DIR}/../lib/config.sh"
source "${SCRIPT_DIR}/../lib/logging.sh"

# Main function
main() {
    # Script logic here
}

# Run main function
main "$@"
```

### Template Usage

```bash
# Create new script from template
cp templates/ci-script-template.sh scripts/your-new-script.sh
chmod +x scripts/your-new-script.sh

# Customize the template
vim scripts/your-new-script.sh

# Create corresponding test
touch spec/scripts/your-new-script_spec.sh
```

### Best Practices

1. **Keep Scripts Small**: Under 50 lines of code
2. **Use Libraries**: Don't reinvent functionality
3. **Handle Errors**: Proper error handling and logging
4. **Testability**: Support dry-run and test modes
5. **Documentation**: Comprehensive headers and comments

### Library Functions

Available libraries in `scripts/lib/`:

- **config.sh**: Configuration and deployment management
- **logging.sh**: Centralized logging with multiple levels
- **validation.sh**: Input validation and security checks
- **deployment.sh**: Deployment orchestration utilities
- **security.sh**: Security scanning and alerting
- **git.sh**: Git utilities and tag management
- **environment.sh**: Environment-specific operations

## 🧪 Testing Strategy

### Test Organization

```
tests/
├── unit/                 # Unit tests for individual functions
├── integration/          # Integration tests for workflows
├── e2e/                 # End-to-end tests
└── fixtures/            # Test data and fixtures
```

### Testing Framework

Uses ShellSpec for bash script testing:

```bash
# Install ShellSpec
mise install shellspec

# Run all tests
mise run test

# Run with coverage
mise run test:coverage

# Run specific test file
shellspec spec/scripts/your-script_spec.sh
```

### Test Structure

```bash
# spec/scripts/your-script_spec.sh
Describe "Your Script"
  It "should validate inputs"
    When call source "./scripts/your-script.sh"
    The function "validate_inputs" should be defined
  End

  It "should handle dry run mode"
    DRY_RUN=true
    When call main_function
    The output should contain "[DRY RUN]"
  End

  It "should handle errors gracefully"
    When call main_function "invalid-input"
    The exit status should be 1
  End
End
```

### Test Categories

1. **Unit Tests**: Test individual functions in isolation
2. **Integration Tests**: Test script interactions
3. **E2E Tests**: Test complete workflows
4. **Security Tests**: Test security features
5. **Performance Tests**: Test performance characteristics

### Writing Tests

1. **Test Success Cases**: Verify correct behavior
2. **Test Error Cases**: Verify error handling
3. **Test Edge Cases**: Test boundary conditions
4. **Test Mocks**: Use test doubles for external dependencies

## ⚙️ Configuration Management

### Environment Hierarchy

```
environments/
├── global/             # Global defaults
│   └── config.yml
├── staging/            # Staging-specific
│   ├── config.yml
│   └── regions/
│       └── us-east/config.yml
├── production/         # Production-specific
│   ├── config.yml
│   └── regions/
│       └── us-east/config.yml
└── development/         # Development-specific
    └── config.yml
```

### Configuration Loading

```bash
# Automatic configuration loading
load_environment_config "$environment" "$region"

# Hierarchical loading order
# 1. Global configuration
# 2. Environment configuration
# 3. Region-specific configuration
```

### Secret Management

Using SOPS + age for encrypted secrets:

```bash
# Generate encryption key
mise run generate-age-key

# Edit secrets
mise run edit-secrets

# Decrypt when needed
mise run decrypt-staging
mise run decrypt-production
```

## 🔒 Security Best Practices

### Input Validation

```bash
# Always validate inputs
validate_input "$input" "filename"

# Use libraries for validation
validate_environment_variables "API_KEY" "DATABASE_URL"
```

### Secret Handling

```bash
# Never log secrets
process_secret "$secret"  # Good
process_secret "$SECRET"   # Bad
```

### Permission Management

```bash
# Check file permissions
if [[ ! -r "$config_file" ]]; then
    log_error "Cannot read configuration file"
    return 1
fi
```

### Security Scanning

```bash
# Run security scan
./scripts/build/30-ci-security-scan.sh production high all

# Custom security checks
validate_security_requirements "production"
```

## 🚀 Deployment Process

### Deployment Types

1. **Development**: Automatic, no approval required
2. **Staging**: Automatic with validation
3. **Production**: Manual approval required

### Deployment Pipeline

```bash
# Validate prerequisites
validate_deployment_prerequisites

# Run security scan
run_security_scan "production" "high" "all"

# Run tests
run_comprehensive_tests

# Execute deployment
execute_deployment "$environment" "$region"

# Health checks
run_deployment_health_checks "$environment" "$region"

# Update tags
update_deployment_tags "$environment" "$region"
```

### Rollback Procedures

1. **Automatic Rollback**: Health check failures
2. **Manual Rollback**: Via GitHub Actions or CLI
3. **Emergency Rollback**: Critical issues only

```bash
# Manual rollback
./scripts/deployment/30-ci-rollback.sh production deploy-123 previous_tag

# Via GitHub Actions
# Use "Rollback Deployment" workflow
```

## 🔍 Troubleshooting

### Common Issues

#### Permission Errors
```bash
# Fix script permissions
chmod +x scripts/**/*.sh

# Check git hook permissions
mise run install-hooks
```

#### Missing Dependencies
```bash
# Verify tools are installed
mise run verify-tools

# Reinstall if needed
mise run dev-setup
```

#### Configuration Issues
```bash
# Validate configuration
mise run validate-config

# Check environment setup
mise profile status
```

#### Security Issues
```bash
# Check for secrets
mise run scan-secrets

# Validate encryption
mise run validate-secrets
```

### Debug Mode

Enable comprehensive debugging:

```bash
export LOG_LEVEL=debug
export CI_TEST_MODE=dry_run
export SHELL_DEBUG=true

# Run with debug output
./scripts/your-script.sh --debug
```

### Getting Help

```bash
# Script-specific help
./scripts/your-script.sh --help

# Framework help
mise run --help

# Documentation
cat docs/script-development.md
```

## 📚 Additional Resources

- [Script Development Guide](script-development.md)
- [Security Guidelines](security.md)
- [Migration Guide](migration.md)
- [API Reference](api/)

## 🤝 Contributing

### Contributing Process

1. **Fork** the repository
2. **Create** feature branch
3. **Develop** following guidelines
4. **Test** thoroughly
5. **Submit** pull request
6. **Review** and merge

### Code Review Criteria

- ✅ Follows code style guidelines
- ✅ Has comprehensive tests
- ✅ Includes documentation
- ✅ Passes security validation
- ✅ Uses appropriate libraries

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type
- [ ] Bug fix
- [ ] Feature
- [ ] Documentation
- [ ] Refactoring

## Testing
- [ ] Unit tests added
- [ ] Integration tests pass
- [ ] Manual testing performed

## Security
- [ ] No secrets committed
- [ ] Security scan passed
- [ ] Dependencies updated
```

## 📈 Performance Optimization

### Script Performance

- Keep scripts under 50 lines
- Use efficient shell commands
- Avoid unnecessary subshells
- Use libraries for common operations

### Pipeline Performance

- Parallelize independent tasks
- Use caching for expensive operations
- Optimize build times
- Monitor resource usage

### Monitoring

```bash
# Performance monitoring
export CI_PERFORMANCE_MONITORING=true

# Resource usage tracking
export CI_RESOURCE_TRACKING=true
```

This comprehensive developer guide should help you understand, contribute to, and extend the CI Excellence Framework effectively.