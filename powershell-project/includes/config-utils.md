# Config Utils

PowerShell 项目配置工具模块，提供配置读取和验证功能。

## 函数列表

### Get-ProjectConfig

读取 JSON 配置文件。

```powershell
function Get-ProjectConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    if (-not (Test-Path $ConfigPath)) {
        Write-Error "Configuration file not found: $ConfigPath"
        return $null
    }

    try {
        $content = Get-Content -Path $ConfigPath -Raw -Encoding UTF8
        $config = $content | ConvertFrom-Json
        return $config
    }
    catch {
        Write-Error "Failed to parse configuration file: $_"
        return $null
    }
}
```

### Get-AllConfigs

读取所有配置文件。

```powershell
function Get-AllConfigs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigDir = "config"
    )

    $configs = @{}

    $configFiles = @("project.json", "runtime.json", "environment.json")

    foreach ($file in $configFiles) {
        $path = Join-Path $ConfigDir $file
        if (Test-Path $path) {
            $name = [System.IO.Path]::GetFileNameWithoutExtension($file)
            $configs[$name] = Get-ProjectConfig -ConfigPath $path
        }
    }

    return $configs
}
```

### Test-ConfigValid

验证配置是否有效。

```powershell
function Test-ConfigValid {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Config,

        [Parameter(Mandatory = $false)]
        [string[]]$RequiredFields
    )

    if ($null -eq $Config) {
        return $false
    }

    if ($RequiredFields) {
        foreach ($field in $RequiredFields) {
            if (-not $Config.PSObject.Properties.Name -contains $field) {
                Write-Warning "Missing required field: $field"
                return $false
            }
        }
    }

    return $true
}
```

### Set-ProjectConfig

保存配置到 JSON 文件。

```powershell
function Set-ProjectConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath,

        [Parameter(Mandatory = $true)]
        [object]$Config
    )

    try {
        $json = $Config | ConvertTo-Json -Depth 10
        $json | Set-Content -Path $ConfigPath -Encoding UTF8
        return $true
    }
    catch {
        Write-Error "Failed to save configuration: $_"
        return $false
    }
}
```

### Merge-Config

合并多个配置对象。

```powershell
function Merge-Config {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$BaseConfig,

        [Parameter(Mandatory = $true)]
        [object]$OverrideConfig
    )

    $result = $BaseConfig.PSObject.Copy()

    foreach ($property in $OverrideConfig.PSObject.Properties) {
        $result.$($property.Name) = $property.Value
    }

    return $result
}
```

### Get-ConfigValue

获取配置中的特定值，支持默认值。

```powershell
function Get-ConfigValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Config,

        [Parameter(Mandatory = $true)]
        [string]$Key,

        [Parameter(Mandatory = $false)]
        [object]$DefaultValue = $null
    )

    if ($Config.PSObject.Properties.Name -contains $Key) {
        return $Config.$Key
    }

    return $DefaultValue
}
