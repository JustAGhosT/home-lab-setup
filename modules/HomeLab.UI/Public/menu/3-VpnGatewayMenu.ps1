<#
.SYNOPSIS
    Displays the VPN Gateway Menu for HomeLab Setup.
.DESCRIPTION
    Presents options for managing the VPN gateway:
      1. Check VPN Gateway Status
      2. Generate VPN Client Configuration
      3. Upload Certificate to VPN Gateway
      4. Remove Certificate from VPN Gateway
      5. Configure VPN Split Tunneling
      0. Return to Main Menu
.PARAMETER ShowProgress
    If specified, shows a progress bar while loading the menu.
.EXAMPLE
    Show-VpnGatewayMenu
.EXAMPLE
    Show-VpnGatewayMenu -ShowProgress
.NOTES
    Author: Jurie Smit
    Date: March 8, 2025
#>
function Show-VpnGatewayMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$ShowProgress
    )
    
    $menuItems = @{
        "1" = "Check VPN Gateway Status"
        "2" = "Generate VPN Client Configuration"
        "3" = "Upload Certificate to VPN Gateway"
        "4" = "Remove Certificate from VPN Gateway"
        "5" = "Configure VPN Split Tunneling"
    }
    
    Show-Menu -Title "VPN GATEWAY MENU" -MenuItems $menuItems -ExitOption "0" -ShowProgress:$ShowProgress
}