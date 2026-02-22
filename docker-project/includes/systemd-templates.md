# Systemd Service 模板

当 Docker 服务需要挂载外部硬盘或其他需要系统检测的资源时，需要使用 systemd 来管理服务的启动顺序，确保在 Docker 服务启动前，所需资源已经就绪。

## Systemd Service 模板

```ini
[Unit]
Description={{PROJECT_NAME}} Docker Service
After=network.target {{MOUNT_UNIT}}.mount
Wants={{MOUNT_UNIT}}.mount

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory={{PROJECT_DIR}}
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose stop
ExecRestart=/usr/bin/docker-compose restart

[Install]
WantedBy=multi-user.target
```

## 带硬盘挂载的 Systemd Service 模板

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

## 等待特定设备挂载的 Systemd Service

```ini
[Unit]
Description={{PROJECT_NAME}} Docker Service
After=network.target
Wants=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory={{PROJECT_DIR}}

ExecStartPre=/bin/bash -c 'until [ -b {{DEVICE}} ] || mountpoint -q {{MOUNT_PATH}}; do sleep 1; done'
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose stop
ExecRestart=/usr/bin/docker-compose restart

[Install]
WantedBy=multi-user.target
```

## 变量替换说明

| 变量 | 说明 | 示例 |
|------|------|------|
| `{{PROJECT_NAME}}` | 项目名称 | myapp |
| `{{PROJECT_DIR}}` | 项目目录 | /opt/myapp |
| `{{MOUNT_UNIT}}` | 挂载单元名称 | opt-myapp.mount |
| `{{MOUNT_PATH}}` | 挂载路径 | /mnt/data |
| `{{DEVICE}}` | 设备路径 | /dev/sdb1 |

## 使用说明

### 1. 安装 Systemd Service

```bash
sudo cp {{PROJECT_NAME}}.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable {{PROJECT_NAME}}.service
```

### 2. 启动服务

```bash
sudo systemctl start {{PROJECT_NAME}}.service
```

### 3. 查看状态

```bash
sudo systemctl status {{PROJECT_NAME}}.service
```

### 4. 停止服务

```bash
sudo systemctl stop {{PROJECT_NAME}}.service
```

### 5. 查看日志

```bash
journalctl -u {{PROJECT_NAME}}.service -f
```

## 挂载单元文件（可选）

如果使用独立的挂载单元，需要创建 `.mount` 文件：

```ini
[Unit]
Description={{MOUNT_PATH}} Mount
After=local-fs.target

[Mount]
What={{DEVICE}}
Where={{MOUNT_PATH}}
Type=ext4
Options=defaults

[Install]
WantedBy=multi-user.target
```

## 检测脚本模板

在脚本中检测 systemd service 是否存在：

```bash
check_systemd_service() {
    local service_name="{{PROJECT_NAME}}.service"
    if systemctl list-unit-files | grep -q "^$service_name"; then
        return 0  # 存在
    fi
    return 1  # 不存在
}

if check_systemd_service; then
    echo "Systemd service 已配置"
    systemctl start {{PROJECT_NAME}}.service
else
    echo "使用 docker-compose 直接启动"
    docker-compose up -d
fi
```
