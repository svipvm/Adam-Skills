# Error Handling

本模块提供错误处理框架，确保C++代码具有完善的异常处理和错误恢复机制。

## 异常类层次结构

### 基类定义

```cpp
#include <exception>
#include <string>
#include <memory>

class BaseException : public std::exception {
public:
    explicit BaseException(const std::string& message)
        : message_(message) {}
    
    const char* what() const noexcept override {
        return message_.c_str();
    }
    
protected:
    std::string message_;
};
```

### 业务异常类

```cpp
class InvalidArgumentException : public BaseException {
public:
    using BaseException::BaseException;
};

class RuntimeException : public BaseException {
public:
    using BaseException::BaseException;
};

class FileException : public BaseException {
public:
    FileException(const std::string& message, const std::string& path)
        : BaseException(message), path_(path) {}
    
    const std::string& path() const { return path_; }
    
private:
    std::string path_;
};

class NetworkException : public BaseException {
public:
    NetworkException(const std::string& message, int error_code)
        : BaseException(message), error_code_(error_code) {}
    
    int errorCode() const { return error_code_; }
    
private:
    int error_code_;
};
```

## 错误码枚举

### 错误码定义

```cpp
enum class ErrorCode {
    Success = 0,
    
    // 通用错误
    UnknownError = 1,
    InvalidArgument = 2,
    NullPointer = 3,
    
    // 文件错误
    FileNotFound = 100,
    PermissionDenied = 101,
    FileCorrupted = 102,
    
    // 网络错误
    ConnectionFailed = 200,
    Timeout = 201,
    InvalidResponse = 202,
    
    // 业务错误
    InvalidState = 300,
    NotImplemented = 301,
};
```

### Result类型

```cpp
template<typename T>
class Result {
public:
    static Result<T> ok(T value) {
        return Result<T>(std::move(value));
    }
    
    static Result<T> error(ErrorCode code, const std::string& message) {
        return Result<T>(code, message);
    }
    
    bool isOk() const { return ok_; }
    bool isError() const { return !ok_; }
    
    T& value() { return value_.value(); }
    const T& value() const { return value_.value(); }
    
    ErrorCode errorCode() const { return error_code_; }
    const std::string& errorMessage() const { return error_message_; }
    
private:
    explicit Result(T value) : ok_(true), value_(std::move(value)) {}
    Result(ErrorCode code, const std::string& message)
        : ok_(false), error_code_(code), error_message_(message) {}
    
    bool ok_;
    std::optional<T> value_;
    ErrorCode error_code_;
    std::string error_message_;
};
```

## 异常安全保证

### 基础保证

```cpp
class ResourceManager {
public:
    void process() {
        auto resource1 = acquireResource1();
        auto resource2 = acquireResource2();
        
        try {
            doProcess(resource1, resource2);
        } catch (...) {
            releaseResource1(resource1);
            releaseResource2(resource2);
            throw;
        }
        
        releaseResource1(resource1);
        releaseResource2(resource2);
    }
    
private:
    Resource acquireResource1();
    Resource acquireResource2();
    void releaseResource1(Resource& r);
    void releaseResource2(Resource& r);
    void doProcess(Resource& r1, Resource& r2);
};
```

### 强保证 (事务性)

```cpp
class TransactionManager {
public:
    void execute() {
        Transaction trans;
        
        try {
            trans.begin();
            doOperation1();
            doOperation2();
            doOperation3();
            trans.commit();
        } catch (...) {
            trans.rollback();
            throw;
        }
    }
};
```

## 断言与静态检查

### 运行时断言

```cpp
#include <cassert>
#include <stdexcept>

void validateInput(int value) {
    if (value < 0) {
        throw InvalidArgumentException("Value must be non-negative");
    }
    
    assert(value <= 100 && "Value should not exceed 100");
}
```

### 静态断言

```cpp
static_assert(sizeof(int) >= 4, "int must be at least 32 bits");
static_assert(std::is_trivially_destructible<MyClass>::value,
              "MyClass should be trivially destructible");
```

## 错误处理宏

```cpp
#define TRY(expr) \
    do { \
        auto _result = (expr); \
        if (!_result.isOk()) { \
            return Result<decltype(_result.value())>::error( \
                _result.errorCode(), _result.errorMessage()); \
        } \
    } while(0)

#define THROW_IF_NULL(ptr, msg) \
    if ((ptr) == nullptr) { \
        throw NullPointerException(msg); \
    }

#define CATCH_AND_LOG(exc_type) \
    catch (const exc_type& e) { \
        Logger::error("{}: {}", #exc_type, e.what()); \
    }
```

## 使用示例

```cpp
Result<int> divide(int a, int b) {
    if (b == 0) {
        return Result<int>::error(
            ErrorCode::InvalidArgument,
            "Division by zero"
        );
    }
    return Result<int>::ok(a / b);
}

void processData(const std::string& data) {
    try {
        auto result = parse(data);
        if (result.isError()) {
            Logger::error("Parse failed: {}", result.errorMessage());
            return;
        }
        
        auto processed = transform(result.value());
        save(processed);
        
    } catch (const FileException& e) {
        Logger::error("File error: {} - {}", e.path(), e.what());
        handleFileError(e);
    } catch (const std::exception& e) {
        Logger::error("Unexpected error: {}", e.what());
        throw;
    }
}
```
