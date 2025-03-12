<#
.SYNOPSIS
    Settings Menu Handler for HomeLab Setup
.DESCRIPTION
    Processes user selections in the settings menu using the new modular structure.
    Options include updating environment, location code, project name, Azure location, or resetting to defaults.
.EXAMPLE
    Invoke-SettingsMenu
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Invoke-SettingsMenu {
    [CmdletBinding()]
    param()
    
    $selection = 0
    do {
        Show-SettingsMenu
        $selection = Read-Host "Select an option"
        
        switch ($selection) {
            "1" {
                $newEnv = Read-Host "Enter new environment (e.g., dev, test, prod)"
                if (-not [string]::IsNullOrWhiteSpace($newEnv)) {
                    # Assuming Update-ConfigurationParameter is defined in another module
                    if (Get-Command Update-ConfigurationParameter -ErrorAction SilentlyContinue) {
                        Update-ConfigurationParameter -Name "env" -Value $newEnv
                        Save-Configuration
                        Write-Host "Environment updated to '$newEnv'" -ForegroundColor Green
                    }
                    else {
                        Write-Host "Function Update-ConfigurationParameter not found. Make sure the required module is imported." -ForegroundColor Red
                    }
                }
                Pause
            }
            "2" {
                $newLoc = Read-Host "Enter new location code (e.g., saf, use, euw)"
                if (-not [string]::IsNullOrWhiteSpace($newLoc)) {
                    # Assuming Update-ConfigurationParameter is defined in another module
                    if (Get-Command Update-ConfigurationParameter -ErrorAction SilentlyContinue) {
                        Update-ConfigurationParameter -Name "loc" -Value $newLoc
                        Save-Configuration
                        Write-Host "Location code updated to '$newLoc'" -ForegroundColor Green
                    }
                    else {
                        Write-Host "Function Update-ConfigurationParameter not found. Make sure the required module is imported." -ForegroundColor Red
                    }
                }
                Pause
            }
            "3" {
                $newProject = Read-Host "Enter new project name"
                if (-not [string]::IsNullOrWhiteSpace($newProject)) {
                    # Assuming Update-ConfigurationParameter is defined in another module
                    if (Get-Command Update-ConfigurationParameter -ErrorAction SilentlyContinue) {
                        Update-ConfigurationParameter -Name "project" -Value $newProject
                        Save-Configuration
                        Write-Host "Project name updated to '$newProject'" -ForegroundColor Green
                    }
                    else {
                        Write-Host "Function Update-ConfigurationParameter not found. Make sure the required module is imported." -ForegroundColor Red
                    }
                }
                Pause
            }
            "4" {
                $newLocation = Read-Host "Enter new Azure location (e.g., southafricanorth, eastus, westeurope)"
                if (-not [string]::IsNullOrWhiteSpace($newLocation)) {
                    # Assuming Update-ConfigurationParameter is defined in another module
                    if (Get-Command Update-ConfigurationParameter -ErrorAction SilentlyContinue) {
                        Update-ConfigurationParameter -Name "location" -Value $newLocation
                        Save-Configuration
                        Write-Host "Azure location updated to '$newLocation'" -ForegroundColor Green
                    }
                    else {
                        Write-Host "Function Update-ConfigurationParameter not found. Make sure the required module is imported." -ForegroundColor Red
                    }
                }
                Pause
            }
            "5" {
                if (Get-UserConfirmation -Message "Are you sure you want to reset to default settings?" -DefaultNo) {
                    # Assuming Reset-Configuration is defined in another module
                    if (Get-Command Reset-Configuration -ErrorAction SilentlyContinue) {
                        Reset-Configuration
                        Write-Host "Settings reset to default values" -ForegroundColor Green
                    }
                    else {
                        Write-Host "Function Reset-Configuration not found. Make sure the required module is imported." -ForegroundColor Red
                    }
                }
                Pause
            }
            "0" {
                # Return to main menu
            }
            default {
                Write-Host "Invalid option. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } while ($selection -ne "0")
}
