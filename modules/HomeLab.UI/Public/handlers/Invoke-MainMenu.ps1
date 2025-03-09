<#
.SYNOPSIS
    Handles the main menu interactions
.DESCRIPTION
    Processes user selections from the main menu and launches appropriate sub-menus or actions
.PARAMETER ShowProgress
    If specified, shows a progress bar while loading the menu.
.PARAMETER State
    Optional state hashtable for backward compatibility with existing code.
.EXAMPLE
    Invoke-MainMenu
.EXAMPLE
    Invoke-MainMenu -ShowProgress
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Invoke-MainMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$ShowProgress,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$State
    )
    
    $exitApplication = $false
    
    do {
        # Show main menu and get result
        $result = Show-MainMenu -ShowProgress:$ShowProgress -State $State
        
        # Process the user's choice
        if ($result.IsExit) {
            # Exit the application
            $exitApplication = $true
            continue
        }
        
        if ($result.IsHelp) {
            # Show help if requested
            if (Get-Command -Name Show-Help -ErrorAction SilentlyContinue) {
                Show-Help -State $State
            } else {
                Write-Host "`nHelp functionality is not implemented yet.`n" -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            }
            
            # Continue to next iteration (will show main menu again)
            continue
        }
        
        # Handle menu selection
        switch ($result.Choice) {
            "1" { 
                if (Get-Command -Name Invoke-DeployMenu -ErrorAction SilentlyContinue) {
                    Invoke-DeployMenu -ShowProgress:$ShowProgress 
                } 
                elseif (Get-Command -Name Show-DeployMenu -ErrorAction SilentlyContinue) {
                    # For backward compatibility
                    Show-DeployMenu -ShowProgress:$ShowProgress 
                }
                else {
                    Write-Host "`nDeployment menu not implemented yet.`n" -ForegroundColor Yellow
                    Start-Sleep -Seconds 2
                }
            }
            "2" { 
                if (Get-Command -Name Invoke-VpnCertMenu -ErrorAction SilentlyContinue) {
                    Invoke-VpnCertMenu -ShowProgress:$ShowProgress 
                }
                elseif (Get-Command -Name Show-VpnCertMenu -ErrorAction SilentlyContinue) {
                    # For backward compatibility
                    Show-VpnCertMenu -ShowProgress:$ShowProgress 
                }
                else {
                    Write-Host "`nVPN Certificate menu not implemented yet.`n" -ForegroundColor Yellow
                    Start-Sleep -Seconds 2
                }
            }
            "3" { 
                if (Get-Command -Name Invoke-VpnGatewayMenu -ErrorAction SilentlyContinue) {
                    Invoke-VpnGatewayMenu -ShowProgress:$ShowProgress 
                }
                elseif (Get-Command -Name Show-VpnGatewayMenu -ErrorAction SilentlyContinue) {
                    # For backward compatibility
                    Show-VpnGatewayMenu -ShowProgress:$ShowProgress 
                }
                else {
                    Write-Host "`nVPN Gateway menu not implemented yet.`n" -ForegroundColor Yellow
                    Start-Sleep -Seconds 2
                }
            }
            "4" { 
                if (Get-Command -Name Invoke-VpnClientMenu -ErrorAction SilentlyContinue) {
                    Invoke-VpnClientMenu -ShowProgress:$ShowProgress 
                }
                elseif (Get-Command -Name Show-VpnClientMenu -ErrorAction SilentlyContinue) {
                    # For backward compatibility
                    Show-VpnClientMenu -ShowProgress:$ShowProgress 
                }
                else {
                    Write-Host "`nVPN Client menu not implemented yet.`n" -ForegroundColor Yellow
                    Start-Sleep -Seconds 2
                }
            }
            "5" { 
                if (Get-Command -Name Invoke-NatGatewayMenu -ErrorAction SilentlyContinue) {
                    Invoke-NatGatewayMenu -ShowProgress:$ShowProgress 
                }
                elseif (Get-Command -Name Show-NatGatewayMenu -ErrorAction SilentlyContinue) {
                    # For backward compatibility
                    Show-NatGatewayMenu -ShowProgress:$ShowProgress 
                }
                else {
                    Write-Host "`nNAT Gateway menu not implemented yet.`n" -ForegroundColor Yellow
                    Start-Sleep -Seconds 2
                }
            }
            "6" { 
                if (Get-Command -Name Invoke-DocumentationMenu -ErrorAction SilentlyContinue) {
                    Invoke-DocumentationMenu -ShowProgress:$ShowProgress 
                }
                elseif (Get-Command -Name Show-DocumentationMenu -ErrorAction SilentlyContinue) {
                    # For backward compatibility
                    Show-DocumentationMenu -ShowProgress:$ShowProgress 
                }
                else {
                    Write-Host "`nDocumentation menu not implemented yet.`n" -ForegroundColor Yellow
                    Start-Sleep -Seconds 2
                }
            }
            "7" { 
                if (Get-Command -Name Invoke-SettingsMenu -ErrorAction SilentlyContinue) {
                    Invoke-SettingsMenu -ShowProgress:$ShowProgress 
                }
                elseif (Get-Command -Name Show-SettingsMenu -ErrorAction SilentlyContinue) {
                    # For backward compatibility
                    Show-SettingsMenu -ShowProgress:$ShowProgress 
                }
                else {
                    Write-Host "`nSettings menu not implemented yet.`n" -ForegroundColor Yellow
                    Start-Sleep -Seconds 2
                }
            }
        }
        
        # Only show progress on first display
        $ShowProgress = $false
        
    } while (-not $exitApplication)
}