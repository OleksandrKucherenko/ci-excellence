# Security Policy

This document outlines the security practices, procedures, and policies for the CI Pipeline Excellence framework.

## 🛡️ Security Overview

Our CI/CD pipeline is designed with security-first principles:

- **Zero Trust Architecture**: All access is verified and audited
- **Encrypted Secrets**: All secrets are encrypted with age/SOPS
- **Comprehensive Scanning**: 100% secret scanning coverage with Gitleaks and Trufflehog
- **Role-Based Access**: granular permissions with emergency override procedures
- **Audit Trails**: 30-day retention for all security events

## 🔐 Secret Management

### Encryption Architecture

We use **SOPS (Secrets OPerationS)** with **age encryption** for secret management:

```bash
# Age key file location
.secrets/mise-age.txt

# SOPS configuration
.sops.yaml
```

### Secret Types

#### 1. Environment Secrets
- **Location**: `environments/{env}/secrets.enc`
- **Access**: Environment-specific decryption keys
- **Rotation**: Environment-specific procedures

#### 2. Repository Secrets
- **Location**: `.env.secrets.json` (SOPS encrypted)
- **Access**: Repository-wide access
- **Rotation**: Global procedures

#### 3. GitHub Secrets
- **Location**: GitHub repository settings
- **Access**: CI/CD pipeline only
- **Rotation**: Through GitHub interface

## 🔄 Secret Rotation Procedures

### Automated Rotation (Recommended)

```bash
# Rotate all encryption keys
mise run secrets-rotate

# Rotate specific environment
mise run secrets-rotate production

# Verify rotation completed successfully
mise run secrets-audit
```

### Manual Rotation Procedure

#### 1. Generate New Age Key

```bash
# Generate new age key pair
age-keygen -o .secrets/mise-age-new.txt

# Backup old key
cp .secrets/mise-age.txt .secrets/mise-age-backup.txt
```

#### 2. Update SOPS Configuration

```bash
# Edit .sops.yaml to add new key
vim .sops.yaml

# Add new age key to all creation rules
```

#### 3. Re-encrypt All Secrets

```bash
# Re-encrypt environment secrets
for env in global staging production canary sandbox performance; do
  if [ -f "environments/$env/secrets.enc" ]; then
    sops --encrypt --config-file .sops.yaml environments/$env/secrets.enc
  fi
done

# Re-encrypt repository secrets
if [ -f ".env.secrets.json" ]; then
  sops --encrypt --config-file .sops.yaml .env.secrets.json
fi
```

#### 4. Update Deployment

```bash
# Replace old key with new key
mv .secrets/mise-age-new.txt .secrets/mise-age.txt

# Commit changes
git add .sops.yaml .secrets/mise-age.txt
git commit -m "security: rotate encryption keys"
git push origin main
```

#### 5. Verify Rotation

```bash
# Test decryption with new key
sops --decrypt environments/production/secrets.enc

# Run security audit
mise run security-audit
```

### Emergency Key Recovery

If key rotation fails and you need to recover:

```bash
# Restore from backup
cp .secrets/mise-age-backup.txt .secrets/mise-age.txt

# Re-encrypt with backup key
# (Follow manual rotation procedure with backup key)
```

## 🔍 Security Scanning

### Tools Used

1. **Gitleaks**: Real-time secret detection
2. **Trufflehog**: Git history scanning
3. **ShellCheck**: Security-focused shell linting
4. **SOPS**: Encrypted file validation

### Scan Configuration

```bash
# Pre-commit: Scan all files
gitleaks protect --no-banner --verbose

# Pre-push: Scan git history
trufflehog git file://. --only-verified

# Manual: Full repository scan
mise run security-scan
mise run scan-history
```

### Secret Detection Rules

We detect and block:

- API keys and tokens
- Database credentials
- SSH keys and certificates
- Cloud provider credentials
- Third-party service keys
- Encryption keys and passwords

### False Positives

If you encounter false positives:

1. **Update Gitleaks configuration**: `.gitleaks.toml`
2. **Add allowlist rules** for known patterns
3. **Test configuration changes**: `mise run security-scan`

## 🚨 Incident Response

### Security Incident Categories

#### 1. Secret Exposure
**Severity**: CRITICAL
**Response Time**: Immediate

**Response**:
1. **Revoke exposed secrets** immediately
2. **Rotate all encryption keys**: `mise run secrets-rotate`
3. **Scan entire repository**: `mise run security-audit`
4. **Audit access logs** for last 30 days
5. **Notify stakeholders** with impact assessment

#### 2. Unauthorized Access
**Severity**: HIGH
**Response Time**: 1 hour

**Response**:
1. **Revoke access** for compromised accounts
2. **Force password resets** for all users
3. **Enable additional authentication** requirements
4. **Audit recent changes** to CI/CD configuration
5. **Update access policies**

#### 3. Pipeline Integrity Issues
**Severity**: MEDIUM
**Response Time**: 4 hours

**Response**:
1. **Pause all deployments** immediately
2. **Verify workflow integrity** with `mise run validate-workflows`
3. **Check for unauthorized modifications**
4. **Run full security scan** with `mise run security-audit`
5. **Document findings** and improvements

### Reporting Security Issues

**For Public Security Issues**:
- Create a private GitHub issue
- Email: security@yourorganization.com
- Include detailed description and steps to reproduce

**For Internal Security Issues**:
- Use your organization's incident reporting channel
- Contact security team immediately
- Follow internal incident response procedures

## 👥 Access Control

### Role-Based Permissions

#### 1. Administrators
- **Full access** to all environments and secrets
- **Emergency override** capabilities
- **Key rotation** and security audit permissions
- **Required for**: Secret rotation, emergency procedures

#### 2. Developers
- **Access to development and staging environments**
- **Limited production access** with approval
- **No access to encryption keys**
- **Required for**: Development, testing, staging deployments

#### 3. Deployers
- **Production deployment** permissions
- **Read access** to production secrets
- **No modification access** to secrets
- **Required for**: Production deployments

#### 4. Auditors
- **Read access** to audit logs and configurations
- **Security audit permissions**
- **No access to secrets**
- **Required for**: Security audits, compliance checks

### Emergency Override Procedures

#### Admin Override for Protected Tags

In emergency situations, administrators can bypass protected tag restrictions:

```bash
# Enable override temporarily
export ALLOW_PROTECTED_TAG_PUSH=true
export EMERGENCY_OVERRIDE_REASON="Emergency deployment for critical security fix"

# Create protected tag
git tag production v1.2.3-emergency-fix
git push origin production

# Document override in audit log
echo "$(date): Emergency override by $USER - $EMERGENCY_OVERRIDE_REASON" >> .secrets/emergency-overrides.log
```

#### Rollback Emergency Procedures

```bash
# Emergency rollback via admin override
gh workflow run rollback.yml \
  --field environment=production \
  --field current_version=v1.2.3-broken \
  --field emergency_override=true \
  --field override_reason="Security vulnerability"
```

## 📊 Security Monitoring

### Audit Trail Retention

- **CI/CD Logs**: 30 days
- **Secret Access Logs**: 90 days
- **Security Scan Results**: 90 days
- **Emergency Override Logs**: 1 year
- **Key Rotation History**: 1 year

### Monitoring Alerts

Set up alerts for:

1. **Secret exposure** in commits or pipelines
2. **Failed authentication** attempts
3. **Unauthorized tag creation** attempts
4. **Key rotation failures**
5. **Security scan failures**

### Regular Security Tasks

#### Daily
- Monitor CI/CD pipeline security scan results
- Review any failed security checks

#### Weekly
- Review emergency override usage
- Audit access logs for unusual patterns

#### Monthly
- Complete security audit with `mise run security-audit`
- Review and update security configurations
- Validate encryption key integrity

#### Quarterly
- Complete secret rotation procedures
- Review and update access policies
- Conduct security training for team members

## 📚 Security Best Practices

### Development Practices

1. **Never commit secrets** to the repository
2. **Use encrypted secrets** for all sensitive data
3. **Enable security scanning** in all environments
4. **Follow principle of least privilege**
5. **Regular security reviews** of configurations

### CI/CD Pipeline Security

1. **Validate all inputs** in workflows
2. **Use GitHub Secrets** for pipeline credentials
3. **Implement timeout protections** for all jobs
4. **Enable concurrency controls** for deployments
5. **Audit all workflow changes**

### Secret Management

1. **Rotate keys regularly** (quarterly minimum)
2. **Use different keys** for different environments
3. **Backup keys securely** with restricted access
4. **Document all rotation procedures**
5. **Test recovery procedures** regularly

## 🔧 Security Configuration Files

### Key Security Files

- `.sops.yaml`: SOPS encryption configuration
- `.secrets/mise-age.txt`: Age encryption key
- `.gitleaks.toml`: Gitleaks secret detection rules
- `.lefthook.yml`: Pre-commit security hooks
- `mise.toml`: Security tool definitions

### Validation Commands

```bash
# Validate SOPS configuration
sops --config-file .sops.yaml --decrypt .env.secrets.json

# Test Gitleaks configuration
gitleaks detect --verbose --config .gitleaks.toml

# Validate git hooks
lefthook run pre-push --dry-run

# Test secret scanning
mise run security-scan
mise run scan-history
```

## 🔧 Self-Healing Security Integration

### Automated Security Fixes

Our CI pipeline includes self-healing capabilities for security issues:

#### Pre-commit Security Hooks
```bash
# Secret detection (blocks commits with secrets)
./scripts/hooks/pre-commit-secret-scan.sh

# Format validation (prevents malformed security scripts)
./scripts/hooks/pre-commit-format.sh

# Lint validation (catches security anti-patterns)
./scripts/hooks/pre-commit-lint.sh

# Commit message validation (prevents secret disclosure in commits)
./scripts/hooks/pre-commit-message-check.sh
```

#### CI/CD Self-Healing Workflows
```bash
# Auto-fix security-related formatting issues
./scripts/ci/50-ci-auto-format.sh

# Auto-fix ShellCheck security warnings
./scripts/ci/60-ci-auto-lint-fix.sh

# Auto-commit security fixes with proper attribution
./scripts/ci/70-ci-commit-fixes.sh
```

### Security Auto-Fix Triggers

The auto-fix workflow triggers on:
1. **Push to main/develop**: Comprehensive security auto-fixes
2. **Pull requests**: Targeted fixes for PR changes
3. **Manual dispatch**: On-demand security fixes

### Security Fix Categories

1. **Format Fixes**: Ensures consistent bash script formatting
2. **Lint Fixes**: Automatically resolves common security anti-patterns:
   - Unquoted variables (`$VAR` → `"$VAR"`)
   - Unsafe command substitutions
   - Missing error handling
   - Insecure temporary file usage

3. **Secret Prevention**: Blocks and educates on secret handling

## 📞 Security Contact

**Security Team**: security@yourorganization.com
**Emergency Contact**: Create GitHub issue with "SECURITY" prefix
**Documentation**: Check `/docs/security` directory for detailed guides

---

**Last Updated**: 2025-11-21
**Next Review**: 2025-12-21
**Security Version**: 1.0.0

This security policy should be reviewed quarterly and updated as needed based on security incidents, threat landscape changes, or system updates.