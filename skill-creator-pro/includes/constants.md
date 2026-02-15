# 常量定义

本模块包含 skill 系统中使用的常量定义。

## 目录常量

```typescript
const SKILL_DIR = 'skills';
const INCLUDES_DIR = 'includes';
const SCRIPTS_DIR = 'scripts';
const CONTEXT_DIR = 'context';
const TYPES_DIR = 'types';
const MAIN_FILE = 'SKILL.md';
const INDEX_FILE = 'INDEX.md';
```

## 文件扩展名

```typescript
const FILE_EXTENSIONS = {
  MARKDOWN: '.md',
  TYPESCRIPT: '.ts',
  JAVASCRIPT: '.js',
  YAML: '.yaml',
  JSON: '.json',
  SHELL: '.sh',
};
```

## 引用语法常量

```typescript
const REFERENCE_SYNTAX = {
  INCLUDE: /\[\[include:([^\]]+)\]\]/g,
  LOAD: /\[\[load:context\/([^\]]+)\]\]/g,
  SKILL: /\[\[skill:([^\]]+)\]\]/g,
  TEMPLATE: /\[\[template:([^\]]+)\]\]/g,
};
```

## Frontmatter 字段常量

```typescript
const FRONTMATTER_FIELDS = {
  REQUIRED: ['name', 'description'],
  OPTIONAL: ['version', 'requires', 'includes', 'context', 'performance'],
  PERFORMANCE: ['lazy_load', 'cache'],
};
```

## 验证常量

```typescript
const VALIDATION = {
  MAX_NAME_LENGTH: 50,
  MAX_DESCRIPTION_LENGTH: 200,
  MIN_VERSION_LENGTH: 3,
  MAX_DEPTH: 5,
  MAX_INCLUDES: 20,
  MAX_CONTEXT: 10,
};
```

## 性能常量

```typescript
const PERFORMANCE = {
  DEFAULT_LAZY_LOAD: true,
  DEFAULT_CACHE: true,
  CACHE_TTL: 3600,
  MAX_CACHE_SIZE: 100,
};
```

## 错误代码常量

```typescript
const ERROR_CODES = {
  E001: 'SKILL_NOT_FOUND',
  E002: 'INVALID_STRUCTURE',
  E003: 'CIRCULAR_DEPENDENCY',
  E004: 'MISSING_REQUIRED_FILE',
  E005: 'INVALID_FRONTMATHER',
  E006: 'INVALID_REFERENCE',
  E007: 'FILE_READ_ERROR',
  E008: 'PARSE_ERROR',
};
```

## 消息常量

```typescript
const MESSAGES = {
  SUCCESS: {
    SKILL_CREATED: 'Skill 创建成功',
    SKILL_UPDATED: 'Skill 更新成功',
    VALIDATION_PASSED: '验证通过',
  },
  ERROR: {
    SKILL_NOT_FOUND: 'Skill 不存在',
    INVALID_NAME: '无效的 skill 名称',
    INVALID_DESCRIPTION: '无效的描述',
    CIRCULAR_DEPENDENCY: '循环依赖',
  },
};
```
