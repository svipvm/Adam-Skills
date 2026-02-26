---
name: "python-to-cpp"
description: "将Python代码转换为C++代码，支持CMake构建和Linux部署。Invoke when用户需要将Python项目迁移到C++或需要高性能C++实现。"
version: "1.0.0"
requires:
  - skill: skill-creator-pro
    optional: true
includes:
  - includes/python-parser.md
  - includes/cpp-generator.md
  - includes/cmake-generator.md
  - includes/design-patterns.md
  - includes/error-handling.md
  - includes/logging.md
context:
  - context/examples.md
performance:
  lazy_load: true
  cache: true
---

# Python to C++ Converter

这是一个专业的Python到C++代码转换技能，支持将Python代码转换为工业级C++代码。

## 核心功能

- **Python代码解析**：提取类、函数、变量、导入等代码元素
- **C++代码生成**：生成等效的C++代码，保持功能一致性
- **CMake构建系统**：自动生成CMakeLists.txt，支持一键编译
- **包管理配置**：支持Conan或CMake子模块依赖管理
- **错误处理框架**：统一的异常处理和错误码机制
- **日志系统**：多级别日志输出
- **设计模式应用**：根据场景应用适当的设计模式

## 使用场景

### 场景1：Python项目迁移到Linux

当用户需要将Python应用部署到Linux生产环境时，可以使用此技能转换代码。

### 场景2：性能优化

当Python代码计算密集，需要转换为高性能C++时使用。

### 场景3：跨平台部署

当需要将Python代码移植到不支持Python的环境时使用。

## 转换流程

### 步骤1：解析Python代码

使用 `[[include:python-parser]]` 模块解析Python代码结构。

### 步骤2：生成C++代码

使用 `[[include:cpp-generator]]` 模块生成C++代码。

### 步骤3：生成构建系统

使用 `[[include:cmake-generator]]` 模块生成CMake配置。

### 步骤4：添加错误处理和日志

使用 `[[include:error-handling]]` 和 `[[include:logging]]` 模块。

### 步骤5：应用设计模式

使用 `[[include:design-patterns]]` 模块优化代码结构。

## 数据类型映射

| Python类型 | C++类型 | 说明 |
|------------|---------|------|
| `int` | `int32_t` | 32位整数 |
| `float` | `double` | 浮点数 |
| `str` | `std::string` | 字符串 |
| `bool` | `bool` | 布尔值 |
| `list` | `std::vector<T>` | 动态数组 |
| `dict` | `std::map<K,V>` | 键值对 |
| `tuple` | `std::tuple<...>` | 元组 |
| `set` | `std::set<T>` | 集合 |
| `None` | `nullptr` | 空值 |

## 代码示例

### 输入 (Python)

```python
class Calculator:
    def add(self, a, b):
        return a + b

    def multiply(self, a, b):
        return a * b
```

### 输出 (C++)

```cpp
class Calculator {
public:
    int add(int a, int b) { return a + b; }
    int multiply(int a, int b) { return a * b; }
};
```

## 生成的项目结构

转换后的C++项目结构如下：

```
project-name/
├── CMakeLists.txt
├── src/
│   ├── main.cpp
│   ├── calculator.cpp
│   └── calculator.h
├── include/
│   └── project-name/
├── build/
├── build.sh
└── run.sh
```

## 使用方法

1. **提供Python代码**：将需要转换的Python代码提供给技能
2. **指定项目名称**：提供转换后的C++项目名称
3. **指定依赖**：列出Python代码中使用的第三方库
4. **生成代码**：技能将生成完整的C++项目结构

## 生成的CMakeLists.txt特性

- 符合Google C++ Style Guide
- 支持Debug和Release构建
- 启用详细编译警告
- 自动检测编译器特性
- 生成静态库或可执行文件

## 错误处理

转换后的代码包含：

- 自定义异常类继承自 `std::exception`
- 统一错误码枚举
- RAII资源管理
- 异常安全保证

## 日志系统

生成的日志系统支持：

- DEBUG：调试信息
- INFO：一般信息
- WARNING：警告信息
- ERROR：错误信息

日志格式：`[LEVEL] [timestamp] message`

## 设计模式应用

技能会根据代码场景自动应用：

- **单例模式**：全局配置管理器
- **工厂模式**：复杂对象创建
- **观察者模式**：事件处理系统
- **RAII**：文件、网络等资源管理

## 相关文件

- [[include:python-parser]]
- [[include:cpp-generator]]
- [[include:cmake-generator]]
- [[include:design-patterns]]
- [[include:error-handling]]
- [[include:logging]]
- [[load:context/examples]]
