# Report Generation Module

## Overview

This module provides comprehensive report generation capabilities for Python code quality analysis results. It transforms raw error data from syntax checkers, type checkers, and linters into structured, human-readable reports across multiple formats.

### Capabilities

- **Multi-Format Output**: Generate reports in JSON, HTML, Markdown, and plain text formats
- **Structured Data**: Organize errors by severity, file, and error type
- **Visual Dashboards**: Create interactive HTML reports with charts and filtering
- **Customizable Templates**: Support for custom report templates and styling
- **Aggregated Statistics**: Provide summary statistics and trend analysis
- **Actionable Suggestions**: Include fix suggestions and code context in reports

---

## Implementation Guide

### 1. Report Data Structures

#### Core Data Models

```python
from dataclasses import dataclass, field
from typing import List, Dict, Any, Optional
from enum import Enum
from datetime import datetime

class Severity(Enum):
    CRITICAL = "critical"
    ERROR = "error"
    WARNING = "warning"
    INFO = "info"
    CONVENTION = "convention"
    REFACTOR = "refactor"

@dataclass
class ErrorLocation:
    file: str
    line: int
    column: int
    end_line: Optional[int] = None
    end_column: Optional[int] = None

@dataclass
class ErrorDetail:
    location: ErrorLocation
    severity: Severity
    error_type: str
    code: str
    message: str
    suggestion: Optional[str] = None
    context: Optional[str] = None
    tool: str = "unknown"
    fix_available: bool = False
    auto_fixable: bool = False

@dataclass
class FileReport:
    file_path: str
    errors: List[ErrorDetail] = field(default_factory=list)
    lines_of_code: int = 0
    error_count: int = 0
    warning_count: int = 0
    
    def __post_init__(self):
        self.error_count = sum(1 for e in self.errors if e.severity in [Severity.ERROR, Severity.CRITICAL])
        self.warning_count = sum(1 for e in self.errors if e.severity == Severity.WARNING)

@dataclass
class QualityReport:
    project_root: str
    timestamp: datetime
    files_scanned: int
    files_with_errors: int
    total_errors: int
    total_warnings: int
    file_reports: List[FileReport] = field(default_factory=list)
    scan_duration_ms: float = 0.0
    tools_used: List[str] = field(default_factory=list)
    
    @property
    def error_rate(self) -> float:
        if self.files_scanned == 0:
            return 0.0
        return self.total_errors / self.files_scanned
    
    @property
    def pass_rate(self) -> float:
        if self.files_scanned == 0:
            return 100.0
        return (self.files_scanned - self.files_with_errors) / self.files_scanned * 100

@dataclass
class ReportStatistics:
    errors_by_severity: Dict[str, int]
    errors_by_type: Dict[str, int]
    errors_by_file: Dict[str, int]
    errors_by_tool: Dict[str, int]
    top_error_files: List[Dict[str, Any]]
    most_common_errors: List[Dict[str, Any]]
```

### 2. JSON Report Generator

#### Implementation

```python
import json
from pathlib import Path
from typing import Dict, Any

class JSONReportGenerator:
    """Generate structured JSON reports for programmatic consumption."""
    
    def __init__(self, indent: int = 2):
        self.indent = indent
    
    def generate(self, report: QualityReport) -> str:
        """Generate a JSON report from quality analysis results."""
        data = self._build_report_data(report)
        return json.dumps(data, indent=self.indent, default=self._json_serializer)
    
    def generate_to_file(self, report: QualityReport, output_path: Path) -> None:
        """Write JSON report to file."""
        data = self._build_report_data(report)
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=self.indent, default=self._json_serializer)
    
    def _build_report_data(self, report: QualityReport) -> Dict[str, Any]:
        """Build the complete report data structure."""
        return {
            "metadata": {
                "project_root": report.project_root,
                "timestamp": report.timestamp.isoformat(),
                "scan_duration_ms": report.scan_duration_ms,
                "tools_used": report.tools_used,
                "generator": "python-code-quality-checker",
                "version": "1.0.0"
            },
            "summary": {
                "files_scanned": report.files_scanned,
                "files_with_errors": report.files_with_errors,
                "total_errors": report.total_errors,
                "total_warnings": report.total_warnings,
                "error_rate": round(report.error_rate, 4),
                "pass_rate": round(report.pass_rate, 2),
                "status": self._determine_status(report)
            },
            "statistics": self._generate_statistics(report),
            "files": self._build_file_reports(report),
            "errors_by_severity": self._group_by_severity(report),
            "errors_by_type": self._group_by_error_type(report)
        }
    
    def _generate_statistics(self, report: QualityReport) -> Dict[str, Any]:
        """Generate statistical summaries."""
        errors_by_severity = {}
        errors_by_type = {}
        errors_by_tool = {}
        
        for file_report in report.file_reports:
            for error in file_report.errors:
                sev_key = error.severity.value
                errors_by_severity[sev_key] = errors_by_severity.get(sev_key, 0) + 1
                
                type_key = error.error_type
                errors_by_type[type_key] = errors_by_type.get(type_key, 0) + 1
                
                tool_key = error.tool
                errors_by_tool[tool_key] = errors_by_tool.get(tool_key, 0) + 1
        
        top_files = sorted(
            [(fr.file_path, len(fr.errors)) for fr in report.file_reports if fr.errors],
            key=lambda x: x[1],
            reverse=True
        )[:10]
        
        common_errors = sorted(
            errors_by_type.items(),
            key=lambda x: x[1],
            reverse=True
        )[:10]
        
        return {
            "errors_by_severity": errors_by_severity,
            "errors_by_type": errors_by_type,
            "errors_by_tool": errors_by_tool,
            "top_error_files": [{"file": f, "count": c} for f, c in top_files],
            "most_common_errors": [{"type": t, "count": c} for t, c in common_errors]
        }
    
    def _build_file_reports(self, report: QualityReport) -> List[Dict[str, Any]]:
        """Build detailed file reports."""
        files = []
        for file_report in report.file_reports:
            file_data = {
                "path": file_report.file_path,
                "lines_of_code": file_report.lines_of_code,
                "error_count": file_report.error_count,
                "warning_count": file_report.warning_count,
                "errors": [self._error_to_dict(e) for e in file_report.errors]
            }
            files.append(file_data)
        return files
    
    def _error_to_dict(self, error: ErrorDetail) -> Dict[str, Any]:
        """Convert error detail to dictionary."""
        return {
            "location": {
                "file": error.location.file,
                "line": error.location.line,
                "column": error.location.column,
                "end_line": error.location.end_line,
                "end_column": error.location.end_column
            },
            "severity": error.severity.value,
            "type": error.error_type,
            "code": error.code,
            "message": error.message,
            "suggestion": error.suggestion,
            "context": error.context,
            "tool": error.tool,
            "fix_available": error.fix_available,
            "auto_fixable": error.auto_fixable
        }
    
    def _group_by_severity(self, report: QualityReport) -> Dict[str, List[Dict]]:
        """Group errors by severity level."""
        groups = {s.value: [] for s in Severity}
        for file_report in report.file_reports:
            for error in file_report.errors:
                groups[error.severity.value].append(self._error_to_dict(error))
        return groups
    
    def _group_by_error_type(self, report: QualityReport) -> Dict[str, List[Dict]]:
        """Group errors by error type."""
        groups = {}
        for file_report in report.file_reports:
            for error in file_report.errors:
                if error.error_type not in groups:
                    groups[error.error_type] = []
                groups[error.error_type].append(self._error_to_dict(error))
        return groups
    
    def _determine_status(self, report: QualityReport) -> str:
        """Determine overall quality status."""
        if report.total_errors == 0 and report.total_warnings == 0:
            return "excellent"
        elif report.total_errors == 0:
            return "good"
        elif report.error_rate < 0.1:
            return "fair"
        else:
            return "poor"
    
    def _json_serializer(self, obj):
        """Custom JSON serializer for non-standard types."""
        if isinstance(obj, datetime):
            return obj.isoformat()
        if isinstance(obj, Path):
            return str(obj)
        raise TypeError(f"Object of type {type(obj)} is not JSON serializable")
```

### 3. HTML Report Generator

#### Implementation with Styling

```python
from pathlib import Path
from typing import Optional
from datetime import datetime

class HTMLReportGenerator:
    """Generate visual HTML dashboards for quality reports."""
    
    def __init__(self, 
                 theme: str = "light",
                 include_charts: bool = True,
                 custom_css: Optional[str] = None):
        self.theme = theme
        self.include_charts = include_charts
        self.custom_css = custom_css
    
    def generate(self, report: QualityReport) -> str:
        """Generate a complete HTML report."""
        html_parts = [
            self._generate_html_header(report),
            self._generate_summary_section(report),
            self._generate_statistics_section(report),
            self._generate_files_section(report),
            self._generate_error_details_section(report),
            self._generate_html_footer()
        ]
        return '\n'.join(html_parts)
    
    def generate_to_file(self, report: QualityReport, output_path: Path) -> None:
        """Write HTML report to file."""
        html_content = self.generate(report)
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(html_content)
    
    def _generate_html_header(self, report: QualityReport) -> str:
        """Generate HTML header with CSS styling."""
        return f'''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Python Code Quality Report - {report.project_root}</title>
    <style>
        {self._get_css_styles()}
    </style>
</head>
<body class="{self.theme}-theme">
    <div class="container">
        <header class="report-header">
            <h1>Python Code Quality Report</h1>
            <div class="metadata">
                <span class="project">Project: {report.project_root}</span>
                <span class="timestamp">Generated: {report.timestamp.strftime('%Y-%m-%d %H:%M:%S')}</span>
                <span class="duration">Duration: {report.scan_duration_ms:.2f}ms</span>
            </div>
        </header>
'''
    
    def _get_css_styles(self) -> str:
        """Get CSS styles for the report."""
        base_css = '''
        :root {
            --color-critical: #dc3545;
            --color-error: #e74c3c;
            --color-warning: #f39c12;
            --color-info: #3498db;
            --color-success: #27ae60;
            --color-convention: #9b59b6;
            --color-refactor: #1abc9c;
        }
        
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            line-height: 1.6;
            padding: 20px;
            background-color: #f5f5f5;
        }
        
        .dark-theme { background-color: #1a1a2e; color: #eee; }
        
        .container { max-width: 1400px; margin: 0 auto; }
        
        .report-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
        }
        
        .report-header h1 { margin-bottom: 15px; }
        
        .metadata {
            display: flex;
            gap: 20px;
            flex-wrap: wrap;
            font-size: 0.9em;
            opacity: 0.9;
        }
        
        .summary-cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .card {
            background: white;
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            text-align: center;
        }
        
        .card.critical { border-left: 4px solid var(--color-critical); }
        .card.error { border-left: 4px solid var(--color-error); }
        .card.warning { border-left: 4px solid var(--color-warning); }
        .card.success { border-left: 4px solid var(--color-success); }
        
        .card-value {
            font-size: 2.5em;
            font-weight: bold;
            margin: 10px 0;
        }
        
        .card-label { color: #666; font-size: 0.9em; }
        
        .section {
            background: white;
            border-radius: 10px;
            padding: 25px;
            margin-bottom: 20px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .section h2 {
            color: #333;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #eee;
        }
        
        .statistics-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
        }
        
        .stat-box h3 {
            color: #555;
            margin-bottom: 15px;
            font-size: 1.1em;
        }
        
        .stat-list { list-style: none; }
        
        .stat-list li {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            border-bottom: 1px solid #eee;
        }
        
        .stat-list li:last-child { border-bottom: none; }
        
        .stat-count {
            background: #f0f0f0;
            padding: 2px 10px;
            border-radius: 15px;
            font-size: 0.9em;
        }
        
        .files-table {
            width: 100%;
            border-collapse: collapse;
        }
        
        .files-table th, .files-table td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #eee;
        }
        
        .files-table th {
            background: #f8f9fa;
            font-weight: 600;
            color: #555;
        }
        
        .files-table tr:hover { background: #f8f9fa; }
        
        .file-path {
            font-family: 'Monaco', 'Menlo', monospace;
            font-size: 0.9em;
            color: #666;
        }
        
        .error-item {
            background: #fafafa;
            border-left: 4px solid var(--color-warning);
            padding: 15px;
            margin-bottom: 15px;
            border-radius: 0 8px 8px 0;
        }
        
        .error-item.critical { border-left-color: var(--color-critical); }
        .error-item.error { border-left-color: var(--color-error); }
        .error-item.warning { border-left-color: var(--color-warning); }
        .error-item.info { border-left-color: var(--color-info); }
        
        .error-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
        }
        
        .error-location {
            font-family: monospace;
            color: #666;
            font-size: 0.9em;
        }
        
        .error-badge {
            padding: 3px 10px;
            border-radius: 12px;
            font-size: 0.8em;
            font-weight: 600;
            text-transform: uppercase;
        }
        
        .badge-critical { background: var(--color-critical); color: white; }
        .badge-error { background: var(--color-error); color: white; }
        .badge-warning { background: var(--color-warning); color: white; }
        .badge-info { background: var(--color-info); color: white; }
        
        .error-message {
            color: #333;
            margin: 10px 0;
            line-height: 1.5;
        }
        
        .error-suggestion {
            background: #e8f5e9;
            padding: 10px 15px;
            border-radius: 5px;
            font-size: 0.9em;
            color: #2e7d32;
        }
        
        .error-context {
            background: #263238;
            color: #aed581;
            padding: 15px;
            border-radius: 5px;
            font-family: monospace;
            font-size: 0.85em;
            overflow-x: auto;
            margin-top: 10px;
        }
        
        .context-line { display: block; }
        
        .context-line.error-line {
            background: rgba(220, 53, 69, 0.3);
            margin: 0 -15px;
            padding: 0 15px;
        }
        
        .progress-bar {
            height: 8px;
            background: #e0e0e0;
            border-radius: 4px;
            overflow: hidden;
            margin-top: 10px;
        }
        
        .progress-fill {
            height: 100%;
            border-radius: 4px;
            transition: width 0.3s ease;
        }
        
        .footer {
            text-align: center;
            padding: 20px;
            color: #666;
            font-size: 0.9em;
        }
        
        @media (max-width: 768px) {
            .summary-cards { grid-template-columns: repeat(2, 1fr); }
            .statistics-grid { grid-template-columns: 1fr; }
        }
        '''
        
        if self.custom_css:
            base_css += f'\n{self.custom_css}'
        
        return base_css
    
    def _generate_summary_section(self, report: QualityReport) -> str:
        """Generate summary cards section."""
        status_class = "success" if report.total_errors == 0 else "warning" if report.total_errors < 10 else "error"
        
        return f'''
        <section class="summary-cards">
            <div class="card {status_class}">
                <div class="card-label">Files Scanned</div>
                <div class="card-value">{report.files_scanned}</div>
            </div>
            <div class="card error">
                <div class="card-label">Total Errors</div>
                <div class="card-value">{report.total_errors}</div>
            </div>
            <div class="card warning">
                <div class="card-label">Total Warnings</div>
                <div class="card-value">{report.total_warnings}</div>
            </div>
            <div class="card success">
                <div class="card-label">Pass Rate</div>
                <div class="card-value">{report.pass_rate:.1f}%</div>
            </div>
        </section>
'''
    
    def _generate_statistics_section(self, report: QualityReport) -> str:
        """Generate statistics section with charts."""
        stats = self._calculate_statistics(report)
        
        severity_html = self._generate_stat_list("Errors by Severity", stats['by_severity'])
        type_html = self._generate_stat_list("Errors by Type", stats['by_type'][:10])
        tool_html = self._generate_stat_list("Errors by Tool", stats['by_tool'])
        
        return f'''
        <section class="section">
            <h2>Statistics</h2>
            <div class="statistics-grid">
                <div class="stat-box">{severity_html}</div>
                <div class="stat-box">{type_html}</div>
                <div class="stat-box">{tool_html}</div>
            </div>
        </section>
'''
    
    def _generate_stat_list(self, title: str, items: list) -> str:
        """Generate a statistics list."""
        items_html = '\n'.join([
            f'<li><span>{item["name"]}</span><span class="stat-count">{item["count"]}</span></li>'
            for item in items
        ])
        return f'''
            <h3>{title}</h3>
            <ul class="stat-list">
                {items_html}
            </ul>
        '''
    
    def _calculate_statistics(self, report: QualityReport) -> Dict[str, list]:
        """Calculate statistics for the report."""
        by_severity = {}
        by_type = {}
        by_tool = {}
        
        for file_report in report.file_reports:
            for error in file_report.errors:
                sev = error.severity.value
                by_severity[sev] = by_severity.get(sev, 0) + 1
                
                err_type = error.error_type
                by_type[err_type] = by_type.get(err_type, 0) + 1
                
                tool = error.tool
                by_tool[tool] = by_tool.get(tool, 0) + 1
        
        return {
            'by_severity': [{'name': k, 'count': v} for k, v in sorted(by_severity.items(), key=lambda x: -x[1])],
            'by_type': [{'name': k, 'count': v} for k, v in sorted(by_type.items(), key=lambda x: -x[1])],
            'by_tool': [{'name': k, 'count': v} for k, v in sorted(by_tool.items(), key=lambda x: -x[1])]
        }
    
    def _generate_files_section(self, report: QualityReport) -> str:
        """Generate files overview table."""
        rows = []
        for file_report in sorted(report.file_reports, key=lambda x: -len(x.errors)):
            if file_report.errors:
                rows.append(f'''
                <tr>
                    <td class="file-path">{file_report.file_path}</td>
                    <td>{file_report.lines_of_code}</td>
                    <td>{file_report.error_count}</td>
                    <td>{file_report.warning_count}</td>
                    <td>{len(file_report.errors)}</td>
                </tr>
                ''')
        
        return f'''
        <section class="section">
            <h2>Files with Issues</h2>
            <table class="files-table">
                <thead>
                    <tr>
                        <th>File Path</th>
                        <th>Lines</th>
                        <th>Errors</th>
                        <th>Warnings</th>
                        <th>Total</th>
                    </tr>
                </thead>
                <tbody>
                    {''.join(rows)}
                </tbody>
            </table>
        </section>
'''
    
    def _generate_error_details_section(self, report: QualityReport) -> str:
        """Generate detailed error listings."""
        error_items = []
        
        for file_report in sorted(report.file_reports, key=lambda x: x.file_path):
            for error in sorted(file_report.errors, key=lambda x: (x.location.line, x.location.column)):
                error_items.append(self._generate_error_item(error))
        
        return f'''
        <section class="section">
            <h2>Error Details</h2>
            {''.join(error_items)}
        </section>
'''
    
    def _generate_error_item(self, error: ErrorDetail) -> str:
        """Generate a single error item."""
        severity_class = error.severity.value
        badge_class = f'badge-{severity_class}'
        
        suggestion_html = ''
        if error.suggestion:
            suggestion_html = f'''
            <div class="error-suggestion">
                <strong>Suggestion:</strong> {error.suggestion}
            </div>
            '''
        
        context_html = ''
        if error.context:
            context_html = f'''
            <div class="error-context">
                <pre>{error.context}</pre>
            </div>
            '''
        
        return f'''
        <div class="error-item {severity_class}">
            <div class="error-header">
                <span class="error-location">{error.location.file}:{error.location.line}:{error.location.column}</span>
                <span class="error-badge {badge_class}">{error.severity.value}</span>
            </div>
            <div class="error-message">
                <strong>[{error.code}]</strong> {error.message}
                <span style="color: #888; font-size: 0.85em;">(via {error.tool})</span>
            </div>
            {suggestion_html}
            {context_html}
        </div>
        '''
    
    def _generate_html_footer(self) -> str:
        """Generate HTML footer."""
        return '''
    </div>
    <footer class="footer">
        <p>Generated by Python Code Quality Checker</p>
    </footer>
</body>
</html>
'''
```

### 4. Markdown Report Generator

#### Implementation

```python
from pathlib import Path
from typing import Optional

class MarkdownReportGenerator:
    """Generate Markdown reports for documentation integration."""
    
    def __init__(self, 
                 include_toc: bool = True,
                 include_code_blocks: bool = True,
                 max_errors_per_file: int = 50):
        self.include_toc = include_toc
        self.include_code_blocks = include_code_blocks
        self.max_errors_per_file = max_errors_per_file
    
    def generate(self, report: QualityReport) -> str:
        """Generate a complete Markdown report."""
        sections = [
            self._generate_header(report),
            self._generate_summary(report),
            self._generate_statistics(report),
            self._generate_files_overview(report),
            self._generate_error_details(report),
            self._generate_footer(report)
        ]
        
        content = '\n\n'.join(sections)
        
        if self.include_toc:
            toc = self._generate_toc(content)
            content = f'{toc}\n\n{content}'
        
        return content
    
    def generate_to_file(self, report: QualityReport, output_path: Path) -> None:
        """Write Markdown report to file."""
        content = self.generate(report)
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(content)
    
    def _generate_header(self, report: QualityReport) -> str:
        """Generate report header."""
        return f'''# Python Code Quality Report

**Project:** `{report.project_root}`

**Generated:** {report.timestamp.strftime('%Y-%m-%d %H:%M:%S')}

**Duration:** {report.scan_duration_ms:.2f}ms

**Tools Used:** {', '.join(report.tools_used) if report.tools_used else 'N/A'}'''
    
    def _generate_toc(self, content: str) -> str:
        """Generate table of contents."""
        toc_lines = ['## Table of Contents\n']
        
        for line in content.split('\n'):
            if line.startswith('## '):
                title = line[3:].strip()
                anchor = title.lower().replace(' ', '-').replace(':', '')
                toc_lines.append(f'- [{title}](#{anchor})')
        
        return '\n'.join(toc_lines)
    
    def _generate_summary(self, report: QualityReport) -> str:
        """Generate summary section."""
        status_emoji = "✅" if report.total_errors == 0 else "⚠️" if report.total_errors < 10 else "❌"
        
        return f'''## Summary

{status_emoji} **Status:** {"All checks passed!" if report.total_errors == 0 else f"Found {report.total_errors} error(s) and {report.total_warnings} warning(s)"}

| Metric | Value |
|--------|-------|
| Files Scanned | {report.files_scanned} |
| Files with Errors | {report.files_with_errors} |
| Total Errors | {report.total_errors} |
| Total Warnings | {report.total_warnings} |
| Error Rate | {report.error_rate:.4f} errors/file |
| Pass Rate | {report.pass_rate:.1f}% |'''
    
    def _generate_statistics(self, report: QualityReport) -> str:
        """Generate statistics section."""
        stats = self._calculate_statistics(report)
        
        severity_table = self._create_markdown_table('Severity', stats['by_severity'])
        type_table = self._create_markdown_table('Error Type', stats['by_type'][:10])
        tool_table = self._create_markdown_table('Tool', stats['by_tool'])
        
        return f'''## Statistics

### Errors by Severity

{severity_table}

### Top Error Types

{type_table}

### Errors by Tool

{tool_table}'''
    
    def _create_markdown_table(self, label: str, items: list) -> str:
        """Create a markdown table from items."""
        if not items:
            return f'No {label.lower()} data available.'
        
        lines = [f'| {label} | Count |', '|--------|-------|']
        for item in items:
            lines.append(f'| {item["name"]} | {item["count"]} |')
        
        return '\n'.join(lines)
    
    def _calculate_statistics(self, report: QualityReport) -> Dict[str, list]:
        """Calculate statistics."""
        by_severity = {}
        by_type = {}
        by_tool = {}
        
        for file_report in report.file_reports:
            for error in file_report.errors:
                by_severity[error.severity.value] = by_severity.get(error.severity.value, 0) + 1
                by_type[error.error_type] = by_type.get(error.error_type, 0) + 1
                by_tool[error.tool] = by_tool.get(error.tool, 0) + 1
        
        return {
            'by_severity': [{'name': k, 'count': v} for k, v in sorted(by_severity.items(), key=lambda x: -x[1])],
            'by_type': [{'name': k, 'count': v} for k, v in sorted(by_type.items(), key=lambda x: -x[1])],
            'by_tool': [{'name': k, 'count': v} for k, v in sorted(by_tool.items(), key=lambda x: -x[1])]
        }
    
    def _generate_files_overview(self, report: QualityReport) -> str:
        """Generate files overview section."""
        files_with_errors = [f for f in report.file_reports if f.errors]
        
        if not files_with_errors:
            return '''## Files Overview

No files with errors found. ✅'''
        
        lines = ['## Files Overview\n']
        lines.append('| File | Errors | Warnings | Total |')
        lines.append('|------|--------|----------|-------|')
        
        for file_report in sorted(files_with_errors, key=lambda x: -len(x.errors)):
            lines.append(
                f'| `{file_report.file_path}` | '
                f'{file_report.error_count} | '
                f'{file_report.warning_count} | '
                f'{len(file_report.errors)} |'
            )
        
        return '\n'.join(lines)
    
    def _generate_error_details(self, report: QualityReport) -> str:
        """Generate detailed error listings."""
        sections = ['## Error Details\n']
        
        files_with_errors = [f for f in report.file_reports if f.errors]
        
        if not files_with_errors:
            sections.append('No errors to display. ✅')
            return '\n'.join(sections)
        
        for file_report in sorted(files_with_errors, key=lambda x: x.file_path):
            sections.append(f'### {file_report.file_path}\n')
            
            error_count = 0
            for error in sorted(file_report.errors, key=lambda x: (x.location.line, x.location.column)):
                if error_count >= self.max_errors_per_file:
                    sections.append(f'\n_... and {len(file_report.errors) - error_count} more errors_')
                    break
                
                sections.append(self._format_error(error))
                error_count += 1
            
            sections.append('')
        
        return '\n'.join(sections)
    
    def _format_error(self, error: ErrorDetail) -> str:
        """Format a single error for Markdown."""
        severity_emoji = {
            'critical': '🔴',
            'error': '❌',
            'warning': '⚠️',
            'info': 'ℹ️',
            'convention': '📋',
            'refactor': '🔧'
        }.get(error.severity.value, '•')
        
        lines = [
            f'#### {severity_emoji} Line {error.location.line}, Column {error.location.column}',
            '',
            f'**Type:** `{error.error_type}`  ',
            f'**Code:** `{error.code}`  ',
            f'**Severity:** `{error.severity.value}`  ',
            f'**Tool:** `{error.tool}`',
            '',
            f'**Message:** {error.message}'
        ]
        
        if error.suggestion:
            lines.append('')
            lines.append(f'> **💡 Suggestion:** {error.suggestion}')
        
        if error.context and self.include_code_blocks:
            lines.append('')
            lines.append('**Code Context:**')
            lines.append('```python')
            lines.append(error.context)
            lines.append('```')
        
        lines.append('\n---\n')
        
        return '\n'.join(lines)
    
    def _generate_footer(self, report: QualityReport) -> str:
        """Generate report footer."""
        return f'''---

*This report was generated by Python Code Quality Checker v1.0.0*

*Report generated at {report.timestamp.strftime('%Y-%m-%d %H:%M:%S')}*'''
```

### 5. Plain Text Report Generator

#### Implementation for Console Output

```python
from pathlib import Path
from typing import Optional
import shutil

class TextReportGenerator:
    """Generate plain text reports for console output."""
    
    def __init__(self, 
                 use_colors: bool = True,
                 show_context: bool = True,
                 max_line_width: Optional[int] = None):
        self.use_colors = use_colors
        self.show_context = show_context
        self.max_line_width = max_line_width or shutil.get_terminal_size().columns
    
    def generate(self, report: QualityReport) -> str:
        """Generate a plain text report."""
        sections = [
            self._generate_header(report),
            self._generate_summary(report),
            self._generate_statistics(report),
            self._generate_errors(report),
            self._generate_footer(report)
        ]
        return '\n\n'.join(sections)
    
    def generate_to_file(self, report: QualityReport, output_path: Path) -> None:
        """Write text report to file (without colors)."""
        original_colors = self.use_colors
        self.use_colors = False
        content = self.generate(report)
        self.use_colors = original_colors
        
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(content)
    
    def _colorize(self, text: str, color: str) -> str:
        """Apply ANSI color codes if enabled."""
        if not self.use_colors:
            return text
        
        colors = {
            'red': '\033[91m',
            'green': '\033[92m',
            'yellow': '\033[93m',
            'blue': '\033[94m',
            'magenta': '\033[95m',
            'cyan': '\033[96m',
            'white': '\033[97m',
            'bold': '\033[1m',
            'reset': '\033[0m'
        }
        
        return f"{colors.get(color, '')}{text}{colors['reset']}"
    
    def _generate_header(self, report: QualityReport) -> str:
        """Generate report header."""
        border = '=' * min(60, self.max_line_width)
        
        return f'''{border}
{self._colorize('PYTHON CODE QUALITY REPORT', 'bold')}
{border}

Project: {report.project_root}
Generated: {report.timestamp.strftime('%Y-%m-%d %H:%M:%S')}
Duration: {report.scan_duration_ms:.2f}ms
Tools: {', '.join(report.tools_used) if report.tools_used else 'N/A'}'''
    
    def _generate_summary(self, report: QualityReport) -> str:
        """Generate summary section."""
        border = '-' * min(40, self.max_line_width)
        
        status = self._colorize('PASSED', 'green') if report.total_errors == 0 else self._colorize('FAILED', 'red')
        
        return f'''{border}
SUMMARY
{border}

Status: {status}

Files Scanned:      {report.files_scanned:>8}
Files with Errors:  {report.files_with_errors:>8}
Total Errors:       {self._colorize(str(report.total_errors), 'red' if report.total_errors > 0 else 'green'):>8}
Total Warnings:     {self._colorize(str(report.total_warnings), 'yellow' if report.total_warnings > 0 else 'green'):>8}
Pass Rate:          {report.pass_rate:>7.1f}%'''
    
    def _generate_statistics(self, report: QualityReport) -> str:
        """Generate statistics section."""
        stats = self._calculate_statistics(report)
        border = '-' * min(40, self.max_line_width)
        
        lines = [f'{border}', 'STATISTICS', border, '']
        
        if stats['by_severity']:
            lines.append('By Severity:')
            for item in stats['by_severity']:
                color = {'critical': 'red', 'error': 'red', 'warning': 'yellow', 'info': 'blue'}.get(item['name'], 'white')
                lines.append(f"  {self._colorize(item['name'], color):<12} {item['count']:>6}")
            lines.append('')
        
        if stats['by_type'][:5]:
            lines.append('Top Error Types:')
            for item in stats['by_type'][:5]:
                lines.append(f"  {item['name']:<20} {item['count']:>6}")
        
        return '\n'.join(lines)
    
    def _calculate_statistics(self, report: QualityReport) -> Dict[str, list]:
        """Calculate statistics."""
        by_severity = {}
        by_type = {}
        
        for file_report in report.file_reports:
            for error in file_report.errors:
                by_severity[error.severity.value] = by_severity.get(error.severity.value, 0) + 1
                by_type[error.error_type] = by_type.get(error.error_type, 0) + 1
        
        return {
            'by_severity': [{'name': k, 'count': v} for k, v in sorted(by_severity.items(), key=lambda x: -x[1])],
            'by_type': [{'name': k, 'count': v} for k, v in sorted(by_type.items(), key=lambda x: -x[1])]
        }
    
    def _generate_errors(self, report: QualityReport) -> str:
        """Generate error listings."""
        files_with_errors = [f for f in report.file_reports if f.errors]
        
        if not files_with_errors:
            return self._colorize('\nNo errors found! All checks passed.', 'green')
        
        lines = []
        border = '-' * min(60, self.max_line_width)
        
        for file_report in sorted(files_with_errors, key=lambda x: x.file_path):
            lines.append(f'\n{border}')
            lines.append(self._colorize(f'FILE: {file_report.file_path}', 'bold'))
            lines.append(f'{border}\n')
            
            for error in sorted(file_report.errors, key=lambda x: (x.location.line, x.location.column)):
                lines.append(self._format_error(error))
        
        return '\n'.join(lines)
    
    def _format_error(self, error: ErrorDetail) -> str:
        """Format a single error for text output."""
        severity_colors = {
            'critical': 'red',
            'error': 'red',
            'warning': 'yellow',
            'info': 'blue',
            'convention': 'magenta',
            'refactor': 'cyan'
        }
        
        color = severity_colors.get(error.severity.value, 'white')
        
        lines = [
            f'{self._colorize(f"[{error.severity.value.upper()}]", color)} '
            f'{error.location.file}:{error.location.line}:{error.location.column}',
            f'  {error.error_type}: {error.message}',
            f'  Code: {error.code} (via {error.tool})'
        ]
        
        if error.suggestion:
            lines.append(f'  {self._colorize("Suggestion:", "cyan")} {error.suggestion}')
        
        if error.context and self.show_context:
            lines.append('  Context:')
            for context_line in error.context.split('\n')[:5]:
                lines.append(f'    {context_line}')
        
        lines.append('')
        
        return '\n'.join(lines)
    
    def _generate_footer(self, report: QualityReport) -> str:
        """Generate report footer."""
        border = '=' * min(60, self.max_line_width)
        
        return f'''{border}
Report generated by Python Code Quality Checker
{border}'''
```

---

## Report Customization Options

### Configuration Schema

```python
from dataclasses import dataclass
from typing import List, Optional, Dict, Any

@dataclass
class ReportConfig:
    """Configuration for report generation."""
    
    output_formats: List[str] = None
    output_directory: str = './reports'
    filename_prefix: str = 'quality-report'
    
    include_sections: List[str] = None
    exclude_sections: List[str] = None
    
    max_errors_per_file: int = 100
    max_total_errors: int = 1000
    show_context: bool = True
    context_lines: int = 3
    
    severity_threshold: str = 'warning'
    fail_on_errors: bool = True
    
    html_theme: str = 'light'
    html_custom_css: Optional[str] = None
    html_include_charts: bool = True
    
    markdown_include_toc: bool = True
    markdown_include_code_blocks: bool = True
    
    text_use_colors: bool = True
    text_max_width: Optional[int] = None
    
    json_indent: int = 2
    json_include_metadata: bool = True
    
    custom_template_path: Optional[str] = None
    
    def __post_init__(self):
        if self.output_formats is None:
            self.output_formats = ['json', 'html', 'markdown', 'text']
        if self.include_sections is None:
            self.include_sections = ['summary', 'statistics', 'files', 'errors']
        if self.exclude_sections is None:
            self.exclude_sections = []
    
    @classmethod
    def from_dict(cls, config: Dict[str, Any]) -> 'ReportConfig':
        """Create config from dictionary."""
        return cls(
            output_formats=config.get('output_formats'),
            output_directory=config.get('output_directory', './reports'),
            filename_prefix=config.get('filename_prefix', 'quality-report'),
            include_sections=config.get('include_sections'),
            exclude_sections=config.get('exclude_sections'),
            max_errors_per_file=config.get('max_errors_per_file', 100),
            max_total_errors=config.get('max_total_errors', 1000),
            show_context=config.get('show_context', True),
            context_lines=config.get('context_lines', 3),
            severity_threshold=config.get('severity_threshold', 'warning'),
            fail_on_errors=config.get('fail_on_errors', True),
            html_theme=config.get('html_theme', 'light'),
            html_custom_css=config.get('html_custom_css'),
            html_include_charts=config.get('html_include_charts', True),
            markdown_include_toc=config.get('markdown_include_toc', True),
            markdown_include_code_blocks=config.get('markdown_include_code_blocks', True),
            text_use_colors=config.get('text_use_colors', True),
            text_max_width=config.get('text_max_width'),
            json_indent=config.get('json_indent', 2),
            json_include_metadata=config.get('json_include_metadata', True),
            custom_template_path=config.get('custom_template_path')
        )
```

### YAML Configuration Example

```yaml
report_generation:
  output_formats:
    - json
    - html
    - markdown
  output_directory: ./reports
  filename_prefix: quality-report
  
  filtering:
    severity_threshold: warning
    max_errors_per_file: 50
    max_total_errors: 500
  
  display:
    show_context: true
    context_lines: 3
  
  html:
    theme: light
    include_charts: true
    custom_css: |
      .custom-header { background: #custom-color; }
  
  markdown:
    include_toc: true
    include_code_blocks: true
  
  text:
    use_colors: true
    max_width: 120
  
  json:
    indent: 2
    include_metadata: true
```

---

## Template System for Custom Reports

### Template Engine Implementation

```python
from string import Template
from pathlib import Path
from typing import Dict, Any, List

class ReportTemplate:
    """Custom report template system."""
    
    def __init__(self, template_path: Optional[Path] = None):
        self.template_path = template_path
        self.custom_templates: Dict[str, str] = {}
        
        if template_path and template_path.exists():
            self._load_templates(template_path)
    
    def _load_templates(self, template_path: Path) -> None:
        """Load templates from a directory or file."""
        if template_path.is_dir():
            for template_file in template_path.glob('*.template'):
                self._load_template_file(template_file)
        else:
            self._load_template_file(template_path)
    
    def _load_template_file(self, template_file: Path) -> None:
        """Load a single template file."""
        with open(template_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        template_name = template_file.stem
        self.custom_templates[template_name] = content
    
    def render(self, template_name: str, context: Dict[str, Any]) -> str:
        """Render a template with the given context."""
        if template_name in self.custom_templates:
            template_str = self.custom_templates[template_name]
        else:
            template_str = self._get_builtin_template(template_name)
        
        template = Template(template_str)
        return template.safe_substitute(self._prepare_context(context))
    
    def _get_builtin_template(self, template_name: str) -> str:
        """Get a built-in template."""
        builtin_templates = {
            'error_item': '''
[$severity] $file:$line:$column
  Type: $error_type
  Code: $code
  Message: $message
  $suggestion
''',
            'file_summary': '''
File: $file_path
  Errors: $error_count
  Warnings: $warning_count
  Lines: $lines_of_code
''',
            'report_header': '''
================================
$report_title
================================
Project: $project_root
Generated: $timestamp
================================
'''
        }
        return builtin_templates.get(template_name, '')
    
    def _prepare_context(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Prepare context for template rendering."""
        prepared = {}
        for key, value in context.items():
            if value is None:
                prepared[key] = ''
            elif isinstance(value, (list, dict)):
                prepared[key] = str(value)
            else:
                prepared[key] = str(value)
        return prepared
    
    def register_template(self, name: str, template: str) -> None:
        """Register a custom template."""
        self.custom_templates[name] = template
    
    def render_custom_report(self, report: QualityReport, template_name: str) -> str:
        """Render a complete report using a custom template."""
        context = {
            'project_root': report.project_root,
            'timestamp': report.timestamp.isoformat(),
            'files_scanned': report.files_scanned,
            'total_errors': report.total_errors,
            'total_warnings': report.total_warnings,
            'pass_rate': f'{report.pass_rate:.1f}%',
            'report_title': 'Python Code Quality Report'
        }
        
        return self.render(template_name, context)
```

### Custom Template Example

```python
def create_custom_template_example():
    """Example of creating a custom report template."""
    template = ReportTemplate()
    
    template.register_template('custom_summary', '''
╔════════════════════════════════════════════════════════════╗
║              CODE QUALITY REPORT SUMMARY                   ║
╠════════════════════════════════════════════════════════════╣
║ Project:      $project_root
║ Generated:    $timestamp
║ Files:        $files_scanned
║ Errors:       $total_errors
║ Warnings:     $total_warnings
║ Pass Rate:    $pass_rate
╚════════════════════════════════════════════════════════════╝
''')
    
    return template
```

---

## Integration with Other Modules

### Integration with Syntax Checker

```python
def generate_syntax_report(project_root: str, config: ReportConfig = None) -> QualityReport:
    """Generate a report from syntax checking results."""
    from syntax_checker import scan_project_syntax
    
    config = config or ReportConfig()
    syntax_report = scan_project_syntax(project_root)
    
    file_reports = []
    for file_path, errors in syntax_report.errors_by_file.items():
        error_details = [
            ErrorDetail(
                location=ErrorLocation(
                    file=str(err.file_path),
                    line=err.line,
                    column=err.column
                ),
                severity=err.severity,
                error_type=err.error_type,
                code=err.error_type,
                message=err.message,
                suggestion=err.suggestion,
                context=err.context,
                tool='syntax-checker'
            )
            for err in errors
        ]
        
        file_reports.append(FileReport(
            file_path=file_path,
            errors=error_details,
            error_count=len([e for e in error_details if e.severity in [Severity.ERROR, Severity.CRITICAL]]),
            warning_count=len([e for e in error_details if e.severity == Severity.WARNING])
        ))
    
    return QualityReport(
        project_root=project_root,
        timestamp=datetime.now(),
        files_scanned=syntax_report.total_files_scanned,
        files_with_errors=syntax_report.files_with_errors,
        total_errors=syntax_report.total_errors,
        total_warnings=0,
        file_reports=file_reports,
        scan_duration_ms=syntax_report.scan_duration_ms,
        tools_used=['syntax-checker']
    )
```

### Integration with Type Checker

```python
def generate_type_check_report(file_path: str, config: ReportConfig = None) -> QualityReport:
    """Generate a report from type checking results."""
    from type_checker import run_mypy_check
    
    config = config or ReportConfig()
    mypy_result = run_mypy_check(file_path)
    
    error_details = []
    for error in mypy_result.get('errors', []):
        error_details.append(ErrorDetail(
            location=ErrorLocation(
                file=error['file'],
                line=error['line'],
                column=error['column']
            ),
            severity=Severity.ERROR if error['severity'] == 'error' else Severity.WARNING,
            error_type='type-error',
            code=error.get('error_code', 'mypy'),
            message=error['message'],
            tool='mypy'
        ))
    
    file_reports = [FileReport(
        file_path=file_path,
        errors=error_details,
        error_count=len([e for e in error_details if e.severity == Severity.ERROR]),
        warning_count=len([e for e in error_details if e.severity == Severity.WARNING])
    )]
    
    return QualityReport(
        project_root=str(Path(file_path).parent),
        timestamp=datetime.now(),
        files_scanned=1,
        files_with_errors=1 if error_details else 0,
        total_errors=len([e for e in error_details if e.severity == Severity.ERROR]),
        total_warnings=len([e for e in error_details if e.severity == Severity.WARNING]),
        file_reports=file_reports,
        tools_used=['mypy']
    )
```

### Integration with Tool Integration Module

```python
def generate_comprehensive_report(
    project_root: str,
    tools: List[str] = None,
    config: ReportConfig = None
) -> QualityReport:
    """Generate a comprehensive report from multiple tools."""
    from tool_integration import ToolRunner
    
    config = config or ReportConfig()
    tools = tools or ['ruff', 'mypy']
    
    runner = ToolRunner(Path(project_root))
    results = runner.run_all_tools([project_root], tools)
    
    all_errors = []
    for tool_name, tool_result in results.items():
        for issue in tool_result.issues:
            all_errors.append(ErrorDetail(
                location=ErrorLocation(
                    file=issue.file,
                    line=issue.line,
                    column=issue.column,
                    end_line=issue.end_line,
                    end_column=issue.end_column
                ),
                severity=issue.severity,
                error_type=issue.code,
                code=issue.code,
                message=issue.message,
                suggestion=issue.fix_suggestion,
                tool=issue.tool,
                fix_available=issue.fix_available
            ))
    
    errors_by_file = {}
    for error in all_errors:
        file_path = error.location.file
        if file_path not in errors_by_file:
            errors_by_file[file_path] = []
        errors_by_file[file_path].append(error)
    
    file_reports = [
        FileReport(
            file_path=file_path,
            errors=errors,
            error_count=len([e for e in errors if e.severity in [Severity.ERROR, Severity.CRITICAL]]),
            warning_count=len([e for e in errors if e.severity == Severity.WARNING])
        )
        for file_path, errors in errors_by_file.items()
    ]
    
    return QualityReport(
        project_root=project_root,
        timestamp=datetime.now(),
        files_scanned=len(errors_by_file),
        files_with_errors=len([fr for fr in file_reports if fr.errors]),
        total_errors=len([e for e in all_errors if e.severity in [Severity.ERROR, Severity.CRITICAL]]),
        total_warnings=len([e for e in all_errors if e.severity == Severity.WARNING]),
        file_reports=file_reports,
        tools_used=tools
    )
```

### Unified Report Generation Function

```python
def generate_reports(
    report: QualityReport,
    config: ReportConfig = None
) -> Dict[str, Path]:
    """Generate reports in all configured formats."""
    config = config or ReportConfig()
    output_dir = Path(config.output_directory)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    generated_files = {}
    timestamp_str = report.timestamp.strftime('%Y%m%d_%H%M%S')
    
    if 'json' in config.output_formats:
        generator = JSONReportGenerator(indent=config.json_indent)
        output_path = output_dir / f'{config.filename_prefix}_{timestamp_str}.json'
        generator.generate_to_file(report, output_path)
        generated_files['json'] = output_path
    
    if 'html' in config.output_formats:
        generator = HTMLReportGenerator(
            theme=config.html_theme,
            include_charts=config.html_include_charts,
            custom_css=config.html_custom_css
        )
        output_path = output_dir / f'{config.filename_prefix}_{timestamp_str}.html'
        generator.generate_to_file(report, output_path)
        generated_files['html'] = output_path
    
    if 'markdown' in config.output_formats:
        generator = MarkdownReportGenerator(
            include_toc=config.markdown_include_toc,
            include_code_blocks=config.markdown_include_code_blocks,
            max_errors_per_file=config.max_errors_per_file
        )
        output_path = output_dir / f'{config.filename_prefix}_{timestamp_str}.md'
        generator.generate_to_file(report, output_path)
        generated_files['markdown'] = output_path
    
    if 'text' in config.output_formats:
        generator = TextReportGenerator(
            use_colors=config.text_use_colors,
            show_context=config.show_context,
            max_line_width=config.text_max_width
        )
        output_path = output_dir / f'{config.filename_prefix}_{timestamp_str}.txt'
        generator.generate_to_file(report, output_path)
        generated_files['text'] = output_path
    
    return generated_files
```

---

## Code Examples

### Example 1: Generate JSON Report

```python
from datetime import datetime
from pathlib import Path

def generate_json_report_example():
    """Example of generating a JSON report."""
    report = QualityReport(
        project_root='/path/to/project',
        timestamp=datetime.now(),
        files_scanned=10,
        files_with_errors=3,
        total_errors=5,
        total_warnings=2,
        file_reports=[
            FileReport(
                file_path='src/main.py',
                errors=[
                    ErrorDetail(
                        location=ErrorLocation(file='src/main.py', line=10, column=5),
                        severity=Severity.ERROR,
                        error_type='SyntaxError',
                        code='E0001',
                        message='invalid syntax',
                        suggestion='Check for missing parentheses',
                        tool='syntax-checker'
                    )
                ]
            )
        ],
        tools_used=['syntax-checker', 'mypy']
    )
    
    generator = JSONReportGenerator(indent=2)
    json_output = generator.generate(report)
    
    print(json_output)
    
    generator.generate_to_file(report, Path('quality-report.json'))

if __name__ == '__main__':
    generate_json_report_example()
```

### Example 2: Generate HTML Dashboard

```python
def generate_html_dashboard_example():
    """Example of generating an HTML dashboard."""
    report = create_sample_report()
    
    generator = HTMLReportGenerator(
        theme='light',
        include_charts=True,
        custom_css='''
        .custom-header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
        '''
    )
    
    html_output = generator.generate(report)
    
    output_path = Path('reports/quality-dashboard.html')
    output_path.parent.mkdir(parents=True, exist_ok=True)
    generator.generate_to_file(report, output_path)
    
    print(f'HTML report generated: {output_path}')

def create_sample_report() -> QualityReport:
    """Create a sample report for demonstration."""
    return QualityReport(
        project_root='/sample/project',
        timestamp=datetime.now(),
        files_scanned=25,
        files_with_errors=5,
        total_errors=12,
        total_warnings=8,
        file_reports=[
            FileReport(
                file_path='src/utils.py',
                errors=[
                    ErrorDetail(
                        location=ErrorLocation(file='src/utils.py', line=15, column=10),
                        severity=Severity.ERROR,
                        error_type='NameError',
                        code='F821',
                        message="undefined name 'undefined_var'",
                        suggestion="Define the variable before using it",
                        context='   13 | def process():\n   14 |     data = []\n>>>15 |     return undefined_var\n   16 | ',
                        tool='flake8'
                    )
                ],
                lines_of_code=150
            )
        ],
        scan_duration_ms=1523.45,
        tools_used=['ruff', 'mypy', 'flake8']
    )

if __name__ == '__main__':
    generate_html_dashboard_example()
```

### Example 3: Generate Markdown Documentation

```python
def generate_markdown_report_example():
    """Example of generating a Markdown report."""
    report = create_sample_report()
    
    generator = MarkdownReportGenerator(
        include_toc=True,
        include_code_blocks=True,
        max_errors_per_file=20
    )
    
    markdown_output = generator.generate(report)
    
    output_path = Path('docs/quality-report.md')
    output_path.parent.mkdir(parents=True, exist_ok=True)
    generator.generate_to_file(report, output_path)
    
    print(f'Markdown report generated: {output_path}')

if __name__ == '__main__':
    generate_markdown_report_example()
```

### Example 4: Generate Console Output

```python
def generate_console_report_example():
    """Example of generating console-friendly output."""
    report = create_sample_report()
    
    generator = TextReportGenerator(
        use_colors=True,
        show_context=True,
        max_line_width=100
    )
    
    text_output = generator.generate(report)
    print(text_output)

if __name__ == '__main__':
    generate_console_report_example()
```

### Example 5: Multi-Format Report Generation

```python
def generate_multi_format_reports_example():
    """Example of generating reports in multiple formats."""
    report = create_sample_report()
    
    config = ReportConfig(
        output_formats=['json', 'html', 'markdown', 'text'],
        output_directory='./reports',
        filename_prefix='quality-check',
        html_theme='light',
        markdown_include_toc=True,
        text_use_colors=False
    )
    
    generated_files = generate_reports(report, config)
    
    print('Generated reports:')
    for format_name, file_path in generated_files.items():
        print(f'  {format_name}: {file_path}')

if __name__ == '__main__':
    generate_multi_format_reports_example()
```

### Example 6: Custom Template Report

```python
def generate_custom_template_report_example():
    """Example of using custom templates for reports."""
    report = create_sample_report()
    
    template = ReportTemplate()
    
    template.register_template('custom_error', '''
┌─────────────────────────────────────────────────────────────┐
│ ERROR: $error_type                                          │
├─────────────────────────────────────────────────────────────┤
│ Location: $file:$line:$column                               │
│ Code: $code                                                 │
│ Message: $message                                           │
│ Tool: $tool                                                 │
└─────────────────────────────────────────────────────────────┘
''')
    
    for file_report in report.file_reports:
        for error in file_report.errors:
            context = {
                'error_type': error.error_type,
                'file': error.location.file,
                'line': error.location.line,
                'column': error.location.column,
                'code': error.code,
                'message': error.message,
                'tool': error.tool
            }
            output = template.render('custom_error', context)
            print(output)

if __name__ == '__main__':
    generate_custom_template_report_example()
```

---

## Performance Considerations

### Memory Optimization for Large Reports

```python
def generate_large_report_streaming(project_root: str, batch_size: int = 100):
    """Generate reports for large projects using streaming."""
    from syntax_checker import discover_python_files
    
    python_files = discover_python_files(project_root)
    
    for i in range(0, len(python_files), batch_size):
        batch = python_files[i:i + batch_size]
        
        batch_errors = []
        for file_path in batch:
            errors = parse_file_for_syntax_errors(file_path)
            if errors:
                batch_errors.extend(errors)
        
        yield {
            'batch_number': i // batch_size + 1,
            'files_processed': len(batch),
            'errors_found': len(batch_errors),
            'errors': batch_errors[:10]
        }
```

### Caching Generated Reports

```python
import hashlib
import pickle
from functools import lru_cache
from typing import Optional

class ReportCache:
    """Cache for generated reports."""
    
    def __init__(self, cache_dir: Path = None):
        self.cache_dir = cache_dir or Path('.report_cache')
        self.cache_dir.mkdir(exist_ok=True)
    
    def _get_cache_key(self, report: QualityReport) -> str:
        """Generate a cache key for a report."""
        content = f"{report.project_root}{report.timestamp}{report.files_scanned}"
        return hashlib.md5(content.encode()).hexdigest()
    
    def get(self, report: QualityReport) -> Optional[str]:
        """Retrieve cached report if available."""
        cache_key = self._get_cache_key(report)
        cache_file = self.cache_dir / f'{cache_key}.pkl'
        
        if cache_file.exists():
            with open(cache_file, 'rb') as f:
                return pickle.load(f)
        return None
    
    def set(self, report: QualityReport, generated_content: str) -> None:
        """Cache a generated report."""
        cache_key = self._get_cache_key(report)
        cache_file = self.cache_dir / f'{cache_key}.pkl'
        
        with open(cache_file, 'wb') as f:
            pickle.dump(generated_content, f)
    
    def clear(self) -> None:
        """Clear the cache."""
        for cache_file in self.cache_dir.glob('*.pkl'):
            cache_file.unlink()
```

---

## Summary

This module provides comprehensive report generation capabilities:

1. **Multi-Format Support**: JSON, HTML, Markdown, and plain text formats
2. **Structured Data Models**: Consistent data structures across all formats
3. **Visual Dashboards**: Interactive HTML reports with styling and charts
4. **Documentation Integration**: Markdown reports with TOC and code blocks
5. **Console Output**: Colorized, terminal-friendly text reports
6. **Customization**: Extensive configuration options for all formats
7. **Template System**: Custom template support for specialized reports
8. **Module Integration**: Seamless integration with syntax, type, and linter modules
9. **Performance**: Streaming and caching for large projects
10. **Extensibility**: Easy to add new formats and templates
