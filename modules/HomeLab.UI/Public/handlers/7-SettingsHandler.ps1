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
    Date: March 5, 2025
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
                    Update-ConfigurationParameter -Name "env" -Value $newEnv
                    Save-Configuration
                }
                Pause
            }
            "2" {
                $newLoc = Read-Host "Enter new location code (e.g., saf, use, euw)"
                if (-not [string]::IsNullOrWhiteSpace($newLoc)) {
                    Update-ConfigurationParameter -Name "loc" -Value $newLoc
                    Save-Configuration
                }
                Pause
            }
            "3" {
                $newProject = Read-Host "Enter new project name"
                if (-not [string]::IsNullOrWhiteSpace($newProject)) {
                    Update-ConfigurationParameter -Name "project" -Value $newProject
                    Save-Configuration
                }
                Pause
            }
            "4" {
                $newLocation = Read-Host "Enter new Azure location (e.g., southafricanorth, eastus, westeurope)"
                if (-not [string]::IsNullOrWhiteSpace($newLocation)) {
                    Update-ConfigurationParameter -Name "location" -Value $newLocation
                    Save-Configuration
                }
                Pause
            }
            "5" {
                if (Get-UserConfirmation -Message "Are you sure you want to reset to default settings?" -DefaultNo) {
                    Reset-Configuration
                    Write-Host "Settings reset to default values" -ForegroundColor Green
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

Export-ModuleMember -Function Invoke-SettingsMenu
