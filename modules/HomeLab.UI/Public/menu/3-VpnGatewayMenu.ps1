<#
.SYNOPSIS
    Displays the VPN Gateway Menu for HomeLab Setup.
.DESCRIPTION
    Presents options for managing the VPN gateway:
      1. Check VPN Gateway Status
      2. Generate VPN Client Configuration
      3. Upload Certificate to VPN Gateway
      4. Remove Certificate from VPN Gateway
      0. Return to Main Menu
.EXAMPLE
    Show-VpnGatewayMenu
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Show-VpnGatewayMenu {
    [CmdletBinding()]
    param()
    
    $menuItems = @{
        "1" = "Check VPN Gateway Status"
        "2" = "Generate VPN Client Configuration"
        "3" = "Upload Certificate to VPN Gateway"
        "4" = "Remove Certificate from VPN Gateway"
    }
    
    Show-Menu -Title "VPN GATEWAY MENU" -MenuItems $menuItems -ExitOption "0"
}
