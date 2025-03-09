<#
.SYNOPSIS
    Displays the Settings Menu for HomeLab Setup.
.DESCRIPTION
    Presents options for configuring settings:
      1. Change Environment (with current value)
      2. Change Location Code (with current value)
      3. Change Project Name (with current value)
      4. Change Azure Location (with current value)
      5. Reset to Default Settings
      0. Return to Main Menu
.EXAMPLE
    Show-SettingsMenu
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Show-SettingsMenu {
    [CmdletBinding()]
    param()
    
    $config = Get-Configuration -ErrorAction SilentlyContinue
    $menuItems = @{
        "1" = "Change Environment (Current: $($config.env))"
        "2" = "Change Location Code (Current: $($config.loc))"
        "3" = "Change Project Name (Current: $($config.project))"
        "4" = "Change Azure Location (Current: $($config.location))"
        "5" = "Reset to Default Settings"
    }
    
    $result = Show-Menu -Title "SETTINGS MENU" -MenuItems $menuItems `
                        -ExitOption "0" -ExitText "Return to Main Menu" `
                        -ValidateInput
    

    return $result
}