<#
.SYNOPSIS
    Core functionality for HomeLab including configuration management, logging, setup, and prerequisites.
.DESCRIPTION
    This module provides the core functionality for HomeLab including configuration
    management, logging, setup, prerequisites, and other essential utilities.
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>

# Initialize the global configuration if it doesn't exist
if (-not $Global:Config) {
    $Global:Config = @{
        # Default configuration values
        env = "dev"
        loc = "saf"
        project = "homelab"
        location = "Bela Bela"
        LogFile = "$env:USERPROFILE\.homelab\logs\homelab.log"
        ConfigFile = "$env:USERPROFILE\.homelab\config.json"
    }
}

# Get the module path
$ModulePath = $PSScriptRoot

# Load private functions
$PrivateFunctions = Get-ChildItem -Path "$ModulePath\Private\*.ps1" -ErrorAction SilentlyContinue
foreach ($Function in $PrivateFunctions) {
    try {
        . $Function.FullName
    }
    catch {
        Write-Error -Message "Failed to import private function $($Function.FullName): $_"
    }
}

# Load public functions
$PublicFunctions = Get-ChildItem -Path "$ModulePath\Public\*.ps1" -ErrorAction SilentlyContinue
foreach ($Function in $PublicFunctions) {
    try {
        . $Function.FullName
    }
    catch {
        Write-Error -Message "Failed to import public function $($Function.FullName): $_"
    }
}

# Load the configuration if it exists
try {
    # Check if setup is complete
    if (Test-SetupComplete -Silent) {
        Load-Configuration -Silent
    }
}
catch {
    # If loading fails, we'll use the default configuration
    Write-Warning "Failed to load configuration: $_. Using default configuration."
}

# Initialize the log file
try {
    # Create the log directory if it doesn't exist
    $logDir = Split-Path -Path $Global:Config.LogFile -Parent
    if (-not (Test-Path -Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    # Initialize the log file if it doesn't exist
    if (-not (Test-Path -Path $Global:Config.LogFile)) {
        Initialize-LogFile
    }
    
    Write-Log -Message "HomeLab.Core module loaded successfully" -Level Info
}
catch {
    Write-Warning "Failed to initialize log file: $_"
}

# Export public functions
Export-ModuleMember -Function $PublicFunctions.BaseName
