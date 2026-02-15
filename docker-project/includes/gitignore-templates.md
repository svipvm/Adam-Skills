# Gitignore 模板

## Docker 项目

```
.env
.env.local
.env.*.local

# Docker
.docker/
docker-compose.override.yml

# 数据卷
/opt/*/data
/opt/*/logs
/opt/*/backups

# 日志
*.log
logs/
*.pid

# 临时文件
tmp/
temp/
*.tmp
*.swp
*.swo
*~

# IDE
.idea/
.vscode/
*.iml
.project
.classpath
.settings/

# OS
.DS_Store
Thumbs.db

# 备份
*.bak
*.backup
*.old
```

## Node.js 项目

```
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
dist/
build/
```

## Python 项目

```
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
env/
.venv/
*.egg-info/
dist/
build/
```
