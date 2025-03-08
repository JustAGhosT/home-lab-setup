<#
.SYNOPSIS
    HomeLab Aggregator Module
.DESCRIPTION
    Aggregates functionality from HomeLab.Core, HomeLab.Azure, HomeLab.Security, HomeLab.UI, and HomeLab.Monitoring.
    Provides the high-level Start-HomeLab function as the main entry point for the application.
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
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

# Function to safely check if a command exists
function Test-CommandExists {
    param (
        [Parameter(Mandatory = $true)]
        [string]$CommandName
    )
    
    try {
        $cmd = Get-Command -Name $CommandName -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# Function to safely load a module
function Import-SafeModule {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModulePath,
        
        [Parameter(Mandatory = $false)]
        [string]$ModuleName = (Split-Path -Path $ModulePath -Leaf)
    )
    
    # Check if the module is already loaded
    if (Get-Module -Name $ModuleName) {
        Write-Verbose "Module $ModuleName is already loaded."
        return $true
    }
    
    if (-not (Test-Path $ModulePath)) {
        Write-Warning "Module path not found: $ModulePath"
        return $false
    }
    
    try {
        # Import the module with DisableNameChecking to prevent automatic function discovery
        Import-Module -Name $ModulePath -Global -Force -DisableNameChecking -ErrorAction Stop
        
        Write-Verbose "Loaded module: $ModuleName from $ModulePath"
        return $true
    }
    catch {
        Write-Warning "Failed to load module: $ModulePath. Error: $_"
        return $false
    }
}

# Ensure Core module is loaded first and functions are available
$coreModulePath = Join-Path -Path $modulesRoot -ChildPath "HomeLab.Core\HomeLab.Core.psm1"
if (Test-Path $coreModulePath) {
    Import-Module $coreModulePath -Force -Global -DisableNameChecking
    
    # Verify core functions are available
    $requiredFunctions = @(
        "Import-Configuration", 
        "Initialize-LogFile", 
        "Write-Log",
        "Write-SimpleLog",
        "Test-Prerequisites",
        "Install-Prerequisites",
        "Test-SetupComplete",
        "Initialize-HomeLab"
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
    Write-Error "HomeLab.Core module not found at expected path: $coreModulePath"
}

# List paths for each submodule's main PSM1.
[string]$azureModulePath = Join-Path -Path $modulesRoot -ChildPath "HomeLab.Azure\HomeLab.Azure.psm1"
[string]$securityModulePath = Join-Path -Path $modulesRoot -ChildPath "HomeLab.Security\HomeLab.Security.psm1"
[string]$uiModulePath = Join-Path -Path $modulesRoot -ChildPath "HomeLab.UI\HomeLab.UI.psm1"
[string]$monitoringModulePath = Join-Path -Path $modulesRoot -ChildPath "HomeLab.Monitoring\HomeLab.Monitoring.psm1"

# Track which modules were successfully loaded
$loadedModules = @{}

# Load Core module first as other modules depend on it
$loadedModules["Core"] = (Get-Module -Name "HomeLab.Core") -ne $null

# Only proceed with other modules if Core was loaded successfully
if ($loadedModules["Core"]) {
    # Now load other modules
    $loadedModules["Azure"] = Import-SafeModule -ModulePath $azureModulePath -ModuleName "HomeLab.Azure"
    $loadedModules["Security"] = Import-SafeModule -ModulePath $securityModulePath -ModuleName "HomeLab.Security"
    $loadedModules["Monitoring"] = Import-SafeModule -ModulePath $monitoringModulePath -ModuleName "HomeLab.Monitoring"
    
    # Load UI last as it depends on other modules
    $loadedModules["UI"] = Import-SafeModule -ModulePath $uiModulePath -ModuleName "HomeLab.UI"
}
else {
    Write-Warning "Core module could not be loaded. HomeLab functionality will be limited."
}

# Define the high-level Start-HomeLab function.
function Start-HomeLab {
    <#
    .SYNOPSIS
        Starts the HomeLab application.
    .DESCRIPTION
        Loads configuration, initializes logging and prerequisites,
        and then enters the main menu loop.
    .EXAMPLE
        Start-HomeLab
        Launches the HomeLab application with the interactive menu system.
    .NOTES
        This is the main entry point for the HomeLab application.
    #>
    [CmdletBinding()]
    param()
    
    # Check if required functions from Core module are available
    $requiredFunctions = @(
        "Import-Configuration", 
        "Initialize-LogFile", 
        "Write-Log",
        "Write-SimpleLog",  # Now we have this function
        "Test-Prerequisites",
        "Install-Prerequisites",
        "Test-SetupComplete",
        "Initialize-HomeLab"
    )
    
    $missingFunctions = @()
    foreach ($function in $requiredFunctions) {
        if (-not (Test-CommandExists -CommandName $function)) {
            $missingFunctions += $function
        }
    }
    
    if ($missingFunctions.Count -gt 0) {
        Write-Host "Required functions not found: $($missingFunctions -join ', ')" -ForegroundColor Red
        Write-Host "Ensure HomeLab.Core module is loaded correctly." -ForegroundColor Red
        
        # List available functions for debugging
        Write-Host "Available functions from HomeLab.Core:" -ForegroundColor Cyan
        Get-Command -Module HomeLab.Core | ForEach-Object {
            Write-Host "  - $($_.Name)" -ForegroundColor Cyan
        }
        
        return $false
    }

    # Initialize logging as early as possible
    try {
        # Create log directory if it doesn't exist
        $defaultLogPath = Join-Path -Path $env:USERPROFILE -ChildPath ".homelab\logs\homelab.log"
        $logDir = Split-Path -Path $defaultLogPath -Parent
        if (-not (Test-Path -Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
        
        # Initialize log file with default path before configuration is loaded
        Initialize-LogFile -LogFilePath $defaultLogPath
        Write-SimpleLog -Message "Starting HomeLab application..." -Level INFO
    }
    catch {
        Write-Host "Failed to initialize logging: $_" -ForegroundColor Red
        # Continue without logging if it fails
    }

    # Load configuration
    try {
        if (-not (Import-Configuration)) {
            Write-Host "Failed to load configuration. Creating default configuration..." -ForegroundColor Yellow
            Write-SimpleLog -Message "Configuration loading failed. Creating default." -Level WARN
            
            # Create default configuration
            Reset-Configuration
            Save-Configuration
            
            if (-not (Import-Configuration)) {
                Write-Host "Failed to create and load default configuration. Exiting." -ForegroundColor Red
                Write-SimpleLog -Message "Default configuration creation failed." -Level ERROR
                return $false
            }
        }
        Write-SimpleLog -Message "Configuration loaded successfully." -Level INFO
    }
    catch {
        Write-Host "Configuration error: $_" -ForegroundColor Red
        Write-SimpleLog -Message "Configuration error: $_" -Level ERROR
        return $false
    }

    # Check prerequisites
    try {
        if (-not (Test-Prerequisites)) {
            Write-SimpleLog -Message "Prerequisites missing; attempting installation." -Level INFO
            Write-Host "Installing missing prerequisites..." -ForegroundColor Yellow
            Install-Prerequisites
            if (-not (Test-Prerequisites)) {
                Write-Host "Prerequisites installation failed. Exiting." -ForegroundColor Red
                Write-SimpleLog -Message "Prerequisites installation failed." -Level ERROR
                return $false
            }
            Write-SimpleLog -Message "Prerequisites verified after installation." -Level INFO
        }
    }
    catch {
        Write-Host "Prerequisites error: $_" -ForegroundColor Red
        Write-SimpleLog -Message "Prerequisites error: $_" -Level ERROR
        return $false
    }

    # First-time setup if needed
    try {
        if (-not (Test-SetupComplete)) {
            Write-SimpleLog -Message "First-time setup required. Setting up HomeLab." -Level INFO
            Write-Host "Running first-time setup..." -ForegroundColor Yellow
            Initialize-HomeLab
        }
    }
    catch {
        Write-Host "Setup error: $_" -ForegroundColor Red
        Write-SimpleLog -Message "Setup error: $_" -Level ERROR
        return $false
    }

    # Check if UI functions exist before attempting to use them
    $uiFunctions = @(
        "Show-MainMenu",
        "Invoke-DeployMenu",
        "Invoke-VpnCertMenu",
        "Invoke-VpnGatewayMenu",
        "Invoke-VpnClientMenu",
        "Invoke-NatGatewayMenu",
        "Invoke-DocumentationMenu",
        "Invoke-SettingsMenu"
    )
    
    $missingUiFunctions = @()
    foreach ($function in $uiFunctions) {
        if (-not (Test-CommandExists -CommandName $function)) {
            $missingUiFunctions += $function
        }
    }
    
    if ($missingUiFunctions.Count -gt 0) {
        Write-Host "UI functions not found: $($missingUiFunctions -join ', ')" -ForegroundColor Red
        Write-Host "HomeLab UI module may not be loaded correctly. Basic functionality only." -ForegroundColor Yellow
        Write-SimpleLog -Message "Missing UI functions: $($missingUiFunctions -join ', ')" -Level WARN
        
        # Provide basic functionality without UI
        Write-Host "HomeLab core modules loaded. For full functionality, ensure UI module is loaded." -ForegroundColor Cyan
        return $true
    }

    # Main menu loop
    try {
        Write-SimpleLog -Message "Entering main menu loop." -Level INFO
        do {
            $selection = Show-MainMenu
            Write-SimpleLog -Message "User selected menu option: $selection" -Level DEBUG
            switch ($selection) {
                "1" { Invoke-DeployMenu }
                "2" { Invoke-VpnCertMenu }
                "3" { Invoke-VpnGatewayMenu }
                "4" { Invoke-VpnClientMenu }
                "5" { Invoke-NatGatewayMenu }
                "6" { Invoke-DocumentationMenu }
                "7" { Invoke-SettingsMenu }
                "0" { Write-Host "Exiting Home Lab Setup..." -ForegroundColor Cyan; Write-SimpleLog -Message "User chose to exit HomeLab." -Level INFO }
                default {
                    Write-Host "Invalid option. Please try again." -ForegroundColor Red
                    Write-SimpleLog -Message "Invalid menu option selected: $selection" -Level WARN
                    Start-Sleep -Seconds 2
                }
            }
        } while ($selection -ne "0")
    }
    catch {
        Write-Host "Error in main menu: $_" -ForegroundColor Red
        Write-SimpleLog -Message "Error in main menu: $_" -Level ERROR
        return $false
    }
    finally {
        Write-SimpleLog -Message "Exiting HomeLab application." -Level INFO
    }
    
    return $true
}

# Restore the original PSDefaultParameterValues
if ($originalPSDefaultParameterValues) {
    $global:PSDefaultParameterValues = $originalPSDefaultParameterValues
}

# Export only the main entry point function
Export-ModuleMember -Function Start-HomeLab

# Restore automatic module loading
$PSModuleAutoLoadingPreference = 'All'
