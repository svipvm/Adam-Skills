# CMake Generator

本模块提供CMake构建系统生成功能，为转换后的C++项目生成完整的构建配置。

## CMakeLists.txt模板

### 基础模板

```cmake
cmake_minimum_required(VERSION 3.16)
project(ProjectName VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -g -O0 -fsanitize=address")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3 -DNDEBUG")

include_directories(include)

file(GLOB SOURCES "src/*.cpp")

add_executable(${PROJECT_NAME} ${SOURCES})

target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_17)
```

## 项目结构配置

### 目录结构

```
project/
├── CMakeLists.txt
├── src/
│   ├── main.cpp
│   └── ...
├── include/
│   └── project/
│       └── *.h
├── tests/
└── external/
```

### CMakeLists.txt配置

```cmake
# 设置输出目录
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# 调试符号
set(CMAKE_CXX_FLAGS_DEBUG "-g -O0 -fsanitize=address -fno-omit-frame-pointer")

# 发布优化
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG -march=native")

# 启用链接时优化
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
```

## 依赖管理

### 使用FetchContent（推荐）

```cmake
include(FetchContent)

FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG v1.14.0
)

FetchContent_MakeAvailable(googletest)
```

### 使用Conan

```cmake
find_package(Boost 1.75 REQUIRED)
find_package(nlohmann_json 3.10.5 REQUIRED)
```

## 编译选项

### 警告级别

```cmake
# 基础警告
add_compile_options(-Wall -Wextra)

# 额外警告
add_compile_options(
    -Wpedantic
    -Werror
    -Wconversion
    -Wshadow
    -Wformat=2
)
```

### 代码分析

```cmake
# Clang-Tidy
set(CMAKE_CXX_CLANG_TIDY 
    clang-tidy
    -header-filter=.*
    -checks=*,-modernize-*
)

# Cppcheck
set(CMAKE_CXX_CPPCHECK 
    cppcheck
    --enable=all
    --inline-suppr
)
```

## 测试配置

### 使用Google Test

```cmake
enable_testing()

add_executable(test_runner test/test_main.cpp)

target_link_libraries(test_runner
    PRIVATE
    ${PROJECT_NAME}
    GTest::gtest_main
)

include(GoogleTest)
gtest_discover_tests(test_runner)
```

## 安装配置

```cmake
install(TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)

install(DIRECTORY include/${PROJECT_NAME}/
    DESTINATION include
)
```

## 构建脚本

### build.sh

```bash
#!/bin/bash
set -e

BUILD_TYPE=${1:-Release}
BUILD_DIR=build/${BUILD_TYPE}

mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

cmake .. -DCMAKE_BUILD_TYPE=${BUILD_TYPE}
make -j$(nproc)

echo "Build complete: ${BUILD_DIR}/${PROJECT_NAME}"
```

### run.sh

```bash
#!/bin/bash
set -e

BUILD_DIR=${1:-build/Release}
BINARY_PATH=${BUILD_DIR}/project_name

if [ ! -f "$BINARY_PATH" ]; then
    echo "Binary not found. Building..."
    ./build.sh
fi

$BINARY_PATH "$@"
```

## 一键构建

```bash
chmod +x build.sh run.sh
./build.sh
./run.sh
```

## 多平台支持

```cmake
if(WIN32)
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
elseif(UNIX)
    add_definitions(-DLINUX)
endif()
```
