# Third-Party Tool Integration Module

## Overview

This module provides comprehensive integration with popular Python code quality tools. It covers installation, configuration, execution, and output parsing for mypy, pylint, flake8, and ruff.

### Supported Tools

| Tool | Purpose | Speed | Best For |
|------|---------|-------|----------|
| **mypy** | Static type checking | Medium | Projects with type annotations |
| **pylint** | Comprehensive linting | Slow | Deep code analysis, custom rules |
| **flake8** | Style and complexity | Fast | PEP 8 compliance, quick checks |
| **ruff** | All-in-one linter | Very Fast | Modern projects, speed-critical CI |

---

## Implementation Guide

### Tool Installation and Version Management

#### Installation Methods

```python
import subprocess
import sys
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
import json

@dataclass
class ToolInfo:
    name: str
    package_name: str
    min_version: str
    recommended_version: str
    description: str

SUPPORTED_TOOLS: Dict[str, ToolInfo] = {
    "mypy": ToolInfo(
        name="mypy",
        package_name="mypy",
        min_version="1.0.0",
        recommended_version="1.8.0",
        description="Static type checker for Python"
    ),
    "pylint": ToolInfo(
        name="pylint",
        package_name="pylint",
        min_version="2.15.0",
        recommended_version="3.0.0",
        description="Python code static analysis"
    ),
    "flake8": ToolInfo(
        name="flake8",
        package_name="flake8",
        min_version="5.0.0",
        recommended_version="7.0.0",
        description="Style guide enforcement"
    ),
    "ruff": ToolInfo(
        name="ruff",
        package_name="ruff",
        min_version="0.1.0",
        recommended_version="0.2.0",
        description="Fast Python linter"
    )
}

def install_tool(tool_name: str, version: Optional[str] = None) -> Tuple[bool, str]:
    """
    Install a code quality tool.
    
    Args:
        tool_name: Name of the tool (mypy, pylint, flake8, ruff)
        version: Optional specific version to install
        
    Returns:
        Tuple of (success, message)
    """
    if tool_name not in SUPPORTED_TOOLS:
        return False, f"Unknown tool: {tool_name}"
    
    tool_info = SUPPORTED_TOOLS[tool_name]
    package_spec = tool_info.package_name
    
    if version:
        package_spec = f"{tool_info.package_name}=={version}"
    else:
        package_spec = f"{tool_info.package_name}>={tool_info.min_version}"
    
    try:
        result = subprocess.run(
            [sys.executable, "-m", "pip", "install", package_spec],
            capture_output=True,
            text=True,
            timeout=120
        )
        
        if result.returncode == 0:
            return True, f"Successfully installed {package_spec}"
        else:
            return False, f"Installation failed: {result.stderr}"
    except subprocess.TimeoutExpired:
        return False, "Installation timed out"
    except Exception as e:
        return False, f"Installation error: {str(e)}"

def get_installed_version(tool_name: str) -> Optional[str]:
    """
    Get the installed version of a tool.
    
    Returns:
        Version string or None if not installed
    """
    try:
        result = subprocess.run(
            [sys.executable, "-m", tool_name, "--version"],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode == 0:
            import re
            match = re.search(r'(\d+\.\d+\.\d+)', result.stdout or result.stderr)
            if match:
                return match.group(1)
    except Exception:
        pass
    return None

def check_version_compatibility(tool_name: str) -> Dict[str, any]:
    """
    Check if the installed version is compatible.
    
    Returns:
        Dict with compatibility information
    """
    if tool_name not in SUPPORTED_TOOLS:
        return {"error": f"Unknown tool: {tool_name}"}
    
    tool_info = SUPPORTED_TOOLS[tool_name]
    installed_version = get_installed_version(tool_name)
    
    if not installed_version:
        return {
            "installed": False,
            "required_min": tool_info.min_version,
            "recommended": tool_info.recommended_version
        }
    
    from packaging import version
    
    return {
        "installed": True,
        "version": installed_version,
        "required_min": tool_info.min_version,
        "recommended": tool_info.recommended_version,
        "is_compatible": version.parse(installed_version) >= version.parse(tool_info.min_version),
        "is_recommended": version.parse(installed_version) >= version.parse(tool_info.recommended_version)
    }
```

---

### Configuration File Generation

```python
from pathlib import Path
from typing import Dict, Any
import configparser
import tomli_w

class ConfigGenerator:
    """Generate configuration files for code quality tools."""
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
    
    def generate_mypy_config(self, config: Dict[str, Any]) -> Path:
        """Generate .mypy.ini configuration file."""
        config_path = self.project_root / ".mypy.ini"
        
        content = f"""[mypy]
python_version = {config.get('python_version', '3.10')}
warn_return_any = {str(config.get('warn_return_any', True)).lower()}
warn_unused_configs = {str(config.get('warn_unused_configs', True)).lower()}
disallow_untyped_defs = {str(config.get('disallow_untyped_defs', True)).lower()}
disallow_incomplete_defs = {str(config.get('disallow_incomplete_defs', True)).lower()}
check_untyped_defs = {str(config.get('check_untyped_defs', True)).lower()}
disallow_untyped_decorators = {str(config.get('disallow_untyped_decorators', True)).lower()}
no_implicit_optional = {str(config.get('no_implicit_optional', True)).lower()}
warn_redundant_casts = {str(config.get('warn_redundant_casts', True)).lower()}
warn_unused_ignores = {str(config.get('warn_unused_ignores', True)).lower()}
warn_no_return = {str(config.get('warn_no_return', True)).lower()}
strict_optional = {str(config.get('strict_optional', True)).lower()}
ignore_missing_imports = {str(config.get('ignore_missing_imports', False)).lower()}
show_error_codes = {str(config.get('show_error_codes', True)).lower()}
show_column_numbers = {str(config.get('show_column_numbers', True)).lower()}
pretty = {str(config.get('pretty', True)).lower()}
"""
        
        if config.get('exclude'):
            content += f"exclude = {config['exclude']}\n"
        
        if config.get('plugins'):
            content += f"plugins = {', '.join(config['plugins'])}\n"
        
        for module, settings in config.get('overrides', {}).items():
            content += f"\n[mypy-{module}]\n"
            for key, value in settings.items():
                content += f"{key} = {str(value).lower()}\n"
        
        config_path.write_text(content)
        return config_path
    
    def generate_pylint_config(self, config: Dict[str, Any]) -> Path:
        """Generate .pylintrc configuration file."""
        config_path = self.project_root / ".pylintrc"
        
        parser = configparser.ConfigParser()
        
        parser['MASTER'] = {
            'jobs': config.get('jobs', 0),
            'persistent': 'yes',
            'load-plugins': ','.join(config.get('load_plugins', [])),
            'ignore': ','.join(config.get('ignore', ['CVS', '.git', '.tox', 'dist', 'build'])),
            'ignore-patterns': ','.join(config.get('ignore_patterns', [])),
        }
        
        parser['MESSAGES CONTROL'] = {
            'disable': ','.join(config.get('disable', [
                'C0114',  # missing-module-docstring
                'C0115',  # missing-class-docstring
                'C0116',  # missing-function-docstring
            ])),
            'enable': ','.join(config.get('enable', [])),
        }
        
        parser['REPORTS'] = {
            'output-format': config.get('output_format', 'text'),
            'reports': 'no',
            'score': str(config.get('score', 'no')).lower(),
        }
        
        parser['BASIC'] = {
            'good-names': ','.join(config.get('good_names', ['i', 'j', 'k', 'ex', 'Run', '_'])),
            'variable-rgx': config.get('variable_rgx', '[a-z_][a-z0-9_]{2,30}$'),
            'function-rgx': config.get('function_rgx', '[a-z_][a-z0-9_]{2,30}$'),
            'class-rgx': config.get('class_rgx', '[A-Z_][a-zA-Z0-9]+$'),
            'const-rgx': config.get('const_rgx', '(([A-Z_][A-Z0-9_]*)|(__.*__))$'),
        }
        
        parser['FORMAT'] = {
            'max-line-length': config.get('max_line_length', 100),
            'max-module-lines': config.get('max_module_lines', 1000),
            'indent-string': config.get('indent_string', '    '),
        }
        
        parser['DESIGN'] = {
            'max-args': config.get('max_args', 5),
            'max-locals': config.get('max_locals', 15),
            'max-returns': config.get('max_returns', 6),
            'max-branches': config.get('max_branches', 12),
            'max-statements': config.get('max_statements', 50),
            'max-attributes': config.get('max_attributes', 7),
            'min-public-methods': config.get('min_public_methods', 2),
            'max-public-methods': config.get('max_public_methods', 20),
            'max-ancestors': config.get('max_ancestors', 7),
        }
        
        parser['REFACTORING'] = {
            'max-nested-blocks': config.get('max_nested_blocks', 5),
        }
        
        parser['SIMILARITIES'] = {
            'min-similarity-lines': config.get('min_similarity_lines', 4),
            'ignore-comments': 'yes',
            'ignore-docstrings': 'yes',
            'ignore-imports': 'yes',
        }
        
        parser['TYPECHECK'] = {
            'ignored-modules': ','.join(config.get('ignored_modules', [])),
            'ignored-classes': ','.join(config.get('ignored_classes', [])),
        }
        
        with open(config_path, 'w') as f:
            parser.write(f)
        
        return config_path
    
    def generate_flake8_config(self, config: Dict[str, Any]) -> Path:
        """Generate .flake8 configuration file."""
        config_path = self.project_root / ".flake8"
        
        parser = configparser.ConfigParser()
        
        parser['flake8'] = {
            'max-line-length': str(config.get('max_line_length', 100)),
            'max-complexity': str(config.get('max_complexity', 10)),
            'ignore': ','.join(config.get('ignore', [
                'E203',  # whitespace before ':'
                'W503',  # line break before binary operator
            ])),
            'select': ','.join(config.get('select', ['E', 'W', 'F', 'C', 'N'])),
            'exclude': ','.join(config.get('exclude', [
                '.git', '__pycache__', 'build', 'dist', '.eggs', '*.egg'
            ])),
            'per-file-ignores': config.get('per_file_ignores', '__init__.py:F401'),
            'docstring-convention': config.get('docstring_convention', 'google'),
            'max-doc-length': str(config.get('max_doc_length', 100)),
        }
        
        if config.get('extend_ignore'):
            parser['flake8']['extend-ignore'] = ','.join(config['extend_ignore'])
        
        if config.get('extend_select'):
            parser['flake8']['extend-select'] = ','.join(config['extend_select'])
        
        with open(config_path, 'w') as f:
            parser.write(f)
        
        return config_path
    
    def generate_ruff_config(self, config: Dict[str, Any]) -> Path:
        """Generate ruff.toml configuration file."""
        config_path = self.project_root / "ruff.toml"
        
        ruff_config = {
            'target-version': config.get('target_version', 'py310'),
            'line-length': config.get('line_length', 100),
            'indent-width': config.get('indent_width', 4),
        }
        
        if config.get('exclude'):
            ruff_config['exclude'] = config['exclude']
        
        if config.get('select'):
            ruff_config['select'] = config['select']
        else:
            ruff_config['select'] = ['E', 'F', 'W', 'I', 'N', 'UP', 'B', 'C4', 'SIM']
        
        if config.get('ignore'):
            ruff_config['ignore'] = config['ignore']
        
        if config.get('extend_select'):
            ruff_config['extend-select'] = config['extend_select']
        
        ruff_config['lint'] = {
            'select': config.get('lint_select', ['E', 'F', 'W', 'I', 'N', 'UP', 'B', 'C4', 'SIM']),
            'ignore': config.get('lint_ignore', []),
            'per-file-ignores': config.get('per_file_ignores', {'__init__.py': ['F401']}),
        }
        
        ruff_config['lint.mccabe'] = {
            'max-complexity': config.get('max_complexity', 10),
        }
        
        ruff_config['lint.isort'] = {
            'known-first-party': config.get('known_first_party', []),
            'force-single-line': config.get('force_single_line', False),
        }
        
        ruff_config['format'] = {
            'quote-style': config.get('quote_style', 'double'),
            'indent-style': config.get('indent_style', 'space'),
            'docstring-code-format': config.get('docstring_code_format', True),
        }
        
        with open(config_path, 'wb') as f:
            tomli_w.dump(ruff_config, f)
        
        return config_path

    def generate_all_configs(self, tools_config: Dict[str, Dict[str, Any]]) -> Dict[str, Path]:
        """Generate configuration files for all specified tools."""
        generated = {}
        
        if 'mypy' in tools_config:
            generated['mypy'] = self.generate_mypy_config(tools_config['mypy'])
        
        if 'pylint' in tools_config:
            generated['pylint'] = self.generate_pylint_config(tools_config['pylint'])
        
        if 'flake8' in tools_config:
            generated['flake8'] = self.generate_flake8_config(tools_config['flake8'])
        
        if 'ruff' in tools_config:
            generated['ruff'] = self.generate_ruff_config(tools_config['ruff'])
        
        return generated
```

---

### Tool Execution and Output Parsing

```python
import re
import subprocess
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from typing import List, Dict, Any, Optional

class Severity(Enum):
    CRITICAL = "critical"
    ERROR = "error"
    WARNING = "warning"
    INFO = "info"
    CONVENTION = "convention"
    REFACTOR = "refactor"

@dataclass
class Issue:
    """Represents a single code quality issue."""
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
        return {
            "file": self.file,
            "line": self.line,
            "column": self.column,
            "severity": self.severity.value,
            "code": self.code,
            "message": self.message,
            "tool": self.tool,
            "end_line": self.end_line,
            "end_column": self.end_column,
            "fix_available": self.fix_available,
            "fix_suggestion": self.fix_suggestion,
        }

@dataclass
class ToolResult:
    """Result from running a code quality tool."""
    tool: str
    success: bool
    issues: List[Issue] = field(default_factory=list)
    error_message: Optional[str] = None
    execution_time: float = 0.0
    files_checked: int = 0
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "tool": self.tool,
            "success": self.success,
            "issues": [issue.to_dict() for issue in self.issues],
            "error_message": self.error_message,
            "execution_time": self.execution_time,
            "files_checked": self.files_checked,
        }

class ToolRunner:
    """Execute code quality tools and parse their output."""
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
    
    def run_mypy(self, paths: List[str], config: Optional[Dict[str, Any]] = None) -> ToolResult:
        """Run mypy type checker."""
        import time
        
        start_time = time.time()
        
        cmd = [sys.executable, "-m", "mypy"]
        cmd.extend(paths)
        cmd.extend([
            "--show-error-codes",
            "--show-column-numbers",
            "--show-error-context",
            "--no-error-summary",
        ])
        
        if config:
            if config.get('strict'):
                cmd.append("--strict")
            if config.get('ignore_missing_imports'):
                cmd.append("--ignore-missing-imports")
        
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                cwd=self.project_root,
                timeout=300
            )
            
            issues = self._parse_mypy_output(result.stdout + result.stderr)
            
            return ToolResult(
                tool="mypy",
                success=result.returncode == 0,
                issues=issues,
                execution_time=time.time() - start_time,
            )
        except subprocess.TimeoutExpired:
            return ToolResult(
                tool="mypy",
                success=False,
                error_message="Mypy execution timed out",
                execution_time=time.time() - start_time,
            )
        except Exception as e:
            return ToolResult(
                tool="mypy",
                success=False,
                error_message=str(e),
                execution_time=time.time() - start_time,
            )
    
    def _parse_mypy_output(self, output: str) -> List[Issue]:
        """Parse mypy output into structured issues."""
        issues = []
        
        pattern = r'^(.+?):(\d+):(\d+):\s+(error|warning|note):\s+(.+?)(?:\s+\[(.+?)\])?$'
        
        for line in output.split('\n'):
            match = re.match(pattern, line.strip())
            if match:
                file_path, line_num, column, severity_str, message, code = match.groups()
                
                severity_map = {
                    'error': Severity.ERROR,
                    'warning': Severity.WARNING,
                    'note': Severity.INFO,
                }
                
                issues.append(Issue(
                    file=file_path,
                    line=int(line_num),
                    column=int(column),
                    severity=severity_map.get(severity_str, Severity.WARNING),
                    code=code or 'mypy',
                    message=message,
                    tool='mypy',
                ))
        
        return issues
    
    def run_pylint(self, paths: List[str], config: Optional[Dict[str, Any]] = None) -> ToolResult:
        """Run pylint linter."""
        import time
        
        start_time = time.time()
        
        cmd = [sys.executable, "-m", "pylint"]
        cmd.extend(paths)
        cmd.extend([
            "--output-format=json",
            "--reports=n",
            "--score=n",
        ])
        
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                cwd=self.project_root,
                timeout=600
            )
            
            issues = self._parse_pylint_output(result.stdout)
            
            return ToolResult(
                tool="pylint",
                success=len(issues) == 0,
                issues=issues,
                execution_time=time.time() - start_time,
            )
        except subprocess.TimeoutExpired:
            return ToolResult(
                tool="pylint",
                success=False,
                error_message="Pylint execution timed out",
                execution_time=time.time() - start_time,
            )
        except Exception as e:
            return ToolResult(
                tool="pylint",
                success=False,
                error_message=str(e),
                execution_time=time.time() - start_time,
            )
    
    def _parse_pylint_output(self, output: str) -> List[Issue]:
        """Parse pylint JSON output into structured issues."""
        issues = []
        
        try:
            findings = json.loads(output) if output.strip() else []
        except json.JSONDecodeError:
            return issues
        
        severity_map = {
            'critical': Severity.CRITICAL,
            'error': Severity.ERROR,
            'warning': Severity.WARNING,
            'convention': Severity.CONVENTION,
            'refactor': Severity.REFACTOR,
            'info': Severity.INFO,
        }
        
        for finding in findings:
            issues.append(Issue(
                file=finding.get('path', ''),
                line=finding.get('line', 0),
                column=finding.get('column', 0),
                severity=severity_map.get(finding.get('type', 'warning'), Severity.WARNING),
                code=finding.get('symbol', finding.get('message-id', '')),
                message=finding.get('message', ''),
                tool='pylint',
                end_line=finding.get('endLine'),
                end_column=finding.get('endColumn'),
            ))
        
        return issues
    
    def run_flake8(self, paths: List[str], config: Optional[Dict[str, Any]] = None) -> ToolResult:
        """Run flake8 linter."""
        import time
        
        start_time = time.time()
        
        cmd = [sys.executable, "-m", "flake8"]
        cmd.extend(paths)
        cmd.extend([
            "--format=%(path)s:%(row)d:%(col)d: %(code)s %(text)s",
        ])
        
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                cwd=self.project_root,
                timeout=300
            )
            
            issues = self._parse_flake8_output(result.stdout + result.stderr)
            
            return ToolResult(
                tool="flake8",
                success=len(issues) == 0,
                issues=issues,
                execution_time=time.time() - start_time,
            )
        except subprocess.TimeoutExpired:
            return ToolResult(
                tool="flake8",
                success=False,
                error_message="Flake8 execution timed out",
                execution_time=time.time() - start_time,
            )
        except Exception as e:
            return ToolResult(
                tool="flake8",
                success=False,
                error_message=str(e),
                execution_time=time.time() - start_time,
            )
    
    def _parse_flake8_output(self, output: str) -> List[Issue]:
        """Parse flake8 output into structured issues."""
        issues = []
        
        pattern = r'^(.+?):(\d+):(\d+):\s+([A-Z]\d+)\s+(.+)$'
        
        for line in output.split('\n'):
            match = re.match(pattern, line.strip())
            if match:
                file_path, line_num, column, code, message = match.groups()
                
                severity = Severity.WARNING
                if code.startswith('E9') or code.startswith('F63'):
                    severity = Severity.ERROR
                elif code.startswith(('E', 'W')):
                    severity = Severity.WARNING
                elif code.startswith('F'):
                    severity = Severity.ERROR
                
                issues.append(Issue(
                    file=file_path,
                    line=int(line_num),
                    column=int(column),
                    severity=severity,
                    code=code,
                    message=message,
                    tool='flake8',
                ))
        
        return issues
    
    def run_ruff(self, paths: List[str], config: Optional[Dict[str, Any]] = None) -> ToolResult:
        """Run ruff linter."""
        import time
        
        start_time = time.time()
        
        cmd = [sys.executable, "-m", "ruff", "check"]
        cmd.extend(paths)
        cmd.extend([
            "--output-format=json",
        ])
        
        if config and config.get('fix'):
            cmd.append("--fix")
        
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                cwd=self.project_root,
                timeout=300
            )
            
            issues = self._parse_ruff_output(result.stdout)
            
            return ToolResult(
                tool="ruff",
                success=len(issues) == 0,
                issues=issues,
                execution_time=time.time() - start_time,
            )
        except subprocess.TimeoutExpired:
            return ToolResult(
                tool="ruff",
                success=False,
                error_message="Ruff execution timed out",
                execution_time=time.time() - start_time,
            )
        except Exception as e:
            return ToolResult(
                tool="ruff",
                success=False,
                error_message=str(e),
                execution_time=time.time() - start_time,
            )
    
    def _parse_ruff_output(self, output: str) -> List[Issue]:
        """Parse ruff JSON output into structured issues."""
        issues = []
        
        try:
            findings = json.loads(output) if output.strip() else []
        except json.JSONDecodeError:
            return issues
        
        severity_map = {
            'error': Severity.ERROR,
            'warning': Severity.WARNING,
            'info': Severity.INFO,
        }
        
        for finding in findings:
            issues.append(Issue(
                file=finding.get('filename', ''),
                line=finding.get('location', {}).get('row', 0),
                column=finding.get('location', {}).get('column', 0),
                severity=severity_map.get(finding.get('severity', 'warning'), Severity.WARNING),
                code=finding.get('code', ''),
                message=finding.get('message', ''),
                tool='ruff',
                end_line=finding.get('end_location', {}).get('row'),
                end_column=finding.get('end_location', {}).get('column'),
                fix_available=finding.get('fix') is not None,
            ))
        
        return issues

    def run_all_tools(self, paths: List[str], tools: List[str], 
                      configs: Optional[Dict[str, Dict[str, Any]]] = None) -> Dict[str, ToolResult]:
        """Run multiple tools and return combined results."""
        results = {}
        configs = configs or {}
        
        tool_runners = {
            'mypy': self.run_mypy,
            'pylint': self.run_pylint,
            'flake8': self.run_flake8,
            'ruff': self.run_ruff,
        }
        
        for tool in tools:
            if tool in tool_runners:
                results[tool] = tool_runners[tool](paths, configs.get(tool))
        
        return results
```

---

## Detailed Configuration Templates

### Mypy Configuration (Strict Type Checking)

```ini
[mypy]
python_version = 3.10

warn_return_any = True
warn_unused_configs = True
disallow_untyped_defs = True
disallow_incomplete_defs = True
check_untyped_defs = True
disallow_untyped_decorators = True
no_implicit_optional = True
warn_redundant_casts = True
warn_unused_ignores = True
warn_no_return = True
strict_optional = True
strict_equality = True
strict_concatenate = True

ignore_missing_imports = False
show_error_codes = True
show_column_numbers = True
show_error_context = True
pretty = True

exclude = (?x)(
    ^build/
    | ^dist/
    | ^venv/
    | ^.venv/
    | ^tests/fixtures/
    )

[mypy-tests.*]
disallow_untyped_defs = False

[mypy-third_party_module.*]
ignore_missing_imports = True
```

### Pylint Configuration (Custom Rules)

```ini
[MASTER]
jobs = 0
persistent = yes
load-plugins =
    pylint.extensions.docparams,
    pylint.extensions.mccabe

ignore = CVS,.git,.tox,dist,build,venv,.venv
ignore-patterns =

[MESSAGES CONTROL]
disable =
    C0114,
    C0115,
    C0116,
    R0903,
    W0212,

enable =
    E,
    F,
    W0611,
    W0612,

[REPORTS]
output-format = text
reports = no
score = no

[BASIC]
good-names = i,j,k,ex,Run,_,id,db
variable-rgx = [a-z_][a-z0-9_]{2,30}$
function-rgx = [a-z_][a-z0-9_]{2,30}$
class-rgx = [A-Z_][a-zA-Z0-9]+$
const-rgx = (([A-Z_][A-Z0-9_]*)|(__.*__))$

[FORMAT]
max-line-length = 100
max-module-lines = 1000
indent-string = '    '

[DESIGN]
max-args = 5
max-locals = 15
max-returns = 6
max-branches = 12
max-statements = 50
max-attributes = 7
min-public-methods = 2
max-public-methods = 20
max-ancestors = 7

[REFACTORING]
max-nested-blocks = 5

[SIMILARITIES]
min-similarity-lines = 4
ignore-comments = yes
ignore-docstrings = yes
ignore-imports = yes

[TYPECHECK]
ignored-modules =
ignored-classes =
```

### Flake8 Configuration (Complexity and Style)

```ini
[flake8]
max-line-length = 100
max-complexity = 10
max-doc-length = 100

ignore =
    E203,
    W503,
    E501,

select =
    E,
    W,
    F,
    C,
    N,
    B,
    T,

exclude =
    .git,
    __pycache__,
    build,
    dist,
    .eggs,
    *.egg,
    venv,
    .venv,

per-file-ignores =
    __init__.py: F401
    tests/*: S101

docstring-convention = google

extend-ignore =
extend-select =
    B9,
```

### Ruff Configuration (Fast Alternative)

```toml
target-version = "py310"
line-length = 100
indent-width = 4

exclude = [
    ".git",
    "__pycache__",
    "build",
    "dist",
    ".eggs",
    "*.egg",
    "venv",
    ".venv",
]

[lint]
select = [
    "E",      # pycodestyle errors
    "W",      # pycodestyle warnings
    "F",      # Pyflakes
    "I",      # isort
    "N",      # pep8-naming
    "UP",     # pyupgrade
    "B",      # flake8-bugbear
    "C4",     # flake8-comprehensions
    "SIM",    # flake8-simplify
    "TCH",    # flake8-type-checking
    "RUF",    # Ruff-specific rules
]

ignore = [
    "E501",   # line too long
    "B008",   # do not perform function calls in argument defaults
]

per-file-ignores = { "__init__.py" = ["F401"] }

[lint.mccabe]
max-complexity = 10

[lint.isort]
known-first-party = ["myproject"]
force-single-line = false

[lint.pycodestyle]
max-line-length = 100
max-doc-length = 100

[format]
quote-style = "double"
indent-style = "space"
docstring-code-format = true
```

---

## Tool Comparison and Selection Guide

### Performance Comparison

| Tool | 100 files | 1000 files | 5000 files |
|------|-----------|------------|------------|
| ruff | ~0.5s | ~3s | ~15s |
| flake8 | ~2s | ~15s | ~60s |
| mypy | ~5s | ~30s | ~120s |
| pylint | ~10s | ~60s | ~300s |

### Feature Comparison

| Feature | mypy | pylint | flake8 | ruff |
|---------|------|--------|--------|------|
| Type checking | ✅ | ❌ | ❌ | ❌ |
| Style checking | ❌ | ✅ | ✅ | ✅ |
| Complexity analysis | ❌ | ✅ | ✅ | ✅ |
| Security checks | ❌ | ✅ | ✅ (ext) | ✅ |
| Auto-fix | ❌ | ❌ | ❌ | ✅ |
| Custom plugins | ✅ | ✅ | ✅ | ✅ |
| Incremental mode | ✅ | ❌ | ❌ | ✅ |

### Selection Recommendations

**Choose mypy when:**
- Project uses type annotations
- Need strict type safety
- Working with complex type hierarchies

**Choose pylint when:**
- Need comprehensive code analysis
- Want custom rule development
- Working on legacy codebases

**Choose flake8 when:**
- Need fast, simple linting
- Want PEP 8 compliance
- Using existing flake8 plugins

**Choose ruff when:**
- Speed is critical (CI/CD)
- Want all-in-one solution
- Need auto-fix capabilities
- Modern Python project

### Recommended Tool Combinations

1. **Modern Project (Fast)**
   ```
   ruff + mypy
   ```

2. **Comprehensive Analysis**
   ```
   ruff + mypy + pylint (weekly)
   ```

3. **Legacy Project**
   ```
   flake8 + pylint + mypy (gradual)
   ```

4. **Strict Type Safety**
   ```
   mypy (strict) + ruff
   ```

---

## CI/CD Pipeline Integration

### GitHub Actions

```yaml
name: Python Quality Check

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  quality-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.10'
          cache: 'pip'
      
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install mypy pylint flake8 ruff
          pip install -r requirements.txt
      
      - name: Run Ruff
        run: ruff check --output-format=github .
      
      - name: Run Mypy
        run: mypy --ignore-missing-imports src/
      
      - name: Run Pylint
        run: pylint --output-format=github src/
        continue-on-error: true
      
      - name: Run Flake8
        run: flake8 src/
```

### GitLab CI

```yaml
python-quality:
  image: python:3.10
  stage: test
  before_script:
    - pip install mypy pylint flake8 ruff
    - pip install -r requirements.txt
  script:
    - ruff check --output-format=gitlab .
    - mypy src/
    - pylint --exit-zero src/
    - flake8 src/
  artifacts:
    reports:
      codequality: gl-code-quality-report.json
```

### Pre-commit Hooks

```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.2.0
    hooks:
      - id: ruff
        args: [--fix, --exit-non-zero-on-fix]
      - id: ruff-format

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.8.0
    hooks:
      - id: mypy
        additional_dependencies: [types-all]
        args: [--ignore-missing-imports]

  - repo: https://github.com/pycqa/flake8
    rev: 7.0.0
    hooks:
      - id: flake8
        additional_dependencies:
          - flake8-bugbear
          - flake8-comprehensions

  - repo: https://github.com/pycqa/pylint
    rev: v3.0.0
    hooks:
      - id: pylint
        args: [--exit-zero]
```

### Jenkins Pipeline

```groovy
pipeline {
    agent any
    
    stages {
        stage('Setup') {
            steps {
                sh 'python -m pip install --upgrade pip'
                sh 'pip install mypy pylint flake8 ruff'
                sh 'pip install -r requirements.txt'
            }
        }
        
        stage('Ruff') {
            steps {
                sh 'ruff check --output-format=json . > ruff-report.json || true'
            }
        }
        
        stage('Mypy') {
            steps {
                sh 'mypy src/ --no-error-summary || true'
            }
        }
        
        stage('Pylint') {
            steps {
                sh 'pylint --output-format=json src/ > pylint-report.json || true'
            }
        }
        
        stage('Flake8') {
            steps {
                sh 'flake8 src/ || true'
            }
        }
    }
    
    post {
        always {
            archiveArtifacts artifacts: '*-report.json', fingerprint: true
        }
    }
}
```

---

## Troubleshooting Common Issues

### Issue 1: Import Errors in Type Checking

**Problem:** Mypy reports "Cannot find implementation or library stub for module"

**Solutions:**
```ini
[mypy]
ignore_missing_imports = True

[mypy-specific_module.*]
ignore_missing_imports = False
```

Or install type stubs:
```bash
pip install types-requests types-python-dateutil
```

### Issue 2: Pylint False Positives

**Problem:** Pylint reports issues that are not actual problems

**Solutions:**

1. Inline disable:
```python
# pylint: disable=too-many-arguments
def complex_function(a, b, c, d, e, f):
    pass
```

2. Configuration disable:
```ini
[MESSAGES CONTROL]
disable = too-many-arguments,too-many-locals
```

3. Use type hints:
```python
def function(arg: int) -> str:  # pylint: disable=unused-argument
    return "result"
```

### Issue 3: Flake8 Line Length Conflicts

**Problem:** Flake8 E501 conflicts with black formatting

**Solutions:**
```ini
[flake8]
max-line-length = 88
extend-ignore = E203, W503
```

### Issue 4: Ruff Configuration Migration

**Problem:** Migrating from flake8/pylint to ruff

**Solutions:**
```bash
ruff check --select ALL --show-files
ruff rule E501
```

Configuration mapping:
```toml
[lint]
select = ["E", "F", "W"]  # flake8 equivalent
ignore = ["E501"]

[lint.pylint]
max-args = 5  # pylint max-args equivalent
```

### Issue 5: Version Compatibility

**Problem:** Different tool versions across environments

**Solutions:**

1. Pin versions in requirements.txt:
```
mypy==1.8.0
pylint==3.0.0
flake8==7.0.0
ruff==0.2.0
```

2. Use pre-commit for consistency:
```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.2.0
```

### Issue 6: Memory Issues with Large Projects

**Problem:** Tools run out of memory on large codebases

**Solutions:**

1. For mypy:
```bash
mypy --no-incremental --cache-dir=/tmp/mypy_cache
```

2. For pylint:
```ini
[MASTER]
jobs = 4
limit-inference-results = 100
```

3. For ruff:
```bash
ruff check --cache --force-exclude
```

### Issue 7: CI/CD Timeout

**Problem:** Quality checks timeout in CI

**Solutions:**

1. Use incremental checking:
```yaml
- name: Mypy Cache
  uses: actions/cache@v3
  with:
    path: .mypy_cache
    key: mypy-${{ hashFiles('**/*.py') }}
```

2. Run only on changed files:
```bash
git diff --name-only HEAD~1 | grep '\.py$' | xargs ruff check
```

3. Split checks across jobs:
```yaml
jobs:
  ruff:
    runs-on: ubuntu-latest
    steps:
      - run: ruff check .
  
  mypy:
    runs-on: ubuntu-latest
    steps:
      - run: mypy src/
```

### Issue 8: Configuration File Not Found

**Problem:** Tools don't find configuration files

**Solutions:**

1. Specify config location:
```bash
mypy --config-file=pyproject.toml
pylint --rcfile=.pylintrc
flake8 --config=.flake8
ruff check --config=ruff.toml
```

2. Use pyproject.toml for all tools:
```toml
[tool.mypy]
python_version = "3.10"

[tool.pylint.messages_control]
disable = ["C0114"]

[tool.ruff]
line-length = 100
```

---

## Best Practices Summary

1. **Start Simple**: Begin with ruff for fast feedback, add mypy for type safety
2. **Pin Versions**: Lock tool versions in requirements for consistency
3. **Use Pre-commit**: Automate checks before commits
4. **Configure Gradually**: Start with default rules, customize as needed
5. **Cache Results**: Enable caching in CI for faster runs
6. **Document Exceptions**: Add comments when disabling rules
7. **Regular Updates**: Keep tools updated for latest rules and fixes
8. **Monitor Performance**: Track execution time and optimize as needed
