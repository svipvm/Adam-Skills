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

echo -e "${COLOR_INFO}Starting $PROJECT_NAME...${COLOR_RESET}"

if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        echo -e "${COLOR_INFO}Creating .env from .env.example...${COLOR_RESET}"
        cp .env.example .env
        echo -e "${COLOR_WARNING}Please edit .env file with your configuration!${COLOR_RESET}"
    else
        echo -e "${COLOR_ERROR}ERROR: .env file not found!${COLOR_RESET}"
        exit 1
    fi
fi

if [ -z "$SERVICE_PORT" ]; then
    echo -e "${COLOR_ERROR}ERROR: SERVICE_PORT not set in .env${COLOR_RESET}"
    exit 1
fi

echo -e "${COLOR_INFO}Creating /opt/$PROJECT_NAME directory structure...${COLOR_RESET}"
mkdir -p "$OPT_DIR"/{config,data,logs}

if [ -d "config" ] && [ "$(ls -A config/)" ]; then
    echo -e "${COLOR_INFO}Copying configuration files to $OPT_DIR/config...${COLOR_RESET}"
    cp -n config/* "$OPT_DIR/config/" 2>/dev/null || true
fi

echo -e "${COLOR_INFO}Opening ports with ufw...${COLOR_RESET}"
ufw allow $SERVICE_PORT/tcp 2>/dev/null || true

echo -e "${COLOR_INFO}Starting Docker Compose services...${COLOR_RESET}"
docker-compose up -d

echo -e "${COLOR_INFO}Waiting for services to be ready...${COLOR_RESET}"
sleep 5

echo ""
echo -e "${COLOR_BOLD}${COLOR_SUCCESS}==========================================${COLOR_RESET}"
echo -e "${COLOR_BOLD}${COLOR_SUCCESS}$PROJECT_NAME started successfully!${COLOR_RESET}"
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
echo -e "${COLOR_INFO}Services:${COLOR_RESET}"
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

echo -e "${COLOR_INFO}Stopping $PROJECT_NAME...${COLOR_RESET}"

read -p "Do you want to remove containers? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${COLOR_INFO}Removing containers...${COLOR_RESET}"
    docker-compose down
else
    echo -e "${COLOR_INFO}Stopping services...${COLOR_RESET}"
    docker-compose stop
fi

read -p "Do you want to remove volumes? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${COLOR_WARNING}WARNING: This will delete all data!${COLOR_RESET}"
    read -p "Are you sure? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker-compose down -v
        echo -e "${COLOR_SUCCESS}Volumes removed.${COLOR_RESET}"
    fi
fi

echo -e "${COLOR_SUCCESS}$PROJECT_NAME stopped.${COLOR_RESET}"
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

echo -e "${COLOR_INFO}Restarting service...${COLOR_RESET}"

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
    echo -e "${COLOR_INFO}Following logs for $PROJECT_NAME... (Ctrl+C to exit)${COLOR_RESET}"
    docker-compose logs -f
else
    echo -e "${COLOR_INFO}Showing last $1 lines of logs for $PROJECT_NAME...${COLOR_RESET}"
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

echo -e "${COLOR_INFO}Creating backup of $PROJECT_NAME...${COLOR_RESET}"

docker-compose exec -T {{SERVICE_NAME}} tar czf - /app/data > "$BACKUP_DIR/data_$TIMESTAMP.tar.gz"

echo -e "${COLOR_SUCCESS}Backup created: $BACKUP_DIR/data_$TIMESTAMP.tar.gz${COLOR_RESET}"
```

## 常用命令

| 命令 | 说明 |
|------|------|
| `./start.sh` | 启动服务 |
| `./stop.sh` | 停止服务 |
| `./restart.sh` | 重启服务 |
| `./logs.sh` | 查看日志 |
| `./logs.sh 100` | 查看最近100行日志 |
| `./backup.sh` | 备份数据 |

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
