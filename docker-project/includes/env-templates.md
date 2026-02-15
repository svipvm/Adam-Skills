# 环境变量模板

## 基础环境变量

```bash
PROJECT_NAME={{PROJECT_NAME}}
SERVICE_PORT={{DEFAULT_PORT}}
LOG_LEVEL=info
```

## 数据库服务

```bash
DB_TYPE=postgresql
DB_HOST=localhost
DB_PORT=5432
DB_NAME=appdb
DB_USER=appuser
DB_PASSWORD=changeme
```

## Redis 服务

```bash
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=changeme
REDIS_DB=0
```

## 应用服务

```bash
APP_ENV=production
APP_DEBUG=false
APP_URL=http://localhost:8080

JWT_SECRET=changeme
JWT_EXPIRY=3600

SESSION_SECRET=changeme
```

## 安全相关

```bash
# 生成安全密码的方法
# openssl rand -base64 32
SECRET_KEY=changeme
ENCRYPTION_KEY=changeme
```

## 完整示例

```bash
PROJECT_NAME=myapp
SERVICE_PORT=8080
LOG_LEVEL=info

DB_TYPE=postgresql
DB_HOST=db
DB_PORT=5432
DB_NAME=myapp
DB_USER=myapp
DB_PASSWORD=SecurePassword123

REDIS_HOST=redis
REDIS_PORT=6379

APP_ENV=production
APP_DEBUG=false
```
