# Python Code Quality Checker - Configuration Guide

This comprehensive guide covers all configuration options for the Python Code Quality Checker, including file structure, configuration sources, strictness profiles, and tool-specific settings.

## Table of Contents

- [Configuration File Structure](#configuration-file-structure)
- [Configuration Sources and Precedence](#configuration-sources-and-precedence)
- [All Configuration Options](#all-configuration-options)
- [Strictness Profiles](#strictness-profiles)
- [Ignore Rules](#ignore-rules)
- [Tool-Specific Configurations](#tool-specific-configurations)
- [Environment Variables](#environment-variables)
- [Command-Line Options](#command-line-options)
- [Configuration Examples](#configuration-examples)
- [Configuration Migration](#configuration-migration)
- [Best Practices](#best-practices)

---

## Configuration File Structure

### Supported Configuration File Formats

The Python Code Quality Checker supports multiple configuration file formats:

#### 1. YAML Configuration (Recommended)

**File Names:**
- `.python-quality-checker.yaml`
- `.python-quality-checker.yml`

**Example:**
```yaml
version: '1.0'
strictness: normal

linters:
  - ruff
  - pylint

type_checker: mypy

formatters:
  - black
  - isort

rules:
  max_line_length: 100
  max_complexity: 10

mypy:
  strict: false
  ignore_missing_imports: true

ruff:
  select: ['E', 'F', 'W', 'I']
  ignore: ['E501']

exclude:
  - venv/
  - build/
  - dist/

auto_fix: true
```

#### 2. TOML Configuration (pyproject.toml)

**Location:** `pyproject.toml` under `[tool.python-quality-checker]`

**Example:**
```toml
[tool.python-quality-checker]
version = "1.0"
strictness = "normal"
linters = ["ruff", "pylint"]
type_checker = "mypy"
formatters = ["black", "isort"]
auto_fix = true

[tool.python-quality-checker.rules]
max_line_length = 100
max_complexity = 10

[tool.python-quality-checker.mypy]
strict = false
ignore_missing_imports = true

[tool.python-quality-checker.ruff]
select = ["E", "F", "W", "I"]
ignore = ["E501"]

[tool.python-quality-checker.exclude]
patterns = ["venv/", "build/", "dist/"]
```

#### 3. INI Configuration (Legacy)

**File Name:** `.python-quality-checker.ini`

**Example:**
```ini
[quality]
strictness = normal
linters = ruff,pylint
type_checker = mypy
formatters = black,isort
auto_fix = true

[rules]
max_line_length = 100
max_complexity = 10

[exclude]
patterns = venv/,build/,dist/
```

### Configuration File Location

The configuration file is searched in the following order:

1. **Project Root:** Current working directory
2. **Parent Directories:** Recursively search parent directories
3. **User Configuration:** `~/.config/python-quality-checker/config.yaml`
4. **System Configuration:** `/etc/python-quality-checker/config.yaml`

---

## Configuration Sources and Precedence

Configuration values are merged from multiple sources with the following precedence (highest to lowest):

### Precedence Order

```
1. Command-Line Arguments      (Highest - always overrides)
2. Environment Variables       (Overrides file configuration)
3. Project Configuration       (.python-quality-checker.yaml or pyproject.toml)
4. User Configuration          (~/.config/python-quality-checker/config.yaml)
5. Strictness Profile          (Applied as base configuration)
6. Default Values              (Lowest - fallback values)
```

### Example of Configuration Merging

**Base Configuration (Default):**
```yaml
rules:
  max_line_length: 100
  max_complexity: 10
auto_fix: true
```

**Project Configuration:**
```yaml
rules:
  max_line_length: 120
ruff:
  select: ['E', 'F']
```

**Environment Variable:**
```bash
export PYTHON_QUALITY_AUTO_FIX=false
```

**Command-Line Argument:**
```bash
--max-line-length 88
```

**Final Merged Configuration:**
```yaml
rules:
  max_line_length: 88        # From CLI (highest priority)
  max_complexity: 10         # From default
auto_fix: false              # From environment variable
ruff:
  select: ['E', 'F']         # From project config
```

---

## All Configuration Options

### Core Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `"1.0"` | Configuration schema version |
| `strictness` | string | `"normal"` | Strictness level: `relaxed`, `normal`, `strict`, `very-strict` |
| `linters` | list | `["ruff"]` | List of linters to run: `pylint`, `flake8`, `ruff` |
| `type_checker` | string | `"mypy"` | Type checker to use: `mypy`, `pyright`, `none` |
| `formatters` | list | `["black", "isort"]` | List of formatters: `black`, `isort`, `autopep8` |
| `auto_fix` | boolean | `true` | Enable automatic fixing of issues |
| `fail_threshold` | string | `"warning"` | Fail on issues of this severity or higher: `error`, `warning`, `info`, `never` |
| `output_format` | string | `"text"` | Output format: `text`, `json`, `junit`, `github`, `sarif`, `html` |
| `parallel` | integer | `4` | Number of parallel processes |
| `cache` | boolean | `true` | Enable caching for faster re-runs |
| `cache_dir` | string | `".quality-checker-cache"` | Directory for cache storage |

### Rules Configuration

```yaml
rules:
  max_line_length: 100           # Maximum line length
  max_complexity: 10             # Maximum cyclomatic complexity
  max_function_length: 50        # Maximum lines per function
  max_class_length: 300          # Maximum lines per class
  max_arguments: 5               # Maximum function arguments
  max_returns: 6                 # Maximum return statements
  max_branches: 12               # Maximum branching statements
  max_statements: 50             # Maximum statements per function
  max_nested_blocks: 5           # Maximum nested block depth
  max_cognitive_complexity: 15   # Maximum cognitive complexity
  min_public_methods: 2          # Minimum public methods per class
  max_public_methods: 20         # Maximum public methods per class
```

### Exclude Configuration

```yaml
exclude:
  - venv/                        # Virtual environment
  - .venv/                       # Virtual environment (hidden)
  - build/                       # Build directory
  - dist/                        # Distribution directory
  - .git/                        # Git directory
  - __pycache__/                 # Python cache
  - "*.egg-info/"                # Egg metadata
  - .eggs/                       # Eggs directory
  - node_modules/                # Node modules (if applicable)
  - migrations/                  # Database migrations
  - "*/tests/fixtures/"          # Test fixtures
```

### Paths Configuration

```yaml
paths:
  - src/                         # Source directory
  - tests/                       # Test directory
  - scripts/                     # Scripts directory
```

---

## Strictness Profiles

### Relaxed Profile

**Use Case:** Prototypes, scripts, learning projects

```yaml
strictness: relaxed

rules:
  max_line_length: 120
  max_complexity: 15
  max_function_length: 100
  max_class_length: 500
  max_arguments: 8

mypy:
  strict: false
  disallow_untyped_defs: false
  disallow_incomplete_defs: false
  check_untyped_defs: false
  ignore_missing_imports: true

pylint:
  disable:
    - C0114    # missing-module-docstring
    - C0115    # missing-class-docstring
    - C0116    # missing-function-docstring
    - R0903    # too-few-public-methods
    - R0913    # too-many-arguments
    - R0914    # too-many-locals
    - W0212    # protected-access
    - W0612    # unused-variable

ruff:
  select: ['E', 'F']
  ignore: ['E501', 'E731']

flake8:
  max_complexity: 15
  ignore: ['E501', 'W503', 'E203']

auto_fix: true
fail_threshold: error
```

### Normal Profile (Default)

**Use Case:** Most production projects

```yaml
strictness: normal

rules:
  max_line_length: 100
  max_complexity: 10
  max_function_length: 50
  max_class_length: 300
  max_arguments: 5

mypy:
  strict: false
  disallow_untyped_defs: false
  disallow_incomplete_defs: true
  check_untyped_defs: true
  ignore_missing_imports: true

pylint:
  disable:
    - C0114    # missing-module-docstring
    - C0115    # missing-class-docstring
    - C0116    # missing-function-docstring

ruff:
  select: ['E', 'F', 'W', 'I', 'N', 'UP', 'B']
  ignore: ['E501']

flake8:
  max_complexity: 10
  ignore: ['W503', 'E203']

auto_fix: true
fail_threshold: warning
```

### Strict Profile

**Use Case:** Libraries, mature projects, critical systems

```yaml
strictness: strict

rules:
  max_line_length: 88
  max_complexity: 8
  max_function_length: 40
  max_class_length: 200
  max_arguments: 4

mypy:
  strict: true
  disallow_untyped_defs: true
  disallow_incomplete_defs: true
  check_untyped_defs: true
  ignore_missing_imports: false

pylint:
  disable: []
  enable: ['E', 'F', 'W', 'R']

ruff:
  select: ['E', 'F', 'W', 'I', 'N', 'UP', 'B', 'C4', 'SIM', 'TCH']
  ignore: []

flake8:
  max_complexity: 8
  ignore: []

auto_fix: false
fail_threshold: warning
```

### Very Strict Profile

**Use Case:** Security-critical code, financial systems, healthcare

```yaml
strictness: very-strict

rules:
  max_line_length: 88
  max_complexity: 5
  max_function_length: 30
  max_class_length: 150
  max_arguments: 3

mypy:
  strict: true
  disallow_untyped_defs: true
  disallow_incomplete_defs: true
  check_untyped_defs: true
  ignore_missing_imports: false
  warn_return_any: true
  warn_unused_ignores: true
  strict_optional: true
  strict_equality: true

pylint:
  disable: []
  enable: ['E', 'F', 'W', 'R', 'C']

ruff:
  select: ['ALL']
  ignore: ['D100', 'D104']

flake8:
  max_complexity: 5
  ignore: []

auto_fix: false
fail_threshold: info
```

### Custom Strictness Profile

Create a custom profile by extending an existing one:

```yaml
strictness: normal

rules:
  max_line_length: 95           # Override from normal (100)
  max_complexity: 12            # Override from normal (10)

mypy:
  strict: false
  disallow_untyped_defs: true   # Stricter than normal

ruff:
  select: ['E', 'F', 'W', 'I', 'N', 'UP', 'B', 'S']  # Add security rules
  ignore: ['E501', 'S101']     # Ignore line length and assert in tests
```

---

## Ignore Rules

### Simple Ignore Patterns

```yaml
ignore:
  - E501                        # Ignore all E501 errors
  - W503                        # Ignore all W503 warnings
  - D100                        # Ignore missing docstrings
```

### Per-File Ignores

```yaml
per_file_ignores:
  "__init__.py":                # Ignore in all __init__.py files
    - F401                      # Unused imports
  "tests/*":                    # Ignore in test files
    - S101                      # Use of assert
    - D103                      # Missing function docstring
  "migrations/*":               # Ignore in migrations
    - E501                      # Line too long
    - D100                      # Missing docstring
  "*/legacy/*":                 # Ignore in legacy code
    - E                         # All E errors
    - W                         # All W warnings
```

### Advanced Ignore Rules

```yaml
ignore:
  - pattern: "*/migrations/*"   # Pattern to match files
    codes:                      # Codes to ignore
      - E501
      - D100
      - D101
      - D102
    reason: "Auto-generated migration files"  # Documentation
    expires: "2024-12-31"       # Temporary ignore with expiry

  - pattern: "tests/fixtures/*"
    codes: ["ALL"]              # Ignore all codes
    reason: "Test fixture files"

  - pattern: ".*_pb2\\.py$"     # Regex pattern
    regex: true                 # Enable regex matching
    codes: ["ALL"]
    reason: "Generated protobuf files"
```

### Inline Ignores

Use inline comments in source code:

```python
# pylint: disable=too-many-arguments
def complex_function(a, b, c, d, e, f):
    pass

# ruff: noqa: E501
very_long_line_that_exceeds_the_maximum_line_length_limit = "some very long value"

# type: ignore[arg-type]
some_function(invalid_argument)

# flake8: noqa: D103
def function_without_docstring():
    pass
```

---

## Tool-Specific Configurations

### Mypy Configuration

```yaml
mypy:
  # Core options
  strict: false                          # Enable all strict checks
  python_version: '3.10'                 # Target Python version
  ignore_missing_imports: true           # Ignore missing imports
  
  # Type checking strictness
  disallow_untyped_defs: true            # Require type annotations
  disallow_incomplete_defs: true         # Require complete annotations
  check_untyped_defs: true               # Check untyped functions
  disallow_untyped_decorators: true      # Require typed decorators
  no_implicit_optional: true             # No implicit Optional
  strict_optional: true                  # Strict Optional checking
  strict_equality: true                  # Strict equality checks
  
  # Warnings
  warn_return_any: true                  # Warn on Any return
  warn_unused_ignores: true              # Warn on unused type: ignore
  warn_redundant_casts: true             # Warn on redundant casts
  warn_no_return: true                   # Warn on missing return
  warn_unreachable: true                 # Warn on unreachable code
  
  # Output options
  show_error_codes: true                 # Show error codes
  show_column_numbers: true              # Show column numbers
  show_error_context: true               # Show error context
  pretty: true                           # Pretty output
  
  # Plugins
  plugins:
    - mypy_django_plugin.main
    - pydantic.mypy
  
  # Exclusions
  exclude:
    - migrations/
    - tests/fixtures/
  
  # Per-module overrides
  overrides:
    tests.*:
      disallow_untyped_defs: false
    third_party_module.*:
      ignore_missing_imports: true
```

### Pylint Configuration

```yaml
pylint:
  # Master settings
  jobs: 0                                # Auto-detect CPU count
  persistent: true                       # Persist analysis data
  load_plugins:                          # Load custom plugins
    - pylint.extensions.docparams
    - pylint.extensions.mccabe
  
  # Message control
  disable:                               # Disable specific checks
    - C0114                              # missing-module-docstring
    - C0115                              # missing-class-docstring
    - C0116                              # missing-function-docstring
    - R0903                              # too-few-public-methods
  enable:                                # Enable specific checks
    - E
    - F
    - W
  
  # Naming conventions
  good_names:                            # Good variable names
    - i
    - j
    - k
    - ex
    - Run
    - _
    - id
    - db
  variable_rgx: '[a-z_][a-z0-9_]{2,30}$'
  function_rgx: '[a-z_][a-z0-9_]{2,30}$'
  class_rgx: '[A-Z_][a-zA-Z0-9]+$'
  const_rgx: '(([A-Z_][A-Z0-9_]*)|(__.*__))$'
  
  # Format settings
  max_line_length: 100
  max_module_lines: 1000
  indent_string: '    '
  
  # Design checks
  max_args: 5                            # Maximum arguments
  max_locals: 15                         # Maximum local variables
  max_returns: 6                         # Maximum return statements
  max_branches: 12                       # Maximum branches
  max_statements: 50                     # Maximum statements
  max_attributes: 7                      # Maximum instance attributes
  min_public_methods: 2                  # Minimum public methods
  max_public_methods: 20                 # Maximum public methods
  max_ancestors: 7                       # Maximum parent classes
  
  # Refactoring
  max_nested_blocks: 5                   # Maximum nested blocks
  
  # Similarity
  min_similarity_lines: 4                # Minimum duplicate lines
  ignore_comments: true
  ignore_docstrings: true
  ignore_imports: true
  
  # Type check
  ignored_modules: []
  ignored_classes: []
  
  # Reports
  output_format: text
  reports: false
  score: false
```

### Flake8 Configuration

```yaml
flake8:
  # Core settings
  max_line_length: 100
  max_complexity: 10
  max_doc_length: 100
  
  # Rule selection
  select:                                # Select rules to check
    - E                                  # pycodestyle errors
    - W                                  # pycodestyle warnings
    - F                                  # Pyflakes
    - C                                  # McCabe complexity
    - N                                  # pep8-naming
    - B                                  # flake8-bugbear
    - T                                  # flake8-print
  
  ignore:                                # Ignore specific rules
    - E203                               # whitespace before ':'
    - W503                               # line break before binary operator
  
  extend_select:                         # Additional rules
    - B9
  
  extend_ignore:                         # Additional ignores
    - E501
  
  # Exclusions
  exclude:
    - .git
    - __pycache__
    - build
    - dist
    - .eggs
    - '*.egg'
    - venv
    - .venv
  
  # Per-file ignores
  per_file_ignores:
    __init__.py: F401
    tests/*: S101
  
  # Docstring convention
  docstring_convention: google           # google, numpy, pep257
```

### Ruff Configuration

```yaml
ruff:
  # Core settings
  target_version: py310
  line_length: 100
  indent_width: 4
  
  # Rule selection
  select:                                # Select rules to check
    - E                                  # pycodestyle errors
    - W                                  # pycodestyle warnings
    - F                                  # Pyflakes
    - I                                  # isort
    - N                                  # pep8-naming
    - UP                                 # pyupgrade
    - B                                  # flake8-bugbear
    - C4                                 # flake8-comprehensions
    - SIM                                # flake8-simplify
    - TCH                                # flake8-type-checking
    - RUF                                # Ruff-specific rules
  
  ignore:                                # Ignore specific rules
    - E501                               # line too long
  
  extend_select: []                      # Additional rules
  
  # Exclusions
  exclude:
    - .git
    - __pycache__
    - build
    - dist
    - .eggs
    - '*.egg'
    - venv
    - .venv
  
  # Per-file ignores
  per_file_ignores:
    __init__.py:
      - F401
    tests/*:
      - S101
  
  # McCabe complexity
  mccabe:
    max_complexity: 10
  
  # isort settings
  isort:
    known_first_party:
      - myproject
    known_third_party:
      - requests
      - django
    force_single_line: false
    force_sort_within_sections: true
  
  # pycodestyle settings
  pycodestyle:
    max_line_length: 100
    max_doc_length: 100
  
  # Format settings
  format:
    quote_style: double                  # double or single
    indent_style: space                  # space or tab
    docstring_code_format: true
  
  # Fix options
  fix: false                             # Auto-fix issues
  unsafe_fixes: false                    # Allow unsafe fixes
```

### Black Configuration

```yaml
black:
  line_length: 88
  target_version:
    - py39
    - py310
    - py311
  skip_string_normalization: false       # Don't normalize quotes
  skip_magic_trailing_comma: false       # Don't skip trailing comma
  exclude:
    - migrations/
  extend_exclude:
    - legacy/
```

### Isort Configuration

```yaml
isort:
  profile: black                         # Compatible with black
  line_length: 88
  known_first_party:
    - myproject
  known_third_party:
    - requests
    - django
  known_local_folder:
    - local_module
  skip:
    - migrations
    - .git
  skip_glob:
    - '*/migrations/*'
  force_single_line: false
  force_sort_within_sections: true
  multi_line_output: 3                   # Vertical hanging indent
  include_trailing_comma: true
  use_parentheses: true
  ensure_newline_before_comments: true
```

---

## Environment Variables

All configuration options can be overridden using environment variables with the `PYTHON_QUALITY_` prefix.

### Core Environment Variables

```bash
# Strictness level
export PYTHON_QUALITY_STRICTNESS=strict

# Linters to run (comma-separated)
export PYTHON_QUALITY_LINTERS=ruff,pylint

# Type checker
export PYTHON_QUALITY_TYPE_CHECKER=mypy

# Formatters (comma-separated)
export PYTHON_QUALITY_FORMATTERS=black,isort

# Auto-fix
export PYTHON_QUALITY_AUTO_FIX=true

# Fail threshold
export PYTHON_QUALITY_FAIL_ON=warning

# Output format
export PYTHON_QUALITY_OUTPUT_FORMAT=json

# Parallel processes
export PYTHON_QUALITY_PARALLEL=8

# Cache
export PYTHON_QUALITY_CACHE=true

# Configuration file
export PYTHON_QUALITY_CONFIG_FILE=/path/to/config.yaml
```

### Rules Environment Variables

```bash
export PYTHON_QUALITY_MAX_LINE_LENGTH=88
export PYTHON_QUALITY_MAX_COMPLEXITY=8
```

### Exclude and Ignore

```bash
# Exclude patterns (comma-separated)
export PYTHON_QUALITY_EXCLUDE=venv/,build/,dist/

# Ignore codes (comma-separated)
export PYTHON_QUALITY_IGNORE=E501,W503
```

### Tool-Specific Environment Variables

```bash
# Mypy
export PYTHON_QUALITY_MYPY_STRICT=true
export PYTHON_QUALITY_MYPY_PYTHON_VERSION=3.10

# Pylint
export PYTHON_QUALITY_PYLINT_JOBS=4

# Ruff
export PYTHON_QUALITY_RUFF_SELECT=E,F,W
export PYTHON_QUALITY_RUFF_IGNORE=E501

# Black
export PYTHON_QUALITY_BLACK_LINE_LENGTH=88
```

---

## Command-Line Options

### Basic Options

```bash
python-quality-checker [OPTIONS] [PATHS]
```

| Option | Short | Description |
|--------|-------|-------------|
| `--config` | `-c` | Path to configuration file |
| `--strictness` | `-s` | Strictness level |
| `--linters` | | Comma-separated list of linters |
| `--type-checker` | | Type checker to use |
| `--formatters` | | Comma-separated list of formatters |
| `--auto-fix` | | Enable auto-fixing |
| `--no-auto-fix` | | Disable auto-fixing |

### Rule Options

```bash
--max-line-length INT      # Maximum line length
--max-complexity INT       # Maximum complexity
--exclude PATTERN          # Exclude pattern (can be used multiple times)
--ignore CODE              # Ignore error code (can be used multiple times)
```

### Output Options

```bash
--output-format FORMAT     # Output format: text, json, junit, github, sarif
--fail-on SEVERITY         # Fail on severity: error, warning, info
```

### Performance Options

```bash
--parallel INT             # Number of parallel processes
--cache                    # Enable caching (default)
--no-cache                 # Disable caching
```

### Examples

```bash
# Check with strict settings
python-quality-checker --strictness strict src/

# Run specific linters
python-quality-checker --linters ruff,mypy src/

# Auto-fix issues
python-quality-checker --auto-fix src/

# Generate JSON report
python-quality-checker --output-format json src/ > report.json

# Check with custom config
python-quality-checker --config config/quality.yaml src/

# Check specific files
python-quality-checker src/main.py src/utils.py

# Exclude patterns
python-quality-checker --exclude migrations/ --exclude tests/fixtures/ src/

# Ignore specific codes
python-quality-checker --ignore E501 --ignore D100 src/

# Use 8 parallel processes
python-quality-checker --parallel 8 src/

# Fail on warnings
python-quality-checker --fail-on warning src/
```

---

## Configuration Examples

### Example 1: Minimal Configuration

```yaml
linters:
  - ruff
type_checker: mypy
```

### Example 2: Web Application (Django)

```yaml
strictness: normal

linters:
  - ruff
  - pylint

type_checker: mypy

formatters:
  - black
  - isort

rules:
  max_line_length: 88
  max_complexity: 10

mypy:
  plugins:
    - mypy_django_plugin.main
  ignore_missing_imports: true

ruff:
  select: ['E', 'F', 'W', 'I', 'N', 'UP', 'B', 'S']
  ignore: ['E501']

exclude:
  - venv/
  - migrations/
  - static/
  - media/

per_file_ignores:
  "*/migrations/*":
    - E501
    - D100
    - D101
  "tests/*":
    - S101
    - D103
```

### Example 3: Library Package

```yaml
strictness: strict

linters:
  - ruff
  - pylint

type_checker: mypy

formatters:
  - black
  - isort

rules:
  max_line_length: 88
  max_complexity: 8
  max_function_length: 40

mypy:
  strict: true
  disallow_untyped_defs: true
  warn_return_any: true

ruff:
  select: ['E', 'F', 'W', 'I', 'N', 'UP', 'B', 'C4', 'SIM', 'TCH']
  ignore: []

pylint:
  disable: []
  enable: ['E', 'F', 'W', 'R', 'C']

exclude:
  - venv/
  - build/
  - dist/
  - docs/

auto_fix: false
fail_threshold: warning
```

### Example 4: Data Science Project

```yaml
strictness: relaxed

linters:
  - ruff

type_checker: mypy

formatters:
  - black
  - isort

rules:
  max_line_length: 100
  max_complexity: 15
  max_function_length: 80

mypy:
  strict: false
  ignore_missing_imports: true
  disallow_untyped_defs: false

ruff:
  select: ['E', 'F', 'W', 'I']
  ignore: ['E501', 'E731']

exclude:
  - venv/
  - .ipynb_checkpoints/
  - data/
  - notebooks/

per_file_ignores:
  "notebooks/*":
    - ALL

auto_fix: true
```

### Example 5: Microservice

```yaml
strictness: normal

linters:
  - ruff

type_checker: mypy

formatters:
  - black
  - isort

rules:
  max_line_length: 100
  max_complexity: 10

mypy:
  strict: false
  ignore_missing_imports: true

ruff:
  select: ['E', 'F', 'W', 'I', 'N', 'UP', 'B', 'S']
  ignore: ['E501']

exclude:
  - venv/
  - .venv/
  - tests/fixtures/

per_file_ignores:
  "tests/*":
    - S101

auto_fix: true
fail_threshold: error
```

### Example 6: Legacy Project Migration

```yaml
strictness: relaxed

linters:
  - ruff

type_checker: none

formatters: []

rules:
  max_line_length: 120
  max_complexity: 20

ruff:
  select: ['E', 'F']
  ignore: ['E501', 'E722', 'F401', 'F841']

exclude:
  - venv/
  - legacy/
  - deprecated/

per_file_ignores:
  "legacy/*":
    - ALL

auto_fix: true

ignore:
  - pattern: "legacy/*"
    codes: ["ALL"]
    reason: "Legacy code - will be refactored"
    expires: "2024-12-31"
```

---

## Configuration Migration

### Version Management

The configuration schema includes a version field for future compatibility:

```yaml
version: '1.0'
```

### Migration Process

When upgrading the quality checker, configuration files are automatically migrated:

1. **Version Detection:** The checker reads the version field
2. **Migration Chain:** Applies necessary migrations in sequence
3. **Backup:** Creates backup of original configuration
4. **Report:** Shows what was changed

### Example Migration

**Before (v0.3):**
```yaml
version: '0.3'
linter: pylint
formatter: black
max_line_length: 100
fail_on: error
disabled_rules:
  - C0114
  - C0115
```

**After (v1.0):**
```yaml
version: '1.0'
linters:
  - pylint
formatters:
  - black
rules:
  max_line_length: 100
fail_threshold: error
ignore:
  - C0114
  - C0115
```

### Migration Report

```
Configuration Migration Report
==============================

From version: 0.3
To version: 1.0

Changes applied:
  ✓ Converted 'linter: pylint' to 'linters: [pylint]'
  ✓ Converted 'formatter: black' to 'formatters: [black]'
  ✓ Moved 'max_line_length' to 'rules.max_line_length'
  ✓ Renamed 'fail_on' to 'fail_threshold'
  ✓ Merged 'disabled_rules' into 'ignore'

Backup created: .python-quality-checker.yaml.backup
```

---

## Best Practices

### 1. Use Version Control

Always include the version field:

```yaml
version: '1.0'
```

### 2. Start with Strictness Profiles

Begin with a strictness profile and customize:

```yaml
strictness: normal

rules:
  max_line_length: 95  # Override specific rules
```

### 3. Document Ignore Rules

Always add reasons for ignore rules:

```yaml
ignore:
  - pattern: "*/migrations/*"
    codes: ["E501", "D100"]
    reason: "Auto-generated Django migrations"
```

### 4. Use Expiry Dates for Temporary Ignores

```yaml
ignore:
  - pattern: "legacy/*"
    codes: ["ALL"]
    reason: "Legacy code scheduled for refactoring"
    expires: "2024-12-31"
```

### 5. Centralize Configuration

Use `pyproject.toml` for all tool configurations:

```toml
[tool.python-quality-checker]
strictness = "normal"

[tool.mypy]
python_version = "3.10"

[tool.ruff]
line-length = 100

[tool.black]
line-length = 100

[tool.isort]
profile = "black"
```

### 6. Layer Configuration

Use multiple configuration layers:

1. **User-level:** Personal preferences
2. **Project-level:** Team standards
3. **CI/CD:** Environment-specific overrides

### 7. Validate Configuration

Regularly validate configuration:

```bash
python-quality-checker --validate-config
```

### 8. Use Environment Variables for CI

Override settings in CI without changing files:

```yaml
# .github/workflows/quality.yml
env:
  PYTHON_QUALITY_STRICTNESS: strict
  PYTHON_QUALITY_FAIL_ON: error
```

### 9. Keep Tools Synchronized

Ensure tool configurations are compatible:

```yaml
black:
  line_length: 88

isort:
  profile: black
  line_length: 88

ruff:
  line_length: 88
```

### 10. Regular Review

Periodically review and update configuration:

- Remove outdated ignore rules
- Update strictness levels
- Add new useful rules
- Remove temporary ignores that expired

---

## Troubleshooting

### Issue: Configuration Not Found

**Problem:** Quality checker uses defaults instead of custom configuration

**Solutions:**
1. Verify file name matches expected patterns
2. Check file is in project root
3. Specify config file explicitly: `--config path/to/config.yaml`

### Issue: Conflicting Tool Settings

**Problem:** Tools report conflicting issues

**Solutions:**
1. Ensure consistent line length across tools
2. Synchronize ignore rules
3. Use ruff as single source of truth

### Issue: Environment Variables Not Applied

**Problem:** Environment variables are ignored

**Solutions:**
1. Verify variable names match `PYTHON_QUALITY_*` prefix
2. Check for typos
3. Ensure proper format (comma-separated for lists)

### Issue: Ignore Rules Not Working

**Problem:** Issues still reported despite ignore rules

**Solutions:**
1. Verify pattern syntax (glob vs regex)
2. Check if rule has expired
3. Ensure codes match actual error codes
4. Use correct section (`ignore` vs `per_file_ignores`)

---

## Quick Reference

| Configuration Area | Key Options |
|-------------------|-------------|
| **Core** | `strictness`, `linters`, `type_checker`, `formatters` |
| **Rules** | `max_line_length`, `max_complexity`, `max_function_length` |
| **Exclude** | `exclude`, `per_file_ignores` |
| **Ignore** | `ignore`, `per_file_ignores` |
| **Output** | `output_format`, `fail_threshold` |
| **Performance** | `parallel`, `cache` |
| **Tools** | `mypy`, `pylint`, `ruff`, `flake8`, `black`, `isort` |
