<#
.SYNOPSIS
    HomeLab UI Helpers Module
.DESCRIPTION
    Provides user interface helper functions for HomeLab.
    This includes core UI functions (Pause, Show-Spinner, Get-UserConfirmation),
    as well as menu display functions and menu handler functions.
.NOTES
    Author: Jurie Smit
    Date: March 5, 2025
#>

# Import core UI helper functions defined below
function Pause {
    Write-Host "Press any key to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-Spinner {
    param (
        [string]$Activity = "Processing",
        [int]$DurationSeconds = 1
    )
    
    $spinner = @('|', '/', '-', '\')
    $startTime = Get-Date
    $endTime = $startTime.AddSeconds($DurationSeconds)
    
    $i = 0
    while ((Get-Date) -lt $endTime) {
        Write-Host "`r$Activity $($spinner[$i % 4])" -NoNewline
        [Console]::Out.Flush()
        Start-Sleep -Milliseconds 250
        $i++
    }
    Write-Host "`r$Activity Complete!     "
    [Console]::Out.Flush()
}

function Get-UserConfirmation {
    param (
        [string]$Message,
        [switch]$DefaultYes
    )
    
    $prompt = if ($DefaultYes) { "$Message (Y/n): " } else { "$Message (y/N): " }
    Write-Host $prompt -NoNewline -ForegroundColor Yellow
    [Console]::Out.Flush()
    
    $response = Read-Host
    if ($DefaultYes) {
        return ($response -ne "n")
    }
    else {
        return ($response -eq "y")
    }
}

# Dot-source additional UI functions from the Public subfolders
# Import all menu display functions:
Get-ChildItem -Path "$PSScriptRoot\Public\menu" -Filter "*.ps1" | ForEach-Object { . $_.FullName }

# Import all menu handler functions:
Get-ChildItem -Path "$PSScriptRoot\Public\handlers" -Filter "*.ps1" | ForEach-Object { . $_.FullName }

# Export core functions and any additional ones from menu/handlers you want public.
Export-ModuleMember -Function Pause, Show-Spinner, Get-UserConfirmation, `
                     Show-Menu, Show-MainMenu, Show-VpnCertMenu, Show-VpnGatewayMenu, `
                     Show-VpnClientMenu, Show-NatGatewayMenu, Show-DocumentationMenu, `
                     Show-SettingsMenu, `
                     Invoke-DeployMenu, Invoke-VpnCertMenu, Invoke-VpnGatewayMenu, `
                     Invoke-VpnClientMenu, Invoke-NatGatewayMenu, Invoke-DocumentationMenu, `
                     Invoke-SettingsMenu
