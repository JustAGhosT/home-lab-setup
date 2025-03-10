<#
.SYNOPSIS
    Initializes the HomeLab environment
.DESCRIPTION
    Sets up the HomeLab environment by configuring preferences, loading required modules,
    and establishing the necessary environment variables for Azure operations
.PARAMETER ConfigPath
    The path to the configuration file. Defaults to "$env:USERPROFILE\.homelab\config.json"
.PARAMETER LogLevel
    The logging level to use. Valid values are "Debug", "Info", "Warning", "Error", "Success". Defaults to "Info"
.PARAMETER LogFilePath
    The path to the log file. If not specified, a default path will be generated
.PARAMETER SkipModuleCheck
    If specified, skips the module availability check
.PARAMETER ForceReload
    If specified, forces reloading of modules even if they are already loaded
.PARAMETER ForceConfig
    If specified, forces creation of a default configuration file if it doesn't exist
.EXAMPLE
    Initialize-Environment -LogLevel "Debug" -ForceConfig
.NOTES
    Author: Jurie Smit
    Version: 1.0.0
    Date: March 10, 2025
#>

function Initialize-Environment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = "$env:USERPROFILE\.homelab\config.json",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Debug", "Info", "Warning", "Error", "Success")]
        [string]$LogLevel = "Info",
        
        [Parameter(Mandatory = $false)]
        [string]$LogFilePath = "",

        [Parameter(Mandatory = $false)]
        [switch]$SkipModuleCheck,
        
        [Parameter(Mandatory = $false)]
        [switch]$ForceReload,
        
        [Parameter(Mandatory = $false)]
        [switch]$ForceConfig
    )
    
    # Save original preferences
    $originalPSModuleAutoLoadingPreference = $PSModuleAutoLoadingPreference
    $originalErrorActionPreference = $ErrorActionPreference
    
    # Set safe preferences
    $PSModuleAutoLoadingPreference = 'None'
    $ErrorActionPreference = 'Continue'
    
    try {
        # Set environment variables to prevent Azure module registration issues
        $env:AZURE_SKIP_MODULE_REGISTRATION = 'true'
        $env:AZURE_SKIP_CREDENTIAL_VALIDATION = 'true'
        
        # Initialize script-level variables if not already set
        if (-not $script:RequiredModules) {
            # Define required modules with their paths or names
            $script:RequiredModules = @(
                @{
                    Name = "HomeLab.Logging"
                    Path = "$PSScriptRoot\..\modules\HomeLab.Logging\HomeLab.Logging.psm1"
                },
                @{
                    Name = "HomeLab.Core"
                    Path = "$PSScriptRoot\..\modules\HomeLab.Core\HomeLab.Core.psm1"
                },
                @{
                    Name = "HomeLab.UI"
                    Path = "$PSScriptRoot\..\modules\HomeLab.UI\HomeLab.UI.psm1"
                },
                @{
                    Name = "HomeLab.Azure"
                    Path = "$PSScriptRoot\..\modules\HomeLab.Azure\HomeLab.Azure.psm1"
                },
                @{
                    Name = "Az.Accounts"
                    MinVersion = "2.10.0"
                },
                @{
                    Name = "Az.Resources"
                    MinVersion = "6.0.0"
                },
                @{
                    Name = "Az.Network"
                    MinVersion = "5.0.0"
                }
            )
        }
        
        # Initialize state object
        if (-not $script:State) {
            $script:State = @{
                StartTime = Get-Date
                User = $env:USERNAME
                ConnectionStatus = "Disconnected"
                ConfigPath = $ConfigPath
                LogLevel = $LogLevel
                Config = $null
                AzContext = $null
                ModulesLoaded = $false
                ConfigLoaded = $false
            }
        }
        
        # First, try to import HomeLab.Logging directly since we need it for logging
        $loggingModule = $script:RequiredModules | Where-Object { $_.Name -eq "HomeLab.Logging" }
        if ($loggingModule -and (Test-Path -Path $loggingModule.Path)) {
            Write-Host "Loading HomeLab.Logging module..." -ForegroundColor Yellow
            Import-Module -Name $loggingModule.Path -Force:$ForceReload -ErrorAction Stop -Global -DisableNameChecking
            
            # Initialize logging with explicit path
            if ([string]::IsNullOrEmpty($LogFilePath)) {
                $logFileName = "homelab_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
                $logDir = Join-Path -Path $env:USERPROFILE -ChildPath ".homelab\logs"
                $LogFilePath = Join-Path -Path $logDir -ChildPath $logFileName
            }

            # Initialize logging
            if (Get-Command -Name Initialize-Logging -ErrorAction SilentlyContinue) {
                Initialize-Logging -LogFilePath $LogFilePath -LogLevel $LogLevel            
                Write-Log -Message "HomeLab environment initialization started" -Level "Info"
            }
            else {
                Write-Host "Initialize-Logging function not found in HomeLab.Logging module" -ForegroundColor Red
            }
        }
        else {
            Write-Host "HomeLab.Logging module not found at expected path. Will try to load it during module availability check." -ForegroundColor Yellow
        }
        
        # Test if all required modules are available
        if (-not $SkipModuleCheck) {
            $modulesAvailable = Test-ModuleAvailability
            if (-not $modulesAvailable) {
                Write-Log -Message "Required modules check failed" -Level "Error"
                return $false
            }
        }
        
        # Import all required modules
        $modulesImported = Import-RequiredModules
        if (-not $modulesImported) {
            Write-Log -Message "Failed to import required modules" -Level "Error"
            return $false
        }
        
        # Load configuration using the new Initialize-Configuration function
        $config = Initialize-Configuration -ConfigPath $ConfigPath -Force:$ForceConfig
        if ($null -eq $config) {
            Write-Log -Message "Failed to load configuration" -Level "Warning"
            # Continue anyway, as we might have created a default config
        }
        else {
            # Store the config in the script state
            $script:State.Config = $config
            $script:State.ConfigLoaded = $true
            
            # Set up the logging configuration from the loaded config
            if ($config.Logging) {
                $logConfig = $config.Logging
                
                if (Get-Command -Name Set-LoggingConfiguration -ErrorAction SilentlyContinue) {
                    Set-LoggingConfiguration -MaxLogAgeDays $logConfig.MaxLogAgeDays `
                                           -EnableConsoleLogging $logConfig.EnableConsoleLogging `
                                           -EnableFileLogging $logConfig.EnableFileLogging `
                                           -ConsoleLogLevel $logConfig.ConsoleLogLevel `
                                           -FileLogLevel $logConfig.FileLogLevel
                }
            }
        }
        
        # Environment is now initialized
        Write-Log -Message "HomeLab environment initialized successfully" -Level "Success"
        return $true
    }
    catch {
        $errorMessage = $_.Exception.Message
        $errorLine = $_.InvocationInfo.ScriptLineNumber
        $errorScript = $_.InvocationInfo.ScriptName
        
        if (Get-Command -Name Write-Log -ErrorAction SilentlyContinue) {
            Write-Log -Message "Error initializing HomeLab environment: $errorMessage" -Level "Error"
            Write-Log -Message "Script: $errorScript, Line: $errorLine" -Level "Error"
        }
        else {
            Write-Host "ERROR: Failed to initialize HomeLab environment: $errorMessage" -ForegroundColor Red
            Write-Host "Script: $errorScript, Line: $errorLine" -ForegroundColor Red
        }
        
        return $false
    }
    finally {
        # Restore original preferences
        $PSModuleAutoLoadingPreference = $originalPSModuleAutoLoadingPreference
        $ErrorActionPreference = $originalErrorActionPreference
    }
}

# Export the function
Export-ModuleMember -Function Initialize-Environment
