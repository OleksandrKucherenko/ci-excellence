# GEMINI.md

## Project Overview

This project is a comprehensive and production-ready CI/CD pipeline framework called "CI Pipeline Excellence". It is designed to be highly modular, testable, and secure, with a focus on providing a consistent and reliable software delivery process.

The framework is built using a combination of GitHub Actions and shell scripts, with `mise` used for managing project dependencies and tasks. It supports a wide range of project types and provides a rich set of features, including:

*   **Advanced Git Tagging:** A three-tier tag system for managing versions, environments, and states.
*   **Multi-Environment Management:** Hierarchical configuration for different deployment environments, with support for encrypted secrets using SOPS.
*   **Testable DRY Scripts:** All pipeline logic is encapsulated in standalone, testable shell scripts.
*   **Enhanced Quality Gates:** Integrated security scanning, linting, and commit message enforcement.
*   **Self-Healing Pipeline:** Automated code formatting and lint fixing.

## Building and Running

The project uses `mise` to manage tasks and dependencies. The following commands are essential for working with this project:

*   **Install dependencies:**
    ```bash
    mise install
    ```
*   **Run all tests:**
    ```bash
    mise run test
    ```
*   **Lint all shell scripts:**
    ```bash
    mise run lint
    ```
*   **Format all shell scripts:**
    ```bash
    mise run format
    ```
*   **Run a pre-release pipeline locally:**
    ```bash
    act -j pre-release
    ```

## Development Conventions

The project follows a number of development conventions to ensure code quality and consistency:

*   **Conventional Commits:** All commit messages must follow the Conventional Commits specification.
*   **Shell Scripting Best Practices:** Shell scripts should be well-documented, modular, and testable. The project uses `shellcheck` for linting and `shfmt` for formatting.
*   **Git Hooks:** The project uses `lefthook` to manage Git hooks, which automatically run checks before committing and pushing code.
*   **Testability:** All scripts are designed to be testable, with a hierarchical system for controlling script behavior using environment variables.
