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
.PARAMETER ShowProgress
    If specified, shows a progress bar while loading the menu.
.PARAMETER State
    Optional state hashtable for backward compatibility with existing code.
.EXAMPLE
    Show-MainMenu
.EXAMPLE
    Show-MainMenu -ShowProgress
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Show-MainMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$ShowProgress,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$State
    )
    
    # Retrieve configuration for display
    $config = Get-Configuration -ErrorAction SilentlyContinue
    
    # Create status message if config is available
    $statusMessage = $null
    
    # If State parameter is provided, use it for status message
    if ($State -and $State.Count -gt 0) {
        $statusInfo = @()
        if ($State.ContainsKey('User')) { $statusInfo += "User: $($State.User)" }
        if ($State.ContainsKey('ConnectionStatus')) { $statusInfo += "Azure: $($State.ConnectionStatus)" }
        if ($State.ContainsKey('ConfigPath')) { $statusInfo += "Config: $($State.ConfigPath)" }
        
        if ($statusInfo.Count -gt 0) {
            $statusMessage = $statusInfo -join " | "
        }
    }
    # Otherwise use config if available
    elseif ($config) {
        $statusInfo = @()
        $statusInfo += "Environment: $($config.env)"
        $statusInfo += "Project: $($config.project)"
        $statusInfo += "Location: $($config.location)"
        
        $statusMessage = $statusInfo -join " | "
    }
    
    # Define menu items based on your existing structure
    $menuItems = @{
        "1" = "Deploy Azure Infrastructure"
        "2" = "VPN Certificate Management"
        "3" = "VPN Gateway Management"
        "4" = "VPN Client Management"
        "5" = "NAT Gateway Management"
        "6" = "View Documentation"
        "7" = "Configure Settings"
    }
    
    # Display the menu and get the user's choice
    $result = Show-Menu -Title "HOME LAB SETUP - MAIN MENU" -MenuItems $menuItems `
                        -ExitOption "0" -ExitText "Exit" -ShowProgress:$ShowProgress `
                        -DefaultOption "1" -ValidateInput -ShowStatus $statusMessage `
                        -ShowHelp:($State -ne $null)
    
    return $result
}