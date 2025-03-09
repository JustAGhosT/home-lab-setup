<#
.SYNOPSIS
    Handles the deployment menu.
.DESCRIPTION
    Processes user selections in the deployment menu and displays progress bars for deployment operations.
.PARAMETER ShowProgress
    If specified, shows a progress bar while loading the menu.
.EXAMPLE
    Invoke-DeployMenu
.EXAMPLE
    Invoke-DeployMenu -ShowProgress
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Invoke-DeployMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$ShowProgress
    )
    
    $exitMenu = $false
    
    do {
        # Get configuration for deployment operations.
        $config = Get-Configuration -ErrorAction SilentlyContinue
        
        # If no configuration is found, notify the user and return to main menu.
        if (-not $config) {
            Write-ColorOutput "Error: No configuration found. Please set up configuration first." -ForegroundColor Red
            Pause
            return
        }
        
        # Show the menu and get user selection.
        $menuResult = Show-DeployMenu -ShowProgress:$ShowProgress
        
        # If user chose to exit, break the loop.
        if ($menuResult.IsExit) {
            $exitMenu = $true
            continue
        }
        
        # Build target info with fallbacks.
        $envPart     = if ([string]::IsNullOrWhiteSpace($config.env)) { "Not set" } else { $config.env }
        $locPart     = if ([string]::IsNullOrWhiteSpace($config.loc)) { "Not set" } else { $config.loc }
        $projectPart = if ([string]::IsNullOrWhiteSpace($config.project)) { "Not set" } else { $config.project }
        $targetInfo = "[Target: $envPart-$locPart-$projectPart]"
        $resourceGroup = "$envPart-$locPart-rg-$projectPart"
        $location = if ([string]::IsNullOrWhiteSpace($config.location)) { "Not set" } else { $config.location }
        
        # Process the user's choice.
        switch ($menuResult.Choice) {
            "1" {
                Invoke-FullDeployment -Config $config -TargetInfo $targetInfo -ResourceGroup $resourceGroup -Location $location
            }
            "2" {
                Invoke-NetworkDeployment -Config $config -TargetInfo $targetInfo -ResourceGroup $resourceGroup -Location $location
            }
            "3" {
                Invoke-VPNGatewayDeployment -Config $config -TargetInfo $targetInfo -ResourceGroup $resourceGroup -Location $location
            }
            "4" {
                Invoke-NATGatewayDeployment -Config $config -TargetInfo $targetInfo -ResourceGroup $resourceGroup -Location $location
            }
            "5" {
                Show-DeploymentStatus -Config $config -TargetInfo $targetInfo -ResourceGroup $resourceGroup -Location $location
            }
            "7" {
                Show-BackgroundMonitoringStatus -Config $config -TargetInfo $targetInfo
            }
            default {
                Write-ColorOutput "Invalid option. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
        
        # Only show progress on first display.
        $ShowProgress = $false
        
    } while (-not $exitMenu)
}
