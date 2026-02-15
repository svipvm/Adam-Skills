export interface SkillFrontmatter {
  name: string;
  description: string;
  version?: string;
  requires?: SkillDependency[];
  includes?: string[];
  context?: string[];
  performance?: PerformanceConfig;
}

export interface SkillDependency {
  skill: string;
  optional: boolean;
}

export interface PerformanceConfig {
  lazy_load?: boolean;
  cache?: boolean;
}

export interface Reference {
  type: 'include' | 'load' | 'skill' | 'template';
  value: string;
  line: number;
  column: number;
}

export interface SkillStructure {
  name: string;
  path: string;
  mainFile: string;
  includes: string[];
  scripts: string[];
  context: string[];
  types: string[];
}

export interface ValidationResult {
  valid: boolean;
  errors: ValidationError[];
  warnings: ValidationWarning[];
}

export interface ValidationError {
  code: string;
  message: string;
  file?: string;
  line?: number;
}

export interface ValidationWarning {
  code: string;
  message: string;
  file?: string;
}

export interface ParsedSkill {
  frontmatter: SkillFrontmatter;
  content: string;
  references: Reference[];
  includes: string[];
  dependencies: string[];
}

export interface CacheEntry {
  skill: ParsedSkill;
  timestamp: number;
  ttl: number;
}

export interface ResolverOptions {
  basePath: string;
  resolveIncludes?: boolean;
  resolveContext?: boolean;
  resolveSkills?: boolean;
  cache?: boolean;
}

export type ReferenceType = 'include' | 'load' | 'skill' | 'template';

export interface TemplateDefinition {
  name: string;
  description: string;
  structure: Partial<SkillStructure>;
  frontmatter: Partial<SkillFrontmatter>;
  content?: string;
}
