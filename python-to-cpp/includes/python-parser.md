# Python Parser

本模块提供Python代码解析功能，用于提取Python代码的结构元素。

## 解析能力

### 支持的代码元素

1. **模块导入**
   - `import module`
   - `from module import name`
   - `from module import name as alias`

2. **类定义**
   - 类名
   - 继承的父类
   - 类的属性和方法

3. **函数定义**
   - 函数名
   - 参数列表
   - 默认参数
   - 返回类型注解（如果有）
   - 函数体

4. **变量赋值**
   - 简单赋值：`x = value`
   - 多重赋值：`a, b = 1, 2`
   - 解包赋值：`a, *b = list`

5. **控制流**
   - 条件语句：`if`, `elif`, `else`
   - 循环：`for`, `while`
   - 循环控制：`break`, `continue`

6. **异常处理**
   - `try`, `except`, `finally`
   - 异常类型捕获

## 解析结果格式

解析结果以结构化方式返回：

```json
{
  "imports": [
    {"type": "import", "module": "os", "names": []},
    {"type": "from_import", "module": "sys", "names": ["argv"]}
  ],
  "classes": [
    {
      "name": "ClassName",
      "base_classes": ["ParentClass"],
      "methods": [
        {
          "name": "method_name",
          "params": [{"name": "param1", "default": null}],
          "body": "..."
        }
      ]
    }
  ],
  "functions": [
    {
      "name": "function_name",
      "params": [...],
      "return_type": "int",
      "body": "..."
    }
  ],
  "variables": [...]
}
```

## 类型推断

### 基本类型

Python类型 | 推断C++类型
----------|------------
`int` | `int32_t`
`float` | `double`
`str` | `std::string`
`bool` | `bool`
`bytes` | `std::vector<uint8_t>`

### 容器类型

Python类型 | 推断C++类型
----------|------------
`list` | `std::vector<T>`
`dict` | `std::map<K, V>`
`tuple` | `std::tuple<...>`
`set` | `std::set<T>`
`frozenset` | `std::set<T>`

### 特殊类型

Python类型 | 推断C++类型
----------|------------
`None` | `nullptr`
`Any` | `std::any`
`Callable` | `std::function`

## 使用示例

### 解析类

输入：
```python
class MyClass(BaseClass):
    def __init__(self, value):
        self.value = value

    def get_value(self):
        return self.value
```

解析结果：
- 类名：`MyClass`
- 父类：`BaseClass`
- 方法：`__init__`, `get_value`
- 属性：`value`

### 解析函数

输入：
```python
def calculate(a: int, b: int = 10) -> int:
    return a + b
```

解析结果：
- 函数名：`calculate`
- 参数：`a` (int), `b` (int, 默认值10)
- 返回类型：`int`
