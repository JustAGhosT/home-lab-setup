<#
.SYNOPSIS
    Displays the Main Menu for Home Lab Setup.
.DESCRIPTION
    Presents the primary options for the Home Lab Setup application. In addition to the original
    deployment and management options, a new option is added to launch the Software KVM Setup menu.
    Options include:
      1. Deploy Azure Infrastructure
      2. VPN Certificate Management
      3. VPN Gateway Management
      4. VPN Client Management
      5. NAT Gateway Management
      6. View Documentation
      7. Configure Settings
      8. Software KVM Setup
      9. Website Deployment
      10. DNS Management
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
    
    # Retrieve configuration for display.
    $config = Get-Configuration -ErrorAction SilentlyContinue
    
    # Build status message from provided state or from config.
    $statusMessage = $null
    if ($State -and $State.Count -gt 0) {
        $statusInfo = @()
        if ($State.ContainsKey('User')) { $statusInfo += "User: $($State.User)" }
        if ($State.ContainsKey('ConnectionStatus')) { $statusInfo += "Azure: $($State.ConnectionStatus)" }
        if ($State.ContainsKey('ConfigPath')) { $statusInfo += "Config: $($State.ConfigPath)" }
        if ($statusInfo.Count -gt 0) {
            $statusMessage = $statusInfo -join " | "
        }
    }
    elseif ($config) {
        # Provide fallback values if any configuration property is empty.
        $envPart     = if ([string]::IsNullOrWhiteSpace($config.env)) { "Not set" } else { $config.env }
        $projectPart = if ([string]::IsNullOrWhiteSpace($config.project)) { "Not set" } else { $config.project }
        $locPart     = if ([string]::IsNullOrWhiteSpace($config.location)) { "Not set" } else { $config.location }
        
        $statusInfo = @(
            "Environment: $envPart",
            "Project: $projectPart",
            "Location: $locPart"
        )
        $statusMessage = $statusInfo -join " | "
    }
    
    # Define menu items including website deployment and DNS management.
    $menuItems = @{
        "1" = "Deploy Azure Infrastructure"
        "2" = "VPN Certificate Management"
        "3" = "VPN Gateway Management"
        "4" = "VPN Client Management"
        "5" = "NAT Gateway Management"
        "6" = "View Documentation"
        "7" = "Configure Settings"
        "8" = "Software KVM Setup"
        "9" = "Website Deployment"
        "10" = "DNS Management"
    }
    
    # Display the menu and get the user's choice.
    $result = Show-Menu -Title "HOME LAB SETUP - MAIN MENU" -MenuItems $menuItems `
                        -ExitOption "0" -ExitText "Exit" -ShowProgress:$ShowProgress `
                        -DefaultOption "1" -ValidateInput -ShowStatus $statusMessage `
                        -ShowHelp:($State -ne $null)
    
    return $result
}
