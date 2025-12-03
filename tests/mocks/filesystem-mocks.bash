#!/usr/bin/env bash
# File System Mocks Library for BATS Testing
# Provides comprehensive filesystem setup patterns for different test scenarios

# Create standard project directory structure
create_project_structure() {
    local project_root="${1:-$PROJECT_ROOT}"
    local project_type="${2:-generic}"

    mkdir -p "$project_root"

    # Common directories
    mkdir -p "$project_root"/{src,lib,test,tests,docs,config,scripts}
    mkdir -p "$project_root"/{.secrets,.github/{workflows,pre-commit-reports}}
    mkdir -p "$project_root"/{dist,build,target,bin}
    mkdir -p "$project_root"/{environments/{staging,production,local,development}}

    # Create project-specific structure
    case "$project_type" in
        "node")
            create_nodejs_project_structure "$project_root"
            ;;
        "python")
            create_python_project_structure "$project_root"
            ;;
        "go")
            create_go_project_structure "$project_root"
            ;;
        "rust")
            create_rust_project_structure "$project_root"
            ;;
        "java")
            create_java_project_structure "$project_root"
            ;;
        "dotnet")
            create_dotnet_project_structure "$project_root"
            ;;
        "generic")
            create_generic_project_structure "$project_root"
            ;;
    esac
}

# Node.js Project Structure
create_nodejs_project_structure() {
    local project_root="$1"

    mkdir -p "$project_root"/{src,lib,test,tests,docs,scripts,config}
    mkdir -p "$project_root"/{dist,build,coverage,.nyc_output}
    mkdir -p "$project_root"/{node_modules,.vscode}

    # Create package.json
    cat > "$project_root/package.json" << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0",
  "description": "Test project for CI excellence",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "build": "webpack --mode production",
    "build:dev": "webpack --mode development",
    "lint": "eslint src/**/*.js",
    "lint:fix": "eslint src/**/*.js --fix",
    "format": "prettier --write src/**/*.js",
    "clean": "rm -rf dist build coverage .nyc_output"
  },
  "dependencies": {
    "express": "^4.18.0",
    "lodash": "^4.17.0"
  },
  "devDependencies": {
    "jest": "^29.0.0",
    "webpack": "^5.0.0",
    "eslint": "^8.0.0",
    "prettier": "^2.0.0"
  },
  "engines": {
    "node": ">=18.0.0",
    "npm": ">=8.0.0"
  }
}
EOF

    # Create package-lock.json for npm projects
    touch "$project_root/package-lock.json"

    # Create .gitignore
    cat > "$project_root/.gitignore" << 'EOF'
node_modules/
dist/
build/
coverage/
.nyc_output/
.env
.env.local
.env.production
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
EOF

    # Create .eslintrc.js
    cat > "$project_root/.eslintrc.js" << 'EOF'
module.exports = {
  env: {
    node: true,
    es2021: true,
    jest: true
  },
  extends: ['eslint:recommended'],
  parserOptions: {
    ecmaVersion: 12,
    sourceType: 'module'
  },
  rules: {
    'no-console': 'warn',
    'no-unused-vars': 'error'
  }
};
EOF

    # Create sample source file
    mkdir -p "$project_root/src"
    cat > "$project_root/src/index.js" << 'EOF'
#!/usr/bin/env node

const express = require('express');

const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({ message: 'Hello, World!' });
});

if (require.main === module) {
  app.listen(port, () => {
    console.log(`Server running on port ${port}`);
  });
}

module.exports = app;
EOF

    # Create sample test file
    mkdir -p "$project_root/test"
    cat > "$project_root/test/index.test.js" << 'EOF'
const request = require('supertest');
const app = require('../src/index');

describe('API Tests', () => {
  test('GET / should return hello message', async () => {
    const response = await request(app)
      .get('/')
      .expect(200);

    expect(response.body.message).toBe('Hello, World!');
  });
});
EOF
}

# Python Project Structure
create_python_project_structure() {
    local project_root="$1"

    mkdir -p "$project_root"/{src,lib,test,tests,docs,scripts,config}
    mkdir -p "$project_root"/{build,dist,.pytest_cache,htmlcov}
    mkdir -p "$project_root"/{venv,.venv}

    # Create requirements.txt
    cat > "$project_root/requirements.txt" << 'EOF'
Flask>=2.0.0
requests>=2.25.0
pytest>=7.0.0
black>=22.0.0
flake8>=5.0.0
EOF

    # Create requirements-dev.txt
    cat > "$project_root/requirements-dev.txt" << 'EOF'
-r requirements.txt
pytest-cov>=4.0.0
pytest-mock>=3.0.0
pre-commit>=2.0.0
mypy>=0.991
EOF

    # Create setup.py
    cat > "$project_root/setup.py" << 'EOF'
from setuptools import setup, find_packages

setup(
    name="test-project",
    version="1.0.0",
    description="Test project for CI excellence",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    python_requires=">=3.8",
    install_requires=[
        "Flask>=2.0.0",
        "requests>=2.25.0",
    ],
    extras_require={
        "dev": [
            "pytest>=7.0.0",
            "black>=22.0.0",
            "flake8>=5.0.0",
        ],
    },
)
EOF

    # Create pyproject.toml
    cat > "$project_root/pyproject.toml" << 'EOF'
[build-system]
requires = ["setuptools>=45", "wheel"]
build-backend = "setuptools.build_meta"

[tool.black]
line-length = 88
target-version = ['py38']

[tool.mypy]
python_version = "3.8"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
EOF

    # Create .gitignore
    cat > "$project_root/.gitignore" << 'EOF'
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
venv/
.venv/
.env
.coverage
htmlcov/
.pytest_cache/
.mypy_cache/
EOF

    # Create sample source file
    mkdir -p "$project_root/src"
    cat > "$project_root/src/app.py" << 'EOF'
#!/usr/bin/env python3

from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def hello():
    return jsonify({"message": "Hello, World!"})

@app.route('/health')
def health():
    return jsonify({"status": "healthy"})

if __name__ == '__main__':
    app.run(debug=True)
EOF

    # Create sample test file
    mkdir -p "$project_root/tests"
    cat > "$project_root/tests/test_app.py" << 'EOF'
import pytest
from src.app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_hello_endpoint(client):
    response = client.get('/')
    assert response.status_code == 200
    assert response.json['message'] == 'Hello, World!'

def test_health_endpoint(client):
    response = client.get('/health')
    assert response.status_code == 200
    assert response.json['status'] == 'healthy'
EOF
}

# Go Project Structure
create_go_project_structure() {
    local project_root="$1"
    local module_name="${2:-github.com/example/test}"

    mkdir -p "$project_root"/{cmd,internal,pkg,test,docs,scripts,configs}
    mkdir -p "$project_root"/{build,bin}

    # Create go.mod
    cat > "$project_root/go.mod" << EOF
module $module_name

go 1.21

require (
    github.com/gin-gonic/gin v1.9.1
    github.com/stretchr/testify v1.8.4
    gopkg.in/yaml.v3 v3.0.1
)
EOF

    # Create go.sum
    touch "$project_root/go.sum"

    # Create .gitignore
    cat > "$project_root/.gitignore" << 'EOF'
# Binaries for programs and plugins
*.exe
*.exe~
*.dll
*.so
*.dylib

# Test binary, built with go test -c
*.test

# Output of the go coverage tool, specifically when used with LiteIDE
*.out

# Dependency directories (remove the comment below to include it)
# vendor/

# Go workspace file
go.work

# Build directories
build/
bin/
EOF

    # Create main application
    mkdir -p "$project_root/cmd/server"
    cat > "$project_root/cmd/server/main.go" << 'EOF'
package main

import (
    "net/http"
    "github.com/gin-gonic/gin"
)

func main() {
    r := gin.Default()

    r.GET("/", func(c *gin.Context) {
        c.JSON(http.StatusOK, gin.H{
            "message": "Hello, World!",
        })
    })

    r.GET("/health", func(c *gin.Context) {
        c.JSON(http.StatusOK, gin.H{
            "status": "healthy",
        })
    })

    r.Run(":8080")
}
EOF

    # Create internal package
    mkdir -p "$project_root/internal/handlers"
    cat > "$project_root/internal/handlers/health.go" << 'EOF'
package handlers

import (
    "net/http"
    "github.com/gin-gonic/gin"
)

func HealthCheck(c *gin.Context) {
    c.JSON(http.StatusOK, gin.H{
        "status": "healthy",
        "service": "test-app",
    })
}
EOF

    # Create test file
    mkdir -p "$project_root/test"
    cat > "$project_root/test/server_test.go" << 'EOF'
package test

import (
    "net/http"
    "net/http/httptest"
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/gin-gonic/gin"
)

func TestHealthEndpoint(t *testing.T) {
    gin.SetMode(gin.TestMode)
    r := gin.Default()

    r.GET("/health", func(c *gin.Context) {
        c.JSON(http.StatusOK, gin.H{
            "status": "healthy",
        })
    })

    w := httptest.NewRecorder()
    req, _ := http.NewRequest("GET", "/health", nil)
    r.ServeHTTP(w, req)

    assert.Equal(t, http.StatusOK, w.Code)
    assert.Contains(t, w.Body.String(), "healthy")
}
EOF
}

# Rust Project Structure
create_rust_project_structure() {
    local project_root="$1"

    mkdir -p "$project_root"/{src,tests,benches,examples,docs,scripts}
    mkdir -p "$project_root"/{target,.cargo}

    # Create Cargo.toml
    cat > "$project_root/Cargo.toml" << 'EOF'
[package]
name = "test-project"
version = "0.1.0"
edition = "2021"
authors = ["Test Author <test@example.com>"]
description = "Test project for CI excellence"

[dependencies]
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
tokio = { version = "1.0", features = ["full"] }
warp = "0.3"

[dev-dependencies]
tokio-test = "0.4"
criterion = "0.5"

[[bin]]
name = "main"
path = "src/main.rs"

[lib]
name = "test_project"
path = "src/lib.rs"
EOF

    # Create .gitignore
    cat > "$project_root/.gitignore" << 'EOF'
# Generated by Cargo
/target/

# IDE and editor files
.idea/
.vscode/
*.swp
*.swo

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db
EOF

    # Create main.rs
    cat > "$project_root/src/main.rs" << 'EOF'
use warp::Filter;
use serde_json::json;

#[tokio::main]
async fn main() {
    let health = warp::path("health")
        .and(warp::get())
        .map(|| {
            warp::reply::json(&json!({
                "status": "healthy",
                "service": "test-app"
            }))
        });

    let index = warp::path::end()
        .and(warp::get())
        .map(|| {
            warp::reply::json(&json!({
                "message": "Hello, World!"
            }))
        });

    let routes = health.or(index);

    warp::serve(routes)
        .run(([127, 0, 0, 1], 3030))
        .await;
}
EOF

    # Create lib.rs
    cat > "$project_root/src/lib.rs" << 'EOF'
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct HealthResponse {
    pub status: String,
    pub service: String,
}

pub fn create_health_response() -> HealthResponse {
    HealthResponse {
        status: "healthy".to_string(),
        service: "test-app".to_string(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_create_health_response() {
        let response = create_health_response();
        assert_eq!(response.status, "healthy");
        assert_eq!(response.service, "test-app");
    }
}
EOF
}

# Java Project Structure (Maven)
create_java_project_structure() {
    local project_root="$1"

    mkdir -p "$project_root"/{src/main/java/com/example,test,docs,scripts}
    mkdir -p "$project_root"/{src/main/resources,src/test/java/com/example}
    mkdir -p "$project_root"/{target,.mvn}

    # Create pom.xml
    cat > "$project_root/pom.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example</groupId>
    <artifactId>test-project</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>

    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <junit.version>5.9.0</junit.version>
        <spring.boot.version>2.7.0</spring.boot.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
            <version>${spring.boot.version}</version>
        </dependency>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter</artifactId>
            <version>${junit.version}</version>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <version>${spring.boot.version}</version>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>3.0.0-M7</version>
            </plugin>
        </plugins>
    </build>
</project>
EOF

    # Create .gitignore
    cat > "$project_root/.gitignore" << 'EOF'
target/
!.mvn/wrapper/maven-wrapper.jar
!**/src/main/**/target/
!**/src/test/**/target/

### STS ###
.apt_generated
.classpath
.factorypath
.project
.settings
.springBeans
.sts4-cache

### IntelliJ IDEA ###
.idea
*.iws
*.iml
*.ipr

### NetBeans ###
/nbproject/private/
/nbbuild/
/dist/
/nbdist/
/.nb-gradle/
build/
!**/src/main/**/build/
!**/src/test/**/build/
EOF

    # Create main Java class
    mkdir -p "$project_root/src/main/java/com/example"
    cat > "$project_root/src/main/java/com/example/Application.java" << 'EOF'
package com.example;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.http.ResponseEntity;
import java.util.HashMap;
import java.util.Map;

@SpringBootApplication
@RestController
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

    @GetMapping("/")
    public ResponseEntity<Map<String, String>> index() {
        Map<String, String> response = new HashMap<>();
        response.put("message", "Hello, World!");
        return ResponseEntity.ok(response);
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "healthy");
        response.put("service", "test-app");
        return ResponseEntity.ok(response);
    }
}
EOF

    # Create test class
    mkdir -p "$project_root/src/test/java/com/example"
    cat > "$project_root/src/test/java/com/example/ApplicationTest.java" << 'EOF'
package com.example;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.ResponseEntity;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class ApplicationTest {

    @LocalServerPort
    private int port;

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    void testIndexEndpoint() {
        ResponseEntity<Map> response = restTemplate.getForEntity(
            "http://localhost:" + port + "/", Map.class);

        assertEquals(200, response.getStatusCodeValue());
        assertEquals("Hello, World!", response.getBody().get("message"));
    }

    @Test
    void testHealthEndpoint() {
        ResponseEntity<Map> response = restTemplate.getForEntity(
            "http://localhost:" + port + "/health", Map.class);

        assertEquals(200, response.getStatusCodeValue());
        assertEquals("healthy", response.getBody().get("status"));
    }
}
EOF
}

# Generic Project Structure
create_generic_project_structure() {
    local project_root="$1"

    # Create README.md
    cat > "$project_root/README.md" << 'EOF'
# Test Project

This is a test project for CI excellence demonstration.

## Features

- Automated CI/CD pipeline
- Comprehensive testing
- Security scanning
- Deployment automation

## Getting Started

1. Clone the repository
2. Install dependencies
3. Run tests
4. Deploy

## License

MIT
EOF

    # Create .gitignore
    cat > "$project_root/.gitignore" << 'EOF'
# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE files
.idea/
.vscode/
*.swp
*.swo

# Build outputs
build/
dist/
target/
bin/

# Logs
*.log
logs/

# Environment files
.env
.env.local
.env.production
EOF

    # Create LICENSE
    cat > "$project_root/LICENSE" << 'EOF'
MIT License

Copyright (c) 2024 Test Project

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
EOF
}

# Create configuration files for CI/CD tools
create_ci_configuration_files() {
    local project_root="${1:-$PROJECT_ROOT}"

    # Create .mise.toml
    cat > "$project_root/.mise.toml" << 'EOF'
[env]
CI = "true"
GITHUB_ACTIONS = "true"

[tools]
node = "18.17.0"
python = "3.11.0"
go = "1.21.0"
rust = "1.73.0"
java = "17.0.0"
bash = "5.0.0"

[tasks]
test = "echo 'Running tests'"
lint = "echo 'Running linting'"
build = "echo 'Building project'"
deploy = "echo 'Deploying application'"
EOF

    # Create .gitleaks.toml
    cat > "$project_root/.gitleaks.toml" << 'EOF'
title = "Gitleaks configuration"

[[rules]]
description = "GitHub token"
id = "github-token"
regex = '''ghp_[0-9a-zA-Z]{36}'''
keywords = ["ghp_"]

[[rules]]
description = "AWS Access Key"
id = "aws-access-key"
regex = '''AKIA[0-9A-Z]{16}'''
keywords = ["AKIA"]

[[rules]]
description = "AWS Secret Key"
id = "aws-secret-key"
regex = '''[0-9a-zA-Z/+]{40}'''
keywords = ["AWS secret"]

[allowlist]
description = "global allow lists"
paths = [
    '''gitleaks.toml''',
    '''test/''',
    '''\.git/''',
]
EOF

    # Create .shfmt.toml
    cat > "$project_root/.shfmt.toml" << 'EOF'
indent = 2
binary_next_line = true
case_indent = true
space_redirects = true
EOF

    # Create pre-commit configuration
    mkdir -p "$project_root/.github/workflows"
    cat > "$project_root/.github/workflows/ci.yml" << 'EOF'
name: CI Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Setup mise
      uses: jdx/mise-action@v2
    - name: Run tests
      run: mise run test
    - name: Run linting
      run: mise run lint
    - name: Build project
      run: mise run build
EOF
}

# Cleanup filesystem mocks
cleanup_filesystem_mocks() {
    local project_root="${1:-$PROJECT_ROOT}"

    # Remove project directories if they exist
    if [[ -d "$project_root" ]]; then
        rm -rf "$project_root"
    fi

    # Remove mock scripts if they exist
    if [[ -d "$BATS_TEST_TMPDIR/scripts" ]]; then
        rm -rf "$BATS_TEST_TMPDIR/scripts"
    fi
}