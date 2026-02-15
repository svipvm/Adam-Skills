---
name: "powershell-project"
description: "创建和管理 Windows PowerShell 项目，提供标准化的项目结构、配置管理和启动/终止脚本。"
version: "1.0.0"
requires:
  - skill: skill-creator-pro
    optional: true
includes:
  - includes/config-utils.md
  - includes/logger.md
  - includes/process-utils.md
---

# PowerShell Project

这是一个用于创建和管理 Windows PowerShell 项目的技能，提供标准化的项目结构、配置化管理、以及启动/终止脚本。

## 核心特性

- **灵活的项目结构**：目录和文件可根据项目需求灵活配置
- **配置化管理**：通过 JSON 配置文件管理项目设置（可选）
- **启动脚本**：开箱即用的 start.ps1（必选）
- **终止脚本**：优雅停止运行中的进程（可选）
- **验证脚本**：项目结构和配置验证工具（可选）
- **日志系统**：内置日志记录功能（可选）
- **进程管理**：方便的服务进程管理工具（可选）

## 目录结构

> **提示**：以下目录和文件并非全部必需，可根据项目实际需求灵活选择。项目规模较小时，可以只保留必要的部分。

```
powershell-project/
├── SKILL.md                    # 主入口
├── includes/                   # 工具模块（可选）
│   ├── config-utils.md         # 配置工具函数
│   ├── logger.md               # 日志工具函数
│   └── process-utils.md        # 进程管理函数
├── scripts/                    # 脚本目录
│   ├── start.ps1               # 启动脚本（必需）
│   ├── stop.ps1                # 终止脚本（可选）
│   └── validate.ps1            # 验证脚本（可选）
├── types/                      # 类型定义（可选）
│   └── project-types.ts        # TypeScript 类型定义
└── config/                     # 配置文件（可选）
    ├── project.json            # 项目配置
    ├── runtime.json            # 运行时配置
    └── environment.json        # 环境配置
```

## 最小配置

最简项目可以只包含：

```
my-project/
└── scripts/
    └── start.ps1    # 只需要启动脚本
```

**start.ps1 可以独立工作**，不强制要求配置文件或其他脚本。

## 快速开始

### 1. 创建新项目

在目标目录下运行以下命令创建项目结构：

```powershell
# 创建目录结构
New-Item -ItemType Directory -Path "config", "scripts", "src", "tests", "logs", "docs"

# 复制配置文件
Copy-Item "path/to/skills/powershell-project/config/*" "config/"
```

### 2. 配置项目

编辑 `config/project.json` 设置项目基本信息：

```json
{
  "name": "my-powershell-project",
  "version": "1.0.0",
  "description": "My PowerShell Project"
}
```

### 3. 启动项目

```powershell
.\scripts\start.ps1
```

### 4. 停止项目

```powershell
.\scripts\stop.ps1
```

## 配置文件说明

> **提示**：配置文件全部为可选，可根据项目需求选择使用。

### config/project.json（可选）

项目基本配置：

| 字段 | 类型 | 说明 |
|------|------|------|
| name | string | 项目名称 |
| version | string | 项目版本 |
| description | string | 项目描述 |
| author | string | 作者 |

### config/runtime.json（可选）

运行时配置：

| 字段 | 类型 | 说明 |
|------|------|------|
| port | number | 端口号 |
| timeout | number | 超时时间(毫秒) |
| logLevel | string | 日志级别 |
| maxRetries | number | 最大重试次数 |

### config/environment.json（可选）

环境变量配置：

| 字段 | 类型 | 说明 |
|------|------|------|
| ENV | string | 环境名称 |
| DEBUG | boolean | 调试模式 |
| custom | object | 自定义变量 |

## 脚本说明

> **注意**：只有 `start.ps1` 是必需的，其他脚本可根据项目需求选择是否添加。

### start.ps1（必需）

启动脚本执行以下步骤：

1. 检查 PowerShell 版本
2. 验证配置文件（如果存在）
3. 创建必要的目录
4. 初始化日志系统
5. 启动应用程序

### stop.ps1（可选）

停止脚本执行以下步骤：

1. 查找运行中的进程
2. 优雅停止进程
3. 保存运行状态
4. 清理临时文件

### validate.ps1（可选）

验证脚本执行以下检查：

1. 目录结构完整性
2. 配置文件格式
3. 脚本语法正确性

## 工具函数

### 配置工具

```powershell
# 读取配置
$config = Get-ProjectConfig -ConfigPath "config/project.json"

# 验证配置
Test-ConfigValid -Config $config
```

### 日志工具

```powershell
# 写入日志
Write-Log -Message "Info message" -Level Info

# 写入错误
Write-Log -Message "Error message" -Level Error
```

### 进程管理

```powershell
# 启动进程
Start-ProjectProcess -FilePath "app.exe" -Arguments "-config config.json"

# 停止进程
Stop-ProjectProcess -ProcessName "app"

# 检查进程状态
Test-ProcessRunning -ProcessName "app"
```

## 示例

### 基本使用示例

```powershell
# 导入工具模块
. "$PSScriptRoot\includes\config-utils.ps1"
. "$PSScriptRoot\includes\logger.ps1"

# 读取配置
$projectConfig = Get-ProjectConfig -ConfigPath "config/project.json"

# 写入日志
Write-Log -Message "Starting project: $($projectConfig.name)" -Level Info

# 启动应用
Start-ProjectProcess -FilePath ".\src\app.ps1"
```

### 自定义启动逻辑

在 `scripts/start.ps1` 中添加自定义启动逻辑：

```powershell
param(
    [string]$ConfigPath = "config"
)

# 导入模块
. "$PSScriptRoot\..\includes\config-utils.ps1"
. "$PSScriptRoot\..\includes\logger.ps1"

# 加载配置
$runtimeConfig = Get-ProjectConfig -ConfigPath "$ConfigPath\runtime.json"

# 自定义启动逻辑
if ($runtimeConfig.enableWebServer) {
    Start-W ebServer -Port $runtimeConfig.port
}
```

## 最佳实践

1. **保持配置简洁**：只添加必要的配置项
2. **使用日志级别**：合理使用 Info/Warning/Error 级别
3. **优雅停止**：确保 stop.ps1 能够正确清理资源
4. **验证脚本**：在部署前运行 validate.ps1 确保配置正确

## 依赖

- skill-creator-pro：用于创建更复杂的技能结构

## 相关文件

- [includes/config-utils.md](includes/config-utils.md) - 配置工具
- [includes/logger.md](includes/logger.md) - 日志工具
- [includes/process-utils.md](includes/process-utils.md) - 进程管理
- [scripts/start.ps1](scripts/start.ps1) - 启动脚本
- [scripts/stop.ps1](scripts/stop.ps1) - 终止脚本
- [scripts/validate.ps1](scripts/validate.ps1) - 验证脚本
- [types/project-types.ts](types/project-types.ts) - 类型定义
