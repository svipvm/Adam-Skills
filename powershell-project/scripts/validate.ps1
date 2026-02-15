<#
.SYNOPSIS
    PowerShell Project Validation Script

.DESCRIPTION
    This script validates the PowerShell project structure and configuration.

.PARAMETER ProjectRoot
    Path to the project root directory. Default is the script directory.

.PARAMETER SkipConfig
    Skip configuration file validation.

.PARAMETER SkipSyntax
    Skip PowerShell syntax validation.

.EXAMPLE
    .\validate.ps1

.EXAMPLE
    .\validate.ps1 -SkipConfig
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = $PSScriptRoot,

    [Parameter(Mandatory = $false)]
    [switch]$SkipConfig,

    [Parameter(Mandatory = $false)]
    [switch]$SkipSyntax
)

$ErrorActionPreference = "Continue"

$script:ProjectRoot = $ProjectRoot
$script:ValidationErrors = @()
$script:ValidationWarnings = @()

function Write-ValidationLog {
    param(
        [string]$Message,
        [string]$Level = "Info"
    )

    $color = switch ($Level) {
        "Error"   { "Red" }
        "Warning" { "Yellow" }
        "Success" { "Green" }
        default   { "White" }
    }

    Write-Host "[$Level] $Message" -ForegroundColor $color
}

function Test-DirectoryStructure {
    Write-ValidationLog "Validating directory structure..." -Level Info

    $requiredDirs = @("config", "scripts", "src")
    $optionalDirs = @("tests", "logs", "docs", "data", "temp", "includes", "types")

    foreach ($dir in $requiredDirs) {
        $dirPath = Join-Path $ProjectRoot $dir
        if (Test-Path $dirPath) {
            Write-ValidationLog "  [OK] $dir/" -Level Success
        }
        else {
            Write-ValidationLog "  [MISSING] $dir/ (required)" -Level Error
            $script:ValidationErrors += "Missing required directory: $dir"
        }
    }

    foreach ($dir in $optionalDirs) {
        $dirPath = Join-Path $ProjectRoot $dir
        if (Test-Path $dirPath) {
            Write-ValidationLog "  [OK] $dir/ (optional)" -Level Success
        }
        else {
            Write-ValidationLog "  [MISSING] $dir/ (optional)" -Level Warning
            $script:ValidationWarnings += "Missing optional directory: $dir"
        }
    }
}

function Test-ConfigurationFiles {
    if ($SkipConfig) {
        Write-ValidationLog "Skipping configuration validation..." -Level Warning
        return
    }

    Write-ValidationLog "Validating configuration files..." -Level Info

    $configDir = Join-Path $ProjectRoot "config"

    if (-not (Test-Path $configDir)) {
        Write-ValidationLog "  [MISSING] config/ directory" -Level Error
        $script:ValidationErrors += "Missing config directory"
        return
    }

    $requiredConfigs = @("project.json", "runtime.json")
    $optionalConfigs = @("environment.json")

    foreach ($config in $requiredConfigs) {
        $configPath = Join-Path $configDir $config
        if (Test-Path $configPath) {
            try {
                $null = Get-Content -Path $configPath -Raw | ConvertFrom-Json
                Write-ValidationLog "  [OK] config/$config" -Level Success
            }
            catch {
                Write-ValidationLog "  [INVALID] config/$config - $_" -Level Error
                $script:ValidationErrors += "Invalid JSON in config/$config"
            }
        }
        else {
            Write-ValidationLog "  [MISSING] config/$config (required)" -Level Error
            $script:ValidationErrors += "Missing required config: $config"
        }
    }

    foreach ($config in $optionalConfigs) {
        $configPath = Join-Path $configDir $config
        if (Test-Path $configPath) {
            try {
                $null = Get-Content -Path $configPath -Raw | ConvertFrom-Json
                Write-ValidationLog "  [OK] config/$config" -Level Success
            }
            catch {
                Write-ValidationLog "  [INVALID] config/$config - $_" -Level Warning
                $script:ValidationWarnings += "Invalid JSON in config/$config"
            }
        }
        else {
            Write-ValidationLog "  [MISSING] config/$config (optional)" -Level Warning
            $script:ValidationWarnings += "Missing optional config: $config"
        }
    }
}

function Test-PowerShellSyntax {
    if ($SkipSyntax) {
        Write-ValidationLog "Skipping syntax validation..." -Level Warning
        return
    }

    Write-ValidationLog "Validating PowerShell syntax..." -Level Info

    $scriptsPath = Join-Path $ProjectRoot "scripts"

    if (-not (Test-Path $scriptsPath)) {
        Write-ValidationLog "  [SKIP] scripts/ directory not found" -Level Warning
        return
    }

    $ps1Files = Get-ChildItem -Path $scriptsPath -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue

    if ($ps1Files.Count -eq 0) {
        Write-ValidationLog "  [WARNING] No PowerShell scripts found" -Level Warning
        $script:ValidationWarnings += "No PowerShell scripts found in scripts/"
        return
    }

    foreach ($file in $ps1Files) {
        try {
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $file.FullName -Raw), [ref]$null)
            Write-ValidationLog "  [OK] $($file.Name)" -Level Success
        }
        catch {
            Write-ValidationLog "  [SYNTAX ERROR] $($file.Name) - $_" -Level Error
            $script:ValidationErrors += "Syntax error in $($file.Name)"
        }
    }
}

function Test-RequiredScripts {
    Write-ValidationLog "Validating required scripts..." -Level Info

    $scriptsPath = Join-Path $ProjectRoot "scripts"

    $requiredScripts = @("start.ps1", "stop.ps1")
    $optionalScripts = @("validate.ps1")

    foreach ($script in $requiredScripts) {
        $scriptPath = Join-Path $scriptsPath $script
        if (Test-Path $scriptPath) {
            Write-ValidationLog "  [OK] scripts/$script" -Level Success
        }
        else {
            Write-ValidationLog "  [MISSING] scripts/$script (required)" -Level Error
            $script:ValidationErrors += "Missing required script: $script"
        }
    }

    foreach ($script in $optionalScripts) {
        $scriptPath = Join-Path $scriptsPath $script
        if (Test-Path $scriptPath) {
            Write-ValidationLog "  [OK] scripts/$script (optional)" -Level Success
        }
    }
}

function Get-ValidationSummary {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  Validation Summary" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    if ($script:ValidationErrors.Count -eq 0 -and $script:ValidationWarnings.Count -eq 0) {
        Write-ValidationLog "All validations passed!" -Level Success
        return $true
    }

    if ($script:ValidationErrors.Count -gt 0) {
        Write-ValidationLog "Errors: $($script:ValidationErrors.Count)" -Level Error
        foreach ($error in $script:ValidationErrors) {
            Write-ValidationLog "  - $error" -Level Error
        }
    }

    if ($script:ValidationWarnings.Count -gt 0) {
        Write-ValidationLog "Warnings: $($script:ValidationWarnings.Count)" -Level Warning
        foreach ($warning in $script:ValidationWarnings) {
            Write-ValidationLog "  - $warning" -Level Warning
        }
    }

    if ($script:ValidationErrors.Count -gt 0) {
        Write-Host "`n[RESULT] Validation FAILED" -ForegroundColor Red
        return $false
    }
    else {
        Write-Host "`n[RESULT] Validation PASSED with warnings" -ForegroundColor Yellow
        return $true
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  PowerShell Project Validation" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-ValidationLog "Project Root: $ProjectRoot" -Level Info

Test-DirectoryStructure

Test-ConfigurationFiles

Test-PowerShellSyntax

Test-RequiredScripts

$result = Get-ValidationSummary

if ($result) {
    exit 0
}
else {
    exit 1
}
