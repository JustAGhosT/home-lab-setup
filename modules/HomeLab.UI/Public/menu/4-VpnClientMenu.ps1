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
.EXAMPLE
    $selection = Show-VpnClientMenu
.NOTES
    Author: Jurie Smit
    Date: March 5, 2025
#>
function Show-VpnClientMenu {
    $menuItems = @{
        "1" = "Add Computer to VPN"
        "2" = "Connect to VPN"
        "3" = "Disconnect from VPN"
        "4" = "Check VPN Connection Status"
    }
    return Show-Menu -Title "VPN CLIENT MANAGEMENT" -MenuItems $menuItems -ExitOption "0"
}

Export-ModuleMember -Function Show-VpnClientMenu
