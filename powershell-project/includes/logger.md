# Logger

PowerShell 项目日志工具模块，提供日志记录功能。

## 函数列表

### Write-Log

写入日志消息。

```powershell
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Debug", "Success")]
        [string]$Level = "Info",

        [Parameter(Mandatory = $false)]
        [string]$LogPath = $null,

        [Parameter(Mandatory = $false)]
        [switch]$NoConsole
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    $color = switch ($Level) {
        "Info"    { "White" }
        "Warning" { "Yellow" }
        "Error"   { "Red" }
        "Debug"   { "Gray" }
        "Success" { "Green" }
    }

    if (-not $NoConsole) {
        Write-Host $logMessage -ForegroundColor $color
    }

    if ($LogPath) {
        $logDir = Split-Path $LogPath -Parent
        if ($logDir -and -not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        Add-Content -Path $LogPath -Value $logMessage -Encoding UTF8
    }
}
```

### Initialize-Log

初始化日志系统。

```powershell
function Initialize-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$LogDir = "logs",

        [Parameter(Mandatory = $false)]
        [string]$LogPrefix = "app",

        [Parameter(Mandatory = $false)]
        [int]$MaxLogFiles = 10
    )

    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }

    $date = Get-Date -Format "yyyyMMdd"
    $logFileName = "${LogPrefix}_${date}.log"
    $logPath = Join-Path $LogDir $logFileName

    $script:LogFilePath = $logPath
    $script:LogDir = $LogDir
    $script:MaxLogFiles = $MaxLogFiles

    Write-Log -Message "Logging initialized: $logPath" -Level Info

    Clean-OldLogs -LogDir $LogDir -MaxFiles $MaxLogFiles

    return $logPath
}
```

### Clean-OldLogs

清理旧的日志文件。

```powershell
function Clean-OldLogs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$LogDir = "logs",

        [Parameter(Mandatory = $false)]
        [int]$MaxFiles = 10
    )

    if (-not (Test-Path $LogDir)) {
        return
    }

    $logFiles = Get-ChildItem -Path $LogDir -Filter "*.log" |
        Sort-Object LastWriteTime -Descending |
        Skip $MaxFiles

    foreach ($file in $logFiles) {
        Remove-Item -Path $file.FullName -Force
        Write-Log -Message "Removed old log file: $($file.Name)" -Level Debug
    }
}
```

### Write-LogSection

写入日志分段标题。

```powershell
function Write-LogSection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Title,

        [Parameter(Mandatory = $false)]
        [string]$LogPath = $script:LogFilePath
    )

    $separator = "=" * 60
    Write-Log -Message $separator -Level Info -LogPath $LogPath
    Write-Log -Message $Title -Level Info -LogPath $LogPath
    Write-Log -Message $separator -Level Info -LogPath $LogPath
}
```

### Write-LogError

写入错误日志并显示详细信息。

```powershell
function Write-LogError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [Parameter(Mandatory = $false)]
        [string]$LogPath = $script:LogFilePath
    )

    Write-Log -Message $Message -Level Error -LogPath $LogPath

    if ($ErrorRecord) {
        Write-Log -Message "Exception: $($ErrorRecord.Exception.Message)" -Level Error -LogPath $LogPath
        Write-Log -Message "Stack Trace: $($ErrorRecord.ScriptStackTrace)" -Level Error -LogPath $LogPath
    }
}
```

### Get-LogPath

获取当前日志文件路径。

```powershell
function Get-LogPath {
    [CmdletBinding()]
    param()

    return $script:LogFilePath
}
```

### Set-LogLevel

设置日志级别。

```powershell
function Set-LogLevel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Debug")]
        [string]$Level = "Info"
    )

    $script:LogLevel = $Level
}
```

### Should-Log

判断指定级别的日志是否应该被记录。

```powershell
function Should-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Debug", "Success")]
        [string]$Level = "Info"
    )

    $levels = @{
        "Debug"   = 0
        "Info"    = 1
        "Success" = 1
        "Warning" = 2
        "Error"   = 3
    }

    $currentLevel = $script:LogLevel
    if (-not $currentLevel) {
        $currentLevel = "Info"
    }

    return $levels[$Level] -ge $levels[$currentLevel]
}
```
