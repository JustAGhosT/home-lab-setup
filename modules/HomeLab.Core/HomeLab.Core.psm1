<#
.SYNOPSIS
    Core functionality for HomeLab including configuration management, logging, setup, and prerequisites.
.DESCRIPTION
    This module provides the core functionality for HomeLab including configuration
    management, logging, setup, prerequisites, and other essential utilities.
.NOTES
    Author: Jurie Smit
    Date: March 8, 2025
#>

# ===== CRITICAL SECTION: PREVENT INFINITE LOOPS =====
# Save original preferences to restore later
$originalPSModuleAutoLoadingPreference = $PSModuleAutoLoadingPreference
$originalDebugPreference = $DebugPreference
$originalVerbosePreference = $VerbosePreference
$originalErrorActionPreference = $ErrorActionPreference

# Disable automatic module loading to prevent recursive loading
$PSModuleAutoLoadingPreference = 'None'
# Disable debugging which can cause infinite loops
$DebugPreference = 'SilentlyContinue'
# Control verbosity
$VerbosePreference = 'SilentlyContinue'
# Make errors non-terminating
$ErrorActionPreference = 'Continue'

# Create a guard to prevent recursive loading
if ($script:IsLoading) {
    Write-Warning "Module is already loading. Preventing recursive loading."
    # Restore original preferences
    $PSModuleAutoLoadingPreference = $originalPSModuleAutoLoadingPreference
    $DebugPreference = $originalDebugPreference
    $VerbosePreference = $originalVerbosePreference
    $ErrorActionPreference = $originalErrorActionPreference
    return
}
$script:IsLoading = $true

try {
    # Get the module path
    $ModulePath = $PSScriptRoot
    $ModuleName = (Get-Item $PSScriptRoot).BaseName

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

    # Create log directory if it doesn't exist
    $logDir = Split-Path -Path $Global:Config.LogFile -Parent
    if (-not (Test-Path -Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    # Create an array to store public function names
    $PublicFunctionNames = @()

    # Import all private functions first
    $PrivateFunctions = Get-ChildItem -Path "$ModulePath\Private\*.ps1" -Recurse -ErrorAction SilentlyContinue
    foreach ($Function in $PrivateFunctions) {
        try {
            . $Function.FullName
            Write-Verbose "Imported private function: $($Function.BaseName)"
        }
        catch {
            Write-Warning "Failed to import private function $($Function.BaseName): $_"
        }
    }

    # Import all public functions and add to export list
    $PublicFunctions = Get-ChildItem -Path "$ModulePath\Public\*.ps1" -Recurse -ErrorAction SilentlyContinue
    foreach ($Function in $PublicFunctions) {
        try {
            . $Function.FullName
            $PublicFunctionNames += $Function.BaseName
            Write-Verbose "Imported public function: $($Function.BaseName)"
        }
        catch {
            Write-Warning "Failed to import public function $($Function.BaseName): $_"
        }
    }

    # Export all public functions
    Export-ModuleMember -Function $PublicFunctionNames

    # Display functions defined in this module
    Write-Host "Functions defined in this module:" -ForegroundColor Cyan
    Get-Command -Module $ModuleName | ForEach-Object { 
        Write-Host "  - $($_.Name)" -ForegroundColor Cyan 
    }
}
finally {
    # ===== CLEANUP SECTION =====
    # Reset module loading guard
    $script:IsLoading = $false
    
    # Restore original preferences
    $PSModuleAutoLoadingPreference = $originalPSModuleAutoLoadingPreference
    $DebugPreference = $originalDebugPreference
    $VerbosePreference = $originalVerbosePreference
    $ErrorActionPreference = $originalErrorActionPreference
}
