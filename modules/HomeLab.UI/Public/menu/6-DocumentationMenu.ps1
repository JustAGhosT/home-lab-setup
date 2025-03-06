<#
.SYNOPSIS
    Displays the Documentation Menu for HomeLab Setup.
.DESCRIPTION
    Presents options for viewing documentation:
      1. View Main README
      2. View VPN Gateway Documentation
      3. View Client Certificate Management Guide
      0. Return to Main Menu
.EXAMPLE
    Show-DocumentationMenu
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Show-DocumentationMenu {
    [CmdletBinding()]
    param()
    
    $menuItems = @{
        "1" = "View Main README"
        "2" = "View VPN Gateway Documentation"
        "3" = "View Client Certificate Management Guide"
    }
    
    Show-Menu -Title "DOCUMENTATION" -MenuItems $menuItems -ExitOption "0"
}
