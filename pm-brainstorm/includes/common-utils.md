# Common Utilities for PM Brainstorm

## Requirement Analysis Utilities

### Feature Prioritization Matrix

```
function createPriorityMatrix(features) {
  return features.map(feature => ({
    name: feature.name,
    impact: feature.userImpact || 1,  // 1-5
    effort: feature.implementationEffort || 1,  // 1-5
    priority: (feature.userImpact * feature.implementationEffort) / 2
  })).sort((a, b) => b.priority - a.priority);
}
```

### User Story Template Generator

```
function generateUserStory(role, goal, benefit) {
  return {
    asA: role,
    iWantTo: goal,
    soThat: benefit,
    acceptanceCriteria: [],
    dependencies: [],
    priority: 'must-have'
  };
}
```

## Architecture Decision Utilities

### API Endpoint Generator

```
function generateEndpoint(resource, operation) {
  const operations = {
    list: { method: 'GET', path: `/${resource}` },
    get: { method: 'GET', path: `/${resource}/:id` },
    create: { method: 'POST', path: `/${resource}` },
    update: { method: 'PUT', path: `/${resource}/:id` },
    delete: { method: 'DELETE', path: `/${resource}/:id` }
  };
  return operations[operation];
}
```

### Database Schema Suggestion

```
function suggestDatabaseType(dataModel) {
  if (dataModel.hasComplexRelationships) return 'relational';
  if (dataModel.hasFlexibleSchema) return 'document';
  if (dataModel.isKeyValueBased) return 'key-value';
  if (dataModel.isGraphBased) return 'graph';
  return 'relational';  // default
}
```

## Testing Utilities

### Test Coverage Calculator

```
function calculateCoverage(covered, total) {
  const percentage = (covered / total) * 100;
  return {
    percentage: percentage.toFixed(2),
    status: percentage >= 80 ? 'good' :
            percentage >= 60 ? 'acceptable' : 'needs improvement'
  };
}
```

### Test Strategy Selector

```
function selectTestStrategy(projectType) {
  const strategies = {
    webApp: ['unit', 'integration', 'e2e', 'visual'],
    mobileApp: ['unit', 'integration', 'e2e', 'device'],
    api: ['unit', 'integration', 'contract', 'load'],
    microservices: ['unit', 'integration', 'contract', 'chaos']
  };
  return strategies[projectType] || strategies.webApp;
}
```

## Docker Utilities

### Dockerfile Template Generator

```
function generateDockerfile(language, packageManager) {
  const templates = {
    nodejs: {
      base: 'node:18-alpine',
      workdir: '/app',
      copy: ['package*.json', './'],
      install: 'npm ci --only=production',
      copySrc: 'COPY . .',
      user: 'node'
    },
    python: {
      base: 'python:3.11-slim',
      workdir: '/app',
      pip: 'pip install --no-cache-dir -r requirements.txt',
      user: 'python'
    }
  };
  return templates[language];
}
```

### Docker Compose Generator

```
function generateCompose(services) {
  return {
    version: '3.8',
    services: services.reduce((acc, svc) => {
      acc[svc.name] = {
        build: svc.build,
        ports: svc.ports,
        environment: svc.environment,
        volumes: svc.volumes,
        depends_on: svc.dependencies
      };
      return acc;
    }, {})
  };
}
```

## Design Pattern Selector

### Pattern Recommender

```
function recommendPattern(useCase) {
  const recommendations = {
    apiClient: ['Adapter', 'Proxy', 'Repository'],
    stateManagement: ['Observer', 'State', 'Memento'],
    validation: ['Chain of Responsibility', 'Strategy'],
    caching: ['Proxy', 'Decorator'],
    pluginSystem: ['Strategy', 'Observer', 'Factory'],
    eventHandling: ['Observer', 'Mediator'],
    dataAccess: ['Repository', 'Unit of Work'],
    externalService: ['Adapter', 'Proxy']
  };
  return recommendations[useCase] || [];
}
```

## Risk Assessment Utilities

### Risk Score Calculator

```
function calculateRiskScore(impact, probability) {
  return {
    score: impact * probability,
    level: impact * probability >= 15 ? 'high' :
           impact * probability >= 8 ? 'medium' : 'low',
    impact,
    probability
  };
}
```

### Mitigation Strategy Generator

```
function generateMitigation(risk) {
  const strategies = {
    high: ['Proof of concept', 'Expert consultation', 'Incremental rollout'],
    medium: ['Additional testing', 'Monitoring', 'Rollback plan'],
    low: ['Standard practices', 'Documentation']
  };
  return strategies[risk.level];
}
```

## Frontend-Backend Decoupling Checklist

### API Contract Validator

```
function validateApiContract(endpoints) {
  return endpoints.map(endpoint => ({
    path: endpoint.path,
    hasContract: !!endpoint.requestSchema && !!endpoint.responseSchema,
    hasExamples: !!endpoint.examples,
    hasErrorHandling: endpoint.errorResponses?.length > 0
  }));
}
```

### Interface Segregation Checker

```
function checkInterfaceSegregation(components, interfaces) {
  const unusedInterfaces = interfaces.filter(iface =>
    !components.some(c => c.implements.includes(iface.name))
  );
  const bloatedInterfaces = interfaces.filter(iface =>
    iface.methods.length > 7
  );
  return { unusedInterfaces, bloatedInterfaces };
}
```

## Code Quality Metrics

### Cyclomatic Complexity

```
function calculateComplexity(functionBody) {
  const decisions = ['if', 'else', 'case', 'for', 'while', 'catch', '&&', '||'];
  let complexity = 1;
  decisions.forEach(d => {
    const regex = new RegExp(`\\b${d}\\b`, 'g');
    complexity += (functionBody.match(regex) || []).length;
  });
  return complexity;
}
```

### Coupling Calculator

```
function calculateCoupling(dependencies, totalModules) {
  return {
    afferent: dependencies.incoming.length,
    efferent: dependencies.outgoing.length,
    instability: (dependencies.outgoing.length /
                  (dependencies.incoming.length + dependencies.outgoing.length))
                 || 0
  };
}
```
