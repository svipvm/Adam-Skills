export interface PythonImport {
  type: 'import' | 'from_import';
  module: string;
  names: string[];
  alias?: string[];
}

export interface PythonParameter {
  name: string;
  type?: string;
  default?: string;
  isVariadic?: boolean;
}

export interface PythonMethod {
  name: string;
  params: PythonParameter[];
  returnType?: string;
  body: string;
  decorators?: string[];
}

export interface PythonClass {
  name: string;
  baseClasses: string[];
  methods: PythonMethod[];
  attributes: string[];
}

export interface PythonFunction {
  name: string;
  params: PythonParameter[];
  returnType?: string;
  body: string;
}

export interface PythonVariable {
  name: string;
  value: string;
  type?: string;
}

export interface PythonStatement {
  type: 'assignment' | 'if' | 'for' | 'while' | 'try' | 'with' | 'return' | 'expression';
  content: string;
}

export interface PythonModule {
  imports: PythonImport[];
  classes: PythonClass[];
  functions: PythonFunction[];
  variables: PythonVariable[];
  statements: PythonStatement[];
}

export interface CppType {
  name: string;
  isConst: boolean;
  isPointer: boolean;
  isReference: boolean;
  templateArgs?: string[];
}

export interface CppParameter {
  name: string;
  type: CppType;
  hasDefault: boolean;
  defaultValue?: string;
}

export interface CppMethod {
  name: string;
  params: CppParameter[];
  returnType: CppType;
  isConst: boolean;
  isVirtual: boolean;
  isOverride: boolean;
  accessSpecifier: 'public' | 'private' | 'protected';
  body: string;
}

export interface CppClass {
  name: string;
  baseClasses: string[];
  methods: CppMethod[];
  members: CppMember[];
  isTemplate: boolean;
}

export interface CppMember {
  name: string;
  type: CppType;
  accessSpecifier: 'public' | 'private' | 'protected';
  isStatic: boolean;
}

export interface CppFunction {
  name: string;
  params: CppParameter[];
  returnType: CppType;
  body: string;
  isInline: boolean;
}

export interface CppProject {
  name: string;
  version: string;
  cxxStandard: string;
  classes: CppClass[];
  functions: CppFunction[];
  includes: string[];
  dependencies: string[];
}

export interface ConversionOptions {
  projectName: string;
  outputDir: string;
  cxxStandard: string;
  enableExceptions: boolean;
  enableLogging: boolean;
  enableTesting: boolean;
  additionalIncludes: string[];
  externalDependencies: string[];
}

export interface ValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
}
