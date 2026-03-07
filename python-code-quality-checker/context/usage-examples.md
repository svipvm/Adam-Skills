# Python Code Quality Checker - Usage Examples

This document provides comprehensive usage examples for the Python Code Quality Checker skill, covering basic to advanced scenarios.

## Table of Contents

- [Basic Usage](#basic-usage)
- [Checking Entire Projects](#checking-entire-projects)
- [Using Specific Tools](#using-specific-tools)
- [Auto-Fixing Issues](#auto-fixing-issues)
- [Generating Reports](#generating-reports)
- [Configuring Strictness Levels](#configuring-strictness-levels)
- [CI/CD Integration](#cicd-integration)
- [IDE Integration](#ide-integration)
- [Advanced Scenarios](#advanced-scenarios)

---

## Basic Usage

### Check a Single File

**Natural Language Request:**
```
Check the quality of src/main.py
```

**What Happens:**
1. Syntax validation runs on the file
2. Type checking with mypy (if configured)
3. Linting with configured linters (ruff by default)
4. Results displayed with severity levels

**Expected Output:**
```
Python Code Quality Check Results
==================================

File: src/main.py

✓ Syntax: Valid
✓ Type Checking: No issues found
⚠ Linting: 3 warnings found

Issues:
  Line 15: W293 blank line contains whitespace
  Line 23: E501 line too long (105 > 100 characters)
  Line 45: F401 'os' imported but unused

Summary: 0 errors, 3 warnings, 0 info
```

### Check Current File in IDE

**Natural Language Request:**
```
Check Python code quality in the current file
```

**What Happens:**
The skill automatically detects the current file and runs all configured checks.

---

## Checking Entire Projects

### Check All Python Files in a Directory

**Natural Language Request:**
```
Check all Python files in the src/ directory
```

**What Happens:**
1. Recursively finds all `.py` files in `src/`
2. Runs checks in parallel (configurable)
3. Aggregates results with file-by-file breakdown

**Expected Output:**
```
Python Code Quality Check Results
==================================

Directory: src/
Files checked: 45
Total issues: 127

Breakdown by file:
  src/main.py: 3 warnings
  src/utils.py: 5 errors, 2 warnings
  src/api/handlers.py: 12 warnings
  ...

Breakdown by severity:
  Errors: 5
  Warnings: 98
  Info: 24

Top issue categories:
  1. Unused imports (F401): 34 occurrences
  2. Line too long (E501): 28 occurrences
  3. Missing docstrings (D100): 24 occurrences
```

### Check Entire Project

**Natural Language Request:**
```
Run a full quality check on the entire project
```

**What Happens:**
1. Scans all Python files in the project root
2. Respects exclude patterns (venv, build, etc.)
3. Runs all configured tools
4. Generates comprehensive report

### Check Specific File Patterns

**Natural Language Request:**
```
Check quality on all test files in the tests/ directory
```

**What Happens:**
Checks only files matching the specified pattern, applying test-specific rules if configured.

---

## Using Specific Tools

### Run Type Checking Only

**Natural Language Request:**
```
Run mypy type checking on src/
```

**What Happens:**
1. Runs only mypy type checker
2. Uses mypy configuration from `.mypy.ini` or `pyproject.toml`
3. Reports type errors and warnings

**Expected Output:**
```
Mypy Type Checking Results
===========================

Files checked: 45
Type errors: 12
Type warnings: 8

Issues:
  src/models.py:15: error: Incompatible types in assignment
  src/api.py:34: error: Argument 1 has incompatible type
  src/utils.py:78: warning: Unused 'type: ignore' comment
```

### Run Specific Linter

**Natural Language Request:**
```
Run pylint on the authentication module
```

**What Happens:**
1. Runs only pylint on specified files
2. Uses pylint configuration
3. Reports all pylint findings

### Run Multiple Specific Tools

**Natural Language Request:**
```
Run ruff and mypy on the src/api/ directory
```

**What Happens:**
1. Runs both ruff and mypy
2. Combines results from both tools
3. Deduplicates overlapping issues

### Run All Configured Tools

**Natural Language Request:**
```
Run all configured quality checks on the project
```

**What Happens:**
Runs all tools specified in configuration (mypy, pylint, flake8, ruff, etc.)

---

## Auto-Fixing Issues

### Fix All Auto-Fixable Issues

**Natural Language Request:**
```
Fix all auto-fixable Python code issues
```

**What Happens:**
1. Identifies all auto-fixable issues
2. Creates backups of original files
3. Applies fixes using appropriate tools
4. Generates summary of changes

**Expected Output:**
```
Auto-Fix Results
================

Files modified: 12
Issues fixed: 45
Backups created in: .quality-checker-backups/

Fixes applied:
  ✓ Removed 23 unused imports
  ✓ Fixed 15 whitespace issues
  ✓ Sorted imports in 8 files
  ✓ Reformatted 4 files with black

Files modified:
  src/main.py (5 fixes)
  src/utils.py (8 fixes)
  src/api/handlers.py (12 fixes)
  ...

Review changes before committing!
```

### Fix Issues in Specific File

**Natural Language Request:**
```
Fix auto-fixable issues in src/main.py
```

**What Happens:**
Applies fixes only to the specified file, creating a backup first.

### Fix Specific Issue Types

**Natural Language Request:**
```
Fix all import sorting issues in the project
```

**What Happens:**
1. Identifies all import sorting issues
2. Uses isort to fix them
3. Reports changes made

### Preview Fixes Without Applying

**Natural Language Request:**
```
Show what fixes would be applied without making changes
```

**What Happens:**
1. Runs tools in dry-run mode
2. Shows diff of proposed changes
3. No files are modified

**Expected Output:**
```
Proposed Fixes (Dry Run)
========================

File: src/main.py
  Line 5-10: Sort imports
    - import os
    - import sys
    - from typing import List
    + import os
    + import sys
    + from typing import List

  Line 45: Remove unused import 'json'
    - import json
    + (removed)

Total changes: 12
Run with --apply to apply these changes.
```

### Rollback Fixes

**Natural Language Request:**
```
Rollback the last auto-fix changes
```

**What Happens:**
1. Restores files from backup
2. Removes backup files
3. Reports restored files

---

## Generating Reports

### Generate Text Report

**Natural Language Request:**
```
Generate a quality report for the project
```

**Expected Output:**
```
Python Code Quality Report
===========================

Project: myproject
Date: 2024-01-15 14:30:00
Duration: 12.5 seconds

Summary
-------
Files checked: 156
Total issues: 234

By Severity:
  Critical: 2
  Error: 15
  Warning: 178
  Info: 39

By Category:
  Code Style: 89 (38%)
  Type Safety: 45 (19%)
  Complexity: 34 (15%)
  Documentation: 28 (12%)
  Security: 18 (8%)
  Other: 20 (8%)

Top 10 Issues:
  1. E501 - Line too long: 34 occurrences
  2. F401 - Unused import: 28 occurrences
  3. D100 - Missing docstring: 24 occurrences
  4. W293 - Blank line whitespace: 19 occurrences
  ...

Files with Most Issues:
  1. src/legacy.py: 45 issues
  2. src/api.py: 32 issues
  3. src/utils.py: 28 issues
```

### Generate JSON Report

**Natural Language Request:**
```
Generate a JSON quality report
```

**Expected Output:**
```json
{
  "project": "myproject",
  "timestamp": "2024-01-15T14:30:00",
  "duration_seconds": 12.5,
  "summary": {
    "files_checked": 156,
    "total_issues": 234,
    "by_severity": {
      "critical": 2,
      "error": 15,
      "warning": 178,
      "info": 39
    }
  },
  "issues": [
    {
      "file": "src/main.py",
      "line": 15,
      "column": 1,
      "severity": "warning",
      "code": "E501",
      "message": "Line too long",
      "tool": "ruff"
    }
  ]
}
```

### Generate HTML Report

**Natural Language Request:**
```
Generate an HTML quality report
```

**What Happens:**
Creates a visually formatted HTML report with:
- Summary dashboard
- Interactive issue browser
- File-by-file breakdown
- Trend charts (if historical data available)

### Generate JUnit XML Report

**Natural Language Request:**
```
Generate a JUnit XML report for CI
```

**What Happens:**
Creates a JUnit-compatible XML report for integration with CI systems.

**Expected Output:**
```xml
<?xml version="1.0" encoding="utf-8"?>
<testsuites>
  <testsuite name="python-quality-check" tests="156" failures="234">
    <testcase name="src/main.py">
      <failure message="E501 Line too long">
        Line 15: Line too long (105 > 100 characters)
      </failure>
    </testcase>
  </testsuite>
</testsuites>
```

### Generate GitHub Actions Report

**Natural Language Request:**
```
Generate a GitHub Actions quality report
```

**What Happens:**
Creates GitHub Actions annotations for display in PR checks.

**Expected Output:**
```
::warning file=src/main.py,line=15::E501 Line too long (105 > 100 characters)
::error file=src/utils.py,line=34::F821 Undefined name 'config'
```

### Generate SARIF Report

**Natural Language Request:**
```
Generate a SARIF report for security scanning
```

**What Happens:**
Creates a SARIF (Static Analysis Results Interchange Format) report for integration with security tools like GitHub Advanced Security.

---

## Configuring Strictness Levels

### Use Relaxed Strictness

**Natural Language Request:**
```
Check code quality with relaxed strictness
```

**What Happens:**
- Higher thresholds (line length: 120, complexity: 15)
- Fewer rules enforced
- Suitable for prototypes and scripts

**Configuration Applied:**
```yaml
strictness: relaxed
rules:
  max_line_length: 120
  max_complexity: 15
mypy:
  strict: false
  ignore_missing_imports: true
```

### Use Normal Strictness (Default)

**Natural Language Request:**
```
Check code quality with normal strictness
```

**What Happens:**
- Balanced thresholds (line length: 100, complexity: 10)
- Essential rules enforced
- Suitable for most production code

### Use Strict Strictness

**Natural Language Request:**
```
Check code quality with strict settings
```

**What Happens:**
- Lower thresholds (line length: 88, complexity: 8)
- Comprehensive rules enforced
- Strict type checking enabled
- Suitable for libraries and critical systems

**Configuration Applied:**
```yaml
strictness: strict
rules:
  max_line_length: 88
  max_complexity: 8
mypy:
  strict: true
  disallow_untyped_defs: true
```

### Use Very Strict Strictness

**Natural Language Request:**
```
Check code quality with very strict settings
```

**What Happens:**
- Minimal thresholds (line length: 88, complexity: 5)
- All rules enforced
- Maximum type safety
- Suitable for security-critical code

### Custom Strictness Profile

**Natural Language Request:**
```
Check with custom strictness: max line length 95, complexity 8
```

**What Happens:**
Overrides specific rules while keeping other settings at default.

---

## CI/CD Integration

### GitHub Actions Integration

**Natural Language Request:**
```
Set up GitHub Actions integration for quality checks
```

**What Happens:**
Creates or updates `.github/workflows/python-quality.yml`:

```yaml
name: Python Quality Check

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  quality-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.10'
          cache: 'pip'
      
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install mypy pylint flake8 ruff black isort
          pip install -r requirements.txt
      
      - name: Run Ruff
        run: ruff check --output-format=github .
      
      - name: Run Mypy
        run: mypy src/ --ignore-missing-imports
      
      - name: Run Pylint
        run: pylint --output-format=github src/
        continue-on-error: true
      
      - name: Run Black check
        run: black --check .
      
      - name: Run isort check
        run: isort --check-only .
```

### GitLab CI Integration

**Natural Language Request:**
```
Set up GitLab CI integration for quality checks
```

**What Happens:**
Creates or updates `.gitlab-ci.yml`:

```yaml
python-quality:
  image: python:3.10
  stage: test
  before_script:
    - pip install mypy pylint flake8 ruff black isort
    - pip install -r requirements.txt
  script:
    - ruff check --output-format=gitlab .
    - mypy src/
    - pylint --exit-zero src/
    - black --check .
    - isort --check-only .
  artifacts:
    reports:
      codequality: gl-code-quality-report.json
```

### Pre-commit Hooks Integration

**Natural Language Request:**
```
Set up pre-commit hooks for quality checks
```

**What Happens:**
Creates or updates `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.2.0
    hooks:
      - id: ruff
        args: [--fix, --exit-non-zero-on-fix]
      - id: ruff-format

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.8.0
    hooks:
      - id: mypy
        additional_dependencies: [types-all]
        args: [--ignore-missing-imports]

  - repo: https://github.com/pycqa/flake8
    rev: 7.0.0
    hooks:
      - id: flake8
        additional_dependencies:
          - flake8-bugbear
          - flake8-comprehensions

  - repo: https://github.com/psf/black
    rev: 24.1.0
    hooks:
      - id: black

  - repo: https://github.com/pycqa/isort
    rev: 5.13.0
    hooks:
      - id: isort
```

### Jenkins Pipeline Integration

**Natural Language Request:**
```
Set up Jenkins pipeline integration for quality checks
```

**What Happens:**
Provides Jenkinsfile snippet:

```groovy
pipeline {
    agent any
    
    stages {
        stage('Setup') {
            steps {
                sh 'python -m pip install --upgrade pip'
                sh 'pip install mypy pylint flake8 ruff black isort'
                sh 'pip install -r requirements.txt'
            }
        }
        
        stage('Quality Check') {
            parallel {
                stage('Ruff') {
                    steps {
                        sh 'ruff check --output-format=json . > ruff-report.json || true'
                    }
                }
                
                stage('Mypy') {
                    steps {
                        sh 'mypy src/ --no-error-summary || true'
                    }
                }
                
                stage('Pylint') {
                    steps {
                        sh 'pylint --output-format=json src/ > pylint-report.json || true'
                    }
                }
                
                stage('Formatting') {
                    steps {
                        sh 'black --check .'
                        sh 'isort --check-only .'
                    }
                }
            }
        }
    }
    
    post {
        always {
            archiveArtifacts artifacts: '*-report.json', fingerprint: true
        }
    }
}
```

### Run Checks on Changed Files Only

**Natural Language Request:**
```
Run quality checks only on files changed in this PR
```

**What Happens:**
1. Detects changed files from git diff
2. Runs checks only on those files
3. Faster feedback for large projects

---

## IDE Integration

### VS Code Integration

**Natural Language Request:**
```
Set up VS Code integration for quality checks
```

**What Happens:**
Creates or updates `.vscode/settings.json`:

```json
{
  "python.linting.enabled": true,
  "python.linting.pylintEnabled": true,
  "python.linting.flake8Enabled": true,
  "python.linting.mypyEnabled": true,
  "python.formatting.provider": "black",
  "editor.formatOnSave": true,
  "python.linting.lintOnSave": true,
  "[python]": {
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.organizeImports": true
    }
  }
}
```

Creates or updates `.vscode/extensions.json`:

```json
{
  "recommendations": [
    "ms-python.python",
    "ms-python.vscode-pylance",
    "charliermarsh.ruff",
    "ms-python.mypy-type-checker"
  ]
}
```

### PyCharm Integration

**Natural Language Request:**
```
Set up PyCharm integration for quality checks
```

**What Happens:**
Provides instructions for:
1. Enabling Pylint integration
2. Configuring MyPy as external tool
3. Setting up Black as file watcher
4. Configuring isort

### Vim/Neovim Integration

**Natural Language Request:**
```
Set up Vim integration for quality checks
```

**What Happens:**
Provides configuration for popular plugins:
- ALE (Asynchronous Lint Engine)
- nvim-lspconfig
- null-ls

### Emacs Integration

**Natural Language Request:**
```
Set up Emacs integration for quality checks
```

**What Happens:**
Provides configuration for:
- flycheck
- lsp-mode
- blacken-mode

---

## Advanced Scenarios

### Check with Custom Configuration File

**Natural Language Request:**
```
Check quality using custom config file at config/strict-quality.yaml
```

**What Happens:**
1. Loads configuration from specified path
2. Applies all settings from that file
3. Runs checks accordingly

### Check Specific Code Patterns

**Natural Language Request:**
```
Check for security issues in the authentication module
```

**What Happens:**
1. Enables security-focused rules
2. Runs checks on specified module
3. Reports security-relevant findings

### Compare Quality Between Branches

**Natural Language Request:**
```
Compare code quality between main and feature branches
```

**What Happens:**
1. Runs checks on both branches
2. Compares issue counts and types
3. Reports quality delta

**Expected Output:**
```
Quality Comparison Report
=========================

Branch: main vs feature/new-auth

main branch:
  Total issues: 234
  Errors: 15
  Warnings: 178

feature/new-auth branch:
  Total issues: 256
  Errors: 18
  Warnings: 195

Changes:
  +22 total issues (+9.4%)
  +3 errors (+20%)
  +17 warnings (+9.6%)

New issues in feature branch:
  src/auth.py:45: E501 Line too long (NEW)
  src/auth.py:78: B106 Hardcoded password (NEW)
```

### Generate Quality Metrics Over Time

**Natural Language Request:**
```
Generate quality metrics trend for the last 30 days
```

**What Happens:**
1. Analyzes historical quality data
2. Generates trend charts
3. Identifies patterns

**Expected Output:**
```
Quality Metrics Trend (Last 30 Days)
=====================================

Total Issues:
  Day 1:  234 ████████████████████████
  Day 7:  221 ██████████████████████▊
  Day 14: 198 ████████████████████▊
  Day 21: 187 ███████████████████▊
  Day 30: 156 ████████████████▊

Trend: ↓ 33.3% improvement

Error Rate:
  Started: 6.4% (15 errors)
  Current: 4.5% (7 errors)
  Trend: ↓ 29.7% improvement

Top Improvements:
  ✓ Reduced unused imports by 45%
  ✓ Fixed all hardcoded passwords
  ✓ Improved type coverage from 72% to 89%
```

### Check with Incremental Mode

**Natural Language Request:**
```
Run quality checks in incremental mode using cache
```

**What Happens:**
1. Uses cached results from previous runs
2. Only checks changed files
3. Significantly faster for large projects

### Parallel Execution

**Natural Language Request:**
```
Run quality checks with 8 parallel processes
```

**What Happens:**
1. Distributes work across multiple processes
2. Runs tools in parallel where possible
3. Aggregates results

### Exclude Specific Files or Patterns

**Natural Language Request:**
```
Check quality but exclude generated files and migrations
```

**What Happens:**
1. Respects exclude patterns
2. Skips specified files/directories
3. Reports on remaining files

### Check with Different Python Versions

**Natural Language Request:**
```
Check quality for Python 3.8 compatibility
```

**What Happens:**
1. Sets target Python version to 3.8
2. Checks for version-specific issues
3. Reports compatibility problems

### Validate Configuration

**Natural Language Request:**
```
Validate the quality checker configuration
```

**What Happens:**
1. Checks configuration file syntax
2. Validates all settings
3. Reports errors and warnings

**Expected Output:**
```
Configuration Validation
========================

File: .python-quality-checker.yaml
Status: ✓ Valid

Warnings:
  - Line 45: Unknown linter 'pyflakes', did you mean 'flake8'?
  - Line 67: 'max_complexity' is very low (3), may cause many warnings

Suggestions:
  - Consider adding 'mypy.plugins = ["mypy_django_plugin.main"]' for Django
  - Enable 'strict' mode for better type safety
```

### Export Configuration

**Natural Language Request:**
```
Export the current quality configuration to pyproject.toml
```

**What Happens:**
1. Reads current configuration
2. Converts to TOML format
3. Writes to pyproject.toml

---

## Best Practices

### 1. Start Simple, Then Customize

```
# Start with default configuration
Check Python code quality

# Then customize as needed
Configure max line length to 95
```

### 2. Use Auto-Fix Wisely

```
# Preview first
Show what fixes would be applied

# Then apply
Fix all auto-fixable issues

# Always review changes
```

### 3. Integrate Early in Development

```
# Set up pre-commit hooks
Set up pre-commit hooks for quality checks

# Run checks frequently
Check quality on changed files
```

### 4. Use Appropriate Strictness

```
# For prototypes
Check with relaxed strictness

# For production
Check with strict settings

# For critical systems
Check with very strict settings
```

### 5. Monitor Quality Over Time

```
# Generate regular reports
Generate quality report

# Track trends
Show quality metrics trend for last 30 days
```

---

## Troubleshooting Common Issues

### Issue: Too Many Warnings

**Request:**
```
The quality check shows too many warnings. How can I focus on important issues?
```

**Solution:**
```
Check quality with severity threshold error
```

### Issue: False Positives

**Request:**
```
Some reported issues are false positives. How can I suppress them?
```

**Solution:**
```
Add ignore rule for pattern "*/migrations/*" with codes ["E501", "D100"]
```

### Issue: Slow Performance

**Request:**
```
Quality checks are too slow on my large project.
```

**Solution:**
```
Run quality checks in incremental mode with cache
```

### Issue: Conflicting Tool Results

**Request:**
```
Different tools report conflicting issues.
```

**Solution:**
```
Run only ruff for consistency
```

---

## Quick Reference

| Task | Natural Language Request |
|------|-------------------------|
| Check single file | "Check quality of src/main.py" |
| Check project | "Run quality check on the project" |
| Fix issues | "Fix all auto-fixable issues" |
| Generate report | "Generate quality report" |
| Set strictness | "Check with strict settings" |
| CI setup | "Set up GitHub Actions integration" |
| IDE setup | "Set up VS Code integration" |
| Preview fixes | "Show what fixes would be applied" |
| Custom config | "Check using config/custom.yaml" |
| Validate config | "Validate quality configuration" |
