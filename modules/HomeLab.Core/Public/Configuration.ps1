<#
.SYNOPSIS
    Configuration Management Module for Home Lab Setup.
.DESCRIPTION
    Provides functions for managing configuration settings for the Home Lab environment.
    It uses a global configuration object ($Global:Config) to store settings and supports
    loading and saving configuration to a JSON file.
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>

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
    Updates a specific configuration parameter.
.DESCRIPTION
    Updates a specific parameter in the global configuration.
.PARAMETER Name
    The name of the parameter to update.
.PARAMETER Value
    The new value for the parameter.
.PARAMETER Persist
    If specified, saves the updated configuration to the configuration file.
.EXAMPLE
    Update-ConfigurationParameter -Name "env" -Value "prod" -Persist
.OUTPUTS
    None.
#>
function Update-ConfigurationParameter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [object]$Value,
        
        [Parameter(Mandatory = $false)]
        [switch]$Persist
    )
    
    # Update the parameter in the global configuration
    $Global:Config[$Name] = $Value
    
    # Log the update
    Write-Log -Message "Configuration parameter '$Name' updated to '$Value'" -Level Info
    
    # Save the configuration if requested
    if ($Persist) {
        Save-Configuration
    }
}

<#
.SYNOPSIS
    Loads configuration from a JSON file.
.DESCRIPTION
    Loads configuration settings from a JSON file into the global configuration.
.PARAMETER ConfigFile
    The path to the configuration file. Defaults to the path in the global configuration.
.PARAMETER Silent
    If specified, suppresses non-error messages.
.EXAMPLE
    Load-Configuration -ConfigFile "C:\Config\homelab.json"
.OUTPUTS
    Boolean. Returns $true if the configuration was loaded successfully, $false otherwise.
#>
function Load-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigFile = $Global:Config.ConfigFile,
        
        [Parameter(Mandatory = $false)]
        [switch]$Silent
    )
    
    # Check if the configuration file exists
    if (Test-Path -Path $ConfigFile) {
        try {
            # Load the configuration from the file
            $configData = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
            
            # Update the global configuration with the loaded data
            foreach ($property in $configData.PSObject.Properties) {
                $Global:Config[$property.Name] = $property.Value
            }
            
            if (-not $Silent) {
                Write-Log -Message "Configuration loaded from $ConfigFile" -Level Info
            }
            
            return $true
        }
        catch {
            Write-Log -Message "Error loading configuration from $ConfigFile: $_" -Level Error
            return $false
        }
    }
    else {
        if (-not $Silent) {
            Write-Log -Message "Configuration file not found at $ConfigFile. Using default configuration." -Level Warning
        }
        return $false
    }
}

<#
.SYNOPSIS
    Saves configuration to a JSON file.
.DESCRIPTION
    Saves the current global configuration to a JSON file.
.PARAMETER ConfigFile
    The path to the configuration file. Defaults to the path in the global configuration.
.EXAMPLE
    Save-Configuration -ConfigFile "C:\Config\homelab.json"
.OUTPUTS
    Boolean. Returns $true if the configuration was saved successfully, $false otherwise.
#>
function Save-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigFile = $Global:Config.ConfigFile
    )
    
    try {
        # Create the directory if it doesn't exist
        $configDir = Split-Path -Path $ConfigFile -Parent
        if (-not (Test-Path -Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        # Save the configuration to the file
        $Global:Config | ConvertTo-Json -Depth 5 | Out-File -FilePath $ConfigFile -Force
        
        Write-Log -Message "Configuration saved to $ConfigFile" -Level Info
        return $true
    }
    catch {
        Write-Log -Message "Error saving configuration to $ConfigFile: $_" -Level Error
        return $false
    }
}

<#
.SYNOPSIS
    Resets configuration to default values.
.DESCRIPTION
    Resets the global configuration to default values.
.PARAMETER Persist
    If specified, saves the reset configuration to the configuration file.
.EXAMPLE
    Reset-Configuration -Persist
.OUTPUTS
    None.
#>
function Reset-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Persist
    )
    
    # Define default configuration values
    $defaultConfig = @{
        env = "dev"
        loc = "saf"
        project = "homelab"
        location = "Bela Bela"
        LogFile = "$env:USERPROFILE\.homelab\logs\homelab.log"
        ConfigFile = "$env:USERPROFILE\.homelab\config.json"
    }
    
    # Update the global configuration with default values
    $Global:Config = $defaultConfig
    
    Write-Log -Message "Configuration reset to default values" -Level Info
    
    # Save the configuration if requested
    if ($Persist) {
        Save-Configuration
    }
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
    
    Write-Log -Message "Configuration updated with $(($ConfigData.Keys -join ', '))" -Level Info
    
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
        IsValid = $true
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
                    Parameter = $param
                    Value = $Global:Config[$param]
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
            
            Write-Log -Message "Configuration backed up to $backupFile." -Level Info
            return $backupFile
        }
        catch {
            Write-Log -Message "Error backing up configuration: $_" -Level Error
            return $null
        }
    }
    else {
        Write-Log -Message "Configuration file not found at $ConfigFile." -Level Error
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
            Load-Configuration -ConfigFile $ConfigFile | Out-Null
            
            Write-Log -Message "Configuration restored from $BackupFile." -Level Info
            return $true
        }
        catch {
            Write-Log -Message "Error restoring configuration: $_" -Level Error
            return $false
        }
    }
    else {
        Write-Log -Message "Backup file not found at $BackupFile." -Level Error
        return $false
    }
}

<#
.SYNOPSIS
    Exports configuration to a specified file.
.DESCRIPTION
    Exports the current configuration to a specified file in JSON format.
.PARAMETER ExportPath
    The path to export the configuration to.
.EXAMPLE
    Export-HomelabConfiguration -ExportPath "C:\Temp\homelab-config.json"
.OUTPUTS
    Boolean. Returns $true if the configuration was exported successfully, $false otherwise.
#>
function Export-HomelabConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ExportPath
    )
    
    try {
        $config = Get-Configuration
        $config | ConvertTo-Json -Depth 5 | Out-File -FilePath $ExportPath -Force
        Write-Log -Message "Configuration exported to $ExportPath." -Level Info
        return $true
    }
    catch {
        Write-Log -Message "Error exporting configuration: $_" -Level Error
        return $false
    }
}

<#
.SYNOPSIS
    Imports configuration from a specified file.
.DESCRIPTION
    Imports configuration from a specified JSON file and updates the current configuration.
.PARAMETER ImportPath
    The path to import the configuration from.
.EXAMPLE
    Import-HomelabConfiguration -ImportPath "C:\Temp\homelab-config.json"
.OUTPUTS
    Boolean. Returns $true if the configuration was imported successfully, $false otherwise.
#>
function Import-HomelabConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ImportPath
    )
    
    if (Test-Path $ImportPath) {
        try {
            $importedConfig = Get-Content -Path $ImportPath -Raw | ConvertFrom-Json
            
            # Convert the imported JSON to a hashtable
            $configData = @{}
            $importedConfig.PSObject.Properties | ForEach-Object {
                $configData[$_.Name] = $_.Value
            }
            
            # Update the configuration
            Set-Configuration -ConfigData $configData
            
            Write-Log -Message "Configuration imported from $ImportPath." -Level Info
            return $true
        }
        catch {
            Write-Log -Message "Error importing configuration: $_" -Level Error
            return $false
        }
    }
    else {
        Write-Log -Message "Import file not found at $ImportPath." -Level Error
        return $false
    }
}
