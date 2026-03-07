#!/bin/bash
#
# test.sh - Tests the skill functionality
#
# This script:
# - Creates a test Python file with intentional errors
# - Runs syntax checking
# - Runs type checking
# - Runs linting
# - Tests auto-fix functionality
# - Generates test reports
# - Cleans up test files
#
# Usage: ./test.sh [--keep-files] [--verbose]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_DIR="/tmp/python-quality-checker-test/workspace"
REPORT_DIR="/tmp/python-quality-checker-test/reports"

VERBOSE=false
KEEP_FILES=false
TESTS_PASSED=0
TESTS_FAILED=0
TEST_RESULTS=()

log_info() {
    echo "[INFO] $1"
    if [ "$VERBOSE" = true ]; then
        TEST_RESULTS+=("INFO: $1")
    fi
}

log_pass() {
    echo "[PASS] $1"
    TEST_RESULTS+=("PASS: $1")
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

log_fail() {
    echo "[FAIL] $1" >&2
    TEST_RESULTS+=("FAIL: $1")
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

log_skip() {
    echo "[SKIP] $1"
    TEST_RESULTS+=("SKIP: $1")
}

setup_test_environment() {
    log_info "Setting up test environment..."
    
    rm -rf "$TEST_DIR" "$REPORT_DIR"
    mkdir -p "$TEST_DIR" "$REPORT_DIR"
    
    log_info "Test directory: $TEST_DIR"
    log_info "Report directory: $REPORT_DIR"
}

create_test_files() {
    log_info "Creating test Python files..."
    
    cat > "$TEST_DIR/syntax_errors.py" << 'EOF'
# Test file with syntax errors
def broken_function(
    # Missing closing parenthesis and colon
    print("This line has an extra bracket]")
    
def another_function(x, y
    # Missing closing parenthesis
    return x + y

# Indentation error
if True:
x = 1

# Invalid syntax
class MyClass
    pass
EOF
    
    cat > "$TEST_DIR/type_errors.py" << 'EOF'
# Test file with type errors
from typing import List, Optional

def greet(name: str) -> str:
    return f"Hello, {name}"

# Type mismatch
result: int = greet("World")  # Should be str, not int

def add_numbers(a: int, b: int) -> int:
    return a + b

# Wrong argument types
add_numbers("1", "2")  # Should be int

# Optional handling
def get_optional() -> Optional[str]:
    return None

value: str = get_optional()  # Should handle Optional

# List type mismatch
numbers: List[int] = [1, 2, "three"]  # Should be all ints
EOF
    
    cat > "$TEST_DIR/style_issues.py" << 'EOF'
# Test file with style issues
import os,sys,json
from typing import List

def bad_function( x,y,z ):
    a=1+2
    b = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100]
    if x>0:
        return y
    else: return z

class bad_class:
    def __init__(self,value):
        self.value=value
EOF
    
    cat > "$TEST_DIR/clean_code.py" << 'EOF'
"""A clean Python file for testing positive cases."""
from typing import List, Optional


def calculate_average(numbers: List[float]) -> float:
    """Calculate the average of a list of numbers."""
    if not numbers:
        return 0.0
    return sum(numbers) / len(numbers)


def find_user(user_id: int) -> Optional[dict]:
    """Find a user by ID."""
    users = {1: {"name": "Alice"}, 2: {"name": "Bob"}}
    return users.get(user_id)


class Calculator:
    """A simple calculator class."""
    
    def __init__(self, initial_value: float = 0.0):
        self.value = initial_value
    
    def add(self, amount: float) -> float:
        """Add an amount to the current value."""
        self.value += amount
        return self.value
    
    def multiply(self, factor: float) -> float:
        """Multiply the current value by a factor."""
        self.value *= factor
        return self.value


if __name__ == "__main__":
    calc = Calculator(10.0)
    print(calc.add(5.0))
    print(calculate_average([1.0, 2.0, 3.0]))
EOF
    
    log_pass "Test files created successfully"
}

test_syntax_checking() {
    log_info "Testing syntax checking..."
    
    local syntax_file="$TEST_DIR/syntax_errors.py"
    local report_file="$REPORT_DIR/syntax_report.txt"
    
    if command -v python3 &> /dev/null; then
        if python3 -m py_compile "$syntax_file" 2> "$report_file"; then
            log_fail "Syntax check should have failed for syntax_errors.py"
        else
            log_pass "Syntax errors detected correctly"
            if [ -s "$report_file" ]; then
                log_info "Syntax error report generated"
            fi
        fi
    else
        log_skip "Syntax checking (python3 not available)"
    fi
}

test_type_checking() {
    log_info "Testing type checking..."
    
    local type_file="$TEST_DIR/type_errors.py"
    local report_file="$REPORT_DIR/type_report.txt"
    
    if command -v mypy &> /dev/null; then
        if mypy "$type_file" --no-error-summary > "$report_file" 2>&1; then
            log_fail "Type check should have reported issues for type_errors.py"
        else
            log_pass "Type errors detected correctly"
            if [ -s "$report_file" ]; then
                log_info "Type error report generated"
            fi
        fi
    else
        log_skip "Type checking (mypy not installed)"
    fi
}

test_linting() {
    log_info "Testing linting..."
    
    local style_file="$TEST_DIR/style_issues.py"
    local report_file="$REPORT_DIR/lint_report.txt"
    
    local linters_found=false
    
    if command -v ruff &> /dev/null; then
        log_info "Running ruff..."
        ruff check "$style_file" > "$report_file" 2>&1 || true
        if [ -s "$report_file" ]; then
            log_pass "Ruff detected style issues"
        fi
        linters_found=true
    fi
    
    if command -v flake8 &> /dev/null; then
        log_info "Running flake8..."
        flake8 "$style_file" > "$report_file" 2>&1 || true
        if [ -s "$report_file" ]; then
            log_pass "Flake8 detected style issues"
        fi
        linters_found=true
    fi
    
    if command -v pylint &> /dev/null; then
        log_info "Running pylint..."
        pylint "$style_file" --output-format=text > "$report_file" 2>&1 || true
        if [ -s "$report_file" ]; then
            log_pass "Pylint detected style issues"
        fi
        linters_found=true
    fi
    
    if [ "$linters_found" = false ]; then
        log_skip "Linting (no linters installed)"
    fi
}

test_clean_code() {
    log_info "Testing clean code validation..."
    
    local clean_file="$TEST_DIR/clean_code.py"
    local report_file="$REPORT_DIR/clean_report.txt"
    
    if command -v python3 &> /dev/null; then
        if python3 -m py_compile "$clean_file" 2> "$report_file"; then
            log_pass "Clean code passed syntax check"
        else
            log_fail "Clean code should pass syntax check"
        fi
    fi
    
    if command -v mypy &> /dev/null; then
        if mypy "$clean_file" --no-error-summary > "$report_file" 2>&1; then
            log_pass "Clean code passed type check"
        else
            log_fail "Clean code should pass type check"
        fi
    fi
}

test_auto_fix() {
    log_info "Testing auto-fix functionality..."
    
    local style_file="$TEST_DIR/style_issues.py"
    local fixed_file="$TEST_DIR/style_issues_fixed.py"
    local backup_file="$TEST_DIR/style_issues.py.bak"
    
    cp "$style_file" "$fixed_file"
    
    local fixers_found=false
    
    if command -v black &> /dev/null; then
        log_info "Running black formatter..."
        cp "$fixed_file" "$backup_file"
        if black "$fixed_file" 2>/dev/null; then
            if ! cmp -s "$fixed_file" "$backup_file"; then
                log_pass "Black formatting applied successfully"
            fi
        fi
        rm -f "$backup_file"
        fixers_found=true
    fi
    
    if command -v isort &> /dev/null; then
        log_info "Running isort..."
        cp "$fixed_file" "$backup_file"
        if isort "$fixed_file" 2>/dev/null; then
            if ! cmp -s "$fixed_file" "$backup_file"; then
                log_pass "Import sorting applied successfully"
            fi
        fi
        rm -f "$backup_file"
        fixers_found=true
    fi
    
    if [ "$fixers_found" = false ]; then
        log_skip "Auto-fix (no formatters installed)"
    fi
}

generate_test_report() {
    log_info "Generating test report..."
    
    local summary_file="$REPORT_DIR/test_summary.txt"
    
    {
        echo "========================================"
        echo "Python Code Quality Checker Test Report"
        echo "========================================"
        echo ""
        echo "Test Date: $(date)"
        echo "Test Directory: $TEST_DIR"
        echo ""
        echo "Summary:"
        echo "  Tests Passed: $TESTS_PASSED"
        echo "  Tests Failed: $TESTS_FAILED"
        echo ""
        echo "Test Results:"
        for result in "${TEST_RESULTS[@]}"; do
            echo "  $result"
        done
        echo ""
        echo "Files Tested:"
        for file in "$TEST_DIR"/*.py; do
            if [ -f "$file" ]; then
                echo "  - $(basename "$file")"
            fi
        done
        echo ""
        if [ "$TESTS_FAILED" -eq 0 ]; then
            echo "Status: ALL TESTS PASSED"
        else
            echo "Status: SOME TESTS FAILED"
        fi
    } > "$summary_file"
    
    log_info "Test report saved to: $summary_file"
}

cleanup_test_files() {
    if [ "$KEEP_FILES" = true ]; then
        log_info "Keeping test files (cleanup skipped)"
        log_info "Test files location: $TEST_DIR"
        log_info "Reports location: $REPORT_DIR"
    else
        log_info "Cleaning up test files..."
        rm -rf "$TEST_DIR"
        log_info "Test files cleaned up"
    fi
}

print_summary() {
    echo ""
    echo "========================================"
    echo "Test Summary"
    echo "========================================"
    echo "Tests Passed: $TESTS_PASSED"
    echo "Tests Failed: $TESTS_FAILED"
    echo ""
    
    if [ "$TESTS_FAILED" -gt 0 ]; then
        echo "Some tests FAILED"
        return 1
    else
        echo "All tests PASSED"
        return 0
    fi
}

main() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --keep-files|-k)
                KEEP_FILES=true
                shift
                ;;
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --keep-files, -k    Keep test files after completion"
                echo "  --verbose, -v       Show verbose output"
                echo "  --help, -h          Show this help message"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    echo "Testing Python Code Quality Checker skill..."
    echo ""
    
    setup_test_environment
    create_test_files
    test_syntax_checking
    test_type_checking
    test_linting
    test_clean_code
    test_auto_fix
    generate_test_report
    cleanup_test_files
    print_summary
}

main "$@"
