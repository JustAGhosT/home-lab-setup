<#
.SYNOPSIS
    Entry point script for HomeLab management environment
.DESCRIPTION
    Initializes and starts the HomeLab management console, loading required modules
    and displaying the main menu interface.
.NOTES
    Author: Jurie Smit
    Version: 1.0.0
    Date: March 9, 2025
.EXAMPLE
    .\Start-HomeLab.ps1
    Starts the HomeLab management console with default settings
.EXAMPLE
    .\Start-HomeLab.ps1 -ConfigPath "C:\HomeLab\config.json" -LogLevel "Debug"
    Starts HomeLab with a specific configuration file and verbose logging
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "$PSScriptRoot\config\homelab.config.json",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Info", "Warning", "Error", "Debug", "None")]
    [string]$LogLevel = "Info",
    
    [Parameter(Mandatory = $false)]
    [switch]$NoSplashScreen,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipVersionCheck,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipModuleCheck,
    
    [Parameter(Mandatory = $false)]
    [switch]$ForceReload
)

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
#endregion

#region Helper Functions
function Initialize-Environment {
    [CmdletBinding()]
    param()
    
    # Set error action preference
    $ErrorActionPreference = "Stop"
    
    # Create log directory if it doesn't exist
    $logDir = "$PSScriptRoot\logs"
    if (-not (Test-Path -Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    
    # Set log file path
    $script:LogFile = "$logDir\homelab_$(Get-Date -Format 'yyyyMMdd').log"
    
    # Initialize logging
    if ($LogLevel -ne "None") {
        # Try to use HomeLab.Logging if available - use local path
        $loggingModulePath = "$PSScriptRoot\modules\HomeLab.Logging\HomeLab.Logging.psm1"
        if (Test-Path $loggingModulePath) {
            Import-Module -Name $loggingModulePath -Force
            # Fixed parameter name from LogPath to LogFilePath
            Initialize-Logging -LogFilePath $script:LogFile -LogLevel $LogLevel
            Write-InfoLog -Message "HomeLab startup initiated - Version $script:Version"
        }
        else {
            # Fallback to basic logging
            function script:Write-Log {
                param([string]$Message, [string]$Level = "Info")
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $logMessage = "[$timestamp] [$Level] $Message"
                $logMessage | Out-File -FilePath $script:LogFile -Append
                
                $colors = @{
                    "Info" = "White"
                    "Warning" = "Yellow"
                    "Error" = "Red"
                    "Success" = "Green"
                    "Debug" = "Cyan"
                }
                
                if ($Level -eq "Debug" -and $LogLevel -ne "Debug") {
                    return
                }
                
                Write-Host $logMessage -ForegroundColor $colors[$Level]
            }
            
            Write-Log -Message "HomeLab startup initiated - Version $script:Version"
            Write-Log -Message "HomeLab.Logging module not found, using basic logging" -Level "Warning"
        }
    }
    
    # Set console title
    $Host.UI.RawUI.WindowTitle = "HomeLab Management Console v$script:Version"
}

function Test-ModuleAvailability {
    [CmdletBinding()]
    param()
    
    $allModulesAvailable = $true
    $modulesToInstall = @()
    
    foreach ($module in $script:RequiredModules) {
        $moduleName = $module.Name
        
        # For local modules, check if the file exists
        if ($module.Path) {
            if (-not (Test-Path -Path $module.Path)) {
                $allModulesAvailable = $false
                Write-Log -Message "Required local module not found: $($module.Path)" -Level "Warning"
            }
        }
        # For external modules like Az, check if they're installed
        else {
            $minVersion = $module.MinVersion
            $moduleInstalled = Get-Module -Name $moduleName -ListAvailable
            
            if (-not $moduleInstalled) {
                $allModulesAvailable = $false
                $modulesToInstall += $moduleName
                Write-Log -Message "Required external module not found: $moduleName" -Level "Warning"
            }
            elseif ($minVersion) {
                # Check version
                $latestVersion = ($moduleInstalled | Sort-Object Version -Descending | Select-Object -First 1).Version
                if ($latestVersion -lt [Version]$minVersion) {
                    $allModulesAvailable = $false
                    $modulesToInstall += $moduleName
                    Write-Log -Message "Module $moduleName version $latestVersion is below required version $minVersion" -Level "Warning"
                }
            }
        }
    }
    
    if (-not $allModulesAvailable -and -not $SkipModuleCheck) {
        Write-Log -Message "Some required modules are missing or outdated" -Level "Warning"
        
        # Only try to install external modules (like Az)
        if ($modulesToInstall.Count -gt 0) {
            $installModules = Read-Host "Would you like to install/update the missing external modules? (Y/N)"
            if ($installModules -eq "Y" -or $installModules -eq "y") {
                foreach ($moduleName in $modulesToInstall) {
                    try {
                        Write-Log -Message "Installing/updating module: $moduleName" -Level "Info"
                        Install-Module -Name $moduleName -Force -AllowClobber -Scope CurrentUser
                        Write-Log -Message "Successfully installed/updated module: $moduleName" -Level "Success"
                    }
                    catch {
                        Write-Log -Message "Failed to install module $moduleName`: $_" -Level "Error"
                        return $false
                    }
                }
            }
            else {
                Write-Log -Message "User chose not to install missing modules" -Level "Warning"
                return $false
            }
        }
    }
    
    return $true
}

function Import-RequiredModules {
    [CmdletBinding()]
    param()
    
    # First import HomeLab.Logging as it's needed by other modules
    $loggingModule = $script:RequiredModules | Where-Object { $_.Name -eq "HomeLab.Logging" }
    if ($loggingModule) {
        try {
            Write-Host "Loading module: HomeLab.Logging" -ForegroundColor Yellow
            Import-Module -Name $loggingModule.Path -Force:$ForceReload -ErrorAction Stop -Global -DisableNameChecking
            Write-Log -Message "Successfully loaded module: HomeLab.Logging" -Level "Success"
        }
        catch {
            Write-Host "Failed to load HomeLab.Logging module: $_" -ForegroundColor Red
            return $false
        }
    }
    
    # Then import HomeLab.Core as it may be needed by other modules
    $coreModule = $script:RequiredModules | Where-Object { $_.Name -eq "HomeLab.Core" }
    if ($coreModule) {
        try {
            Write-Log -Message "Loading module: HomeLab.Core" -Level "Info"
            Import-Module -Name $coreModule.Path -Force:$ForceReload -ErrorAction Stop -Global -DisableNameChecking
            Write-Log -Message "Successfully loaded module: HomeLab.Core" -Level "Success"
        }
        catch {
            Write-Log -Message "Failed to load HomeLab.Core module: $_" -Level "Error"
            return $false
        }
    }
    
    # Import the rest of the modules
    foreach ($module in $script:RequiredModules) {
        $moduleName = $module.Name
        
        # Skip already imported modules
        if ($moduleName -eq "HomeLab.Logging" -or $moduleName -eq "HomeLab.Core") {
            continue
        }
        
        try {
            Write-Log -Message "Loading module: $moduleName" -Level "Info"
            
            # For local modules, use the Path
            if ($module.Path) {
                Import-Module -Name $module.Path -Force:$ForceReload -ErrorAction Stop -Global -DisableNameChecking
            }
            # For external modules like Az, use the Name
            else {
                Import-Module -Name $moduleName -Force:$ForceReload -ErrorAction Stop
            }
            
            Write-Log -Message "Successfully loaded module: $moduleName" -Level "Success"
        }
        catch {
            Write-Log -Message "Failed to load module $moduleName`: $_" -Level "Error"
            # Continue loading other modules even if one fails
        }
    }
    
    $script:ModulesLoaded = $true
    return $true
}

function Load-Configuration {
    [CmdletBinding()]
    param()
    
    try {
        Write-Log -Message "Loading configuration from: $ConfigPath" -Level "Info"
        
        if (-not (Test-Path -Path $ConfigPath)) {
            Write-Log -Message "Configuration file not found: $ConfigPath" -Level "Warning"
            
            # Check if we should create a default config
            $createDefault = Read-Host "Configuration file not found. Create default configuration? (Y/N)"
            if ($createDefault -eq "Y" -or $createDefault -eq "y") {
                # Create config directory if it doesn't exist
                $configDir = Split-Path -Path $ConfigPath -Parent
                if (-not (Test-Path -Path $configDir)) {
                    New-Item -Path $configDir -ItemType Directory -Force | Out-Null
                }
                
                # Create default config
                $defaultConfig = @{
                    General = @{
                        DefaultSubscription = ""
                        DefaultResourceGroup = "HomeLab"
                        DefaultLocation = "eastus"
                        DefaultVNetName = "HomeLab-VNet"
                        DefaultVNetAddressPrefix = "10.0.0.0/16"
                        DefaultSubnetName = "default"
                        DefaultSubnetAddressPrefix = "10.0.0.0/24"
                    }
                    VPN = @{
                        GatewayName = "HomeLab-VPNGateway"
                        GatewaySku = "VpnGw1"
                        ClientAddressPool = "172.16.0.0/24"
                        EnableBgp = $false
                        IsEnabled = $false
                    }
                    NAT = @{
                        GatewayName = "HomeLab-NATGateway"
                        IdleTimeoutMinutes = 10
                        PublicIpCount = 1
                    }
                    UI = @{
                        Theme = "Default"
                        ShowSplashScreen = $true
                        AutoSaveConfig = $true
                        ConfirmDeployments = $true
                    }
                    Logging = @{
                        DefaultLogLevel = "Info"
                        MaxLogAgeDays = 30
                        EnableConsoleLogging = $true
                        EnableFileLogging = $true
                    }
                }
                
                $defaultConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $ConfigPath -Encoding utf8
                Write-Log -Message "Created default configuration file: $ConfigPath" -Level "Success"
            }
            else {
                Write-Log -Message "User chose not to create default configuration" -Level "Warning"
                return $false
            }
        }
        
        # Load config file
        $script:State.Config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        $script:ConfigLoaded = $true
        
        Write-Log -Message "Configuration loaded successfully" -Level "Success"
        return $true
    }
    catch {
        Write-Log -Message "Failed to load configuration: $_" -Level "Error"
        return $false
    }
}

function Show-SplashScreen {
    [CmdletBinding()]
    param()
    
    if ($NoSplashScreen) {
        return
    }
    
    # Clear the console
    Clear-Host
    
    # ASCII art for HomeLab
    $splashText = @"
    
    ██╗  ██╗ ██████╗ ███╗   ███╗███████╗██╗      █████╗ ██████╗ 
    ██║  ██║██╔═══██╗████╗ ████║██╔════╝██║     ██╔══██╗██╔══██╗
    ███████║██║   ██║██╔████╔██║█████╗  ██║     ███████║██████╔╝
    ██╔══██║██║   ██║██║╚██╔╝██║██╔══╝  ██║     ██╔══██║██╔══██╗
    ██║  ██║╚██████╔╝██║ ╚═╝ ██║███████╗███████╗██║  ██║██████╔╝
    ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝╚═════╝ 
                                                                
    ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗ 
    ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗
    ██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝
    ██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗
    ██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║
    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝
                                                                  
    Version: $script:Version
    
"@
    
    # Display splash screen with cyan color
    Write-Host $splashText -ForegroundColor Cyan
    
    # Display loading message
    Write-Host "Initializing HomeLab environment..." -ForegroundColor Yellow
    Write-Host ""
    
    # Simulate loading with a progress bar
    $totalSteps = 10
    for ($i = 1; $i -le $totalSteps; $i++) {
        $percent = ($i / $totalSteps) * 100
        $progressBar = "[" + ("█" * [math]::Floor($i * 50 / $totalSteps)) + (" " * [math]::Ceiling((50 - ($i * 50 / $totalSteps)))) + "]"
        Write-Host "`r$progressBar $percent%" -NoNewline -ForegroundColor Cyan
        Start-Sleep -Milliseconds 100
    }
    
    Write-Host "`r[██████████████████████████████████████████████████] 100%" -ForegroundColor Green
    Start-Sleep -Seconds 1
    
    # Clear the console again before proceeding
    Clear-Host
}

function Check-AzureConnection {
    [CmdletBinding()]
    param()
    
    try {
        Write-Log -Message "Checking Azure connection" -Level "Info"
        
        # Check if Az module is loaded
        if (-not (Get-Module -Name Az.Accounts)) {
            Write-Log -Message "Az.Accounts module not loaded. Attempting to load..." -Level "Warning"
            Import-Module -Name Az.Accounts -ErrorAction Stop
        }
        
        # Check if already connected
        $context = Get-AzContext -ErrorAction SilentlyContinue
        if ($context -and $context.Account) {
            $script:State.AzContext = $context
            $script:State.User = $context.Account.Id
            $script:State.ConnectionStatus = "Connected"
            
            Write-Log -Message "Already connected to Azure as $($context.Account.Id)" -Level "Success"
            Write-Log -Message "Subscription: $($context.Subscription.Name) ($($context.Subscription.Id))" -Level "Info"
            
            return $true
        }
        else {
            Write-Log -Message "Not connected to Azure" -Level "Warning"
            
            # Ask if user wants to connect
            $connect = Read-Host "You are not connected to Azure. Connect now? (Y/N)"
            if ($connect -eq "Y" -or $connect -eq "y") {
                # Connect to Azure
                $context = Connect-AzAccount -ErrorAction Stop
                
                if ($context) {
                    $script:State.AzContext = $context
                    $script:State.User = $context.Context.Account.Id
                    $script:State.ConnectionStatus = "Connected"
                    
                    Write-Log -Message "Successfully connected to Azure as $($context.Context.Account.Id)" -Level "Success"
                    Write-Log -Message "Subscription: $($context.Context.Subscription.Name) ($($context.Context.Subscription.Id))" -Level "Info"
                    
                    return $true
                }
            }
            else {
                Write-Log -Message "User chose not to connect to Azure" -Level "Warning"
                return $false
            }
        }
    }
    catch {
        Write-Log -Message "Failed to connect to Azure: $_" -Level "Error"
        return $false
    }
    
    return $false
}

function Start-MainLoop {
    [CmdletBinding()]
    param()
    
    try {
        # Check if HomeLab.UI module is available
        if (-not (Get-Module -Name HomeLab.UI)) {
            Write-Log -Message "HomeLab.UI module not loaded. Cannot start UI." -Level "Error"
            return
        }
        
        # Start the main menu loop
        Write-Log -Message "Starting main menu loop" -Level "Info"
        
        # Call the main menu handler function from HomeLab.UI
        # This is the key change - call Invoke-MainMenu instead of Show-MainMenu
        Invoke-MainMenu -State $script:State
        
        Write-Log -Message "Main menu loop ended" -Level "Info"
    }
    catch {
        Write-Log -Message "Error in main loop: $_" -Level "Error"
    }
}

function Show-StartupSummary {
    [CmdletBinding()]
    param()
    
    $elapsedTime = (Get-Date) - $script:StartTime
    $formattedTime = "{0:mm}m {0:ss}s" -f $elapsedTime
    
    Write-Host ""
    Write-Host "HomeLab Startup Summary" -ForegroundColor Cyan
    Write-Host "------------------------" -ForegroundColor Cyan
    Write-Host "Version: $script:Version"
    Write-Host "Startup Time: $formattedTime"
    Write-Host "Configuration: $(if ($script:ConfigLoaded) { 'Loaded' } else { 'Not Loaded' })"
    Write-Host "Modules: $(if ($script:ModulesLoaded) { 'Loaded' } else { 'Not Loaded' })"
    Write-Host "Azure Connection: $($script:State.ConnectionStatus)"
    if ($script:State.User) {
        Write-Host "User: $($script:State.User)"
    }
    Write-Host "------------------------" -ForegroundColor Cyan
    Write-Host ""
}
#endregion

#region Main Script
# Initialize environment
Initialize-Environment

# Show splash screen
Show-SplashScreen

# Check module availability
$modulesAvailable = Test-ModuleAvailability
if (-not $modulesAvailable -and -not $SkipModuleCheck) {
    Write-Log -Message "Required modules are not available. Exiting." -Level "Error"
    exit 1
}

# Import required modules
$modulesImported = Import-RequiredModules
if (-not $modulesImported) {
    Write-Log -Message "Failed to import required modules. Exiting." -Level "Error"
    exit 1
}

# Load configuration
$configLoaded = Load-Configuration
if (-not $configLoaded) {
    Write-Log -Message "Failed to load configuration. Proceeding with defaults." -Level "Warning"
}

# Check Azure connection
$azureConnected = Check-AzureConnection
if (-not $azureConnected) {
    Write-Log -Message "Not connected to Azure. Limited functionality will be available." -Level "Warning"
}

# Show startup summary
Show-StartupSummary

# Start main loop
Start-MainLoop

# Clean up and exit
Write-Log -Message "HomeLab session ended" -Level "Info"
#endregion
