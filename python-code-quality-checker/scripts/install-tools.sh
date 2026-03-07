#!/bin/bash
#
# install-tools.sh - Installs dependency tools for Python code quality checking
#
# This script installs:
# - mypy (type checking)
# - pylint (linting)
# - flake8 (linting)
# - ruff (fast linting)
# - black (formatting)
# - isort (import sorting)
# - autopep8 (PEP 8 formatting)
#
# Usage: ./install-tools.sh [--user] [--upgrade] [--dry-run]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(dirname "$SCRIPT_DIR")"

USER_INSTALL=false
UPGRADE=false
DRY_RUN=false
INSTALLED_TOOLS=()
FAILED_TOOLS=()

log_info() {
    echo "[INFO] $1"
}

log_success() {
    echo "[OK] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

log_warning() {
    echo "[WARNING] $1" >&2
}

check_python() {
    log_info "Checking Python installation..."
    
    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
    elif command -v python &> /dev/null; then
        PYTHON_CMD="python"
    else
        log_error "Python is not installed. Please install Python 3.8 or later."
        exit 1
    fi
    
    PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | awk '{print $2}')
    log_success "Found Python $PYTHON_VERSION"
    
    if ! $PYTHON_CMD -c "import pip" 2>/dev/null; then
        log_error "pip is not installed. Please install pip."
        exit 1
    fi
    log_success "pip is available"
}

check_pip() {
    log_info "Checking pip..."
    
    if command -v pip3 &> /dev/null; then
        PIP_CMD="pip3"
    elif command -v pip &> /dev/null; then
        PIP_CMD="pip"
    else
        PIP_CMD="$PYTHON_CMD -m pip"
    fi
    
    PIP_VERSION=$($PIP_CMD --version 2>&1 | awk '{print $2}')
    log_success "Found pip $PIP_VERSION"
}

build_pip_command() {
    local package="$1"
    local cmd="$PIP_CMD install"
    
    if [ "$USER_INSTALL" = true ]; then
        cmd="$cmd --user"
    fi
    
    if [ "$UPGRADE" = true ]; then
        cmd="$cmd --upgrade"
    fi
    
    cmd="$cmd $package"
    
    echo "$cmd"
}

install_tool() {
    local tool_name="$1"
    local package_name="${2:-$tool_name}"
    
    log_info "Installing $tool_name..."
    
    if [ "$DRY_RUN" = true ]; then
        local cmd=$(build_pip_command "$package_name")
        log_info "[DRY RUN] Would run: $cmd"
        return 0
    fi
    
    local cmd=$(build_pip_command "$package_name")
    
    if $cmd 2>&1; then
        log_success "$tool_name installed successfully"
        INSTALLED_TOOLS+=("$tool_name")
    else
        log_error "Failed to install $tool_name"
        FAILED_TOOLS+=("$tool_name")
    fi
}

verify_installation() {
    local tool_name="$1"
    local command_name="${2:-$tool_name}"
    
    log_info "Verifying $tool_name installation..."
    
    if command -v "$command_name" &> /dev/null; then
        local version=$($command_name --version 2>&1 | head -n 1)
        log_success "$tool_name is available: $version"
        return 0
    else
        log_warning "$tool_name command not found in PATH"
        return 1
    fi
}

generate_config_files() {
    log_info "Generating default configuration files..."
    
    local config_dir="$SKILL_ROOT/config"
    mkdir -p "$config_dir"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would generate configuration files in $config_dir"
        return 0
    fi
    
    cat > "$config_dir/mypy.ini" << 'EOF'
[mypy]
python_version = 3.9
warn_return_any = True
warn_unused_ignores = True
disallow_untyped_defs = False
disallow_incomplete_defs = False
check_untyped_defs = True
ignore_missing_imports = True

[mypy-tests.*]
ignore_errors = True
EOF
    log_success "Generated mypy.ini"
    
    cat > "$config_dir/.flake8" << 'EOF'
[flake8]
max-line-length = 100
max-complexity = 10
ignore = E203, W503
exclude = 
    .git,
    __pycache__,
    venv,
    .venv,
    build,
    dist,
    *.egg-info
EOF
    log_success "Generated .flake8 config"
    
    cat > "$config_dir/pyproject.toml" << 'EOF'
[tool.black]
line-length = 100
target-version = ['py39', 'py310', 'py311']
include = '\.pyi?$'
exclude = '''
/(
    \.git
  | \.venv
  | venv
  | __pycache__
  | build
  | dist
)/
'''

[tool.isort]
profile = "black"
line_length = 100
multi_line_output = 3
include_trailing_comma = true
force_grid_wrap = 0
use_parentheses = true
ensure_newline_before_comments = true

[tool.ruff]
line-length = 100
target-version = "py39"

[tool.ruff.lint]
select = ["E", "F", "W", "I", "N", "UP", "B", "C4"]
ignore = ["E203", "W503"]

[tool.pylint.messages_control]
disable = [
    "C0114",  # missing-module-docstring
    "C0115",  # missing-class-docstring
    "C0116",  # missing-function-docstring
]

[tool.pylint.format]
max-line-length = 100
EOF
    log_success "Generated pyproject.toml"
    
    cat > "$config_dir/.pylintrc" << 'EOF'
[MESSAGES CONTROL]
disable=
    C0114,
    C0115,
    C0116,
    too-few-public-methods,
    too-many-arguments,

[FORMAT]
max-line-length=100
indent-string='    '

[BASIC]
good-names=i,j,k,ex,Run,_,id

[DESIGN]
max-attributes=10
max-args=10
EOF
    log_success "Generated .pylintrc"
    
    cat > "$config_dir/ruff.toml" << 'EOF'
line-length = 100
target-version = "py39"

[lint]
select = ["E", "F", "W", "I", "N", "UP", "B", "C4", "SIM"]
ignore = ["E203", "W503"]

[lint.per-file-ignores]
"__init__.py" = ["F401"]
"tests/*" = ["S101"]
EOF
    log_success "Generated ruff.toml"
}

print_summary() {
    echo ""
    echo "========================================"
    echo "Installation Summary"
    echo "========================================"
    echo ""
    
    if [ "$DRY_RUN" = true ]; then
        echo "Mode: DRY RUN (no actual installations)"
        echo ""
    fi
    
    echo "Successfully installed: ${#INSTALLED_TOOLS[@]} tool(s)"
    for tool in "${INSTALLED_TOOLS[@]}"; do
        echo "  - $tool"
    done
    
    if [ ${#FAILED_TOOLS[@]} -gt 0 ]; then
        echo ""
        echo "Failed to install: ${#FAILED_TOOLS[@]} tool(s)"
        for tool in "${FAILED_TOOLS[@]}"; do
            echo "  - $tool"
        done
    fi
    
    echo ""
    echo "Configuration files generated in: $SKILL_ROOT/config/"
    echo ""
    
    echo "Next steps:"
    echo "  1. Review configuration files in config/ directory"
    echo "  2. Copy desired configs to your project root"
    echo "  3. Run 'python3 -m mypy --version' to verify mypy"
    echo "  4. Run 'ruff --version' to verify ruff"
    echo "  5. Run 'black --version' to verify black"
}

main() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --user|-u)
                USER_INSTALL=true
                shift
                ;;
            --upgrade|-U)
                UPGRADE=true
                shift
                ;;
            --dry-run|-n)
                DRY_RUN=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --user, -u        Install to user site-packages"
                echo "  --upgrade, -U     Upgrade existing packages"
                echo "  --dry-run, -n     Show what would be installed without installing"
                echo "  --help, -h        Show this help message"
                echo ""
                echo "This script installs the following tools:"
                echo "  - mypy      (type checking)"
                echo "  - pylint    (linting)"
                echo "  - flake8    (linting)"
                echo "  - ruff      (fast linting)"
                echo "  - black     (formatting)"
                echo "  - isort     (import sorting)"
                echo "  - autopep8  (PEP 8 formatting)"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    echo "Installing Python Code Quality Checker tools..."
    echo ""
    
    check_python
    check_pip
    
    echo ""
    log_info "Installing tools..."
    echo ""
    
    install_tool "mypy"
    install_tool "pylint"
    install_tool "flake8"
    install_tool "ruff"
    install_tool "black"
    install_tool "isort"
    install_tool "autopep8"
    
    echo ""
    log_info "Verifying installations..."
    echo ""
    
    if [ "$DRY_RUN" = false ]; then
        verify_installation "mypy"
        verify_installation "pylint"
        verify_installation "flake8"
        verify_installation "ruff"
        verify_installation "black"
        verify_installation "isort"
        verify_installation "autopep8"
    fi
    
    echo ""
    generate_config_files
    print_summary
}

main "$@"
