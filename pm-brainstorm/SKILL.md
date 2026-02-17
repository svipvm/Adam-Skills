---
name: "pm-brainstorm"
description: "Project Manager Brainstorm skill for full-stack product development. Invoked when user needs help with requirement analysis, technical architecture, testing strategy, and Docker deployment planning."
version: "1.0.0"
requires:
  - skill: skill-creator
    optional: true
includes:
  - includes/prompts.md
  - includes/constants.md
  - includes/common-utils.md
context:
  - context/examples.md
performance:
  lazy_load: true
  cache: true
---

# Project Manager Brainstorm

A comprehensive skill for full-stack product development that covers requirement analysis, technical architecture, testing strategy, and Docker deployment planning.

## Core Capabilities

- **Requirement Analysis**: Deep dive into product requirements, user stories, and acceptance criteria
- **Technical Architecture**: Frontend styling, backend performance, API design
- **Testing Strategy**: Functional testing, unit testing, integration testing
- **Docker Deployment**: Containerization readiness and deployment planning
- **Design Patterns**: Apply appropriate patterns for extensibility
- **Frontend-Backend Decoupling**: Clear separation of concerns

## Brainstorm Workflow

### Phase 1: Requirement Discovery

1. Ask clarifying questions about product vision
2. Identify core features and user flows
3. Define success metrics and KPIs
4. Map out edge cases and error scenarios

### Phase 2: Technical Analysis

1. **Frontend Analysis**
   - UI/UX requirements
   - Component architecture
   - State management approach
   - Responsive design requirements

2. **Backend Analysis**
   - API design and data flow
   - Database schema considerations
   - Performance optimization
   - Caching strategies

3. **Integration Analysis**
   - API contract definition
   - Error handling protocols
   - Data validation layers

### Phase 3: Testing Strategy

1. Define test coverage requirements
2. Plan unit test structure
3. Design functional test scenarios
4. Plan integration test approach

### Phase 4: Docker Readiness

1. Identify containerization requirements
2. Define environment variables
3. Plan volume mounts
4. Configure health checks

## Questioning Framework

When conducting brainstorming sessions, continuously probe for:

- **Product Details**: Who are the users? What problem does this solve?
- **Technical Constraints**: What frameworks? What databases? Performance requirements?
- **Timeline**: What's the launch date? Milestones?
- **Scale**: Expected users? Data volume?
- **Integration**: Third-party services? External APIs?

## Design Patterns Selection Guide

| Scenario | Recommended Pattern |
|----------|---------------------|
| Complex state management | Repository Pattern |
| API client abstraction | Adapter Pattern |
| Plugin system | Strategy Pattern |
| Feature flags | Feature Toggle Pattern |
| Event-driven architecture | Observer Pattern |
| Caching layer | Proxy Pattern |

## Docker Best Practices Checklist

- [ ] Multi-stage builds for minimal images
- [ ] Non-root user execution
- [ ] Health check endpoints
- [ ] Graceful shutdown handling
- [ ] Environment-based configuration
- [ ] Log management
- [ ] Volume mounts for persistent data
- [ ] Resource limits configuration

## Output Format

Provide structured output including:

1. **Requirement Document**: User stories, acceptance criteria
2. **Architecture Decision Record (ADR)**: Technical choices and rationale
3. **API Specification**: Endpoints, request/response schemas
4. **Testing Plan**: Test types, coverage targets, tools
5. **Docker Configuration**: Dockerfile, docker-compose.yml templates
6. **Risk Assessment**: Potential issues and mitigation strategies

## Usage Examples

### Starting a New Project

```
User: "I want to build an e-commerce platform"
PM Brainstorm: "Great! Let me ask some clarifying questions..."
```

### Analyzing Existing Requirements

```
User: "Here's my feature spec for a user authentication system"
PM Brainstorm: "Let me analyze this and identify gaps..."
```

### Technical Architecture Review

```
User: "How should we structure our frontend and backend?"
PM Brainstorm: "Based on your requirements, here's my recommendation..."
```

## Related Modules

- [includes/prompts.md](includes/prompts.md) - Prompt templates for different scenarios
- [includes/constants.md](includes/constants.md) - Constants and enumerations
- [includes/common-utils.md](includes/common-utils.md) - Utility functions
- [context/examples.md](context/examples.md) - Usage examples
- [types/skill-types.ts](types/skill-types.ts) - TypeScript definitions
