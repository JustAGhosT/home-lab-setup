<#
.SYNOPSIS
    Gets the current configuration.
.DESCRIPTION
    Retrieves the current configuration from the configuration file.
    If the configuration file doesn't exist, returns a default configuration.
.EXAMPLE
    $config = Get-Configuration
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Get-Configuration {
    [CmdletBinding()]
    param()
    
    # Define the path to the configuration file
    $configPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\config\homelab.config.json"
    
    # Check if the configuration file exists
    if (Test-Path -Path $configPath) {
        # Read the configuration file
        $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
    } else {
        # Return default configuration
        $config = [PSCustomObject]@{
            env = "dev"
            loc = "saf"
            project = "homelab"
            location = "southafricanorth"
        }
    }
    
    return $config
}

# Export the functions
Export-ModuleMember -Function Show-Menu, Show-MainMenu, Show-DeployMenu, Show-VpnCertMenu, 
                              Show-VpnGatewayMenu, Show-VpnClientMenu, Show-NatGatewayMenu,
                              Show-DocumentationMenu, Show-SettingsMenu, Get-Configuration