---
name: "docker-project"
description: "创建标准化Docker项目结构，包含配置模板、环境变量、Compose和管理脚本。Invoke when用户需要创建新的Docker部署项目或设置容器化服务。"
version: "1.0.4"
includes:
  - includes/compose-templates.md
  - includes/script-templates.md
  - includes/env-templates.md
  - includes/gitignore-templates.md
  - includes/systemd-templates.md
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
  - "8080:8080"   # 主机端口:容器端口
```

2. 在 `start.sh` 中使用 `iptables` 开放端口（需要外部访问的端口）：
```bash
iptables -I INPUT -p tcp --dport 8080 -j ACCEPT
```

3. 在 README.md 中说明需要在云安全组中开放的端口。

### 端口暴露规范

所有生成的 `docker-compose.yml` 文件必须明确声明端口映射，格式为 `"主机端口:容器端口"`。

示例：
```yaml
ports:
  - "80:8080"     # HTTP服务 - 主机80映射到容器8080
  - "443:8443"   # HTTPS服务 - 主机443映射到容器8443
  - "5432:5432"  # PostgreSQL数据库
  - "6379:6379"  # Redis缓存
```

## Healthcheck 要求

所有 Docker 容器都必须配置健康检查（healthcheck），用于检测服务是否正常运行。

### 必需配置

在 `docker-compose.yml` 中添加 healthcheck 配置：

```yaml
services:
  {{SERVICE_NAME}}:
    image: {{IMAGE}}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:{{CONTAINER_PORT}}/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
```

### 常用健康检查命令

| 服务类型 | 检查命令 |
|----------|----------|
| HTTP 服务 | `curl -f http://localhost:端口/health` |
| PostgreSQL | `pg_isready -U postgres` |
| MySQL | `mysqladmin ping -h localhost` |
| Redis | `redis-cli ping` |
| 通用 TCP | `nc -z localhost 端口` |

### 启动脚本集成

`start.sh` 必须在启动容器后等待健康检查通过，使用内置的 `wait_for_healthy` 函数：

```bash
wait_for_healthy() {
    local container_name="{{PROJECT_NAME}}"
    local max_wait=60

    while [ $max_wait -gt 0 ]; do
        local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null)
        if [ "$health_status" = "healthy" ]; then
            echo "服务健康检查通过！"
            return 0
        fi
        sleep 3
        max_wait=$((max_wait - 3))
    done
    echo "健康检查超时"
    return 1
}

docker-compose up -d
wait_for_healthy
```

### 依赖服务健康检查

当服务依赖其他服务（如数据库）时，使用 `depends_on` 的 `condition: service_healthy` 选项：

```yaml
services:
  app:
    image: myapp
    depends_on:
      db:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      ...

  db:
    image: postgres
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "postgres"]
      ...
```

## Systemd 依赖启动要求

当 Docker 服务需要挂载外部硬盘或其他需要系统检测的资源时，需要使用 systemd 来管理服务的启动顺序，确保在机器重启后，所需资源先被系统检测/挂载，然后再启动 Docker 服务。

### 适用场景

- 使用外部硬盘存储数据
- 使用网络存储（NFS、CIFS）
- 需要在系统启动后等待特定设备就绪

### 实现方式

1. **创建 systemd service 文件**：在项目根目录创建 `{{PROJECT_NAME}}.service` 文件
2. **自动检测**：start.sh 和 stop.sh 会自动检测是否存在 systemd service
3. **挂载等待**：启动前等待挂载点就绪

### Systemd Service 模板

```ini
[Unit]
Description={{PROJECT_NAME}} Docker Service
After=network.target
Wants=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory={{PROJECT_DIR}}

ExecStartPre=/bin/bash -c 'until mountpoint -q {{MOUNT_PATH}}; do sleep 1; done'
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose stop
ExecRestart=/usr/bin/docker-compose restart

[Install]
WantedBy=multi-user.target
```

### 脚本自动处理逻辑

start.sh 和 stop.sh 会自动检测是否存在 systemd service：

1. **检测函数** `check_systemd_service()`：检查 systemd service 是否已安装
2. **挂载等待** `wait_for_mount()`：等待挂载点就绪后再启动
3. **systemd 启动** `start_via_systemd()`：通过 systemctl 启动服务
4. **自动切换**：检测到 systemd service 时自动使用 systemd 方式，未检测到时使用 docker-compose 直接启动

### 安装 systemd service

如果项目目录中存在 `.service` 文件，可以手动安装：

```bash
sudo cp {{PROJECT_NAME}}.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable {{PROJECT_NAME}}.service
```

### 常用命令

| 命令 | 说明 |
|------|------|
| `sudo systemctl start {{PROJECT_NAME}}.service` | 启动服务 |
| `sudo systemctl stop {{PROJECT_NAME}}.service` | 停止服务 |
| `sudo systemctl restart {{PROJECT_NAME}}.service` | 重启服务 |
| `sudo systemctl status {{PROJECT_NAME}}.service` | 查看状态 |
| `journalctl -u {{PROJECT_NAME}}.service -f` | 查看日志 |

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
- [includes/systemd-templates.md](includes/systemd-templates.md) - Systemd Service 模板
- [context/examples.md](context/examples.md) - 使用示例
- [types/docker-types.ts](types/docker-types.ts) - 类型定义
