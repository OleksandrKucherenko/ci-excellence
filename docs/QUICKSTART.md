# Quick Start Guide

Get your CI/CD pipeline running in 5 minutes!

## Step 1: Copy Files (1 minute)

Copy these directories to your project root:

```bash
cp -r .github scripts config /path/to/your/project/
cd /path/to/your/project
```

## Step 2: Make Scripts Executable (30 seconds)

```bash
chmod +x scripts/**/*.sh
```

## Step 3: Configure GitHub (2 minutes)

### Go to: Repository Settings > Secrets and variables > Actions > Variables

Add these variables:

```
ENABLE_COMPILE=true
ENABLE_LINT=true
ENABLE_UNIT_TESTS=true
ENABLE_GITHUB_RELEASE=true
```

Click "New repository variable" for each one.

## Step 4: Customize One Script (1 minute)

Edit the script for your tech stack:

### For Node.js/TypeScript:

```bash
# Edit scripts/ci/build/ci-10-compile.sh
vim scripts/ci/build/ci-10-compile.sh

# Uncomment this line:
# npx tsc
```

### For Python:

```bash
# Edit scripts/ci/build/ci-10-compile.sh
vim scripts/ci/build/ci-10-compile.sh

# Uncomment this line:
# python -m build
```

### For Go:

```bash
# Edit scripts/ci/build/ci-10-compile.sh
vim scripts/ci/build/ci-10-compile.sh

# Uncomment this line:
# go build -v ./...
```

## Step 5: Push and Test (30 seconds)

```bash
git add .
git commit -m "chore: add CI/CD pipeline"
git push
```

## ✅ Done!

Go to your repository's "Actions" tab to see the pipeline running!

## What's Next?

### Enable More Features

Go to Settings > Secrets and variables > Actions > Variables and add:

```
ENABLE_INTEGRATION_TESTS=true
ENABLE_E2E_TESTS=true
ENABLE_SECURITY_SCAN=true
```

### Customize More Scripts

Edit scripts in the `scripts/` directory:

- `scripts/ci/test/ci-10-unit-tests.sh` - Unit testing
- `scripts/ci/test/ci-20-integration-tests.sh` - Integration testing
- `scripts/ci/build/ci-20-lint.sh` - Linting
- `scripts/ci/release/ci-65-publish-npm.sh` - NPM publishing

### Run Your First Release

1. Go to Actions tab
2. Click "Release Pipeline"
3. Click "Run workflow"
4. Select "patch" for release type
5. Click "Run workflow" button

### Enable NPM Publishing (Optional)

1. Get NPM token from npmjs.com
2. Go to Settings > Secrets and variables > Actions > Secrets
3. Add secret: `NPM_TOKEN` with your token
4. Add variable: `ENABLE_NPM_PUBLISH=true`

## Need Help?

Check the full [README.md](README.md) for:
- Complete documentation
- Troubleshooting guide
- Best practices
- Advanced configuration

## Common Issues

### "Permission denied" error

```bash
chmod +x scripts/**/*.sh
git add scripts/
git commit -m "fix: make scripts executable"
git push
```

### Jobs are skipped

This is normal! Jobs only run when enabled. Add the `ENABLE_*` variable to enable them.

### Can't find GitHub Actions tab

Make sure you pushed the `.github/workflows/` directory to your repository.

---

**You're all set! 🚀**
