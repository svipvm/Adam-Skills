---
name: "docker-project"
description: "创建标准化Docker项目结构，包含配置模板、环境变量、Compose和管理脚本。Invoke when用户需要创建新的Docker部署项目或设置容器化服务。"
version: "1.0.2"
includes:
  - includes/compose-templates.md
  - includes/script-templates.md
  - includes/env-templates.md
  - includes/gitignore-templates.md
context:
  - context/examples.md
performance:
  lazy_load: true
  cache: true
---

# Docker Project Creator

此技能用于创建标准化的 Docker 项目结构，支持快速部署容器化服务。

## 项目大纲

本技能提供完整的 Docker 项目生成能力，包括：

1. **标准化项目结构** - 一致的目录布局和文件组织
2. **配置管理** - 环境变量模板和配置文件管理
3. **自动化脚本** - 智能启动/停止脚本，支持首次和二次启动
4. **挂载点规范** - 所有数据存储在 `/opt/<project-name>/`
5. **端口管理** - 自动使用 iptables 开放端口
6. **主题美化** - 彩色终端输出，友好用户体验

## 快速开始

当用户请求创建 Docker 项目时，获取以下信息：
1. **项目名称** - 项目目录名
2. **服务类型** - 部署的服务类型（数据库、Web应用、缓存等）
3. **镜像** - 使用的 Docker 镜像
4. **端口** - 主机端口和容器端口映射
5. **持久化** - 数据卷挂载需求

## 生成的目录结构

```
<project-name>/
├── config/                    # 服务配置文件
├── .env.example              # 环境变量模板
├── .gitignore                # Git 忽略规则
├── docker-compose.yml        # Docker Compose 配置
├── start.sh                  # 启动脚本
├── stop.sh                   # 停止脚本
├── restart.sh                # 重启脚本
├── logs.sh                   # 日志查看脚本
├── backup.sh                 # 备份脚本
└── README.md                 # 项目文档
```

## 模板

[[include:compose-templates]]

## 脚本模板

[[include:script-templates]]

## 环境变量模板

[[include:env-templates]]

## Gitignore 模板

[[include:gitignore-templates]]

## 使用示例

[[load:context/examples]]

## 挂载点约定

所有 Docker 卷挂载点应放在操作系统的 `/opt/<project-name>/` 目录下。

```yaml
volumes:
  - /opt/{{PROJECT_NAME}}/config:/app/config
  - /opt/{{PROJECT_NAME}}/data:/app/data
  - /opt/{{PROJECT_NAME}}/logs:/app/logs
```

### 挂载点要求

1. **日志必须挂载**：所有 Docker 服务的日志必须挂载到 `/opt/{{PROJECT_NAME}}/logs` 目录
2. **配置文件挂载**：配置文件需要从容器的 `/app/config` 或类似位置挂载到 `/opt/{{PROJECT_NAME}}/config`，用户修改配置时应修改 `/opt/{{PROJECT_NAME}}/config` 下的文件，而不是在项目目录内修改
3. **数据目录**：其他持久化数据根据服务类型决定是否挂载

## 端口暴露要求

在云服务器上部署时，需要使用 `iptables` 工具开放端口：

1. 在 `docker-compose.yml` 中明确暴露端口：
```yaml
ports:
  - "8080:8080"
```

2. 在 `start.sh` 中使用 `iptables` 开放端口（需要外部访问的端口）：
```bash
iptables -I INPUT -p tcp --dport 8080 -j ACCEPT
```

3. 在 README.md 中说明需要在云安全组中开放的端口。

## 启动脚本要求

`start.sh` 脚本需要支持**首次启动**和**二次启动**两种模式：

### 首次启动（初始化）
- 检测 `/opt/<project-name>/.initialized` 标记文件
- 如不存在，则执行完整初始化：
  - 创建 `/opt/<project-name>/{config,data,logs}` 目录结构
  - 复制配置文件到 `/opt/<project-name>/config/`
  - 使用 `iptables` 开放端口
  - 创建 `.initialized` 标记文件

### 二次启动（重启）
- 检测到 `.initialized` 文件已存在时：
  - 复用已有的配置和数据
  - 确保目录结构完整
  - 重新启动 Docker 容器
  - 不删除任何已有数据

### 启动输出要求
脚本启动后必须输出项目的使用说明，包括：
1. **服务访问地址**：如何访问服务（如 http://ip:端口）
2. **日志查看命令**：如何查看日志（如 `./logs.sh`）
3. **配置文件位置**：配置文件在 `/opt/<project-name>/config`
4. **数据目录位置**：数据存储在 `/opt/<project-name>/data`
5. **端口信息**：已开放的端口列表
6. **常用命令**：启动、停止、重启等命令

## 脚本主题美化

脚本支持个性化主题配色：
- 使用 `tput` 命令获取终端颜色，兼容各种 Linux 发行版
- 支持回退到 ANSI 转义序列
- 非交互式终端自动禁用颜色
- 所有脚本设置 UTF-8 编码确保中文显示正常

配色包括：成功(绿色)、错误(红色)、警告(橙色)、信息(浅蓝色)、强调(紫色)等

## 相关文件

- [includes/compose-templates.md](includes/compose-templates.md) - Docker Compose 模板
- [includes/script-templates.md](includes/script-templates.md) - 脚本模板
- [includes/env-templates.md](includes/env-templates.md) - 环境变量模板
- [includes/gitignore-templates.md](includes/gitignore-templates.md) - Gitignore 模板
- [context/examples.md](context/examples.md) - 使用示例
- [types/docker-types.ts](types/docker-types.ts) - 类型定义
