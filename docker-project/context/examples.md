# Docker 项目完整示例

## 示例 1: Redis 服务

用户请求: "Create a Docker project for deploying Redis"

### 1. 收集需求
- 项目名称: redis
- 服务类型: Redis 缓存
- 端口: 6379
- 数据持久化: 是

### 2. 生成的目录结构
```
redis/
├── config/
│   └── redis.conf
├── .env.example
├── .gitignore
├── docker-compose.yml
├── start.sh
├── stop.sh
├── logs.sh
└── README.md
```

### 3. config/redis.conf
```conf
bind 0.0.0.0
protected-mode yes
port 6379
timeout 0
tcp-keepalive 300
daemonize no
supervised no
loglevel notice
databases 16
save 900 1
save 300 10
save 60 10000
dir /data
```

### 4. .env.example
```bash
PROJECT_NAME=redis
SERVICE_PORT=6379
REDIS_PASSWORD=changeme
```

### 5. docker-compose.yml
```yaml
version: '3.8'

services:
  redis:
    image: redis:7-alpine
    container_name: redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - /opt/redis/data:/data
      - ./config/redis.conf:/usr/local/etc/redis/redis.conf
    command: redis-server /usr/local/etc/redis/redis.conf
    networks:
      - redis-net

networks:
  redis-net:
    driver: bridge
```

### 6. start.sh
```bash
#!/bin/bash
set -e

PROJECT_NAME="redis"

if [ ! -f .env ]; then
    cp .env.example .env
fi

docker-compose up -d
echo "Redis started on port $SERVICE_PORT"
```

### 7. README.md
```markdown
# Redis Docker Project

## 快速开始

1. 复制环境变量文件: `cp .env.example .env`
2. 编辑 `.env` 设置密码
3. 启动: `./start.sh`

## 端口

- 6379: Redis 服务端口

## 数据持久化

数据存储在 `/opt/redis/data`
```

---

## 示例 2: PostgreSQL + Node.js 应用

用户请求: "Create a Docker project for a Node.js API with PostgreSQL"

### 1. 目录结构
```
myapi/
├── config/
│   └── nginx.conf
├── .env.example
├── .gitignore
├── docker-compose.yml
├── start.sh
├── stop.sh
└── README.md
```

### 2. docker-compose.yml
```yaml
version: '3.8'

services:
  app:
    image: node:18-alpine
    container_name: myapi-app
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - /opt/myapi/app-data:/app/data
      - /opt/myapi/logs:/app/logs
    env_file:
      - .env
    depends_on:
      - db
    networks:
      - myapi-net

  db:
    image: postgres:15-alpine
    container_name: myapi-db
    restart: unless-stopped
    ports:
      - "5432:5432"
    volumes:
      - /opt/myapi/db-data:/var/lib/postgresql/data
    env_file:
      - .env
    networks:
      - myapi-net

networks:
  myapi-net:
    driver: bridge
```

### 3. .env.example
```bash
PROJECT_NAME=myapi
APP_PORT=3000
DB_PORT=5432

DB_HOST=db
DB_NAME=myapp
DB_USER=myapp
DB_PASSWORD=SecurePassword123
DB_ROOT_PASSWORD=RootPassword123

NODE_ENV=production
```

---

## 示例 3: 带安全组端口说明的完整项目

用户请求: "Create a Docker project for a web service that needs to be accessible from the internet"

### 端口暴露说明

生成的 README.md 应包含:

```markdown
## 端口配置

| 服务 | 容器端口 | 映射端口 | 协议 | 云安全组 |
|------|----------|----------|------|----------|
| Web  | 80       | 80       | TCP  | 需要开放 |
| API  | 3000     | 8080     | TCP  | 需要开放 |
| DB   | 5432     | -        | TCP  | 禁止外部 |

## 云服务器安全组配置

必须在云控制台开放以下端口:
- 80 (HTTP)
- 8080 (自定义API)
```

### docker-compose.yml (带端口暴露)
```yaml
services:
  web:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
  api:
    image: myapi:latest
    ports:
      - "8080:3000"
```
