<#
.SYNOPSIS
    Home Lab Setup - Main Entry Point
.DESCRIPTION
    Loads the necessary modules (configuration, logging, UI, and menus), initializes settings,
    and starts the main menu loop.
.NOTES
    Author: Jurie Smit
    Date: March 5, 2025
#>

# Get the root folder of the project
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Import modules (Configuration, Logging, UI, etc.)
$modulesPath = Join-Path -Path $ScriptRoot -ChildPath "modules"
Get-ChildItem -Path $modulesPath -Filter "*.ps1" | ForEach-Object {
    . $_.FullName
}

# Import menu modules from the 'menu' subfolder
$menuPath = Join-Path -Path $ScriptRoot -ChildPath "menu"
Get-ChildItem -Path $menuPath -Filter "*.ps1" | ForEach-Object {
    . $_.FullName
}

# Load configuration and initialize logging
if (-not (Load-Configuration)) {
    Write-Host "Failed to load configuration. Exiting." -ForegroundColor Red
    exit 1
}
Initialize-LogFile -LogFilePath (Get-Configuration).LogFile

# Main menu loop
function Start-HomeLab {
    do {
        Show-MainMenu
        $selection = Read-Host "Select an option"
        switch ($selection) {
            "1" { Invoke-DeployMenu }
            "2" { Invoke-VpnCertMenu }
            "3" { Invoke-VpnGatewayMenu }
            "4" { Invoke-VpnClientMenu }
            "5" { Invoke-NatGatewayMenu }
            "6" { Invoke-DocumentationMenu }
            "7" { Invoke-SettingsMenu }
            "0" { Write-Host "Exiting Home Lab Setup..." -ForegroundColor Cyan }
            default { Write-Host "Invalid option. Please try again." -ForegroundColor Red; Start-Sleep -Seconds 2 }
        }
    } while ($selection -ne "0")
}

# Start the application
Start-HomeLab
