# 使用示例

本文档展示 Skill Creator Pro 的各种使用场景和示例。

## 基础示例

### 1. 创建最简单的 Skill

```bash
mkdir -p skills/hello-world
```

创建 `skills/hello-world/SKILL.md`:

```markdown
---
name: "hello-world"
description: "输出 Hello World。Invoke when 用户需要基础示例。"
---

# Hello World

这是一个最简单的 skill 示例。

## 使用方法

直接调用即可：

```
[[skill:hello-world]]
```

## 输出

```
Hello, World!
```
```

### 2. 使用 Include 子模块

创建 `skills/greeting/SKILL.md`:

```markdown
---
name: "greeting"
description: "问候语生成器。Invoke when 用户需要生成问候语。"
includes:
  - includes/greeting-templates.md
---

# 问候语生成器

[[include:greeting-templates]]

## 使用方法

设置问候语类型并调用。
```

创建 `skills/greeting/includes/greeting-templates.md`:

```markdown
## 问候语模板

### 早上好
- "早上好！新的一天开始了！"
- "早安！今天也要加油！"

### 晚上好
- "晚上好！辛苦了一天好好休息！"
- "晚安！好梦！"
```

### 3. 使用 Context 分片

创建大型技能时，将大段上下文拆分：

`skills/llm-guide/SKILL.md`:

```markdown
---
name: "llm-guide"
description: "LLM 使用指南。Invoke when 用户需要 LLM 使用帮助。"
context:
  - context/prompt-engineering.md
  - context/context-window.md
  - context/token-optimization.md
---

# LLM 使用指南

本指南帮助您更好地使用大语言模型。

## 提示工程

[[load:context/prompt-engineering]]

## 上下文窗口

[[load:context/context-window]]

## Token 优化

[[load:context/token-optimization]]
```

`skills/llm-guide/context/prompt-engineering.md`:

```markdown
# 提示工程指南

## 基本原则

1. 明确具体
2. 提供示例
3. 分步指令

## 技巧

### 零样本提示
直接给出任务指令。

### 少样本提示
提供几个示例帮助模型理解。
```

## 复杂示例

### 4. 完整的多模块 Skill

```
skills/docker-project/
├── SKILL.md
├── includes/
│   ├── common-utils.md
│   ├── prompts.md
│   └── constants.md
├── scripts/
│   ├── validate.sh
│   └── build.sh
└── context/
    └── docker-compose.yml
```

`SKILL.md`:

```markdown
---
name: "docker-project"
description: "Docker 项目模板生成器。Invoke when 用户需要创建 Docker 项目结构。"
version: "1.0.0"
requires:
  - skill: skill-creator
    optional: false
includes:
  - includes/common-utils.md
  - includes/prompts.md
context:
  - context/docker-compose.yml
performance:
  lazy_load: true
  cache: true
---

# Docker 项目模板生成器

[[include:common-utils]]

[[include:prompts]]

## Docker Compose 配置

[[load:context/docker-compose.yml]]

## 使用方法

1. 指定项目名称
2. 选择服务类型
3. 生成配置
```

## 性能优化示例

### 5. 延迟加载大模块

```markdown
---
name: "large-skill"
description: "大型技能示例。"
performance:
  lazy_load: true
  cache: true
---

# 大型技能

## 常用功能（立即加载）
- 基础功能说明

## 高级功能（延迟加载）
[[load:context/advanced-features]]
```

## 最佳实践总结

1. **保持主文件简洁**：主 SKILL.md 应控制在 500 行以内
2. **合理拆分上下文**：超过 200 行的内容放入 context/
3. **复用 includes**：通用功能放在 includes/ 目录
4. **验证脚本**：创建 scripts/validate.sh 确保质量
5. **类型定义**：复杂技能使用 types/ 目录
