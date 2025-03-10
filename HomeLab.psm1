<#
.SYNOPSIS
    HomeLab Aggregator Module
.DESCRIPTION
    Aggregates functionality from HomeLab.Core, HomeLab.Azure, HomeLab.Security, HomeLab.UI, and HomeLab.Monitoring.
    Provides the high-level Start-HomeLab function as the main entry point for the application.
.NOTES
    Author: Jurie Smit
    Date: March 10, 2025
    Version: 1.0.0
#>

# ===== CRITICAL SECTION: PREVENT INFINITE LOOPS =====
# Disable automatic module loading to prevent recursive loading
$PSModuleAutoLoadingPreference = 'None'
# Disable function discovery debugging which can cause infinite loops
$DebugPreference = 'SilentlyContinue'


#region Script Variables
$script:Version = "1.0.0"
$script:StartTime = Get-Date
$script:ModulesLoaded = $false
$script:ConfigLoaded = $false
# Updated to reflect local module paths
$script:RequiredModules = @(
    @{Name = "HomeLab.Core"; Path = "$PSScriptRoot\modules\HomeLab.Core\HomeLab.Core.psm1"},
    @{Name = "HomeLab.UI"; Path = "$PSScriptRoot\modules\HomeLab.UI\HomeLab.UI.psm1"},
    @{Name = "HomeLab.Logging"; Path = "$PSScriptRoot\modules\HomeLab.Logging\HomeLab.Logging.psm1"},
    @{Name = "HomeLab.Utils"; Path = "$PSScriptRoot\modules\HomeLab.Utils\HomeLab.Utils.psm1"},
    @{Name = "HomeLab.Azure"; Path = "$PSScriptRoot\modules\HomeLab.Azure\HomeLab.Azure.psm1"},
    @{Name = "HomeLab.Security"; Path = "$PSScriptRoot\modules\HomeLab.Security\HomeLab.Security.psm1"},
    @{Name = "HomeLab.Monitoring"; Path = "$PSScriptRoot\modules\HomeLab.Monitoring\HomeLab.Monitoring.psm1"}
    # @{Name = "Az"; MinVersion = "9.0.0"} # Az is the only external module
)
$script:State = @{
    ConfigPath = $ConfigPath
    LogLevel = $LogLevel
    Config = $null
    User = $null
    AzContext = $null
    ConnectionStatus = "Disconnected"
    LastDeployment = $null
    MenuHistory = @()
}
$script:LogFile = "$env:USERPROFILE\.homelab\logs\homelab_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
#endregion

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

# Define the Functions directory path
[string]$functionsDirectory = Join-Path -Path $scriptDirectory -ChildPath "Functions"
Write-Verbose "Functions directory set to: $functionsDirectory"

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
            "Initialize-Configuration", 
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

# Create the Functions directory if it doesn't exist
if (-not (Test-Path -Path $functionsDirectory)) {
    try {
        New-Item -Path $functionsDirectory -ItemType Directory -Force | Out-Null
        Write-Verbose "Created Functions directory: $functionsDirectory"
    }
    catch {
        Write-Error "Failed to create Functions directory: $_"
    }
}

# Import all function files from the Functions directory
if (Test-Path $functionsDirectory) {
    Write-Verbose "Importing functions from directory: $functionsDirectory"
    $functionFiles = Get-ChildItem -Path $functionsDirectory -Filter "*.ps1" -ErrorAction SilentlyContinue
    
    if ($functionFiles.Count -gt 0) {
        foreach ($functionFile in $functionFiles) {
            try {
                Write-Verbose "Importing function file: $($functionFile.FullName)"
                . $functionFile.FullName
                Write-Verbose "Successfully imported function file: $($functionFile.Name)"
            }
            catch {
                Write-Error "Failed to import function file $($functionFile.Name): $_"
            }
        }
    }
    else {
        Write-Warning "No function files found in directory: $functionsDirectory"
    }
}

# Export both Start-HomeLab and Start-MainLoop functions
Export-ModuleMember -Function Start-HomeLab, Start-MainLoop

# Restore automatic module loading
$PSModuleAutoLoadingPreference = 'All'

# Restore the original PSDefaultParameterValues
if ($originalPSDefaultParameterValues) {
    $global:PSDefaultParameterValues = $originalPSDefaultParameterValues
}
