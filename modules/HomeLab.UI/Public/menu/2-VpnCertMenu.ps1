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
.PARAMETER ShowProgress
    If specified, shows a progress bar while loading the menu.
.EXAMPLE
    Show-VpnCertMenu
.EXAMPLE
    Show-VpnCertMenu -ShowProgress
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Show-VpnCertMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$ShowProgress
    )
    
    $menuItems = @{
        "1" = "Create New Root Certificate"
        "2" = "Create Client Certificate"
        "3" = "Add Client Certificate to Existing Root"
        "4" = "Upload Certificate to VPN Gateway"
        "5" = "List All Certificates"
    }
    
    $result = Show-Menu -Title "VPN CERTIFICATE MENU" -MenuItems $menuItems `
                        -ExitOption "0" -ExitText "Return to Main Menu" `
                        -ShowProgress:$ShowProgress -ValidateInput
    
    return $result
}