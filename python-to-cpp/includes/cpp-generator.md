# C++ Code Generator

本模块提供C++代码生成功能，将解析后的Python代码转换为等效的C++代码。

## 代码生成原则

### 1. 功能等效

转换后的C++代码必须保持与原Python代码相同的功能逻辑。

### 2. 类型安全

使用强类型系统，避免使用`void*`或原始指针。

### 3. 内存安全

优先使用智能指针，避免内存泄漏。

### 4. 异常安全

使用RAII和异常规范确保异常安全。

## 类转换

### Python类

```python
class MyClass:
    def __init__(self, value):
        self.value = value
    
    def method(self, param):
        return self.value + param
```

### C++类

```cpp
class MyClass {
public:
    explicit MyClass(int value) : value_(value) {}
    
    int method(int param) const {
        return value_ + param;
    }
    
private:
    int value_;
};
```

### 转换规则

1. `__init__` → 构造函数
2. `self` → 移除（隐式this）
3. `self.param` → `member_`
4. 实例方法添加`const`限定符（如果不会修改成员）
5. 公有成员使用`public:`，私有成员使用`private:`

## 函数转换

### Python函数

```python
def add(a: int, b: int = 0) -> int:
    return a + b
```

### C++函数

```cpp
int add(int a, int b = 0) {
    return a + b;
}
```

### 转换规则

1. 类型注解 → C++类型
2. 默认参数 → 默认参数值
3. `return` → 直接返回
4. `print()` → `std::cout <<`
5. `None` → `void`或`nullptr`

## 控制流转换

### 条件语句

Python:
```python
if x > 0:
    print("positive")
elif x < 0:
    print("negative")
else:
    print("zero")
```

C++:
```cpp
if (x > 0) {
    std::cout << "positive" << std::endl;
} else if (x < 0) {
    std::cout << "negative" << std::endl;
} else {
    std::cout << "zero" << std::endl;
}
```

### 循环

Python:
```python
for item in items:
    print(item)
```

C++:
```cpp
for (const auto& item : items) {
    std::cout << item << std::endl;
}
```

### While循环

Python:
```python
while x > 0:
    x -= 1
```

C++:
```cpp
while (x > 0) {
    --x;
}
```

## 异常处理

### Python

```python
try:
    result = risky_operation()
except ValueError as e:
    print(f"Error: {e}")
finally:
    cleanup()
```

### C++

```cpp
try {
    auto result = risky_operation();
} catch (const ValueError& e) {
    std::cerr << "Error: " << e.what() << std::endl;
} catch (...) {
    // catch all
} finally {
    cleanup();  // 使用RAII替代
}
```

## 标准库映射

### 输入输出

Python | C++
-------|------
`print(x)` | `std::cout << x << std::endl;`
`input()` | `std::getline(std::cin, str);`
`open(file)` | `std::ifstream` / `std::ofstream`

### 容器操作

Python | C++
-------|------
`len(list)` | `list.size()`
`list.append(x)` | `list.push_back(x);`
`list[0]` | `list[0]` 或 `list.at(0)`
`dict.keys()` | `for (auto& [k,v] : dict)`
`dict.get(k, default)` | `dict.count(k) ? dict[k] : default`

### 字符串操作

Python | C++
-------|------
`"{}".format(x)` | `fmt::format("{}", x)` 或 `std::to_string`
`s.upper()` | `std::transform(s.begin(), s.end(), s.begin(), ::toupper)`
`s.split(',')` | `std::stringstream` 分割
`int(s)` | `std::stoi(s)`

## 代码组织

### 头文件 (.h)

```cpp
#ifndef PROJECT_CLASS_NAME_H
#define PROJECT_CLASS_NAME_H

#include <string>

class ClassName {
public:
    ClassName();
    ~ClassName();
    
    void method();
    
private:
    std::string member_;
};

#endif  // PROJECT_CLASS_NAME_H
```

### 源文件 (.cpp)

```cpp
#include "class_name.h"

ClassName::ClassName() : member_("default") {
}

ClassName::~ClassName() = default;

void ClassName::method() {
}
```

### main.cpp模板

```cpp
#include <iostream>
#include <memory>
#include "class_name.h"

int main(int argc, char* argv[]) {
    try {
        auto obj = std::make_unique<ClassName>();
        obj->method();
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
}
```
