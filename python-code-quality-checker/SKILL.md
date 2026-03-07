---
name: "python-code-quality-checker"
description: "Comprehensive Python code quality checker with syntax detection, type checking, third-party tool integration, auto-trigger, intelligent error fixing, and multi-format reporting. Invoke when user needs to check Python code quality or fix code issues."
version: "1.0.0"

includes:
  - includes/syntax-checker.md
  - includes/type-checker.md
  - includes/tool-integration.md
  - includes/auto-trigger.md
  - includes/auto-fixer.md
  - includes/report-generator.md
  - includes/config-manager.md
  - includes/performance-optimizer.md
  - scripts/validate.sh
  - scripts/test.sh
  - scripts/install-tools.sh
  - context/usage-examples.md
  - context/configuration-guide.md
  - context/api-reference.md
performance:
  lazy_load: true
  cache: true
---

# Python Code Quality Checker

## Overview

The Python Code Quality Checker is a comprehensive skill designed to ensure your Python code meets the highest quality standards. It combines multiple analysis tools and techniques to detect syntax errors, type issues, style violations, and potential bugs, while providing intelligent auto-fixing capabilities.

## Core Features

- **Syntax Detection**: Real-time Python syntax validation and error detection
- **Type Checking**: Static type analysis using mypy and similar tools
- **Third-Party Tool Integration**: Seamless integration with popular linters (pylint, flake8, ruff)
- **Auto-Trigger**: Automatic quality checks on file save or modification
- **Intelligent Error Fixing**: Automated fixes for common issues with manual review options
- **Code Formatting**: Integration with black, isort, and autopep8
- **Customizable Rules**: Configurable rule sets for different project requirements
- **Detailed Reports**: Comprehensive reports with severity levels and fix suggestions

## Quick Start Guide

1. **Basic Quality Check**
   ```
   Check Python code quality in the current file
   ```

2. **Fix Issues Automatically**
   ```
   Fix all auto-fixable Python code issues
   ```

3. **Run Specific Checks**
   ```
   Run type checking on the project
   Run linting with pylint
   ```

4. **Configure Rules**
   ```
   Configure Python quality checker rules for this project
   ```

## Module Descriptions

### Includes Modules

- **syntax-checker.md**: Core syntax validation logic using Python AST for real-time error detection
- **type-checker.md**: Type annotation validation, type inference, and mypy integration
- **tool-integration.md**: Third-party tool configurations (mypy, pylint, flake8, ruff) with CI/CD integration
- **auto-trigger.md**: Automatic scanning triggers (time-based, event-based, hybrid) with async execution
- **auto-fixer.md**: Intelligent auto-fixing strategies with safety checks and rollback capabilities
- **report-generator.md**: Multi-format report generation (JSON, HTML, Markdown, text)
- **config-manager.md**: Flexible configuration management with multiple sources (YAML, TOML, INI, JSON)
- **performance-optimizer.md**: Incremental checking, parallel processing, and result caching

### Scripts

- **validate.sh**: Validates skill structure completeness
- **test.sh**: Tests skill functionality
- **install-tools.sh**: Installs required third-party tools (mypy, pylint, flake8, ruff)

### Context

- **usage-examples.md**: Practical usage examples and scenarios
- **configuration-guide.md**: Detailed configuration guide with examples
- **api-reference.md**: API reference for programmatic usage

## Configuration Options

### Basic Configuration

Create a `.python-quality.yaml` file in your project root:

```yaml
linters:
  - pylint
  - flake8
  - ruff

type_checker: mypy

formatters:
  - black
  - isort

auto_fix: true
severity_threshold: warning

exclude:
  - venv/
  - build/
  - dist/
```

### Advanced Configuration

```yaml
rules:
  max_line_length: 100
  max_complexity: 10
  
pylint:
  disable:
    - C0114
    - C0115
  
mypy:
  strict: true
  ignore_missing_imports: true

black:
  line_length: 100
  target_version: py39
```

## Usage Examples

### Example 1: Check Current File

```
Check the quality of src/main.py
```

The skill will:
1. Run syntax validation
2. Perform type checking
3. Execute configured linters
4. Generate a detailed report

### Example 2: Fix Project Issues

```
Fix all Python quality issues in the src/ directory
```

The skill will:
1. Scan all Python files in src/
2. Identify auto-fixable issues
3. Apply fixes with backup
4. Generate a fix summary

### Example 3: Custom Linter Configuration

```
Run ruff with custom rules on the authentication module
```

The skill will:
1. Load custom ruff configuration
2. Run checks on specified module
3. Report findings with suggestions

## Integration with Development Workflow

### Pre-commit Hooks

The skill can be integrated with pre-commit hooks to ensure code quality before commits:

```yaml
repos:
  - repo: local
    hooks:
      - id: python-quality-check
        name: Python Quality Check
        entry: python-quality-checker
        language: system
        types: [python]
```

### CI/CD Pipeline

Example GitHub Actions integration:

```yaml
- name: Python Quality Check
  run: |
    python -m python_quality_checker \
      --config .python-quality.yaml \
      --output-format json \
      --fail-on-error
```

## Error Severity Levels

- **Critical**: Syntax errors, type errors that will cause runtime failures
- **Error**: Issues that should be fixed (unused imports, undefined variables)
- **Warning**: Style issues and potential problems
- **Info**: Suggestions for code improvement

## Best Practices

1. Run quality checks early and often during development
2. Configure rules that match your team's coding standards
3. Review auto-fixed changes before committing
4. Use severity thresholds to focus on critical issues first
5. Keep linter and formatter versions consistent across the team

## Troubleshooting

### Common Issues

1. **False Positives**: Use inline comments to suppress specific rules
2. **Performance**: Enable caching and lazy loading for large projects
3. **Configuration Conflicts**: Ensure consistent configuration across tools

## Support

For issues and feature requests, refer to the skill documentation or create an issue in the project repository.
