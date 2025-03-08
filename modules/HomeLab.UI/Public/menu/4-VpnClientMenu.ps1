<#
.SYNOPSIS
    Displays the VPN Client Menu for HomeLab Setup.
.DESCRIPTION
    Presents options for managing VPN client connections:
      1. Add Computer to VPN
      2. Connect to VPN
      3. Disconnect from VPN
      4. Check VPN Connection Status
      0. Return to Main Menu
.PARAMETER ShowProgress
    If specified, shows a progress bar while loading the menu.
.EXAMPLE
    Show-VpnClientMenu
.EXAMPLE
    Show-VpnClientMenu -ShowProgress
.NOTES
    Author: Jurie Smit
    Date: March 8, 2025
#>
function Show-VpnClientMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$ShowProgress
    )
    
    $menuItems = @{
        "1" = "Add Computer to VPN"
        "2" = "Connect to VPN"
        "3" = "Disconnect from VPN"
        "4" = "Check VPN Connection Status"
    }
    
    Show-Menu -Title "VPN CLIENT MANAGEMENT" -MenuItems $menuItems -ExitOption "0" -ShowProgress:$ShowProgress
}
