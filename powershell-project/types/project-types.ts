export interface ProjectConfig {
  name: string;
  version: string;
  description: string;
  author?: string;
  license?: string;
  mainScript?: string;
  homepage?: string;
}

export interface RuntimeConfig {
  port: number;
  timeout: number;
  logLevel: LogLevel;
  maxRetries: number;
  mainScript?: string;
  processName?: string;
  enableWebServer?: boolean;
  autoRestart?: boolean;
  workingDirectory?: string;
}

export interface EnvironmentConfig {
  ENV: Environment;
  DEBUG: boolean;
  custom?: Record<string, any>;
}

export type LogLevel = 'Debug' | 'Info' | 'Warning' | 'Error';

export type Environment = 'development' | 'staging' | 'production';

export interface ProcessInfo {
  Name: string;
  Id: number;
  CPU?: number;
  MemoryMB: number;
  StartTime?: Date;
  Status: 'Running' | 'Exited';
}

export interface ProjectState {
  stoppedAt: string;
  exitCode: number;
}

export interface ValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
}
