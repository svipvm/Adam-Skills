# Auto-Trigger Mechanism Module

## Overview

This module provides automatic code quality scanning capabilities that can be triggered after conversations, file modifications, or scheduled intervals. It enables continuous quality monitoring without manual intervention, ensuring code quality standards are maintained throughout the development workflow.

### Key Capabilities

| Feature | Description | Use Case |
|---------|-------------|----------|
| **Post-Conversation Scan** | Trigger scans after AI-assisted code changes | Validate AI-generated code |
| **File Watch Mode** | Monitor file changes in real-time | Development workflow |
| **Scheduled Scans** | Time-based periodic scanning | CI/CD integration |
| **Event-Based Triggers** | Custom event-driven scanning | IDE integration |
| **Async Execution** | Non-blocking background scans | Performance optimization |

---

## Implementation Guide

### Trigger Condition Configuration

```python
from dataclasses import dataclass, field
from datetime import timedelta
from enum import Enum
from typing import Dict, List, Optional, Callable, Any
from pathlib import Path
import json

class TriggerType(Enum):
    TIME_BASED = "time_based"
    EVENT_BASED = "event_based"
    HYBRID = "hybrid"

class EventType(Enum):
    FILE_SAVE = "file_save"
    FILE_MODIFY = "file_modify"
    CONVERSATION_END = "conversation_end"
    COMMIT_PRE = "commit_pre"
    BRANCH_SWITCH = "branch_switch"
    TEST_COMPLETE = "test_complete"

@dataclass
class TimeBasedConfig:
    interval_seconds: int = 300
    start_delay_seconds: int = 0
    max_consecutive_scans: int = 3
    cooldown_seconds: int = 60
    schedule_cron: Optional[str] = None

@dataclass
class EventBasedConfig:
    events: List[EventType] = field(default_factory=lambda: [EventType.FILE_SAVE])
    debounce_seconds: float = 1.0
    throttle_seconds: float = 5.0
    batch_events: bool = True
    batch_window_seconds: float = 10.0
    file_patterns: List[str] = field(default_factory=lambda: ["*.py"])
    exclude_patterns: List[str] = field(default_factory=lambda: ["venv/*", ".venv/*", "build/*"])

@dataclass
class TriggerConfig:
    trigger_type: TriggerType = TriggerType.EVENT_BASED
    enabled: bool = True
    time_config: Optional[TimeBasedConfig] = None
    event_config: Optional[EventBasedConfig] = None
    min_severity: str = "warning"
    tools: List[str] = field(default_factory=lambda: ["ruff", "mypy"])
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "trigger_type": self.trigger_type.value,
            "enabled": self.enabled,
            "time_config": self.time_config.__dict__ if self.time_config else None,
            "event_config": {
                "events": [e.value for e in self.event_config.events],
                "debounce_seconds": self.event_config.debounce_seconds,
                "throttle_seconds": self.event_config.throttle_seconds,
                "batch_events": self.event_config.batch_events,
                "batch_window_seconds": self.event_config.batch_window_seconds,
                "file_patterns": self.event_config.file_patterns,
                "exclude_patterns": self.event_config.exclude_patterns,
            } if self.event_config else None,
            "min_severity": self.min_severity,
            "tools": self.tools,
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "TriggerConfig":
        config = cls(
            trigger_type=TriggerType(data.get("trigger_type", "event_based")),
            enabled=data.get("enabled", True),
            min_severity=data.get("min_severity", "warning"),
            tools=data.get("tools", ["ruff", "mypy"]),
        )
        
        if data.get("time_config"):
            config.time_config = TimeBasedConfig(**data["time_config"])
        
        if data.get("event_config"):
            event_data = data["event_config"]
            config.event_config = EventBasedConfig(
                events=[EventType(e) for e in event_data.get("events", ["file_save"])],
                debounce_seconds=event_data.get("debounce_seconds", 1.0),
                throttle_seconds=event_data.get("throttle_seconds", 5.0),
                batch_events=event_data.get("batch_events", True),
                batch_window_seconds=event_data.get("batch_window_seconds", 10.0),
                file_patterns=event_data.get("file_patterns", ["*.py"]),
                exclude_patterns=event_data.get("exclude_patterns", ["venv/*"]),
            )
        
        return config

class TriggerConfigManager:
    """Manage trigger configurations with persistence."""
    
    DEFAULT_CONFIG_PATH = ".trae/auto-trigger-config.json"
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.config_path = project_root / self.DEFAULT_CONFIG_PATH
        self._config: Optional[TriggerConfig] = None
    
    def load_config(self) -> TriggerConfig:
        if self._config:
            return self._config
        
        if self.config_path.exists():
            try:
                with open(self.config_path, 'r') as f:
                    data = json.load(f)
                self._config = TriggerConfig.from_dict(data)
            except (json.JSONDecodeError, KeyError):
                self._config = TriggerConfig()
        else:
            self._config = TriggerConfig()
        
        return self._config
    
    def save_config(self, config: TriggerConfig) -> None:
        self._config = config
        self.config_path.parent.mkdir(parents=True, exist_ok=True)
        with open(self.config_path, 'w') as f:
            json.dump(config.to_dict(), f, indent=2)
    
    def update_config(self, **kwargs) -> TriggerConfig:
        config = self.load_config()
        for key, value in kwargs.items():
            if hasattr(config, key):
                setattr(config, key, value)
        self.save_config(config)
        return config
```

---

### Scan Scope Configuration

```python
from dataclasses import dataclass
from pathlib import Path
from typing import List, Set, Optional
import fnmatch
import os

@dataclass
class ScanScope:
    directories: List[str]
    file_patterns: List[str]
    exclude_patterns: List[str]
    follow_symlinks: bool = False
    max_depth: Optional[int] = None
    max_files: int = 1000
    
    def get_files(self, project_root: Path) -> List[Path]:
        files: List[Path] = []
        
        for directory in self.directories:
            dir_path = project_root / directory
            if not dir_path.exists():
                continue
            
            for root, dirs, filenames in os.walk(dir_path, followlinks=self.follow_symlinks):
                root_path = Path(root)
                
                rel_root = root_path.relative_to(project_root)
                if self._should_exclude(rel_root):
                    dirs[:] = []
                    continue
                
                if self.max_depth is not None:
                    depth = len(rel_root.parts)
                    if depth > self.max_depth:
                        dirs[:] = []
                        continue
                
                for filename in filenames:
                    if self._matches_pattern(filename):
                        file_path = root_path / filename
                        rel_file = file_path.relative_to(project_root)
                        if not self._should_exclude(rel_file):
                            files.append(file_path)
                            
                            if len(files) >= self.max_files:
                                return files
        
        return files
    
    def _matches_pattern(self, filename: str) -> bool:
        for pattern in self.file_patterns:
            if fnmatch.fnmatch(filename, pattern):
                return True
        return False
    
    def _should_exclude(self, path: Path) -> bool:
        path_str = str(path)
        for pattern in self.exclude_patterns:
            if fnmatch.fnmatch(path_str, pattern):
                return True
            if fnmatch.fnmatch(path_str, f"{pattern}*"):
                return True
        return False

class ScanScopeManager:
    """Manage scan scope configurations for different scenarios."""
    
    SCOPES = {
        "full_project": ScanScope(
            directories=["."],
            file_patterns=["*.py"],
            exclude_patterns=[
                "venv", ".venv", "env", ".env",
                "build", "dist", "*.egg-info",
                "__pycache__", ".git", ".tox",
                "node_modules", ".mypy_cache",
            ],
            max_files=5000,
        ),
        "source_only": ScanScope(
            directories=["src", "lib"],
            file_patterns=["*.py"],
            exclude_patterns=["__pycache__", "*.egg-info"],
            max_files=2000,
        ),
        "changed_files": ScanScope(
            directories=[],
            file_patterns=["*.py"],
            exclude_patterns=[],
            max_files=100,
        ),
        "tests_only": ScanScope(
            directories=["tests", "test"],
            file_patterns=["*.py"],
            exclude_patterns=["__pycache__"],
            max_files=1000,
        ),
    }
    
    @classmethod
    def get_scope(cls, name: str) -> Optional[ScanScope]:
        return cls.SCOPES.get(name)
    
    @classmethod
    def create_custom_scope(
        cls,
        directories: List[str],
        exclude: Optional[List[str]] = None,
        max_files: int = 1000,
    ) -> ScanScope:
        return ScanScope(
            directories=directories,
            file_patterns=["*.py"],
            exclude_patterns=exclude or ["__pycache__", "*.egg-info"],
            max_files=max_files,
        )
```

---

### Asynchronous Execution Mechanism

```python
import asyncio
import threading
from concurrent.futures import ThreadPoolExecutor, Future
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Dict, List, Optional, Callable, Any
from queue import Queue, Empty
import time
import uuid

class ScanStatus(Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"

@dataclass
class ScanResult:
    scan_id: str
    status: ScanStatus
    started_at: datetime
    completed_at: Optional[datetime] = None
    files_scanned: int = 0
    issues_found: int = 0
    issues: List[Dict[str, Any]] = field(default_factory=list)
    error_message: Optional[str] = None
    execution_time_seconds: float = 0.0
    trigger_source: str = "manual"
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "scan_id": self.scan_id,
            "status": self.status.value,
            "started_at": self.started_at.isoformat(),
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
            "files_scanned": self.files_scanned,
            "issues_found": self.issues_found,
            "issues": self.issues,
            "error_message": self.error_message,
            "execution_time_seconds": self.execution_time_seconds,
            "trigger_source": self.trigger_source,
        }

@dataclass
class ScanTask:
    task_id: str
    scope: ScanScope
    tools: List[str]
    config: Dict[str, Any]
    callback: Optional[Callable[[ScanResult], None]] = None
    priority: int = 0
    created_at: datetime = field(default_factory=datetime.now)

class AsyncScanExecutor:
    """Execute code quality scans asynchronously."""
    
    def __init__(self, project_root: Path, max_workers: int = 4):
        self.project_root = project_root
        self.max_workers = max_workers
        self._executor = ThreadPoolExecutor(max_workers=max_workers)
        self._task_queue: Queue[ScanTask] = Queue()
        self._active_scans: Dict[str, Future] = {}
        self._results: Dict[str, ScanResult] = {}
        self._running = False
        self._worker_thread: Optional[threading.Thread] = None
        self._lock = threading.Lock()
    
    def start(self) -> None:
        if self._running:
            return
        
        self._running = True
        self._worker_thread = threading.Thread(target=self._process_queue, daemon=True)
        self._worker_thread.start()
    
    def stop(self) -> None:
        self._running = False
        if self._worker_thread:
            self._worker_thread.join(timeout=5.0)
        self._executor.shutdown(wait=False)
    
    def submit_scan(
        self,
        scope: ScanScope,
        tools: List[str],
        config: Optional[Dict[str, Any]] = None,
        callback: Optional[Callable[[ScanResult], None]] = None,
        priority: int = 0,
    ) -> str:
        task_id = str(uuid.uuid4())[:8]
        task = ScanTask(
            task_id=task_id,
            scope=scope,
            tools=tools,
            config=config or {},
            callback=callback,
            priority=priority,
        )
        
        with self._lock:
            self._results[task_id] = ScanResult(
                scan_id=task_id,
                status=ScanStatus.PENDING,
                started_at=datetime.now(),
                trigger_source="async_submit",
            )
        
        self._task_queue.put(task)
        return task_id
    
    def get_result(self, task_id: str) -> Optional[ScanResult]:
        return self._results.get(task_id)
    
    def get_status(self, task_id: str) -> Optional[ScanStatus]:
        result = self._results.get(task_id)
        return result.status if result else None
    
    def cancel_scan(self, task_id: str) -> bool:
        with self._lock:
            if task_id in self._active_scans:
                future = self._active_scans[task_id]
                cancelled = future.cancel()
                if cancelled and task_id in self._results:
                    self._results[task_id].status = ScanStatus.CANCELLED
                return cancelled
        return False
    
    def _process_queue(self) -> None:
        while self._running:
            try:
                task = self._task_queue.get(timeout=1.0)
                
                if task.task_id not in self._results:
                    continue
                
                with self._lock:
                    self._results[task.task_id].status = ScanStatus.RUNNING
                
                future = self._executor.submit(
                    self._execute_scan,
                    task,
                )
                
                with self._lock:
                    self._active_scans[task.task_id] = future
                
                future.add_done_callback(
                    lambda f, tid=task.task_id: self._scan_complete(tid, f)
                )
                
            except Empty:
                continue
            except Exception as e:
                continue
    
    def _execute_scan(self, task: ScanTask) -> ScanResult:
        start_time = time.time()
        result = self._results.get(task.task_id)
        
        if not result:
            return ScanResult(
                scan_id=task.task_id,
                status=ScanStatus.FAILED,
                started_at=datetime.now(),
                error_message="Task result not found",
            )
        
        try:
            files = task.scope.get_files(self.project_root)
            result.files_scanned = len(files)
            
            all_issues: List[Dict[str, Any]] = []
            
            for tool in task.tools:
                tool_issues = self._run_tool(tool, files, task.config)
                all_issues.extend(tool_issues)
            
            result.issues = all_issues
            result.issues_found = len(all_issues)
            result.status = ScanStatus.COMPLETED
            result.completed_at = datetime.now()
            result.execution_time_seconds = time.time() - start_time
            
        except Exception as e:
            result.status = ScanStatus.FAILED
            result.error_message = str(e)
            result.completed_at = datetime.now()
            result.execution_time_seconds = time.time() - start_time
        
        return result
    
    def _run_tool(
        self,
        tool: str,
        files: List[Path],
        config: Dict[str, Any],
    ) -> List[Dict[str, Any]]:
        import subprocess
        import sys
        
        issues: List[Dict[str, Any]] = []
        
        tool_commands = {
            "ruff": [sys.executable, "-m", "ruff", "check", "--output-format=json"],
            "mypy": [sys.executable, "-m", "mypy", "--output=json"],
            "flake8": [sys.executable, "-m", "flake8", "--format=default"],
            "pylint": [sys.executable, "-m", "pylint", "--output-format=json"],
        }
        
        if tool not in tool_commands:
            return issues
        
        cmd = tool_commands[tool].copy()
        cmd.extend([str(f) for f in files[:100]])
        
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=300,
                cwd=self.project_root,
            )
            
            if tool in ["ruff", "pylint", "mypy"]:
                try:
                    import json
                    parsed = json.loads(result.stdout) if result.stdout.strip() else []
                    if isinstance(parsed, list):
                        issues.extend(parsed)
                except json.JSONDecodeError:
                    pass
            
        except subprocess.TimeoutExpired:
            pass
        except Exception:
            pass
        
        return issues
    
    def _scan_complete(self, task_id: str, future: Future) -> None:
        with self._lock:
            if task_id in self._active_scans:
                del self._active_scans[task_id]
            
            result = self._results.get(task_id)
            if result and result.callback:
                try:
                    result.callback(result)
                except Exception:
                    pass

class AsyncScanManager:
    """High-level manager for async scanning operations."""
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.executor = AsyncScanExecutor(project_root)
        self.history = ScanHistory(project_root)
    
    def start(self) -> None:
        self.executor.start()
    
    def stop(self) -> None:
        self.executor.stop()
    
    def scan_full_project(
        self,
        tools: Optional[List[str]] = None,
        callback: Optional[Callable[[ScanResult], None]] = None,
    ) -> str:
        scope = ScanScopeManager.get_scope("full_project")
        return self.executor.submit_scan(
            scope=scope,
            tools=tools or ["ruff", "mypy"],
            callback=callback,
        )
    
    def scan_source_only(
        self,
        tools: Optional[List[str]] = None,
        callback: Optional[Callable[[ScanResult], None]] = None,
    ) -> str:
        scope = ScanScopeManager.get_scope("source_only")
        return self.executor.submit_scan(
            scope=scope,
            tools=tools or ["ruff", "mypy"],
            callback=callback,
        )
    
    def scan_files(
        self,
        files: List[Path],
        tools: Optional[List[str]] = None,
        callback: Optional[Callable[[ScanResult], None]] = None,
    ) -> str:
        file_strs = [str(f.relative_to(self.project_root)) for f in files]
        scope = ScanScopeManager.create_custom_scope(
            directories=[str(f.parent) for f in files[:10]],
            max_files=len(files),
        )
        scope.file_patterns = ["*"]
        return self.executor.submit_scan(
            scope=scope,
            tools=tools or ["ruff"],
            callback=callback,
        )
```

---

### Scan Logging and History Tracking

```python
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Any
import json
import csv
from collections import defaultdict

@dataclass
class ScanHistoryEntry:
    scan_id: str
    timestamp: datetime
    trigger_source: str
    status: ScanStatus
    files_scanned: int
    issues_found: int
    execution_time_seconds: float
    tools_used: List[str]
    error_message: Optional[str] = None
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "scan_id": self.scan_id,
            "timestamp": self.timestamp.isoformat(),
            "trigger_source": self.trigger_source,
            "status": self.status.value,
            "files_scanned": self.files_scanned,
            "issues_found": self.issues_found,
            "execution_time_seconds": self.execution_time_seconds,
            "tools_used": self.tools_used,
            "error_message": self.error_message,
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "ScanHistoryEntry":
        return cls(
            scan_id=data["scan_id"],
            timestamp=datetime.fromisoformat(data["timestamp"]),
            trigger_source=data["trigger_source"],
            status=ScanStatus(data["status"]),
            files_scanned=data["files_scanned"],
            issues_found=data["issues_found"],
            execution_time_seconds=data["execution_time_seconds"],
            tools_used=data["tools_used"],
            error_message=data.get("error_message"),
        )

@dataclass
class ScanStatistics:
    total_scans: int = 0
    successful_scans: int = 0
    failed_scans: int = 0
    total_issues_found: int = 0
    total_files_scanned: int = 0
    total_execution_time: float = 0.0
    avg_issues_per_scan: float = 0.0
    avg_execution_time: float = 0.0
    most_common_issues: Dict[str, int] = field(default_factory=dict)
    issues_by_severity: Dict[str, int] = field(default_factory=dict)
    issues_by_file: Dict[str, int] = field(default_factory=dict)
    scans_by_trigger: Dict[str, int] = field(default_factory=dict)
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "total_scans": self.total_scans,
            "successful_scans": self.successful_scans,
            "failed_scans": self.failed_scans,
            "total_issues_found": self.total_issues_found,
            "total_files_scanned": self.total_files_scanned,
            "total_execution_time": self.total_execution_time,
            "avg_issues_per_scan": self.avg_issues_per_scan,
            "avg_execution_time": self.avg_execution_time,
            "most_common_issues": self.most_common_issues,
            "issues_by_severity": self.issues_by_severity,
            "issues_by_file": self.issues_by_file,
            "scans_by_trigger": self.scans_by_trigger,
        }

class ScanHistory:
    """Track and analyze scan history."""
    
    HISTORY_DIR = ".trae/scan-history"
    HISTORY_FILE = "history.json"
    ISSUES_FILE = "issues.json"
    MAX_ENTRIES = 1000
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.history_dir = project_root / self.HISTORY_DIR
        self.history_file = self.history_dir / self.HISTORY_FILE
        self.issues_file = self.history_dir / self.ISSUES_FILE
        self._entries: List[ScanHistoryEntry] = []
        self._issues_cache: Dict[str, List[Dict[str, Any]]] = {}
        self._loaded = False
    
    def load(self) -> None:
        if self._loaded:
            return
        
        self.history_dir.mkdir(parents=True, exist_ok=True)
        
        if self.history_file.exists():
            try:
                with open(self.history_file, 'r') as f:
                    data = json.load(f)
                self._entries = [ScanHistoryEntry.from_dict(e) for e in data]
            except (json.JSONDecodeError, KeyError):
                self._entries = []
        
        if self.issues_file.exists():
            try:
                with open(self.issues_file, 'r') as f:
                    self._issues_cache = json.load(f)
            except (json.JSONDecodeError, KeyError):
                self._issues_cache = {}
        
        self._loaded = True
    
    def save(self) -> None:
        self.history_dir.mkdir(parents=True, exist_ok=True)
        
        entries_to_save = self._entries[-self.MAX_ENTRIES:]
        
        with open(self.history_file, 'w') as f:
            json.dump([e.to_dict() for e in entries_to_save], f, indent=2)
        
        with open(self.issues_file, 'w') as f:
            json.dump(self._issues_cache, f, indent=2)
    
    def record_scan(self, result: ScanResult, tools: List[str]) -> None:
        self.load()
        
        entry = ScanHistoryEntry(
            scan_id=result.scan_id,
            timestamp=result.started_at,
            trigger_source=result.trigger_source,
            status=result.status,
            files_scanned=result.files_scanned,
            issues_found=result.issues_found,
            execution_time_seconds=result.execution_time_seconds,
            tools_used=tools,
            error_message=result.error_message,
        )
        
        self._entries.append(entry)
        
        if result.issues:
            self._issues_cache[result.scan_id] = result.issues
        
        self.save()
    
    def get_recent_scans(self, limit: int = 10) -> List[ScanHistoryEntry]:
        self.load()
        return self._entries[-limit:]
    
    def get_scans_by_date_range(
        self,
        start: datetime,
        end: datetime,
    ) -> List[ScanHistoryEntry]:
        self.load()
        return [
            e for e in self._entries
            if start <= e.timestamp <= end
        ]
    
    def get_scan_issues(self, scan_id: str) -> List[Dict[str, Any]]:
        self.load()
        return self._issues_cache.get(scan_id, [])
    
    def get_statistics(self, days: int = 30) -> ScanStatistics:
        self.load()
        
        cutoff = datetime.now() - timedelta(days=days)
        recent = [e for e in self._entries if e.timestamp >= cutoff]
        
        if not recent:
            return ScanStatistics()
        
        stats = ScanStatistics()
        stats.total_scans = len(recent)
        stats.successful_scans = sum(1 for e in recent if e.status == ScanStatus.COMPLETED)
        stats.failed_scans = sum(1 for e in recent if e.status == ScanStatus.FAILED)
        stats.total_issues_found = sum(e.issues_found for e in recent)
        stats.total_files_scanned = sum(e.files_scanned for e in recent)
        stats.total_execution_time = sum(e.execution_time_seconds for e in recent)
        
        if stats.total_scans > 0:
            stats.avg_issues_per_scan = stats.total_issues_found / stats.total_scans
            stats.avg_execution_time = stats.total_execution_time / stats.total_scans
        
        issue_counts: Dict[str, int] = defaultdict(int)
        severity_counts: Dict[str, int] = defaultdict(int)
        file_counts: Dict[str, int] = defaultdict(int)
        trigger_counts: Dict[str, int] = defaultdict(int)
        
        for entry in recent:
            trigger_counts[entry.trigger_source] += 1
            
            if entry.scan_id in self._issues_cache:
                for issue in self._issues_cache[entry.scan_id]:
                    code = issue.get("code", "unknown")
                    issue_counts[code] += 1
                    
                    severity = issue.get("severity", "warning")
                    severity_counts[severity] += 1
                    
                    file_path = issue.get("filename", issue.get("file", "unknown"))
                    file_counts[file_path] += 1
        
        stats.most_common_issues = dict(sorted(issue_counts.items(), key=lambda x: -x[1])[:10])
        stats.issues_by_severity = dict(severity_counts)
        stats.issues_by_file = dict(sorted(file_counts.items(), key=lambda x: -x[1])[:20])
        stats.scans_by_trigger = dict(trigger_counts)
        
        return stats
    
    def export_to_csv(self, output_path: Path) -> None:
        self.load()
        
        with open(output_path, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow([
                "scan_id", "timestamp", "trigger_source", "status",
                "files_scanned", "issues_found", "execution_time",
                "tools_used", "error_message"
            ])
            
            for entry in self._entries:
                writer.writerow([
                    entry.scan_id,
                    entry.timestamp.isoformat(),
                    entry.trigger_source,
                    entry.status.value,
                    entry.files_scanned,
                    entry.issues_found,
                    f"{entry.execution_time_seconds:.2f}",
                    ",".join(entry.tools_used),
                    entry.error_message or "",
                ])
    
    def clear_old_history(self, days: int = 90) -> int:
        self.load()
        
        cutoff = datetime.now() - timedelta(days=days)
        original_count = len(self._entries)
        
        self._entries = [e for e in self._entries if e.timestamp >= cutoff]
        
        removed_ids = set()
        for scan_id in list(self._issues_cache.keys()):
            if scan_id not in [e.scan_id for e in self._entries]:
                del self._issues_cache[scan_id]
                removed_ids.add(scan_id)
        
        self.save()
        
        return original_count - len(self._entries)
```

---

## Code Examples

### Configuring Trigger Conditions

```python
from pathlib import Path

project_root = Path("/path/to/project")
config_manager = TriggerConfigManager(project_root)

config = TriggerConfig(
    trigger_type=TriggerType.HYBRID,
    enabled=True,
    time_config=TimeBasedConfig(
        interval_seconds=300,
        cooldown_seconds=60,
        schedule_cron="0 9 * * 1-5",
    ),
    event_config=EventBasedConfig(
        events=[EventType.FILE_SAVE, EventType.CONVERSATION_END],
        debounce_seconds=2.0,
        throttle_seconds=10.0,
        batch_events=True,
        batch_window_seconds=15.0,
        file_patterns=["*.py"],
        exclude_patterns=["venv/*", "build/*", "dist/*"],
    ),
    min_severity="warning",
    tools=["ruff", "mypy"],
)

config_manager.save_config(config)

print("Configuration saved:")
print(json.dumps(config.to_dict(), indent=2))
```

### Executing Scans Asynchronously

```python
from pathlib import Path
from typing import Optional

project_root = Path("/path/to/project")
scan_manager = AsyncScanManager(project_root)

def on_scan_complete(result: ScanResult) -> None:
    print(f"Scan {result.scan_id} completed!")
    print(f"  Status: {result.status.value}")
    print(f"  Files scanned: {result.files_scanned}")
    print(f"  Issues found: {result.issues_found}")
    print(f"  Execution time: {result.execution_time_seconds:.2f}s")
    
    if result.issues:
        print("\nTop issues:")
        for issue in result.issues[:5]:
            print(f"  - {issue.get('filename', 'unknown')}:{issue.get('line', '?')}")
            print(f"    {issue.get('code', '?')}: {issue.get('message', '')}")

scan_manager.start()

task_id = scan_manager.scan_full_project(
    tools=["ruff", "mypy"],
    callback=on_scan_complete,
)

print(f"Scan submitted with task ID: {task_id}")

import time
while True:
    status = scan_manager.executor.get_status(task_id)
    if status in [ScanStatus.COMPLETED, ScanStatus.FAILED, ScanStatus.CANCELLED]:
        break
    time.sleep(1)

result = scan_manager.executor.get_result(task_id)
scan_manager.history.record_scan(result, ["ruff", "mypy"])

scan_manager.stop()
```

### Tracking Scan History

```python
from pathlib import Path
from datetime import datetime, timedelta

project_root = Path("/path/to/project")
history = ScanHistory(project_root)

stats = history.get_statistics(days=30)

print("Scan Statistics (Last 30 Days)")
print("=" * 40)
print(f"Total scans: {stats.total_scans}")
print(f"Successful: {stats.successful_scans}")
print(f"Failed: {stats.failed_scans}")
print(f"Total issues found: {stats.total_issues_found}")
print(f"Average issues per scan: {stats.avg_issues_per_scan:.2f}")
print(f"Average execution time: {stats.avg_execution_time:.2f}s")

print("\nMost Common Issues:")
for code, count in stats.most_common_issues.items():
    print(f"  {code}: {count} occurrences")

print("\nIssues by Severity:")
for severity, count in stats.issues_by_severity.items():
    print(f"  {severity}: {count}")

print("\nScans by Trigger Source:")
for source, count in stats.scans_by_trigger.items():
    print(f"  {source}: {count}")

recent = history.get_recent_scans(limit=5)
print("\nRecent Scans:")
for entry in recent:
    print(f"  {entry.timestamp.strftime('%Y-%m-%d %H:%M:%S')} - "
          f"{entry.status.value} - {entry.issues_found} issues")

history.export_to_csv(project_root / "scan-history-export.csv")
print("\nHistory exported to scan-history-export.csv")
```

### Integrating with IDE/Editor Hooks

```python
from pathlib import Path
from typing import Set, Optional
import time
import threading
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler, FileModifiedEvent

class IDEIntegration:
    """Integration layer for IDE/editor hooks."""
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.scan_manager = AsyncScanManager(project_root)
        self.config_manager = TriggerConfigManager(project_root)
        self._observer: Optional[Observer] = None
        self._debounce_timer: Optional[threading.Timer] = None
        self._pending_files: Set[Path] = set()
        self._lock = threading.Lock()
    
    def start(self) -> None:
        self.scan_manager.start()
        config = self.config_manager.load_config()
        
        if config.event_config and EventType.FILE_MODIFY in config.event_config.events:
            self._start_file_watcher(config.event_config)
    
    def stop(self) -> None:
        if self._observer:
            self._observer.stop()
            self._observer.join()
        self.scan_manager.stop()
    
    def _start_file_watcher(self, event_config: EventBasedConfig) -> None:
        handler = FileChangeHandler(
            callback=self._on_file_changed,
            patterns=event_config.file_patterns,
            excludes=event_config.exclude_patterns,
        )
        
        self._observer = Observer()
        self._observer.schedule(handler, str(self.project_root), recursive=True)
        self._observer.start()
    
    def _on_file_changed(self, file_path: Path) -> None:
        config = self.config_manager.load_config()
        if not config.enabled or not config.event_config:
            return
        
        with self._lock:
            self._pending_files.add(file_path)
        
        if self._debounce_timer:
            self._debounce_timer.cancel()
        
        self._debounce_timer = threading.Timer(
            config.event_config.debounce_seconds,
            self._execute_batch_scan,
        )
        self._debounce_timer.start()
    
    def _execute_batch_scan(self) -> None:
        with self._lock:
            files = list(self._pending_files)
            self._pending_files.clear()
        
        if files:
            self.scan_manager.scan_files(
                files=files,
                tools=["ruff"],
                callback=self._on_scan_complete,
            )
    
    def _on_scan_complete(self, result: ScanResult) -> None:
        self.scan_manager.history.record_scan(result, ["ruff"])
        
        if result.issues_found > 0:
            self._notify_issues(result)
    
    def _notify_issues(self, result: ScanResult) -> None:
        notification = {
            "type": "quality_issues",
            "scan_id": result.scan_id,
            "issues_count": result.issues_found,
            "issues": result.issues[:10],
        }
        
        print(json.dumps(notification, indent=2))
    
    def on_conversation_end(self, changed_files: Optional[Set[Path]] = None) -> str:
        config = self.config_manager.load_config()
        
        if not config.enabled:
            return ""
        
        if changed_files:
            return self.scan_manager.scan_files(
                files=list(changed_files),
                tools=config.tools,
            )
        else:
            return self.scan_manager.scan_full_project(tools=config.tools)
    
    def on_pre_commit(self) -> bool:
        config = self.config_manager.load_config()
        
        if not config.enabled:
            return True
        
        task_id = self.scan_manager.scan_full_project(tools=config.tools)
        
        while True:
            status = self.scan_manager.executor.get_status(task_id)
            if status in [ScanStatus.COMPLETED, ScanStatus.FAILED]:
                break
            time.sleep(0.5)
        
        result = self.scan_manager.executor.get_result(task_id)
        self.scan_manager.history.record_scan(result, config.tools)
        
        if result.status == ScanStatus.COMPLETED:
            critical_issues = [
                i for i in result.issues
                if i.get("severity") in ["error", "critical"]
            ]
            return len(critical_issues) == 0
        
        return True

class FileChangeHandler(FileSystemEventHandler):
    """Handle file system change events."""
    
    def __init__(
        self,
        callback: callable,
        patterns: List[str],
        excludes: List[str],
    ):
        super().__init__()
        self.callback = callback
        self.patterns = patterns
        self.excludes = excludes
    
    def on_modified(self, event: FileModifiedEvent) -> None:
        if event.is_directory:
            return
        
        file_path = Path(event.src_path)
        
        if not self._matches_patterns(file_path):
            return
        
        if self._is_excluded(file_path):
            return
        
        self.callback(file_path)
    
    def _matches_patterns(self, path: Path) -> bool:
        import fnmatch
        for pattern in self.patterns:
            if fnmatch.fnmatch(path.name, pattern):
                return True
        return False
    
    def _is_excluded(self, path: Path) -> bool:
        import fnmatch
        path_str = str(path)
        for pattern in self.excludes:
            if fnmatch.fnmatch(path_str, f"*{pattern}*"):
                return True
        return False
```

---

## Configuration Options

### Auto-Trigger Configuration File

Create `.trae/auto-trigger-config.json`:

```json
{
  "trigger_type": "hybrid",
  "enabled": true,
  "time_config": {
    "interval_seconds": 300,
    "start_delay_seconds": 30,
    "max_consecutive_scans": 3,
    "cooldown_seconds": 60,
    "schedule_cron": "0 9,17 * * 1-5"
  },
  "event_config": {
    "events": ["file_save", "conversation_end"],
    "debounce_seconds": 2.0,
    "throttle_seconds": 10.0,
    "batch_events": true,
    "batch_window_seconds": 15.0,
    "file_patterns": ["*.py"],
    "exclude_patterns": [
      "venv/*",
      ".venv/*",
      "build/*",
      "dist/*",
      "__pycache__/*",
      "*.egg-info/*"
    ]
  },
  "min_severity": "warning",
  "tools": ["ruff", "mypy"]
}
```

### Configuration Options Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `trigger_type` | string | `"event_based"` | Type of trigger: `time_based`, `event_based`, `hybrid` |
| `enabled` | boolean | `true` | Enable or disable auto-trigger |
| `time_config.interval_seconds` | int | `300` | Interval between scheduled scans |
| `time_config.schedule_cron` | string | `null` | Cron expression for scheduled scans |
| `time_config.cooldown_seconds` | int | `60` | Minimum time between consecutive scans |
| `event_config.events` | array | `["file_save"]` | Events that trigger scans |
| `event_config.debounce_seconds` | float | `1.0` | Debounce delay for rapid events |
| `event_config.throttle_seconds` | float | `5.0` | Minimum time between triggered scans |
| `event_config.batch_events` | boolean | `true` | Batch multiple events into single scan |
| `event_config.batch_window_seconds` | float | `10.0` | Window for batching events |
| `event_config.file_patterns` | array | `["*.py"]` | File patterns to monitor |
| `event_config.exclude_patterns` | array | `[]` | Patterns to exclude from monitoring |
| `min_severity` | string | `"warning"` | Minimum severity to report |
| `tools` | array | `["ruff", "mypy"]` | Tools to run during scans |

---

## Best Practices

### 1. Performance Optimization

```python
RECOMMENDED_PRACTICES = """
- Use debounce/throttle to prevent excessive scans
- Batch file changes for efficiency
- Limit scan scope for frequent triggers
- Use faster tools (ruff) for real-time feedback
- Schedule comprehensive scans for off-peak hours
- Cache results when possible
- Set appropriate cooldown periods
"""
```

### 2. Resource Management

```python
@dataclass
class ResourceLimits:
    max_concurrent_scans: int = 2
    max_files_per_scan: int = 1000
    max_memory_mb: int = 512
    max_cpu_percent: int = 50
    scan_timeout_seconds: int = 300
    
    def check_resources(self) -> bool:
        import psutil
        
        memory = psutil.virtual_memory()
        cpu = psutil.cpu_percent(interval=0.1)
        
        if memory.percent > 80:
            return False
        
        if cpu > self.max_cpu_percent:
            return False
        
        return True
```

### 3. Error Handling

```python
class AutoTriggerErrorHandler:
    """Handle errors in auto-trigger operations."""
    
    def __init__(self, max_retries: int = 3):
        self.max_retries = max_retries
        self._retry_counts: Dict[str, int] = defaultdict(int)
    
    def handle_scan_error(
        self,
        scan_id: str,
        error: Exception,
        retry_callback: Callable,
    ) -> bool:
        self._retry_counts[scan_id] += 1
        
        if self._retry_counts[scan_id] <= self.max_retries:
            if isinstance(error, (TimeoutError, subprocess.TimeoutExpired)):
                time.sleep(5)
                retry_callback()
                return True
            
            if isinstance(error, (MemoryError,)):
                return False
        
        return False
    
    def should_disable_trigger(self, consecutive_failures: int) -> bool:
        return consecutive_failures >= 5
```

### 4. Notification Strategy

```python
class NotificationConfig:
    """Configure scan result notifications."""
    
    def __init__(self):
        self.notify_on_success: bool = False
        self.notify_on_issues: bool = True
        self.notify_on_failure: bool = True
        self.min_issues_to_notify: int = 1
        self.severity_filter: List[str] = ["error", "critical"]
        self.quiet_hours_start: Optional[int] = None
        self.quiet_hours_end: Optional[int] = None
    
    def should_notify(self, result: ScanResult) -> bool:
        if result.status == ScanStatus.COMPLETED:
            if not self.notify_on_issues:
                return False
            
            if result.issues_found < self.min_issues_to_notify:
                return False
            
            filtered_issues = [
                i for i in result.issues
                if i.get("severity") in self.severity_filter
            ]
            return len(filtered_issues) > 0
        
        if result.status == ScanStatus.FAILED:
            return self.notify_on_failure
        
        return False
```

---

## Integration with Other Modules

### Integration with Syntax Checker

```python
class SyntaxCheckerIntegration:
    """Integrate auto-trigger with syntax checker module."""
    
    def __init__(self, auto_trigger: AsyncScanManager):
        self.auto_trigger = auto_trigger
    
    def scan_with_syntax_priority(
        self,
        files: List[Path],
    ) -> str:
        return self.auto_trigger.scan_files(
            files=files,
            tools=["ruff"],
            callback=self._syntax_callback,
        )
    
    def _syntax_callback(self, result: ScanResult) -> None:
        syntax_errors = [
            i for i in result.issues
            if i.get("code", "").startswith("E9") or
               i.get("code", "").startswith("F63")
        ]
        
        if syntax_errors:
            print(f"CRITICAL: {len(syntax_errors)} syntax errors found!")
```

### Integration with Type Checker

```python
class TypeCheckerIntegration:
    """Integrate auto-trigger with type checker module."""
    
    def __init__(self, auto_trigger: AsyncScanManager):
        self.auto_trigger = auto_trigger
    
    def scan_with_type_check(
        self,
        scope: ScanScope,
        strict: bool = False,
    ) -> str:
        config = {
            "mypy": {
                "strict": strict,
                "ignore_missing_imports": not strict,
            }
        }
        
        return self.auto_trigger.executor.submit_scan(
            scope=scope,
            tools=["mypy"],
            config=config,
            callback=self._type_check_callback,
        )
    
    def _type_check_callback(self, result: ScanResult) -> None:
        type_errors = [
            i for i in result.issues
            if "type" in i.get("message", "").lower() or
               i.get("code", "").startswith("mypy")
        ]
        
        if type_errors:
            print(f"Type errors: {len(type_errors)}")
```

### Integration with Error Fixer

```python
class ErrorFixerIntegration:
    """Integrate auto-trigger with error fixer module."""
    
    def __init__(
        self,
        auto_trigger: AsyncScanManager,
        auto_fix: bool = False,
    ):
        self.auto_trigger = auto_trigger
        self.auto_fix = auto_fix
    
    def scan_and_fix(self, files: List[Path]) -> str:
        def callback(result: ScanResult) -> None:
            if self.auto_fix and result.issues_found > 0:
                self._attempt_auto_fix(result)
        
        return self.auto_trigger.scan_files(
            files=files,
            tools=["ruff"],
            callback=callback,
        )
    
    def _attempt_auto_fix(self, result: ScanResult) -> None:
        auto_fixable = [
            i for i in result.issues
            if i.get("fix_available", False)
        ]
        
        if auto_fixable:
            print(f"Auto-fixing {len(auto_fixable)} issues...")
```

### Integration with Tool Integration Module

```python
class ToolIntegrationBridge:
    """Bridge auto-trigger with tool integration module."""
    
    def __init__(
        self,
        auto_trigger: AsyncScanManager,
        tool_runner: "ToolRunner",
    ):
        self.auto_trigger = auto_trigger
        self.tool_runner = tool_runner
    
    def run_comprehensive_scan(
        self,
        scope: ScanScope,
        tools: List[str],
    ) -> str:
        return self.auto_trigger.executor.submit_scan(
            scope=scope,
            tools=tools,
            callback=self._comprehensive_callback,
        )
    
    def _comprehensive_callback(self, result: ScanResult) -> None:
        summary = {
            "scan_id": result.scan_id,
            "total_issues": result.issues_found,
            "by_tool": defaultdict(int),
            "by_severity": defaultdict(int),
        }
        
        for issue in result.issues:
            summary["by_tool"][issue.get("tool", "unknown")] += 1
            summary["by_severity"][issue.get("severity", "unknown")] += 1
        
        print(json.dumps(summary, indent=2))
```

---

## Summary

The Auto-Trigger Mechanism Module provides:

1. **Flexible Trigger Configuration**: Support for time-based, event-based, and hybrid triggers with comprehensive configuration options.

2. **Efficient Async Execution**: Non-blocking background scanning with thread pool execution, task queuing, and priority support.

3. **Comprehensive History Tracking**: Full scan history with statistics, issue tracking, and export capabilities.

4. **IDE/Editor Integration**: Ready-to-use integration patterns for file watchers, conversation hooks, and pre-commit checks.

5. **Resource Management**: Built-in throttling, debouncing, and resource limits to prevent system overload.

6. **Module Integration**: Seamless integration with syntax checker, type checker, error fixer, and tool integration modules.
