export interface DockerProjectConfig {
  projectName: string;
  serviceType: 'database' | 'webapp' | 'cache' | 'api' | 'custom';
  image: string;
  ports: PortMapping[];
  volumes: VolumeMapping[];
  environment: EnvironmentVariable[];
  dependsOn?: string[];
}

export interface PortMapping {
  host: number;
  container: number;
  protocol: 'tcp' | 'udp';
  expose: boolean;
}

export interface VolumeMapping {
  host: string;
  container: string;
  type: 'bind' | 'volume';
}

export interface EnvironmentVariable {
  key: string;
  value: string;
  required: boolean;
  description?: string;
}

export interface ServiceDefinition {
  name: string;
  image: string;
  restart: 'always' | 'no' | 'on-failure' | 'unless-stopped';
  ports?: PortMapping[];
  volumes?: VolumeMapping[];
  environment?: EnvironmentVariable[];
  dependsOn?: string[];
  healthcheck?: HealthCheckConfig;
}

export interface HealthCheckConfig {
  test: string[];
  interval: string;
  timeout: string;
  retries: number;
  startPeriod: string;
}

export interface DockerComposeFile {
  version: string;
  services: Record<string, ServiceDefinition>;
  volumes?: Record<string, any>;
  networks?: Record<string, { driver: string }>;
}

export interface ScriptTemplate {
  name: string;
  content: string;
  variables: string[];
}

export interface ProjectTemplate {
  name: string;
  description: string;
  files: GeneratedFile[];
}

export interface GeneratedFile {
  path: string;
  content: string;
  template?: string;
}
