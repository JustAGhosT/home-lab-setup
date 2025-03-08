<#
.SYNOPSIS
    HomeLab.Utils module.
.DESCRIPTION
    This module provides utility functions for HomeLab environment.
.NOTES
    Author: Jurie Smit
    Date: March 8, 2025
#>

# Save original preferences to restore later
$originalPSModuleAutoLoadingPreference = $PSModuleAutoLoadingPreference
$originalDebugPreference = $DebugPreference
$originalVerbosePreference = $VerbosePreference
$originalErrorActionPreference = $ErrorActionPreference

# Disable automatic module loading to prevent recursive loading
$PSModuleAutoLoadingPreference = 'None'
$DebugPreference = 'SilentlyContinue'
$VerbosePreference = 'Continue' # Force verbose output for diagnostics
$ErrorActionPreference = 'Continue'

# Create a guard to prevent recursive loading
if ($script:IsLoading) {
    Write-Warning "Module is already loading. Preventing recursive loading."
    $PSModuleAutoLoadingPreference = $originalPSModuleAutoLoadingPreference
    $DebugPreference = $originalDebugPreference
    $VerbosePreference = $originalVerbosePreference
    $ErrorActionPreference = $originalErrorActionPreference
    return
}
$script:IsLoading = $true

try {
    # Diagnostic information
    Write-Verbose "Module Root: $PSScriptRoot"
    Write-Verbose "Looking for private functions in: $PSScriptRoot\Private"
    Write-Verbose "Looking for public functions in: $PSScriptRoot\Public"
    
    # Initialize the global configuration with default values
    if (-not $Global:Config) {
        $Global:Config = @{
            # Default configuration values
            env = "dev"
            loc = "saf"
            project = "homelab"
            location = "southafricanorth"
            LogFile = "$env:USERPROFILE\.homelab\logs\homelab.log"
            ConfigFile = "$env:USERPROFILE\.homelab\config.json"
        }
    }

    # Get all private functions
    $privateFunctions = Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -Recurse -ErrorAction SilentlyContinue
    Write-Verbose "Found $($privateFunctions.Count) private function files"
    
    foreach ($function in $privateFunctions) {
        try {
            . $function.FullName
            Write-Verbose "Imported private function: $($function.BaseName)"
        }
        catch {
            Write-Warning "Failed to import private function $($function.BaseName): $_"
        }
    }

    # Get all public functions
    $publicFunctions = Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -Recurse -ErrorAction SilentlyContinue
    Write-Verbose "Found $($publicFunctions.Count) public function files"
    
    $publicFunctionNames = @()
    foreach ($function in $publicFunctions) {
        try {
            Write-Verbose "Loading function file: $($function.FullName)"
            . $function.FullName
            $publicFunctionNames += $function.BaseName
            Write-Verbose "Imported public function: $($function.BaseName)"
        }
        catch {
            Write-Warning "Failed to import public function $($function.BaseName): $_"
        }
    }

    # Export all public functions
    Write-Verbose "Exporting $($publicFunctionNames.Count) public functions: $($publicFunctionNames -join ', ')"
    Export-ModuleMember -Function $publicFunctionNames
}
finally {
    # Reset module loading guard
    $script:IsLoading = $false
    
    # Restore original preferences
    $PSModuleAutoLoadingPreference = $originalPSModuleAutoLoadingPreference
    $DebugPreference = $originalDebugPreference
    $VerbosePreference = $originalVerbosePreference
    $ErrorActionPreference = $originalErrorActionPreference
}
