# Type Error Detection Module

## Overview

This module provides comprehensive static type checking capabilities for Python code, enabling early detection of type-related errors before runtime. It leverages Python's type hint system (PEP 484, PEP 526, and related PEPs) and integrates with industry-standard tools like mypy to deliver robust type analysis.

### Key Capabilities

- **Type Annotation Parsing**: Extract and analyze type hints from function signatures, variable declarations, and class attributes
- **Type Mismatch Detection**: Identify incompatibilities between expected and actual types in assignments, function calls, and return statements
- **Undefined Variable Detection**: Catch references to variables that haven't been defined or properly initialized
- **Type Inference**: Automatically deduce types for expressions without explicit annotations
- **Generic Type Support**: Handle complex types including List, Dict, Optional, Union, and custom generics
- **Integration with mypy**: Leverage mypy's powerful type checking engine for enhanced analysis

---

## Implementation Guide

### 1. Type Annotation Parsing and Analysis

Type annotations in Python can appear in multiple locations. This section covers how to parse and analyze them systematically.

#### Parsing Function Signatures

```python
import inspect
from typing import get_type_hints, get_origin, get_args
import ast

def parse_function_annotations(func):
    """
    Extract type annotations from a function.
    
    Returns:
        dict: Contains 'parameters' and 'return' type information
    """
    hints = get_type_hints(func)
    sig = inspect.signature(func)
    
    result = {
        'parameters': {},
        'return': hints.get('return', None)
    }
    
    for param_name, param in sig.parameters.items():
        param_type = hints.get(param_name, None)
        result['parameters'][param_name] = {
            'type': param_type,
            'default': param.default if param.default is not param.empty else None,
            'kind': str(param.kind)
        }
    
    return result

# Example usage
def example_func(name: str, age: int = 0) -> str:
    return f"{name} is {age} years old"

annotations = parse_function_annotations(example_func)
# annotations['parameters']['name']['type'] -> <class 'str'>
# annotations['return'] -> <class 'str'>
```

#### Parsing Type Hints from Source Code

```python
def parse_type_hints_from_source(source_code: str):
    """
    Parse type hints directly from Python source code using AST.
    
    Useful for analyzing code without importing it.
    """
    tree = ast.parse(source_code)
    
    type_info = {
        'functions': [],
        'classes': [],
        'variables': []
    }
    
    for node in ast.walk(tree):
        if isinstance(node, ast.FunctionDef):
            func_info = {
                'name': node.name,
                'args': [(arg.arg, ast.unparse(arg.annotation) if arg.annotation else None) 
                         for arg in node.args.args],
                'returns': ast.unparse(node.returns) if node.returns else None,
                'line': node.lineno
            }
            type_info['functions'].append(func_info)
        
        elif isinstance(node, ast.AnnAssign):
            # Variable with type annotation: var: Type = value
            var_info = {
                'name': ast.unparse(node.target),
                'type': ast.unparse(node.annotation),
                'line': node.lineno
            }
            type_info['variables'].append(var_info)
        
        elif isinstance(node, ast.ClassDef):
            class_info = {
                'name': node.name,
                'attributes': [],
                'methods': [],
                'line': node.lineno
            }
            for item in node.body:
                if isinstance(item, ast.AnnAssign):
                    class_info['attributes'].append({
                        'name': ast.unparse(item.target),
                        'type': ast.unparse(item.annotation)
                    })
            type_info['classes'].append(class_info)
    
    return type_info
```

### 2. Type Mismatch Detection

Type mismatches occur when an expression's type is incompatible with its expected type.

#### Detecting Assignment Type Mismatches

```python
from typing import get_type_hints, get_origin, get_args, Union
import sys

def is_type_compatible(actual_type, expected_type) -> bool:
    """
    Check if actual_type is compatible with expected_type.
    
    Handles basic types, generics, and Union types.
    """
    if expected_type is None or actual_type is None:
        return True  # No type constraint
    
    # Handle Any type
    if expected_type is Any or actual_type is Any:
        return True
    
    # Handle Union types (including Optional)
    if get_origin(expected_type) is Union:
        return any(is_type_compatible(actual_type, arg) 
                   for arg in get_args(expected_type))
    
    # Handle generic types
    actual_origin = get_origin(actual_type)
    expected_origin = get_origin(expected_type)
    
    if actual_origin and expected_origin:
        if actual_origin != expected_origin:
            return False
        actual_args = get_args(actual_type)
        expected_args = get_args(expected_type)
        if len(actual_args) != len(expected_args):
            return False
        return all(is_type_compatible(a, e) 
                   for a, e in zip(actual_args, expected_args))
    
    # Basic type comparison
    try:
        return issubclass(actual_type, expected_type)
    except TypeError:
        return actual_type == expected_type

def detect_assignment_mismatch(variable_name: str, 
                                expected_type, 
                                actual_type,
                                line_number: int) -> dict:
    """
    Detect and report type mismatch in variable assignment.
    """
    if not is_type_compatible(actual_type, expected_type):
        return {
            'error_type': 'type_mismatch',
            'variable': variable_name,
            'expected': expected_type,
            'actual': actual_type,
            'line': line_number,
            'message': f"Cannot assign {actual_type} to variable '{variable_name}' "
                      f"of type {expected_type}"
        }
    return None
```

#### Detecting Function Call Type Mismatches

```python
def detect_function_call_mismatch(func_name: str,
                                   func_annotations: dict,
                                   call_args: list,
                                   call_kwargs: dict,
                                   line_number: int) -> list:
    """
    Detect type mismatches in function call arguments.
    
    Args:
        func_name: Name of the function being called
        func_annotations: Output from parse_function_annotations
        call_args: List of (type, value) tuples for positional args
        call_kwargs: Dict of {arg_name: (type, value)} for keyword args
        line_number: Source line number
    
    Returns:
        List of type mismatch errors
    """
    errors = []
    params = func_annotations['parameters']
    
    # Check positional arguments
    for i, (actual_type, _) in enumerate(call_args):
        if i < len(list(params.keys())):
            param_name = list(params.keys())[i]
            expected_type = params[param_name]['type']
            
            error = detect_assignment_mismatch(
                param_name, expected_type, actual_type, line_number
            )
            if error:
                error['context'] = f"function call to {func_name}"
                errors.append(error)
    
    # Check keyword arguments
    for arg_name, (actual_type, _) in call_kwargs.items():
        if arg_name in params:
            expected_type = params[arg_name]['type']
            
            error = detect_assignment_mismatch(
                arg_name, expected_type, actual_type, line_number
            )
            if error:
                error['context'] = f"function call to {func_name}"
                errors.append(error)
    
    return errors
```

### 3. Undefined Variable Detection

Detecting undefined variables requires tracking variable scope and definitions.

```python
import ast
from typing import Set, Dict, List

class UndefinedVariableDetector(ast.NodeVisitor):
    """
    AST visitor that detects undefined variable references.
    """
    
    def __init__(self):
        self.errors: List[dict] = []
        self.scopes: List[Set[str]] = [set()]  # Stack of scopes
        self.current_scope: Set[str] = self.scopes[0]
        self.builtins: Set[str] = set(dir(__builtins__)) if isinstance(__builtins__, dict) else set(dir(__builtins__))
    
    def enter_scope(self):
        """Enter a new scope (function, class, comprehension)."""
        new_scope = set()
        self.scopes.append(new_scope)
        self.current_scope = new_scope
    
    def exit_scope(self):
        """Exit current scope."""
        self.scopes.pop()
        self.current_scope = self.scopes[-1] if self.scopes else set()
    
    def define(self, name: str):
        """Mark a variable as defined in current scope."""
        self.current_scope.add(name)
    
    def is_defined(self, name: str) -> bool:
        """Check if variable is defined in any accessible scope."""
        if name in self.builtins:
            return True
        for scope in reversed(self.scopes):
            if name in scope:
                return True
        return False
    
    def visit_FunctionDef(self, node: ast.FunctionDef):
        """Handle function definitions."""
        self.define(node.name)
        self.enter_scope()
        
        # Add parameters to scope
        for arg in node.args.args:
            self.define(arg.arg)
        for arg in node.args.posonlyargs:
            self.define(arg.arg)
        for arg in node.args.kwonlyargs:
            self.define(arg.arg)
        if node.args.vararg:
            self.define(node.args.vararg.arg)
        if node.args.kwarg:
            self.define(node.args.kwarg.arg)
        
        self.generic_visit(node)
        self.exit_scope()
    
    def visit_ClassDef(self, node: ast.ClassDef):
        """Handle class definitions."""
        self.define(node.name)
        self.enter_scope()
        self.generic_visit(node)
        self.exit_scope()
    
    def visit_Name(self, node: ast.Name):
        """Handle variable references."""
        if isinstance(node.ctx, ast.Store):
            # Variable is being assigned
            self.define(node.id)
        elif isinstance(node.ctx, ast.Load):
            # Variable is being read
            if not self.is_defined(node.id):
                self.errors.append({
                    'error_type': 'undefined_variable',
                    'variable': node.id,
                    'line': node.lineno,
                    'col': node.col_offset,
                    'message': f"Undefined variable '{node.id}'"
                })
        self.generic_visit(node)
    
    def visit_Import(self, node: ast.Import):
        """Handle import statements."""
        for alias in node.names:
            name = alias.asname if alias.asname else alias.name
            self.define(name.split('.')[0])
    
    def visit_ImportFrom(self, node: ast.ImportFrom):
        """Handle from ... import statements."""
        for alias in node.names:
            name = alias.asname if alias.asname else alias.name
            self.define(name)
    
    def visit_For(self, node: ast.For):
        """Handle for loops - target variable is defined."""
        self.visit(node.iter)
        self.visit(node.target)
        for stmt in node.body:
            self.visit(stmt)
        for stmt in node.orelse:
            self.visit(stmt)
    
    def visit_comprehension(self, node: ast.comprehension):
        """Handle comprehension scopes."""
        self.enter_scope()
        self.visit(node.iter)
        self.visit(node.target)
        for if_ in node.ifs:
            self.visit(if_)
        self.exit_scope()

def detect_undefined_variables(source_code: str) -> List[dict]:
    """
    Analyze source code and detect undefined variable references.
    
    Returns:
        List of error dictionaries with variable name, line, and message
    """
    try:
        tree = ast.parse(source_code)
        detector = UndefinedVariableDetector()
        detector.visit(tree)
        return detector.errors
    except SyntaxError as e:
        return [{
            'error_type': 'syntax_error',
            'message': str(e),
            'line': e.lineno
        }]
```

### 4. Type Inference Support

Type inference deduces types for expressions without explicit annotations.

```python
import ast
from typing import Any, Dict, Optional, Type

class TypeInferencer(ast.NodeVisitor):
    """
    Infer types for expressions based on context and operations.
    """
    
    def __init__(self):
        self.type_map: Dict[str, Type] = {}
        self.current_function_return_types: Dict[str, set] = {}
    
    def infer_type(self, node: ast.AST, context: dict = None) -> Optional[Type]:
        """
        Infer the type of an AST node.
        
        Args:
            node: AST node to analyze
            context: Dictionary of variable names to types
        
        Returns:
            Inferred type or None if cannot determine
        """
        if context is None:
            context = {}
        
        if isinstance(node, ast.Constant):
            return type(node.value)
        
        elif isinstance(node, ast.Num):
            return int if isinstance(node.n, int) else float
        
        elif isinstance(node, ast.Str):
            return str
        
        elif isinstance(node, ast.Name):
            return context.get(node.id, self.type_map.get(node.id))
        
        elif isinstance(node, ast.BinOp):
            left_type = self.infer_type(node.left, context)
            right_type = self.infer_type(node.right, context)
            
            # String concatenation
            if left_type == str or right_type == str:
                if isinstance(node.op, ast.Add):
                    return str
            
            # Numeric operations
            if left_type in (int, float) and right_type in (int, float):
                if isinstance(node.op, (ast.Add, ast.Sub, ast.Mult, ast.Div)):
                    return float if float in (left_type, right_type) else int
            
            return None
        
        elif isinstance(node, ast.Compare):
            # Comparisons typically return bool
            return bool
        
        elif isinstance(node, ast.BoolOp):
            return bool
        
        elif isinstance(node, ast.List):
            return list
        
        elif isinstance(node, ast.Dict):
            return dict
        
        elif isinstance(node, ast.Tuple):
            return tuple
        
        elif isinstance(node, ast.Call):
            # Try to infer return type of function call
            if isinstance(node.func, ast.Name):
                func_name = node.func.id
                if func_name in self.type_map:
                    return self.type_map[func_name]
            return None
        
        elif isinstance(node, ast.Subscript):
            # Indexing into list/dict
            container_type = self.infer_type(node.value, context)
            if container_type == list:
                return Any  # Could be any type
            elif container_type == dict:
                return Any
            return None
        
        return None
    
    def visit_AnnAssign(self, node: ast.AnnAssign):
        """Store explicitly annotated types."""
        if isinstance(node.target, ast.Name):
            type_str = ast.unparse(node.annotation)
            self.type_map[node.target.id] = self._parse_type_string(type_str)
        self.generic_visit(node)
    
    def visit_FunctionDef(self, node: ast.FunctionDef):
        """Store function return types."""
        if node.returns:
            return_type = self._parse_type_string(ast.unparse(node.returns))
            self.type_map[node.name] = return_type
        self.generic_visit(node)
    
    def _parse_type_string(self, type_str: str) -> Type:
        """Convert type string to type object."""
        type_map = {
            'int': int,
            'float': float,
            'str': str,
            'bool': bool,
            'list': list,
            'dict': dict,
            'tuple': tuple,
            'set': set,
            'Any': Any,
        }
        return type_map.get(type_str, Any)

def infer_expression_type(code: str, expression: str) -> Optional[Type]:
    """
    Infer the type of an expression in given code context.
    
    Args:
        code: Full source code providing context
        expression: Expression to type-check
    
    Returns:
        Inferred type or None
    """
    try:
        tree = ast.parse(code)
        inferencer = TypeInferencer()
        inferencer.visit(tree)
        
        expr_tree = ast.parse(expression, mode='eval')
        return inferencer.infer_type(expr_tree.body, inferencer.type_map)
    except:
        return None
```

### 5. Generic and Complex Type Handling

Python's typing module provides powerful generic types that require special handling.

```python
from typing import (
    List, Dict, Set, Tuple, Optional, Union, 
    Generic, TypeVar, Any, Callable, Type,
    get_origin, get_args, get_type_hints
)

def analyze_generic_type(type_hint) -> dict:
    """
    Analyze a generic type hint and extract its structure.
    
    Returns:
        Dictionary with origin type and type arguments
    """
    origin = get_origin(type_hint)
    args = get_args(type_hint)
    
    result = {
        'origin': origin,
        'origin_name': getattr(origin, '__name__', str(origin)) if origin else None,
        'args': [],
        'is_optional': False,
        'is_union': False,
        'is_generic': origin is not None
    }
    
    # Check for Optional (Union with None)
    if origin is Union:
        result['is_union'] = True
        result['is_optional'] = type(None) in args
        result['args'] = [analyze_generic_type(arg) for arg in args if arg is not type(None)]
    elif args:
        result['args'] = [analyze_generic_type(arg) for arg in args]
    
    return result

def validate_generic_type_assignment(container_type, item_type, index_type=None) -> dict:
    """
    Validate type compatibility for generic container operations.
    
    Args:
        container_type: The generic container type (e.g., List[int])
        item_type: The type being assigned/retrieved
        index_type: For dict operations, the key type
    
    Returns:
        Validation result with any errors
    """
    analysis = analyze_generic_type(container_type)
    errors = []
    
    if not analysis['is_generic']:
        return {'valid': True, 'errors': []}
    
    origin = analysis['origin']
    
    # List[T] - item should match T
    if origin is list:
        expected_item_type = analysis['args'][0] if analysis['args'] else Any
        if not is_type_compatible(item_type, expected_item_type['origin'] if isinstance(expected_item_type, dict) else expected_item_type):
            errors.append({
                'error': 'list_item_type_mismatch',
                'expected': expected_item_type,
                'actual': item_type
            })
    
    # Dict[K, V] - key and value should match
    elif origin is dict:
        if len(analysis['args']) >= 2:
            expected_key_type = analysis['args'][0]
            expected_value_type = analysis['args'][1]
            
            if index_type and not is_type_compatible(index_type, expected_key_type.get('origin', expected_key_type)):
                errors.append({
                    'error': 'dict_key_type_mismatch',
                    'expected': expected_key_type,
                    'actual': index_type
                })
            
            if not is_type_compatible(item_type, expected_value_type.get('origin', expected_value_type)):
                errors.append({
                    'error': 'dict_value_type_mismatch',
                    'expected': expected_value_type,
                    'actual': item_type
                })
    
    return {
        'valid': len(errors) == 0,
        'errors': errors
    }

# Example: Working with TypeVar and Generic classes
T = TypeVar('T')

class Container(Generic[T]):
    """Example generic class for demonstration."""
    
    def __init__(self, value: T):
        self.value = value
    
    def get(self) -> T:
        return self.value
    
    def set(self, value: T) -> None:
        self.value = value

def extract_typevar_constraints(typevar: TypeVar) -> dict:
    """
    Extract constraints and bounds from a TypeVar.
    """
    return {
        'name': typevar.__name__,
        'constraints': typevar.__constraints__,
        'bound': typevar.__bound__,
        'covariant': typevar.__covariant__,
        'contravariant': typevar.__contravariant__
    }
```

---

## Integration with mypy

Mypy is the industry-standard static type checker for Python. This section covers integration strategies.

### Basic mypy Integration

```python
import subprocess
import json
from typing import List, Dict

def run_mypy_check(file_path: str, 
                   config_file: str = None,
                   strict: bool = False) -> Dict:
    """
    Run mypy on a Python file and parse results.
    
    Args:
        file_path: Path to Python file to check
        config_file: Optional path to mypy config file
        strict: Enable strict mode checking
    
    Returns:
        Dictionary with errors, warnings, and statistics
    """
    cmd = ['mypy', file_path, '--show-error-codes', '--show-column-numbers']
    
    if config_file:
        cmd.extend(['--config-file', config_file])
    
    if strict:
        cmd.append('--strict')
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    return {
        'exit_code': result.returncode,
        'output': result.stdout,
        'errors': parse_mypy_output(result.stdout),
        'success': result.returncode == 0
    }

def parse_mypy_output(output: str) -> List[Dict]:
    """
    Parse mypy output into structured error information.
    
    Output format: file.py:line:column: error: message [error-code]
    """
    errors = []
    
    for line in output.split('\n'):
        if not line.strip():
            continue
        
        # Parse standard mypy output format
        parts = line.split(':', 4)
        if len(parts) >= 5:
            error_info = {
                'file': parts[0].strip(),
                'line': int(parts[1].strip()) if parts[1].strip().isdigit() else 0,
                'column': int(parts[2].strip()) if parts[2].strip().isdigit() else 0,
                'severity': parts[3].strip(),
                'message': parts[4].strip()
            }
            
            # Extract error code if present
            if '[' in error_info['message'] and ']' in error_info['message']:
                msg = error_info['message']
                error_code = msg[msg.rfind('[')+1:msg.rfind(']')]
                error_info['error_code'] = error_code
                error_info['message'] = msg[:msg.rfind('[')].strip()
            
            errors.append(error_info)
    
    return errors
```

### Programmatic mypy Integration

```python
from mypy import api

def run_mypy_programmatically(files: List[str], 
                               options: List[str] = None) -> Dict:
    """
    Run mypy programmatically using mypy.api.
    
    This provides better integration than subprocess calls.
    
    Args:
        files: List of file paths to check
        options: Additional mypy command-line options
    
    Returns:
        Dictionary with results
    """
    if options is None:
        options = []
    
    cmd = files + options + ['--show-error-codes', '--show-column-numbers']
    
    stdout, stderr, exit_code = api.run(cmd)
    
    return {
        'exit_code': exit_code,
        'stdout': stdout,
        'stderr': stderr,
        'errors': parse_mypy_output(stdout),
        'success': exit_code == 0
    }

def get_mypy_type_info(file_path: str) -> Dict:
    """
    Use mypy to get detailed type information for a file.
    
    Requires mypy daemon (dmypy) for efficient repeated checking.
    """
    result = run_mypy_programmatically(
        [file_path],
        ['--no-error-summary', '--no-pretty']
    )
    
    type_info = {
        'functions': {},
        'classes': {},
        'variables': {}
    }
    
    for error in result['errors']:
        error_code = error.get('error_code', '')
        
        # Categorize by error type
        if error_code == 'arg-type':
            # Function argument type mismatch
            pass
        elif error_code == 'assignment':
            # Assignment type mismatch
            pass
        elif error_code == 'name-defined':
            # Undefined name
            pass
    
    return type_info
```

### mypy Configuration Options

```python
def generate_mypy_config(output_path: str = None,
                         strictness: str = 'moderate',
                         custom_options: Dict = None) -> str:
    """
    Generate a mypy.ini configuration file.
    
    Args:
        output_path: Path to write config file (optional)
        strictness: Preset strictness level ('relaxed', 'moderate', 'strict')
        custom_options: Additional custom options
    
    Returns:
        Configuration file content as string
    """
    presets = {
        'relaxed': {
            'ignore_missing_imports': True,
            'no_implicit_optional': False,
            'strict_optional': False,
            'warn_return_any': False,
            'warn_unused_ignores': False,
        },
        'moderate': {
            'ignore_missing_imports': True,
            'no_implicit_optional': True,
            'strict_optional': True,
            'warn_return_any': False,
            'warn_unused_ignores': True,
        },
        'strict': {
            'ignore_missing_imports': False,
            'no_implicit_optional': True,
            'strict_optional': True,
            'warn_return_any': True,
            'warn_unused_ignores': True,
            'disallow_untyped_defs': True,
            'disallow_any_generics': True,
            'check_untyped_defs': True,
        }
    }
    
    options = presets.get(strictness, presets['moderate'])
    
    if custom_options:
        options.update(custom_options)
    
    config_lines = ['[mypy]', 'python_version = 3.9']
    
    for key, value in options.items():
        if isinstance(value, bool):
            config_lines.append(f'{key} = {str(value).lower()}')
        else:
            config_lines.append(f'{key} = {value}')
    
    config_content = '\n'.join(config_lines)
    
    if output_path:
        with open(output_path, 'w') as f:
            f.write(config_content)
    
    return config_content
```

---

## Code Examples

### Example 1: Parse Type Hints from Python Code

```python
from typing import get_type_hints, get_origin, get_args
import inspect

def analyze_module_types(module) -> dict:
    """
    Analyze all type hints in a module.
    
    Returns comprehensive type information for all public members.
    """
    analysis = {
        'functions': {},
        'classes': {},
        'variables': {}
    }
    
    for name, obj in inspect.getmembers(module):
        if name.startswith('_'):
            continue
        
        if inspect.isfunction(obj):
            hints = get_type_hints(obj)
            sig = inspect.signature(obj)
            
            analysis['functions'][name] = {
                'parameters': {
                    param: hints.get(param)
                    for param in sig.parameters
                },
                'return': hints.get('return'),
                'docstring': inspect.getdoc(obj)
            }
        
        elif inspect.isclass(obj):
            class_info = {
                'attributes': {},
                'methods': {},
                'docstring': inspect.getdoc(obj)
            }
            
            for member_name, member in inspect.getmembers(obj):
                if member_name.startswith('_') and not member_name.startswith('__'):
                    continue
                
                if inspect.isfunction(member) or inspect.ismethod(member):
                    try:
                        hints = get_type_hints(member)
                        class_info['methods'][member_name] = {
                            'parameters': hints,
                            'return': hints.get('return')
                        }
                    except:
                        pass
            
            analysis['classes'][name] = class_info
    
    return analysis

# Usage example
if __name__ == '__main__':
    import json
    from typing import List, Dict, Optional
    
    def sample_function(items: List[str], count: int = 10) -> Dict[str, int]:
        """Sample function with type hints."""
        return {item: len(item) for item in items[:count]}
    
    class SampleClass:
        """Sample class with typed attributes."""
        
        def __init__(self, name: str, values: Optional[List[int]] = None):
            self.name = name
            self.values = values or []
        
        def process(self, multiplier: int) -> List[int]:
            return [v * multiplier for v in self.values]
    
    # Analyze the current module
    import sys
    analysis = analyze_module_types(sys.modules[__name__])
    print(json.dumps(analysis, indent=2, default=str))
```

### Example 2: Detect Type Mismatches in Function Calls

```python
from typing import get_type_hints, Any
import ast

class FunctionCallTypeChecker(ast.NodeVisitor):
    """
    AST visitor that checks type mismatches in function calls.
    """
    
    def __init__(self, type_hints: dict):
        self.type_hints = type_hints  # Function name -> type hints
        self.errors = []
    
    def visit_Call(self, node: ast.Call):
        """Check function call arguments against type hints."""
        if isinstance(node.func, ast.Name):
            func_name = node.func.id
            
            if func_name in self.type_hints:
                hints = self.type_hints[func_name]
                params = {k: v for k, v in hints.items() if k != 'return'}
                
                # Check positional arguments
                for i, arg in enumerate(node.args):
                    param_names = list(params.keys())
                    if i < len(param_names):
                        param_name = param_names[i]
                        expected_type = params[param_name]
                        actual_type = self._infer_type(arg)
                        
                        if actual_type and expected_type:
                            if not self._is_compatible(actual_type, expected_type):
                                self.errors.append({
                                    'line': node.lineno,
                                    'function': func_name,
                                    'parameter': param_name,
                                    'expected': expected_type,
                                    'actual': actual_type,
                                    'message': f"Type mismatch in {func_name}(): "
                                             f"parameter '{param_name}' expects {expected_type}, "
                                             f"got {actual_type}"
                                })
        
        self.generic_visit(node)
    
    def _infer_type(self, node: ast.AST) -> type:
        """Infer type of an expression node."""
        if isinstance(node, ast.Constant):
            return type(node.value)
        elif isinstance(node, ast.List):
            return list
        elif isinstance(node, ast.Dict):
            return dict
        elif isinstance(node, ast.Name):
            return Any  # Would need symbol table for precise inference
        return Any
    
    def _is_compatible(self, actual: type, expected: type) -> bool:
        """Check type compatibility."""
        if expected is Any or actual is Any:
            return True
        try:
            return issubclass(actual, expected)
        except TypeError:
            return actual == expected

def check_function_calls(source: str, functions: dict) -> list:
    """
    Check all function calls in source code for type mismatches.
    
    Args:
        source: Python source code
        functions: Dict of function_name -> type_hints
    
    Returns:
        List of type mismatch errors
    """
    tree = ast.parse(source)
    checker = FunctionCallTypeChecker(functions)
    checker.visit(tree)
    return checker.errors

# Example usage
source = '''
def greet(name: str, age: int) -> str:
    return f"Hello {name}, you are {age}"

# These calls will be checked:
greet("Alice", 30)      # OK
greet("Bob", "thirty")  # Error: age expects int, got str
greet(123, 45)          # Error: name expects str, got int
'''

type_hints = {
    'greet': {
        'name': str,
        'age': int,
        'return': str
    }
}

errors = check_function_calls(source, type_hints)
for error in errors:
    print(f"Line {error['line']}: {error['message']}")
```

### Example 3: Identify Undefined Variables

```python
def check_undefined_in_file(file_path: str) -> list:
    """
    Check a Python file for undefined variable references.
    
    Returns list of issues found.
    """
    with open(file_path, 'r') as f:
        source = f.read()
    
    return detect_undefined_variables(source)

# Example with detailed output
def analyze_variable_usage(source: str) -> dict:
    """
    Comprehensive variable usage analysis.
    
    Returns:
        Dictionary with defined variables, used variables, and undefined references
    """
    tree = ast.parse(source)
    
    class VariableAnalyzer(ast.NodeVisitor):
        def __init__(self):
            self.defined = {}  # name -> (line, scope)
            self.used = {}     # name -> [lines]
            self.undefined = []
            self.scope_stack = ['global']
        
        @property
        def current_scope(self):
            return '.'.join(self.scope_stack)
        
        def visit_FunctionDef(self, node):
            self.defined[node.name] = (node.lineno, self.current_scope)
            self.scope_stack.append(node.name)
            
            # Parameters are defined
            for arg in node.args.args:
                self.defined[arg.arg] = (node.lineno, self.current_scope)
            
            self.generic_visit(node)
            self.scope_stack.pop()
        
        def visit_ClassDef(self, node):
            self.defined[node.name] = (node.lineno, self.current_scope)
            self.scope_stack.append(node.name)
            self.generic_visit(node)
            self.scope_stack.pop()
        
        def visit_Name(self, node):
            if isinstance(node.ctx, ast.Store):
                self.defined[node.id] = (node.lineno, self.current_scope)
            elif isinstance(node.ctx, ast.Load):
                if node.id not in self.used:
                    self.used[node.id] = []
                self.used[node.id].append(node.lineno)
                
                # Check if defined
                is_builtin = node.id in dir(__builtins__)
                is_defined = node.id in self.defined
                
                if not is_builtin and not is_defined:
                    self.undefined.append({
                        'name': node.id,
                        'line': node.lineno,
                        'scope': self.current_scope
                    })
            
            self.generic_visit(node)
    
    analyzer = VariableAnalyzer()
    analyzer.visit(tree)
    
    return {
        'defined': analyzer.defined,
        'used': analyzer.used,
        'undefined': analyzer.undefined
    }
```

### Example 4: Handle Generic Types

```python
from typing import List, Dict, Optional, Union, TypeVar, Generic

def validate_list_operations():
    """Demonstrate type checking for list operations."""
    
    # Correct usage
    numbers: List[int] = [1, 2, 3]
    numbers.append(4)  # OK: int matches List[int]
    
    # This would be caught by type checker
    # numbers.append("five")  # Error: str doesn't match int
    
    # Nested generics
    matrix: List[List[int]] = [[1, 2], [3, 4]]
    
    # Type checking nested access
    def get_element(m: List[List[int]], i: int, j: int) -> int:
        return m[i][j]  # Return type is int

def validate_dict_operations():
    """Demonstrate type checking for dict operations."""
    
    # Typed dictionary
    user_ages: Dict[str, int] = {
        "Alice": 30,
        "Bob": 25
    }
    
    # Correct operations
    user_ages["Charlie"] = 35  # OK
    age: int = user_ages["Alice"]  # OK
    
    # These would be caught
    # user_ages[123] = 40  # Error: key should be str
    # user_ages["Dave"] = "forty"  # Error: value should be int

def validate_optional_types():
    """Demonstrate Optional type handling."""
    
    def get_user(id: int) -> Optional[str]:
        """Returns user name or None if not found."""
        users = {1: "Alice", 2: "Bob"}
        return users.get(id)
    
    result = get_user(1)
    
    # Must handle None case
    if result is not None:
        name: str = result  # OK, we've checked for None
        print(f"User: {name}")
    else:
        print("User not found")
    
    # This would be caught
    # name: str = get_user(1)  # Error: Optional[str] not compatible with str

def validate_union_types():
    """Demonstrate Union type handling."""
    
    def process(value: Union[int, str]) -> str:
        """Process int or str and return str."""
        if isinstance(value, int):
            return f"Number: {value}"
        else:
            return f"String: {value}"
    
    result1: str = process(42)      # OK
    result2: str = process("hello") # OK
    
    # This would be caught
    # result3: str = process([1, 2, 3])  # Error: list not in Union

# TypeVar with constraints
T = TypeVar('T', int, float)

def double(value: T) -> T:
    """Double a numeric value."""
    return value * 2

# Usage
result_int: int = double(5)      # OK
result_float: float = double(3.14)  # OK
# result_str: str = double("hi")  # Error: str not in constraints
```

---

## Configuration Options for Type Checking Strictness

### Strictness Levels

```python
TYPE_CHECKING_PRESETS = {
    'minimal': {
        'description': 'Basic type checking with minimal strictness',
        'settings': {
            'check_untyped_defs': False,
            'disallow_untyped_defs': False,
            'disallow_any_generics': False,
            'ignore_missing_imports': True,
            'strict_optional': False,
            'warn_return_any': False,
            'warn_unused_ignores': False,
        }
    },
    
    'standard': {
        'description': 'Standard type checking for most projects',
        'settings': {
            'check_untyped_defs': True,
            'disallow_untyped_defs': False,
            'disallow_any_generics': False,
            'ignore_missing_imports': True,
            'strict_optional': True,
            'warn_return_any': False,
            'warn_unused_ignores': True,
        }
    },
    
    'strict': {
        'description': 'Strict type checking with comprehensive checks',
        'settings': {
            'check_untyped_defs': True,
            'disallow_untyped_defs': True,
            'disallow_any_generics': True,
            'ignore_missing_imports': False,
            'strict_optional': True,
            'warn_return_any': True,
            'warn_unused_ignores': True,
            'disallow_untyped_calls': True,
            'disallow_untyped_decorators': True,
            'no_implicit_optional': True,
        }
    },
    
    'extreme': {
        'description': 'Maximum strictness for critical code',
        'settings': {
            'check_untyped_defs': True,
            'disallow_untyped_defs': True,
            'disallow_any_generics': True,
            'ignore_missing_imports': False,
            'strict_optional': True,
            'warn_return_any': True,
            'warn_unused_ignores': True,
            'disallow_untyped_calls': True,
            'disallow_untyped_decorators': True,
            'no_implicit_optional': True,
            'disallow_any_unimported': True,
            'disallow_any_expr': True,
            'disallow_any_decorated': True,
            'disallow_any_explicit': True,
            'disallow_subclassing_any': True,
        }
    }
}
```

### Configuration File Generator

```python
def create_type_checking_config(
    strictness: str = 'standard',
    output_format: str = 'ini',
    custom_settings: dict = None
) -> str:
    """
    Create a type checking configuration file.
    
    Args:
        strictness: Preset strictness level
        output_format: 'ini' for mypy.ini or 'toml' for pyproject.toml
        custom_settings: Override default settings
    
    Returns:
        Configuration file content
    """
    preset = TYPE_CHECKING_PRESETS.get(strictness, TYPE_CHECKING_PRESETS['standard'])
    settings = preset['settings'].copy()
    
    if custom_settings:
        settings.update(custom_settings)
    
    if output_format == 'toml':
        lines = ['[tool.mypy]']
        for key, value in settings.items():
            if isinstance(value, bool):
                lines.append(f'{key} = {str(value).lower()}')
            else:
                lines.append(f'{key} = "{value}"')
        return '\n'.join(lines)
    
    else:  # ini format
        lines = ['[mypy]', 'python_version = 3.9']
        for key, value in settings.items():
            if isinstance(value, bool):
                lines.append(f'{key} = {str(value).lower()}')
            else:
                lines.append(f'{key} = {value}')
        return '\n'.join(lines)
```

---

## Best Practices for Type Hint Usage

### 1. Use Type Hints for All Public APIs

```python
# Good: Public function with complete type hints
def calculate_average(numbers: List[float]) -> float:
    """Calculate the average of a list of numbers."""
    if not numbers:
        return 0.0
    return sum(numbers) / len(numbers)

# Avoid: Missing type hints on public function
def calculate_average(numbers):  # Type checker can't verify usage
    if not numbers:
        return 0.0
    return sum(numbers) / len(numbers)
```

### 2. Prefer Specific Types Over Generic Types

```python
# Good: Specific type
def get_user_name(user_id: int) -> str:
    ...

# Avoid: Too generic
def get_user_name(user_id: Any) -> Any:
    ...
```

### 3. Use Optional for Values That Can Be None

```python
# Good: Explicit Optional
def find_user(user_id: int) -> Optional[Dict[str, Any]]:
    """Find user by ID. Returns None if not found."""
    ...

# Avoid: Implicit None possibility
def find_user(user_id: int) -> Dict[str, Any]:  # May return None but not indicated
    ...
```

### 4. Use Union for Multiple Possible Types

```python
# Good: Clear union of possible types
def process_input(data: Union[str, bytes, bytearray]) -> str:
    if isinstance(data, bytes):
        return data.decode('utf-8')
    return str(data)

# Modern Python 3.10+ syntax
def process_input(data: str | bytes | bytearray) -> str:
    ...
```

### 5. Use TypeVar for Generic Functions

```python
from typing import TypeVar, Sequence

T = TypeVar('T')

# Good: Preserves input type
def first(items: Sequence[T]) -> T:
    """Return the first item from a sequence."""
    return items[0]

# The return type matches the input type
names: List[str] = ["Alice", "Bob"]
first_name: str = first(names)  # Type checker knows this is str
```

### 6. Use Protocol for Structural Typing

```python
from typing import Protocol

class Drawable(Protocol):
    """Protocol for objects that can be drawn."""
    
    def draw(self) -> None:
        ...

def render(obj: Drawable) -> None:
    """Render any drawable object."""
    obj.draw()

# Any class with a draw() method works, no inheritance needed
class Circle:
    def draw(self) -> None:
        print("Drawing circle")

render(Circle())  # OK - Circle has draw() method
```

### 7. Avoid Any When Possible

```python
# Bad: Using Any defeats the purpose of type checking
def process(data: Any) -> Any:
    return data

# Good: Use more specific types or TypeVar
from typing import TypeVar

T = TypeVar('T')

def process(data: T) -> T:
    return data
```

### 8. Use Type Aliases for Complex Types

```python
from typing import TypeAlias, Dict, List

# Define type aliases for clarity
UserId: TypeAlias = int
UserName: TypeAlias = str
UserDict: TypeAlias = Dict[UserId, UserName]
UserDatabase: TypeAlias = Dict[str, UserDict]

# Usage is clearer
def get_users() -> UserDict:
    return {1: "Alice", 2: "Bob"}
```

### 9. Document Type Constraints with Docstrings

```python
def calculate_discount(
    price: float,
    discount_rate: float,
    min_price: float = 0.0
) -> float:
    """
    Calculate discounted price.
    
    Args:
        price: Original price (must be non-negative)
        discount_rate: Discount rate between 0 and 1
        min_price: Minimum allowed price after discount
    
    Returns:
        Discounted price
    
    Raises:
        ValueError: If price < 0 or discount_rate not in [0, 1]
    """
    if price < 0:
        raise ValueError("Price must be non-negative")
    if not 0 <= discount_rate <= 1:
        raise ValueError("Discount rate must be between 0 and 1")
    
    discounted = price * (1 - discount_rate)
    return max(discounted, min_price)
```

### 10. Use TypedDict for Dictionary Structures

```python
from typing import TypedDict, Required, NotRequired

class User(TypedDict):
    """User data structure."""
    id: int
    name: str
    email: str
    age: NotRequired[int]  # Optional in Python 3.11+

def create_user(data: User) -> None:
    print(f"Creating user {data['name']}")

# Type checker validates structure
create_user({
    'id': 1,
    'name': 'Alice',
    'email': 'alice@example.com'
})
```

---

## Common Type Checking Scenarios and Solutions

### Scenario 1: Third-Party Library Without Type Stubs

```python
# Problem: Third-party library has no type hints
import some_library  # type: ignore

# Solution 1: Add type: ignore comment
result = some_library.function()  # type: ignore

# Solution 2: Create a stub file (.pyi)
# some_library.pyi
def function() -> Any: ...

# Solution 3: Use TYPE_CHECKING block
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    # Type-only imports
    pass
```

### Scenario 2: Dynamic Attribute Access

```python
# Problem: Dynamic attribute access
class Dynamic:
    def __getattr__(self, name: str) -> Any:
        return f"Value of {name}"

# Solution: Use __getattr__ with proper typing
class Dynamic:
    def __getattr__(self, name: str) -> Any:
        return f"Value of {name}"
    
    # Define known attributes explicitly
    known_attr: str
```

### Scenario 3: Callback Functions

```python
from typing import Callable

# Define callback type
EventHandler = Callable[[str, int], bool]

def register_handler(handler: EventHandler) -> None:
    """Register an event handler."""
    result = handler("event", 42)

# Usage
def my_handler(event: str, code: int) -> bool:
    print(f"Event: {event}, Code: {code}")
    return True

register_handler(my_handler)
```

### Scenario 4: Class Methods and Self Types

```python
from typing import TypeVar, Type

T = TypeVar('T', bound='BaseClass')

class BaseClass:
    @classmethod
    def create(cls: Type[T], value: int) -> T:
        """Factory method returning instance of subclass."""
        return cls(value)
    
    def __init__(self, value: int):
        self.value = value

class SubClass(BaseClass):
    pass

# Type checker knows this is SubClass
instance: SubClass = SubClass.create(42)
```

### Scenario 5: Overloaded Functions

```python
from typing import overload, Union

class Processor:
    @overload
    def process(self, data: str) -> str: ...
    
    @overload
    def process(self, data: int) -> int: ...
    
    @overload
    def process(self, data: list) -> list: ...
    
    def process(self, data: Union[str, int, list]) -> Union[str, int, list]:
        """Process data, preserving type."""
        if isinstance(data, str):
            return data.upper()
        elif isinstance(data, int):
            return data * 2
        else:
            return [x * 2 for x in data]

# Type checker knows return type based on input
p = Processor()
result1: str = p.process("hello")  # OK
result2: int = p.process(5)        # OK
result3: list = p.process([1, 2])  # OK
```

### Scenario 6: Context Managers

```python
from typing import ContextManager
from contextlib import contextmanager

@contextmanager
def managed_resource(name: str) -> ContextManager[str]:
    """Context manager that yields a resource."""
    print(f"Acquiring {name}")
    yield name
    print(f"Releasing {name}")

# Usage with type inference
with managed_resource("db") as resource:
    # resource is typed as str
    print(f"Using {resource}")
```

### Scenario 7: Async Functions

```python
from typing import Coroutine, Any
import asyncio

async def fetch_data(url: str) -> dict:
    """Async function returning dict."""
    await asyncio.sleep(1)
    return {"url": url, "data": "..."}

# Type annotation for async function
AsyncFetch = Coroutine[Any, Any, dict]

def schedule_fetch(coro: AsyncFetch) -> None:
    """Schedule an async fetch operation."""
    asyncio.create_task(coro)
```

### Scenario 8: Recursive Types

```python
from typing import List, Union, Dict, Any

# JSON type
JSON = Union[
    None,
    bool,
    int,
    float,
    str,
    List['JSON'],
    Dict[str, 'JSON']
]

def process_json(data: JSON) -> str:
    """Process JSON data recursively."""
    if isinstance(data, dict):
        return "{" + ", ".join(f"{k}: {process_json(v)}" for k, v in data.items()) + "}"
    elif isinstance(data, list):
        return "[" + ", ".join(process_json(item) for item in data) + "]"
    else:
        return str(data)
```

### Scenario 9: Descriptor Protocol

```python
from typing import TypeVar, Generic, Any, Type

T = TypeVar('T')

class TypedProperty(Generic[T]):
    """Descriptor that enforces type checking."""
    
    def __init__(self, name: str, type_: Type[T]):
        self.name = name
        self.type = type_
        self.private_name = f'_{name}'
    
    def __get__(self, obj: Any, objtype: Any = None) -> T:
        if obj is None:
            return self
        return getattr(obj, self.private_name)
    
    def __set__(self, obj: Any, value: T) -> None:
        if not isinstance(value, self.type):
            raise TypeError(f"{self.name} must be {self.type.__name__}")
        setattr(obj, self.private_name, value)

class Person:
    name: TypedProperty[str] = TypedProperty('name', str)
    age: TypedProperty[int] = TypedProperty('age', int)
    
    def __init__(self, name: str, age: int):
        self.name = name
        self.age = age
```

### Scenario 10: Factory Patterns with Type Safety

```python
from typing import TypeVar, Type, Dict, Callable

T = TypeVar('T')

class Factory:
    """Type-safe factory pattern."""
    
    _registry: Dict[str, Type] = {}
    
    @classmethod
    def register(cls, name: str) -> Callable[[Type[T]], Type[T]]:
        """Decorator to register a class."""
        def decorator(klass: Type[T]) -> Type[T]:
            cls._registry[name] = klass
            return klass
        return decorator
    
    @classmethod
    def create(cls, name: str, *args, **kwargs) -> Any:
        """Create an instance by name."""
        if name not in cls._registry:
            raise ValueError(f"Unknown type: {name}")
        return cls._registry[name](*args, **kwargs)

@Factory.register('user')
class User:
    def __init__(self, name: str):
        self.name = name

# Usage
user = Factory.create('user', 'Alice')
```

---

## Summary

This module provides a comprehensive framework for type error detection in Python code:

1. **Type Annotation Parsing**: Extract and analyze type hints from source code using AST and introspection
2. **Type Mismatch Detection**: Identify incompatibilities in assignments, function calls, and return statements
3. **Undefined Variable Detection**: Track variable scopes and catch undefined references
4. **Type Inference**: Automatically deduce types for expressions without explicit annotations
5. **Generic Type Support**: Handle complex types including List, Dict, Optional, Union, and TypeVar
6. **mypy Integration**: Leverage mypy's powerful type checking engine for enhanced analysis
7. **Configurable Strictness**: Multiple preset levels from minimal to extreme type checking
8. **Best Practices**: Guidelines for effective type hint usage
9. **Common Scenarios**: Solutions for typical type checking challenges

By implementing these techniques, you can catch type-related errors early in the development process, improve code documentation, and enhance IDE support for better developer experience.
