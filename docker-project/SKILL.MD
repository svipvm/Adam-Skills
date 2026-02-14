---
name: "docker-project"
description: "Creates a standardized Docker project structure with config templates, env files, compose, and management scripts. Invoke when user wants to create a new Docker deployment project or set up a containerized service."
---

# Docker Project Creator

This skill creates a standardized Docker project structure for deploying containerized services.

## Project Structure

When invoked, this skill creates the following structure:

```
<project-name>/
├── config/                 # Configuration template files
│   └── (service configs)
├── .env.example            # Environment variables template
├── .gitignore              # Git ignore rules
├── docker-compose.yml      # Docker Compose configuration
├── start.sh                # Service startup script
├── stop.sh                 # Service shutdown script
└── README.md               # Project documentation
```

## File Descriptions

### config/
Contains all configuration template files required by the service. These are example configs that users can customize.

### .env.example
Template file containing all dynamic parameters. Users should copy this to `.env` and fill in their values. The `start.sh` script reads these values during startup.

### .gitignore
Standard Git ignore rules for Docker projects, including:
- `.env` (contains secrets)
- Docker volumes
- Log files
- Common IDE files

### docker-compose.yml
Docker Compose configuration file defining the service(s), networks, volumes, and environment variable substitutions.

### start.sh
Startup script that:
1. Checks if `.env` exists (copies from `.env.example` if not)
2. Validates required environment variables
3. Starts the Docker Compose services

### stop.sh
Shutdown script that:
1. Stops the Docker Compose services
2. Optionally cleans up resources

### README.md
Project documentation including:
- Project description
- Prerequisites
- Quick start guide
- Configuration options
- Troubleshooting

## Usage

When a user requests to create a Docker project, ask for:
1. **Project name** - The directory name for the project
2. **Service type** - What service will be deployed (e.g., database, web app, etc.)
3. **Configuration needs** - What config files the service requires
4. **Environment variables** - What dynamic parameters are needed
5. **Ports and volumes** - Network ports and persistent storage requirements

Then create all the necessary files with appropriate content based on the service requirements.

## Template Variables

When generating files, use these placeholder patterns:
- `{{PROJECT_NAME}}` - Project/service name
- `{{SERVICE_NAME}}` - Docker service name
- `{{IMAGE}}` - Docker image to use
- `{{PORTS}}` - Port mappings
- `{{VOLUMES}}` - Volume mappings
- `{{ENV_VARS}}` - Environment variable definitions

## Example Invocation

User: "Create a Docker project for deploying Redis"

The skill will:
1. Create project directory `redis/`
2. Generate `config/redis.conf` template
3. Create `.env.example` with Redis password, port, etc.
4. Write `docker-compose.yml` for Redis service
5. Create `start.sh` and `stop.sh` scripts
6. Generate `README.md` with setup instructions
7. Add appropriate `.gitignore`
