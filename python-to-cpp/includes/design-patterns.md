# Design Patterns

本模块提供设计模式应用指南，根据Python代码场景自动应用适当的设计模式。

## 单例模式 (Singleton)

### 适用场景

- 全局配置管理器
- 日志系统
- 数据库连接池
- 缓存管理器

### Python代码

```python
class ConfigManager:
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
```

### C++实现

```cpp
class ConfigManager {
public:
    static ConfigManager& getInstance() {
        static ConfigManager instance;
        return instance;
    }
    
    void load(const std::string& path);
    std::string get(const std::string& key) const;
    
private:
    ConfigManager() = default;
    ~ConfigManager() = default;
    
    ConfigManager(const ConfigManager&) = delete;
    ConfigManager& operator=(const ConfigManager&) = delete;
    
    std::map<std::string, std::string> config_;
};
```

## 工厂模式 (Factory)

### 适用场景

- 对象创建逻辑复杂
- 需要根据条件创建不同类型的对象
- 解耦对象创建和使用

### Python代码

```python
class Dog:
    def speak(self):
        return "Woof!"

class Cat:
    def speak(self):
        return "Meow!"

def create_pet(pet_type):
    pets = {"dog": Dog, "cat": Cat}
    return pets[pet_type]()
```

### C++实现

```cpp
class Animal {
public:
    virtual ~Animal() = default;
    virtual std::string speak() const = 0;
};

class Dog : public Animal {
public:
    std::string speak() const override { return "Woof!"; }
};

class Cat : public Animal {
public:
    std::string speak() const override { return "Meow!"; }
};

class AnimalFactory {
public:
    static std::unique_ptr<Animal> create(const std::string& type) {
        if (type == "dog") return std::make_unique<Dog>();
        if (type == "cat") return std::make_unique<Cat>();
        return nullptr;
    }
};
```

## 观察者模式 (Observer)

### 适用场景

- 事件处理系统
- GUI事件
- 消息订阅发布
- 状态变化通知

### Python代码

```python
class Subject:
    def __init__(self):
        self._observers = []
    
    def attach(self, observer):
        self._observers.append(observer)
    
    def notify(self):
        for observer in self._observers:
            observer.update()
```

### C++实现

```cpp
class Observer {
public:
    virtual ~Observer() = default;
    virtual void update() = 0;
};

class Subject {
public:
    void attach(std::shared_ptr<Observer> observer) {
        observers_.push_back(observer);
    }
    
    void detach(std::shared_ptr<Observer> observer) {
        observers_.erase(
            std::remove(observers_.begin(), observers_.end(), observer),
            observers_.end()
        );
    }
    
    void notify() {
        for (auto& obs : observers_) {
            obs->update();
        }
    }
    
private:
    std::vector<std::shared_ptr<Observer>> observers_;
};
```

## RAII模式

### 适用场景

- 文件操作
- 网络连接
- 内存管理
- 锁管理

### Python代码

```python
with open("file.txt", "r") as f:
    content = f.read()
```

### C++实现

```cpp
class FileGuard {
public:
    explicit FileGuard(const std::string& path, std::ios::openmode mode)
        : stream_(path, mode) {
        if (!stream_.is_open()) {
            throw std::runtime_error("Failed to open file: " + path);
        }
    }
    
    ~FileGuard() {
        if (stream_.is_open()) {
            stream_.close();
        }
    }
    
    std::fstream& stream() { return stream_; }
    
private:
    std::fstream stream_;
};

// 使用
{
    FileGuard file("file.txt", std::ios::in);
    std::string content((std::istreambuf_iterator<char>(file.stream())),
                         std::istreambuf_iterator<char>());
}
```

### 智能指针

```cpp
// unique_ptr
auto ptr = std::make_unique<Resource>();

// shared_ptr
auto shared = std::make_shared<Resource>();

// 自定义删除器
auto file = std::unique_ptr<FILE, decltype(&fclose)>(
    fopen("file.txt", "r"), fclose
);
```

## 策略模式 (Strategy)

### 适用场景

- 算法切换
- 不同处理方式
- 运行时选择行为

### Python代码

```python
class SortStrategy:
    def sort(self, data):
        pass

class QuickSort(SortStrategy):
    def sort(self, data):
        # 快速排序实现
        pass

class Context:
    def __init__(self, strategy):
        self.strategy = strategy
    
    def execute(self, data):
        return self.strategy.sort(data)
```

### C++实现

```cpp
class SortStrategy {
public:
    virtual ~SortStrategy() = default;
    virtual void sort(std::vector<int>& data) = 0;
};

class QuickSort : public SortStrategy {
public:
    void sort(std::vector<int>& data) override {
        // 快速排序实现
    }
};

class Context {
public:
    explicit Context(std::unique_ptr<SortStrategy> strategy)
        : strategy_(std::move(strategy)) {}
    
    void execute(std::vector<int>& data) {
        strategy_->sort(data);
    }
    
    void setStrategy(std::unique_ptr<SortStrategy> strategy) {
        strategy_ = std::move(strategy);
    }
    
private:
    std::unique_ptr<SortStrategy> strategy_;
};
```

## 装饰器模式 (Decorator)

### 适用场景

- 动态添加功能
- 功能扩展
- 责任链

### Python代码

```python
def log_calls(func):
    def wrapper(*args, **kwargs):
        print(f"Calling {func.__name__}")
        result = func(*args, **kwargs)
        print(f"Finished {func.__name__}")
        return result
    return wrapper

@log_calls
def process():
    pass
```

### C++实现

```cpp
class Processor {
public:
    virtual ~Processor() = default;
    virtual void process() = 0;
};

class BaseProcessor : public Processor {
public:
    void process() override {
        // 基础处理
    }
};

class LoggingDecorator : public Processor {
public:
    explicit LoggingDecorator(std::unique_ptr<Processor> wrapped)
        : wrapped_(std::move(wrapped)) {}
    
    void process() override {
        std::cout << "Calling process" << std::endl;
        wrapped_->process();
        std::cout << "Finished process" << std::endl;
    }
    
private:
    std::unique_ptr<Processor> wrapped_;
};
```
