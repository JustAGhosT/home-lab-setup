<#
.SYNOPSIS
    Configuration management for HomeLab environment.
.DESCRIPTION
    Provides functions for managing configuration settings for the HomeLab environment,
    including loading, saving, and modifying configuration values.
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>

# Save original preferences at the beginning of the module
$originalPSModuleAutoLoadingPreference = $PSModuleAutoLoadingPreference
$PSModuleAutoLoadingPreference = 'None'

<#
.SYNOPSIS
    Gets the current configuration.
.DESCRIPTION
    Returns the current global configuration object.
.EXAMPLE
    $config = Get-Configuration
.OUTPUTS
    Hashtable. Returns the global configuration hashtable.
#>
function Get-Configuration {
    [CmdletBinding()]
    param()
    
    return $Global:Config
}

<#
.SYNOPSIS
    Loads configuration from a JSON file.
.DESCRIPTION
    Loads configuration settings from a JSON file and updates the global configuration.
.PARAMETER ConfigFile
    The path to the configuration file. If not specified, uses the default path from global configuration.
.PARAMETER Silent
    If specified, suppresses log messages.
.EXAMPLE
    Import-Configuration -ConfigFile "C:\config.json"
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Import-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigFile = $Global:Config.ConfigFile,
        
        [Parameter(Mandatory = $false)]
        [switch]$Silent
    )
    
    Write-SafeLog -Message "Loading configuration from $ConfigFile" -Level Info -NoOutput:$Silent
    
    if (-not (Test-Path -Path $ConfigFile)) {
        Write-SafeLog -Message "Configuration file not found: $ConfigFile" -Level Warning -NoOutput:$Silent
        return $false
    }
    
    try {
        $configJson = Get-Content -Path $ConfigFile -Raw
        $config = $configJson | ConvertFrom-Json -AsHashtable
        
        # Update global configuration
        foreach ($key in $config.Keys) {
            $Global:Config[$key] = $config[$key]
        }
        
        Write-SafeLog -Message "Configuration loaded successfully." -Level Success -NoOutput:$Silent
        return $true
    }
    catch {
        Write-SafeLog -Message "Failed to load configuration: $_" -Level Error -NoOutput:$Silent
        return $false
    }
}

<#
.SYNOPSIS
    Saves configuration to a JSON file.
.DESCRIPTION
    Saves the current global configuration to a JSON file.
.PARAMETER ConfigFile
    The path to the configuration file. If not specified, uses the default path from global configuration.
.PARAMETER Silent
    If specified, suppresses log messages.
.EXAMPLE
    Save-Configuration -ConfigFile "C:\config.json"
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Save-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigFile = $Global:Config.ConfigFile,
        
        [Parameter(Mandatory = $false)]
        [switch]$Silent
    )
    
    Write-SafeLog -Message "Saving configuration to $ConfigFile" -Level Info -NoOutput:$Silent
    
    try {
        # Create directory if it doesn't exist
        $configDir = Split-Path -Path $ConfigFile -Parent
        if (-not (Test-Path -Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        # Convert configuration to JSON and save
        $configJson = $Global:Config | ConvertTo-Json -Depth 5
        Set-Content -Path $ConfigFile -Value $configJson -Force
        
        Write-SafeLog -Message "Configuration saved successfully." -Level Success -NoOutput:$Silent
        return $true
    }
    catch {
        Write-SafeLog -Message "Failed to save configuration: $_" -Level Error -NoOutput:$Silent
        return $false
    }
}

<#
.SYNOPSIS
    Gets a configuration value.
.DESCRIPTION
    Gets a value from the global configuration.
.PARAMETER Key
    The key of the configuration value to get.
.PARAMETER DefaultValue
    The default value to return if the key is not found.
.EXAMPLE
    Get-ConfigValue -Key "env" -DefaultValue "dev"
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Get-ConfigValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key,
        
        [Parameter(Mandatory = $false)]
        $DefaultValue = $null
    )
    
    if ($Global:Config.ContainsKey($Key)) {
        return $Global:Config[$Key]
    }
    
    return $DefaultValue
}

<#
.SYNOPSIS
    Sets a configuration value.
.DESCRIPTION
    Sets a value in the global configuration and optionally saves the configuration.
.PARAMETER Key
    The key of the configuration value to set.
.PARAMETER Value
    The value to set.
.PARAMETER Save
    If specified, saves the configuration after setting the value.
.EXAMPLE
    Set-ConfigValue -Key "env" -Value "prod" -Save
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Set-ConfigValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key,
        
        [Parameter(Mandatory = $true)]
        $Value,
        
        [Parameter(Mandatory = $false)]
        [switch]$Save
    )
    
    $oldValue = $null
    if ($Global:Config.ContainsKey($Key)) {
        $oldValue = $Global:Config[$Key]
    }
    
    $Global:Config[$Key] = $Value
    
    Write-SafeLog -Message "Configuration value '$Key' updated: '$oldValue' -> '$Value'" -Level Info
    
    if ($Save) {
        Save-Configuration
    }
    
    return $true
}

<#
.SYNOPSIS
    Removes a configuration value.
.DESCRIPTION
    Removes a value from the global configuration and optionally saves the configuration.
.PARAMETER Key
    The key of the configuration value to remove.
.PARAMETER Save
    If specified, saves the configuration after removing the value.
.EXAMPLE
    Remove-ConfigValue -Key "tempValue" -Save
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Remove-ConfigValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key,
        
        [Parameter(Mandatory = $false)]
        [switch]$Save
    )
    
    if (-not $Global:Config.ContainsKey($Key)) {
        Write-SafeLog -Message "Configuration value '$Key' not found." -Level Warning
        return $false
    }
    
    $oldValue = $Global:Config[$Key]
    $Global:Config.Remove($Key)
    
    Write-SafeLog -Message "Configuration value '$Key' removed. Old value: '$oldValue'" -Level Info
    
    if ($Save) {
        Save-Configuration
    }
    
    return $true
}

<#
.SYNOPSIS
    Resets the configuration to default values.
.DESCRIPTION
    Resets the global configuration to default values and optionally saves the configuration.
.PARAMETER Save
    If specified, saves the configuration after resetting.
.EXAMPLE
    Reset-Configuration -Save
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Reset-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Save
    )
    
    Write-SafeLog -Message "Resetting configuration to default values." -Level Info
    
    # Save the current ConfigFile path
    $configFile = $Global:Config.ConfigFile
    $logFile = $Global:Config.LogFile
    
    # Create default configuration
    $Global:Config = @{
        env        = "dev"
        loc        = "we"
        project    = "homelab"
        location   = "westeurope"
        LogFile    = $logFile
        ConfigFile = $configFile
        LastSetup  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    Write-SafeLog -Message "Configuration reset to default values." -Level Success
    
    if ($Save) {
        Save-Configuration
    }
    
    return $true
}

<#
.SYNOPSIS
    Gets the path to the configuration file.
.DESCRIPTION
    Returns the path to the current configuration file.
.EXAMPLE
    $configPath = Get-ConfigPath
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Get-ConfigPath {
    [CmdletBinding()]
    param()
    
    return $Global:Config.ConfigFile
}

<#
.SYNOPSIS
    Updates multiple configuration parameters.
.DESCRIPTION
    Updates multiple parameters in the global configuration.
.PARAMETER ConfigData
    A hashtable containing parameter names and values to update.
.PARAMETER Persist
    If specified, saves the updated configuration to the configuration file.
.EXAMPLE
    Set-Configuration -ConfigData @{ env = "prod"; loc = "we" } -Persist
.OUTPUTS
    None.
#>
function Set-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ConfigData,
        
        [Parameter(Mandatory = $false)]
        [switch]$Persist
    )
    
    # Update the global configuration with the provided data
    foreach ($key in $ConfigData.Keys) {
        $Global:Config[$key] = $ConfigData[$key]
    }
    
    Write-SafeLog -Message "Configuration updated with $(($ConfigData.Keys -join ', '))" -Level Info
    
    # Save the configuration if requested
    if ($Persist) {
        Save-Configuration
    }
}

<#
.SYNOPSIS
    Validates the current configuration.
.DESCRIPTION
    Checks if the current configuration contains all required parameters and if they have valid values.
.EXAMPLE
    Test-Configuration
.OUTPUTS
    PSObject. Returns an object with validation results.
#>
function Test-Configuration {
    [CmdletBinding()]
    param()
    
    $validationResults = @{
        IsValid           = $true
        MissingParameters = @()
        InvalidParameters = @()
    }
    
    # Required parameters
    $requiredParams = @('env', 'loc', 'project', 'location', 'LogFile', 'ConfigFile')
    
    # Valid values for certain parameters
    $validValues = @{
        env = @('dev', 'test', 'prod')
        loc = @('saf', 'we', 'ea')
    }
    
    # Check for missing parameters
    foreach ($param in $requiredParams) {
        if (-not $Global:Config.ContainsKey($param) -or [string]::IsNullOrEmpty($Global:Config[$param])) {
            $validationResults.IsValid = $false
            $validationResults.MissingParameters += $param
        }
    }
    
    # Check for invalid values
    foreach ($param in $validValues.Keys) {
        if ($Global:Config.ContainsKey($param) -and -not [string]::IsNullOrEmpty($Global:Config[$param])) {
            if ($validValues[$param] -notcontains $Global:Config[$param]) {
                $validationResults.IsValid = $false
                $validationResults.InvalidParameters += @{
                    Parameter   = $param
                    Value       = $Global:Config[$param]
                    ValidValues = $validValues[$param]
                }
            }
        }
    }
    
    return [PSCustomObject]$validationResults
}

<#
.SYNOPSIS
    Backs up the current configuration.
.DESCRIPTION
    Creates a backup of the current configuration file with a timestamp.
.PARAMETER ConfigFile
    The path to the configuration file. Defaults to the path in the global configuration.
.EXAMPLE
    Backup-Configuration
.OUTPUTS
    String. Returns the path to the backup file if successful, $null otherwise.
#>
function Backup-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigFile = $Global:Config.ConfigFile
    )
    
    if (Test-Path $ConfigFile) {
        try {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $backupDir = Join-Path -Path (Split-Path -Parent $ConfigFile) -ChildPath "Backups"
            
            if (-not (Test-Path $backupDir)) {
                New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
            }
            
            $backupFile = Join-Path -Path $backupDir -ChildPath "config_$timestamp.json"
            Copy-Item -Path $ConfigFile -Destination $backupFile -Force
            
            Write-SafeLog -Message "Configuration backed up to $backupFile." -Level Info
            return $backupFile
        }
        catch {
            Write-SafeLog -Message "Error backing up configuration: ${_}" -Level Error
            return $null
        }
    }
    else {
        Write-SafeLog -Message "Configuration file not found at $ConfigFile." -Level Error
        return $null
    }
}

<#
.SYNOPSIS
    Restores a configuration from backup.
.DESCRIPTION
    Restores the configuration from a specified backup file.
.PARAMETER BackupFile
    The path to the backup file to restore from.
.PARAMETER ConfigFile
    The path to the configuration file. Defaults to the path in the global configuration.
.EXAMPLE
    Restore-Configuration -BackupFile "$env:USERPROFILE\.homelab\Backups\config_20250305_123456.json"
.OUTPUTS
    Boolean. Returns $true if the configuration was restored successfully, $false otherwise.
#>
function Restore-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupFile,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigFile = $Global:Config.ConfigFile
    )
    
    if (Test-Path $BackupFile) {
        try {
            # Create a backup of the current configuration before restoring
            Backup-Configuration -ConfigFile $ConfigFile | Out-Null
            
            # Restore from the backup file
            Copy-Item -Path $BackupFile -Destination $ConfigFile -Force
            
            # Reload the configuration
            Import-Configuration -ConfigFile $ConfigFile | Out-Null
            
            Write-SafeLog -Message "Configuration restored from $BackupFile." -Level Info
            return $true
        }
        catch {
            Write-SafeLog -Message "Error restoring configuration: $_" -Level Error
            return $false
        }
    }
    else {
        Write-SafeLog -Message "Backup file not found at $BackupFile." -Level Error
        return $false
    }
}

<#
.SYNOPSIS
    Exports the current configuration to a file in various formats.
.DESCRIPTION
    Exports the current global configuration to a file in JSON, CSV, XML, or YAML format.
    This allows sharing configuration with other systems or creating configuration templates.
.PARAMETER Path
    The path where the configuration will be exported. If not specified, uses the default path with appropriate extension.
.PARAMETER Format
    The format to export the configuration in. Valid values are JSON, CSV, XML, and YAML. Default is JSON.
.PARAMETER IncludeTimestamp
    If specified, includes a timestamp in the filename.
.PARAMETER ExcludeKeys
    An array of keys to exclude from the export.
.PARAMETER AsTemplate
    If specified, removes environment-specific values to create a template.
.EXAMPLE
    Export-Configuration -Path "C:\Configs\exported_config.json"
.EXAMPLE
    Export-Configuration -Format XML -IncludeTimestamp
.EXAMPLE
    Export-Configuration -Format YAML -ExcludeKeys @('LogFile', 'LastSetup') -AsTemplate
.NOTES
    Author: Jurie Smit
    Date: March 8, 2025
#>
function Export-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "CSV", "XML", "YAML")]
        [string]$Format = "JSON",
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeTimestamp,
        
        [Parameter(Mandatory = $false)]
        [string[]]$ExcludeKeys = @(),
        
        [Parameter(Mandatory = $false)]
        [switch]$AsTemplate
    )
    
    # Generate default path if not specified
    if ([string]::IsNullOrEmpty($Path)) {
        $configDir = Split-Path -Path $Global:Config.ConfigFile -Parent
        $fileName = "config_export"
        
        if ($IncludeTimestamp) {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $fileName = "${fileName}_${timestamp}"
        }
        
        $extension = switch ($Format.ToLower()) {
            "json" { ".json" }
            "csv"  { ".csv" }
            "xml"  { ".xml" }
            "yaml" { ".yaml" }
            default { ".json" }
        }
        
        $Path = Join-Path -Path $configDir -ChildPath "${fileName}${extension}"
    }
    
    try {
        # Create a copy of the configuration to modify
        $exportConfig = $Global:Config.Clone()
        
        # Remove excluded keys
        foreach ($key in $ExcludeKeys) {
            if ($exportConfig.ContainsKey($key)) {
                $exportConfig.Remove($key)
            }
        }
        
        # If creating a template, remove environment-specific values
        if ($AsTemplate) {
            $templateExcludeKeys = @('LastSetup', 'LogFile', 'ConfigFile')
            foreach ($key in $templateExcludeKeys) {
                if ($exportConfig.ContainsKey($key)) {
                    $exportConfig.Remove($key)
                }
            }
            
            # Reset environment-specific values to placeholders
            if ($exportConfig.ContainsKey('env')) {
                $exportConfig['env'] = "{{environment}}"
            }
            if ($exportConfig.ContainsKey('project')) {
                $exportConfig['project'] = "{{project_name}}"
            }
        }
        
        # Create directory if it doesn't exist
        $exportDir = Split-Path -Path $Path -Parent
        if (-not (Test-Path -Path $exportDir)) {
            New-Item -ItemType Directory -Path $exportDir -Force | Out-Null
        }
        
        # Export based on format
        switch ($Format.ToLower()) {
            "json" {
                $exportConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Force
            }
            "csv" {
                # Convert hashtable to PSObject for CSV export
                $csvObject = New-Object PSObject
                foreach ($key in $exportConfig.Keys) {
                    # Handle nested objects by converting them to JSON strings
                    if ($exportConfig[$key] -is [System.Collections.IDictionary] -or $exportConfig[$key] -is [Array]) {
                        $csvObject | Add-Member -MemberType NoteProperty -Name $key -Value (ConvertTo-Json -InputObject $exportConfig[$key] -Compress)
                    }
                    else {
                        $csvObject | Add-Member -MemberType NoteProperty -Name $key -Value $exportConfig[$key]
                    }
                }
                $csvObject | Export-Csv -Path $Path -NoTypeInformation -Force
            }
            "xml" {
                # Convert hashtable to PSObject for XML export
                $xmlObject = New-Object PSObject
                foreach ($key in $exportConfig.Keys) {
                    $xmlObject | Add-Member -MemberType NoteProperty -Name $key -Value $exportConfig[$key]
                }
                $xmlObject | Export-Clixml -Path $Path -Force
            }
            "yaml" {
                # Check if PowerShell-YAML module is installed
                if (-not (Get-Module -ListAvailable -Name PowerShell-YAML)) {
                    Write-SafeLog -Message "PowerShell-YAML module not found. Please install it using 'Install-Module -Name PowerShell-YAML'." -Level Error
                    return $false
                }
                
                # Import the module
                Import-Module -Name PowerShell-YAML
                
                # Convert to YAML and export
                $yamlContent = $exportConfig | ConvertTo-Yaml
                Set-Content -Path $Path -Value $yamlContent -Force
            }
        }
        
        Write-SafeLog -Message "Configuration exported to $Path in $Format format." -Level Success
        return $Path
    }
    catch {
        Write-SafeLog -Message "Failed to export configuration: $_" -Level Error
        return $false
    }
}

# Restore original preferences
$PSModuleAutoLoadingPreference = $originalPSModuleAutoLoadingPreference