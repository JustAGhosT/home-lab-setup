<#
.SYNOPSIS
    VPN Client Menu Handler for HomeLab Setup
.DESCRIPTION
    Processes user selections in the VPN client menu using the new modular structure.
    Options include adding a computer to the VPN, connecting, disconnecting, and checking VPN connection status.
.EXAMPLE
    Invoke-VpnClientMenu
.NOTES
    Author: Jurie Smit
    Date: March 5, 2025
#>
function Invoke-VpnClientMenu {
    [CmdletBinding()]
    param()
    
    $selection = 0
    do {
        Show-VpnClientMenu
        $selection = Read-Host "Select an option"
        $config = Get-Configuration
        
        switch ($selection) {
            "1" {
                Write-Host "Adding computer to VPN..." -ForegroundColor Cyan
                VpnAddComputer
                Pause
            }
            "2" {
                Write-Host "Connecting to VPN..." -ForegroundColor Cyan
                VpnConnectDisconnect -Connect
                Pause
            }
            "3" {
                Write-Host "Disconnecting from VPN..." -ForegroundColor Cyan
                VpnConnectDisconnect -Disconnect
                Pause
            }
            "4" {
                Write-Host "Checking VPN connection status..." -ForegroundColor Cyan
                $connections = Get-VpnConnection | Where-Object { $_.Name -like "*$($config.project)*" }
                if ($connections) {
                    $connections | Format-Table -Property Name, ServerAddress, ConnectionStatus, AuthenticationMethod
                }
                else {
                    Write-Host "No VPN connections found for project $($config.project)." -ForegroundColor Yellow
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

Export-ModuleMember -Function Invoke-VpnClientMenu
