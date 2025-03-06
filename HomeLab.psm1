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

# Check and import required modules
$requiredModules = @('Az')

foreach ($module in $requiredModules) {
    if (-not (Get-Module -Name $module -ListAvailable)) {
        Write-Warning "Required module '$module' is not installed. Attempting to install..."
        
        try {
            Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
            Write-Verbose "Module '$module' installed successfully."
        }
        catch {
            throw "Failed to install required module '$module'. Please install it manually using: Install-Module -Name $module -Scope CurrentUser"
        }
    }
    
    # Import the module if it's not already loaded
    if (-not (Get-Module -Name $module)) {
        Write-Verbose "Importing module '$module'..."
        Import-Module -Name $module -ErrorAction Stop
    }
}

# Use $PSScriptRoot if available; otherwise, fall back to the current directory.
if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    [string]$scriptDirectory = (Get-Location).Path
} else {
    [string]$scriptDirectory = $PSScriptRoot
}
Write-Verbose "Using script directory: $scriptDirectory"

# Force $modulesRoot to be a single string.
[string]$modulesRoot = Join-Path -Path $scriptDirectory -ChildPath "modules"
Write-Verbose "Modules root set to: $modulesRoot"

# List paths for each submodule's main PSM1.
[string]$coreModulePath      = Join-Path -Path $modulesRoot -ChildPath "HomeLab.Core\HomeLab.Core.psm1"
[string]$azureModulePath     = Join-Path -Path $modulesRoot -ChildPath "HomeLab.Azure\HomeLab.Azure.psm1"
[string]$securityModulePath  = Join-Path -Path $modulesRoot -ChildPath "HomeLab.Security\HomeLab.Security.psm1"
[string]$uiModulePath        = Join-Path -Path $modulesRoot -ChildPath "HomeLab.UI\HomeLab.UI.psm1"
[string]$monitoringModulePath = Join-Path -Path $modulesRoot -ChildPath "HomeLab.Monitoring\HomeLab.Monitoring.psm1"

$submodules = @(
    # Load Core first as other modules depend on it
    $coreModulePath,
    # Load other modules
    $azureModulePath,
    $securityModulePath,
    $monitoringModulePath,
    # Load UI last as it depends on other modules
    $uiModulePath
)

# Import each submodule
foreach ($path in $submodules) {
    if (Test-Path $path) {
        try {
            . $path
            Write-Verbose "Loaded submodule: $path"
            # Log that the submodule was loaded (if Write-Log is available)
            if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
                Write-Log -Message "Loaded submodule: $path" -Level INFO
            }
        }
        catch {
            Write-Warning "Failed to load submodule: $path. Error: $_"
            if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
                Write-Log -Message "Failed to load submodule: $path. Error: $_" -Level ERROR
            }
        }
    } else {
        Write-Warning "Submodule path not found: $path"
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log -Message "Submodule path not found: $path" -Level WARN
        }
    }
}

# Additionally, load UI menu functions from HomeLab.UI\Public\menu.
[string]$uiMenuPath = Join-Path -Path $modulesRoot -ChildPath "HomeLab.UI\Public\menu"
if (Test-Path $uiMenuPath) {
    Get-ChildItem -Path $uiMenuPath -Filter "*.ps1" | ForEach-Object {
        try {
            . $_.FullName
            Write-Verbose "Loaded UI menu file: $($_.FullName)"
            if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
                Write-Log -Message "Loaded UI menu file: $($_.FullName)" -Level INFO
            }
        }
        catch {
            Write-Warning "Failed to load UI menu file: $($_.FullName). Error: $_"
            if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
                Write-Log -Message "Failed to load UI menu file: $($_.FullName). Error: $_" -Level ERROR
            }
        }
    }
} else {
    Write-Warning "UI menu folder not found: $uiMenuPath"
    if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
        Write-Log -Message "UI menu folder not found: $uiMenuPath" -Level WARN
    }
}

# Additionally, load UI handler functions from HomeLab.UI\Public\handlers.
[string]$uiHandlersPath = Join-Path -Path $modulesRoot -ChildPath "HomeLab.UI\Public\handlers"
if (Test-Path $uiHandlersPath) {
    Get-ChildItem -Path $uiHandlersPath -Filter "*.ps1" | ForEach-Object {
        try {
            . $_.FullName
            Write-Verbose "Loaded UI handler file: $($_.FullName)"
            if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
                Write-Log -Message "Loaded UI handler file: $($_.FullName)" -Level INFO
            }
        }
        catch {
            Write-Warning "Failed to load UI handler file: $($_.FullName). Error: $_"
            if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
                Write-Log -Message "Failed to load UI handler file: $($_.FullName). Error: $_" -Level ERROR
            }
        }
    }
} else {
    Write-Warning "UI handlers folder not found: $uiHandlersPath"
    if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
        Write-Log -Message "UI handlers folder not found: $uiHandlersPath" -Level WARN
    }
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

    # Check if Core module functions are available
    if (-not (Get-Command Load-Configuration -ErrorAction SilentlyContinue)) {
        Write-Host "Load-Configuration function not found. Ensure HomeLab.Core is loaded." -ForegroundColor Red
        return $false
    }

    # Initialize logging as early as possible
    try {
        # Create log directory if it doesn't exist
        $defaultLogPath = Join-Path -Path $env:USERPROFILE -ChildPath "HomeLab\logs\homelab.log"
        $logDir = Split-Path -Path $defaultLogPath -Parent
        if (-not (Test-Path -Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
        
        # Initialize log file with default path before configuration is loaded
        Initialize-LogFile -LogFilePath $defaultLogPath
        Write-Log -Message "Starting HomeLab application..." -Level INFO
    }
    catch {
        Write-Host "Failed to initialize logging: $_" -ForegroundColor Red
        # Continue without logging if it fails
    }

    # Load configuration
    try {
        if (-not (Load-Configuration)) {
            Write-Host "Failed to load configuration. Creating default configuration..." -ForegroundColor Yellow
            Write-Log -Message "Configuration loading failed. Creating default." -Level WARN
            
            # Create default configuration
            Reset-Configuration
            Save-Configuration
            
            if (-not (Load-Configuration)) {
                Write-Host "Failed to create and load default configuration. Exiting." -ForegroundColor Red
                Write-Log -Message "Default configuration creation failed." -Level ERROR
                return $false
            }
        }
        Write-Log -Message "Configuration loaded successfully." -Level INFO
        
        # Re-initialize log file with configured path
        Initialize-LogFile -LogFilePath (Get-Configuration).LogFile
        Write-Log -Message "Log file initialized at: $((Get-Configuration).LogFile)" -Level INFO
    }
    catch {
        Write-Host "Configuration error: $_" -ForegroundColor Red
        Write-Log -Message "Configuration error: $_" -Level ERROR
        return $false
    }

    # Check prerequisites
    try {
        if (-not (Test-Prerequisites)) {
            Write-Log -Message "Prerequisites missing; attempting installation." -Level INFO
            Write-Host "Installing missing prerequisites..." -ForegroundColor Yellow
            Install-Prerequisites
            if (-not (Test-Prerequisites)) {
                Write-Host "Prerequisites installation failed. Exiting." -ForegroundColor Red
                Write-Log -Message "Prerequisites installation failed." -Level ERROR
                return $false
            }
            Write-Log -Message "Prerequisites verified after installation." -Level INFO
        }
    }
    catch {
        Write-Host "Prerequisites error: $_" -ForegroundColor Red
        Write-Log -Message "Prerequisites error: $_" -Level ERROR
        return $false
    }

    # First-time setup if needed
    try {
        if (-not (Test-SetupComplete)) {
            Write-Log -Message "First-time setup required. Initializing HomeLab." -Level INFO
            Write-Host "Running first-time setup..." -ForegroundColor Yellow
            Initialize-HomeLab
        }
    }
    catch {
        Write-Host "Setup error: $_" -ForegroundColor Red
        Write-Log -Message "Setup error: $_" -Level ERROR
        return $false
    }

    # Main menu loop
    try {
        Write-Log -Message "Entering main menu loop." -Level INFO
        do {
            $selection = Show-MainMenu
            Write-Log -Message "User selected menu option: $selection" -Level DEBUG
            switch ($selection) {
                "1" { Invoke-DeployMenu }
                "2" { Invoke-VpnCertMenu }
                "3" { Invoke-VpnGatewayMenu }
                "4" { Invoke-VpnClientMenu }
                "5" { Invoke-NatGatewayMenu }
                "6" { Invoke-DocumentationMenu }
                "7" { Invoke-SettingsMenu }
                "0" { Write-Host "Exiting Home Lab Setup..." -ForegroundColor Cyan; Write-Log -Message "User chose to exit HomeLab." -Level INFO }
                default {
                    Write-Host "Invalid option. Please try again." -ForegroundColor Red
                    Write-Log -Message "Invalid menu option selected: $selection" -Level WARN
                    Start-Sleep -Seconds 2
                }
            }
        } while ($selection -ne "0")
    }
    catch {
        Write-Host "Error in main menu: $_" -ForegroundColor Red
        Write-Log -Message "Error in main menu: $_" -Level ERROR
        return $false
    }
    finally {
        Write-Log -Message "Exiting HomeLab application." -Level INFO
    }
    
    return $true
}

# Export only the main entry point function
Export-ModuleMember -Function Start-HomeLab
