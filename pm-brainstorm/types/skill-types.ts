export interface UserStory {
  asA: string;
  iWantTo: string;
  soThat: string;
  acceptanceCriteria: string[];
  dependencies: string[];
  priority: 'must-have' | 'should-have' | 'could-have' | 'won’t-have';
}

export interface Feature {
  id: string;
  name: string;
  description: string;
  userStories: UserStory[];
  priority: number;
  effort: number;
  status: 'proposed' | 'planned' | 'in-progress' | 'completed';
}

export interface ApiEndpoint {
  method: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';
  path: string;
  description: string;
  requestSchema?: object;
  responseSchema?: object;
  errorResponses: HttpStatusCode[];
  authentication: boolean;
  rateLimit?: number;
}

export interface HttpStatusCode {
  code: number;
  message: string;
}

export interface DatabaseSchema {
  name: string;
  tables: TableDefinition[];
}

export interface TableDefinition {
  name: string;
  columns: ColumnDefinition[];
  indexes: IndexDefinition[];
  foreignKeys: ForeignKeyDefinition[];
}

export interface ColumnDefinition {
  name: string;
  type: string;
  nullable: boolean;
  primaryKey: boolean;
  defaultValue?: string;
}

export interface IndexDefinition {
  columns: string[];
  unique: boolean;
}

export interface ForeignKeyDefinition {
  column: string;
  references: string;
  onDelete: 'CASCADE' | 'SET NULL' | 'RESTRICT';
}

export interface TestPlan {
  unitTests: TestCase[];
  integrationTests: TestCase[];
  e2eTests: TestCase[];
  coverageTarget: number;
}

export interface TestCase {
  id: string;
  name: string;
  type: 'unit' | 'integration' | 'e2e';
  description: string;
  steps: string[];
  expectedResult: string;
  priority: 'critical' | 'high' | 'medium' | 'low';
}

export interface DockerConfig {
  baseImage: string;
  multiStageBuild: boolean;
  nonRootUser: boolean;
  healthCheck: HealthCheckConfig;
  environment: EnvironmentVariable[];
  volumes: VolumeMount[];
  ports: PortMapping[];
}

export interface HealthCheckConfig {
  test: string[];
  interval: string;
  timeout: string;
  retries: number;
  startPeriod: string;
}

export interface EnvironmentVariable {
  name: string;
  value: string;
  required: boolean;
  description: string;
}

export interface VolumeMount {
  hostPath: string;
  containerPath: string;
  readOnly: boolean;
}

export interface PortMapping {
  host: number;
  container: number;
  protocol: 'tcp' | 'udp';
}

export interface DockerComposeConfig {
  version: string;
  services: ServiceDefinition[];
}

export interface ServiceDefinition {
  name: string;
  build?: string;
  image?: string;
  ports: PortMapping[];
  environment: EnvironmentVariable[];
  volumes: VolumeMount[];
  dependsOn: string[];
  restart: 'no' | 'always' | 'on-failure' | 'unless-stopped';
}

export interface ArchitectureDecision {
  id: string;
  title: string;
  status: 'proposed' | 'accepted' | 'deprecated' | 'superseded';
  context: string;
  decision: string;
  consequences: string[];
  alternatives: AlternativeDecision[];
}

export interface AlternativeDecision {
  description: string;
  pros: string[];
  cons: string[];
}

export interface DesignPatternRecommendation {
  pattern: string;
  useCase: string;
  implementation: string;
  benefits: string[];
}

export interface Risk {
  id: string;
  name: string;
  description: string;
  impact: number;
  probability: number;
  score: number;
  level: 'low' | 'medium' | 'high';
  mitigation: string[];
}

export interface FrontendArchitecture {
  framework: 'react' | 'vue' | 'angular' | 'svelte' | 'other';
  stateManagement: string;
  uiLibrary: string;
  styling: string;
  components: ComponentDefinition[];
}

export interface ComponentDefinition {
  name: string;
  type: 'atomic' | 'molecular' | 'organism';
  props: PropDefinition[];
  children?: string[];
}

export interface PropDefinition {
  name: string;
  type: string;
  required: boolean;
  description: string;
}

export interface BackendArchitecture {
  framework: string;
  language: string;
  apiStyle: 'rest' | 'graphql' | 'grpc' | 'websocket';
  database: DatabaseConfig;
  caching: CacheConfig;
  queue?: QueueConfig;
}

export interface DatabaseConfig {
  type: 'relational' | 'document' | 'key-value' | 'graph' | 'time-series';
  engine: string;
  connectionString: string;
}

export interface CacheConfig {
  enabled: boolean;
  type: 'redis' | 'memcached' | 'local';
  ttl: number;
}

export interface QueueConfig {
  enabled: boolean;
  type: 'bull' | 'rabbitmq' | 'kafka';
  workers: number;
}

export interface ProjectPlan {
  phases: ProjectPhase[];
  milestones: Milestone[];
  timeline: TimelineItem[];
}

export interface ProjectPhase {
  name: string;
  startDate: Date;
  endDate: Date;
  deliverables: string[];
}

export interface Milestone {
  name: string;
  date: Date;
  criteria: string[];
}

export interface TimelineItem {
  task: string;
  startDate: Date;
  endDate: Date;
  assignee: string;
  dependencies: string[];
}

export type BrainstormPhase =
  | 'requirement-discovery'
  | 'technical-analysis'
  | 'testing-strategy'
  | 'docker-readiness'
  | 'risk-assessment'
  | 'summary';

export interface BrainstormSession {
  id: string;
  projectName: string;
  currentPhase: BrainstormPhase;
  requirements: Feature[];
  architecture: {
    frontend: FrontendArchitecture;
    backend: BackendArchitecture;
    api: ApiEndpoint[];
  };
  testing: TestPlan;
  docker: DockerConfig;
  risks: Risk[];
}
