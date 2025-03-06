<#
.SYNOPSIS
    Displays the VPN Certificate Menu for HomeLab Setup.
.DESCRIPTION
    Presents options for managing VPN certificates:
      1. Create New Root Certificate
      2. Create Client Certificate
      3. Add Client Certificate to Existing Root
      4. Upload Certificate to VPN Gateway
      5. List All Certificates
      0. Return to Main Menu
.EXAMPLE
    Show-VpnCertMenu
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Show-VpnCertMenu {
    [CmdletBinding()]
    param()
    
    $menuItems = @{
        "1" = "Create New Root Certificate"
        "2" = "Create Client Certificate"
        "3" = "Add Client Certificate to Existing Root"
        "4" = "Upload Certificate to VPN Gateway"
        "5" = "List All Certificates"
    }
    
    Show-Menu -Title "VPN CERTIFICATE MENU" -MenuItems $menuItems -ExitOption "0"
}
