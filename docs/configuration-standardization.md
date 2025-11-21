# Configuration File Standardization Analysis

## Current State Analysis

Based on investigation of our existing tool configurations, here's what we found:

### ✅ Already Standardized (Hidden with Comment Support)

| Tool | Current File | Format | Status |
|------|--------------|--------|--------|
| **Mise** | `.mise.toml` | TOML | ✅ Perfect |
| **ShellSpec** | `.shellspec.toml` | TOML | ✅ Perfect |
| **shfmt** | `.shfmt.toml` | TOML | ✅ Perfect |
| **SOPS** | `.sops.yaml` | YAML | ✅ Perfect |
| **Trufflehog** | `.trufflehog.yaml` | YAML | ✅ Perfect |

### ⚠️ Needs Standardization

| Tool | Current File(s) | Format | Issues |
|------|-----------------|--------|--------|
| **Lefthook** | `lefthook.yml`, `.lefthook.yml` | YAML | Duplicate files, should consolidate to hidden file |
| **Commitizen** | `commitizen.json` | JSON | Visible file, should be hidden and support comments |

## Tool Configuration Format Support

### Lefthook
- **Supported Formats**: YAML (primary)
- **File Names**: `.lefthook.yml` (preferred), `lefthook.yml`
- **Comments**: ✅ YAML supports comments
- **Recommendation**: Use `.lefthook.yml`, remove duplicate `lefthook.yml`

### Commitizen
- **Supported Formats**: TOML, JSON, Python's pyproject.toml
- **File Names**: `.cz.toml`, `cz.toml`, `package.json`, `pyproject.toml`
- **Comments**: ✅ TOML supports comments
- **Recommendation**: Convert to `.cz.toml` for better comment support

## Standardization Plan

### Phase 1: Immediate Fixes
1. **Lefthook Consolidation**
   - Keep `.lefthook.yml` (already correct)
   - Remove duplicate `lefthook.yml`
   - Merge any unique configurations

2. **Commitizen Conversion**
   - Convert `commitizen.json` → `.cz.toml`
   - Preserve all existing configuration
   - Add comments for better documentation

### Phase 2: Documentation and Standards

### Configuration File Standards

All configuration files should follow these standards:

1. **Hidden Files**: Start with `.` (e.g., `.tool.toml`, `.tool.yaml`)
2. **Format Preference**: TOML > YAML > JSON (prioritizing comment support)
3. **Comment Headers**: Include tool description and documentation links
4. **Consistent Naming**: Use kebab-case for tool names when needed

### Recommended File Structure

```
# Core tool configuration (hidden files)
.mise.toml                    # Mise task management
.lefthook.yml                 # Git hooks manager
.cz.toml                      # Commitizen (commit message standardization)
.shfmt.toml                   # Shell formatting
.shellspec.toml               # Shell testing framework
.sops.yaml                    # Secret encryption
.trufflehog.yaml             # Secret scanning
.trufflehogignore             # Trufflehog exclude patterns (already done)

# Environment configuration (visible, by design)
mise.toml                     # Project-specific mise configuration (visible by design)
environments/                 # Environment configurations (visible by design)

# IDE and editor configuration (hidden)
.vscode/settings.json         # VS Code settings (JSON required by VS Code)
.claude/settings.local.json   # Claude settings (JSON required by Claude)
```

## Implementation Steps

### Step 1: Lefthook Consolidation
```bash
# Check differences between files
diff lefthook.yml .lefthook.yml

# Merge configurations (if needed)
# Then remove duplicate
rm lefthook.yml
```

### Step 2: Commitizen Conversion
```bash
# Convert JSON to TOML format
# Create .cz.toml with equivalent configuration
# Remove commitizen.json
```

### Step 3: Validation
```bash
# Test Lefthook
lefthook install
lefthook run pre-commit

# Test Commitizen
git commit -m "test: verify commitizen configuration"
```

## Benefits

1. **Consistency**: All tool configs hidden and standardized
2. **Comments**: TOML/YAML support for better documentation
3. **Maintainability**: Easier to understand and modify configurations
4. **Clean Repository**: Reduce visible file clutter
5. **Standards Compliance**: Follow industry best practices

## Risk Assessment

- **Low Risk**: Changes are configuration file moves/renames
- **Backward Compatibility**: Most tools support multiple formats
- **Rollback**: Original files can be restored if needed
- **Testing**: Can validate with existing git hooks and commit process

## Next Steps

1. Review current configuration differences
2. Implement Lefthook consolidation
3. Convert Commitizen to TOML
4. Test all tooling works correctly
5. Update documentation with new standards