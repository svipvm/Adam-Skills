# 提示词模板

本模块包含创建 skill 时常用的提示词模板。

## Skill 创建模板

### 新建 Skill 模板

```markdown
---
name: "{{skill-name}}"
description: "{{简短描述功能}}"
version: "1.0.0"
---

# {{技能标题}}

{{技能详细描述}}

## 使用场景

- {{场景1}}
- {{场景2}}

## 调用方式

{{如何调用这个技能}}
```

### 复杂 Skill 模板

```markdown
---
name: "{{skill-name}}"
description: "{{简短描述功能}}"
version: "1.0.0"
requires:
  - skill: {{依赖skill}}
    optional: false
includes:
  - includes/{{子模块1}}.md
  - includes/{{子模块2}}.md
context:
  - context/{{上下文1}}.md
performance:
  lazy_load: true
  cache: true
---

# {{技能标题}}

{{技能详细描述}}

## 核心功能

{{主要功能列表}}

## 子模块说明

{{各子模块用途说明}}
```

## 验证模板

### Skill 验证清单

```markdown
## 验证清单

- [ ] SKILL.md 存在且格式正确
- [ ] frontmatter 包含 name 和 description
- [ ] description 说明功能 + 调用时机
- [ ] 目录结构符合规范
- [ ] 引用语法使用正确
```

## 文档模板

### README 模板

```markdown
# {{Skill 名称}}

{{简短描述}}

## 安装

{{安装步骤}}

## 使用

{{使用示例}}

## 配置

{{配置选项}}

## 依赖

{{依赖项列表}}
```

## 错误处理模板

### 错误消息模板

```typescript
const ERROR_MESSAGES = {
  SKILL_NOT_FOUND: "Skill '{{name}}' 不存在",
  INVALID_STRUCTURE: "Skill 目录结构无效",
  CIRCULAR_DEPENDENCY: "检测到循环依赖: {{skills}}",
  MISSING_REQUIRED: "缺少必需文件: {{file}}",
  INVALID_FRONTMATHER: "Frontmatter 格式错误",
};
```
