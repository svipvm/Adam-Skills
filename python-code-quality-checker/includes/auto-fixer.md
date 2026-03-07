# Intelligent Error Fixing Module

## Overview

The Intelligent Error Fixing module provides automated detection and correction of common Python code quality issues. It combines static analysis with safe, configurable auto-fixing capabilities to maintain code quality standards while minimizing manual intervention.

### Key Capabilities

- **Precise Problem Identification**: Locates exact file, line, and column positions of issues
- **Multi-Option Fix Suggestions**: Provides multiple fix alternatives when applicable
- **Safe Auto-Fixing**: Applies changes with comprehensive safety checks and rollback support
- **Fix Validation**: Verifies fixes don't introduce new issues
- **Comprehensive Reporting**: Generates detailed fix reports with before/after comparisons

---

## Implementation Guide

### 1. Precise Problem Identification

The first step in intelligent error fixing is accurately identifying the problem location and nature.

```python
from dataclasses import dataclass
from enum import Enum
from typing import Optional, List, Dict, Any
import re

class IssueSeverity(Enum):
    ERROR = "error"
    WARNING = "warning"
    INFO = "info"
    CONVENTION = "convention"
    REFACTOR = "refactor"

class IssueCategory(Enum):
    IMPORT = "import"
    STYLE = "style"
    TYPE = "type"
    NAMING = "naming"
    REFACTORING = "refactoring"
    SYNTAX = "syntax"
    LOGIC = "logic"

@dataclass
class CodeIssue:
    file_path: str
    line: int
    column: int
    end_line: Optional[int]
    end_column: Optional[int]
    severity: IssueSeverity
    category: IssueCategory
    code: str
    message: str
    source: str
    fixable: bool
    suggested_fix: Optional[str] = None
    context_before: Optional[List[str]] = None
    context_after: Optional[List[str]] = None

class ProblemIdentifier:
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.issue_patterns = self._load_issue_patterns()
    
    def _load_issue_patterns(self) -> Dict[str, re.Pattern]:
        return {
            "unused_import": re.compile(r"(\w+).*imported but unused"),
            "missing_import": re.compile(r"Undefined name '(\w+)'"),
            "line_too_long": re.compile(r"line too long \((\d+) > (\d+)\)"),
            "trailing_whitespace": re.compile(r"trailing whitespace"),
            "missing_newline": re.compile(r"final newline"),
            "multiple_imports": re.compile(r"multiple imports on one line"),
            "wrong_import_order": re.compile(r"wrong import order"),
            "undefined_variable": re.compile(r"Undefined variable '(\w+)'"),
            "redefined_variable": re.compile(r"Redefining name '(\w+)'"),
        }
    
    def identify_issue(self, raw_error: Dict[str, Any]) -> CodeIssue:
        file_path = raw_error.get("file", "")
        line = raw_error.get("line", 1)
        column = raw_error.get("column", 0)
        message = raw_error.get("message", "")
        code = raw_error.get("code", "")
        source = raw_error.get("source", "unknown")
        
        severity = self._determine_severity(code, message)
        category = self._determine_category(code, message)
        fixable = self._is_fixable(code, category)
        
        return CodeIssue(
            file_path=file_path,
            line=line,
            column=column,
            end_line=raw_error.get("endLine"),
            end_column=raw_error.get("endColumn"),
            severity=severity,
            category=category,
            code=code,
            message=message,
            source=source,
            fixable=fixable
        )
    
    def _determine_severity(self, code: str, message: str) -> IssueSeverity:
        severity_map = {
            "E": IssueSeverity.ERROR,
            "F": IssueSeverity.ERROR,
            "W": IssueSeverity.WARNING,
            "C": IssueSeverity.CONVENTION,
            "R": IssueSeverity.REFACTOR,
            "N": IssueSeverity.CONVENTION,
        }
        prefix = code[0] if code else "W"
        return severity_map.get(prefix, IssueSeverity.WARNING)
    
    def _determine_category(self, code: str, message: str) -> IssueCategory:
        category_map = {
            "F401": IssueCategory.IMPORT,
            "F403": IssueCategory.IMPORT,
            "E501": IssueCategory.STYLE,
            "W291": IssueCategory.STYLE,
            "W292": IssueCategory.STYLE,
            "W293": IssueCategory.STYLE,
            "E302": IssueCategory.STYLE,
            "E305": IssueCategory.STYLE,
            "N801": IssueCategory.NAMING,
            "N802": IssueCategory.NAMING,
            "N803": IssueCategory.NAMING,
            "N806": IssueCategory.NAMING,
        }
        
        if code in category_map:
            return category_map[code]
        
        if "import" in message.lower():
            return IssueCategory.IMPORT
        if "type" in message.lower() or "annotation" in message.lower():
            return IssueCategory.TYPE
        if "name" in message.lower() or "naming" in message.lower():
            return IssueCategory.NAMING
        
        return IssueCategory.STYLE
    
    def _is_fixable(self, code: str, category: IssueCategory) -> bool:
        auto_fixable_codes = {
            "F401", "E501", "W291", "W292", "W293",
            "E302", "E305", "I001", "I003", "I004",
            "I005", "UP001", "UP003", "UP004"
        }
        return code in auto_fixable_codes or category in {
            IssueCategory.IMPORT, IssueCategory.STYLE
        }
    
    def extract_context(self, file_path: str, line: int, 
                        context_lines: int = 3) -> tuple:
        try:
            with open(file_path, 'r') as f:
                lines = f.readlines()
            
            start = max(0, line - context_lines - 1)
            end = min(len(lines), line + context_lines)
            
            before = lines[start:line-1] if line > 1 else []
            current = lines[line-1] if line <= len(lines) else ""
            after = lines[line:end]
            
            return before, current, after
        except Exception:
            return [], "", []
```

### 2. Fix Suggestion Generation

Generate multiple fix options when applicable, allowing users to choose the best approach.

```python
from abc import ABC, abstractmethod
from typing import List, Tuple, Optional
import difflib

@dataclass
class FixSuggestion:
    issue: CodeIssue
    fix_type: str
    description: str
    original_code: str
    fixed_code: str
    confidence: float
    auto_applicable: bool
    requires_review: bool
    side_effects: List[str]
    diff: Optional[str] = None

class FixGenerator(ABC):
    @abstractmethod
    def can_fix(self, issue: CodeIssue) -> bool:
        pass
    
    @abstractmethod
    def generate_fixes(self, issue: CodeIssue, 
                       file_content: str) -> List[FixSuggestion]:
        pass

class ImportFixGenerator(FixGenerator):
    def can_fix(self, issue: CodeIssue) -> bool:
        return issue.category == IssueCategory.IMPORT
    
    def generate_fixes(self, issue: CodeIssue, 
                       file_content: str) -> List[FixSuggestion]:
        fixes = []
        lines = file_content.split('\n')
        
        if issue.code == "F401":
            fixes.extend(self._fix_unused_import(issue, lines))
        elif issue.code == "F403":
            fixes.extend(self._fix_star_import(issue, lines))
        elif "I001" in issue.code:
            fixes.extend(self._fix_import_order(issue, lines))
        elif "missing" in issue.message.lower():
            fixes.extend(self._fix_missing_import(issue, lines))
        
        return fixes
    
    def _fix_unused_import(self, issue: CodeIssue, 
                           lines: List[str]) -> List[FixSuggestion]:
        fixes = []
        import_line = lines[issue.line - 1] if issue.line <= len(lines) else ""
        
        match = re.search(r'from\s+[\w.]+\s+import\s+(.+)', import_line)
        if match:
            imports = [i.strip() for i in match.group(1).split(',')]
            unused = self._extract_unused_name(issue.message)
            
            if unused and unused in imports:
                if len(imports) == 1:
                    fixed_line = ""
                    description = f"Remove entire import line: {import_line.strip()}"
                else:
                    imports.remove(unused)
                    fixed_line = import_line[:match.start(1)] + ', '.join(imports) + '\n'
                    description = f"Remove unused import '{unused}' from line"
                
                fixes.append(FixSuggestion(
                    issue=issue,
                    fix_type="remove_unused_import",
                    description=description,
                    original_code=import_line,
                    fixed_code=fixed_line,
                    confidence=0.95,
                    auto_applicable=True,
                    requires_review=False,
                    side_effects=[]
                ))
        
        return fixes
    
    def _fix_star_import(self, issue: CodeIssue, 
                         lines: List[str]) -> List[FixSuggestion]:
        fixes = []
        import_line = lines[issue.line - 1] if issue.line <= len(lines) else ""
        
        match = re.search(r'from\s+([\w.]+)\s+import\s+\*', import_line)
        if match:
            module = match.group(1)
            used_names = self._find_used_names_from_module(
                module, lines, issue.line
            )
            
            if used_names:
                fixed_line = f"from {module} import {', '.join(sorted(used_names))}\n"
                fixes.append(FixSuggestion(
                    issue=issue,
                    fix_type="expand_star_import",
                    description=f"Replace star import with explicit imports: {', '.join(used_names)}",
                    original_code=import_line,
                    fixed_code=fixed_line,
                    confidence=0.85,
                    auto_applicable=False,
                    requires_review=True,
                    side_effects=["May need to add more imports if new names are used"]
                ))
        
        return fixes
    
    def _fix_missing_import(self, issue: CodeIssue, 
                            lines: List[str]) -> List[FixSuggestion]:
        fixes = []
        match = re.search(r"Undefined name '(\w+)'", issue.message)
        
        if match:
            name = match.group(1)
            possible_sources = self._find_possible_import_sources(name)
            
            for source in possible_sources:
                import_line = f"import {source}\n"
                insert_line = self._find_import_insert_position(lines)
                
                fixes.append(FixSuggestion(
                    issue=issue,
                    fix_type="add_missing_import",
                    description=f"Add import: {import_line.strip()}",
                    original_code="",
                    fixed_code=import_line,
                    confidence=0.7,
                    auto_applicable=False,
                    requires_review=True,
                    side_effects=[f"Adds dependency on '{source}'"]
                ))
        
        return fixes
    
    def _extract_unused_name(self, message: str) -> Optional[str]:
        match = re.search(r"'(\w+)' imported but unused", message)
        return match.group(1) if match else None
    
    def _find_used_names_from_module(self, module: str, lines: List[str],
                                      import_line: int) -> List[str]:
        used_names = set()
        module_short = module.split('.')[-1]
        
        for i, line in enumerate(lines):
            if i == import_line - 1:
                continue
            
            patterns = [
                rf'\b{module_short}\.\w+',
                rf'\bfrom\s+{module}\s+import\s+\w+',
            ]
            
            for pattern in patterns:
                matches = re.findall(pattern, line)
                for match in matches:
                    if '.' in match:
                        used_names.add(match.split('.')[-1])
        
        return list(used_names)
    
    def _find_possible_import_sources(self, name: str) -> List[str]:
        common_modules = {
            'os': ['os'],
            'sys': ['sys'],
            're': ['re'],
            'json': ['json'],
            'datetime': ['datetime'],
            'Path': ['pathlib'],
            'List': ['typing'],
            'Dict': ['typing'],
            'Optional': ['typing'],
            'Any': ['typing'],
            'Union': ['typing'],
            'Callable': ['typing'],
        }
        return common_modules.get(name, [name])
    
    def _find_import_insert_position(self, lines: List[str]) -> int:
        last_import = 0
        for i, line in enumerate(lines):
            if line.strip().startswith(('import ', 'from ')):
                last_import = i + 1
            elif line.strip() and not line.strip().startswith('#'):
                if last_import > 0:
                    break
        return last_import

class StyleFixGenerator(FixGenerator):
    def can_fix(self, issue: CodeIssue) -> bool:
        return issue.category == IssueCategory.STYLE
    
    def generate_fixes(self, issue: CodeIssue, 
                       file_content: str) -> List[FixSuggestion]:
        fixes = []
        lines = file_content.split('\n')
        
        if issue.code == "E501":
            fixes.extend(self._fix_long_line(issue, lines))
        elif issue.code == "W291":
            fixes.extend(self._fix_trailing_whitespace(issue, lines))
        elif issue.code == "W292":
            fixes.extend(self._fix_missing_newline(issue, lines))
        elif issue.code in ("E302", "E305"):
            fixes.extend(self._fix_blank_lines(issue, lines))
        
        return fixes
    
    def _fix_long_line(self, issue: CodeIssue, 
                       lines: List[str]) -> List[FixSuggestion]:
        fixes = []
        line = lines[issue.line - 1] if issue.line <= len(lines) else ""
        max_length = self._extract_max_length(issue.message)
        
        if not max_length:
            max_length = 88
        
        if len(line) > max_length:
            fixed_versions = self._try_split_line(line, max_length)
            
            for i, fixed in enumerate(fixed_versions):
                fixes.append(FixSuggestion(
                    issue=issue,
                    fix_type="split_long_line",
                    description=f"Split line to comply with {max_length} character limit (option {i+1})",
                    original_code=line,
                    fixed_code=fixed,
                    confidence=0.8 if i == 0 else 0.6,
                    auto_applicable=i == 0,
                    requires_review=True,
                    side_effects=["May affect readability"]
                ))
        
        return fixes
    
    def _try_split_line(self, line: str, max_length: int) -> List[str]:
        results = []
        
        if '(' in line and ')' in line:
            results.extend(self._split_function_call(line, max_length))
        
        if ',' in line and not results:
            results.extend(self._split_comma_separated(line, max_length))
        
        if ' ' in line and not results:
            results.extend(self._split_at_operator(line, max_length))
        
        if not results:
            results.append(line)
        
        return results
    
    def _split_function_call(self, line: str, max_length: int) -> List[str]:
        match = re.match(r'(\s*)(\w+)\((.*)\)(.*)', line)
        if not match:
            return []
        
        indent, func_name, args, rest = match.groups()
        arg_list = [a.strip() for a in args.split(',')]
        
        if len(arg_list) > 1:
            formatted = f"{indent}{func_name}(\n"
            for arg in arg_list:
                formatted += f"{indent}    {arg},\n"
            formatted += f"{indent}){rest}"
            return [formatted]
        
        return []
    
    def _split_comma_separated(self, line: str, max_length: int) -> List[str]:
        indent_match = re.match(r'(\s*)', line)
        indent = indent_match.group(1) if indent_match else ""
        
        parts = line.split(',')
        if len(parts) > 1:
            return [',\n'.join(f"{indent}{p.strip()}" if i > 0 else p 
                              for i, p in enumerate(parts))]
        return []
    
    def _split_at_operator(self, line: str, max_length: int) -> List[str]:
        operators = [' and ', ' or ', ' + ', ' - ', ' == ', ' != ']
        
        for op in operators:
            if op in line:
                parts = line.split(op, 1)
                if len(parts) == 2:
                    indent_match = re.match(r'(\s*)', line)
                    indent = indent_match.group(1) if indent_match else ""
                    return [f"{parts[0]}{op}\n{indent}{parts[1]}"]
        
        return []
    
    def _fix_trailing_whitespace(self, issue: CodeIssue, 
                                  lines: List[str]) -> List[FixSuggestion]:
        line = lines[issue.line - 1] if issue.line <= len(lines) else ""
        fixed_line = line.rstrip() + '\n' if line.endswith('\n') else line.rstrip()
        
        return [FixSuggestion(
            issue=issue,
            fix_type="remove_trailing_whitespace",
            description="Remove trailing whitespace",
            original_code=line,
            fixed_code=fixed_line,
            confidence=1.0,
            auto_applicable=True,
            requires_review=False,
            side_effects=[]
        )]
    
    def _fix_missing_newline(self, issue: CodeIssue, 
                             lines: List[str]) -> List[FixSuggestion]:
        if lines and not lines[-1].endswith('\n'):
            return [FixSuggestion(
                issue=issue,
                fix_type="add_final_newline",
                description="Add final newline",
                original_code=lines[-1],
                fixed_code=lines[-1] + '\n',
                confidence=1.0,
                auto_applicable=True,
                requires_review=False,
                side_effects=[]
            )]
        return []
    
    def _fix_blank_lines(self, issue: CodeIssue, 
                         lines: List[str]) -> List[FixSuggestion]:
        required_blank = 2 if issue.code == "E302" else 2
        fixes = []
        
        current_blanks = 0
        for i in range(issue.line - 2, -1, -1):
            if i >= 0 and lines[i].strip() == '':
                current_blanks += 1
            else:
                break
        
        if current_blanks < required_blank:
            blank_line = '\n' * (required_blank - current_blanks)
            fixes.append(FixSuggestion(
                issue=issue,
                fix_type="add_blank_lines",
                description=f"Add {required_blank - current_blanks} blank line(s)",
                original_code="",
                fixed_code=blank_line,
                confidence=1.0,
                auto_applicable=True,
                requires_review=False,
                side_effects=[]
            ))
        
        return fixes
    
    def _extract_max_length(self, message: str) -> Optional[int]:
        match = re.search(r'\((\d+) > (\d+)\)', message)
        if match:
            return int(match.group(2))
        return None

class TypeAnnotationFixGenerator(FixGenerator):
    def can_fix(self, issue: CodeIssue) -> bool:
        return issue.category == IssueCategory.TYPE
    
    def generate_fixes(self, issue: CodeIssue, 
                       file_content: str) -> List[FixSuggestion]:
        fixes = []
        lines = file_content.split('\n')
        
        if "missing type" in issue.message.lower():
            fixes.extend(self._add_type_annotation(issue, lines))
        elif "incompatible" in issue.message.lower():
            fixes.extend(self._fix_incompatible_type(issue, lines))
        
        return fixes
    
    def _add_type_annotation(self, issue: CodeIssue, 
                             lines: List[str]) -> List[FixSuggestion]:
        line = lines[issue.line - 1] if issue.line <= len(lines) else ""
        fixes = []
        
        func_match = re.match(r'(\s*)def\s+(\w+)\s*\(([^)]*)\)', line)
        if func_match:
            indent, func_name, params = func_match.groups()
            
            if '->' not in line:
                fixed_line = line.rstrip()
                if fixed_line.endswith(':'):
                    fixed_line = fixed_line[:-1] + ' -> None:'
                else:
                    fixed_line = fixed_line + ' -> None'
                
                fixes.append(FixSuggestion(
                    issue=issue,
                    fix_type="add_return_type",
                    description="Add return type annotation 'None'",
                    original_code=line,
                    fixed_code=fixed_line + '\n',
                    confidence=0.7,
                    auto_applicable=False,
                    requires_review=True,
                    side_effects=["Assumes function returns None"]
                ))
        
        return fixes
    
    def _fix_incompatible_type(self, issue: CodeIssue, 
                               lines: List[str]) -> List[FixSuggestion]:
        return []

class NamingFixGenerator(FixGenerator):
    def can_fix(self, issue: CodeIssue) -> bool:
        return issue.category == IssueCategory.NAMING
    
    def generate_fixes(self, issue: CodeIssue, 
                       file_content: str) -> List[FixSuggestion]:
        fixes = []
        lines = file_content.split('\n')
        
        if issue.code == "N801":
            fixes.extend(self._fix_class_name(issue, lines))
        elif issue.code == "N802":
            fixes.extend(self._fix_function_name(issue, lines))
        elif issue.code == "N803":
            fixes.extend(self._fix_argument_name(issue, lines))
        elif issue.code == "N806":
            fixes.extend(self._fix_variable_name(issue, lines))
        
        return fixes
    
    def _fix_class_name(self, issue: CodeIssue, 
                        lines: List[str]) -> List[FixSuggestion]:
        line = lines[issue.line - 1] if issue.line <= len(lines) else ""
        match = re.search(r'class\s+(\w+)', line)
        
        if match:
            old_name = match.group(1)
            new_name = self._to_pascal_case(old_name)
            
            if new_name != old_name:
                fixed_line = line.replace(f"class {old_name}", f"class {new_name}")
                return [FixSuggestion(
                    issue=issue,
                    fix_type="rename_class",
                    description=f"Rename class '{old_name}' to '{new_name}'",
                    original_code=line,
                    fixed_code=fixed_line,
                    confidence=0.9,
                    auto_applicable=False,
                    requires_review=True,
                    side_effects=["All references to this class must be updated"]
                )]
        
        return []
    
    def _fix_function_name(self, issue: CodeIssue, 
                           lines: List[str]) -> List[FixSuggestion]:
        line = lines[issue.line - 1] if issue.line <= len(lines) else ""
        match = re.search(r'def\s+(\w+)', line)
        
        if match:
            old_name = match.group(1)
            new_name = self._to_snake_case(old_name)
            
            if new_name != old_name:
                fixed_line = line.replace(f"def {old_name}", f"def {new_name}")
                return [FixSuggestion(
                    issue=issue,
                    fix_type="rename_function",
                    description=f"Rename function '{old_name}' to '{new_name}'",
                    original_code=line,
                    fixed_code=fixed_line,
                    confidence=0.85,
                    auto_applicable=False,
                    requires_review=True,
                    side_effects=["All call sites must be updated"]
                )]
        
        return []
    
    def _fix_argument_name(self, issue: CodeIssue, 
                           lines: List[str]) -> List[FixSuggestion]:
        line = lines[issue.line - 1] if issue.line <= len(lines) else ""
        match = re.search(r'(\w+)\s*=', line)
        
        if match:
            old_name = match.group(1)
            new_name = self._to_snake_case(old_name)
            
            if new_name != old_name:
                fixed_line = re.sub(
                    rf'\b{old_name}\b', new_name, line, count=1
                )
                return [FixSuggestion(
                    issue=issue,
                    fix_type="rename_argument",
                    description=f"Rename argument '{old_name}' to '{new_name}'",
                    original_code=line,
                    fixed_code=fixed_line,
                    confidence=0.85,
                    auto_applicable=False,
                    requires_review=True,
                    side_effects=["Function body references must be updated"]
                )]
        
        return []
    
    def _fix_variable_name(self, issue: CodeIssue, 
                           lines: List[str]) -> List[FixSuggestion]:
        line = lines[issue.line - 1] if issue.line <= len(lines) else ""
        match = re.search(r'(\w+)\s*=', line)
        
        if match:
            old_name = match.group(1)
            new_name = self._to_snake_case(old_name)
            
            if new_name != old_name:
                return [FixSuggestion(
                    issue=issue,
                    fix_type="rename_variable",
                    description=f"Rename variable '{old_name}' to '{new_name}'",
                    original_code=line,
                    fixed_code=line.replace(old_name, new_name, 1),
                    confidence=0.8,
                    auto_applicable=False,
                    requires_review=True,
                    side_effects=["All usages in scope must be updated"]
                )]
        
        return []
    
    def _to_pascal_case(self, name: str) -> str:
        parts = re.split(r'[_\s]+', name)
        return ''.join(word.capitalize() for word in parts if word)
    
    def _to_snake_case(self, name: str) -> str:
        s1 = re.sub(r'(.)([A-Z][a-z]+)', r'\1_\2', name)
        return re.sub(r'([a-z0-9])([A-Z])', r'\1_\2', s1).lower()

class FixSuggestionEngine:
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.generators: List[FixGenerator] = [
            ImportFixGenerator(),
            StyleFixGenerator(),
            TypeAnnotationFixGenerator(),
            NamingFixGenerator(),
        ]
    
    def generate_suggestions(self, issue: CodeIssue, 
                            file_content: str) -> List[FixSuggestion]:
        suggestions = []
        
        for generator in self.generators:
            if generator.can_fix(issue):
                suggestions.extend(generator.generate_fixes(issue, file_content))
        
        for suggestion in suggestions:
            suggestion.diff = self._generate_diff(
                suggestion.original_code, 
                suggestion.fixed_code
            )
        
        return suggestions
    
    def _generate_diff(self, original: str, fixed: str) -> str:
        diff = difflib.unified_diff(
            original.splitlines(keepends=True),
            fixed.splitlines(keepends=True),
            fromfile='original',
            tofile='fixed',
            lineterm=''
        )
        return ''.join(diff)
```

### 3. Automatic Fix Application with Safety Checks

Apply fixes safely with comprehensive validation and rollback capabilities.

```python
import shutil
from pathlib import Path
from datetime import datetime
from typing import Set
import hashlib
import json

@dataclass
class AppliedFix:
    suggestion: FixSuggestion
    timestamp: str
    backup_path: Optional[str]
    file_hash_before: str
    file_hash_after: str
    success: bool
    error_message: Optional[str] = None

@dataclass
class FixBatch:
    batch_id: str
    timestamp: str
    fixes: List[AppliedFix]
    files_modified: Set[str]
    rollback_available: bool

class SafetyChecker:
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.protected_patterns = [
            r'test_.*\.py$',
            r'__init__\.py$',
            r'setup\.py$',
            r'conftest\.py$',
        ]
        self.max_fixes_per_file = config.get('max_fixes_per_file', 10)
        self.require_review_threshold = config.get('require_review_threshold', 0.8)
    
    def is_safe_to_fix(self, issue: CodeIssue, 
                       suggestion: FixSuggestion) -> Tuple[bool, List[str]]:
        warnings = []
        
        if suggestion.confidence < self.require_review_threshold:
            warnings.append(f"Low confidence fix: {suggestion.confidence:.2f}")
        
        if suggestion.requires_review:
            warnings.append("Fix requires manual review")
        
        for pattern in self.protected_patterns:
            if re.search(pattern, issue.file_path):
                warnings.append(f"Protected file pattern: {pattern}")
        
        if not suggestion.auto_applicable:
            warnings.append("Fix is not marked as auto-applicable")
        
        is_safe = len(warnings) == 0 or self.config.get('force_apply', False)
        
        return is_safe, warnings
    
    def check_file_state(self, file_path: str, 
                         expected_hash: str) -> Tuple[bool, str]:
        current_hash = self._compute_file_hash(file_path)
        return current_hash == expected_hash, current_hash
    
    def _compute_file_hash(self, file_path: str) -> str:
        try:
            with open(file_path, 'rb') as f:
                return hashlib.sha256(f.read()).hexdigest()
        except Exception:
            return ""

class FixApplicator:
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.safety_checker = SafetyChecker(config)
        self.backup_dir = Path(config.get('backup_dir', '.fix_backups'))
        self.backup_dir.mkdir(exist_ok=True)
        self.applied_fixes: List[AppliedFix] = []
    
    def apply_fix(self, suggestion: FixSuggestion, 
                  auto_confirm: bool = False) -> AppliedFix:
        issue = suggestion.issue
        file_path = issue.file_path
        timestamp = datetime.now().isoformat()
        
        is_safe, warnings = self.safety_checker.is_safe_to_fix(issue, suggestion)
        
        if not is_safe and not auto_confirm:
            return AppliedFix(
                suggestion=suggestion,
                timestamp=timestamp,
                backup_path=None,
                file_hash_before="",
                file_hash_after="",
                success=False,
                error_message=f"Safety check failed: {'; '.join(warnings)}"
            )
        
        try:
            file_hash_before = self.safety_checker._compute_file_hash(file_path)
            backup_path = self._create_backup(file_path, timestamp)
            
            with open(file_path, 'r') as f:
                content = f.read()
            
            if suggestion.fix_type in ['add_missing_import', 'add_blank_lines']:
                modified_content = self._apply_insertion(content, suggestion)
            elif suggestion.fix_type in ['remove_unused_import']:
                modified_content = self._apply_removal(content, suggestion)
            else:
                modified_content = self._apply_replacement(content, suggestion)
            
            with open(file_path, 'w') as f:
                f.write(modified_content)
            
            file_hash_after = self.safety_checker._compute_file_hash(file_path)
            
            applied_fix = AppliedFix(
                suggestion=suggestion,
                timestamp=timestamp,
                backup_path=str(backup_path),
                file_hash_before=file_hash_before,
                file_hash_after=file_hash_after,
                success=True
            )
            
            self.applied_fixes.append(applied_fix)
            return applied_fix
            
        except Exception as e:
            return AppliedFix(
                suggestion=suggestion,
                timestamp=timestamp,
                backup_path=None,
                file_hash_before="",
                file_hash_after="",
                success=False,
                error_message=str(e)
            )
    
    def apply_batch(self, suggestions: List[FixSuggestion], 
                    auto_confirm: bool = False) -> FixBatch:
        batch_id = hashlib.sha256(
            str(datetime.now()).encode()
        ).hexdigest()[:8]
        timestamp = datetime.now().isoformat()
        
        applied_fixes = []
        files_modified = set()
        
        for suggestion in suggestions:
            result = self.apply_fix(suggestion, auto_confirm)
            applied_fixes.append(result)
            if result.success:
                files_modified.add(suggestion.issue.file_path)
        
        return FixBatch(
            batch_id=batch_id,
            timestamp=timestamp,
            fixes=applied_fixes,
            files_modified=files_modified,
            rollback_available=True
        )
    
    def _create_backup(self, file_path: str, timestamp: str) -> Path:
        source = Path(file_path)
        backup_name = f"{source.stem}_{timestamp.replace(':', '-')}{source.suffix}"
        backup_path = self.backup_dir / backup_name
        shutil.copy2(source, backup_path)
        return backup_path
    
    def _apply_replacement(self, content: str, 
                          suggestion: FixSuggestion) -> str:
        lines = content.split('\n')
        line_idx = suggestion.issue.line - 1
        
        if 0 <= line_idx < len(lines):
            lines[line_idx] = suggestion.fixed_code.rstrip('\n')
        
        return '\n'.join(lines)
    
    def _apply_removal(self, content: str, 
                       suggestion: FixSuggestion) -> str:
        lines = content.split('\n')
        line_idx = suggestion.issue.line - 1
        
        if 0 <= line_idx < len(lines):
            if suggestion.fixed_code.strip() == '':
                lines.pop(line_idx)
            else:
                lines[line_idx] = suggestion.fixed_code.rstrip('\n')
        
        return '\n'.join(lines)
    
    def _apply_insertion(self, content: str, 
                        suggestion: FixSuggestion) -> str:
        lines = content.split('\n')
        
        if suggestion.fix_type == 'add_missing_import':
            insert_pos = self._find_import_position(lines)
            lines.insert(insert_pos, suggestion.fixed_code.rstrip('\n'))
        elif suggestion.fix_type == 'add_blank_lines':
            line_idx = suggestion.issue.line - 1
            for _ in range(len(suggestion.fixed_code)):
                lines.insert(line_idx, '')
        
        return '\n'.join(lines)
    
    def _find_import_position(self, lines: List[str]) -> int:
        last_import = 0
        in_docstring = False
        docstring_char = None
        
        for i, line in enumerate(lines):
            stripped = line.strip()
            
            if not in_docstring:
                if stripped.startswith(('"""', "'''")):
                    in_docstring = True
                    docstring_char = stripped[:3]
                    if stripped.count(docstring_char) >= 2:
                        in_docstring = False
                    continue
                
                if stripped.startswith(('import ', 'from ')):
                    last_import = i + 1
            else:
                if docstring_char and docstring_char in line:
                    in_docstring = False
        
        return last_import
    
    def rollback(self, applied_fix: AppliedFix) -> bool:
        if not applied_fix.backup_path:
            return False
        
        try:
            backup_path = Path(applied_fix.backup_path)
            if backup_path.exists():
                shutil.copy2(backup_path, applied_fix.suggestion.issue.file_path)
                backup_path.unlink()
                return True
        except Exception:
            pass
        
        return False
    
    def rollback_batch(self, batch: FixBatch) -> Dict[str, bool]:
        results = {}
        
        for applied_fix in reversed(batch.fixes):
            if applied_fix.success and applied_fix.backup_path:
                file_path = applied_fix.suggestion.issue.file_path
                if file_path not in results:
                    results[file_path] = self.rollback(applied_fix)
        
        return results
```

### 4. Fix Validation and Testing

Validate that applied fixes don't introduce new issues.

```python
from typing import Callable
import subprocess

@dataclass
class ValidationResult:
    fix: AppliedFix
    passed: bool
    new_issues: List[CodeIssue]
    resolved_issues: List[CodeIssue]
    warnings: List[str]
    test_results: Optional[Dict[str, Any]] = None

class FixValidator:
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.validators: List[Callable] = [
            self._validate_syntax,
            self._validate_imports,
            self._validate_style,
            self._validate_types,
        ]
    
    def validate_fix(self, applied_fix: AppliedFix, 
                     original_issues: List[CodeIssue]) -> ValidationResult:
        file_path = applied_fix.suggestion.issue.file_path
        
        try:
            with open(file_path, 'r') as f:
                content = f.read()
        except Exception as e:
            return ValidationResult(
                fix=applied_fix,
                passed=False,
                new_issues=[],
                resolved_issues=[],
                warnings=[f"Could not read file: {e}"]
            )
        
        new_issues = []
        warnings = []
        
        for validator in self.validators:
            try:
                issues, warns = validator(file_path, content)
                new_issues.extend(issues)
                warnings.extend(warns)
            except Exception as e:
                warnings.append(f"Validator {validator.__name__} failed: {e}")
        
        resolved = self._find_resolved_issues(
            applied_fix.suggestion.issue, 
            original_issues
        )
        
        passed = len(new_issues) == 0
        
        return ValidationResult(
            fix=applied_fix,
            passed=passed,
            new_issues=new_issues,
            resolved_issues=resolved,
            warnings=warnings
        )
    
    def _validate_syntax(self, file_path: str, 
                         content: str) -> Tuple[List[CodeIssue], List[str]]:
        issues = []
        warnings = []
        
        try:
            compile(content, file_path, 'exec')
        except SyntaxError as e:
            issues.append(CodeIssue(
                file_path=file_path,
                line=e.lineno or 1,
                column=e.offset or 0,
                end_line=None,
                end_column=None,
                severity=IssueSeverity.ERROR,
                category=IssueCategory.SYNTAX,
                code="E999",
                message=f"SyntaxError: {e.msg}",
                source="python",
                fixable=False
            ))
        
        return issues, warnings
    
    def _validate_imports(self, file_path: str, 
                          content: str) -> Tuple[List[CodeIssue], List[str]]:
        issues = []
        warnings = []
        
        try:
            result = subprocess.run(
                ['python', '-m', 'pyflakes', file_path],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode != 0:
                for line in result.stdout.split('\n'):
                    if 'imported but unused' in line:
                        match = re.search(r':(\d+):', line)
                        if match:
                            issues.append(CodeIssue(
                                file_path=file_path,
                                line=int(match.group(1)),
                                column=0,
                                end_line=None,
                                end_column=None,
                                severity=IssueSeverity.WARNING,
                                category=IssueCategory.IMPORT,
                                code="F401",
                                message=line.split(':', 2)[-1].strip(),
                                source="pyflakes",
                                fixable=True
                            ))
        except subprocess.TimeoutExpired:
            warnings.append("Import validation timed out")
        except Exception as e:
            warnings.append(f"Import validation failed: {e}")
        
        return issues, warnings
    
    def _validate_style(self, file_path: str, 
                        content: str) -> Tuple[List[CodeIssue], List[str]]:
        issues = []
        warnings = []
        
        try:
            result = subprocess.run(
                ['python', '-m', 'pycodestyle', '--select=E,W', file_path],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            for line in result.stdout.split('\n'):
                if line.strip():
                    match = re.match(
                        r'.*:(\d+):(\d+):\s+(\w+)\s+(.+)', 
                        line
                    )
                    if match:
                        issues.append(CodeIssue(
                            file_path=file_path,
                            line=int(match.group(1)),
                            column=int(match.group(2)),
                            end_line=None,
                            end_column=None,
                            severity=IssueSeverity.WARNING,
                            category=IssueCategory.STYLE,
                            code=match.group(3),
                            message=match.group(4),
                            source="pycodestyle",
                            fixable=True
                        ))
        except subprocess.TimeoutExpired:
            warnings.append("Style validation timed out")
        except Exception as e:
            warnings.append(f"Style validation failed: {e}")
        
        return issues, warnings
    
    def _validate_types(self, file_path: str, 
                        content: str) -> Tuple[List[CodeIssue], List[str]]:
        issues = []
        warnings = []
        
        if not self.config.get('run_type_checker', False):
            return issues, warnings
        
        try:
            result = subprocess.run(
                ['python', '-m', 'mypy', '--no-error-summary', file_path],
                capture_output=True,
                text=True,
                timeout=60
            )
            
            for line in result.stdout.split('\n'):
                if 'error:' in line:
                    match = re.match(r'.*:(\d+):(\d+):\s+error:\s+(.+)', line)
                    if match:
                        issues.append(CodeIssue(
                            file_path=file_path,
                            line=int(match.group(1)),
                            column=int(match.group(2)),
                            end_line=None,
                            end_column=None,
                            severity=IssueSeverity.ERROR,
                            category=IssueCategory.TYPE,
                            code="TYP001",
                            message=match.group(3),
                            source="mypy",
                            fixable=False
                        ))
        except subprocess.TimeoutExpired:
            warnings.append("Type validation timed out")
        except FileNotFoundError:
            warnings.append("mypy not installed, skipping type validation")
        except Exception as e:
            warnings.append(f"Type validation failed: {e}")
        
        return issues, warnings
    
    def _find_resolved_issues(self, fixed_issue: CodeIssue, 
                              original_issues: List[CodeIssue]) -> List[CodeIssue]:
        resolved = []
        
        for issue in original_issues:
            if (issue.file_path == fixed_issue.file_path and
                issue.code == fixed_issue.code and
                issue.line == fixed_issue.line):
                resolved.append(issue)
        
        return resolved
    
    def run_tests(self, test_command: str = None) -> Dict[str, Any]:
        if not test_command:
            test_command = self.config.get('test_command', 'python -m pytest')
        
        try:
            result = subprocess.run(
                test_command.split(),
                capture_output=True,
                text=True,
                timeout=300
            )
            
            return {
                'passed': result.returncode == 0,
                'output': result.stdout,
                'errors': result.stderr,
                'return_code': result.returncode
            }
        except subprocess.TimeoutExpired:
            return {
                'passed': False,
                'output': '',
                'errors': 'Test execution timed out',
                'return_code': -1
            }
        except Exception as e:
            return {
                'passed': False,
                'output': '',
                'errors': str(e),
                'return_code': -1
            }
```

### 5. Fix Report Generation

Generate comprehensive reports of all fixes applied.

```python
from typing import TextIO
import csv

@dataclass
class FixReport:
    report_id: str
    timestamp: str
    total_issues: int
    fixable_issues: int
    fixes_applied: int
    fixes_successful: int
    fixes_failed: int
    files_modified: Set[str]
    issues_by_category: Dict[str, int]
    issues_by_severity: Dict[str, int]
    details: List[Dict[str, Any]]

class ReportGenerator:
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.output_dir = Path(config.get('report_dir', '.fix_reports'))
        self.output_dir.mkdir(exist_ok=True)
    
    def generate_report(self, issues: List[CodeIssue], 
                        fixes: List[AppliedFix],
                        validations: List[ValidationResult]) -> FixReport:
        report_id = hashlib.sha256(
            str(datetime.now()).encode()
        ).hexdigest()[:12]
        timestamp = datetime.now().isoformat()
        
        fixable = sum(1 for i in issues if i.fixable)
        successful = sum(1 for f in fixes if f.success)
        failed = len(fixes) - successful
        
        files_modified = {f.suggestion.issue.file_path for f in fixes if f.success}
        
        by_category = {}
        for issue in issues:
            cat = issue.category.value
            by_category[cat] = by_category.get(cat, 0) + 1
        
        by_severity = {}
        for issue in issues:
            sev = issue.severity.value
            by_severity[sev] = by_severity.get(sev, 0) + 1
        
        details = []
        for fix, validation in zip(fixes, validations):
            details.append({
                'file': fix.suggestion.issue.file_path,
                'line': fix.suggestion.issue.line,
                'code': fix.suggestion.issue.code,
                'message': fix.suggestion.issue.message,
                'fix_type': fix.suggestion.fix_type,
                'description': fix.suggestion.description,
                'success': fix.success,
                'error': fix.error_message,
                'validation_passed': validation.passed,
                'new_issues': len(validation.new_issues),
                'warnings': len(validation.warnings),
                'confidence': fix.suggestion.confidence,
            })
        
        return FixReport(
            report_id=report_id,
            timestamp=timestamp,
            total_issues=len(issues),
            fixable_issues=fixable,
            fixes_applied=len(fixes),
            fixes_successful=successful,
            fixes_failed=failed,
            files_modified=files_modified,
            issues_by_category=by_category,
            issues_by_severity=by_severity,
            details=details
        )
    
    def write_text_report(self, report: FixReport, 
                          output_file: str = None) -> str:
        if not output_file:
            output_file = self.output_dir / f"fix_report_{report.report_id}.txt"
        
        lines = [
            "=" * 80,
            "FIX REPORT",
            "=" * 80,
            f"Report ID: {report.report_id}",
            f"Timestamp: {report.timestamp}",
            "",
            "SUMMARY",
            "-" * 40,
            f"Total Issues Found: {report.total_issues}",
            f"Fixable Issues: {report.fixable_issues}",
            f"Fixes Applied: {report.fixes_applied}",
            f"Successful: {report.fixes_successful}",
            f"Failed: {report.fixes_failed}",
            f"Files Modified: {len(report.files_modified)}",
            "",
            "ISSUES BY CATEGORY",
            "-" * 40,
        ]
        
        for category, count in sorted(report.issues_by_category.items()):
            lines.append(f"  {category}: {count}")
        
        lines.extend([
            "",
            "ISSUES BY SEVERITY",
            "-" * 40,
        ])
        
        for severity, count in sorted(report.issues_by_severity.items()):
            lines.append(f"  {severity}: {count}")
        
        lines.extend([
            "",
            "DETAILED FIX LOG",
            "-" * 40,
        ])
        
        for detail in report.details:
            status = "✓" if detail['success'] else "✗"
            lines.extend([
                f"\n{status} {detail['file']}:{detail['line']}",
                f"  Code: {detail['code']}",
                f"  Issue: {detail['message']}",
                f"  Fix: {detail['description']}",
                f"  Confidence: {detail['confidence']:.0%}",
            ])
            
            if not detail['success']:
                lines.append(f"  Error: {detail['error']}")
            
            if detail['new_issues'] > 0:
                lines.append(f"  ⚠ New issues introduced: {detail['new_issues']}")
        
        lines.extend([
            "",
            "=" * 80,
            "END OF REPORT",
            "=" * 80,
        ])
        
        content = '\n'.join(lines)
        
        with open(output_file, 'w') as f:
            f.write(content)
        
        return str(output_file)
    
    def write_json_report(self, report: FixReport, 
                          output_file: str = None) -> str:
        if not output_file:
            output_file = self.output_dir / f"fix_report_{report.report_id}.json"
        
        report_dict = {
            'report_id': report.report_id,
            'timestamp': report.timestamp,
            'summary': {
                'total_issues': report.total_issues,
                'fixable_issues': report.fixable_issues,
                'fixes_applied': report.fixes_applied,
                'fixes_successful': report.fixes_successful,
                'fixes_failed': report.fixes_failed,
                'files_modified': list(report.files_modified),
            },
            'issues_by_category': report.issues_by_category,
            'issues_by_severity': report.issues_by_severity,
            'details': report.details,
        }
        
        with open(output_file, 'w') as f:
            json.dump(report_dict, f, indent=2)
        
        return str(output_file)
    
    def write_csv_report(self, report: FixReport, 
                         output_file: str = None) -> str:
        if not output_file:
            output_file = self.output_dir / f"fix_report_{report.report_id}.csv"
        
        with open(output_file, 'w', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=[
                'file', 'line', 'code', 'message', 'fix_type',
                'description', 'success', 'error', 'validation_passed',
                'new_issues', 'warnings', 'confidence'
            ])
            writer.writeheader()
            writer.writerows(report.details)
        
        return str(output_file)
    
    def print_summary(self, report: FixReport) -> str:
        lines = [
            "\n" + "=" * 60,
            "FIX SUMMARY",
            "=" * 60,
            f"Total Issues: {report.total_issues}",
            f"Fixes Applied: {report.fixes_applied}",
            f"Successful: {report.fixes_successful}",
            f"Failed: {report.fixes_failed}",
            f"Files Modified: {len(report.files_modified)}",
            "=" * 60 + "\n",
        ]
        return '\n'.join(lines)
```

---

## Common Fix Patterns

### Import Organization

#### Unused Imports (F401)

```python
def fix_unused_import(file_path: str, line: int, import_name: str) -> str:
    with open(file_path, 'r') as f:
        lines = f.readlines()
    
    import_line = lines[line - 1]
    
    from_match = re.match(
        r'(from\s+[\w.]+\s+import\s+)(.+)', 
        import_line
    )
    
    if from_match:
        imports = [i.strip() for i in from_match.group(2).split(',')]
        imports = [i for i in imports if i != import_name]
        
        if imports:
            new_line = from_match.group(1) + ', '.join(imports) + '\n'
            lines[line - 1] = new_line
        else:
            lines.pop(line - 1)
    else:
        if re.match(rf'import\s+{import_name}', import_line):
            lines.pop(line - 1)
    
    with open(file_path, 'w') as f:
        f.writelines(lines)
    
    return file_path
```

#### Missing Imports

```python
def add_missing_import(file_path: str, module: str, 
                       name: str = None) -> str:
    with open(file_path, 'r') as f:
        lines = f.readlines()
    
    if name:
        import_statement = f"from {module} import {name}\n"
    else:
        import_statement = f"import {module}\n"
    
    insert_pos = 0
    for i, line in enumerate(lines):
        if line.strip().startswith(('import ', 'from ')):
            insert_pos = i + 1
        elif line.strip() and not line.strip().startswith('#'):
            break
    
    lines.insert(insert_pos, import_statement)
    
    with open(file_path, 'w') as f:
        f.writelines(lines)
    
    return file_path
```

#### Import Order (I001)

```python
def fix_import_order(file_path: str) -> str:
    with open(file_path, 'r') as f:
        content = f.read()
    
    import_pattern = re.compile(
        r'^((?:from\s+[\w.]+\s+import\s+.*|import\s+.*)\n)+',
        re.MULTILINE
    )
    
    match = import_pattern.search(content)
    if not match:
        return file_path
    
    import_block = match.group(0)
    import_lines = import_block.strip().split('\n')
    
    stdlib = []
    third_party = []
    local = []
    
    stdlib_modules = {'os', 'sys', 're', 'json', 'datetime', 'typing', 
                      'collections', 'itertools', 'functools', 'pathlib'}
    
    for line in import_lines:
        line = line.strip()
        if not line:
            continue
        
        module = extract_module_name(line)
        
        if module in stdlib_modules:
            stdlib.append(line)
        elif module.startswith('.'):
            local.append(line)
        else:
            third_party.append(line)
    
    sorted_imports = []
    
    if stdlib:
        sorted_imports.extend(sorted(stdlib))
    if third_party:
        if sorted_imports:
            sorted_imports.append('')
        sorted_imports.extend(sorted(third_party))
    if local:
        if sorted_imports:
            sorted_imports.append('')
        sorted_imports.extend(sorted(local))
    
    new_import_block = '\n'.join(sorted_imports) + '\n'
    
    new_content = content[:match.start()] + new_import_block + content[match.end():]
    
    with open(file_path, 'w') as f:
        f.write(new_content)
    
    return file_path

def extract_module_name(import_line: str) -> str:
    if import_line.startswith('from '):
        match = re.match(r'from\s+([\w.]+)', import_line)
        return match.group(1) if match else ''
    else:
        match = re.match(r'import\s+([\w.]+)', import_line)
        return match.group(1) if match else ''
```

### Code Style Issues

#### Line Length (E501)

```python
def fix_long_line(line: str, max_length: int = 88) -> List[str]:
    if len(line) <= max_length:
        return [line]
    
    indent_match = re.match(r'^(\s+)', line)
    base_indent = indent_match.group(1) if indent_match else ''
    extra_indent = '    '
    
    if '(' in line and ')' in line:
        return split_function_call(line, base_indent, extra_indent, max_length)
    
    if ',' in line:
        return split_comma_list(line, base_indent, extra_indent)
    
    if any(op in line for op in [' and ', ' or ', ' + ', ' - ']):
        return split_binary_op(line, base_indent, extra_indent)
    
    return [line]

def split_function_call(line: str, base_indent: str, 
                        extra_indent: str, max_length: int) -> List[str]:
    match = re.match(r'(\s*)(\w+)\((.*)\)(.*)', line)
    if not match:
        return [line]
    
    indent, func_name, args, rest = match.groups()
    arg_list = [a.strip() for a in args.split(',')]
    
    if len(arg_list) <= 1:
        return [line]
    
    result = [f"{indent}{func_name}("]
    for arg in arg_list:
        result.append(f"{indent}{extra_indent}{arg},")
    result.append(f"{indent}){rest}")
    
    return result
```

#### Trailing Whitespace (W291)

```python
def fix_trailing_whitespace(file_path: str) -> int:
    with open(file_path, 'r') as f:
        lines = f.readlines()
    
    fixed_count = 0
    for i, line in enumerate(lines):
        stripped = line.rstrip()
        if line.rstrip() != line.rstrip(' \t'):
            lines[i] = stripped + '\n' if line.endswith('\n') else stripped
            fixed_count += 1
    
    with open(file_path, 'w') as f:
        f.writelines(lines)
    
    return fixed_count
```

#### Blank Lines (E302, E305)

```python
def fix_blank_lines(file_path: str) -> int:
    with open(file_path, 'r') as f:
        lines = f.readlines()
    
    fixed_count = 0
    new_lines = []
    
    for i, line in enumerate(lines):
        if re.match(r'^(class|def|async\s+def)\s+', line.strip()):
            needed_blanks = 2 if line.strip().startswith('class') else 2
            
            actual_blanks = 0
            for j in range(len(new_lines) - 1, -1, -1):
                if new_lines[j].strip() == '':
                    actual_blanks += 1
                else:
                    break
            
            if actual_blanks < needed_blanks:
                for _ in range(needed_blanks - actual_blanks):
                    new_lines.append('\n')
                    fixed_count += 1
        
        new_lines.append(line)
    
    with open(file_path, 'w') as f:
        f.writelines(new_lines)
    
    return fixed_count
```

### Type Annotation Fixes

```python
def add_type_annotations(file_path: str) -> List[Dict[str, Any]]:
    with open(file_path, 'r') as f:
        content = f.read()
    
    tree = ast.parse(content)
    changes = []
    
    for node in ast.walk(tree):
        if isinstance(node, ast.FunctionDef):
            if not node.returns:
                line = content.split('\n')[node.lineno - 1]
                
                if '->' not in line:
                    return_type = infer_return_type(node, content)
                    new_line = add_return_annotation(line, return_type)
                    changes.append({
                        'line': node.lineno,
                        'original': line,
                        'fixed': new_line,
                        'type': 'return_annotation'
                    })
            
            for arg in node.args.args:
                if arg.annotation is None:
                    param_type = infer_param_type(arg, node, content)
                    if param_type:
                        line = content.split('\n')[node.lineno - 1]
                        new_line = add_param_annotation(line, arg.arg, param_type)
                        changes.append({
                            'line': node.lineno,
                            'original': line,
                            'fixed': new_line,
                            'type': 'param_annotation',
                            'param': arg.arg
                        })
    
    return changes

def infer_return_type(node: ast.FunctionDef, content: str) -> str:
    has_return = False
    return_value = None
    
    for child in ast.walk(node):
        if isinstance(child, ast.Return) and child.value:
            has_return = True
            return_value = child.value
            
            if isinstance(return_value, ast.Constant):
                if isinstance(return_value.value, str):
                    return 'str'
                elif isinstance(return_value.value, int):
                    return 'int'
                elif isinstance(return_value.value, bool):
                    return 'bool'
                elif return_value.value is None:
                    return 'None'
    
    if not has_return or return_value is None:
        return 'None'
    
    return 'Any'

def add_return_annotation(line: str, return_type: str) -> str:
    line = line.rstrip()
    if line.endswith(':'):
        return line[:-1] + f' -> {return_type}:'
    return line + f' -> {return_type}'
```

### Variable Naming Fixes

```python
def fix_variable_naming(file_path: str, old_name: str, 
                        new_name: str, scope_start: int,
                        scope_end: int) -> int:
    with open(file_path, 'r') as f:
        lines = f.readlines()
    
    changes = 0
    for i in range(scope_start - 1, min(scope_end, len(lines))):
        line = lines[i]
        
        pattern = rf'\b{re.escape(old_name)}\b'
        new_line = re.sub(pattern, new_name, line)
        
        if new_line != line:
            lines[i] = new_line
            changes += 1
    
    with open(file_path, 'w') as f:
        f.writelines(lines)
    
    return changes

def convert_to_snake_case(name: str) -> str:
    s1 = re.sub(r'(.)([A-Z][a-z]+)', r'\1_\2', name)
    return re.sub(r'([a-z0-9])([A-Z])', r'\1_\2', s1).lower()

def convert_to_pascal_case(name: str) -> str:
    parts = re.split(r'[_\-\s]+', name)
    return ''.join(word.capitalize() for word in parts if word)
```

### Simple Refactoring

#### Extract Method

```python
def extract_method(file_path: str, start_line: int, end_line: int,
                   method_name: str, params: List[str]) -> str:
    with open(file_path, 'r') as f:
        lines = f.readlines()
    
    extracted = lines[start_line - 1:end_line]
    indent_match = re.match(r'^(\s+)', extracted[0])
    indent = indent_match.group(1) if indent_match else ''
    base_indent = indent[:-4] if len(indent) >= 4 else ''
    
    param_str = ', '.join(params) if params else ''
    
    new_method = [
        f'\n{base_indent}def {method_name}({param_str}):\n',
        *extracted
    ]
    
    call_line = f'{indent}{method_name}({param_str})\n'
    
    new_lines = lines[:start_line - 1] + [call_line] + lines[end_line:]
    
    insert_pos = find_method_insert_position(new_lines, start_line)
    new_lines = new_lines[:insert_pos] + new_method + new_lines[insert_pos:]
    
    with open(file_path, 'w') as f:
        f.writelines(new_lines)
    
    return file_path
```

#### Remove Dead Code

```python
def remove_dead_code(file_path: str) -> List[int]:
    with open(file_path, 'r') as f:
        content = f.read()
    
    tree = ast.parse(content)
    lines_to_remove = []
    
    for node in ast.walk(tree):
        if isinstance(node, ast.Expr):
            if isinstance(node.value, ast.Constant):
                if node.value.value is ...:
                    lines_to_remove.append(node.lineno)
        
        if isinstance(node, ast.If):
            if isinstance(node.test, ast.Constant):
                if node.test.value is False:
                    lines_to_remove.append(node.lineno)
    
    return lines_to_remove
```

---

## Safety Mechanisms and Rollback Capabilities

### Pre-Fix Safety Checks

```python
class SafetyMechanism:
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.checks = [
            self.check_git_status,
            self.check_file_size,
            self.check_syntax_validity,
            self.check_test_status,
            self.check_backup_space,
        ]
    
    def perform_safety_checks(self, file_path: str) -> Tuple[bool, List[str]]:
        warnings = []
        all_passed = True
        
        for check in self.checks:
            try:
                passed, warning = check(file_path)
                if not passed:
                    all_passed = False
                if warning:
                    warnings.append(warning)
            except Exception as e:
                warnings.append(f"Safety check '{check.__name__}' failed: {e}")
                all_passed = False
        
        return all_passed, warnings
    
    def check_git_status(self, file_path: str) -> Tuple[bool, Optional[str]]:
        try:
            result = subprocess.run(
                ['git', 'status', '--porcelain', file_path],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.stdout.strip():
                return True, "File has uncommitted changes"
            return True, None
        except Exception:
            return True, "Could not check git status"
    
    def check_file_size(self, file_path: str) -> Tuple[bool, Optional[str]]:
        max_size = self.config.get('max_file_size', 1024 * 1024)
        
        try:
            size = Path(file_path).stat().st_size
            if size > max_size:
                return False, f"File too large: {size} bytes (max: {max_size})"
            return True, None
        except Exception as e:
            return False, f"Could not check file size: {e}"
    
    def check_syntax_validity(self, file_path: str) -> Tuple[bool, Optional[str]]:
        try:
            with open(file_path, 'r') as f:
                compile(f.read(), file_path, 'exec')
            return True, None
        except SyntaxError as e:
            return False, f"Syntax error: {e}"
    
    def check_test_status(self, file_path: str) -> Tuple[bool, Optional[str]]:
        if not self.config.get('run_tests_before_fix', False):
            return True, None
        
        test_cmd = self.config.get('test_command', 'python -m pytest')
        
        try:
            result = subprocess.run(
                test_cmd.split(),
                capture_output=True,
                text=True,
                timeout=300
            )
            
            if result.returncode != 0:
                return False, "Tests are currently failing"
            return True, None
        except Exception:
            return True, "Could not run tests"
    
    def check_backup_space(self, file_path: str) -> Tuple[bool, Optional[str]]:
        backup_dir = Path(self.config.get('backup_dir', '.fix_backups'))
        
        try:
            backup_dir.mkdir(exist_ok=True)
            
            import shutil
            stat = shutil.disk_usage(backup_dir)
            
            min_space = self.config.get('min_backup_space', 100 * 1024 * 1024)
            
            if stat.free < min_space:
                return False, f"Insufficient disk space: {stat.free} bytes"
            
            return True, None
        except Exception as e:
            return False, f"Could not check backup space: {e}"
```

### Rollback System

```python
class RollbackManager:
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.backup_dir = Path(config.get('backup_dir', '.fix_backups'))
        self.backup_dir.mkdir(exist_ok=True)
        self.manifest_file = self.backup_dir / 'manifest.json'
        self.manifest = self._load_manifest()
    
    def _load_manifest(self) -> Dict[str, Any]:
        if self.manifest_file.exists():
            with open(self.manifest_file, 'r') as f:
                return json.load(f)
        return {'backups': {}}
    
    def _save_manifest(self):
        with open(self.manifest_file, 'w') as f:
            json.dump(self.manifest, f, indent=2)
    
    def create_backup(self, file_path: str, batch_id: str) -> str:
        timestamp = datetime.now().isoformat()
        source = Path(file_path)
        
        backup_name = f"{source.stem}_{batch_id}_{timestamp.replace(':', '-')}{source.suffix}"
        backup_path = self.backup_dir / backup_name
        
        shutil.copy2(source, backup_path)
        
        file_hash = hashlib.sha256(source.read_bytes()).hexdigest()
        
        self.manifest['backups'][str(backup_path)] = {
            'original_file': str(file_path),
            'batch_id': batch_id,
            'timestamp': timestamp,
            'hash': file_hash,
        }
        self._save_manifest()
        
        return str(backup_path)
    
    def rollback_file(self, backup_path: str) -> bool:
        if backup_path not in self.manifest['backups']:
            return False
        
        info = self.manifest['backups'][backup_path]
        original_file = info['original_file']
        
        try:
            backup = Path(backup_path)
            if not backup.exists():
                return False
            
            original = Path(original_file)
            current_hash = hashlib.sha256(original.read_bytes()).hexdigest()
            
            shutil.copy2(backup, original)
            backup.unlink()
            
            del self.manifest['backups'][backup_path]
            self._save_manifest()
            
            return True
        except Exception:
            return False
    
    def rollback_batch(self, batch_id: str) -> Dict[str, bool]:
        results = {}
        
        backups_to_rollback = [
            (path, info) for path, info in self.manifest['backups'].items()
            if info['batch_id'] == batch_id
        ]
        
        for backup_path, info in reversed(backups_to_rollback):
            original_file = info['original_file']
            success = self.rollback_file(backup_path)
            results[original_file] = success
        
        return results
    
    def list_backups(self) -> List[Dict[str, Any]]:
        return [
            {
                'backup_path': path,
                **info
            }
            for path, info in self.manifest['backups'].items()
        ]
    
    def cleanup_old_backups(self, max_age_days: int = 30) -> int:
        cutoff = datetime.now() - timedelta(days=max_age_days)
        removed = 0
        
        to_remove = []
        for backup_path, info in self.manifest['backups'].items():
            timestamp = datetime.fromisoformat(info['timestamp'])
            if timestamp < cutoff:
                to_remove.append(backup_path)
        
        for backup_path in to_remove:
            try:
                Path(backup_path).unlink(missing_ok=True)
                del self.manifest['backups'][backup_path]
                removed += 1
            except Exception:
                pass
        
        self._save_manifest()
        return removed
```

---

## Configuration Options

```python
@dataclass
class AutoFixerConfig:
    enabled: bool = True
    
    max_fixes_per_file: int = 10
    max_fixes_per_run: int = 100
    
    auto_apply_safe_fixes: bool = True
    require_confirmation: bool = True
    confidence_threshold: float = 0.8
    
    create_backups: bool = True
    backup_dir: str = '.fix_backups'
    max_backup_age_days: int = 30
    
    run_validation: bool = True
    run_type_checker: bool = False
    run_tests_after_fix: bool = False
    test_command: str = 'python -m pytest'
    
    fix_categories: Dict[str, bool] = None
    
    ignored_codes: List[str] = None
    ignored_files: List[str] = None
    
    max_file_size: int = 1024 * 1024
    max_line_length: int = 88
    
    report_format: str = 'text'
    report_dir: str = '.fix_reports'
    
    def __post_init__(self):
        if self.fix_categories is None:
            self.fix_categories = {
                'import': True,
                'style': True,
                'type': False,
                'naming': False,
                'refactoring': False,
            }
        
        if self.ignored_codes is None:
            self.ignored_codes = []
        
        if self.ignored_files is None:
            self.ignored_files = [
                '*/migrations/*',
                '*/__pycache__/*',
                '*/venv/*',
                '*/.venv/*',
            ]
    
    @classmethod
    def from_file(cls, config_path: str) -> 'AutoFixerConfig':
        with open(config_path, 'r') as f:
            data = json.load(f)
        return cls(**data)
    
    def to_file(self, config_path: str):
        with open(config_path, 'w') as f:
            json.dump(asdict(self), f, indent=2)
    
    def should_fix_category(self, category: str) -> bool:
        return self.fix_categories.get(category, False)
    
    def should_ignore_code(self, code: str) -> bool:
        return code in self.ignored_codes
    
    def should_ignore_file(self, file_path: str) -> bool:
        for pattern in self.ignored_files:
            if fnmatch.fnmatch(file_path, pattern):
                return True
        return False
```

### Configuration File Example

```json
{
  "enabled": true,
  "max_fixes_per_file": 10,
  "max_fixes_per_run": 100,
  "auto_apply_safe_fixes": true,
  "require_confirmation": true,
  "confidence_threshold": 0.8,
  "create_backups": true,
  "backup_dir": ".fix_backups",
  "max_backup_age_days": 30,
  "run_validation": true,
  "run_type_checker": false,
  "run_tests_after_fix": false,
  "test_command": "python -m pytest -x",
  "fix_categories": {
    "import": true,
    "style": true,
    "type": false,
    "naming": false,
    "refactoring": false
  },
  "ignored_codes": ["E501", "W503"],
  "ignored_files": [
    "*/migrations/*",
    "*/tests/*",
    "*/__pycache__/*"
  ],
  "max_file_size": 1048576,
  "max_line_length": 88,
  "report_format": "text",
  "report_dir": ".fix_reports"
}
```

---

## Integration with Syntax and Type Checkers

### Integration Manager

```python
class CheckerIntegration:
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.checkers = {
            'pyflakes': PyflakesIntegration(config),
            'pycodestyle': PycodestyleIntegration(config),
            'pylint': PylintIntegration(config),
            'mypy': MypyIntegration(config),
            'ruff': RuffIntegration(config),
        }
    
    def run_all_checkers(self, file_path: str) -> List[CodeIssue]:
        all_issues = []
        
        for name, checker in self.checkers.items():
            if checker.is_enabled():
                try:
                    issues = checker.check(file_path)
                    all_issues.extend(issues)
                except Exception as e:
                    logging.warning(f"Checker {name} failed: {e}")
        
        return self._deduplicate_issues(all_issues)
    
    def _deduplicate_issues(self, issues: List[CodeIssue]) -> List[CodeIssue]:
        seen = set()
        unique = []
        
        for issue in issues:
            key = (issue.file_path, issue.line, issue.code)
            if key not in seen:
                seen.add(key)
                unique.append(issue)
        
        return unique

class BaseCheckerIntegration(ABC):
    def __init__(self, config: Dict[str, Any]):
        self.config = config
    
    @abstractmethod
    def is_enabled(self) -> bool:
        pass
    
    @abstractmethod
    def check(self, file_path: str) -> List[CodeIssue]:
        pass
    
    @abstractmethod
    def parse_output(self, output: str, file_path: str) -> List[CodeIssue]:
        pass

class PyflakesIntegration(BaseCheckerIntegration):
    def is_enabled(self) -> bool:
        return self.config.get('use_pyflakes', True)
    
    def check(self, file_path: str) -> List[CodeIssue]:
        try:
            result = subprocess.run(
                ['python', '-m', 'pyflakes', file_path],
                capture_output=True,
                text=True,
                timeout=30
            )
            return self.parse_output(result.stdout, file_path)
        except Exception:
            return []
    
    def parse_output(self, output: str, file_path: str) -> List[CodeIssue]:
        issues = []
        
        for line in output.split('\n'):
            match = re.match(
                r'.*:(\d+):(\d+)\s+(.+)',
                line
            )
            if match:
                line_num = int(match.group(1))
                col = int(match.group(2))
                message = match.group(3)
                
                code = self._get_code_from_message(message)
                
                issues.append(CodeIssue(
                    file_path=file_path,
                    line=line_num,
                    column=col,
                    end_line=None,
                    end_column=None,
                    severity=IssueSeverity.WARNING,
                    category=self._get_category(message),
                    code=code,
                    message=message,
                    source='pyflakes',
                    fixable=self._is_fixable(code)
                ))
        
        return issues
    
    def _get_code_from_message(self, message: str) -> str:
        if 'imported but unused' in message:
            return 'F401'
        elif 'Undefined name' in message:
            return 'F821'
        elif 'redefined' in message:
            return 'F811'
        elif 'duplicate import' in message:
            return 'F811'
        return 'F000'
    
    def _get_category(self, message: str) -> IssueCategory:
        if 'import' in message.lower():
            return IssueCategory.IMPORT
        elif 'undefined' in message.lower():
            return IssueCategory.LOGIC
        return IssueCategory.STYLE
    
    def _is_fixable(self, code: str) -> bool:
        return code in {'F401', 'F811'}

class PycodestyleIntegration(BaseCheckerIntegration):
    def is_enabled(self) -> bool:
        return self.config.get('use_pycodestyle', True)
    
    def check(self, file_path: str) -> List[CodeIssue]:
        try:
            result = subprocess.run(
                ['python', '-m', 'pycodestyle', file_path],
                capture_output=True,
                text=True,
                timeout=30
            )
            return self.parse_output(result.stdout, file_path)
        except Exception:
            return []
    
    def parse_output(self, output: str, file_path: str) -> List[CodeIssue]:
        issues = []
        
        for line in output.split('\n'):
            match = re.match(
                r'.*:(\d+):(\d+):\s+(\w+)\s+(.+)',
                line
            )
            if match:
                issues.append(CodeIssue(
                    file_path=file_path,
                    line=int(match.group(1)),
                    column=int(match.group(2)),
                    end_line=None,
                    end_column=None,
                    severity=IssueSeverity.WARNING,
                    category=IssueCategory.STYLE,
                    code=match.group(3),
                    message=match.group(4),
                    source='pycodestyle',
                    fixable=True
                ))
        
        return issues

class MypyIntegration(BaseCheckerIntegration):
    def is_enabled(self) -> bool:
        return self.config.get('use_mypy', False)
    
    def check(self, file_path: str) -> List[CodeIssue]:
        try:
            result = subprocess.run(
                ['python', '-m', 'mypy', '--no-error-summary', file_path],
                capture_output=True,
                text=True,
                timeout=60
            )
            return self.parse_output(result.stdout, file_path)
        except FileNotFoundError:
            return []
        except Exception:
            return []
    
    def parse_output(self, output: str, file_path: str) -> List[CodeIssue]:
        issues = []
        
        for line in output.split('\n'):
            if 'error:' in line:
                match = re.match(
                    r'.*:(\d+):(\d+):\s+error:\s+(.+)',
                    line
                )
                if match:
                    issues.append(CodeIssue(
                        file_path=file_path,
                        line=int(match.group(1)),
                        column=int(match.group(2)),
                        end_line=None,
                        end_column=None,
                        severity=IssueSeverity.ERROR,
                        category=IssueCategory.TYPE,
                        code='TYP001',
                        message=match.group(3),
                        source='mypy',
                        fixable=False
                    ))
        
        return issues

class RuffIntegration(BaseCheckerIntegration):
    def is_enabled(self) -> bool:
        return self.config.get('use_ruff', False)
    
    def check(self, file_path: str) -> List[CodeIssue]:
        try:
            result = subprocess.run(
                ['ruff', 'check', '--output-format=json', file_path],
                capture_output=True,
                text=True,
                timeout=30
            )
            return self.parse_output(result.stdout, file_path)
        except FileNotFoundError:
            return []
        except Exception:
            return []
    
    def parse_output(self, output: str, file_path: str) -> List[CodeIssue]:
        issues = []
        
        try:
            data = json.loads(output)
            for item in data:
                issues.append(CodeIssue(
                    file_path=item.get('filename', file_path),
                    line=item.get('location', {}).get('row', 1),
                    column=item.get('location', {}).get('column', 0),
                    end_line=item.get('end_location', {}).get('row'),
                    end_column=item.get('end_location', {}).get('column'),
                    severity=IssueSeverity.WARNING,
                    category=self._get_category(item.get('code', '')),
                    code=item.get('code', ''),
                    message=item.get('message', ''),
                    source='ruff',
                    fixable=item.get('fix', {}).get('applicability') is not None
                ))
        except json.JSONDecodeError:
            pass
        
        return issues
    
    def _get_category(self, code: str) -> IssueCategory:
        if code.startswith('F'):
            return IssueCategory.IMPORT
        elif code.startswith('E') or code.startswith('W'):
            return IssueCategory.STYLE
        elif code.startswith('N'):
            return IssueCategory.NAMING
        elif code.startswith('UP'):
            return IssueCategory.REFACTORING
        return IssueCategory.STYLE
```

---

## Complete Usage Example

```python
def run_auto_fixer(file_paths: List[str], config: AutoFixerConfig) -> FixReport:
    identifier = ProblemIdentifier(asdict(config))
    suggestion_engine = FixSuggestionEngine(asdict(config))
    applicator = FixApplicator(asdict(config))
    validator = FixValidator(asdict(config))
    reporter = ReportGenerator(asdict(config))
    integration = CheckerIntegration(asdict(config))
    
    all_issues = []
    for file_path in file_paths:
        if config.should_ignore_file(file_path):
            continue
        
        issues = integration.run_all_checkers(file_path)
        all_issues.extend(issues)
    
    fixable_issues = [
        i for i in all_issues 
        if i.fixable and config.should_fix_category(i.category.value)
        and not config.should_ignore_code(i.code)
    ]
    
    suggestions = []
    for issue in fixable_issues:
        with open(issue.file_path, 'r') as f:
            content = f.read()
        
        file_suggestions = suggestion_engine.generate_suggestions(issue, content)
        suggestions.extend(file_suggestions)
    
    safe_suggestions = [
        s for s in suggestions 
        if s.auto_applicable and s.confidence >= config.confidence_threshold
    ][:config.max_fixes_per_run]
    
    applied_fixes = []
    validations = []
    
    for suggestion in safe_suggestions:
        applied = applicator.apply_fix(suggestion, auto_confirm=True)
        applied_fixes.append(applied)
        
        if applied.success and config.run_validation:
            validation = validator.validate_fix(applied, all_issues)
            validations.append(validation)
            
            if not validation.passed and config.create_backups:
                applicator.rollback(applied)
        else:
            validations.append(ValidationResult(
                fix=applied,
                passed=applied.success,
                new_issues=[],
                resolved_issues=[],
                warnings=[]
            ))
    
    report = reporter.generate_report(all_issues, applied_fixes, validations)
    
    reporter.write_text_report(report)
    reporter.write_json_report(report)
    
    print(reporter.print_summary(report))
    
    return report

if __name__ == '__main__':
    config = AutoFixerConfig(
        auto_apply_safe_fixes=True,
        confidence_threshold=0.85,
        fix_categories={
            'import': True,
            'style': True,
            'type': False,
            'naming': True,
            'refactoring': False,
        }
    )
    
    report = run_auto_fixer(['src/main.py', 'src/utils.py'], config)
```

---

## Summary

The Intelligent Error Fixing Module provides:

1. **Precise Problem Identification**: Accurate detection and categorization of code issues
2. **Multi-Option Fix Suggestions**: Multiple fix alternatives with confidence scores
3. **Safe Auto-Fixing**: Comprehensive safety checks before applying changes
4. **Rollback Capabilities**: Full backup and restore functionality
5. **Fix Validation**: Verification that fixes don't introduce new issues
6. **Detailed Reporting**: Comprehensive reports in multiple formats
7. **Flexible Configuration**: Extensive customization options
8. **Tool Integration**: Seamless integration with popular Python linters and type checkers
