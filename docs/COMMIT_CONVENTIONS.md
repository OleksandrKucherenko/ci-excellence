# Commit Message Conventions

This project follows the [Conventional Commits](https://www.conventionalcommits.org/) specification for commit messages. This standardization helps with:

- Automated changelog generation
- Semantic versioning automation
- Better readability of project history
- Easier collaboration

---

## Commit Message Format

Each commit message consists of a **header**, optional **body**, and optional **footer**:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Header

The header is **mandatory** and must conform to this format:

```
<type>[optional scope]: <description>
```

#### Type

Must be one of the following:

| Type | Description | Example |
|------|-------------|---------|
| **feat** | A new feature | `feat: add user authentication` |
| **fix** | A bug fix | `fix: resolve login timeout issue` |
| **docs** | Documentation only changes | `docs: update API documentation` |
| **style** | Code style changes (formatting, missing semicolons, etc.) | `style: format code with prettier` |
| **refactor** | Code change that neither fixes a bug nor adds a feature | `refactor: simplify user validation logic` |
| **perf** | Performance improvements | `perf: optimize database queries` |
| **test** | Adding or updating tests | `test: add unit tests for auth module` |
| **build** | Changes to build system or dependencies | `build: update webpack to v5` |
| **ci** | Changes to CI configuration files and scripts | `ci: add codecov integration` |
| **chore** | Other changes that don't modify src or test files | `chore: update gitignore` |
| **revert** | Reverts a previous commit | `revert: revert feat: add feature X` |

#### Scope (Optional)

The scope provides additional context about what part of the codebase is affected:

```
feat(api): add new endpoint for user profile
fix(ui): resolve button alignment issue
docs(readme): add installation instructions
```

Common scopes in this project:
- `api` - API changes
- `ui` - User interface changes
- `core` - Core functionality
- `docs` - Documentation
- `config` - Configuration files
- `deps` - Dependencies
- `ci` - CI/CD workflows
- `scripts` - Build/utility scripts
- `tests` - Test files
- `workflows` - GitHub Actions workflows

#### Description

The description is a short summary of the change:

- Use imperative, present tense: "add" not "added" or "adds"
- Don't capitalize the first letter
- No period (.) at the end
- Keep it under 72 characters

✅ **Good:**
```
feat: add email notification service
fix: resolve memory leak in cache module
docs: update contributing guidelines
```

❌ **Bad:**
```
feat: Added email notification service.  (capitalized, past tense, period)
fix: Fixes memory leak                   (wrong tense)
docs: Updated the contributing guidelines (past tense, capitalized)
```

#### Breaking Changes

Breaking changes should be indicated by an **!** after the type/scope:

```
feat!: remove deprecated API endpoints
feat(api)!: change authentication mechanism
```

### Body (Optional)

The body should include the motivation for the change and contrast with previous behavior:

```
feat: add support for custom themes

This allows users to create and apply custom color schemes
to the application UI. Themes can be defined in JSON format
and stored in the themes directory.

Previous behavior required modifying CSS files directly.
```

### Footer (Optional)

The footer should contain:
- Breaking change notices
- Issue references
- PR references

```
BREAKING CHANGE: Configuration format has changed from YAML to JSON

Closes #123
Fixes #456
See also: #789
```

---

## Complete Examples

### Simple Feature
```
feat: add dark mode toggle
```

### Feature with Scope
```
feat(ui): add user profile page
```

### Bug Fix with Issue Reference
```
fix(api): resolve timeout in authentication

The authentication endpoint was timing out for users with
special characters in their username. Added proper escaping
to resolve the issue.

Fixes #234
```

### Breaking Change
```
feat(api)!: change authentication to OAuth2

BREAKING CHANGE: The authentication mechanism has been changed
from JWT tokens to OAuth2. All existing tokens will be invalidated.

Migration guide: docs/migration/oauth2.md

Closes #567
```

### Refactor with Body
```
refactor(core): simplify validation logic

Extracted common validation patterns into reusable functions,
reducing code duplication by 30% and improving maintainability.
```

---

## Tools

### Using Commitizen

The easiest way to create properly formatted commit messages is using `commitizen`:

```bash
# Interactive commit message creation
cz commit

# Or use the git alias
git cz
```

This will guide you through creating a properly formatted commit message.

### Manual Commits

If you prefer writing commit messages manually, they will be validated by a git hook:

```bash
git commit -m "feat: add new feature"
```

The commit-msg hook will validate your message and provide feedback if it doesn't match the format.

---

## Validation

### Pre-Commit Hook

This project uses [Lefthook](https://github.com/evilmartians/lefthook) to manage git hooks. The commit-msg hook validates all commit messages against the Conventional Commits standard.

When you commit, the hook will:

✅ **Accept** valid commit messages:
```
feat: add user authentication
fix(api): resolve timeout issue
docs: update README
```

❌ **Reject** invalid commit messages:
```
Added new feature                    (no type)
Feat: Add new feature               (capitalized type and description)
feat add new feature                (missing colon)
```

### Skipping Validation

The validation is automatically skipped for:
- Merge commits
- Revert commits
- Rebase operations

To temporarily skip validation (not recommended):
```bash
git commit --no-verify -m "message"
```

---

## Benefits

### 1. Automated Changelog Generation

Conventional commits enable automatic changelog generation:

```bash
# Generate changelog
cz changelog

# Create new version and update changelog
cz bump
```

### 2. Semantic Versioning

Commits determine version bumps automatically:

- **feat**: Minor version bump (0.1.0 → 0.2.0)
- **fix**: Patch version bump (0.1.0 → 0.1.1)
- **BREAKING CHANGE**: Major version bump (0.1.0 → 1.0.0)

### 3. Better Git History

```bash
# View commits by type
git log --oneline --grep="^feat"
git log --oneline --grep="^fix"

# View commits for specific scope
git log --oneline --grep="(api)"
```

### 4. Improved Collaboration

Team members can quickly understand:
- What changed (type + description)
- Where it changed (scope)
- Why it changed (body)
- Impact (breaking changes)

---

## Common Scenarios

### Adding a New Feature
```
feat(auth): add two-factor authentication

Implements TOTP-based 2FA for enhanced account security.
Users can enable 2FA in their account settings.

Closes #123
```

### Fixing a Bug
```
fix(api): prevent race condition in cache updates

Added mutex locking to prevent concurrent cache updates
from corrupting data. This resolves sporadic data
inconsistency issues reported by users.

Fixes #456
```

### Updating Documentation
```
docs: add API authentication guide

Created comprehensive guide for API authentication including
examples for all supported authentication methods.
```

### Refactoring Code
```
refactor(core): extract common validation functions

Moved validation logic into shared utilities module to
reduce code duplication across components.
```

### Improving Performance
```
perf(db): optimize user query performance

Added database indexes on frequently queried columns,
reducing average query time from 500ms to 50ms.
```

### Updating Dependencies
```
build(deps): upgrade react to v18

Updated React and related packages to v18.x for better
performance and new features. All tests passing.
```

### CI/CD Changes
```
ci: add automated security scanning

Integrated Snyk security scanning into GitHub Actions
workflow to detect vulnerabilities in dependencies.
```

---

## Troubleshooting

### Commit Rejected: Invalid Format

**Error:**
```
✗ Invalid commit message format
```

**Solution:**
Review the error message and ensure your commit follows the format:
```
<type>[optional scope]: <description>
```

Use lowercase for type and description, and include a colon after the type/scope.

### Commit Message Too Long

**Warning:**
```
⚠️  Warning: Commit subject is 95 characters (recommended max: 72)
```

**Solution:**
Keep the description concise. Use the body for additional details:

❌ **Bad:**
```
feat: add comprehensive user authentication system with JWT tokens and refresh token support
```

✅ **Good:**
```
feat: add JWT-based user authentication

Implements JWT token authentication with automatic refresh.
Includes support for token expiration and renewal.
```

### Need to Commit Quickly

**Option 1:** Use commitizen for guided input:
```bash
cz commit
```

**Option 2:** Use a simple format:
```bash
git commit -m "fix: resolve critical bug"
```

---

## Configuration

### Commitizen Configuration

Located in `.cz.toml`:

```toml
[tool.commitizen]
name = "cz_conventional_commits"
version = "0.1.0"
```

### Lefthook Configuration

Located in `lefthook.yml`:

```yaml
commit-msg:
  commands:
    conventional-commit:
      run: ./scripts/git-hooks/commit-msg-validate.sh {1}
```

---

## Resources

- [Conventional Commits Specification](https://www.conventionalcommits.org/)
- [Commitizen Documentation](https://commitizen-tools.github.io/commitizen/)
- [Lefthook Documentation](https://github.com/evilmartians/lefthook)
- [Semantic Versioning](https://semver.org/)

---

## Quick Reference

```
<type>[scope]: <description>

Types:
  feat      - New feature
  fix       - Bug fix
  docs      - Documentation
  style     - Formatting
  refactor  - Code restructuring
  perf      - Performance
  test      - Tests
  build     - Build system
  ci        - CI/CD
  chore     - Maintenance
  revert    - Revert commit

Examples:
  feat: add user authentication
  fix(api): resolve timeout issue
  docs: update installation guide
  feat!: breaking API changes
```

---

**Happy committing! 🚀**
