<#
.SYNOPSIS
    Displays the Main Menu for Home Lab Setup.
.DESCRIPTION
    Presents the primary options for the Home Lab Setup application.
    Options include:
      1. Deploy Azure Infrastructure
      2. VPN Certificate Management
      3. VPN Gateway Management
      4. VPN Client Management
      5. NAT Gateway Management
      6. View Documentation
      7. Configure Settings
      0. Exit
.EXAMPLE
    $selection = Show-MainMenu
.NOTES
    Author: Jurie Smit
    Date: March 5, 2025
#>
function Show-MainMenu {
    # Retrieve configuration if needed (for display, we can show current settings, etc.)
    $config = Get-Configuration

    $menuItems = @{
        "1" = "Deploy Azure Infrastructure"
        "2" = "VPN Certificate Management"
        "3" = "VPN Gateway Management"
        "4" = "VPN Client Management"
        "5" = "NAT Gateway Management"
        "6" = "View Documentation"
        "7" = "Configure Settings"
    }

    return Show-Menu -Title "HOME LAB SETUP - MAIN MENU" -MenuItems $menuItems -ExitOption "0"
}

Export-ModuleMember -Function Show-MainMenu
