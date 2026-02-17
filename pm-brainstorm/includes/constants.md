# Constants and Enumerations

## Testing Frameworks

### Frontend Testing

| Framework | Language | Use Case |
|-----------|----------|----------|
| Jest | JavaScript/TypeScript | Unit testing, mocking |
| React Testing Library | JavaScript/TypeScript | React component testing |
| Vue Test Utils | JavaScript | Vue component testing |
| Cypress | JavaScript | E2E testing |
| Playwright | JavaScript/TypeScript | E2E testing |
| Vitest | JavaScript/TypeScript | Fast unit testing |

### Backend Testing

| Framework | Language | Use Case |
|-----------|----------|----------|
| JUnit | Java | Unit and integration testing |
| pytest | Python | Unit and API testing |
| Mocha | JavaScript | Node.js testing |
| RSpec | Ruby | BDD testing |
| Go test | Go | Unit and integration testing |
| .NET xUnit | C# | Unit testing |

## Design Patterns

### Core Patterns

```
PATTERNS = {
  creational: [
    'Factory Method',
    'Abstract Factory',
    'Builder',
    'Prototype',
    'Singleton'
  ],
  structural: [
    'Adapter',
    'Bridge',
    'Composite',
    'Decorator',
    'Facade',
    'Proxy'
  ],
  behavioral: [
    'Chain of Responsibility',
    'Command',
    'Iterator',
    'Mediator',
    'Memento',
    'Observer',
    'State',
    'Strategy',
    'Template Method',
    'Visitor'
  ]
}
```

### Pattern Selection Criteria

| Requirement | Recommended Pattern |
|-------------|---------------------|
| API abstraction | Adapter Pattern |
| Database access | Repository Pattern |
| Caching | Proxy Pattern |
| Feature toggles | Strategy Pattern |
| Event system | Observer Pattern |
| Plugin system | Chain of Responsibility |
| Complex validation | Chain of Responsibility + Strategy |
| State machines | State Pattern |

## Docker Best Practices

### Base Image Selection

| Use Case | Recommended Image | Size |
|----------|-------------------|------|
| Node.js production | node:18-alpine | ~170MB |
| Python production | python:3.11-slim | ~130MB |
| Go production | golang:alpine | ~150MB |
| Multi-stage build | Builder pattern | Variable |

### Security Best Practices

```
SECURITY_CHECKLIST = [
  'Use non-root user',
  'Read-only root filesystem',
  'No secrets in image',
  'Minimal base image',
  'Image scanning',
  'Signed images',
  'Regular updates'
]
```

### Health Check Examples

```yaml
# Docker health check examples
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

## API Design Standards

### HTTP Methods

| Method | Idempotent | Use Case |
|--------|------------|----------|
| GET | Yes | Retrieve resources |
| POST | No | Create resources |
| PUT | Yes | Replace resources |
| PATCH | Yes | Partial update |
| DELETE | Yes | Remove resources |

### Status Codes

| Code | Meaning | Usage |
|------|---------|-------|
| 200 | OK | Successful GET/PUT/PATCH |
| 201 | Created | Successful POST |
| 204 | No Content | Successful DELETE |
| 400 | Bad Request | Validation error |
| 401 | Unauthorized | Authentication required |
| 403 | Forbidden | Permission denied |
| 404 | Not Found | Resource not found |
| 500 | Internal Error | Server error |

## Frontend Architecture

### State Management Options

| Library | Complexity | Use Case |
|---------|------------|----------|
| React Context | Low | Simple state |
| Zustand | Low-Medium | React state |
| Redux Toolkit | Medium | Complex state |
| Recoil | Low-Medium | React-specific |
| Vuex/Pinia | Medium | Vue applications |

### Component Libraries

| Framework | Libraries |
|-----------|-----------|
| React | Material UI, Ant Design, Chakra UI, Tailwind |
| Vue | Vuetify, Element Plus, Naive UI, Tailwind |
| Angular | Angular Material, PrimeNG |

## Backend Architecture

### Database Options

| Type | Databases | Use Case |
|------|-----------|----------|
| Relational | PostgreSQL, MySQL | Structured data, ACID |
| Document | MongoDB, CouchDB | Flexible schema |
| Key-Value | Redis, DynamoDB | Caching, sessions |
| Graph | Neo4j | Relationships |
| Time-series | InfluxDB, TimescaleDB | Metrics |

### API Architectural Styles

| Style | Description | Pros | Cons |
|-------|-------------|------|------|
| REST | Resource-based | Simple, widely adopted | Over-fetching |
| GraphQL | Query language | Flexible, precise | Complexity |
| gRPC | RPC protocol | Fast, type-safe | Learning curve |
| WebSocket | Real-time | Bidirectional | Stateful |

## Testing Pyramid

```
        /\
       /  \      E2E Tests (Few)
      /----\
     /      \   Integration Tests (Some)
    /--------\
   /          \  Unit Tests (Many)
  /____________\
```

| Level | Quantity | Speed | Scope |
|-------|----------|-------|-------|
| Unit | Many | Fast | Single component |
| Integration | Some | Medium | Multiple components |
| E2E | Few | Slow | Full system |

## Docker Compose Patterns

### Development Setup

```yaml
services:
  app:
    build: .
    volumes:
      - .:/app
    environment:
      - NODE_ENV=development
```

### Production Setup

```yaml
services:
  app:
    build: .
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
```

## Risk Categories

| Category | Examples | Mitigation |
|----------|----------|------------|
| Technical | Performance, Scalability | Proof of concept, Load testing |
| Security | Vulnerabilities | Security audit, Penetration testing |
| Integration | Third-party APIs | Contract testing, Mock services |
| Operational | Deployment, Monitoring | Automation, Alerting |
| Timeline | Scope creep | MVP approach, Iterative delivery |
