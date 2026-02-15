# Process Utils

PowerShell 项目进程管理工具模块，提供进程启动、停止和状态检查功能。

## 函数列表

### Start-ProjectProcess

启动项目进程。

```powershell
function Start-ProjectProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$Arguments = "",

        [Parameter(Mandatory = $false)]
        [string]$WorkingDirectory = $PWD,

        [Parameter(Mandatory = $false)]
        [switch]$NoWindow,

        [Parameter(Mandatory = $false)]
        [switch]$WaitForExit
    )

    if (-not (Test-Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        return $null
    }

    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = $FilePath
    $processInfo.WorkingDirectory = $WorkingDirectory

    if ($Arguments) {
        $processInfo.Arguments = $Arguments
    }

    if ($NoWindow) {
        $processInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        $processInfo.UseShellExecute = $false
    }

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $processInfo

    try {
        $process.Start() | Out-Null

        Write-Log -Message "Process started: $FilePath $Arguments" -Level Success

        if ($WaitForExit) {
            $process.WaitForExit()
            return $process.ExitCode
        }

        return $process
    }
    catch {
        Write-Log -Message "Failed to start process: $_" -Level Error
        return $null
    }
}
```

### Stop-ProjectProcess

停止项目进程。

```powershell
function Stop-ProjectProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProcessName,

        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 30,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    $processes = Get-ProjectProcess -ProcessName $ProcessName

    if ($processes.Count -eq 0) {
        Write-Log -Message "No process found with name: $ProcessName" -Level Warning
        return $true
    }

    foreach ($process in $processes) {
        try {
            if (-not $Force) {
                $process.CloseMainWindow() | Out-Null

                $exited = $process.WaitForExit($TimeoutSeconds * 1000)

                if (-not $exited) {
                    Write-Log -Message "Process did not exit gracefully, forcing..." -Level Warning
                    $process.Kill()
                }
            }
            else {
                $process.Kill()
            }

            $process.Dispose()
            Write-Log -Message "Process stopped: $ProcessName (PID: $($process.Id))" -Level Success
        }
        catch {
            Write-Log -Message "Failed to stop process: $_" -Level Error
            return $false
        }
    }

    return $true
}
```

### Get-ProjectProcess

获取项目进程。

```powershell
function Get-ProjectProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProcessName
    )

    $processes = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue

    if (-not $processes) {
        $processes = Get-Process -Filter "*$ProcessName*" -ErrorAction SilentlyContinue
    }

    return $processes
}
```

### Test-ProcessRunning

检查进程是否正在运行。

```powershell
function Test-ProcessRunning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProcessName
    )

    $processes = Get-ProjectProcess -ProcessName $ProcessName

    return ($null -ne $processes -and $processes.Count -gt 0)
}
```

### Wait-ForProcess

等待进程启动或退出。

```powershell
function Wait-ForProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProcessName,

        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 60,

        [Parameter(Mandatory = $false)]
        [switch]$WaitForExit
    )

    $startTime = Get-Date

    while ($true) {
        $running = Test-ProcessRunning -ProcessName $ProcessName

        if ($WaitForExit -and -not $running) {
            return $true
        }

        if (-not $WaitForExit -and $running) {
            return $true
        }

        $elapsed = (Get-Date) - $startTime
        if ($elapsed.TotalSeconds -ge $TimeoutSeconds) {
            Write-Log -Message "Timeout waiting for process: $ProcessName" -Level Warning
            return $false
        }

        Start-Sleep -Milliseconds 500
    }
}
```

### Start-PowerShellScript

启动 PowerShell 脚本。

```powershell
function Start-PowerShellScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $false)]
        [string]$Arguments = "",

        [Parameter(Mandatory = $false)]
        [string]$WorkingDirectory = $PWD,

        [Parameter(Mandatory = $false)]
        [switch]$NoWindow,

        [Parameter(Mandatory = $false)]
        [switch]$WaitForExit,

        [Parameter(Mandatory = $false)]
        [string]$ExecutionPolicy = "Bypass"
    )

    if (-not (Test-Path $ScriptPath)) {
        Write-Error "Script not found: $ScriptPath"
        return $null
    }

    $psArgs = "-ExecutionPolicy $ExecutionPolicy -NoProfile -File `"$ScriptPath`""
    if ($Arguments) {
        $psArgs += " $Arguments"
    }

    return Start-ProjectProcess `
        -FilePath "powershell.exe" `
        -Arguments $psArgs `
        -WorkingDirectory $WorkingDirectory `
        -NoWindow:$NoWindow `
        -WaitForExit:$WaitForExit
}
```

### Stop-AllProjectProcesses

停止所有项目相关进程。

```powershell
function Stop-AllProjectProcesses {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$ProcessNames,

        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 30,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    $results = @{}

    foreach ($name in $ProcessNames) {
        $results[$name] = Stop-ProjectProcess `
            -ProcessName $name `
            -TimeoutSeconds $TimeoutSeconds `
            -Force:$Force
    }

    return $results
}
```

### Get-ProcessInfo

获取进程详细信息。

```powershell
function Get-ProcessInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProcessName
    )

    $processes = Get-ProjectProcess -ProcessName $ProcessName

    if ($processes.Count -eq 0) {
        return $null
    }

    $info = @()

    foreach ($process in $processes) {
        $info += [PSCustomObject]@{
            Name        = $process.ProcessName
            Id          = $process.Id
            CPU         = $process.CPU
            MemoryMB    = [math]::Round($process.WorkingSet64 / 1MB, 2)
            StartTime   = $process.StartTime
            Status      = if ($process.HasExited) { "Exited" } else { "Running" }
        }
    }

    return $info
}
```
