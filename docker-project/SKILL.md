---
name: "docker-project"
description: "创建标准化Docker项目结构，包含配置模板、环境变量、Compose和管理脚本。Invoke when用户需要创建新的Docker部署项目或设置容器化服务。"
version: "1.0.0"
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
  - /opt/{{PROJECT_NAME}}/data:/app/data
  - /opt/{{PROJECT_NAME}}/logs:/app/logs
```

### 挂载点要求

1. **日志必须挂载**：所有 Docker 服务的日志必须挂载到 `/opt/{{PROJECT_NAME}}/logs` 目录
2. **配置文件挂载**：配置文件需要从容器的 `/app/config` 或类似位置挂载到 `/opt/{{PROJECT_NAME}}/config`，用户修改配置时应修改 `/opt/{{PROJECT_NAME}}/config` 下的文件，而不是在项目目录内修改
3. **数据目录**：其他持久化数据根据服务类型决定是否挂载

## 端口暴露要求

在云服务器上部署时，需要使用 `ufw` 工具开放端口：

1. 在 `docker-compose.yml` 中明确暴露端口：
```yaml
ports:
  - "8080:8080"
```

2. 在 `start.sh` 中使用 `ufw` 开放端口（需要外部访问的端口）：
```bash
ufw allow 8080/tcp
```

3. 在 README.md 中说明需要在云安全组中开放的端口。

## 启动脚本要求

`start.sh` 脚本启动后必须输出项目的使用说明，包括：

1. **服务访问地址**：如何访问服务（如 http://ip:端口）
2. **日志查看命令**：如何查看日志（如 `./logs.sh`）
3. **配置文件位置**：配置文件在 `/opt/{{PROJECT_NAME}}/config`
4. **数据目录位置**：数据存储在 `/opt/{{PROJECT_NAME}}/data`
5. **端口信息**：已开放的端口列表
6. **常用命令**：启动、停止、重启等命令

## 相关文件

- [includes/compose-templates.md](includes/compose-templates.md) - Docker Compose 模板
- [includes/script-templates.md](includes/script-templates.md) - 脚本模板
- [includes/env-templates.md](includes/env-templates.md) - 环境变量模板
- [includes/gitignore-templates.md](includes/gitignore-templates.md) - Gitignore 模板
- [context/examples.md](context/examples.md) - 使用示例
- [types/docker-types.ts](types/docker-types.ts) - 类型定义
