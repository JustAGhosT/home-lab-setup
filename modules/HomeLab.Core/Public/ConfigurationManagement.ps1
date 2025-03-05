<#
.SYNOPSIS
    Configuration Management Module for Home Lab Setup.
.DESCRIPTION
    Provides functions to load, save, reset, update, and query configuration settings for Home Lab Setup.
    The configuration is stored in a JSON file (e.g., config.json) located in a designated directory.
    This module uses a global configuration variable ($Global:Config) for managing settings.
.NOTES
    Author: Jurie Smit
    Date: March 5, 2025
#>

# Initialize a global configuration variable if it doesn't already exist.
if (-not $Global:Config) {
    $Global:Config = @{
        env                = "dev"
        loc                = "saf"
        project            = "homelab"
        location           = "southafricanorth"
        defaultLogFilePath = "HomeLab_Logs"
        LogFile            = "HomeLab_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    }
}

<#
.SYNOPSIS
    Gets the current configuration settings.
.DESCRIPTION
    Returns the global configuration as a hashtable.
.EXAMPLE
    $config = Get-Configuration
#>
function Get-Configuration {
    [CmdletBinding()]
    param()
    return $Global:Config
}

<#
.SYNOPSIS
    Updates a configuration parameter.
.DESCRIPTION
    Updates a specific configuration parameter in the global configuration.
.PARAMETER Name
    The name of the parameter to update (e.g., "env", "loc", "project", "location").
.PARAMETER Value
    The new value for the parameter.
.EXAMPLE
    Update-ConfigurationParameter -Name "env" -Value "prod"
#>
function Update-ConfigurationParameter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Value
    )
    
    if ($Global:Config.ContainsKey($Name)) {
        $Global:Config[$Name] = $Value
        Write-Log -Message "Configuration parameter '$Name' updated to '$Value'." -Level INFO
        return $true
    }
    else {
        Write-Log -Message "Configuration parameter '$Name' not found." -Level ERROR
        return $false
    }
}

<#
.SYNOPSIS
    Loads configuration from file.
.DESCRIPTION
    Reads configuration settings from the specified JSON file. If the file does not exist,
    it creates a default configuration file.
.PARAMETER ConfigFile
    The path to the configuration file. Defaults to "$env:USERPROFILE\.homelab\config.json".
.EXAMPLE
    Load-Configuration
    $result = Load-Configuration -ConfigFile "C:\Config\homelab.json"
.OUTPUTS
    Boolean. Returns $true if the configuration was loaded successfully, $false otherwise.
#>
function Load-Configuration {
    [CmdletBinding()]
    param(
        [string]$ConfigFile = "$env:USERPROFILE\.homelab\config.json"
    )
    
    if (Test-Path $ConfigFile) {
        try {
            $json = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
            # Update global configuration with the values from the file.
            $Global:Config.env                = $json.env
            $Global:Config.loc                = $json.loc
            $Global:Config.project            = $json.project
            $Global:Config.location           = $json.location
            $Global:Config.defaultLogFilePath = $json.defaultLogFilePath
            
            # Ensure the default log file directory exists.
            if (-not (Test-Path $Global:Config.defaultLogFilePath)) {
                New-Item -ItemType Directory -Path $Global:Config.defaultLogFilePath -Force | Out-Null
            }
            # Update the log file with a new timestamp.
            $Global:Config.LogFile = Join-Path -Path $Global:Config.defaultLogFilePath -ChildPath "HomeLab_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
            
            Write-Log -Message "Configuration loaded successfully from $ConfigFile." -Level INFO
            return $true
        }
        catch {
            Write-Log -Message "Error loading configuration: $_" -Level ERROR
            return $false
        }
    }
    else {
        Write-Log -Message "Configuration file not found at $ConfigFile. Creating default configuration..." -Level WARNING
        
        # Create default configuration.
        $defaultConfig = @{
            env         = "dev"
            loc         = "saf"
            project     = "homelab"
            location    = "southafricanorth"
            defaultLogFilePath = "HomeLab_Logs"
            LogFile     = "HomeLab_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
            LastUpdated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        }
        
        # Create the directory if it doesn't exist.
        $configDir = Split-Path -Parent $ConfigFile
        if (-not (Test-Path $configDir)) {
            New-Item -Path $configDir -ItemType Directory -Force | Out-Null
        }
        
        # Save the default configuration.
        $defaultConfig | ConvertTo-Json | Out-File -FilePath $ConfigFile -Force
        Write-Log -Message "Created default configuration file at $ConfigFile." -Level INFO
        
        return $defaultConfig
    }
}

<#
.SYNOPSIS
    Saves configuration to file.
.DESCRIPTION
    Writes the current global configuration to the specified JSON file.
.PARAMETER ConfigFile
    The path to the configuration file. Defaults to "$env:USERPROFILE\.homelab\config.json".
.EXAMPLE
    Save-Configuration
    $result = Save-Configuration -ConfigFile "C:\Config\homelab.json"
.OUTPUTS
    Boolean. Returns $true if configuration was saved successfully, $false otherwise.
#>
function Save-Configuration {
    [CmdletBinding()]
    param(
        [string]$ConfigFile = "$env:USERPROFILE\.homelab\config.json"
    )
    try {
        $Global:Config | ConvertTo-Json -Depth 5 | Out-File -FilePath $ConfigFile -Force
        Write-Log -Message "Configuration saved successfully to $ConfigFile." -Level INFO
        return $true
    }
    catch {
        Write-Log -Message "Error saving configuration: $_" -Level ERROR
        return $false
    }
}

<#
.SYNOPSIS
    Resets configuration to default values.
.DESCRIPTION
    Resets all configuration parameters to default values and saves the configuration.
.EXAMPLE
    Reset-Configuration
#>
function Reset-Configuration {
    $Global:Config.env                = "dev"
    $Global:Config.loc                = "saf"
    $Global:Config.project            = "homelab"
    $Global:Config.location           = "southafricanorth"
    $Global:Config.defaultLogFilePath = "HomeLab_Logs"
    $Global:Config.LogFile            = "HomeLab_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    
    if (Save-Configuration) {
        Write-Log -Message "Configuration reset to default values." -Level SUCCESS
        return $true
    }
    else {
        Write-Log -Message "Failed to reset configuration to default values." -Level ERROR
        return $false
    }
}

<#
.SYNOPSIS
    Updates the configuration.
.DESCRIPTION
    Updates the configuration with the provided hashtable and saves it to the config file.
.PARAMETER ConfigData
    A hashtable containing configuration values to update.
.PARAMETER ConfigFile
    Optional path to the configuration file. Defaults to "$env:USERPROFILE\.homelab\config.json".
.EXAMPLE
    Set-Configuration -ConfigData @{ env = "prod"; loc = "we" }
#>
function Set-Configuration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$ConfigData,
        [Parameter(Mandatory = $false)]
        [string]$ConfigFile = "$env:USERPROFILE\.homelab\config.json"
    )
    
    try {
        if (Test-Path $ConfigFile) {
            $currentConfig = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
            $configObj = [PSCustomObject]$currentConfig
        }
        else {
            $configObj = [PSCustomObject]@{}
        }
        
        foreach ($key in $ConfigData.Keys) {
            $configObj | Add-Member -MemberType NoteProperty -Name $key -Value $ConfigData[$key] -Force
        }
        
        $configObj | Add-Member -MemberType NoteProperty -Name "LastUpdated" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss") -Force
        
        $configDir = Split-Path -Parent $ConfigFile
        if (-not (Test-Path $configDir)) {
            New-Item -Path $configDir -ItemType Directory -Force | Out-Null
        }
        
        $configObj | ConvertTo-Json | Out-File -FilePath $ConfigFile -Force
        Write-Log -Message "Configuration updated successfully." -Level SUCCESS
        return $true
    }
    catch {
        Write-Log -Message "Error updating configuration: $_" -Level ERROR
        return $false
    }
}

Export-ModuleMember -Function Get-Configuration, Update-ConfigurationParameter, Load-Configuration, Save-Configuration, Reset-Configuration, Set-Configuration
