# Docker Compose 模板

## 基本服务模板

```yaml
version: '3.8'

services:
  {{SERVICE_NAME}}:
    image: {{IMAGE}}
    container_name: {{PROJECT_NAME}}
    restart: unless-stopped
    ports:
      - "{{HOST_PORT}}:{{CONTAINER_PORT}}"
    volumes:
      - /opt/{{PROJECT_NAME}}/config:/app/config
      - /opt/{{PROJECT_NAME}}/data:/app/data
      - /opt/{{PROJECT_NAME}}/logs:/app/logs
    env_file:
      - .env
    networks:
      - {{PROJECT_NAME}}-net

networks:
  {{PROJECT_NAME}}-net:
    driver: bridge
```

## 多服务模板

```yaml
version: '3.8'

services:
  {{SERVICE_NAME}}_app:
    image: {{APP_IMAGE}}
    container_name: {{PROJECT_NAME}}-app
    restart: unless-stopped
    ports:
      - "{{APP_PORT}}:{{APP_CONTAINER_PORT}}"
    volumes:
      - /opt/{{PROJECT_NAME}}/app-config:/app/config
      - /opt/{{PROJECT_NAME}}/app-data:/app/data
      - /opt/{{PROJECT_NAME}}/app-logs:/app/logs
    env_file:
      - .env
    depends_on:
      - {{SERVICE_NAME}}_db

  {{SERVICE_NAME}}_db:
    image: {{DB_IMAGE}}
    container_name: {{PROJECT_NAME}}-db
    restart: unless-stopped
    ports:
      - "{{DB_PORT}}:{{DB_CONTAINER_PORT}}"
    volumes:
      - /opt/{{PROJECT_NAME}}/db-config:/etc/{{DB_SERVICE}}
      - /opt/{{PROJECT_NAME}}/db-data:/var/lib/postgresql/data
      - /opt/{{PROJECT_NAME}}/db-logs:/var/log/postgresql
    env_file:
      - .env

volumes:
  {{PROJECT_NAME}}-app-data:
  {{PROJECT_NAME}}-db-data:

networks:
  {{PROJECT_NAME}}-net:
    driver: bridge
```

## 带健康检查的模板

```yaml
version: '3.8'

services:
  {{SERVICE_NAME}}:
    image: {{IMAGE}}
    container_name: {{PROJECT_NAME}}
    restart: unless-stopped
    ports:
      - "{{HOST_PORT}}:{{CONTAINER_PORT}}"
    volumes:
      - /opt/{{PROJECT_NAME}}/config:/app/config
      - /opt/{{PROJECT_NAME}}/data:/app/data
      - /opt/{{PROJECT_NAME}}/logs:/app/logs
    env_file:
      - .env
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:{{CONTAINER_PORT}}/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

networks:
  {{PROJECT_NAME}}-net:
    driver: bridge
```

## 变量替换说明

| 变量 | 说明 | 示例 |
|------|------|------|
| `{{PROJECT_NAME}}` | 项目名称 | myapp |
| `{{SERVICE_NAME}}` | 服务名称 | api |
| `{{IMAGE}}` | Docker 镜像 | nginx:latest |
| `{{HOST_PORT}}` | 主机端口 | 8080 |
| `{{CONTAINER_PORT}}` | 容器端口 | 80 |
| `{{ENV_VARS}}` | 环境变量 | NODE_ENV=production |
