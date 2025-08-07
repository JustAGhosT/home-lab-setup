<#
.SYNOPSIS
    Displays the deployment menu
.DESCRIPTION
    Shows the deployment menu options and returns the user's selection
.PARAMETER ShowProgress
    If specified, shows a progress bar while loading the menu
.EXAMPLE
    Show-DeployMenu
.EXAMPLE
    Show-DeployMenu -ShowProgress
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Show-DeployMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$ShowProgress,

        [Parameter(Mandatory = $false)]
        [hashtable]$State
    )
    
    # Get configuration for displaying in the menu
    $config = Get-Configuration -ErrorAction SilentlyContinue
    $targetInfo = if ($config) { "$($config.env)-$($config.loc)-$($config.project)" } else { "Not configured" }
    
    if ($ShowProgress) {
        # Show a progress bar while loading the menu
        $progressParams = @{
            Activity = "Loading Deployment Menu"
            Status = "Preparing options..."
            PercentComplete = 0
        }
        
        Write-Progress @progressParams
        Start-Sleep -Milliseconds 300
        
        $progressParams.Status = "Loading configuration..."
        $progressParams.PercentComplete = 30
        Write-Progress @progressParams
        Start-Sleep -Milliseconds 300
        
        $progressParams.Status = "Checking Azure connection..."
        $progressParams.PercentComplete = 60
        Write-Progress @progressParams
        Start-Sleep -Milliseconds 300
        
        $progressParams.Status = "Ready"
        $progressParams.PercentComplete = 100
        Write-Progress @progressParams
        Start-Sleep -Milliseconds 300
        
        # Complete the progress bar
        Write-Progress -Activity "Loading Deployment Menu" -Completed
    }
    
    Clear-Host
    
    # Display the menu header with ASCII art
    Write-ColorOutput @"
    
╔══════════════════════════════════════════════════════════════════╗
║                      AZURE DEPLOYMENT MENU                       ║
╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
    
    # Display current target
    Write-ColorOutput "  Current Target: " -ForegroundColor White -NoNewline
    Write-ColorOutput $targetInfo -ForegroundColor $(if ($config) { "Green" } else { "Red" })
    Write-ColorOutput ""
    
    # Display menu options
    Write-ColorOutput "  1. Deploy Full Infrastructure" -ForegroundColor White
    Write-ColorOutput "  2. Deploy Network Only" -ForegroundColor White
    Write-ColorOutput "  3. Deploy VPN Gateway Only" -ForegroundColor White
    Write-ColorOutput "  4. Deploy NAT Gateway Only" -ForegroundColor White
    Write-ColorOutput "  5. Check Deployment Status" -ForegroundColor White
    Write-ColorOutput "  6. VPN Gateway Management (Enable/Disable)" -ForegroundColor White
    Write-ColorOutput "  7. View Background Monitoring Status" -ForegroundColor White
    Write-ColorOutput "  0. Return to Main Menu" -ForegroundColor White
    Write-ColorOutput ""
    
    # Get user selection
    $choice = Read-Host "Select an option"
    
    # Return the user's choice and whether they chose to exit
    return @{
        Choice = $choice
        IsExit = ($choice -eq "0")
    }
}
