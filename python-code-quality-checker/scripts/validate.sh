#!/bin/bash
#
# validate.sh - Validates the skill structure completeness
#
# This script checks:
# - All required files exist (SKILL.md, INDEX.md)
# - All includes/ modules are present
# - Proper frontmatter in SKILL.md
# - Valid directory structure
#
# Usage: ./validate.sh [--verbose] [--json]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(dirname "$SCRIPT_DIR")"

VERBOSE=false
JSON_OUTPUT=false
ERRORS=0
WARNINGS=0
VALIDATION_RESULTS=()

log_info() {
    if [ "$VERBOSE" = true ]; then
        echo "[INFO] $1"
    fi
    VALIDATION_RESULTS+=("INFO: $1")
}

log_error() {
    echo "[ERROR] $1" >&2
    VALIDATION_RESULTS+=("ERROR: $1")
    ERRORS=$((ERRORS + 1))
}

log_warning() {
    echo "[WARNING] $1" >&2
    VALIDATION_RESULTS+=("WARNING: $1")
    WARNINGS=$((WARNINGS + 1))
}

log_success() {
    if [ "$VERBOSE" = true ]; then
        echo "[OK] $1"
    fi
    VALIDATION_RESULTS+=("OK: $1")
}

check_required_files() {
    log_info "Checking required files..."
    
    local required_files=(
        "SKILL.md"
        "INDEX.md"
    )
    
    for file in "${required_files[@]}"; do
        local filepath="$SKILL_ROOT/$file"
        if [ -f "$filepath" ]; then
            log_success "Required file exists: $file"
        else
            log_error "Missing required file: $file"
        fi
    done
}

check_directory_structure() {
    log_info "Checking directory structure..."
    
    local required_dirs=(
        "includes"
    )
    
    for dir in "${required_dirs[@]}"; do
        local dirpath="$SKILL_ROOT/$dir"
        if [ -d "$dirpath" ]; then
            log_success "Directory exists: $dir"
        else
            log_error "Missing required directory: $dir"
        fi
    done
    
    local optional_dirs=(
        "scripts"
        "context"
        "types"
    )
    
    for dir in "${optional_dirs[@]}"; do
        local dirpath="$SKILL_ROOT/$dir"
        if [ -d "$dirpath" ]; then
            log_success "Optional directory exists: $dir"
        else
            log_warning "Optional directory missing: $dir"
        fi
    done
}

check_frontmatter() {
    log_info "Checking SKILL.md frontmatter..."
    
    local skill_md="$SKILL_ROOT/SKILL.md"
    
    if [ ! -f "$skill_md" ]; then
        log_error "Cannot check frontmatter: SKILL.md not found"
        return 1
    fi
    
    local in_frontmatter=false
    local frontmatter_start=-1
    local frontmatter_end=-1
    local line_num=0
    
    while IFS= read -r line || [ -n "$line" ]; do
        line_num=$((line_num + 1))
        
        if [ "$line" = "---" ]; then
            if [ "$frontmatter_start" -eq -1 ]; then
                frontmatter_start=$line_num
                in_frontmatter=true
            elif [ "$frontmatter_end" -eq -1 ]; then
                frontmatter_end=$line_num
                in_frontmatter=false
                break
            fi
        fi
    done < "$skill_md"
    
    if [ "$frontmatter_start" -eq 1 ] && [ "$frontmatter_end" -gt 1 ]; then
        log_success "Frontmatter delimiters found (lines $frontmatter_start-$frontmatter_end)"
    else
        log_error "Invalid frontmatter format in SKILL.md"
        return 1
    fi
    
    local required_fields=(
        "name"
        "description"
        "version"
    )
    
    for field in "${required_fields[@]}"; do
        if grep -q "^${field}:" "$skill_md" 2>/dev/null; then
            log_success "Frontmatter field found: $field"
        else
            log_error "Missing required frontmatter field: $field"
        fi
    done
    
    local optional_fields=(
        "requires"
        "includes"
        "performance"
    )
    
    for field in "${optional_fields[@]}"; do
        if grep -q "^${field}:" "$skill_md" 2>/dev/null; then
            log_success "Optional frontmatter field found: $field"
        else
            log_info "Optional frontmatter field not present: $field"
        fi
    done
}

check_includes_modules() {
    log_info "Checking includes modules..."
    
    local includes_dir="$SKILL_ROOT/includes"
    
    if [ ! -d "$includes_dir" ]; then
        log_error "Includes directory not found"
        return 1
    fi
    
    local expected_modules=(
        "syntax-checker.md"
        "type-checker.md"
        "tool-integration.md"
        "auto-fixer.md"
        "auto-trigger.md"
        "config-manager.md"
        "performance-optimizer.md"
        "report-generator.md"
    )
    
    for module in "${expected_modules[@]}"; do
        local module_path="$includes_dir/$module"
        if [ -f "$module_path" ]; then
            log_success "Include module exists: $module"
            
            if [ ! -s "$module_path" ]; then
                log_warning "Include module is empty: $module"
            fi
        else
            log_warning "Include module missing: $module"
        fi
    done
    
    local found_modules=()
    while IFS= read -r -d '' file; do
        found_modules+=("$(basename "$file")")
    done < <(find "$includes_dir" -name "*.md" -print0 2>/dev/null)
    
    for module in "${found_modules[@]}"; do
        if [[ ! " ${expected_modules[*]} " =~ " ${module} " ]]; then
            log_info "Additional include module found: $module"
        fi
    done
}

check_scripts() {
    log_info "Checking scripts..."
    
    local scripts_dir="$SKILL_ROOT/scripts"
    
    if [ ! -d "$scripts_dir" ]; then
        log_warning "Scripts directory not found"
        return 0
    fi
    
    local expected_scripts=(
        "validate.sh"
        "test.sh"
        "install-tools.sh"
    )
    
    for script in "${expected_scripts[@]}"; do
        local script_path="$scripts_dir/$script"
        if [ -f "$script_path" ]; then
            log_success "Script exists: $script"
            
            if [ ! -x "$script_path" ]; then
                log_warning "Script is not executable: $script"
            fi
        else
            log_info "Script not found: $script"
        fi
    done
}

check_index_consistency() {
    log_info "Checking INDEX.md consistency..."
    
    local index_md="$SKILL_ROOT/INDEX.md"
    
    if [ ! -f "$index_md" ]; then
        log_error "Cannot check consistency: INDEX.md not found"
        return 1
    fi
    
    local includes_dir="$SKILL_ROOT/includes"
    if [ -d "$includes_dir" ]; then
        for file in "$includes_dir"/*.md; do
            if [ -f "$file" ]; then
                local basename=$(basename "$file")
                if grep -q "$basename" "$index_md" 2>/dev/null; then
                    log_success "INDEX.md references: $basename"
                else
                    log_warning "INDEX.md missing reference to: $basename"
                fi
            fi
        done
    fi
}

print_summary() {
    echo ""
    echo "========================================"
    echo "Validation Summary"
    echo "========================================"
    echo "Skill Root: $SKILL_ROOT"
    echo "Errors: $ERRORS"
    echo "Warnings: $WARNINGS"
    echo ""
    
    if [ "$JSON_OUTPUT" = true ]; then
        echo ""
        echo "{"
        echo "  \"skill_root\": \"$SKILL_ROOT\","
        echo "  \"errors\": $ERRORS,"
        echo "  \"warnings\": $WARNINGS,"
        echo "  \"passed\": $([ "$ERRORS" -eq 0 ] && echo "true" || echo "false"),"
        echo "  \"results\": ["
        local first=true
        for result in "${VALIDATION_RESULTS[@]}"; do
            if [ "$first" = true ]; then
                first=false
            else
                echo ","
            fi
            echo -n "    \"$result\""
        done
        echo ""
        echo "  ]"
        echo "}"
    fi
    
    if [ "$ERRORS" -gt 0 ]; then
        echo "Validation FAILED with $ERRORS error(s)"
        return 1
    else
        echo "Validation PASSED"
        if [ "$WARNINGS" -gt 0 ]; then
            echo "  (with $WARNINGS warning(s))"
        fi
        return 0
    fi
}

main() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --json|-j)
                JSON_OUTPUT=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --verbose, -v    Show verbose output"
                echo "  --json, -j       Output results in JSON format"
                echo "  --help, -h       Show this help message"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    echo "Validating Python Code Quality Checker skill..."
    echo "Skill root: $SKILL_ROOT"
    echo ""
    
    check_required_files
    check_directory_structure
    check_frontmatter
    check_includes_modules
    check_scripts
    check_index_consistency
    
    print_summary
}

main "$@"
