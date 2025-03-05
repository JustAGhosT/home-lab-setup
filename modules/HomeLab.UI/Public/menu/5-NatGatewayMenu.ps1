<#
.SYNOPSIS
    Displays the NAT Gateway Menu for HomeLab Setup.
.DESCRIPTION
    Presents options for managing the NAT gateway:
      1. Enable NAT Gateway
      2. Disable NAT Gateway
      3. Check NAT Gateway Status
      0. Return to Main Menu
.EXAMPLE
    $selection = Show-NatGatewayMenu
.NOTES
    Author: Jurie Smit
    Date: March 5, 2025
#>
function Show-NatGatewayMenu {
    $menuItems = @{
        "1" = "Enable NAT Gateway"
        "2" = "Disable NAT Gateway"
        "3" = "Check NAT Gateway Status"
    }
    return Show-Menu -Title "NAT GATEWAY MENU" -MenuItems $menuItems -ExitOption "0"
}

Export-ModuleMember -Function Show-NatGatewayMenu
