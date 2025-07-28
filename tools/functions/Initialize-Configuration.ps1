<#
.SYNOPSIS
    Initializes the HomeLab configuration
.DESCRIPTION
    Loads the configuration from the specified path or creates a default configuration.
    Returns the loaded configuration object.
.PARAMETER ConfigPath
    The path to the configuration file. If not specified, uses the default path.
.PARAMETER Force
    If specified, creates a default configuration without prompting when the file doesn't exist.
.PARAMETER NoPrompt
    If specified, doesn't create a default configuration when the file doesn't exist.
.EXAMPLE
    Initialize-Configuration -ConfigPath "C:\config.json" -Force
    Loads the configuration from the specified path or creates a default configuration without prompting.
.NOTES
    Author: Jurie Smit
    Version: 1.0.0
    Date: March 10, 2025
#>

function Initialize-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = "$env:USERPROFILE\.homelab\config.json",
        
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoPrompt
    )
    
    try {
        # Use Write-Host if logging is not initialized yet
        # You can replace these with Write-Log calls later if logging is already initialized
        Write-Host "Loading configuration from: $ConfigPath" -ForegroundColor Cyan
        
        if (-not (Test-Path -Path $ConfigPath)) {
            Write-Host "Configuration file not found: $ConfigPath" -ForegroundColor Yellow
            
            $createDefault = $false
            
            # Determine if we should create a default config
            if ($Force) {
                $createDefault = $true
            }
            elseif (-not $NoPrompt) {
                $response = Read-Host "Configuration file not found. Create default configuration? (Y/N)"
                $createDefault = ($response -eq "Y" -or $response -eq "y")
            }
            
            if ($createDefault) {
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
                        MaxLogAgeDays = 30
                        EnableConsoleLogging = $true
                        EnableFileLogging = $true
                        DefaultLogLevel = "Info"
                        ConsoleLogLevel = "Info"
                        FileLogLevel = "Debug"
                    }
                }
                
                $defaultConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $ConfigPath -Encoding utf8
                Write-Host "Created default configuration file: $ConfigPath" -ForegroundColor Green
            }
            else {
                Write-Host "User chose not to create default configuration" -ForegroundColor Yellow
                return $null
            }
        }
        
        # Load config file
        $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        
        # Set script variables if they exist
        if (Get-Variable -Name "State" -Scope Script -ErrorAction SilentlyContinue) {
            $script:State.Config = $config
        }
        
        if (Get-Variable -Name "ConfigLoaded" -Scope Script -ErrorAction SilentlyContinue) {
            $script:ConfigLoaded = $true
        }
        
        Write-Host "Configuration loaded successfully" -ForegroundColor Green
        
        # Return the config object for use by the caller
        return $config
    }
    catch {
        Write-Host "Failed to load configuration: $_" -ForegroundColor Red
        return $null
    }
}

# Export the function
Export-ModuleMember -Function Initialize-Configuration
