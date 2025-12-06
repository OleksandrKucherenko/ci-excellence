#!/usr/bin/env bash
set -euo pipefail

# CI Script: Security Scan
# Purpose: Run security vulnerability scans (technology-agnostic stub)

echo "========================================="
echo "Running Security Scans"
echo "========================================="

EXIT_CODE=0

# Ensure mise is available
if ! command -v mise &> /dev/null; then
    echo "❌ mise not found. Please run setup script first."
    exit 1
fi

# Run gitleaks via mise
echo "Running gitleaks secret detection..."
if mise x -- gitleaks detect --redact --verbose --report-path gitleaks-report.json --report-format json; then
    echo "✓ No secrets detected by gitleaks"
else
    echo "⚠ Gitleaks found potential secrets!"
    EXIT_CODE=1
fi

echo ""

# Run trufflehog via mise
echo "Running trufflehog credential scan..."
if mise x -- trufflehog git file://. --only-verified --fail --exclude-paths .trufflehog-exclude.txt --json > trufflehog-report.json 2>&1; then
    echo "✓ No leaked credentials detected by trufflehog"
else
    echo "⚠ Trufflehog found leaked credentials!"
    EXIT_CODE=1
fi

echo ""

# Example: NPM audit
# if [ -f "package.json" ]; then
#     echo "Running npm audit..."
#     npm audit --audit-level=moderate || EXIT_CODE=$?
# fi

# Example: Snyk scan
# if command -v snyk &> /dev/null; then
#     echo "Running Snyk scan..."
#     snyk test || EXIT_CODE=$?
# fi

# Example: Python safety check
# if [ -f "requirements.txt" ]; then
#     echo "Running safety check..."
#     safety check -r requirements.txt || EXIT_CODE=$?
# fi

# Example: Trivy for container scanning
# if [ -f "Dockerfile" ]; then
#     echo "Running Trivy container scan..."
#     trivy image --severity HIGH,CRITICAL myapp:latest || EXIT_CODE=$?
# fi

# Example: OWASP Dependency Check
# if command -v dependency-check &> /dev/null; then
#     echo "Running OWASP Dependency Check..."
#     dependency-check --project \"MyProject\" --scan . || EXIT_CODE=$?
# fi

# Add your security scanning commands here
echo "✓ Security scan stub executed"
echo "  Customize this script in scripts/ci/build/ci-03-security-scan.sh"

# Create SARIF output for GitHub Security
mkdir -p .
cat > security-results.sarif <<EOF
{
  "\$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
  "version": "2.1.0",
  "runs": [
    {
      "tool": {
        "driver": {
          "name": "Security Scan",
          "version": "1.0.0",
          "informationUri": "https://github.com/your-org/ci-excellence"
        }
      },
      "results": []
    }
  ]
}
EOF

if [ $EXIT_CODE -ne 0 ]; then
    echo "========================================="
    echo "⚠ Security issues found"
    echo "========================================="

    # Show summary of findings
    if [ -f "gitleaks-report.json" ]; then
        echo ""
        echo "Gitleaks findings:"
        cat gitleaks-report.json | head -20
    fi

    if [ -f "trufflehog-report.json" ]; then
        echo ""
        echo "Trufflehog findings:"
        cat trufflehog-report.json | head -20
    fi

    # Exit with error code to fail the build
    exit $EXIT_CODE
fi

echo "========================================="
echo "Security Scan Complete"
echo "========================================="
