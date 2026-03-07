# Python Code Quality Checker - File Index

## Directory Structure

```
python-code-quality-checker/
├── SKILL.md                    # Main skill definition and documentation
├── INDEX.md                    # This file - directory and file listing
├── includes/                   # Reusable module components
│   ├── syntax-checker.md       # Syntax validation module
│   ├── type-checker.md         # Type checking module
│   ├── tool-integration.md     # Third-party tool integration
│   ├── auto-trigger.md         # Automatic scanning triggers
│   ├── auto-fixer.md           # Auto-fixing strategies
│   ├── report-generator.md     # Multi-format report generation
│   ├── config-manager.md       # Configuration management
│   └── performance-optimizer.md # Performance optimization
├── scripts/                    # Executable scripts
│   ├── validate.sh             # Skill structure validation
│   ├── test.sh                 # Functionality testing
│   └── install-tools.sh        # Tool installation script
└── context/                    # Context and reference materials
    ├── usage-examples.md       # Usage examples
    ├── configuration-guide.md  # Configuration guide
    └── api-reference.md        # API reference
```

## Files by Category

### Core Files

| File | Purpose |
|------|---------|
| SKILL.md | Main skill definition with frontmatter, documentation, and usage guide |
| INDEX.md | File index and directory structure reference |

### Includes Modules

| File | Purpose |
|------|---------|
| includes/syntax-checker.md | Python AST-based syntax validation and error detection |
| includes/type-checker.md | Type annotation validation, type inference, and mypy integration |
| includes/tool-integration.md | Third-party tool configurations (mypy, pylint, flake8, ruff) |
| includes/auto-trigger.md | Automatic scanning triggers with async execution |
| includes/auto-fixer.md | Intelligent auto-fixing with safety checks and rollback |
| includes/report-generator.md | Multi-format report generation (JSON, HTML, Markdown, text) |
| includes/config-manager.md | Multi-source configuration management |
| includes/performance-optimizer.md | Incremental checking, parallel processing, caching |

### Scripts

| File | Purpose |
|------|---------|
| scripts/validate.sh | Validates skill structure completeness |
| scripts/test.sh | Tests skill functionality |
| scripts/install-tools.sh | Installs required third-party tools |

### Context Files

| File | Purpose |
|------|---------|
| context/usage-examples.md | Practical usage examples and scenarios |
| context/configuration-guide.md | Detailed configuration guide |
| context/api-reference.md | API reference for programmatic usage |

## File Status

- [x] SKILL.md - Created and integrated
- [x] INDEX.md - Created
- [x] includes/syntax-checker.md - Created
- [x] includes/type-checker.md - Created
- [x] includes/tool-integration.md - Created
- [x] includes/auto-trigger.md - Created
- [x] includes/auto-fixer.md - Created
- [x] includes/report-generator.md - Created
- [x] includes/config-manager.md - Created
- [x] includes/performance-optimizer.md - Created
- [x] scripts/validate.sh - Created
- [x] scripts/test.sh - Created
- [x] scripts/install-tools.sh - Created
- [x] context/usage-examples.md - Created
- [x] context/configuration-guide.md - Created
- [x] context/api-reference.md - Created

## Dependencies

This skill requires the following external tools:

- Python 3.8+
- mypy (type checking)
- pylint (linting)
- flake8 (linting)
- ruff (fast linting)

## Quick Start

1. Install required tools: `bash scripts/install-tools.sh`
2. Validate skill structure: `bash scripts/validate.sh`
3. Run tests: `bash scripts/test.sh`

## Integration Points

- **Syntax Checking**: Use `includes/syntax-checker.md` for AST-based validation
- **Type Checking**: Use `includes/type-checker.md` for static type analysis
- **Tool Integration**: Use `includes/tool-integration.md` for third-party tool setup
- **Auto-Fixing**: Use `includes/auto-fixer.md` for intelligent code fixes
- **Reporting**: Use `includes/report-generator.md` for multi-format reports
- **Configuration**: Use `includes/config-manager.md` for flexible settings
- **Performance**: Use `includes/performance-optimizer.md` for optimized checking
