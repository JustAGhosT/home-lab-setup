<#
.SYNOPSIS
    KVM Software Setup Menu Handler for HomeLab Setup.
.DESCRIPTION
    Processes user selections in the KVM Software Setup menu using a modular structure.
    Options include installing Barrier, Synergy, Mouse Without Borders, ShareMouse, or
    configuring Barrier for a home lab setup.
.EXAMPLE
    Invoke-KVMMenu
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Invoke-KVMMenu {
    [CmdletBinding()]
    param()
    
    $selection = $null
    do {
        # Display the KVM menu. (Assumes Show-KVMMenu is defined.)
        $result = Show-KVMMenu -ShowProgress
        $selection = $result.Choice
        
        switch ($selection) {
            "1" {
                Write-Host "`nInstalling Barrier..." -ForegroundColor Cyan
                Install-Barrier
                Pause-ForUser
            }
            "2" {
                Write-Host "`nInstalling Synergy..." -ForegroundColor Cyan
                Install-Synergy
                Pause-ForUser
            }
            "3" {
                Write-Host "`nInstalling Mouse Without Borders..." -ForegroundColor Cyan
                Install-MouseWithoutBorders
                Pause-ForUser
            }
            "4" {
                Write-Host "`nInstalling ShareMouse..." -ForegroundColor Cyan
                Install-ShareMouse
                Pause-ForUser
            }
            "5" {
                Write-Host "`nConfiguring Barrier for Home Lab..." -ForegroundColor Cyan
                Configure-BarrierHomeLab
                Pause-ForUser
            }
            "0" {
                Write-Host "`nReturning to Main Menu..." -ForegroundColor Cyan
            }
            default {
                Write-Host "Invalid option. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } while ($selection -ne "0")
}
