# Python Code Quality Checker - API Reference

This document provides comprehensive API reference documentation for the Python Code Quality Checker, including module APIs, function signatures, class interfaces, data models, and integration points.

## Table of Contents

- [Core Modules](#core-modules)
- [Data Models](#data-models)
- [Configuration API](#configuration-api)
- [Tool Execution API](#tool-execution-api)
- [Report Generation API](#report-generation-api)
- [Auto-Fixer API](#auto-fixer-api)
- [Integration Points](#integration-points)
- [Exception Handling](#exception-handling)
- [Type Definitions](#type-definitions)

---

## Core Modules

### Module: `quality_checker`

Main entry point for the Python Code Quality Checker.

#### Class: `QualityChecker`

```python
class QualityChecker:
    """
    Main quality checker class that orchestrates all quality checks.
    
    Attributes:
        config: Configuration object
        project_root: Path to project root directory
        cache: Cache manager instance
    """
    
    def __init__(
        self,
        config: Optional[Union[Dict[str, Any], Path, str]] = None,
        project_root: Optional[Path] = None
    ) -> None:
        """
        Initialize the quality checker.
        
        Args:
            config: Configuration dict, path to config file, or None for auto-detection
            project_root: Project root directory, or None for auto-detection
            
        Example:
            >>> checker = QualityChecker()
            >>> checker = QualityChecker(config={'strictness': 'strict'})
            >>> checker = QualityChecker(config='path/to/config.yaml')
        """
    
    def check(
        self,
        paths: Optional[List[Union[str, Path]]] = None,
        tools: Optional[List[str]] = None
    ) -> QualityReport:
        """
        Run quality checks on specified paths.
        
        Args:
            paths: List of file/directory paths to check (default: configured paths)
            tools: List of tools to run (default: configured tools)
            
        Returns:
            QualityReport: Comprehensive quality report
            
        Raises:
            QualityCheckerError: If check fails
            
        Example:
            >>> report = checker.check(['src/', 'tests/'])
            >>> print(report.summary)
        """
    
    def fix(
        self,
        paths: Optional[List[Union[str, Path]]] = None,
        dry_run: bool = False,
        backup: bool = True
    ) -> FixReport:
        """
        Auto-fix issues in specified paths.
        
        Args:
            paths: List of file/directory paths to fix (default: configured paths)
            dry_run: If True, show changes without applying
            backup: If True, create backups before fixing
            
        Returns:
            FixReport: Report of fixes applied
            
        Raises:
            FixError: If fixing fails
            
        Example:
            >>> report = checker.fix(['src/'], dry_run=True)
            >>> print(report.changes)
        """
    
    def validate_config(self) -> ValidationResult:
        """
        Validate the current configuration.
        
        Returns:
            ValidationResult: Validation result with errors and warnings
            
        Example:
            >>> result = checker.validate_config()
            >>> if not result.is_valid:
            ...     print(result.errors)
        """
```

---

## Data Models

### Class: `Issue`

```python
@dataclass
class Issue:
    """
    Represents a single code quality issue.
    
    Attributes:
        file: Path to the file containing the issue
        line: Line number (1-indexed)
        column: Column number (1-indexed)
        severity: Issue severity level
        code: Error/warning code
        message: Human-readable message
        tool: Tool that reported the issue
        end_line: End line number (optional, for multi-line issues)
        end_column: End column number (optional)
        fix_available: Whether auto-fix is available
        fix_suggestion: Suggested fix (optional)
    """
    
    file: str
    line: int
    column: int
    severity: Severity
    code: str
    message: str
    tool: str
    end_line: Optional[int] = None
    end_column: Optional[int] = None
    fix_available: bool = False
    fix_suggestion: Optional[str] = None
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary representation."""
    
    def to_json(self) -> str:
        """Convert to JSON string."""
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'Issue':
        """Create from dictionary."""
    
    def __str__(self) -> str:
        """String representation: 'file:line:column: code message'"""
```

### Class: `Severity`

```python
class Severity(Enum):
    """Issue severity levels."""
    
    CRITICAL = "critical"      # Will cause runtime failure
    ERROR = "error"            # Should be fixed
    WARNING = "warning"        # Style or potential issue
    INFO = "info"              # Informational suggestion
    CONVENTION = "convention"  # Naming/style convention
    REFACTOR = "refactor"      # Refactoring suggestion
    
    @property
    def priority(self) -> int:
        """Get priority for sorting (higher = more severe)."""
    
    def __lt__(self, other: 'Severity') -> bool:
        """Compare severity levels."""
```

### Class: `QualityReport`

```python
@dataclass
class QualityReport:
    """
    Comprehensive quality check report.
    
    Attributes:
        project: Project name
        timestamp: Report generation timestamp
        duration: Check duration in seconds
        files_checked: Number of files checked
        issues: List of all issues found
        tool_results: Results from each tool
        summary: Summary statistics
    """
    
    project: str
    timestamp: datetime
    duration: float
    files_checked: int
    issues: List[Issue]
    tool_results: Dict[str, ToolResult]
    summary: ReportSummary
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
    
    def to_json(self, indent: int = 2) -> str:
        """Convert to JSON string."""
    
    def to_junit_xml(self) -> str:
        """Convert to JUnit XML format."""
    
    def to_github_annotations(self) -> str:
        """Convert to GitHub Actions annotations."""
    
    def to_sarif(self) -> Dict[str, Any]:
        """Convert to SARIF format."""
    
    def to_html(self, template: Optional[str] = None) -> str:
        """Convert to HTML report."""
    
    def filter_by_severity(
        self,
        min_severity: Severity
    ) -> List[Issue]:
        """Filter issues by minimum severity."""
    
    def filter_by_file(self, file_pattern: str) -> List[Issue]:
        """Filter issues by file pattern."""
    
    def filter_by_code(self, codes: List[str]) -> List[Issue]:
        """Filter issues by error codes."""
    
    def group_by_file(self) -> Dict[str, List[Issue]]:
        """Group issues by file."""
    
    def group_by_severity(self) -> Dict[Severity, List[Issue]]:
        """Group issues by severity."""
    
    def group_by_tool(self) -> Dict[str, List[Issue]]:
        """Group issues by tool."""
    
    def get_top_issues(self, n: int = 10) -> List[Tuple[str, int]]:
        """Get top N most common issues."""
    
    def save(self, path: Union[str, Path], format: str = 'json') -> None:
        """
        Save report to file.
        
        Args:
            path: Output file path
            format: Output format ('json', 'junit', 'sarif', 'html')
        """
```

### Class: `ReportSummary`

```python
@dataclass
class ReportSummary:
    """Summary statistics for quality report."""
    
    total_issues: int
    by_severity: Dict[Severity, int]
    by_category: Dict[str, int]
    by_tool: Dict[str, int]
    top_issues: List[Tuple[str, int]]
    files_with_most_issues: List[Tuple[str, int]]
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
```

### Class: `ToolResult`

```python
@dataclass
class ToolResult:
    """
    Result from running a single tool.
    
    Attributes:
        tool: Tool name
        success: Whether tool ran successfully
        issues: List of issues found
        error_message: Error message if tool failed
        execution_time: Execution time in seconds
        files_checked: Number of files checked
    """
    
    tool: str
    success: bool
    issues: List[Issue] = field(default_factory=list)
    error_message: Optional[str] = None
    execution_time: float = 0.0
    files_checked: int = 0
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
```

### Class: `FixReport`

```python
@dataclass
class FixReport:
    """
    Report of auto-fix operations.
    
    Attributes:
        files_modified: Number of files modified
        issues_fixed: Number of issues fixed
        backups_dir: Directory containing backups
        changes: List of file changes
        errors: List of fix errors
    """
    
    files_modified: int
    issues_fixed: int
    backups_dir: Optional[Path]
    changes: List[FileChange]
    errors: List[FixError]
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
    
    def get_diff(self) -> str:
        """Get unified diff of all changes."""
```

### Class: `FileChange`

```python
@dataclass
class FileChange:
    """Represents a change to a file."""
    
    file: Path
    backup: Optional[Path]
    fixes_applied: List[str]
    lines_added: int
    lines_removed: int
    lines_modified: int
    
    def get_diff(self) -> str:
        """Get unified diff for this change."""
    
    def rollback(self) -> bool:
        """Rollback the change using backup."""
```

---

## Configuration API

### Module: `quality_checker.config`

#### Class: `ConfigurationManager`

```python
class ConfigurationManager:
    """
    Manages configuration loading, merging, and validation.
    """
    
    def __init__(self, project_root: Optional[Path] = None):
        """
        Initialize configuration manager.
        
        Args:
            project_root: Project root directory
        """
    
    def load(
        self,
        config_path: Optional[Union[str, Path]] = None,
        cli_args: Optional[Dict[str, Any]] = None
    ) -> QualityCheckerConfig:
        """
        Load and merge configuration from all sources.
        
        Args:
            config_path: Optional explicit config file path
            cli_args: Optional CLI argument overrides
            
        Returns:
            QualityCheckerConfig: Merged configuration
            
        Example:
            >>> manager = ConfigurationManager()
            >>> config = manager.load()
        """
    
    def find_config_file(self) -> Optional[Path]:
        """Find configuration file in project."""
    
    def validate(
        self,
        config: Dict[str, Any]
    ) -> ValidationResult:
        """Validate configuration dictionary."""
    
    def migrate(
        self,
        config: Dict[str, Any]
    ) -> MigrationResult:
        """Migrate configuration to current version."""
```

#### Class: `QualityCheckerConfig`

```python
@dataclass
class QualityCheckerConfig:
    """
    Complete configuration for quality checker.
    
    Attributes:
        version: Configuration schema version
        strictness: Strictness level
        linters: List of linters to run
        type_checker: Type checker to use
        formatters: List of formatters
        rules: Rule configuration
        mypy: Mypy-specific configuration
        pylint: Pylint-specific configuration
        ruff: Ruff-specific configuration
        flake8: Flake8-specific configuration
        black: Black-specific configuration
        isort: Isort-specific configuration
        ignore: Ignore rules
        per_file_ignores: Per-file ignore rules
        exclude: Exclude patterns
        auto_fix: Enable auto-fixing
        fail_threshold: Fail threshold severity
        output_format: Output format
        parallel: Number of parallel processes
        cache: Enable caching
        cache_dir: Cache directory
        paths: Paths to check
        config_file: Config file path
    """
    
    version: str = '1.0'
    strictness: str = 'normal'
    linters: List[str] = field(default_factory=lambda: ['ruff'])
    type_checker: str = 'mypy'
    formatters: List[str] = field(default_factory=lambda: ['black', 'isort'])
    
    rules: RulesConfig = field(default_factory=RulesConfig)
    mypy: MypyConfig = field(default_factory=MypyConfig)
    pylint: PylintConfig = field(default_factory=PylintConfig)
    ruff: RuffConfig = field(default_factory=RuffConfig)
    flake8: Flake8Config = field(default_factory=Flake8Config)
    black: BlackConfig = field(default_factory=BlackConfig)
    isort: IsortConfig = field(default_factory=IsortConfig)
    
    ignore: List[Union[str, IgnoreRuleConfig]] = field(default_factory=list)
    per_file_ignores: Dict[str, List[str]] = field(default_factory=dict)
    exclude: List[str] = field(default_factory=lambda: [
        'venv/', '.venv/', 'build/', 'dist/', '.git/', '__pycache__/'
    ])
    
    auto_fix: bool = True
    fail_threshold: str = 'warning'
    output_format: str = 'text'
    parallel: int = 4
    cache: bool = True
    cache_dir: str = '.quality-checker-cache'
    
    paths: List[str] = field(default_factory=lambda: ['.'])
    config_file: Optional[str] = None
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'QualityCheckerConfig':
        """Create from dictionary."""
    
    def to_yaml(self, path: Union[str, Path]) -> None:
        """Save to YAML file."""
    
    def to_toml(self, path: Union[str, Path]) -> None:
        """Save to TOML file."""
```

#### Class: `RulesConfig`

```python
@dataclass
class RulesConfig:
    """Rule configuration."""
    
    max_line_length: int = 100
    max_complexity: int = 10
    max_function_length: int = 50
    max_class_length: int = 300
    max_arguments: int = 5
    max_returns: int = 6
    max_branches: int = 12
    max_statements: int = 50
    max_nested_blocks: int = 5
    max_cognitive_complexity: int = 15
    min_public_methods: int = 2
    max_public_methods: int = 20
```

#### Class: `IgnoreRuleConfig`

```python
@dataclass
class IgnoreRuleConfig:
    """Configuration for an ignore rule."""
    
    pattern: str
    codes: List[str] = field(default_factory=list)
    files: List[str] = field(default_factory=list)
    reason: Optional[str] = None
    expires: Optional[str] = None
    regex: bool = False
```

#### Class: `ValidationResult`

```python
@dataclass
class ValidationResult:
    """Result of configuration validation."""
    
    is_valid: bool
    errors: List[str] = field(default_factory=list)
    warnings: List[str] = field(default_factory=list)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
```

---

## Tool Execution API

### Module: `quality_checker.tools`

#### Class: `ToolRunner`

```python
class ToolRunner:
    """
    Executes code quality tools and parses output.
    """
    
    def __init__(
        self,
        project_root: Path,
        config: QualityCheckerConfig
    ):
        """
        Initialize tool runner.
        
        Args:
            project_root: Project root directory
            config: Quality checker configuration
        """
    
    def run_tool(
        self,
        tool: str,
        paths: List[str],
        config: Optional[Dict[str, Any]] = None
    ) -> ToolResult:
        """
        Run a single tool.
        
        Args:
            tool: Tool name ('mypy', 'pylint', 'flake8', 'ruff')
            paths: Paths to check
            config: Tool-specific configuration
            
        Returns:
            ToolResult: Tool execution result
            
        Raises:
            ToolNotFoundError: If tool is not installed
            ToolExecutionError: If tool execution fails
        """
    
    def run_all(
        self,
        paths: List[str],
        tools: Optional[List[str]] = None
    ) -> Dict[str, ToolResult]:
        """
        Run all configured tools.
        
        Args:
            paths: Paths to check
            tools: Tools to run (default: all configured)
            
        Returns:
            Dict mapping tool names to results
        """
    
    def run_mypy(
        self,
        paths: List[str],
        config: Optional[Dict[str, Any]] = None
    ) -> ToolResult:
        """Run mypy type checker."""
    
    def run_pylint(
        self,
        paths: List[str],
        config: Optional[Dict[str, Any]] = None
    ) -> ToolResult:
        """Run pylint linter."""
    
    def run_flake8(
        self,
        paths: List[str],
        config: Optional[Dict[str, Any]] = None
    ) -> ToolResult:
        """Run flake8 linter."""
    
    def run_ruff(
        self,
        paths: List[str],
        config: Optional[Dict[str, Any]] = None
    ) -> ToolResult:
        """Run ruff linter."""
    
    def check_tool_installed(self, tool: str) -> bool:
        """Check if a tool is installed."""
    
    def get_tool_version(self, tool: str) -> Optional[str]:
        """Get installed tool version."""
    
    def install_tool(
        self,
        tool: str,
        version: Optional[str] = None
    ) -> bool:
        """Install a tool."""
```

#### Class: `OutputParser`

```python
class OutputParser:
    """Parses output from various tools."""
    
    @staticmethod
    def parse_mypy(output: str) -> List[Issue]:
        """Parse mypy output."""
    
    @staticmethod
    def parse_pylint(output: str) -> List[Issue]:
        """Parse pylint JSON output."""
    
    @staticmethod
    def parse_flake8(output: str) -> List[Issue]:
        """Parse flake8 output."""
    
    @staticmethod
    def parse_ruff(output: str) -> List[Issue]:
        """Parse ruff JSON output."""
```

---

## Report Generation API

### Module: `quality_checker.reports`

#### Class: `ReportGenerator`

```python
class ReportGenerator:
    """Generates reports in various formats."""
    
    def __init__(self, report: QualityReport):
        """
        Initialize report generator.
        
        Args:
            report: Quality report to generate from
        """
    
    def generate_text(self) -> str:
        """Generate text report."""
    
    def generate_json(self, indent: int = 2) -> str:
        """Generate JSON report."""
    
    def generate_junit_xml(self) -> str:
        """Generate JUnit XML report."""
    
    def generate_github_annotations(self) -> str:
        """Generate GitHub Actions annotations."""
    
    def generate_sarif(self) -> Dict[str, Any]:
        """Generate SARIF report."""
    
    def generate_html(
        self,
        template: Optional[str] = None,
        include_charts: bool = True
    ) -> str:
        """
        Generate HTML report.
        
        Args:
            template: Custom template path
            include_charts: Include trend charts
        """
    
    def generate_markdown(self) -> str:
        """Generate Markdown report."""
    
    def save(
        self,
        path: Union[str, Path],
        format: str = 'json'
    ) -> None:
        """
        Save report to file.
        
        Args:
            path: Output file path
            format: Output format
        """
```

#### Class: `ReportBuilder`

```python
class ReportBuilder:
    """Builds quality reports from tool results."""
    
    def __init__(self, project_name: str):
        """Initialize report builder."""
    
    def add_tool_result(self, result: ToolResult) -> 'ReportBuilder':
        """Add tool result to report."""
    
    def set_duration(self, duration: float) -> 'ReportBuilder':
        """Set total check duration."""
    
    def set_files_checked(self, count: int) -> 'ReportBuilder':
        """Set number of files checked."""
    
    def build(self) -> QualityReport:
        """Build the final report."""
```

---

## Auto-Fixer API

### Module: `quality_checker.fixers`

#### Class: `AutoFixer`

```python
class AutoFixer:
    """
    Automatically fixes code quality issues.
    """
    
    def __init__(
        self,
        project_root: Path,
        config: QualityCheckerConfig
    ):
        """
        Initialize auto-fixer.
        
        Args:
            project_root: Project root directory
            config: Quality checker configuration
        """
    
    def fix(
        self,
        paths: List[str],
        dry_run: bool = False,
        backup: bool = True,
        issues: Optional[List[Issue]] = None
    ) -> FixReport:
        """
        Fix issues in specified paths.
        
        Args:
            paths: Paths to fix
            dry_run: Preview changes without applying
            backup: Create backups before fixing
            issues: Specific issues to fix (default: all auto-fixable)
            
        Returns:
            FixReport: Report of fixes applied
        """
    
    def preview_fixes(
        self,
        paths: List[str]
    ) -> Dict[str, str]:
        """
        Preview fixes without applying.
        
        Returns:
            Dict mapping file paths to diffs
        """
    
    def rollback(
        self,
        backup_dir: Union[str, Path]
    ) -> bool:
        """
        Rollback fixes from backup directory.
        
        Args:
            backup_dir: Directory containing backups
            
        Returns:
            True if rollback successful
        """
    
    def get_fixable_issues(
        self,
        issues: List[Issue]
    ) -> List[Issue]:
        """Filter issues that can be auto-fixed."""
    
    def apply_fix(
        self,
        issue: Issue,
        file_path: Path
    ) -> bool:
        """Apply fix for a single issue."""
```

#### Class: `FixStrategy`

```python
class FixStrategy(ABC):
    """Base class for fix strategies."""
    
    @abstractmethod
    def can_fix(self, issue: Issue) -> bool:
        """Check if this strategy can fix the issue."""
    
    @abstractmethod
    def apply(
        self,
        file_path: Path,
        issue: Issue
    ) -> Tuple[str, str]:
        """
        Apply fix to file.
        
        Returns:
            Tuple of (original_content, fixed_content)
        """
```

#### Class: `ImportFixer`

```python
class ImportFixer(FixStrategy):
    """Fixes import-related issues."""
    
    def can_fix(self, issue: Issue) -> bool:
        """Can fix unused imports and import order."""
    
    def apply(
        self,
        file_path: Path,
        issue: Issue
    ) -> Tuple[str, str]:
        """Remove unused imports or sort imports."""
```

#### Class: `WhitespaceFixer`

```python
class WhitespaceFixer(FixStrategy):
    """Fixes whitespace issues."""
    
    def can_fix(self, issue: Issue) -> bool:
        """Can fix trailing whitespace and blank line issues."""
    
    def apply(
        self,
        file_path: Path,
        issue: Issue
    ) -> Tuple[str, str]:
        """Fix whitespace issues."""
```

---

## Integration Points

### Module: `quality_checker.integrations`

#### Class: `CIIntegration`

```python
class CIIntegration:
    """Base class for CI/CD integrations."""
    
    @staticmethod
    def detect_ci() -> Optional[str]:
        """Detect current CI environment."""
    
    @staticmethod
    def get_output_format() -> str:
        """Get appropriate output format for CI."""
    
    @staticmethod
    def should_fail(report: QualityReport, threshold: str) -> bool:
        """Determine if build should fail."""
```

#### Class: `GitHubActionsIntegration`

```python
class GitHubActionsIntegration(CIIntegration):
    """GitHub Actions integration."""
    
    @staticmethod
    def create_annotations(report: QualityReport) -> str:
        """Create GitHub Actions annotations."""
    
    @staticmethod
    def set_output(name: str, value: str) -> None:
        """Set GitHub Actions output variable."""
    
    @staticmethod
    def create_summary(report: QualityReport) -> str:
        """Create GitHub Actions job summary."""
```

#### Class: `GitLabCIIntegration`

```python
class GitLabCIIntegration(CIIntegration):
    """GitLab CI integration."""
    
    @staticmethod
    def create_codequality_report(report: QualityReport) -> Dict[str, Any]:
        """Create GitLab code quality report."""
    
    @staticmethod
    def create_artifact(report: QualityReport, path: Path) -> None:
        """Create GitLab CI artifact."""
```

#### Class: `PreCommitHook`

```python
class PreCommitHook:
    """Pre-commit hook integration."""
    
    @staticmethod
    def install() -> bool:
        """Install pre-commit hook."""
    
    @staticmethod
    def run(files: List[str]) -> int:
        """Run pre-commit hook on files."""
    
    @staticmethod
    def get_staged_files() -> List[str]:
        """Get list of staged files."""
```

---

## Exception Handling

### Exception Hierarchy

```python
class QualityCheckerError(Exception):
    """Base exception for quality checker."""
    
    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None):
        self.message = message
        self.details = details or {}
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            'error': self.__class__.__name__,
            'message': self.message,
            'details': self.details
        }

class ConfigurationError(QualityCheckerError):
    """Configuration-related error."""
    pass

class ToolNotFoundError(QualityCheckerError):
    """Tool is not installed."""
    
    def __init__(self, tool: str):
        super().__init__(
            f"Tool '{tool}' is not installed",
            {'tool': tool}
        )

class ToolExecutionError(QualityCheckerError):
    """Tool execution failed."""
    
    def __init__(self, tool: str, message: str, exit_code: int):
        super().__init__(
            f"Tool '{tool}' execution failed: {message}",
            {'tool': tool, 'exit_code': exit_code}
        )

class FixError(QualityCheckerError):
    """Auto-fix operation failed."""
    pass

class ValidationError(QualityCheckerError):
    """Validation failed."""
    pass

class CacheError(QualityCheckerError):
    """Cache operation failed."""
    pass
```

### Exception Handling Example

```python
from quality_checker import QualityChecker, QualityCheckerError

try:
    checker = QualityChecker()
    report = checker.check(['src/'])
    
    if report.summary.total_issues > 0:
        print(f"Found {report.summary.total_issues} issues")
        
except ConfigurationError as e:
    print(f"Configuration error: {e.message}")
    print(f"Details: {e.details}")
    
except ToolNotFoundError as e:
    print(f"Missing tool: {e.details['tool']}")
    print("Install with: pip install <tool>")
    
except ToolExecutionError as e:
    print(f"Tool failed: {e.message}")
    print(f"Exit code: {e.details['exit_code']}")
    
except QualityCheckerError as e:
    print(f"Quality check failed: {e.message}")
```

---

## Type Definitions

### Type Aliases

```python
from typing import Union, List, Dict, Any, Optional, Path
from pathlib import Path as PathlibPath

PathLike = Union[str, PathlibPath]
ConfigDict = Dict[str, Any]
IssueList = List[Issue]
ToolConfig = Dict[str, Any]
```

### Protocol Definitions

```python
from typing import Protocol

class ToolPlugin(Protocol):
    """Protocol for tool plugins."""
    
    @property
    def name(self) -> str:
        """Tool name."""
    
    @property
    def version(self) -> str:
        """Tool version."""
    
    def run(
        self,
        paths: List[str],
        config: Optional[Dict[str, Any]] = None
    ) -> ToolResult:
        """Run the tool."""
    
    def is_installed(self) -> bool:
        """Check if tool is installed."""

class ReporterPlugin(Protocol):
    """Protocol for reporter plugins."""
    
    @property
    def format_name(self) -> str:
        """Format name."""
    
    def generate(self, report: QualityReport) -> str:
        """Generate report."""
```

---

## Utility Functions

### Module: `quality_checker.utils`

```python
def find_python_files(
    paths: List[PathLike],
    exclude: Optional[List[str]] = None
) -> List[Path]:
    """
    Find all Python files in paths.
    
    Args:
        paths: Paths to search
        exclude: Patterns to exclude
        
    Returns:
        List of Python file paths
    """

def should_ignore_file(
    file_path: Path,
    ignore_rules: List[IgnoreRuleConfig]
) -> bool:
    """
    Check if file should be ignored.
    
    Args:
        file_path: File path to check
        ignore_rules: Ignore rules to apply
        
    Returns:
        True if file should be ignored
    """

def calculate_complexity(source: str) -> int:
    """
    Calculate cyclomatic complexity of code.
    
    Args:
        source: Python source code
        
    Returns:
        Cyclomatic complexity score
    """

def format_issue(issue: Issue, format: str = 'text') -> str:
    """
    Format issue for display.
    
    Args:
        issue: Issue to format
        format: Output format ('text', 'json', 'github')
        
    Returns:
        Formatted issue string
    """

def get_git_changed_files(
    base_branch: str = 'main'
) -> List[str]:
    """
    Get list of files changed from base branch.
    
    Args:
        base_branch: Base branch to compare
        
    Returns:
        List of changed file paths
    """

def create_backup(
    file_path: Path,
    backup_dir: Path
) -> Path:
    """
    Create backup of file.
    
    Args:
        file_path: File to backup
        backup_dir: Backup directory
        
    Returns:
        Path to backup file
    """
```

---

## Complete Usage Example

```python
from pathlib import Path
from quality_checker import (
    QualityChecker,
    QualityCheckerConfig,
    Severity,
    QualityCheckerError
)

def main():
    try:
        checker = QualityChecker(
            config={
                'strictness': 'strict',
                'linters': ['ruff', 'mypy'],
                'rules': {
                    'max_line_length': 88,
                    'max_complexity': 8
                }
            },
            project_root=Path.cwd()
        )
        
        report = checker.check(
            paths=['src/', 'tests/'],
            tools=['ruff', 'mypy']
        )
        
        print(f"Files checked: {report.files_checked}")
        print(f"Total issues: {report.summary.total_issues}")
        
        errors = report.filter_by_severity(Severity.ERROR)
        print(f"Errors: {len(errors)}")
        
        for issue in errors[:10]:
            print(f"  {issue.file}:{issue.line}: {issue.code} {issue.message}")
        
        report.save('quality-report.json', format='json')
        
        if report.summary.total_issues > 0:
            fix_report = checker.fix(
                paths=['src/'],
                dry_run=False,
                backup=True
            )
            print(f"Fixed {fix_report.issues_fixed} issues")
        
        return 0 if report.summary.total_issues == 0 else 1
        
    except QualityCheckerError as e:
        print(f"Error: {e.message}")
        return 1

if __name__ == '__main__':
    exit(main())
```

---

## API Versioning

The API follows semantic versioning:

- **Major version (X.0.0):** Breaking changes
- **Minor version (0.X.0):** New features, backward compatible
- **Patch version (0.0.X):** Bug fixes, backward compatible

Current API version: **1.0.0**

---

## Deprecation Policy

When APIs are deprecated:

1. Warning is issued for one major version
2. Documentation marks API as deprecated
3. Alternative API is provided
4. API is removed in next major version

Example deprecation:

```python
import warnings

def old_function():
    """
    Deprecated: Use new_function() instead.
    
    .. deprecated:: 1.0.0
       Use :func:`new_function` instead.
    """
    warnings.warn(
        "old_function is deprecated, use new_function",
        DeprecationWarning,
        stacklevel=2
    )
    return new_function()
```

---

## Quick Reference

| Class | Purpose |
|-------|---------|
| `QualityChecker` | Main entry point |
| `Issue` | Single quality issue |
| `Severity` | Issue severity level |
| `QualityReport` | Comprehensive report |
| `ToolResult` | Single tool result |
| `FixReport` | Auto-fix report |
| `ConfigurationManager` | Config management |
| `QualityCheckerConfig` | Configuration data |
| `ToolRunner` | Execute tools |
| `AutoFixer` | Fix issues |
| `ReportGenerator` | Generate reports |

| Function | Purpose |
|----------|---------|
| `check()` | Run quality checks |
| `fix()` | Auto-fix issues |
| `validate_config()` | Validate configuration |
| `to_dict()` | Convert to dictionary |
| `to_json()` | Convert to JSON |
| `filter_by_severity()` | Filter issues |
| `save()` | Save report |
