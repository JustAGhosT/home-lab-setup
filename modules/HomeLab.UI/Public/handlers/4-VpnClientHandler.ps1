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
    Date: March 6, 2025
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
                
                # Assuming VpnAddComputer is defined in another module
                if (Get-Command VpnAddComputer -ErrorAction SilentlyContinue) {
                    VpnAddComputer
                }
                else {
                    Write-Host "Function VpnAddComputer not found. Make sure the required module is imported." -ForegroundColor Red
                    
                    # Fallback to manual instructions
                    Write-Host "Manual steps to add computer to VPN:" -ForegroundColor Yellow
                    Write-Host "1. Extract the VPN client configuration ZIP file" -ForegroundColor White
                    Write-Host "2. Run the VPN client installer (usually in the WindowsAmd64 folder)" -ForegroundColor White
                    Write-Host "3. Follow the installation prompts" -ForegroundColor White
                }
                
                Pause
            }
            "2" {
                Write-Host "Connecting to VPN..." -ForegroundColor Cyan
                
                # Assuming VpnConnectDisconnect is defined in another module
                if (Get-Command VpnConnectDisconnect -ErrorAction SilentlyContinue) {
                    VpnConnectDisconnect -Connect
                }
                else {
                    Write-Host "Function VpnConnectDisconnect not found. Make sure the required module is imported." -ForegroundColor Red
                    
                    # Fallback to direct PowerShell command
                    $vpnName = "$($config.env)-$($config.project)-vpn"
                    $connections = Get-VpnConnection | Where-Object { $_.Name -like "*$($config.project)*" }
                    
                    if ($connections) {
                        $vpnName = $connections[0].Name
                        Write-Host "Attempting to connect to VPN '$vpnName'..." -ForegroundColor Yellow
                        rasdial $vpnName
                    }
                    else {
                        Write-Host "No VPN connections found for project $($config.project)." -ForegroundColor Red
                    }
                }
                
                Pause
            }
            "3" {
                Write-Host "Disconnecting from VPN..." -ForegroundColor Cyan
                
                # Assuming VpnConnectDisconnect is defined in another module
                if (Get-Command VpnConnectDisconnect -ErrorAction SilentlyContinue) {
                    VpnConnectDisconnect -Disconnect
                }
                else {
                    Write-Host "Function VpnConnectDisconnect not found. Make sure the required module is imported." -ForegroundColor Red
                    
                    # Fallback to direct PowerShell command
                    $vpnName = "$($config.env)-$($config.project)-vpn"
                    $connections = Get-VpnConnection | Where-Object { $_.Name -like "*$($config.project)*" }
                    
                    if ($connections) {
                        $vpnName = $connections[0].Name
                        Write-Host "Attempting to disconnect from VPN '$vpnName'..." -ForegroundColor Yellow
                        rasdial $vpnName /disconnect
                    }
                    else {
                        Write-Host "No VPN connections found for project $($config.project)." -ForegroundColor Red
                    }
                }
                
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
