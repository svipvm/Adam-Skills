# Logging

本模块提供统一的日志系统，支持多级别日志输出、时间戳、格式化输出等功能。

## 日志级别

### 级别定义

```cpp
enum class LogLevel {
    DEBUG = 0,
    INFO = 1,
    WARNING = 2,
    ERROR = 3,
    FATAL = 4
};
```

### 级别说明

| 级别 | 说明 | 使用场景 |
|------|------|----------|
| DEBUG | 调试信息 | 开发调试 |
| INFO | 一般信息 | 正常流程 |
| WARNING | 警告信息 | 潜在问题 |
| ERROR | 错误信息 | 错误处理 |
| FATAL | 致命错误 | 程序终止 |

## 日志系统实现

### Logger类

```cpp
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <memory>
#include <chrono>
#include <mutex>

class Logger {
public:
    static Logger& getInstance();
    
    void setLevel(LogLevel level);
    void setOutput(std::ostream& os);
    void setOutput(const std::string& filepath);
    
    void debug(const std::string& message);
    void info(const std::string& message);
    void warning(const std::string& message);
    void error(const std::string& message);
    void fatal(const std::string& message);
    
    template<typename... Args>
    void log(LogLevel level, Args&&... args);
    
private:
    Logger() = default;
    ~Logger();
    
    Logger(const Logger&) = delete;
    Logger& operator=(const Logger&) = delete;
    
    void logImpl(LogLevel level, const std::string& message);
    std::string getTimestamp();
    std::string levelToString(LogLevel level);
    
    LogLevel min_level_ = LogLevel::INFO;
    std::ostream* output_ = &std::cout;
    std::ofstream file_stream_;
    std::mutex mutex_;
};
```

### 日志方法实现

```cpp
Logger& Logger::getInstance() {
    static Logger instance;
    return instance;
}

void Logger::logImpl(LogLevel level, const std::string& message) {
    if (level < min_level_) return;
    
    std::lock_guard<std::mutex> lock(mutex_);
    
    std::ostringstream oss;
    oss << "[" << getTimestamp() << "] "
        << "[" << levelToString(level) << "] "
        << message
        << std::endl;
    
    if (output_) {
        *output_ << oss.str();
        output_->flush();
    }
}

std::string Logger::getTimestamp() {
    auto now = std::chrono::system_clock::now();
    auto time = std::chrono::system_clock::to_time_t(now);
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
        now.time_since_epoch()) % 1000;
    
    std::ostringstream oss;
    oss << std::put_time(std::localtime(&time), "%Y-%m-%d %H:%M:%S");
    oss << '.' << std::setfill('0') << std::setw(3) << ms.count();
    
    return oss.str();
}

std::string Logger::levelToString(LogLevel level) {
    switch (level) {
        case LogLevel::DEBUG:   return "DEBUG";
        case LogLevel::INFO:    return "INFO ";
        case LogLevel::WARNING: return "WARN ";
        case LogLevel::ERROR:   return "ERROR";
        case LogLevel::FATAL:   return "FATAL";
        default:                return "UNKNOWN";
    }
}
```

## 便捷宏

### 基础日志宏

```cpp
#define LOG_DEBUG(msg) Logger::getInstance().debug(msg)
#define LOG_INFO(msg)  Logger::getInstance().info(msg)
#define LOG_WARN(msg)  Logger::getInstance().warning(msg)
#define LOG_ERROR(msg) Logger::getInstance().error(msg)
#define LOG_FATAL(msg) Logger::getInstance().fatal(msg)
```

### 格式化日志宏

```cpp
#define LOGF_DEBUG(fmt, ...) \
    Logger::getInstance().debug(fmt::format(fmt, __VA_ARGS__))
#define LOGF_INFO(fmt, ...) \
    Logger::getInstance().info(fmt::format(fmt, __VA_ARGS__))
#define LOGF_ERROR(fmt, ...) \
    Logger::getInstance().error(fmt::format(fmt, __VA_ARGS__))
```

### 条件日志

```cpp
#define LOG_IF_DEBUG(condition, msg) \
    if (condition) LOG_DEBUG(msg)

#define LOG_IF_ERROR(condition, msg) \
    if (condition) LOG_ERROR(msg)
```

## 使用示例

### 基础使用

```cpp
#include <iostream>

int main() {
    Logger& logger = Logger::getInstance();
    
    logger.setLevel(LogLevel::DEBUG);
    logger.setOutput(std::cout);
    
    LOG_DEBUG("Starting application");
    LOG_INFO("Configuration loaded");
    LOG_WARN("Deprecated API called");
    LOG_ERROR("Failed to connect to database");
    LOG_FATAL("Critical system failure");
    
    return 0;
}
```

### 文件输出

```cpp
int main() {
    Logger& logger = Logger::getInstance();
    
    try {
        logger.setOutput("application.log");
        logger.setLevel(LogLevel::INFO);
        
        logger.info("Application started");
        
        auto result = processData();
        logger.debug("Processing result: {}", result);
        
    } catch (const std::exception& e) {
        logger.fatal("Unhandled exception: {}", e.what());
        return 1;
    }
    
    logger.info("Application terminated normally");
    return 0;
}
```

### 使用fmt库

```cpp
#include <fmt/format.h>

int main() {
    Logger& logger = Logger::getInstance();
    
    int count = 42;
    std::string name = "test";
    
    LOGF_INFO("Processing {} items for {}", count, name);
    LOGF_DEBUG("Value at index {} is {}", i, value);
    LOGF_ERROR("Failed to {} after {} retries", operation, max_retries);
    
    return 0;
}
```

## 高级特性

### 多logger支持

```cpp
class LoggerManager {
public:
    static LoggerManager& getInstance();
    
    Logger& getLogger(const std::string& name);
    void setDefaultLevel(LogLevel level);
    
private:
    std::map<std::string, std::unique_ptr<Logger>> loggers_;
};

// 使用
auto& appLogger = LoggerManager::getInstance().getLogger("app");
auto& dbLogger = LoggerManager::getInstance().getLogger("database");

appLogger.info("Application started");
dbLogger.error("Connection failed");
```

### 结构化日志

```cpp
struct LogEntry {
    std::string timestamp;
    LogLevel level;
    std::string logger;
    std::string message;
    std::string file;
    int line;
};

void structuredLog(const LogEntry& entry) {
    std::cout << fmt::format(
        "{} [{}] {} - {} ({}:{})\n",
        entry.timestamp,
        entry.level,
        entry.logger,
        entry.message,
        entry.file,
        entry.line
    );
}
```
