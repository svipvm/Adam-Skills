# Python to C++ Conversion Examples

本文件提供Python代码到C++代码转换的详细示例。

## 示例1：简单类转换

### Python代码

```python
class Calculator:
    def __init__(self, initial_value=0):
        self.value = initial_value
    
    def add(self, n):
        self.value += n
        return self
    
    def subtract(self, n):
        self.value -= n
        return self
    
    def get_value(self):
        return self.value
```

### 转换后的C++代码

#### 头文件 (calculator.h)

```cpp
#ifndef PROJECT_CALCULATOR_H
#define PROJECT_CALCULATOR_H

#include <iostream>
#include <string>

class Calculator {
public:
    explicit Calculator(int initial_value = 0);
    
    Calculator& add(int n);
    Calculator& subtract(int n);
    int get_value() const;
    
private:
    int value_;
};

#endif  // PROJECT_CALCULATOR_H
```

#### 源文件 (calculator.cpp)

```cpp
#include "calculator.h"

Calculator::Calculator(int initial_value) 
    : value_(initial_value) {
}

Calculator& Calculator::add(int n) {
    value_ += n;
    return *this;
}

Calculator& Calculator::subtract(int n) {
    value_ -= n;
    return *this;
}

int Calculator::get_value() const {
    return value_;
}
```

#### 主程序 (main.cpp)

```cpp
#include <iostream>
#include <memory>
#include "calculator.h"

int main() {
    auto calc = std::make_unique<Calculator>(10);
    
    calc->add(5)->subtract(3);
    
    std::cout << "Result: " << calc->get_value() << std::endl;
    
    return 0;
}
```

## 示例2：带异常处理的转换

### Python代码

```python
class FileProcessor:
    def __init__(self, filename):
        self.filename = filename
        self.content = None
    
    def read_file(self):
        try:
            with open(self.filename, 'r') as f:
                self.content = f.read()
            return True
        except FileNotFoundError:
            print(f"File not found: {self.filename}")
            return False
        except PermissionError:
            print(f"Permission denied: {self.filename}")
            return False
    
    def process(self):
        if self.content is None:
            raise RuntimeError("File not loaded")
        return self.content.upper()
```

### 转换后的C++代码

#### 头文件

```cpp
#ifndef PROJECT_FILE_PROCESSOR_H
#define PROJECT_FILE_PROCESSOR_H

#include <string>
#include <fstream>
#include <stdexcept>

class FileException : public std::runtime_error {
public:
    FileException(const std::string& message, const std::string& path)
        : std::runtime_error(message), path_(path) {}
    
    const std::string& path() const { return path_; }
    
private:
    std::string path_;
};

class FileProcessor {
public:
    explicit FileProcessor(const std::string& filename);
    
    bool readFile();
    std::string process();
    
private:
    std::string filename_;
    std::string content_;
};

#endif  // PROJECT_FILE_PROCESSOR_H
```

#### 源文件

```cpp
#include "file_processor.h"
#include <iostream>

FileProcessor::FileProcessor(const std::string& filename)
    : filename_(filename) {
}

bool FileProcessor::readFile() {
    std::ifstream file(filename_);
    
    if (!file.is_open()) {
        std::cerr << "File not found: " << filename_ << std::endl;
        return false;
    }
    
    if (file.fail()) {
        std::cerr << "Permission denied: " << filename_ << std::endl;
        return false;
    }
    
    std::stringstream buffer;
    buffer << file.rdbuf();
    content_ = buffer.str();
    
    return true;
}

std::string FileProcessor::process() {
    if (content_.empty()) {
        throw std::runtime_error("File not loaded");
    }
    
    std::string result = content_;
    std::transform(result.begin(), result.end(), result.begin(), ::toupper);
    return result;
}
```

## 示例3：数据结构的转换

### Python代码

```python
from typing import Dict, List

class DataManager:
    def __init__(self):
        self.users: Dict[str, int] = {}
        self.scores: List[int] = []
    
    def add_user(self, name: str, age: int):
        self.users[name] = age
    
    def add_score(self, score: int):
        self.scores.append(score)
    
    def get_average_score(self) -> float:
        if not self.scores:
            return 0.0
        return sum(self.scores) / len(self.scores)
    
    def get_user_age(self, name: str) -> int:
        return self.users.get(name, 0)
```

### 转换后的C++代码

```cpp
#include <string>
#include <map>
#include <vector>
#include <numeric>
#include <stdexcept>

class DataManager {
public:
    DataManager() = default;
    
    void addUser(const std::string& name, int age) {
        users_[name] = age;
    }
    
    void addScore(int score) {
        scores_.push_back(score);
    }
    
    double getAverageScore() const {
        if (scores_.empty()) {
            return 0.0;
        }
        
        int sum = std::accumulate(scores_.begin(), scores_.end(), 0);
        return static_cast<double>(sum) / scores_.size();
    }
    
    int getUserAge(const std::string& name) const {
        auto it = users_.find(name);
        if (it != users_.end()) {
            return it->second;
        }
        return 0;
    }
    
private:
    std::map<std::string, int> users_;
    std::vector<int> scores_;
};
```

## 示例4：单例模式的转换

### Python代码

```python
class ConfigManager:
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._initialized = False
        return cls._instance
    
    def __init__(self):
        if self._initialized:
            return
        self._initialized = True
        self.config = {}
    
    def set(self, key, value):
        self.config[key] = value
    
    def get(self, key, default=None):
        return self.config.get(key, default)
```

### 转换后的C++代码

```cpp
#include <string>
#include <map>
#include <memory>

class ConfigManager {
public:
    static ConfigManager& getInstance() {
        static ConfigManager instance;
        return instance;
    }
    
    void set(const std::string& key, const std::string& value) {
        config_[key] = value;
    }
    
    std::string get(const std::string& key, 
                    const std::string& default_value = "") const {
        auto it = config_.find(key);
        if (it != config_.end()) {
            return it->second;
        }
        return default_value;
    }
    
    ConfigManager(const ConfigManager&) = delete;
    ConfigManager& operator=(const ConfigManager&) = delete;

private:
    ConfigManager() = default;
    ~ConfigManager() = default;
    
    std::map<std::string, std::string> config_;
};
```

## 示例5：生成的项目结构

转换后生成的完整项目结构：

```
my-project/
├── CMakeLists.txt
├── README.md
├── LICENSE
├── src/
│   ├── main.cpp
│   ├── calculator.cpp
│   ├── calculator.h
│   ├── file_processor.cpp
│   └── file_processor.h
├── include/
│   └── my-project/
│       └── exception.h
├── tests/
│   ├── test_calculator.cpp
│   └── test_file_processor.cpp
├── scripts/
│   ├── build.sh
│   └── run.sh
└── external/
    └── (dependencies)
```

### CMakeLists.txt内容

```cmake
cmake_minimum_required(VERSION 3.16)
project(my-project VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Wpedantic")
set(CMAKE_CXX_FLAGS_DEBUG "-g -O0 -fsanitize=address")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

include_directories(include)

file(GLOB SOURCES "src/*.cpp")
add_executable(${PROJECT_NAME} ${SOURCES})

target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_17)

install(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION bin)
```

### build.sh内容

```bash
#!/bin/bash
set -e

BUILD_TYPE=${1:-Release}
BUILD_DIR=build/${BUILD_TYPE}

mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

cmake .. -DCMAKE_BUILD_TYPE=${BUILD_TYPE}
make -j$(nproc)

echo "==================================="
echo "Build complete!"
echo "Executable: ${BUILD_DIR}/my-project"
echo "==================================="
```

### run.sh内容

```bash
#!/bin/bash
set -e

BUILD_DIR=${1:-build/Release}
BINARY_PATH=${BUILD_DIR}/my-project

if [ ! -f "$BINARY_PATH" ]; then
    echo "Binary not found. Building..."
    ./build.sh
fi

echo "Running my-project..."
$BINARY_PATH "$@"
```
