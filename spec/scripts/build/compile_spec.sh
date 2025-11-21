#!/usr/bin/env bash
# ShellSpec tests for CI Compile Script
# Tests compilation script with testability modes and different project types

set -euo pipefail

# Load the script under test
# shellcheck disable=SC1090,SC1091
. "$(dirname "$0")/../../../scripts/build/10-ci-compile.sh" 2>/dev/null || {
  echo "Failed to source 10-ci-compile.sh" >&2
  exit 1
}

# Setup test environment
setup_test_environment() {
  # Create test directory
  mkdir -p "/tmp/compile-test"
  cd "/tmp/compile-test"

  # Create project structure for different types
  mkdir -p nodejs-project/{src,tests,docs}
  mkdir -p python-project/{src,tests,docs}
  mkdir -p go-project/{cmd,internal,pkg,test,docs}
  mkdir -p rust-project/{src,tests,docs}
  mkdir -p generic-project/{src,tests,docs}

  # Create Node.js project files
  cat > nodejs-project/package.json << 'EOF'
{
  "name": "test-nodejs-project",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "build": "tsc",
    "test": "jest",
    "lint": "eslint src/**/*.ts",
    "type-check": "tsc --noEmit"
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "@types/node": "^20.0.0",
    "jest": "^29.0.0",
    "eslint": "^8.0.0"
  }
}
EOF

  cat > nodejs-project/src/index.ts << 'EOF'
export function hello(name: string): string {
  return `Hello, ${name}!`;
}

console.log(hello('World'));
EOF

  cat > nodejs-project/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "node",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "tests"]
}
EOF

  # Create Python project files
  cat > python-project/pyproject.toml << 'EOF'
[build-system]
requires = ["setuptools>=61.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "test-python-project"
version = "1.0.0"
description = "Test Python project"
dependencies = []

[tool.setuptools.packages.find]
where = ["src"]

[tool.pytest.ini_options]
testpaths = ["tests"]
EOF

  cat > python-project/src/main.py << 'EOF'
def hello(name: str) -> str:
    return f"Hello, {name}!"

if __name__ == "__main__":
    print(hello("World"))
EOF

  cat > python-project/requirements.txt << 'EOF'
pytest>=7.0.0
black>=23.0.0
flake8>=6.0.0
mypy>=1.0.0
EOF

  # Create Go project files
  cat > go-project/go.mod << 'EOF'
module test-go-project

go 1.21

require (
  github.com/stretchr/testify v1.8.4
)
EOF

  cat > go-project/cmd/main.go << 'EOF'
package main

import "fmt"
import "test-go-project/internal/greeter"

func main() {
  fmt.Println(greeter.Hello("World"))
}
EOF

  mkdir -p go-project/internal/greeter
  cat > go-project/internal/greeter/greeter.go << 'EOF'
package greeter

import "fmt"

func Hello(name string) string {
  return fmt.Sprintf("Hello, %s!", name)
}
EOF

  cat > go-project/internal/greeter/greeter_test.go << 'EOF'
package greeter

import (
  "testing"
)

func TestHello(t *testing.T) {
  expected := "Hello, World!"
  actual := Hello("World")

  if actual != expected {
    t.Errorf("Expected %q, got %q", expected, actual)
  }
}
EOF

  # Create Rust project files
  cat > rust-project/Cargo.toml << 'EOF'
[package]
name = "test-rust-project"
version = "1.0.0"
edition = "2021"

[dependencies]

[dev-dependencies]
EOF

  cat > rust-project/src/main.rs << 'EOF`
fn main() {
    let message = greeter::hello("World");
    println!("{}", message);
}

pub mod greeter {
    pub fn hello(name: &str) -> String {
        format!("Hello, {}!", name)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_hello() {
        assert_eq!(greeter::hello("World"), "Hello, World!");
    }
}
EOF

  # Create generic project files
  cat > generic-project/Makefile << 'EOF'
.PHONY: build test lint clean

build:
	@echo "Building generic project..."
	@mkdir -p dist
	@echo "Build complete" > dist/build.log

test:
	@echo "Running tests..."
	@mkdir -p dist
	@echo "Tests passed" > dist/test.log

lint:
	@echo "Running lints..."
	@mkdir -p dist
	@echo "Linting passed" > dist/lint.log

clean:
	@echo "Cleaning project..."
	@rm -rf dist
EOF

  # Set project type environment variable
  export PROJECT_TYPE="nodejs"
  export PROJECT_ROOT="/tmp/compile-test/nodejs-project"
}

# Cleanup test environment
cleanup_test_environment() {
  cd - >/dev/null
  rm -rf "/tmp/compile-test"
}

# Mock build tools
mock_build_tools() {
  # Mock common build commands
  tsc() {
    echo "TypeScript compilation simulated"
    echo "Compiled 2 files successfully"
  }

  npm() {
    case "$1" in
      "install")
        echo "Installing npm dependencies..."
        echo "Dependencies installed successfully"
        ;;
      "run")
        case "$2" in
          "build")
            tsc
            ;;
          "type-check")
            echo "Type checking..."
            echo "Type check passed"
            ;;
          *)
            echo "Running npm $2..."
            ;;
        esac
        ;;
      *)
        echo "npm $* command simulated"
        ;;
    esac
  }

  python() {
    case "$1" in
      "-m"*)
        echo "Python $2 simulated"
        ;;
      *)
        echo "Python command simulated"
        ;;
    esac
  }

  pip() {
    echo "pip $* simulated"
  }

  go() {
    case "$1" in
      "build")
        echo "Go build simulated"
        echo "Build successful"
        ;;
      "test")
        echo "Go tests simulated"
        echo "All tests passed"
        ;;
      "mod")
        echo "Go mod $2 simulated"
        ;;
      *)
        echo "go $* command simulated"
        ;;
    esac
  }

  cargo() {
    case "$1" in
      "build")
        echo "Rust build simulated"
        echo "Build successful"
        ;;
      "test")
        echo "Rust tests simulated"
        echo "All tests passed"
        ;;
      "check")
        echo "Rust check simulated"
        echo "Check passed"
        ;;
      *)
        echo "cargo $* command simulated"
        ;;
    esac
  }

  make() {
    case "$1" in
      "build"|"test"|"lint"|"clean")
        echo "make $1 simulated"
        ;;
      *)
        echo "make $* command simulated"
        ;;
    esac
  }
}

# Mock logging functions
mock_logging_functions() {
  log_info() {
    echo "[INFO] $*"
  }

  log_success() {
    echo "[SUCCESS] $*"
  }

  log_error() {
    echo "[ERROR] $*" >&2
  }

  log_warn() {
    echo "[WARN] $*" >&2
  }

  log_debug() {
    echo "[DEBUG] $*" >&2
  }
}

Describe "CI Compile Script"
  BeforeEach "setup_test_environment"
  BeforeEach "mock_build_tools"
  BeforeEach "mock_logging_functions"
  AfterEach "cleanup_test_environment"

  Describe "Project type detection"
    Context "when detecting Node.js project"
      It "should identify Node.js project by package.json"
        When call detect_project_type "/tmp/compile-test/nodejs-project"
        The output should equal "nodejs"
      End

      It "should detect TypeScript configuration"
        When call detect_project_type "/tmp/compile-test/nodejs-project"
        The output should equal "nodejs"
      End
    End

    Context "when detecting Python project"
      BeforeEach "export PROJECT_ROOT=/tmp/compile-test/python-project"

      It "should identify Python project by pyproject.toml"
        When call detect_project_type "/tmp/compile-test/python-project"
        The output should equal "python"
      End

      It "should detect requirements.txt"
        When call detect_project_type "/tmp/compile-test/python-project"
        The output should equal "python"
      End
    End

    Context "when detecting Go project"
      BeforeEach "export PROJECT_ROOT=/tmp/compile-test/go-project"

      It "should identify Go project by go.mod"
        When call detect_project_type "/tmp/compile-test/go-project"
        The output should equal "go"
      End
    End

    Context "when detecting Rust project"
      BeforeEach "export PROJECT_ROOT=/tmp/compile-test/rust-project"

      It "should identify Rust project by Cargo.toml"
        When call detect_project_type "/tmp/compile-test/rust-project"
        The output should equal "rust"
      End
    End

    Context "when detecting generic project"
      BeforeEach "export PROJECT_ROOT=/tmp/compile-test/generic-project"

      It "should identify generic project by Makefile"
        When call detect_project_type "/tmp/compile-test/generic-project"
        The output should equal "generic"
      End
    End

    Context "when project type is not found"
      It "should return generic as fallback"
        When call detect_project_type "/tmp/compile-test/nonexistent"
        The output should equal "generic"
      End
    End
  End

  Describe "Compilation by project type"
    Context "when compiling Node.js project"
      It "should compile TypeScript project"
        When call compile_nodejs_project
        The output should include "TypeScript compilation simulated"
        The output should include "Compiled 2 files successfully"
      End

      It "should install dependencies first"
        When call compile_nodejs_project
        The output should include "Installing npm dependencies"
      End

      It "should run type checking"
        When call compile_nodejs_project
        The output should include "Type checking"
        The output should include "Type check passed"
      End
    End

    Context "when compiling Python project"
      BeforeEach "export PROJECT_ROOT=/tmp/compile-test/python-project"

      It "should compile Python project"
        When call compile_python_project
        The output should include "Python build simulated"
      End

      It "should install dependencies"
        When call compile_python_project
        The output should include "pip install simulated"
      End
    End

    Context "when compiling Go project"
      BeforeEach "export PROJECT_ROOT=/tmp/compile-test/go-project"

      It "should compile Go project"
        When call compile_go_project
        The output should include "Go build simulated"
        The output should include "Build successful"
      End

      It "should download dependencies"
        When call compile_go_project
        The output should include "Go mod download simulated"
      End
    End

    Context "when compiling Rust project"
      BeforeEach "export PROJECT_ROOT=/tmp/compile-test/rust-project"

      It "should compile Rust project"
        When call compile_rust_project
        The output should include "Rust build simulated"
        The output should include "Build successful"
      End

      It "should run cargo check"
        When call compile_rust_project
        The output should include "Rust check simulated"
        The output should include "Check passed"
      End
    End

    Context "when compiling generic project"
      BeforeEach "export PROJECT_ROOT=/tmp/compile-test/generic-project"

      It "should compile using Makefile"
        When call compile_generic_project
        The output should include "make build simulated"
      End
    End
  End

  Describe "Testability modes"
    Context "when in EXECUTE mode"
      BeforeEach "export COMPILE_MODE=EXECUTE"

      It "should actually compile the project"
        When call run_compile
        The output should include "🚀 EXECUTE: Compiling project"
        The output should include "TypeScript compilation simulated"
      End
    End

    Context "when in DRY_RUN mode"
      BeforeEach "export COMPILE_MODE=DRY_RUN"

      It "should simulate compilation without actual commands"
        When call run_compile
        The output should include "🔍 DRY_RUN: Would compile project"
        The output should not include "TypeScript compilation simulated"
      End
    End

    Context "when in PASS mode"
      BeforeEach "export COMPILE_MODE=PASS"

      It "should simulate successful compilation"
        When call run_compile
        The output should include "✅ PASS MODE: Compile simulated successfully"
        The output should not include "TypeScript compilation simulated"
      End
    End

    Context "when in FAIL mode"
      BeforeEach "export COMPILE_MODE=FAIL"

      It "should simulate compilation failure"
        When call run_compile
        The status should be failure
        The output should include "❌ FAIL MODE: Simulating compile failure"
        The output should not include "TypeScript compilation simulated"
      End
    End

    Context "when in SKIP mode"
      BeforeEach "export COMPILE_MODE=SKIP"

      It "should skip compilation"
        When call run_compile
        The output should include "⏭️ SKIP MODE: Compile skipped"
        The output should not include "TypeScript compilation simulated"
      End
    End

    Context "when in TIMEOUT mode"
      BeforeEach "export COMPILE_MODE=TIMEOUT"

      It "should simulate compilation timeout"
        When run timeout 2s run_compile
        The status should equal 124  # TIMEOUT exit code
        The output should include "⏰ TIMEOUT MODE: Simulating compile timeout"
      End
    End
  End

  Describe "Build artifact management"
    Context "when managing build artifacts"
      It "should create build directory"
        When call ensure_build_directory
        The directory "/tmp/compile-test/nodejs-project/dist" should exist
      End

      It "should generate build metadata"
        When call generate_build_metadata
        The file "/tmp/compile-test/nodejs-project/dist/build-metadata.json" should exist
      End

      It "should include build information in metadata"
        When call generate_build_metadata
        The contents of file "/tmp/compile-test/nodejs-project/dist/build-metadata.json" should include "build_timestamp"
        The contents of file "/tmp/compile-test/nodejs-project/dist/build-metadata.json" should include "project_type"
        The contents of file "/tmp/compile-test/nodejs-project/dist/build-metadata.json" should include "compile_mode"
      End
    End
  End

  Describe "Error handling"
    Context "when compilation fails"
      It "should handle compilation errors gracefully"
        # Mock tsc to fail
        tsc() {
          echo "TypeScript compilation failed" >&2
          return 1
        }

        When call compile_nodejs_project
        The status should be failure
        The output should include "Compilation failed"
      End
    End

    Context "when project directory doesn't exist"
      It "should handle missing directory gracefully"
        When call detect_project_type "/nonexistent/directory"
        The output should equal "generic"
      End
    End

    Context "when build tools are not available"
      BeforeEach "unset -f tsc npm"

      It "should handle missing tools gracefully"
        When call compile_nodejs_project
        The status should be failure
        The output should include "tsc is not available"
      End
    End
  End

  Describe "Main compilation function"
    Context "when running main compilation"
      It "should use auto-detected project type"
        BeforeEach "export COMPILE_MODE=EXECUTE"
        BeforeEach "export PROJECT_ROOT=/tmp/compile-test/nodejs-project"

        When call main
        The output should include "Compiling nodejs project"
        The output should include "TypeScript compilation simulated"
      End

      It "should respect manual project type override"
        BeforeEach "export COMPILE_MODE=EXECUTE"
        BeforeEach "export PROJECT_TYPE=python"
        BeforeEach "export PROJECT_ROOT=/tmp/compile-test/python-project"

        When call main
        The output should include "Compiling python project"
        The output should include "Python build simulated"
      End

      It "should generate comprehensive build report"
        BeforeEach "export COMPILE_MODE=EXECUTE"

        When call main
        The output should include "Compilation completed successfully"
        The output should include "Build artifacts created"
      End
    End
  End
End