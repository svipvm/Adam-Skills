# Prompt Templates for PM Brainstorm

## Requirement Discovery Prompts

### Initial Discovery

```
Hello! I'm here to help you brainstorm your project requirements.
To get started, could you tell me:

1. What is the main purpose of your project?
2. Who are the target users?
3. What problem does it solve?

Feel free to share as much or as little as you know - we'll refine together!
```

### Feature Deep Dive

```
Let's dig deeper into the features you've described.

For each feature, please consider:
- What are the user actions involved?
- What should happen on success?
- What should happen on failure?
- Are there any edge cases we should handle?

Which feature would you like to explore first?
```

## Technical Architecture Prompts

### Frontend Analysis

```
Now let's discuss the frontend architecture:

1. What frontend framework are you considering? (React, Vue, Angular, etc.)
2. Do you have any design mockups or style preferences?
3. Will this be a web app, mobile app, or both?
4. What's your expected team size for frontend development?
```

### Backend Analysis

```
For the backend, I'd like to understand:

1. What's your preferred language/framework?
2. Do you need real-time features? (WebSockets, etc.)
3. What's the expected data volume and growth?
4. Are there any existing systems we need to integrate with?
```

### API Design

```
Let's define your API contract:

For each endpoint, we'll need:
- HTTP method and path
- Request parameters and body schema
- Response format and status codes
- Authentication requirements
- Rate limiting considerations

What API endpoints are essential for your application?
```

## Testing Strategy Prompts

### Unit Testing

```
For unit testing, consider:

1. Which frameworks fit your stack? (Jest, Mocha, pytest, etc.)
2. What's your target code coverage percentage?
3. Will you use TDD (Test-Driven Development)?
4. How will you handle test data fixtures?

What's your team's testing experience?
```

### Functional Testing

```
Functional testing approach:

1. Will you need end-to-end testing? (Playwright, Cypress, Selenium)
2. How will you manage test environments?
3. Do you need performance/load testing?
4. What's your CI/CD pipeline for tests?

Are there critical user flows we should prioritize?
```

## Docker Deployment Prompts

### Containerization Readiness

```
For Docker deployment, we need to plan:

1. Base image selection (official images, Alpine variants)
2. Multi-stage build optimization
3. Environment variable configuration
4. Data persistence strategy (volumes)
5. Health check implementation
6. Log management approach

Do you have any existing Docker experience in your team?
```

### Production Considerations

```
Production deployment checklist:

1. Container orchestration? (Docker Swarm, Kubernetes, etc.)
2. Monitoring and alerting strategy?
3. Backup and disaster recovery?
4. SSL/TLS certificate management?
5. Domain and routing configuration?

What's your target deployment environment?
```

## Design Patterns Prompts

### Pattern Selection

```
Based on your requirements, here are pattern recommendations:

[Dynamic based on project analysis]

Would you like me to elaborate on any of these patterns or suggest alternatives?
```

### Extension Points

```
For future extensibility, consider:

1. Plugin/hook systems for feature expansion
2. Strategy pattern for interchangeable algorithms
3. Observer pattern for event-driven features
4. Repository pattern for data access abstraction

Which areas do you anticipate needing the most flexibility?
```

## Follow-up Question Templates

| Phase | Question Type | Template |
|-------|---------------|----------|
| Requirements | Clarification | "Could you elaborate on...?" |
| Requirements | Validation | "So if I understand correctly, you mean...?" |
| Technical | Constraints | "Are there any restrictions on...?" |
| Technical | Trade-offs | "Between X and Y, which is more important to you?" |
| Testing | Priority | "Which scenario is more critical to test first?" |
| Docker | Experience | "Have you worked with Docker before?" |
| Docker | Infrastructure | "What's your current hosting infrastructure?" |
