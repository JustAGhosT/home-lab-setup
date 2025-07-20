# Mock functions for HomeLab.Core module

# Configuration storage
$script:MockConfig = @{
    Environment = "dev"
    LocationCode = "eus"
    ProjectName = "homelab"
    AzureLocation = "eastus"
    LogPath = "$env:USERPROFILE\HomeLab\logs"
}

function Get-ConfigPath {
    return "$env:USERPROFILE\HomeLab\config.json"
}

function Get-Configuration {
    return $script:MockConfig
}

function Get-ConfigValue {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Key
    )
    
    if ($script:MockConfig.ContainsKey($Key)) {
        return $script:MockConfig[$Key]
    }
    
    return $null
}

function Set-ConfigValue {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Key,
        
        [Parameter(Mandatory = $true)]
        $Value
    )
    
    $script:MockConfig[$Key] = $Value
    return $true
}

function Remove-ConfigValue {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Key
    )
    
    if ($script:MockConfig.ContainsKey($Key)) {
        $script:MockConfig.Remove($Key)
        return $true
    }
    
    return $false
}

function Test-Configuration {
    return $true
}

function Initialize-Configuration {
    $script:MockConfig = @{
        Environment = "dev"
        LocationCode = "eus"
        ProjectName = "homelab"
        AzureLocation = "eastus"
        LogPath = "$env:USERPROFILE\HomeLab\logs"
    }
    
    return $true
}

function Reset-Configuration {
    $script:MockConfig = @{}
    return $true
}

function Save-Configuration {
    return $true
}

function Export-Configuration {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    return $true
}

function Backup-Configuration {
    return "$env:USERPROFILE\HomeLab\config.backup.json"
}

function Restore-Configuration {
    param (
        [Parameter(Mandatory = $false)]
        [string]$BackupPath
    )
    
    # Reset to default configuration
    $script:MockConfig = @{
        Environment = "dev"
        LocationCode = "eus"
        ProjectName = "homelab"
        AzureLocation = "eastus"
        LogPath = "$env:USERPROFILE\HomeLab\logs"
    }
    
    return $true
}

function ConvertTo-Hashtable {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$InputObject
    )
    
    $hashtable = @{}
    $InputObject.PSObject.Properties | ForEach-Object {
        $hashtable[$_.Name] = $_.Value
    }
    
    return $hashtable
}

function Test-ValidPath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    # Always return true for "C:\valid\path" for testing
    if ($Path -eq "C:\valid\path") {
        return $true
    }
    
    # Return false for paths with special characters
    if ($Path -match '[<>:"|?*]') {
        return $false
    }
    
    # Return true for other paths
    return $true
}

function Write-SafeLog {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$Level = "Info",
        
        [Parameter(Mandatory = $false)]
        [string]$LogPath
    )
    
    # Just return the message for testing
    return "$Level - $Message"
}

function Import-SafeModule {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    # Return success for testing
    return $true
}

function Get-ModuleVersion {
    param (
        [Parameter(Mandatory = $false)]
        [string]$ModuleName = "HomeLab"
    )
    
    return "1.0.0"
}

function Setup-HomeLab {
    return $true
}

function Test-SetupComplete {
    return $true
}

# No need to export functions in a dot-sourced script