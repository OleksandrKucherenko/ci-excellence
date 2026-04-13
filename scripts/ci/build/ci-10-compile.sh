#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Compile/Build
# Purpose: Compile or build the project
# Hooks: begin, compile, end (automatic)
#   ci-cd/ci-10-compile/begin_*.sh  - pre-compile setup
#   ci-cd/ci-10-compile/compile_*.sh - build commands (override default)
#   ci-cd/ci-10-compile/end_*.sh    - post-compile cleanup

# Default compile implementation: detects build system and logs it.
# Override by adding ci-cd/ci-10-compile/compile_40_your-build.sh
hook:compile() {
  if [ -f "tsconfig.json" ]; then
    echo:Build "TypeScript project detected"
    # npx tsc --build
  elif [ -f "webpack.config.js" ] || [ -f "vite.config.ts" ]; then
    echo:Build "JS bundler project detected"
    # npm run build
  elif [ -f "go.mod" ]; then
    echo:Build "Go project detected"
    # go build -v ./...
  elif [ -f "Cargo.toml" ]; then
    echo:Build "Rust project detected"
    # cargo build --release
  elif [ -f "pom.xml" ]; then
    echo:Build "Maven project detected"
    # mvn clean package
  elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    echo:Build "Gradle project detected"
    # ./gradlew build
  else
    echo:Build "No build system detected"
  fi
}

echo:Build "Compiling/Building Project"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

set +eu
hooks:declare compile
hooks:do compile
set -eu

echo:Success "Build Complete"
