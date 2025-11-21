#!/usr/bin/env bash
# Pre-commit Secret Scan Hook
# Scans staged files for secrets before commit

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

log_error() {
  echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $*" >&2
}

log_info() {
  echo -e "${GREEN}[INFO]${NC} $*" >&2
}

# Get list of staged files
get_staged_files() {
  git diff --cached --name-only --diff-filter=ACM
}

# Check if file is text (not binary)
is_text_file() {
  local file="$1"
  file -b --mime-type "$file" 2>/dev/null | grep -q "text/"
}

# Run Gitleaks on staged files
run_gitleaks_staged() {
  log_info "Running Gitleaks on staged files"

  local staged_files
  readarray -t staged_files < <(get_staged_files)

  if [[ ${#staged_files[@]} -eq 0 ]]; then
    log_info "No staged files to scan"
    return 0
  fi

  log_info "Scanning ${#staged_files[@]} staged files"

  # Create temporary file with staged file list
  local temp_file
  temp_file=$(mktemp)
  printf '%s\n' "${staged_files[@]}" > "$temp_file"

  # Run Gitleaks on staged files
  if gitleaks protect --staged --redact --verbose --no-banner 2>/dev/null; then
    log_success "Gitleaks scan passed - no secrets found in staged files"
  else
    log_error "❌ Gitleaks found secrets in staged files!"
    log_error ""
    log_error "To fix this:"
    log_error "1. Remove any hardcoded secrets from the staged files"
    log_error "2. Use environment variables or encrypted secrets"
    log_error "3. Stage your changes again and retry the commit"
    rm -f "$temp_file"
    return 1
  fi

  rm -f "$temp_file"
}

# Run Trufflehog on staged files
run_trufflehog_staged() {
  log_info "Running Trufflehog on staged files"

  local staged_files
  readarray -t staged_files < <(get_staged_files)

  # Filter to text files only
  local text_files=()
  for file in "${staged_files[@]}"; do
    if [[ -f "$file" ]] && is_text_file "$file"; then
      text_files+=("$file")
    fi
  done

  if [[ ${#text_files[@]} -eq 0 ]]; then
    log_info "No text files to scan"
    return 0
  fi

  log_info "Scanning ${#text_files[@]} text files"

  # Run Trufflehog on staged text files
  if trufflehog filesystem "${text_files[@]}" --only-verified --fail 2>/dev/null; then
    log_success "Trufflehog scan passed - no secrets found in staged files"
  else
    log_error "❌ Trufflehog found secrets in staged files!"
    log_error ""
    log_error "To fix this:"
    log_error "1. Remove any hardcoded secrets from the staged files"
    log_error "2. Use environment variables or encrypted secrets"
    log_error "3. Stage your changes again and retry the commit"
    return 1
  fi
}

# Check for common secret patterns in staged files
check_common_patterns() {
  log_info "Checking for common secret patterns in staged files"

  local staged_files
  readarray -t staged_files < <(get_staged_files)

  local issues_found=false
  local patterns=(
    "password\s*=\s*['\"][^'\"]{8,}['\"]"
    "secret\s*=\s*['\"][^'\"]{8,}['\"]"
    "key\s*=\s*['\"][^'\"]{8,}['\"]"
    "token\s*=\s*['\"][^'\"]{8,}['\"]"
    "api[_-]?key\s*=\s*['\"][^'\"]{8,}['\"]"
    "private[_-]?key\s*=\s*['\"][^'\"]{8,}['\"]"
    "aws[_-]?access[_-]?key\s*=\s*['\"][^'\"]{8,}['\"]"
    "aws[_-]?secret[_-]?key\s*=\s*['\"][^'\"]{8,}['\"]"
  )

  for file in "${staged_files[@]}"; do
    # Only check text files
    if [[ -f "$file" ]] && is_text_file "$file"; then
      for pattern in "${patterns[@]}"; do
        if grep -E "$pattern" "$file" >/dev/null 2>&1; then
          local line_number
          line_number=$(grep -n -E "$pattern" "$file" | head -1 | cut -d: -f1)
          log_error "Potential secret found in $file at line $line_number"
          log_error "Pattern: $pattern"
          issues_found=true
        fi
      done
    fi
  done

  if [[ "$issues_found" == "true" ]]; then
    log_error ""
    log_error "❌ Potential secrets found in staged files!"
    log_error ""
    log_error "To fix this:"
    log_error "1. Review the files mentioned above"
    log_error "2. Replace hardcoded secrets with environment variables"
    log_error "3. Use SOPS for encrypted configuration"
    log_error "4. Stage your changes again and retry the commit"
    return 1
  fi

  log_success "No common secret patterns found in staged files"
}

# Main execution
main() {
  log_info "🔍 Running pre-commit secret scan"

  # Run all checks
  check_common_patterns
  run_gitleaks_staged
  run_trufflehog_staged

  log_success "✅ Pre-commit secret scan passed"
}

# Execute main function
main "$@"