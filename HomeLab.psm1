<#
.SYNOPSIS
    HomeLab Aggregator Module
.DESCRIPTION
    Aggregates functionality from HomeLab.Core, HomeLab.Azure, HomeLab.Security, HomeLab.UI, and HomeLab.Monitoring.
    Provides the high-level Start-HomeLab function as the main entry point for the application.
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
    Version: 1.0.0
#>

# ===== CRITICAL SECTION: PREVENT INFINITE LOOPS =====
# Disable automatic module loading to prevent recursive loading
$PSModuleAutoLoadingPreference = 'None'
# Disable function discovery debugging which can cause infinite loops
$DebugPreference = 'SilentlyContinue'

# Save the original PSDefaultParameterValues at the start to prevent infinite loops
$originalPSDefaultParameterValues = $null
if ($global:PSDefaultParameterValues) {
    $originalPSDefaultParameterValues = $global:PSDefaultParameterValues.Clone()
    # Clear it to prevent infinite loops during module loading
    $global:PSDefaultParameterValues = @{}
}

# Use $PSScriptRoot if available; otherwise, fall back to the current directory.
if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    [string]$scriptDirectory = (Get-Location).Path
}
else {
    [string]$scriptDirectory = $PSScriptRoot
}
Write-Verbose "Using script directory: $scriptDirectory"

# Force $modulesRoot to be a single string.
[string]$modulesRoot = Join-Path -Path $scriptDirectory -ChildPath "modules"
Write-Verbose "Modules root set to: $modulesRoot"

# List paths for each submodule's main PSM1.
[string]$loggingModulePath = Join-Path -Path $modulesRoot -ChildPath "HomeLab.Logging\HomeLab.Logging.psm1"
[string]$coreModulePath = Join-Path -Path $modulesRoot -ChildPath "HomeLab.Core\HomeLab.Core.psm1"
[string]$utilsModulePath = Join-Path -Path $modulesRoot -ChildPath "HomeLab.Utils\HomeLab.Utils.psm1"
[string]$azureModulePath = Join-Path -Path $modulesRoot -ChildPath "HomeLab.Azure\HomeLab.Azure.psm1"
[string]$securityModulePath = Join-Path -Path $modulesRoot -ChildPath "HomeLab.Security\HomeLab.Security.psm1"
[string]$monitoringModulePath = Join-Path -Path $modulesRoot -ChildPath "HomeLab.Monitoring\HomeLab.Monitoring.psm1"
[string]$uiModulePath = Join-Path -Path $modulesRoot -ChildPath "HomeLab.UI\HomeLab.UI.psm1"

# Track which modules were successfully loaded
$loadedModules = @{}

# Load modules in the correct dependency order
# 1. First load Logging module as it's needed by all others
if (Test-Path $loggingModulePath) {
    Write-Verbose "Loading HomeLab.Logging module from $loggingModulePath"
    Import-Module $loggingModulePath -Force -Global -DisableNameChecking
    $loadedModules["Logging"] = (Get-Module -Name "HomeLab.Logging") -ne $null
    
    if (-not $loadedModules["Logging"]) {
        Write-Warning "Failed to load HomeLab.Logging module. Functionality will be limited."
    }
}
else {
    Write-Warning "HomeLab.Logging module not found at expected path: $loggingModulePath"
}

# 2. Next load Core module which depends on Logging
if (Test-Path $coreModulePath) {
    Write-Verbose "Loading HomeLab.Core module from $coreModulePath"
    Import-Module $coreModulePath -Force -Global -DisableNameChecking
    $loadedModules["Core"] = (Get-Module -Name "HomeLab.Core") -ne $null
    
    if ($loadedModules["Core"]) {
        # Verify core functions are available
        $requiredFunctions = @(
            "Import-Configuration", 
            "Initialize-Logging", 
            "Write-Log",
            "Import-SafeModule"
        )
        
        $missingFunctions = @()
        foreach ($function in $requiredFunctions) {
            if (-not (Get-Command -Name $function -ErrorAction SilentlyContinue)) {
                $missingFunctions += $function
            }
        }
        
        if ($missingFunctions.Count -gt 0) {
            Write-Warning "Some core functions are not available: $($missingFunctions -join ', ')"
            Write-Warning "This will likely cause HomeLab to fail. Please check HomeLab.Core module exports."
        }
        else {
            Write-Verbose "All required Core functions verified as available."
        }
    }
    else {
        Write-Warning "Failed to load HomeLab.Core module. Functionality will be limited."
    }
}
else {
    Write-Error "HomeLab.Core module not found at expected path: $coreModulePath"
}

# Only proceed with other modules if Core was loaded successfully
if ($loadedModules["Core"]) {
    # Now load other modules using Import-SafeModule from Core
    $loadedModules["Utils"] = Import-SafeModule -ModulePath $utilsModulePath -ModuleName "HomeLab.Utils"
    $loadedModules["Azure"] = Import-SafeModule -ModulePath $azureModulePath -ModuleName "HomeLab.Azure"
    $loadedModules["Security"] = Import-SafeModule -ModulePath $securityModulePath -ModuleName "HomeLab.Security"
    $loadedModules["Monitoring"] = Import-SafeModule -ModulePath $monitoringModulePath -ModuleName "HomeLab.Monitoring"
    
    # Load UI last as it depends on other modules
    $loadedModules["UI"] = Import-SafeModule -ModulePath $uiModulePath -ModuleName "HomeLab.UI"
}
else {
    Write-Warning "Core module could not be loaded. HomeLab functionality will be limited."
}

# Import the Start-HomeLab function from the separate file
$startHomeLabPath = Join-Path -Path $scriptDirectory -ChildPath "Start-HomeLab.ps1"
if (Test-Path $startHomeLabPath) {
    try {
        . $startHomeLabPath
        Write-Verbose "Successfully imported Start-HomeLab function from $startHomeLabPath"
    }
    catch {
        Write-Error "Failed to import Start-HomeLab function: $_"
    }
}
else {
    Write-Error "Start-HomeLab.ps1 not found at expected path: $startHomeLabPath"
}

# Export the Start-HomeLab function so it's available to users of this module
Export-ModuleMember -Function Start-HomeLab

# Restore automatic module loading
$PSModuleAutoLoadingPreference = 'All'

# Restore the original PSDefaultParameterValues
if ($originalPSDefaultParameterValues) {
    $global:PSDefaultParameterValues = $originalPSDefaultParameterValues
}
