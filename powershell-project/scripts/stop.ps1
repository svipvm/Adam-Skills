<#
.SYNOPSIS
    PowerShell Project Stop Script

.DESCRIPTION
    This script gracefully stops the PowerShell project application.

.PARAMETER ProcessName
    Name of the process to stop. Default is read from runtime.json.

.PARAMETER Force
    Force kill the process without waiting for graceful shutdown.

.PARAMETER Timeout
    Seconds to wait for graceful shutdown. Default is 30.

.PARAMETER ProjectRoot
    Path to the project root directory.

.EXAMPLE
    .\stop.ps1

.EXAMPLE
    .\stop.ps1 -Force

.EXAMPLE
    .\stop.ps1 -ProcessName "myapp" -Timeout 60
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$ProcessName = "",

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [int]$Timeout = 30,

    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = $PSScriptRoot
)

$ErrorActionPreference = "Stop"

$script:ProjectRoot = $ProjectRoot
$script:ConfigPath = Join-Path $ProjectRoot "config"

function Import-ProjectModules {
    Write-Host "[INFO] Loading project modules..." -ForegroundColor Cyan

    $utilsScript = @"
function Write-Log {
    param(
        [string]`$Message,
        [string]`$Level = "Info"
    )

    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    `$logMessage = "[`$timestamp] [`$Level] `$Message"

    `$color = switch (`$Level) {
        "Info"    { "White" }
        "Warning" { "Yellow" }
        "Error"   { "Red" }
        "Debug"   { "Gray" }
        "Success" { "Green" }
    }

    Write-Host `$logMessage -ForegroundColor `$color
}

function Get-ProcessInfoSafe {
    param([string]`$Name)

    try {
        return Get-Process -Name `$Name -ErrorAction SilentlyContinue
    }
    catch {
        return `$null
    }
}
"@

    Invoke-Expression $utilsScript

    Write-Host "[SUCCESS] Modules loaded" -ForegroundColor Green
}

function Initialize-Logging {
    Write-Host "[INFO] Initializing logging..." -ForegroundColor Cyan

    $logsPath = Join-Path $ProjectRoot "logs"
    $date = Get-Date -Format "yyyyMMdd"
    $logFile = Join-Path $logsPath "stop_$date.log"

    if (-not (Test-Path $logsPath)) {
        New-Item -ItemType Directory -Path $logsPath -Force | Out-Null
    }

    $script:LogFilePath = $logFile
    Write-Log -Message "Log file: $logFile" -Level Info

    return $logFile
}

function Get-ProcessNameFromConfig {
    if ($ProcessName) {
        return $ProcessName
    }

    $runtimeConfigPath = Join-Path $ConfigPath "runtime.json"

    if (Test-Path $runtimeConfigPath) {
        try {
            $content = Get-Content -Path $runtimeConfigPath -Raw -Encoding UTF8
            $config = $content | ConvertFrom-Json

            if ($config.processName) {
                return $config.processName
            }
        }
        catch {
            Write-Log -Message "Failed to read runtime config: $_" -Level Warning
        }
    }

    return $null
}

function Stop-ProcessGracefully {
    param(
        [string]$Name,
        [int]$TimeoutSeconds,
        [bool]$ForceKill
    )

    Write-Host "[INFO] Stopping process: $Name" -ForegroundColor Cyan

    $processes = Get-ProcessInfoSafe -Name $Name

    if (-not $processes) {
        $processes = Get-Process | Where-Object { $_.ProcessName -like "*$Name*" } -ErrorAction SilentlyContinue
    }

    if (-not $processes -or $processes.Count -eq 0) {
        Write-Log -Message "No running process found: $Name" -Level Warning
        return $true
    }

    foreach ($process in $processes) {
        $pid = $process.Id
        $processName = $process.ProcessName

        Write-Log -Message "Stopping process: $processName (PID: $pid)" -Level Info

        if ($ForceKill) {
            try {
                Stop-Process -Id $pid -Force -ErrorAction Stop
                Write-Log -Message "Force stopped process: $processName" -Level Success
            }
            catch {
                Write-Log -Message "Failed to stop process: $_" -Level Error
            }
        }
        else {
            try {
                $process.CloseMainWindow() | Out-Null

                $exited = $process.WaitForExit($TimeoutSeconds * 1000)

                if ($exited) {
                    Write-Log -Message "Process exited gracefully: $processName" -Level Success
                }
                else {
                    Write-Log -Message "Process did not exit within timeout, forcing..." -Level Warning
                    Stop-Process -Id $pid -Force -ErrorAction Stop
                    Write-Log -Message "Force stopped process: $processName" -Level Success
                }
            }
            catch {
                Write-Log -Message "Error stopping process: $_" -Level Error
            }
        }
    }

    return $true
}

function Save-ApplicationState {
    Write-Host "[INFO] Saving application state..." -ForegroundColor Cyan

    $stateDir = Join-Path $ProjectRoot "state"

    if (-not (Test-Path $stateDir)) {
        New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
    }

    $stateFile = Join-Path $stateDir "last_run.json"
    $state = @{
        stoppedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        exitCode = 0
    }

    try {
        $state | ConvertTo-Json | Set-Content -Path $stateFile -Encoding UTF8
        Write-Log -Message "State saved to: $stateFile" -Level Success
    }
    catch {
        Write-Log -Message "Failed to save state: $_" -Level Warning
    }
}

function Clear-TempFiles {
    Write-Host "[INFO] Cleaning temporary files..." -ForegroundColor Cyan

    $tempDir = Join-Path $ProjectRoot "temp"

    if (Test-Path $tempDir) {
        try {
            $tempFiles = Get-ChildItem -Path $tempDir -File -ErrorAction SilentlyContinue

            $count = 0
            foreach ($file in $tempFiles) {
                try {
                    Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                    $count++
                }
                catch {
                    Write-Log -Message "Could not remove: $($file.Name)" -Level Debug
                }
            }

            Write-Log -Message "Removed $count temporary files" -Level Success
        }
        catch {
            Write-Log -Message "Failed to clean temp directory: $_" -Level Warning
        }
    }
}

function Remove-PidFile {
    $pidFile = Join-Path $ProjectRoot "app.pid"

    if (Test-Path $pidFile) {
        try {
            Remove-Item -Path $pidFile -Force
            Write-Log -Message "Removed PID file" -Level Debug
        }
        catch {
            Write-Log -Message "Failed to remove PID file: $_" -Level Warning
        }
    }
}

try {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  PowerShell Project Stop" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    Import-ProjectModules

    $logFile = Initialize-Logging

    $targetProcessName = Get-ProcessNameFromConfig

    if ($targetProcessName) {
        Stop-ProcessGracefully -Name $targetProcessName -TimeoutSeconds $Timeout -ForceKill $Force
    }
    else {
        Write-Log -Message "No process name configured. Skipping process termination." -Level Warning
        Write-Host "[INFO] No process to stop." -ForegroundColor Yellow
    }

    Remove-PidFile

    Save-ApplicationState

    Clear-TempFiles

    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "  Stop Complete" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Green
}
catch {
    Write-Host "`n[ERROR] Stop failed: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}
