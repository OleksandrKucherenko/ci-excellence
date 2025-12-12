# Contributing to CI Excellence

Thank you for your interest in contributing to CI Excellence! This document provides guidelines and instructions for contributing to this project.

## How to Contribute

### Reporting Issues

If you find a bug or have a suggestion:

1. **Search existing issues** to avoid duplicates
2. **Create a new issue** with:
   - Clear, descriptive title
   - Detailed description of the problem or suggestion
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - Your environment (OS, CI platform, etc.)

### Submitting Changes

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
   - Follow the existing code style
   - Update documentation as needed
   - Add comments to explain complex logic
4. **Test your changes**
   - Ensure all workflows run successfully
   - Test with different configurations
5. **Commit your changes**
   ```bash
   git commit -m "feat: add new feature"
   ```
   Use [Conventional Commits](https://www.conventionalcommits.org/)
6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```
7. **Create a Pull Request**
   - Provide clear description of changes
   - Reference related issues
   - Include before/after examples if applicable

## Code Style Guidelines

### Shell Scripts

- Use `#!/usr/bin/env bash` shebang
- Enable strict mode: `set -euo pipefail`
- Add descriptive comments
- Use meaningful variable names
- Include error handling
- Echo informative messages

Example:
```bash
#!/usr/bin/env bash
set -euo pipefail

# CI Pipeline Stub: Example Script
# Purpose: Demonstrate proper script structure

echo "========================================="
echo "Running Example Script"
echo "========================================="

# Check required environment variable
if [ -z "${REQUIRED_VAR:-}" ]; then
    echo "⚠ REQUIRED_VAR is not set"
    exit 1
fi

# Main logic here
echo "✓ Script executed successfully"

echo "========================================="
echo "Example Script Complete"
echo "========================================="
```

### GitHub Actions Workflows

- Use clear, descriptive job names
- Add comments for complex logic
- Use environment variables for configuration
- Implement proper job dependencies
- Add meaningful step names

### Documentation

- Update README.md for major changes
- Add inline comments for complex code
- Include examples in documentation
- Keep language clear and concise
- Use proper Markdown formatting

## Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/ci-excellence.git
   cd ci-excellence
   ```

2. **Make scripts executable**
   ```bash
   chmod +x scripts/**/*.sh
   ```

3. **Test locally** (if applicable)
   ```bash
   ./scripts/ci/setup/ci-20-install-dependencies.sh
   ./scripts/ci/build/ci-10-compile.sh
   ./scripts/ci/test/ci-10-unit-tests.sh
   ```

## Testing Guidelines

### Before Submitting

- [ ] All scripts are executable
- [ ] Scripts have proper error handling
- [ ] Workflows validate successfully
- [ ] Documentation is updated
- [ ] Changes work with different tech stacks
- [ ] No secrets or sensitive data committed

### Testing Workflows

Test workflows using:
1. [act](https://github.com/nektos/act) for local testing
2. Fork repository and test with real GitHub Actions
3. Different scenarios (various tech stacks)

## Areas for Contribution

### High Priority

- Additional language/framework support
- More comprehensive testing examples
- Improved error handling
- Better documentation
- Security enhancements

### Ideas Welcome

- Integration with other CI platforms
- Additional deployment targets
- Monitoring and alerting
- Performance optimizations
- More comprehensive templates

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Welcome newcomers
- Accept constructive criticism
- Focus on what's best for the project
- Show empathy towards others

### Unacceptable Behavior

- Harassment or discrimination
- Trolling or insulting comments
- Publishing others' private information
- Unprofessional conduct

## Questions?

- Check the [README.md](README.md) for documentation
- Search existing issues for answers
- Create a new issue for questions
- Reach out to maintainers

## Recognition

Contributors will be:
- Listed in release notes
- Mentioned in CONTRIBUTORS.md
- Thanked in release announcements

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT License).

---

Thank you for contributing to CI Excellence! 🎉
