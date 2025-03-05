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
    $selection = Show-VpnGatewayMenu
.NOTES
    Author: Jurie Smit
    Date: March 5, 2025
#>
function Show-VpnGatewayMenu {
    $menuItems = @{
        "1" = "Check VPN Gateway Status"
        "2" = "Generate VPN Client Configuration"
        "3" = "Upload Certificate to VPN Gateway"
        "4" = "Remove Certificate from VPN Gateway"
    }
    return Show-Menu -Title "VPN GATEWAY MENU" -MenuItems $menuItems -ExitOption "0"
}

Export-ModuleMember -Function Show-VpnGatewayMenu
