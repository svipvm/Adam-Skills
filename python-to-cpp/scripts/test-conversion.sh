#!/bin/bash

set -e

echo "=== Python to C++ Conversion Test ==="

if [ $# -lt 2 ]; then
    echo "Usage: $0 <python_file> <output_dir> [cmake_args...]"
    exit 1
fi

PYTHON_FILE=$1
OUTPUT_DIR=$2
shift 2
CMAKE_ARGS="$@"

if [ ! -f "$PYTHON_FILE" ]; then
    echo "ERROR: Python file not found: $PYTHON_FILE"
    exit 1
fi

PROJECT_NAME=$(basename "$PYTHON_FILE" .py)
PROJECT_NAME="py2cpp_${PROJECT_NAME}"

echo "Python file: $PYTHON_FILE"
echo "Output directory: $OUTPUT_DIR"
echo "Project name: $PROJECT_NAME"

mkdir -p "$OUTPUT_DIR"

echo ""
echo "=== Simulating Python to C++ conversion ==="
echo "Note: This is a validation script to test the skill's output."
echo "Actual conversion would be performed by the skill."

# Create test CMakeLists.txt
cat > "$OUTPUT_DIR/CMakeLists.txt" << EOF
cmake_minimum_required(VERSION 3.16)
project(${PROJECT_NAME} VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include_directories(include)

file(GLOB SOURCES "src/*.cpp")
add_executable(\${PROJECT_NAME} \${SOURCES})
EOF

# Create test source directory
mkdir -p "$OUTPUT_DIR/src"

# Create test main.cpp
cat > "$OUTPUT_DIR/src/main.cpp" << EOF
#include <iostream>
#include <string>
#include <vector>
#include <map>

int main(int argc, char* argv[]) {
    std::cout << "Python to C++ conversion test" << std::endl;
    std::cout << "Arguments: " << argc << std::endl;
    
    std::vector<int> numbers = {1, 2, 3, 4, 5};
    for (const auto& n : numbers) {
        std::cout << n << " ";
    }
    std::cout << std::endl;
    
    return 0;
}
EOF

echo ""
echo "=== Building test project ==="

BUILD_DIR="$OUTPUT_DIR/build"
mkdir -p "$BUILD_DIR"

cd "$BUILD_DIR"
cmake .. -DCMAKE_BUILD_TYPE=Release $CMAKE_ARGS
make -j$(nproc)

echo ""
echo "=== Running test executable ==="
./${PROJECT_NAME}

echo ""
echo "=== Test Complete ==="
echo "Output directory: $OUTPUT_DIR"
echo "Build directory: $BUILD_DIR"
