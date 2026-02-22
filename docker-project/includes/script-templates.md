# 脚本模板

## 颜色和样式定义（可自定义主题）

```bash
# 主题配色方案
# 终端颜色代码 - 兼容各种Linux系统
if [ -t 1 ]; then
    # 检查终端是否支持颜色
    if command -v tput &> /dev/null && tput colors &> /dev/null && [ "$(tput colors)" -ge 8 ]; then
        # 使用tput获取终端颜色，兼容性好
        COLOR_RESET=$(tput sgr0)
        COLOR_BOLD=$(tput bold)
        COLOR_DIM=$(tput dim)

        # 主色调 - 现代蓝色主题
        COLOR_PRIMARY=$(tput setaf 33)      # 蓝色
        COLOR_SUCCESS=$(tput setaf 82)       # 绿色
        COLOR_WARNING=$(tput setaf 214)      # 橙色
        COLOR_ERROR=$(tput setaf 196)        # 红色
        COLOR_INFO=$(tput setaf 75)          # 浅蓝色
        COLOR_ACCENT=$(tput setaf 171)       # 紫色

        # 次要色调
        COLOR_MUTED=$(tput setaf 245)        # 灰色
        COLOR_HIGHLIGHT=$(tput setaf 228)    # 浅黄色
    else
        # 回退到ANSI转义序列
        COLOR_RESET='\033[0m'
        COLOR_BOLD='\033[1m'
        COLOR_DIM='\033[2m'
        COLOR_PRIMARY='\033[0;34m'
        COLOR_SUCCESS='\033[0;32m'
        COLOR_WARNING='\033[0;33m'
        COLOR_ERROR='\033[0;31m'
        COLOR_INFO='\033[0;36m'
        COLOR_ACCENT='\033[0;35m'
        COLOR_MUTED='\033[0;90m'
        COLOR_HIGHLIGHT='\033[0;93m'
    fi
else
    # 非交互式终端，不使用颜色
    COLOR_RESET=''
    COLOR_BOLD=''
    COLOR_DIM=''
    COLOR_PRIMARY=''
    COLOR_SUCCESS=''
    COLOR_WARNING=''
    COLOR_ERROR=''
    COLOR_INFO=''
    COLOR_ACCENT=''
    COLOR_MUTED=''
    COLOR_HIGHLIGHT=''
fi

# 确保输出编码为UTF-8
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}
```

## start.sh

```bash
#!/bin/bash
set -e

# UTF-8编码支持
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}

# 主题配色（可自定义）
if [ -t 1 ]; then
    if command -v tput &> /dev/null && tput colors &> /dev/null && [ "$(tput colors)" -ge 8 ]; then
        COLOR_RESET=$(tput sgr0)
        COLOR_BOLD=$(tput bold)
        COLOR_SUCCESS=$(tput setaf 82)
        COLOR_WARNING=$(tput setaf 214)
        COLOR_ERROR=$(tput setaf 196)
        COLOR_INFO=$(tput setaf 75)
        COLOR_ACCENT=$(tput setaf 171)
        COLOR_MUTED=$(tput setaf 245)
    else
        COLOR_RESET='\033[0m'
        COLOR_BOLD='\033[1m'
        COLOR_SUCCESS='\033[0;32m'
        COLOR_WARNING='\033[0;33m'
        COLOR_ERROR='\033[0;31m'
        COLOR_INFO='\033[0;36m'
        COLOR_ACCENT='\033[0;35m'
        COLOR_MUTED='\033[0;90m'
    fi
else
    COLOR_RESET='' COLOR_BOLD='' COLOR_SUCCESS='' COLOR_WARNING='' COLOR_ERROR='' COLOR_INFO='' COLOR_ACCENT='' COLOR_MUTED=''
fi

PROJECT_NAME="{{PROJECT_NAME}}"
OPT_DIR="/opt/$PROJECT_NAME"

# 检测是否为首次启动
is_first_start() {
    if [ ! -d "$OPT_DIR" ] || [ ! -f "$OPT_DIR/.initialized" ]; then
        return 0  # 是首次启动
    fi
    return 1  # 不是首次启动
}

# 检查Docker容器是否存在（服务曾经启动过）
is_service_existed() {
    docker-compose ps -a --format "{{.Names}}" 2>/dev/null | grep -q "^{{PROJECT_NAME}}$"
    return $?
}

echo -e "${COLOR_INFO}==========================================${COLOR_RESET}"
echo -e "${COLOR_INFO}  $PROJECT_NAME 启动脚本${COLOR_RESET}"
echo -e "${COLOR_INFO}==========================================${COLOR_RESET}"

if is_first_start; then
    echo -e "${COLOR_WARNING}首次启动检测：初始化所有运行环境...${COLOR_RESET}"

    if [ ! -f .env ]; then
        if [ -f .env.example ]; then
            echo -e "${COLOR_INFO}创建 .env 配置文件...${COLOR_RESET}"
            cp .env.example .env
            echo -e "${COLOR_WARNING}请先编辑 .env 文件配置必要的参数！${COLOR_RESET}"
            exit 1
        else
            echo -e "${COLOR_ERROR}错误: .env.example 文件不存在！${COLOR_RESET}"
            exit 1
        fi
    fi

    if [ -z "$SERVICE_PORT" ]; then
        echo -e "${COLOR_ERROR}错误: SERVICE_PORT 未在 .env 中配置！${COLOR_RESET}"
        exit 1
    fi

    echo -e "${COLOR_INFO}创建 /opt/$PROJECT_NAME 目录结构...${COLOR_RESET}"
    mkdir -p "$OPT_DIR"/{config,data,logs}

    if [ -d "config" ] && [ "$(ls -A config/)" ]; then
        echo -e "${COLOR_INFO}复制配置文件到 $OPT_DIR/config/...${COLOR_RESET}"
        cp -n config/* "$OPT_DIR/config/" 2>/dev/null || true
    fi

    echo -e "${COLOR_INFO}使用 iptables 开放端口...${COLOR_RESET}"
    iptables -I INPUT -p tcp --dport $SERVICE_PORT -j ACCEPT 2>/dev/null || true

    touch "$OPT_DIR/.initialized"
    echo -e "${COLOR_SUCCESS}首次启动初始化完成！${COLOR_RESET}"
    echo ""

else
    echo -e "${COLOR_INFO}二次启动检测：使用已有配置重启服务...${COLOR_RESET}"

    if [ ! -f .env ]; then
        if [ -f .env.example ]; then
            echo -e "${COLOR_INFO}从模板恢复 .env 配置...${COLOR_RESET}"
            cp .env.example .env
        fi
    fi

    if [ -z "$SERVICE_PORT" ]; then
        if [ -f "$OPT_DIR/.env" ]; then
            echo -e "${COLOR_INFO}从已有配置恢复环境变量...${COLOR_RESET}"
            source "$OPT_DIR/.env" 2>/dev/null || true
        fi
    fi

    echo -e "${COLOR_INFO}检查 /opt/$PROJECT_NAME 目录结构...${COLOR_RESET}"
    mkdir -p "$OPT_DIR"/{config,data,logs}

    if [ -d "config" ] && [ "$(ls -A config/)" ]; then
        echo -e "${COLOR_INFO}更新配置文件（保留已有配置）...${COLOR_RESET}"
        cp -n config/* "$OPT_DIR/config/" 2>/dev/null || true
    fi

    echo -e "${COLOR_INFO}确保端口已开放...${COLOR_RESET}"
    iptables -I INPUT -p tcp --dport $SERVICE_PORT -j ACCEPT 2>/dev/null || true
fi

wait_for_healthy() {
    local container_name="{{PROJECT_NAME}}"
    local max_wait=60
    local interval=3
    local waited=0

    echo -e "${COLOR_INFO}等待服务健康检查通过...${COLOR_RESET}"

    while [ $waited -lt $max_wait ]; do
        local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "none")

        if [ "$health_status" = "healthy" ]; then
            echo -e "${COLOR_SUCCESS}服务健康检查通过！${COLOR_RESET}"
            return 0
        elif [ "$health_status" = "none" ]; then
            local state=$(docker inspect --format='{{.State.Status}}' "$container_name" 2>/dev/null || echo "unknown")
            if [ "$state" = "running" ]; then
                echo -e "${COLOR_SUCCESS}服务已启动（无健康检查）！${COLOR_RESET}"
                return 0
            fi
        fi

        echo -n "."
        sleep $interval
        waited=$((waited + interval))
    done

    echo ""
    echo -e "${COLOR_WARNING}健康检查超时，服务可能仍在启动中${COLOR_RESET}"
    return 1
}

echo ""
echo -e "${COLOR_INFO}启动 Docker Compose 服务...${COLOR_RESET}"
docker-compose up -d

wait_for_healthy

echo ""
echo -e "${COLOR_BOLD}${COLOR_SUCCESS}==========================================${COLOR_RESET}"
echo -e "${COLOR_BOLD}${COLOR_SUCCESS}  $PROJECT_NAME 启动成功！${COLOR_RESET}"
echo -e "${COLOR_BOLD}${COLOR_SUCCESS}==========================================${COLOR_RESET}"
echo ""
echo -e "${COLOR_ACCENT}服务访问地址:${COLOR_RESET}"
echo -e "  ${COLOR_HIGHLIGHT}http://localhost:$SERVICE_PORT${COLOR_RESET}"
echo ""
echo -e "${COLOR_ACCENT}日志查看命令:${COLOR_RESET}"
echo -e "  ${COLOR_MUTED}./logs.sh${COLOR_RESET}"
echo -e "  ${COLOR_MUTED}./logs.sh 100${COLOR_RESET}"
echo ""
echo -e "${COLOR_ACCENT}配置文件位置:${COLOR_RESET}"
echo -e "  ${COLOR_MUTED}$OPT_DIR/config/${COLOR_RESET}"
echo ""
echo -e "${COLOR_ACCENT}数据存储位置:${COLOR_RESET}"
echo -e "  ${COLOR_MUTED}$OPT_DIR/data/${COLOR_RESET}"
echo ""
echo -e "${COLOR_ACCENT}日志存储位置:${COLOR_RESET}"
echo -e "  ${COLOR_MUTED}$OPT_DIR/logs/${COLOR_RESET}"
echo ""
echo -e "${COLOR_ACCENT}已开放端口:${COLOR_RESET}"
echo -e "  ${COLOR_WARNING}$SERVICE_PORT/tcp${COLOR_RESET}"
echo ""
echo -e "${COLOR_ACCENT}常用命令:${COLOR_RESET}"
echo -e "  ${COLOR_MUTED}./start.sh    - 启动服务${COLOR_RESET}"
echo -e "  ${COLOR_MUTED}./stop.sh     - 停止服务${COLOR_RESET}"
echo -e "  ${COLOR_MUTED}./restart.sh  - 重启服务${COLOR_RESET}"
echo -e "  ${COLOR_MUTED}./logs.sh     - 查看日志${COLOR_RESET}"
echo -e "${COLOR_BOLD}${COLOR_SUCCESS}==========================================${COLOR_RESET}"
echo ""
echo -e "${COLOR_INFO}运行中的服务:${COLOR_RESET}"
docker-compose ps
```

## stop.sh

```bash
#!/bin/bash
set -e

# UTF-8编码支持
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}

# 主题配色
if [ -t 1 ]; then
    if command -v tput &> /dev/null && tput colors &> /dev/null && [ "$(tput colors)" -ge 8 ]; then
        COLOR_RESET=$(tput sgr0)
        COLOR_BOLD=$(tput bold)
        COLOR_SUCCESS=$(tput setaf 82)
        COLOR_WARNING=$(tput setaf 214)
        COLOR_ERROR=$(tput setaf 196)
        COLOR_INFO=$(tput setaf 75)
        COLOR_MUTED=$(tput setaf 245)
    else
        COLOR_RESET='\033[0m'
        COLOR_BOLD='\033[1m'
        COLOR_SUCCESS='\033[0;32m'
        COLOR_WARNING='\033[0;33m'
        COLOR_ERROR='\033[0;31m'
        COLOR_INFO='\033[0;36m'
        COLOR_MUTED='\033[0;90m'
    fi
else
    COLOR_RESET='' COLOR_BOLD='' COLOR_SUCCESS='' COLOR_WARNING='' COLOR_ERROR='' COLOR_INFO='' COLOR_MUTED=''
fi

PROJECT_NAME="{{PROJECT_NAME}}"
OPT_DIR="/opt/$PROJECT_NAME"

echo -e "${COLOR_INFO}==========================================${COLOR_RESET}"
echo -e "${COLOR_INFO}  $PROJECT_NAME 停止脚本${COLOR_RESET}"
echo -e "${COLOR_INFO}==========================================${COLOR_RESET}"

echo -e "${COLOR_INFO}正在停止 $PROJECT_NAME...${COLOR_RESET}"

read -p "是否移除容器？[y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${COLOR_INFO}移除容器中...${COLOR_RESET}"
    docker-compose down
    echo -e "${COLOR_SUCCESS}容器已移除${COLOR_RESET}"
else
    echo -e "${COLOR_INFO}停止服务中...${COLOR_RESET}"
    docker-compose stop
    echo -e "${COLOR_SUCCESS}服务已停止${COLOR_RESET}"
fi

echo -e "${COLOR_SUCCESS}$PROJECT_NAME 已停止${COLOR_RESET}"
echo ""
echo -e "${COLOR_INFO}注意：/opt/$PROJECT_NAME 目录下的配置和数据依然保留${COLOR_RESET}"
echo -e "${COLOR_INFO}下次启动时将自动使用已有配置${COLOR_RESET}"
```

## restart.sh

```bash
#!/bin/bash
set -e

# UTF-8编码支持
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}

# 主题配色
if [ -t 1 ]; then
    if command -v tput &> /dev/null && tput colors &> /dev/null && [ "$(tput colors)" -ge 8 ]; then
        COLOR_RESET=$(tput sgr0)
        COLOR_INFO=$(tput setaf 75)
    else
        COLOR_RESET='\033[0m'
        COLOR_INFO='\033[0;36m'
    fi
else
    COLOR_RESET='' COLOR_INFO=''
fi

echo -e "${COLOR_INFO}重启服务中...${COLOR_RESET}"

./stop.sh
echo ""
./start.sh
```

## logs.sh

```bash
#!/bin/bash

# UTF-8编码支持
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}

PROJECT_NAME="{{PROJECT_NAME}}"

# 主题配色
if [ -t 1 ]; then
    if command -v tput &> /dev/null && tput colors &> /dev/null && [ "$(tput colors)" -ge 8 ]; then
        COLOR_RESET=$(tput sgr0)
        COLOR_INFO=$(tput setaf 75)
    else
        COLOR_RESET='\033[0m'
        COLOR_INFO='\033[0;36m'
    fi
else
    COLOR_RESET='' COLOR_INFO=''
fi

if [ -z "$1" ]; then
    echo -e "${COLOR_INFO}正在跟踪 $PROJECT_NAME 的日志... (按 Ctrl+C 退出)${COLOR_RESET}"
    docker-compose logs -f
else
    echo -e "${COLOR_INFO}显示 $PROJECT_NAME 最近 $1 行日志...${COLOR_RESET}"
    docker-compose logs -f --tail="$1"
fi
```

## backup.sh

```bash
#!/bin/bash
set -e

# UTF-8编码支持
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}

# 主题配色
if [ -t 1 ]; then
    if command -v tput &> /dev/null && tput colors &> /dev/null && [ "$(tput colors)" -ge 8 ]; then
        COLOR_RESET=$(tput sgr0)
        COLOR_BOLD=$(tput bold)
        COLOR_SUCCESS=$(tput setaf 82)
        COLOR_INFO=$(tput setaf 75)
        COLOR_WARNING=$(tput setaf 214)
    else
        COLOR_RESET='\033[0m'
        COLOR_BOLD='\033[1m'
        COLOR_SUCCESS='\033[0;32m'
        COLOR_INFO='\033[0;36m'
        COLOR_WARNING='\033[0;33m'
    fi
else
    COLOR_RESET='' COLOR_BOLD='' COLOR_SUCCESS='' COLOR_INFO='' COLOR_WARNING=''
fi

PROJECT_NAME="{{PROJECT_NAME}}"
BACKUP_DIR="/opt/$PROJECT_NAME/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

echo -e "${COLOR_INFO}正在创建 $PROJECT_NAME 的备份...${COLOR_RESET}"

docker-compose exec -T {{SERVICE_NAME}} tar czf - /app/data > "$BACKUP_DIR/data_$TIMESTAMP.tar.gz"

echo -e "${COLOR_SUCCESS}备份已创建: $BACKUP_DIR/data_$TIMESTAMP.tar.gz${COLOR_RESET}"
```

## 常用命令

| 命令 | 说明 |
|------|------|
| `./start.sh` | 启动服务（首次初始化/二次启动） |
| `./stop.sh` | 停止服务 |
| `./restart.sh` | 重启服务 |
| `./logs.sh` | 查看日志 |
| `./logs.sh 100` | 查看最近100行日志 |
| `./backup.sh` | 备份数据 |

## 首次启动 vs 二次启动

### 首次启动（初始化）
- 检测到 `/opt/$PROJECT_NAME/.initialized` 文件不存在
- 创建目录结构：config、data、logs
- 复制配置文件到 `/opt/$PROJECT_NAME/config/`
- 使用 iptables 开放端口
- 创建 `.initialized` 标记文件

### 二次启动（重启）
- 检测到 `/opt/$PROJECT_NAME/.initialized` 文件存在
- 复用已有的配置和数据
- 确保目录结构完整
- 重新启动 Docker 容器
- 不删除任何已有数据

### 停止服务
- 保留 `/opt/$PROJECT_NAME` 目录下的所有配置和数据
- 下次启动时自动使用已有配置
- 可选择是否删除 Docker 容器

## 主题配色说明

脚本支持以下颜色变量，可在脚本开头自定义：

| 变量 | 默认颜色 | 用途 |
|------|----------|------|
| `COLOR_PRIMARY` | 蓝色 | 主要信息 |
| `COLOR_SUCCESS` | 绿色 | 成功提示 |
| `COLOR_WARNING` | 橙色 | 警告信息 |
| `COLOR_ERROR` | 红色 | 错误信息 |
| `COLOR_INFO` | 浅蓝色 | 一般信息 |
| `COLOR_ACCENT` | 紫色 | 强调内容 |
| `COLOR_MUTED` | 灰色 | 次要信息 |
| `COLOR_HIGHLIGHT` | 浅黄色 | 高亮内容 |
| `COLOR_BOLD` | 粗体 | 标题 |
| `COLOR_RESET` | 重置 | 清除样式 |

兼容性说明：
- 自动检测终端是否支持颜色
- 优先使用 `tput` 命令（兼容性最好）
- 回退到 ANSI 转义序列
- 非交互式终端自动禁用颜色
- 所有脚本都设置 UTF-8 编码确保中文显示正常
