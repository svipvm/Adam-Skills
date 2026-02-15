<#
.SYNOPSIS
    PowerShell Project Start Script

.DESCRIPTION
    This script initializes and starts the PowerShell project application.

.PARAMETER ConfigPath
    Path to the configuration directory. Default is "config".

.PARAMETER NoWindow
    Run the application without showing a console window.

.PARAMETER SkipValidation
    Skip configuration validation on startup.

.EXAMPLE
    .\start.ps1

.EXAMPLE
    .\start.ps1 -ConfigPath "config" -NoWindow
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "config",

    [Parameter(Mandatory = $false)]
    [switch]$NoWindow,

    [Parameter(Mandatory = $false)]
    [switch]$SkipValidation,

    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = $PSScriptRoot
)

$ErrorActionPreference = "Stop"

$script:ProjectRoot = $ProjectRoot
$script:ConfigPath = Join-Path $ProjectRoot $ConfigPath

function Import-ProjectModules {
    Write-Host "[INFO] Loading project modules..." -ForegroundColor Cyan

    $includesPath = Join-Path $ProjectRoot "includes"

    $moduleFiles = @(
        "config-utils.md",
        "logger.md",
        "process-utils.md"
    )

    foreach ($module in $moduleFiles) {
        $modulePath = Join-Path $includesPath $module
        if (Test-Path $modulePath) {
            Write-Host "[DEBUG] Loading module: $module" -ForegroundColor Gray
        }
        else {
            Write-Warning "Module not found: $module"
        }
    }

    $utilsScript = @"
function Get-ProjectConfig {
    param([string]`$ConfigPath)

    if (-not (Test-Path `$ConfigPath)) {
        Write-Error "Configuration file not found: `$ConfigPath"
        return `$null
    }

    try {
        `$content = Get-Content -Path `$ConfigPath -Raw -Encoding UTF8
        return `$content | ConvertFrom-Json
    }
    catch {
        Write-Error "Failed to parse configuration: `$_"
        return `$null
    }
}

function Write-Log {
    param(
        [string]`$Message,
        [string]`$Level = "Info",
        [string]`$LogPath = `$null
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

    if (`$LogPath -and (Test-Path (Split-Path `$LogPath -Parent))) {
        Add-Content -Path `$LogPath -Value `$logMessage -Encoding UTF8
    }
}

function Get-ProjectProcess {
    param([string]`$ProcessName)

    `$processes = Get-Process -Name `$ProcessName -ErrorAction SilentlyContinue
    if (-not `$processes) {
        `$processes = Get-Process -Filter "*`$ProcessName*" -ErrorAction SilentlyContinue
    }
    return `$processes
}
"@

    Invoke-Expression $utilsScript

    Write-Host "[SUCCESS] Modules loaded" -ForegroundColor Green
}

function Test-PowerShellVersion {
    Write-Host "[INFO] Checking PowerShell version..." -ForegroundColor Cyan

    $version = $PSVersionTable.PSVersion
    $minimumVersion = [version]"5.1"

    if ($version -lt $minimumVersion) {
        Write-Log -Message "PowerShell version $version is below minimum required version $minimumVersion" -Level Error
        exit 1
    }

    Write-Log -Message "PowerShell version: $version" -Level Success
}

function Initialize-Directories {
    Write-Host "[INFO] Initializing project directories..." -ForegroundColor Cyan

    $directories = @("logs", "temp", "data")

    foreach ($dir in $directories) {
        $dirPath = Join-Path $ProjectRoot $dir

        if (-not (Test-Path $dirPath)) {
            New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
            Write-Log -Message "Created directory: $dir" -Level Info
        }
        else {
            Write-Log -Message "Directory already exists: $dir" -Level Debug
        }
    }

    Write-Log -Message "Directory initialization complete" -Level Success
}

function Initialize-Logging {
    Write-Host "[INFO] Initializing logging system..." -ForegroundColor Cyan

    $logsPath = Join-Path $ProjectRoot "logs"
    $date = Get-Date -Format "yyyyMMdd"
    $logFile = Join-Path $logsPath "start_$date.log"

    if (-not (Test-Path $logsPath)) {
        New-Item -ItemType Directory -Path $logsPath -Force | Out-Null
    }

    $script:LogFilePath = $logFile
    Write-Log -Message "Log file: $logFile" -Level Info -LogPath $logFile

    return $logFile
}

function Test-Configuration {
    Write-Host "[INFO] Validating configuration..." -ForegroundColor Cyan

    $requiredConfigs = @("project.json", "runtime.json")

    foreach ($config in $requiredConfigs) {
        $configPath = Join-Path $ConfigPath $config

        if (-not (Test-Path $configPath)) {
            Write-Log -Message "Missing required config: $config" -Level Error
            return $false
        }

        try {
            $configData = Get-Content -Path $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
            Write-Log -Message "Loaded config: $config" -Level Debug
        }
        catch {
            Write-Log -Message "Invalid config file: $config - $_" -Level Error
            return $false
        }
    }

    Write-Log -Message "Configuration validation passed" -Level Success
    return $true
}

function Start-Application {
    Write-Host "[INFO] Starting application..." -ForegroundColor Cyan

    $runtimeConfigPath = Join-Path $ConfigPath "runtime.json"

    if (Test-Path $runtimeConfigPath) {
        $runtimeConfig = Get-ProjectConfig -ConfigPath $runtimeConfigPath

        $mainScript = $runtimeConfig.mainScript
        if (-not $mainScript) {
            $mainScript = "src\main.ps1"
        }

        $scriptPath = Join-Path $ProjectRoot $mainScript

        if (Test-Path $scriptPath) {
            Write-Log -Message "Starting main script: $mainScript" -Level Info

            if ($NoWindow) {
                $process = Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$scriptPath`"" -WindowStyle Hidden -PassThru
            }
            else {
                & $scriptPath
            }

            Write-Log -Message "Application started successfully" -Level Success
        }
        else {
            Write-Log -Message "Main script not found: $scriptPath" -Level Warning
            Write-Host "[INFO] No main script found. Project initialized successfully." -ForegroundColor Yellow
        }
    }
    else {
        Write-Log -Message "Runtime configuration not found. Project initialized." -Level Warning
    }
}

try {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  PowerShell Project Start" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    Import-ProjectModules

    Test-PowerShellVersion

    Initialize-Directories

    $logFile = Initialize-Logging

    if (-not $SkipValidation) {
        $configValid = Test-Configuration
        if (-not $configValid) {
            Write-Host "[ERROR] Configuration validation failed. Use -SkipValidation to bypass." -ForegroundColor Red
            exit 1
        }
    }
    else {
        Write-Log -Message "Configuration validation skipped" -Level Warning
    }

    Start-Application

    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "  Startup Complete" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Green
}
catch {
    Write-Host "`n[ERROR] Startup failed: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}
