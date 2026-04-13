#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Install Dependencies
# Purpose: Install project dependencies
# Hooks: begin, install, end (automatic)
#   ci-cd/ci-20-install-dependencies/begin_*.sh   - pre-install setup
#   ci-cd/ci-20-install-dependencies/install_*.sh - install commands (override default)
#   ci-cd/ci-20-install-dependencies/end_*.sh     - post-install cleanup

# Default install implementation: detects package manager and logs it.
# Override by adding ci-cd/ci-20-install-dependencies/install_40_your-installer.sh
hook:install() {
  if [ -f "package.json" ]; then
    if [ -f "pnpm-lock.yaml" ]; then
      echo:Setup "Detected pnpm"
      # pnpm install --frozen-lockfile
    elif [ -f "yarn.lock" ]; then
      echo:Setup "Detected yarn"
      # yarn install --frozen-lockfile
    elif [ -f "package-lock.json" ]; then
      echo:Setup "Detected npm (lockfile)"
      # npm ci
    else
      echo:Setup "Detected npm (no lockfile)"
      # npm install
    fi
  elif [ -f "requirements.txt" ]; then
    echo:Setup "Detected Python requirements.txt"
    # pip3 install -r requirements.txt
  elif [ -f "Pipfile" ]; then
    echo:Setup "Detected Pipenv"
    # pipenv install --deploy
  elif [ -f "poetry.lock" ]; then
    echo:Setup "Detected Poetry"
    # poetry install
  elif [ -f "go.mod" ]; then
    echo:Setup "Detected Go modules"
    # go mod download
  elif [ -f "Gemfile" ]; then
    echo:Setup "Detected Ruby Bundler"
    # bundle install
  elif [ -f "composer.json" ]; then
    echo:Setup "Detected PHP Composer"
    # composer install
  elif [ -f "Cargo.toml" ]; then
    echo:Setup "Detected Rust Cargo"
    # cargo fetch
  else
    echo:Setup "No recognized dependency file found"
  fi
}

echo:Setup "Installing Project Dependencies"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

set +eu
hooks:declare install
hooks:do install
set -eu

echo:Success "Dependency Installation Complete"
