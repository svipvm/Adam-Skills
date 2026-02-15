# 通用工具函数

本模块包含可在多个 skill 间复用的通用工具函数。

## 目录解析工具

### getSkillDir

获取 skill 目录路径。

```typescript
function getSkillDir(skillName: string): string {
  return `skills/${skillName}`;
}
```

### resolveIncludePath

解析 include 引用路径。

```typescript
function resolveIncludePath(skillDir: string, includeName: string): string {
  return `${skillDir}/includes/${includeName}.md`;
}
```

## 文件操作工具

### readSkillFile

读取 skill 文件内容。

```typescript
async function readSkillFile(skillName: string, fileName: string): Promise<string> {
  const path = `skills/${skillName}/${fileName}`;
  return await readFile(path);
}
```

### listSkillIncludes

列出 skill 的所有 includes 文件。

```typescript
async function listSkillIncludes(skillDir: string): Promise<string[]> {
  const includesDir = `${skillDir}/includes`;
  return await listFiles(includesDir, '*.md');
}
```

## Frontmatter 解析工具

### parseFrontmatter

解析 YAML frontmatter。

```typescript
function parseFrontmatter(content: string): { data: Record<string, any>; body: string } {
  const match = content.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
  if (!match) {
    return { data: {}, body: content };
  }
  const yaml = match[1];
  const body = match[2];
  const data = parseYaml(yaml);
  return { data, body };
}
```

### extractDependencies

从 frontmatter 提取依赖。

```typescript
function extractDependencies(frontmatter: any): string[] {
  const requires = frontmatter.requires || [];
  return requires.map((r: any) => r.skill);
}
```

## 引用解析工具

### findReferences

查找所有引用。

```typescript
function findReferences(content: string): Reference[] {
  const regex = /\[\[(\w+):([^\]]+)\]\]/g;
  const refs: Reference[] = [];
  let match;
  while ((match = regex.exec(content)) !== null) {
    refs.push({ type: match[1], value: match[2] });
  }
  return refs;
}
```

## 验证工具

### validateSkillStructure

验证 skill 目录结构。

```typescript
function validateSkillStructure(skillDir: string): ValidationResult {
  const required = ['SKILL.md'];
  const optional = ['includes', 'scripts', 'context', 'types'];
  const errors: string[] = [];

  for (const file of required) {
    if (!exists(`${skillDir}/${file}`)) {
      errors.push(`Missing required file: ${file}`);
    }
  }

  return { valid: errors.length === 0, errors };
}
```
