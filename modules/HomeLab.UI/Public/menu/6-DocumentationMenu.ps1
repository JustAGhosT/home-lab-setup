<#
.SYNOPSIS
    Displays the Documentation Menu for HomeLab Setup.
.DESCRIPTION
    Presents options for viewing documentation:
      1. View Main README
      2. View VPN Gateway Documentation
      3. View Client Certificate Management Guide
      0. Return to Main Menu
.PARAMETER ShowProgress
    If specified, shows a progress bar while loading the menu.
.EXAMPLE
    Show-DocumentationMenu
.EXAMPLE
    Show-DocumentationMenu -ShowProgress
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Show-DocumentationMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$ShowProgress
    )
    
    $menuItems = @{
        "1" = "View Main README"
        "2" = "View VPN Gateway Documentation"
        "3" = "View Client Certificate Management Guide"
    }
    
    $result = Show-Menu -Title "DOCUMENTATION" -MenuItems $menuItems `
                        -ExitOption "0" -ExitText "Return to Main Menu" `
                        -ShowProgress:$ShowProgress -ValidateInput
    

    return $result
}