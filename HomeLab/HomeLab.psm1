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
    @{Name = "HomeLab.Logging"; Path = "$PSScriptRoot\modules\HomeLab.Logging\HomeLab.Logging.psm1"},
    @{Name = "HomeLab.Utils"; Path = "$PSScriptRoot\modules\HomeLab.Utils\HomeLab.Utils.psm1"},
    @{Name = "HomeLab.Core"; Path = "$PSScriptRoot\modules\HomeLab.Core\HomeLab.Core.psm1"},
    @{Name = "HomeLab.UI"; Path = "$PSScriptRoot\modules\HomeLab.UI\HomeLab.UI.psm1"},
    @{Name = "HomeLab.Azure"; Path = "$PSScriptRoot\modules\HomeLab.Azure\HomeLab.Azure.psm1"},
    @{Name = "HomeLab.Security"; Path = "$PSScriptRoot\modules\HomeLab.Security\HomeLab.Security.psm1"},
    @{Name = "HomeLab.Monitoring"; Path = "$PSScriptRoot\modules\HomeLab.Monitoring\HomeLab.Monitoring.psm1"}
    # @{Name = "Az"; MinVersion = "9.0.0"} # Az is the only external module
)
$script:State = @{
    ConfigPath = "$env:USERPROFILE\.homelab\config.json"  # Set a default value
    LogLevel = "Info"  # Set a default value
    Config = $null
    User = $env:USERNAME
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

# Load core modules in the correct order
$moduleOrder = @(
    $loggingModulePath,  # Fixed: removed comma and added $
    $utilsModulePath,    # Fixed: removed comma and added $
    $coreModulePath,     # Fixed: removed comma and added $
    $uiModulePath,       # Fixed: removed comma and added $
    $azureModulePath,    # Fixed: removed comma and added $
    $securityModulePath, # Fixed: removed comma and added $
    $monitoringModulePath # Fixed: removed comma and added $
)

# Track which modules were successfully loaded
$loadedModules = @{}

# Import each module in order
foreach ($modulePath in $moduleOrder) {
    if (Test-Path -Path $modulePath) {
        Write-Verbose "Loading module from path: $modulePath"
        try {
            Import-Module -Name $modulePath -Global -Force -DisableNameChecking -ErrorAction Stop
            
            # Get the module name from the path
            $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($modulePath)
            $moduleName = $moduleName.Split('\')[-1]
            
            # Check if the module was loaded correctly
            $loadedModules[$modulePath] = (Get-Module -Name $moduleName -ErrorAction SilentlyContinue) -ne $null
            
            if ($loadedModules[$modulePath]) {
                Write-Verbose "Successfully loaded module: $moduleName"
            } else {
                Write-Warning "Module loaded but not found in Get-Module: $moduleName"
            }
        } catch {
            Write-Warning "Failed to load module from path: $modulePath. Error: $_"
            $loadedModules[$modulePath] = $false
        }
    }
    else {
        Write-Warning "Module path not found: $modulePath"
        $loadedModules[$modulePath] = $false
    }
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

# Explicitly re-export the Show-Menu function from HomeLab.UI to ensure it's available
if (Get-Module -Name "HomeLab.UI" -ErrorAction SilentlyContinue) {
    try {
        # Check if the function exists in the module
        $uiModule = Get-Module -Name "HomeLab.UI"
        $hasShowMenu = $uiModule.ExportedFunctions.ContainsKey('Show-Menu')
        
        if ($hasShowMenu) {
            Write-Verbose "Re-exporting Show-Menu function from HomeLab.UI"
            Export-ModuleMember -Function Show-Menu
        } else {
            Write-Warning "Show-Menu function not found in HomeLab.UI module"
        }
    } catch {
        Write-Warning "Error checking for Show-Menu function: $_"
    }
}

# Export functions from the main module
Export-ModuleMember -Function Start-HomeLab, Start-MainLoop, Initialize-Environment, Initialize-Configuration

# Export critical functions that might be needed
if (Get-Command -Name Get-AzureConnection -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function Get-AzureConnection
}
if (Get-Command -Name Import-RequiredModules -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function Import-RequiredModules
}
if (Get-Command -Name Test-ModuleAvailability -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function Test-ModuleAvailability
}
if (Get-Command -Name Wait-BeforeSplash -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function Wait-BeforeSplash
}

# Restore automatic module loading
$PSModuleAutoLoadingPreference = 'All'

# Restore the original PSDefaultParameterValues
if ($originalPSDefaultParameterValues) {
    $global:PSDefaultParameterValues = $originalPSDefaultParameterValues
}

# Set a flag to indicate that the module has been loaded
$script:ModulesLoaded = $true

Write-Verbose "HomeLab module initialization complete"
