<#
.SYNOPSIS
    Displays the Deployment Menu for HomeLab Setup.
.DESCRIPTION
    Presents options for deploying Azure infrastructure:
      1. Full Deployment (All Resources)
      2. Deploy Network Only
      3. Deploy VPN Gateway Only
      4. Deploy NAT Gateway Only
      5. Check Deployment Status
      0. Return to Main Menu
.EXAMPLE
    Show-DeployMenu
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Show-DeployMenu {
    [CmdletBinding()]
    param()
    
    $menuItems = @{
        "1" = "Full Deployment (All Resources)"
        "2" = "Deploy Network Only"
        "3" = "Deploy VPN Gateway Only"
        "4" = "Deploy NAT Gateway Only"
        "5" = "Check Deployment Status"
    }
    
    Show-Menu -Title "DEPLOYMENT MENU" -MenuItems $menuItems -ExitOption "0"
}
