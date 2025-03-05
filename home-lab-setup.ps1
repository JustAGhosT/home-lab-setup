<#
.SYNOPSIS
    Home Lab Setup - Main Entry Point
.DESCRIPTION
    This script serves as the main entry point for the Home Lab Setup project,
    providing a menu-driven interface to access all functionality.
.NOTES
    Author: Jurie Smit
    Date: March 5, 2025
#>

# Get script path
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesPath = Join-Path -Path $scriptPath -ChildPath "modules"

# Import modules
$modulesToImport = @(
    "HomeLab.Core",
    "HomeLab.Azure"
)

foreach ($module in $modulesToImport) {
    $modulePath = Join-Path -Path $modulesPath -ChildPath $module
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force
        Write-Host "Imported module: $module" -ForegroundColor Green
    } else {
        Write-Host "Module not found: $module" -ForegroundColor Red
        exit 1
    }
}

# Check prerequisites
if (-not (Test-Prerequisites)) {
    Write-Host "Installing missing prerequisites..." -ForegroundColor Yellow
    Install-Prerequisites
    
    if (-not (Test-Prerequisites)) {
        Write-Host "Prerequisites installation failed. Please check the logs and try again." -ForegroundColor Red
        exit 1
    }
}

# Run first-time setup if needed
if (-not (Test-SetupComplete)) {
    Write-Host "Running first-time setup..." -ForegroundColor Yellow
    Initialize-HomeLab
}

# Main menu loop
$exitRequested = $false
while (-not $exitRequested) {
    $menuItems = @{
        "1" = "Deployment"
        "2" = "Configuration"
        "3" = "Monitoring"
    }
    
    $selection = Show-Menu -Title "HOMELAB SETUP - MAIN MENU" -MenuItems $menuItems
    
    switch ($selection) {
        "1" {
            # Deployment menu
            $deployMenuItems = @{
                "1" = "Deploy All Components"
                "2" = "Deploy Network Only"
                "3" = "Deploy VPN Gateway Only"
                "4" = "Deploy NAT Gateway Only"
                "5" = "Check Deployment Status"
            }
            
            $deploySelection = Show-Menu -Title "DEPLOYMENT MENU" -MenuItems $deployMenuItems
            
            $config = Get-Configuration
            
            switch ($deploySelection) {
                "1" {
                    Write-Host "Starting full deployment..." -ForegroundColor Cyan
                    Deploy-Infrastructure
                }
                "2" {
                    Write-Host "Deploying network only..." -ForegroundColor Cyan
                    Deploy-Infrastructure -ComponentsOnly "network"
                }
                "3" {
                    Write-Host "Deploying VPN Gateway only..." -ForegroundColor Cyan
                    Deploy-Infrastructure -ComponentsOnly "vpngateway"
                }
                "4" {
                    Write-Host "Deploying NAT Gateway only..." -ForegroundColor Cyan
                    Deploy-Infrastructure -ComponentsOnly "natgateway"
                }
                "5" {
                    Write-Host "Checking deployment status..." -ForegroundColor Cyan
                    $config = Get-Configuration
                    $resourceGroup = "$($config.ENV)-$($config.LOC)-rg-$($config.PROJECT)"
                    az group show --name $resourceGroup --query "properties.provisioningState" -o tsv
                }
                "0" {
                    # Return to main menu
                }
            }
        }
        "2" {
            # Configuration menu - implement later
            Write-Host "Configuration menu not implemented yet." -ForegroundColor Yellow
        }
        "3" {
            # Monitoring menu - implement later
            Write-Host "Monitoring menu not implemented yet." -ForegroundColor Yellow
        }
        "0" {
            $exitRequested = $true
            Write-Host "Exiting HomeLab Setup..." -ForegroundColor Yellow
        }
        default {
            Write-Host "Invalid option. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
    
    # Pause after each action unless exiting
    if (-not $exitRequested -and $selection -ne "0") {
        Write-Host "Press any key to continue..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}
