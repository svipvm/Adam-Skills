---
name: "skill-creator-pro"
description: "创建模块化高性能skill，支持层级调用和上下文分片。Invoke when用户需要创建复杂skill或优化现有skill结构。"
version: "1.0.0"
requires:
  - skill: skill-creator
    optional: true
includes:
  - includes/common-utils.md
  - includes/prompts.md
  - includes/constants.md
context:
  - context/examples.md
performance:
  lazy_load: true
  cache: true
---

# Skill Creator Pro

这是一个强大的 skill 创作系统，专为创建高性能、节省 token、易于维护的模块化 skill 而设计。

## 核心特性

- **模块化架构**：将复杂 skill 拆分为可复用的子模块
- **Token 优化**：大上下文拆分，按需加载
- **高性能**：延迟加载 + 缓存机制
- **强可读性**：自动索引 + 类型定义

## 目录结构

```
skills/<skill-name>/
├── SKILL.md           # 主入口（必需）
├── INDEX.md           # 自动生成的索引
├── includes/          # 可复用的子模块
│   ├── common-utils.md
│   ├── prompts.md
│   └── constants.md
├── scripts/           # 可执行脚本
│   ├── validate.sh
│   └── build.sh
├── context/           # 大上下文分片
│   └── large-context.md
└── types/             # 类型定义
    └── skill-types.ts
```

## 快速开始

### 1. 创建新 Skill

```bash
mkdir -p skills/my-new-skill/{includes,scripts,context,types}
```

### 2. 编写 SKILL.md

```markdown
---
name: "my-new-skill"
description: "简短描述（功能 + 调用时机）"
version: "1.0.0"
---

# 技能标题

技能详细说明...
```

### 3. 使用引用语法

在 SKILL.md 中使用以下引用：

| 语法 | 说明 | 示例 |
|------|------|------|
| `[[include:filename]]` | 包含子模块 | `[[include:common-utils]]` |
| `[[load:context/name]]` | 加载上下文分片 | `[[load:context/large-data]]` |
| `[[skill:skill-name]]` | 引用其他 skill | `[[skill:helper-skill]]` |

## Frontmatter 字段

### 必需字段

```yaml
---
name: "skill-name"        # 唯一标识符
description: "描述"       # 功能 + 调用时机
---
```

### 可选字段

```yaml
---
version: "1.0.0"          # 版本号
requires:                # 依赖的 skill
  - skill: other-skill
    optional: false
includes:                # 引用的子模块
  - includes/common-utils.md
context:                 # 上下文分片
  - context/part1.md
performance:             # 性能配置
  lazy_load: true        # 延迟加载
  cache: true           # 启用缓存
---
```

## 子模块说明

### includes/ - 通用模块

存放可复用的代码片段、工具函数、提示词模板等。

### scripts/ - 可执行脚本

存放验证脚本、构建脚本等可执行文件。

### context/ - 上下文分片

存放大段上下文内容，使用 `[[load:context/filename]]` 按需加载。

### types/ - 类型定义

存放 TypeScript 类型定义文件。

## 引用解析器

系统会自动解析以下引用：

1. **Include 引用** `[[include:filename]]`
   - 查找 `includes/filename.md`
   - 替换为文件内容

2. **上下文引用** `[[load:context/name]]`
   - 查找 `context/name.md`
   - 仅在实际使用时加载

3. **Skill 引用** `[[skill:skill-name]]`
   - 查找 `skills/skill-name/SKILL.md`
   - 链式加载依赖

## 性能优化

### 延迟加载

大模块使用延迟加载，仅在需要时解析：

```yaml
performance:
  lazy_load: true
```

### 缓存机制

已解析的内容会被缓存，避免重复解析：

```yaml
performance:
  cache: true
```

## 示例

### 基础 Skill

```
skills/hello-world/
└── SKILL.md
```

### 复杂 Skill

```
skills/advanced-feature/
├── SKILL.md
├── includes/
│   ├── prompts.md
│   └── utils.md
├── scripts/
│   └── validate.sh
└── context/
    └── examples.md
```

## 最佳实践

1. **保持主文件简洁**：将详细内容拆分到 includes/ 和 context/
2. **合理拆分上下文**：大段内容放入 context/ 分片
3. **复用 includes**：通用功能提取到 includes/ 目录
4. **使用类型定义**：复杂 skill 使用 types/ 目录定义类型
5. **编写验证脚本**：scripts/validate.sh 确保质量

## 相关文件

- [includes/common-utils.md](includes/common-utils.md) - 通用工具函数
- [includes/prompts.md](includes/prompts.md) - 提示词模板
- [includes/constants.md](includes/constants.md) - 常量定义
- [context/examples.md](context/examples.md) - 使用示例
- [types/skill-types.ts](types/skill-types.ts) - 类型定义
