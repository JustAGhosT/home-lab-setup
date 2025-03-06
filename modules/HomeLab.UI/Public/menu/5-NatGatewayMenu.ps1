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
    Show-NatGatewayMenu
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Show-NatGatewayMenu {
    [CmdletBinding()]
    param()
    
    $menuItems = @{
        "1" = "Enable NAT Gateway"
        "2" = "Disable NAT Gateway"
        "3" = "Check NAT Gateway Status"
    }
    
    Show-Menu -Title "NAT GATEWAY MENU" -MenuItems $menuItems -ExitOption "0"
}
