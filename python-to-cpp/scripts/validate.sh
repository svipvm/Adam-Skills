#!/bin/bash

set -e

echo "=== C++ Code Validation Script ==="

if [ $# -eq 0 ]; then
    echo "Usage: $0 <source_dir>"
    exit 1
fi

SOURCE_DIR=$1

echo "Validating C++ code in: $SOURCE_DIR"

# Check required files
echo "[1/5] Checking file structure..."
if [ ! -f "$SOURCE_DIR/CMakeLists.txt" ]; then
    echo "ERROR: CMakeLists.txt not found"
    exit 1
fi

if [ ! -d "$SOURCE_DIR/src" ]; then
    echo "ERROR: src/ directory not found"
    exit 1
fi

# Check for main.cpp or main file
if [ ! -f "$SOURCE_DIR/src/main.cpp" ]; then
    echo "WARNING: main.cpp not found"
fi

# Check CMake syntax
echo "[2/5] Checking CMake syntax..."
if command -v cmake &> /dev/null; then
    mkdir -p "$SOURCE_DIR/build_temp"
    cd "$SOURCE_DIR/build_temp"
    cmake .. > /dev/null 2>&1 && echo "CMake: OK" || echo "CMake: FAILED"
    cd - > /dev/null
    rm -rf "$SOURCE_DIR/build_temp"
else
    echo "WARNING: cmake not installed, skipping CMake check"
fi

# Check C++ syntax
echo "[3/5] Checking C++ syntax..."
if command -v g++ &> /dev/null; then
    for src in $(find "$SOURCE_DIR/src" -name "*.cpp" 2>/dev/null); do
        g++ -fsyntax-only -std=c++17 "$src" 2>&1 && echo "  $src: OK" || echo "  $src: FAILED"
    done
else
    echo "WARNING: g++ not installed, skipping syntax check"
fi

# Check header guards
echo "[4/5] Checking header guards..."
for header in $(find "$SOURCE_DIR/include" -name "*.h" 2>/dev/null); do
    if grep -q "#ifndef" "$header" && grep -q "#define" "$header" && grep -q "#endif" "$header"; then
        echo "  $header: OK"
    else
        echo "  $header: WARNING - missing or incomplete header guard"
    fi
done

# Check for common issues
echo "[5/5] Checking for common issues..."
if grep -r "using namespace std" "$SOURCE_DIR/src" > /dev/null 2>&1; then
    echo "WARNING: 'using namespace std' found in source files"
fi

if grep -r "new " "$SOURCE_DIR/src" | grep -v "make_unique" > /dev/null 2>&1; then
    echo "WARNING: Raw 'new' operator found, consider using smart pointers"
fi

echo ""
echo "=== Validation Complete ==="
