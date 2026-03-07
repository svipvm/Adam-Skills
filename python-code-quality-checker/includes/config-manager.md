# Configuration Management Module

## Overview

This module provides comprehensive configuration management capabilities for the Python Code Quality Checker. It handles multiple configuration sources, merging strategies, validation, and versioning to ensure flexible and maintainable quality check settings across different project environments.

### Key Capabilities

- **Multi-source Configuration**: Support for YAML, TOML, INI, and JSON configuration files
- **Layered Configuration**: Merge configurations from multiple sources with clear precedence
- **Environment Variables**: Override settings via environment variables
- **Command-line Overrides**: Runtime configuration through CLI arguments
- **Ignore Rules**: Flexible pattern-based ignore configurations
- **Strictness Levels**: Predefined and custom strictness profiles
- **Schema Validation**: Type-safe configuration with detailed error messages
- **Migration Support**: Automatic configuration version upgrades

---

## Implementation Guide

### Configuration File Parsing

#### YAML Configuration Parser

```python
from pathlib import Path
from typing import Dict, Any, Optional, List
import yaml
from dataclasses import dataclass, field

@dataclass
class ParseResult:
    success: bool
    config: Dict[str, Any] = field(default_factory=dict)
    errors: List[str] = field(default_factory=list)
    warnings: List[str] = field(default_factory=list)
    source: str = ""

class YAMLConfigParser:
    """Parse YAML configuration files for Python quality checker."""
    
    SUPPORTED_FILES = ['.python-quality-checker.yaml', '.python-quality-checker.yml']
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
    
    def find_config_file(self) -> Optional[Path]:
        """Locate the configuration file in the project root."""
        for filename in self.SUPPORTED_FILES:
            config_path = self.project_root / filename
            if config_path.exists():
                return config_path
        return None
    
    def parse(self, config_path: Optional[Path] = None) -> ParseResult:
        """Parse the YAML configuration file."""
        if config_path is None:
            config_path = self.find_config_file()
        
        if config_path is None:
            return ParseResult(
                success=False,
                errors=["No configuration file found"],
                source="yaml"
            )
        
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                content = yaml.safe_load(f)
            
            if content is None:
                content = {}
            
            return ParseResult(
                success=True,
                config=content,
                source=str(config_path)
            )
        except yaml.YAMLError as e:
            return ParseResult(
                success=False,
                errors=[f"YAML parsing error: {str(e)}"],
                source=str(config_path)
            )
        except Exception as e:
            return ParseResult(
                success=False,
                errors=[f"Failed to read config file: {str(e)}"],
                source=str(config_path)
            )
    
    def parse_with_includes(self, config_path: Optional[Path] = None) -> ParseResult:
        """Parse configuration with support for include directives."""
        result = self.parse(config_path)
        
        if not result.success:
            return result
        
        config = result.config.copy()
        includes = config.pop('include', [])
        
        for include_path in includes:
            include_file = self.project_root / include_path
            include_result = self.parse(include_file)
            
            if include_result.success:
                config = self._deep_merge(config, include_result.config)
            else:
                result.warnings.append(
                    f"Failed to include {include_path}: {include_result.errors}"
                )
        
        return ParseResult(
            success=True,
            config=config,
            warnings=result.warnings,
            source=result.source
        )
    
    def _deep_merge(self, base: Dict[str, Any], override: Dict[str, Any]) -> Dict[str, Any]:
        """Deep merge two configuration dictionaries."""
        result = base.copy()
        
        for key, value in override.items():
            if key in result and isinstance(result[key], dict) and isinstance(value, dict):
                result[key] = self._deep_merge(result[key], value)
            else:
                result[key] = value
        
        return result
```

#### TOML Configuration Parser

```python
import tomllib
from typing import Dict, Any, Optional

class TOMLConfigParser:
    """Parse TOML configuration files (pyproject.toml)."""
    
    SUPPORTED_FILES = ['pyproject.toml']
    CONFIG_SECTION = 'tool.python-quality-checker'
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
    
    def find_config_file(self) -> Optional[Path]:
        """Locate pyproject.toml in the project root."""
        for filename in self.SUPPORTED_FILES:
            config_path = self.project_root / filename
            if config_path.exists():
                return config_path
        return None
    
    def parse(self, config_path: Optional[Path] = None) -> ParseResult:
        """Parse the TOML configuration file."""
        if config_path is None:
            config_path = self.find_config_file()
        
        if config_path is None:
            return ParseResult(
                success=False,
                errors=["No pyproject.toml found"],
                source="toml"
            )
        
        try:
            with open(config_path, 'rb') as f:
                content = tomllib.load(f)
            
            config = content.get('tool', {}).get('python-quality-checker', {})
            
            return ParseResult(
                success=True,
                config=config,
                source=str(config_path)
            )
        except tomllib.TOMLDecodeError as e:
            return ParseResult(
                success=False,
                errors=[f"TOML parsing error: {str(e)}"],
                source=str(config_path)
            )
        except Exception as e:
            return ParseResult(
                success=False,
                errors=[f"Failed to read config file: {str(e)}"],
                source=str(config_path)
            )
    
    def parse_tool_sections(self, config_path: Optional[Path] = None) -> Dict[str, Dict[str, Any]]:
        """Parse all tool-specific sections from pyproject.toml."""
        if config_path is None:
            config_path = self.find_config_file()
        
        if config_path is None:
            return {}
        
        try:
            with open(config_path, 'rb') as f:
                content = tomllib.load(f)
            
            tool_configs = {}
            tools = content.get('tool', {})
            
            for tool_name in ['mypy', 'pylint', 'ruff', 'flake8', 'black', 'isort']:
                if tool_name in tools:
                    tool_configs[tool_name] = tools[tool_name]
            
            return tool_configs
        except Exception:
            return {}
```

---

### Command-line Argument Override

```python
import argparse
from typing import Dict, Any, List, Optional

class CLIConfigOverride:
    """Handle command-line argument configuration overrides."""
    
    def __init__(self):
        self.parser = self._create_parser()
        self.args: Optional[argparse.Namespace] = None
    
    def _create_parser(self) -> argparse.ArgumentParser:
        """Create the argument parser for quality checker options."""
        parser = argparse.ArgumentParser(
            description='Python Code Quality Checker',
            add_help=False
        )
        
        parser.add_argument(
            '--config', '-c',
            type=str,
            help='Path to configuration file'
        )
        
        parser.add_argument(
            '--strictness', '-s',
            choices=['relaxed', 'normal', 'strict', 'very-strict'],
            help='Strictness level for quality checks'
        )
        
        parser.add_argument(
            '--linters',
            type=str,
            help='Comma-separated list of linters to run'
        )
        
        parser.add_argument(
            '--type-checker',
            choices=['mypy', 'pyright', 'none'],
            help='Type checker to use'
        )
        
        parser.add_argument(
            '--formatters',
            type=str,
            help='Comma-separated list of formatters to use'
        )
        
        parser.add_argument(
            '--max-line-length',
            type=int,
            help='Maximum line length'
        )
        
        parser.add_argument(
            '--max-complexity',
            type=int,
            help='Maximum cyclomatic complexity'
        )
        
        parser.add_argument(
            '--exclude',
            type=str,
            action='append',
            help='Patterns to exclude (can be used multiple times)'
        )
        
        parser.add_argument(
            '--ignore',
            type=str,
            action='append',
            help='Error codes to ignore (can be used multiple times)'
        )
        
        parser.add_argument(
            '--auto-fix',
            action='store_true',
            help='Automatically fix issues where possible'
        )
        
        parser.add_argument(
            '--no-auto-fix',
            action='store_true',
            help='Disable auto-fixing'
        )
        
        parser.add_argument(
            '--fail-on',
            choices=['error', 'warning', 'info'],
            help='Fail on issues of this severity or higher'
        )
        
        parser.add_argument(
            '--output-format',
            choices=['text', 'json', 'junit', 'github'],
            help='Output format for results'
        )
        
        parser.add_argument(
            '--parallel',
            type=int,
            help='Number of parallel processes'
        )
        
        parser.add_argument(
            '--cache/--no-cache',
            default=True,
            help='Enable/disable caching'
        )
        
        parser.add_argument(
            'paths',
            nargs='*',
            help='Paths to check'
        )
        
        return parser
    
    def parse_args(self, args: Optional[List[str]] = None) -> argparse.Namespace:
        """Parse command-line arguments."""
        self.args = self.parser.parse_args(args)
        return self.args
    
    def to_config_dict(self) -> Dict[str, Any]:
        """Convert parsed arguments to configuration dictionary."""
        if self.args is None:
            return {}
        
        config: Dict[str, Any] = {}
        
        if self.args.config:
            config['config_file'] = self.args.config
        
        if self.args.strictness:
            config['strictness'] = self.args.strictness
        
        if self.args.linters:
            config['linters'] = [l.strip() for l in self.args.linters.split(',')]
        
        if self.args.type_checker:
            config['type_checker'] = self.args.type_checker
        
        if self.args.formatters:
            config['formatters'] = [f.strip() for f in self.args.formatters.split(',')]
        
        if self.args.max_line_length:
            config['rules'] = config.get('rules', {})
            config['rules']['max_line_length'] = self.args.max_line_length
        
        if self.args.max_complexity:
            config['rules'] = config.get('rules', {})
            config['rules']['max_complexity'] = self.args.max_complexity
        
        if self.args.exclude:
            config['exclude'] = self.args.exclude
        
        if self.args.ignore:
            config['ignore'] = self.args.ignore
        
        if self.args.auto_fix:
            config['auto_fix'] = True
        elif self.args.no_auto_fix:
            config['auto_fix'] = False
        
        if self.args.fail_on:
            config['severity_threshold'] = self.args.fail_on
        
        if self.args.output_format:
            config['output_format'] = self.args.output_format
        
        if self.args.parallel:
            config['parallel'] = self.args.parallel
        
        if not self.args.cache:
            config['cache'] = False
        
        if self.args.paths:
            config['paths'] = self.args.paths
        
        return config
    
    def apply_overrides(self, base_config: Dict[str, Any]) -> Dict[str, Any]:
        """Apply CLI overrides to base configuration."""
        cli_config = self.to_config_dict()
        return self._merge_configs(base_config, cli_config, override=True)
    
    def _merge_configs(self, base: Dict[str, Any], override: Dict[str, Any], 
                       override: bool = True) -> Dict[str, Any]:
        """Merge configurations with optional override behavior."""
        result = base.copy()
        
        for key, value in override.items():
            if value is None:
                continue
            
            if key in result and isinstance(result[key], dict) and isinstance(value, dict):
                result[key] = self._merge_configs(result[key], value, override)
            elif override or key not in result:
                result[key] = value
        
        return result
```

---

### Environment Variable Configuration

```python
import os
from typing import Dict, Any, Optional

class EnvironmentConfigLoader:
    """Load configuration from environment variables."""
    
    ENV_PREFIX = 'PYTHON_QUALITY_'
    ENV_MAPPING = {
        'PYTHON_QUALITY_STRICTNESS': 'strictness',
        'PYTHON_QUALITY_LINTERS': 'linters',
        'PYTHON_QUALITY_TYPE_CHECKER': 'type_checker',
        'PYTHON_QUALITY_FORMATTERS': 'formatters',
        'PYTHON_QUALITY_MAX_LINE_LENGTH': 'rules.max_line_length',
        'PYTHON_QUALITY_MAX_COMPLEXITY': 'rules.max_complexity',
        'PYTHON_QUALITY_EXCLUDE': 'exclude',
        'PYTHON_QUALITY_IGNORE': 'ignore',
        'PYTHON_QUALITY_AUTO_FIX': 'auto_fix',
        'PYTHON_QUALITY_FAIL_ON': 'severity_threshold',
        'PYTHON_QUALITY_OUTPUT_FORMAT': 'output_format',
        'PYTHON_QUALITY_PARALLEL': 'parallel',
        'PYTHON_QUALITY_CACHE': 'cache',
        'PYTHON_QUALITY_CONFIG_FILE': 'config_file',
    }
    
    BOOL_TRUE_VALUES = {'true', '1', 'yes', 'on', 'enabled'}
    BOOL_FALSE_VALUES = {'false', '0', 'no', 'off', 'disabled'}
    
    def load(self) -> Dict[str, Any]:
        """Load configuration from environment variables."""
        config: Dict[str, Any] = {}
        
        for env_key, config_path in self.ENV_MAPPING.items():
            value = os.environ.get(env_key)
            if value is not None:
                self._set_nested_value(config, config_path, value)
        
        return config
    
    def _set_nested_value(self, config: Dict[str, Any], path: str, value: str) -> None:
        """Set a value in a nested dictionary using dot notation path."""
        keys = path.split('.')
        current = config
        
        for key in keys[:-1]:
            if key not in current:
                current[key] = {}
            current = current[key]
        
        final_key = keys[-1]
        current[final_key] = self._parse_value(final_key, value)
    
    def _parse_value(self, key: str, value: str) -> Any:
        """Parse environment variable value to appropriate type."""
        if key in ('auto_fix', 'cache'):
            return value.lower() in self.BOOL_TRUE_VALUES
        
        if key in ('max_line_length', 'max_complexity', 'parallel'):
            try:
                return int(value)
            except ValueError:
                return value
        
        if key in ('linters', 'formatters', 'exclude', 'ignore'):
            return [v.strip() for v in value.split(',')]
        
        return value
    
    def get_tool_config(self, tool_name: str) -> Dict[str, Any]:
        """Get tool-specific configuration from environment."""
        prefix = f'{self.ENV_PREFIX}{tool_name.upper()}_'
        config: Dict[str, Any] = {}
        
        for env_key, value in os.environ.items():
            if env_key.startswith(prefix):
                config_key = env_key[len(prefix):].lower()
                config[config_key] = self._parse_value(config_key, value)
        
        return config
    
    def apply_to_config(self, base_config: Dict[str, Any]) -> Dict[str, Any]:
        """Apply environment configuration to base configuration."""
        env_config = self.load()
        return self._deep_merge(base_config, env_config)
    
    def _deep_merge(self, base: Dict[str, Any], override: Dict[str, Any]) -> Dict[str, Any]:
        """Deep merge two configuration dictionaries."""
        result = base.copy()
        
        for key, value in override.items():
            if key in result and isinstance(result[key], dict) and isinstance(value, dict):
                result[key] = self._deep_merge(result[key], value)
            else:
                result[key] = value
        
        return result
```

---

### Ignore Rules Configuration

```python
import re
import fnmatch
from dataclasses import dataclass, field
from typing import Dict, Any, List, Optional, Set, Pattern
from pathlib import Path

@dataclass
class IgnoreRule:
    """Represents a single ignore rule."""
    pattern: str
    codes: Set[str] = field(default_factory=set)
    files: Set[str] = field(default_factory=set)
    reason: Optional[str] = None
    expires: Optional[str] = None
    is_regex: bool = False
    
    def matches_file(self, file_path: str) -> bool:
        """Check if this rule matches a file path."""
        if self.files:
            return file_path in self.files
        
        if self.is_regex:
            return bool(re.match(self.pattern, file_path))
        
        return fnmatch.fnmatch(file_path, self.pattern)
    
    def matches_code(self, code: str) -> bool:
        """Check if this rule matches an error code."""
        if not self.codes:
            return True
        return code in self.codes
    
    def is_expired(self) -> bool:
        """Check if this temporary ignore rule has expired."""
        if not self.expires:
            return False
        
        from datetime import datetime
        try:
            expiry_date = datetime.strptime(self.expires, '%Y-%m-%d')
            return datetime.now() > expiry_date
        except ValueError:
            return False

class IgnoreRulesManager:
    """Manage ignore rules for code quality checks."""
    
    def __init__(self):
        self.rules: List[IgnoreRule] = []
        self.file_cache: Dict[str, List[IgnoreRule]] = {}
    
    def load_from_config(self, config: Dict[str, Any]) -> None:
        """Load ignore rules from configuration."""
        self.rules = []
        
        ignore_patterns = config.get('ignore', [])
        for pattern in ignore_patterns:
            if isinstance(pattern, str):
                self.rules.append(IgnoreRule(pattern=pattern))
            elif isinstance(pattern, dict):
                self.rules.append(IgnoreRule(
                    pattern=pattern.get('pattern', ''),
                    codes=set(pattern.get('codes', [])),
                    files=set(pattern.get('files', [])),
                    reason=pattern.get('reason'),
                    expires=pattern.get('expires'),
                    is_regex=pattern.get('regex', False)
                ))
        
        per_file_ignores = config.get('per_file_ignores', {})
        for file_pattern, codes in per_file_ignores.items():
            if isinstance(codes, str):
                codes = [codes]
            self.rules.append(IgnoreRule(
                pattern=file_pattern,
                codes=set(codes)
            ))
        
        self.file_cache.clear()
    
    def should_ignore(self, file_path: str, code: str) -> bool:
        """Check if a file/code combination should be ignored."""
        for rule in self.rules:
            if rule.is_expired():
                continue
            if rule.matches_file(file_path) and rule.matches_code(code):
                return True
        return False
    
    def get_ignored_codes_for_file(self, file_path: str) -> Set[str]:
        """Get all ignored codes for a specific file."""
        ignored_codes: Set[str] = set()
        
        for rule in self.rules:
            if rule.is_expired():
                continue
            if rule.matches_file(file_path):
                ignored_codes.update(rule.codes)
        
        return ignored_codes
    
    def add_inline_ignore(self, file_path: str, line: int, code: str, 
                          reason: Optional[str] = None) -> None:
        """Add an inline ignore from source code comment."""
        pass
    
    def get_ignore_reason(self, file_path: str, code: str) -> Optional[str]:
        """Get the reason for ignoring a file/code combination."""
        for rule in self.rules:
            if rule.is_expired():
                continue
            if rule.matches_file(file_path) and rule.matches_code(code):
                return rule.reason
        return None
    
    def validate_rules(self) -> List[str]:
        """Validate all ignore rules and return any errors."""
        errors = []
        
        for i, rule in enumerate(self.rules):
            if rule.is_regex:
                try:
                    re.compile(rule.pattern)
                except re.error as e:
                    errors.append(f"Rule {i}: Invalid regex pattern '{rule.pattern}': {e}")
            
            if rule.expires:
                try:
                    from datetime import datetime
                    datetime.strptime(rule.expires, '%Y-%m-%d')
                except ValueError:
                    errors.append(f"Rule {i}: Invalid expiry date format '{rule.expires}'")
        
        return errors
    
    def to_config_dict(self) -> Dict[str, Any]:
        """Export ignore rules to configuration dictionary."""
        ignore_list = []
        per_file_ignores: Dict[str, List[str]] = {}
        
        for rule in self.rules:
            if rule.codes and rule.files:
                ignore_list.append({
                    'pattern': rule.pattern,
                    'codes': list(rule.codes),
                    'files': list(rule.files),
                    'reason': rule.reason,
                    'expires': rule.expires,
                    'regex': rule.is_regex
                })
            elif rule.codes:
                per_file_ignores[rule.pattern] = list(rule.codes)
            else:
                ignore_list.append(rule.pattern)
        
        config: Dict[str, Any] = {}
        if ignore_list:
            config['ignore'] = ignore_list
        if per_file_ignores:
            config['per_file_ignores'] = per_file_ignores
        
        return config
```

---

### Strictness Level Configuration

```python
from enum import Enum
from typing import Dict, Any, Optional

class StrictnessLevel(Enum):
    """Predefined strictness levels for quality checks."""
    RELAXED = 'relaxed'
    NORMAL = 'normal'
    STRICT = 'strict'
    VERY_STRICT = 'very-strict'

class StrictnessConfigManager:
    """Manage strictness level configurations."""
    
    STRICTNESS_PROFILES: Dict[StrictnessLevel, Dict[str, Any]] = {
        StrictnessLevel.RELAXED: {
            'rules': {
                'max_line_length': 120,
                'max_complexity': 15,
                'max_function_length': 100,
                'max_class_length': 500,
                'max_arguments': 8,
            },
            'mypy': {
                'strict': False,
                'disallow_untyped_defs': False,
                'disallow_incomplete_defs': False,
                'check_untyped_defs': False,
                'ignore_missing_imports': True,
            },
            'pylint': {
                'disable': [
                    'C0114', 'C0115', 'C0116',
                    'R0903', 'R0913', 'R0914',
                    'W0212', 'W0612',
                ],
            },
            'ruff': {
                'select': ['E', 'F'],
                'ignore': ['E501', 'E731'],
            },
            'flake8': {
                'max_complexity': 15,
                'ignore': ['E501', 'W503', 'E203'],
            },
            'auto_fix': True,
            'fail_threshold': 'error',
        },
        
        StrictnessLevel.NORMAL: {
            'rules': {
                'max_line_length': 100,
                'max_complexity': 10,
                'max_function_length': 50,
                'max_class_length': 300,
                'max_arguments': 5,
            },
            'mypy': {
                'strict': False,
                'disallow_untyped_defs': False,
                'disallow_incomplete_defs': True,
                'check_untyped_defs': True,
                'ignore_missing_imports': True,
            },
            'pylint': {
                'disable': [
                    'C0114', 'C0115', 'C0116',
                ],
            },
            'ruff': {
                'select': ['E', 'F', 'W', 'I', 'N', 'UP', 'B'],
                'ignore': ['E501'],
            },
            'flake8': {
                'max_complexity': 10,
                'ignore': ['W503', 'E203'],
            },
            'auto_fix': True,
            'fail_threshold': 'warning',
        },
        
        StrictnessLevel.STRICT: {
            'rules': {
                'max_line_length': 88,
                'max_complexity': 8,
                'max_function_length': 40,
                'max_class_length': 200,
                'max_arguments': 4,
            },
            'mypy': {
                'strict': True,
                'disallow_untyped_defs': True,
                'disallow_incomplete_defs': True,
                'check_untyped_defs': True,
                'ignore_missing_imports': False,
            },
            'pylint': {
                'disable': [],
                'enable': ['E', 'F', 'W', 'R'],
            },
            'ruff': {
                'select': ['E', 'F', 'W', 'I', 'N', 'UP', 'B', 'C4', 'SIM', 'TCH'],
                'ignore': [],
            },
            'flake8': {
                'max_complexity': 8,
                'ignore': [],
            },
            'auto_fix': False,
            'fail_threshold': 'warning',
        },
        
        StrictnessLevel.VERY_STRICT: {
            'rules': {
                'max_line_length': 88,
                'max_complexity': 5,
                'max_function_length': 30,
                'max_class_length': 150,
                'max_arguments': 3,
            },
            'mypy': {
                'strict': True,
                'disallow_untyped_defs': True,
                'disallow_incomplete_defs': True,
                'check_untyped_defs': True,
                'ignore_missing_imports': False,
                'warn_return_any': True,
                'warn_unused_ignores': True,
                'strict_optional': True,
                'strict_equality': True,
            },
            'pylint': {
                'disable': [],
                'enable': ['E', 'F', 'W', 'R', 'C'],
            },
            'ruff': {
                'select': ['ALL'],
                'ignore': ['D100', 'D104'],
            },
            'flake8': {
                'max_complexity': 5,
                'ignore': [],
            },
            'auto_fix': False,
            'fail_threshold': 'info',
        },
    }
    
    def __init__(self, default_level: StrictnessLevel = StrictnessLevel.NORMAL):
        self.current_level = default_level
    
    def get_config(self, level: Optional[StrictnessLevel] = None) -> Dict[str, Any]:
        """Get configuration for a strictness level."""
        level = level or self.current_level
        return self.STRICTNESS_PROFILES[level].copy()
    
    def set_level(self, level: StrictnessLevel) -> None:
        """Set the current strictness level."""
        self.current_level = level
    
    def apply_to_config(self, base_config: Dict[str, Any], 
                        level: Optional[StrictnessLevel] = None) -> Dict[str, Any]:
        """Apply strictness settings to base configuration."""
        strictness_config = self.get_config(level)
        return self._deep_merge(strictness_config, base_config)
    
    def _deep_merge(self, base: Dict[str, Any], override: Dict[str, Any]) -> Dict[str, Any]:
        """Deep merge with override taking precedence."""
        result = base.copy()
        
        for key, value in override.items():
            if key in result and isinstance(result[key], dict) and isinstance(value, dict):
                result[key] = self._deep_merge(result[key], value)
            else:
                result[key] = value
        
        return result
    
    def create_custom_profile(self, name: str, base_level: StrictnessLevel,
                              overrides: Dict[str, Any]) -> Dict[str, Any]:
        """Create a custom strictness profile based on an existing level."""
        base_config = self.get_config(base_level)
        return self._deep_merge(base_config, overrides)
    
    def get_level_description(self, level: StrictnessLevel) -> str:
        """Get a description of a strictness level."""
        descriptions = {
            StrictnessLevel.RELAXED: (
                "Relaxed checking - suitable for prototypes, scripts, and learning projects. "
                "Minimal enforcement with higher thresholds for complexity and line length."
            ),
            StrictnessLevel.NORMAL: (
                "Normal checking - balanced approach for most production projects. "
                "Reasonable thresholds with essential checks enabled."
            ),
            StrictnessLevel.STRICT: (
                "Strict checking - for mature projects requiring high code quality. "
                "Lower thresholds, comprehensive type checking, and minimal rule exclusions."
            ),
            StrictnessLevel.VERY_STRICT: (
                "Very strict checking - for critical systems and libraries. "
                "Maximum enforcement with all rules enabled and very low thresholds."
            ),
        }
        return descriptions.get(level, "")
```

---

## Configuration Schema Definition

### Complete Configuration Schema

```python
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Any, Union
from enum import Enum

class OutputFormat(Enum):
    TEXT = 'text'
    JSON = 'json'
    JUNIT = 'junit'
    GITHUB = 'github'
    SARIF = 'sarif'

class FailThreshold(Enum):
    ERROR = 'error'
    WARNING = 'warning'
    INFO = 'info'
    NEVER = 'never'

@dataclass
class RulesConfig:
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

@dataclass
class MypyConfig:
    strict: bool = False
    python_version: str = '3.10'
    disallow_untyped_defs: bool = True
    disallow_incomplete_defs: bool = True
    check_untyped_defs: bool = True
    ignore_missing_imports: bool = True
    warn_return_any: bool = False
    warn_unused_ignores: bool = False
    strict_optional: bool = True
    show_error_codes: bool = True
    show_column_numbers: bool = True
    plugins: List[str] = field(default_factory=list)
    exclude: List[str] = field(default_factory=list)
    overrides: Dict[str, Dict[str, Any]] = field(default_factory=dict)

@dataclass
class PylintConfig:
    disable: List[str] = field(default_factory=lambda: ['C0114', 'C0115', 'C0116'])
    enable: List[str] = field(default_factory=list)
    load_plugins: List[str] = field(default_factory=list)
    good_names: List[str] = field(default_factory=lambda: ['i', 'j', 'k', 'ex', 'Run', '_'])
    max_line_length: int = 100
    max_complexity: int = 10
    jobs: int = 0
    ignore: List[str] = field(default_factory=list)
    ignore_patterns: List[str] = field(default_factory=list)

@dataclass
class RuffConfig:
    select: List[str] = field(default_factory=lambda: ['E', 'F', 'W', 'I', 'N', 'UP', 'B'])
    ignore: List[str] = field(default_factory=list)
    extend_select: List[str] = field(default_factory=list)
    line_length: int = 100
    target_version: str = 'py310'
    exclude: List[str] = field(default_factory=list)
    per_file_ignores: Dict[str, List[str]] = field(default_factory=dict)
    fix: bool = False

@dataclass
class Flake8Config:
    max_line_length: int = 100
    max_complexity: int = 10
    max_doc_length: int = 100
    ignore: List[str] = field(default_factory=lambda: ['W503', 'E203'])
    select: List[str] = field(default_factory=lambda: ['E', 'W', 'F', 'C', 'N'])
    extend_ignore: List[str] = field(default_factory=list)
    extend_select: List[str] = field(default_factory=list)
    exclude: List[str] = field(default_factory=list)
    per_file_ignores: Dict[str, str] = field(default_factory=dict)

@dataclass
class BlackConfig:
    line_length: int = 88
    target_version: List[str] = field(default_factory=lambda: ['py39', 'py310'])
    skip_string_normalization: bool = False
    skip_magic_trailing_comma: bool = False
    exclude: List[str] = field(default_factory=list)
    extend_exclude: List[str] = field(default_factory=list)

@dataclass
class IsortConfig:
    profile: str = 'black'
    line_length: int = 88
    known_first_party: List[str] = field(default_factory=list)
    known_third_party: List[str] = field(default_factory=list)
    skip: List[str] = field(default_factory=list)
    skip_glob: List[str] = field(default_factory=list)

@dataclass
class IgnoreRuleConfig:
    pattern: str
    codes: List[str] = field(default_factory=list)
    files: List[str] = field(default_factory=list)
    reason: Optional[str] = None
    expires: Optional[str] = None
    regex: bool = False

@dataclass
class QualityCheckerConfig:
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
        'venv/', '.venv/', 'build/', 'dist/', '.git/', '__pycache__/', '*.egg-info/'
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
        """Convert config to dictionary."""
        from dataclasses import asdict
        return asdict(self)
```

---

## Configuration Precedence Rules

### Precedence Order (Highest to Lowest)

```
1. Command-line Arguments     (Highest priority - always wins)
2. Environment Variables      (Overrides file configuration)
3. Project Configuration      (.python-quality-checker.yaml or pyproject.toml)
4. User Configuration         (~/.config/python-quality-checker/config.yaml)
5. Strictness Profile         (Applied as base configuration)
6. Default Values             (Lowest priority - fallback values)
```

### Configuration Merger Implementation

```python
from typing import Dict, Any, List
from pathlib import Path
import os

class ConfigurationMerger:
    """Merge configurations from multiple sources with proper precedence."""
    
    PRECEDENCE_ORDER = [
        'defaults',
        'strictness_profile',
        'user_config',
        'project_config',
        'environment',
        'cli_args',
    ]
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.yaml_parser = YAMLConfigParser(project_root)
        self.toml_parser = TOMLConfigParser(project_root)
        self.env_loader = EnvironmentConfigLoader()
        self.strictness_manager = StrictnessConfigManager()
    
    def merge_all(self, cli_args: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """Merge all configuration sources."""
        configs: Dict[str, Dict[str, Any]] = {
            'defaults': self._get_defaults(),
            'strictness_profile': {},
            'user_config': self._load_user_config(),
            'project_config': self._load_project_config(),
            'environment': self.env_loader.load(),
            'cli_args': cli_args or {},
        }
        
        strictness = self._determine_strictness(configs)
        configs['strictness_profile'] = self.strictness_manager.get_config(
            StrictnessLevel(strictness)
        )
        
        return self._merge_in_order(configs)
    
    def _determine_strictness(self, configs: Dict[str, Dict[str, Any]]) -> str:
        """Determine the effective strictness level."""
        for source in reversed(self.PRECEDENCE_ORDER):
            if source in configs and 'strictness' in configs[source]:
                return configs[source]['strictness']
        return 'normal'
    
    def _merge_in_order(self, configs: Dict[str, Dict[str, Any]]) -> Dict[str, Any]:
        """Merge configurations following precedence order."""
        result: Dict[str, Any] = {}
        
        for source in self.PRECEDENCE_ORDER:
            if source in configs:
                result = self._deep_merge(result, configs[source])
        
        return result
    
    def _deep_merge(self, base: Dict[str, Any], override: Dict[str, Any]) -> Dict[str, Any]:
        """Deep merge with override taking precedence."""
        result = base.copy()
        
        for key, value in override.items():
            if value is None:
                continue
            
            if key in result and isinstance(result[key], dict) and isinstance(value, dict):
                result[key] = self._deep_merge(result[key], value)
            elif isinstance(value, list) and key in result and isinstance(result[key], list):
                if key in ('exclude', 'ignore', 'disable'):
                    result[key] = list(set(result[key] + value))
                else:
                    result[key] = value
            else:
                result[key] = value
        
        return result
    
    def _get_defaults(self) -> Dict[str, Any]:
        """Get default configuration values."""
        return QualityCheckerConfig().to_dict()
    
    def _load_user_config(self) -> Dict[str, Any]:
        """Load user-level configuration."""
        config_dir = os.environ.get(
            'XDG_CONFIG_HOME',
            str(Path.home() / '.config')
        )
        user_config_path = Path(config_dir) / 'python-quality-checker' / 'config.yaml'
        
        if user_config_path.exists():
            result = YAMLConfigParser(user_config_path.parent).parse(user_config_path)
            if result.success:
                return result.config
        
        return {}
    
    def _load_project_config(self) -> Dict[str, Any]:
        """Load project-level configuration."""
        yaml_result = self.yaml_parser.parse_with_includes()
        if yaml_result.success:
            return yaml_result.config
        
        toml_result = self.toml_parser.parse()
        if toml_result.success:
            return toml_result.config
        
        return {}
    
    def get_effective_config_source(self, key: str, configs: Dict[str, Dict[str, Any]]) -> str:
        """Determine which source provided a specific configuration value."""
        for source in reversed(self.PRECEDENCE_ORDER):
            if source in configs:
                if self._has_key(configs[source], key):
                    return source
        return 'defaults'
    
    def _has_key(self, config: Dict[str, Any], key: str) -> bool:
        """Check if a nested key exists in config."""
        keys = key.split('.')
        current = config
        
        for k in keys:
            if isinstance(current, dict) and k in current:
                current = current[k]
            else:
                return False
        
        return True
```

---

## Default Configuration Values

```python
DEFAULT_CONFIG: Dict[str, Any] = {
    'version': '1.0',
    'strictness': 'normal',
    
    'linters': ['ruff'],
    'type_checker': 'mypy',
    'formatters': ['black', 'isort'],
    
    'rules': {
        'max_line_length': 100,
        'max_complexity': 10,
        'max_function_length': 50,
        'max_class_length': 300,
        'max_arguments': 5,
        'max_returns': 6,
        'max_branches': 12,
        'max_statements': 50,
        'max_nested_blocks': 5,
        'max_cognitive_complexity': 15,
        'min_public_methods': 2,
        'max_public_methods': 20,
    },
    
    'mypy': {
        'strict': False,
        'python_version': '3.10',
        'disallow_untyped_defs': True,
        'disallow_incomplete_defs': True,
        'check_untyped_defs': True,
        'ignore_missing_imports': True,
        'warn_return_any': False,
        'warn_unused_ignores': False,
        'strict_optional': True,
        'show_error_codes': True,
        'show_column_numbers': True,
        'plugins': [],
        'exclude': [],
        'overrides': {},
    },
    
    'pylint': {
        'disable': ['C0114', 'C0115', 'C0116'],
        'enable': [],
        'load_plugins': [],
        'good_names': ['i', 'j', 'k', 'ex', 'Run', '_'],
        'max_line_length': 100,
        'max_complexity': 10,
        'jobs': 0,
        'ignore': [],
        'ignore_patterns': [],
    },
    
    'ruff': {
        'select': ['E', 'F', 'W', 'I', 'N', 'UP', 'B'],
        'ignore': [],
        'extend_select': [],
        'line_length': 100,
        'target_version': 'py310',
        'exclude': [],
        'per_file_ignores': {},
        'fix': False,
    },
    
    'flake8': {
        'max_line_length': 100,
        'max_complexity': 10,
        'max_doc_length': 100,
        'ignore': ['W503', 'E203'],
        'select': ['E', 'W', 'F', 'C', 'N'],
        'extend_ignore': [],
        'extend_select': [],
        'exclude': [],
        'per_file_ignores': {},
    },
    
    'black': {
        'line_length': 88,
        'target_version': ['py39', 'py310'],
        'skip_string_normalization': False,
        'skip_magic_trailing_comma': False,
        'exclude': [],
        'extend_exclude': [],
    },
    
    'isort': {
        'profile': 'black',
        'line_length': 88,
        'known_first_party': [],
        'known_third_party': [],
        'skip': [],
        'skip_glob': [],
    },
    
    'ignore': [],
    'per_file_ignores': {},
    'exclude': [
        'venv/',
        '.venv/',
        'build/',
        'dist/',
        '.git/',
        '__pycache__/',
        '*.egg-info/',
        '.eggs/',
        'node_modules/',
    ],
    
    'auto_fix': True,
    'fail_threshold': 'warning',
    'output_format': 'text',
    'parallel': 4,
    'cache': True,
    'cache_dir': '.quality-checker-cache',
    
    'paths': ['.'],
    'config_file': None,
}
```

---

## Configuration Migration and Versioning

```python
from typing import Dict, Any, List, Optional, Tuple
from dataclasses import dataclass
import copy

@dataclass
class MigrationResult:
    success: bool
    config: Dict[str, Any]
    from_version: str
    to_version: str
    changes: List[str]
    warnings: List[str]

class ConfigurationMigrator:
    """Handle configuration version migrations."""
    
    CURRENT_VERSION = '1.0'
    
    MIGRATIONS: Dict[str, callable] = {}
    
    def __init__(self):
        self._register_migrations()
    
    def _register_migrations(self) -> None:
        """Register all migration functions."""
        self.MIGRATIONS = {
            ('0.1', '0.2'): self._migrate_0_1_to_0_2,
            ('0.2', '0.3'): self._migrate_0_2_to_0_3,
            ('0.3', '1.0'): self._migrate_0_3_to_1_0,
        }
    
    def migrate(self, config: Dict[str, Any]) -> MigrationResult:
        """Migrate configuration to current version."""
        version = config.get('version', '0.1')
        changes: List[str] = []
        warnings: List[str] = []
        
        migrated_config = copy.deepcopy(config)
        
        while version != self.CURRENT_VERSION:
            next_version = self._get_next_version(version)
            
            if next_version is None:
                warnings.append(f"Unknown version: {version}, assuming current")
                migrated_config['version'] = self.CURRENT_VERSION
                break
            
            migration_key = (version, next_version)
            
            if migration_key in self.MIGRATIONS:
                migrated_config, migration_changes = self.MIGRATIONS[migration_key](migrated_config)
                changes.extend(migration_changes)
                version = next_version
                migrated_config['version'] = version
            else:
                warnings.append(f"No migration path from {version} to {next_version}")
                break
        
        return MigrationResult(
            success=True,
            config=migrated_config,
            from_version=config.get('version', '0.1'),
            to_version=self.CURRENT_VERSION,
            changes=changes,
            warnings=warnings
        )
    
    def _get_next_version(self, current: str) -> Optional[str]:
        """Get the next version in the migration chain."""
        version_chain = ['0.1', '0.2', '0.3', '1.0']
        
        try:
            index = version_chain.index(current)
            if index < len(version_chain) - 1:
                return version_chain[index + 1]
        except ValueError:
            return None
        
        return None
    
    def _migrate_0_1_to_0_2(self, config: Dict[str, Any]) -> Tuple[Dict[str, Any], List[str]]:
        """Migrate from version 0.1 to 0.2."""
        changes = []
        migrated = copy.deepcopy(config)
        
        if 'max_line_length' in migrated:
            migrated['rules'] = migrated.get('rules', {})
            migrated['rules']['max_line_length'] = migrated.pop('max_line_length')
            changes.append("Moved 'max_line_length' to 'rules.max_line_length'")
        
        if 'max_complexity' in migrated:
            migrated['rules'] = migrated.get('rules', {})
            migrated['rules']['max_complexity'] = migrated.pop('max_complexity')
            changes.append("Moved 'max_complexity' to 'rules.max_complexity'")
        
        return migrated, changes
    
    def _migrate_0_2_to_0_3(self, config: Dict[str, Any]) -> Tuple[Dict[str, Any], List[str]]:
        """Migrate from version 0.2 to 0.3."""
        changes = []
        migrated = copy.deepcopy(config)
        
        if 'linter' in migrated:
            linter = migrated.pop('linter')
            if isinstance(linter, str):
                migrated['linters'] = [linter]
                changes.append(f"Converted 'linter: {linter}' to 'linters: [{linter}]'")
        
        if 'formatter' in migrated:
            formatter = migrated.pop('formatter')
            if isinstance(formatter, str):
                migrated['formatters'] = [formatter]
                changes.append(f"Converted 'formatter: {formatter}' to 'formatters: [{formatter}]'")
        
        return migrated, changes
    
    def _migrate_0_3_to_1_0(self, config: Dict[str, Any]) -> Tuple[Dict[str, Any], List[str]]:
        """Migrate from version 0.3 to 1.0."""
        changes = []
        migrated = copy.deepcopy(config)
        
        if 'fail_on' in migrated:
            migrated['fail_threshold'] = migrated.pop('fail_on')
            changes.append("Renamed 'fail_on' to 'fail_threshold'")
        
        if 'disabled_rules' in migrated:
            disabled = migrated.pop('disabled_rules')
            if isinstance(disabled, list):
                existing_ignore = migrated.get('ignore', [])
                migrated['ignore'] = list(set(existing_ignore + disabled))
                changes.append("Merged 'disabled_rules' into 'ignore'")
        
        return migrated, changes
    
    def needs_migration(self, config: Dict[str, Any]) -> bool:
        """Check if configuration needs migration."""
        version = config.get('version', '0.1')
        return version != self.CURRENT_VERSION
    
    def get_migration_info(self, config: Dict[str, Any]) -> Dict[str, Any]:
        """Get information about required migrations."""
        version = config.get('version', '0.1')
        
        return {
            'current_version': version,
            'target_version': self.CURRENT_VERSION,
            'needs_migration': self.needs_migration(config),
            'migration_path': self._get_migration_path(version),
        }
    
    def _get_migration_path(self, from_version: str) -> List[str]:
        """Get the migration path from a version."""
        path = []
        current = from_version
        
        while current != self.CURRENT_VERSION:
            next_v = self._get_next_version(current)
            if next_v is None:
                break
            path.append(f"{current} -> {next_v}")
            current = next_v
        
        return path


class ConfigurationValidator:
    """Validate configuration against schema."""
    
    def __init__(self):
        self.errors: List[str] = []
        self.warnings: List[str] = []
    
    def validate(self, config: Dict[str, Any]) -> bool:
        """Validate configuration and return True if valid."""
        self.errors = []
        self.warnings = []
        
        self._validate_version(config)
        self._validate_strictness(config)
        self._validate_linters(config)
        self._validate_type_checker(config)
        self._validate_rules(config)
        self._validate_ignore_rules(config)
        self._validate_paths(config)
        
        return len(self.errors) == 0
    
    def _validate_version(self, config: Dict[str, Any]) -> None:
        """Validate version field."""
        version = config.get('version')
        if version is None:
            self.warnings.append("Missing 'version' field, will use default")
        elif not isinstance(version, str):
            self.errors.append("'version' must be a string")
    
    def _validate_strictness(self, config: Dict[str, Any]) -> None:
        """Validate strictness level."""
        strictness = config.get('strictness')
        valid_levels = ['relaxed', 'normal', 'strict', 'very-strict']
        
        if strictness is not None and strictness not in valid_levels:
            self.errors.append(
                f"Invalid strictness level '{strictness}', must be one of: {valid_levels}"
            )
    
    def _validate_linters(self, config: Dict[str, Any]) -> None:
        """Validate linters configuration."""
        linters = config.get('linters')
        valid_linters = ['pylint', 'flake8', 'ruff']
        
        if linters is not None:
            if not isinstance(linters, list):
                self.errors.append("'linters' must be a list")
            else:
                for linter in linters:
                    if linter not in valid_linters:
                        self.warnings.append(f"Unknown linter '{linter}'")
    
    def _validate_type_checker(self, config: Dict[str, Any]) -> None:
        """Validate type checker configuration."""
        type_checker = config.get('type_checker')
        valid_checkers = ['mypy', 'pyright', 'none']
        
        if type_checker is not None and type_checker not in valid_checkers:
            self.warnings.append(f"Unknown type checker '{type_checker}'")
    
    def _validate_rules(self, config: Dict[str, Any]) -> None:
        """Validate rules configuration."""
        rules = config.get('rules', {})
        
        numeric_rules = [
            'max_line_length', 'max_complexity', 'max_function_length',
            'max_class_length', 'max_arguments', 'max_returns', 'max_branches',
            'max_statements', 'max_nested_blocks', 'max_cognitive_complexity',
            'min_public_methods', 'max_public_methods'
        ]
        
        for rule in numeric_rules:
            value = rules.get(rule)
            if value is not None:
                if not isinstance(value, int):
                    self.errors.append(f"'rules.{rule}' must be an integer")
                elif value <= 0:
                    self.errors.append(f"'rules.{rule}' must be positive")
    
    def _validate_ignore_rules(self, config: Dict[str, Any]) -> None:
        """Validate ignore rules configuration."""
        ignore = config.get('ignore', [])
        
        for rule in ignore:
            if isinstance(rule, dict):
                if 'pattern' not in rule:
                    self.errors.append("Ignore rule missing 'pattern' field")
                
                if 'expires' in rule:
                    try:
                        from datetime import datetime
                        datetime.strptime(rule['expires'], '%Y-%m-%d')
                    except ValueError:
                        self.errors.append(
                            f"Invalid expiry date format: {rule['expires']}, expected YYYY-MM-DD"
                        )
    
    def _validate_paths(self, config: Dict[str, Any]) -> None:
        """Validate paths configuration."""
        paths = config.get('paths', [])
        
        if not isinstance(paths, list):
            self.errors.append("'paths' must be a list")
        else:
            for path in paths:
                if not isinstance(path, str):
                    self.errors.append(f"Invalid path: {path}")
    
    def get_errors(self) -> List[str]:
        """Get validation errors."""
        return self.errors
    
    def get_warnings(self) -> List[str]:
        """Get validation warnings."""
        return self.warnings
```

---

## Configuration Examples

### Example 1: Parse YAML Configuration

```python
from pathlib import Path

project_root = Path('/path/to/project')
parser = YAMLConfigParser(project_root)

result = parser.parse_with_includes()

if result.success:
    print(f"Configuration loaded from: {result.source}")
    print(f"Configuration: {result.config}")
    
    for warning in result.warnings:
        print(f"Warning: {warning}")
else:
    for error in result.errors:
        print(f"Error: {error}")
```

### Example 2: Merge Multiple Configuration Sources

```python
from pathlib import Path

project_root = Path('/path/to/project')
merger = ConfigurationMerger(project_root)

cli_args = {
    'strictness': 'strict',
    'linters': ['ruff', 'mypy'],
    'auto_fix': False,
}

final_config = merger.merge_all(cli_args)
print(f"Effective configuration: {final_config}")
```

### Example 3: Apply Command-line Overrides

```python
cli_handler = CLIConfigOverride()
cli_handler.parse_args(['--strictness', 'strict', '--max-line-length', '88'])

base_config = {
    'strictness': 'normal',
    'rules': {
        'max_line_length': 100,
    }
}

final_config = cli_handler.apply_overrides(base_config)
print(f"Configuration after CLI overrides: {final_config}")
```

### Example 4: Handle Environment Variables

```python
import os

os.environ['PYTHON_QUALITY_STRICTNESS'] = 'strict'
os.environ['PYTHON_QUALITY_MAX_LINE_LENGTH'] = '88'
os.environ['PYTHON_QUALITY_LINTERS'] = 'ruff,pylint'

env_loader = EnvironmentConfigLoader()
env_config = env_loader.load()

print(f"Environment configuration: {env_config}")
```

### Example 5: Validate Configuration

```python
config = {
    'version': '1.0',
    'strictness': 'invalid-level',
    'linters': ['unknown-linter'],
    'rules': {
        'max_line_length': -100,
    }
}

validator = ConfigurationValidator()
is_valid = validator.validate(config)

if not is_valid:
    print("Validation errors:")
    for error in validator.get_errors():
        print(f"  - {error}")

print("Validation warnings:")
for warning in validator.get_warnings():
    print(f"  - {warning}")
```

---

## Best Practices

1. **Use Version Control**: Always include a `version` field in configuration files for future migrations
2. **Layer Configuration**: Start with strictness profiles, then add project-specific overrides
3. **Document Exceptions**: Add `reason` fields to ignore rules for future reference
4. **Use Expiry Dates**: Set `expires` on temporary ignore rules to prevent permanent exceptions
5. **Validate Early**: Run configuration validation before starting quality checks
6. **Centralize Configuration**: Prefer `pyproject.toml` for all tool configurations
7. **Environment Parity**: Use environment variables for CI/CD-specific overrides
8. **Cache Configuration**: Cache parsed configuration for performance in large projects
9. **Audit Regularly**: Review ignore rules and strictness levels periodically
10. **Test Migrations**: Test configuration migrations in a branch before applying to main

---

## Troubleshooting

### Issue 1: Configuration Not Found

**Problem:** Quality checker cannot find configuration file

**Solutions:**
1. Ensure file is in project root
2. Check file name matches expected patterns
3. Specify config file explicitly: `--config path/to/config.yaml`

### Issue 2: Conflicting Configurations

**Problem:** Multiple configuration sources have conflicting values

**Solutions:**
1. Use `ConfigurationMerger.get_effective_config_source()` to identify source
2. Review precedence rules
3. Remove redundant configurations

### Issue 3: Migration Fails

**Problem:** Configuration migration produces unexpected results

**Solutions:**
1. Check `MigrationResult.warnings` for issues
2. Review migration path with `get_migration_info()`
3. Manually update configuration to current version

### Issue 4: Environment Variables Not Applied

**Problem:** Environment variable settings are ignored

**Solutions:**
1. Verify variable names match `PYTHON_QUALITY_*` prefix
2. Check for typos in variable names
3. Ensure values are in correct format (comma-separated for lists)

### Issue 5: Ignore Rules Not Working

**Problem:** Issues are still reported despite ignore rules

**Solutions:**
1. Verify pattern syntax (glob vs regex)
2. Check if rule has expired
3. Ensure codes match actual error codes
4. Validate rules with `IgnoreRulesManager.validate_rules()`
