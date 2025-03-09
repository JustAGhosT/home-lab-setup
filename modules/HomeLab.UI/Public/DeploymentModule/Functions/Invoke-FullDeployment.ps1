<#
.SYNOPSIS
    Handles full infrastructure deployment
.DESCRIPTION
    Deploys all infrastructure components including resource group, network, and other resources
.PARAMETER Config
    The configuration object containing deployment settings
.PARAMETER TargetInfo
    A formatted string describing the deployment target
.PARAMETER ResourceGroup
    The name of the resource group to deploy to
.PARAMETER Location
    The Azure location to deploy to
.EXAMPLE
    Invoke-FullDeployment -Config $config -TargetInfo "[Target: dev-saf-homelab]" -ResourceGroup "dev-saf-rg-homelab" -Location "southafricanorth"
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Invoke-FullDeployment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config,
        
        [Parameter(Mandatory = $true)]
        [string]$TargetInfo,
        
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory = $true)]
        [string]$Location
    )
    
    Write-ColorOutput "Starting full deployment... $TargetInfo" -ForegroundColor Cyan
    
    # Initialize variables with default values
    $useForce = $false
    $useMonitor = $false
    $useBackgroundMonitor = $false
    
    # Check if resource group exists
    $rgExists = az group exists --name $ResourceGroup --output tsv 2>$null
    
    if ($rgExists -eq "true") {
        Write-ColorOutput "Warning: Resource group '$ResourceGroup' already exists." -ForegroundColor Yellow
        $confirmation = Read-Host "Do you want to reset the resource group (delete and recreate)? (Y/N)"
        
        if ($confirmation -eq "Y" -or $confirmation -eq "y") {
            # Reset the resource group
            $resetResult = Reset-ResourceGroup -ResourceGroupName $ResourceGroup -Location $Location -Force
            
            if (-not $resetResult) {
                Write-ColorOutput "Resource group reset failed or was cancelled. Deployment cancelled." -ForegroundColor Yellow
                Pause
                return
            }
            
            Write-ColorOutput "Resource group has been reset. Proceeding with deployment..." -ForegroundColor Green
        }
        else {
            Write-ColorOutput "Proceeding with deployment to existing resource group..." -ForegroundColor Yellow
            $confirmation = Read-Host "Skip confirmation prompts during deployment? (Y/N)"
            $useForce = ($confirmation -eq "Y" -or $confirmation -eq "y")
        }
    }
    
    $monitorConfirmation = Read-Host "Monitor deployment progress? (F)oreground, (B)ackground, or (N)one"
    $useMonitor = $monitorConfirmation -eq "F" -or $monitorConfirmation -eq "f"
    $useBackgroundMonitor = $monitorConfirmation -eq "B" -or $monitorConfirmation -eq "b"
    
    # Create a progress task for the full deployment
    $result = Start-ProgressTask -Activity "Full Deployment $TargetInfo" -TotalSteps 5 -ScriptBlock {
        param($useForce, $useMonitor, $useBackgroundMonitor)
        
        # Step 1: Resource Group
        $Global:syncHash.Status = "Creating/Verifying Resource Group..."
        $Global:syncHash.CurrentStep = 1
        
        try {
            # Call the actual deployment function with appropriate parameters
            if ($useForce -and $useMonitor) {
                Deploy-Infrastructure -Force -Monitor
            } 
            elseif ($useForce -and $useBackgroundMonitor) {
                Deploy-Infrastructure -Force -BackgroundMonitor
            }
            elseif ($useForce) {
                Deploy-Infrastructure -Force
            }
            elseif ($useMonitor) {
                Deploy-Infrastructure -Monitor
            }
            elseif ($useBackgroundMonitor) {
                Deploy-Infrastructure -BackgroundMonitor
            }
            else {
                Deploy-Infrastructure
            }
            
            # If background monitoring was started, show a message
            if ($useBackgroundMonitor) {
                return "Deployment initiated successfully! Background monitoring has been started."
            }
            
            # If the deployment is successful, return a success message
            return "Full deployment completed successfully!"
        }
        catch {
            return "Error during deployment: $_"
        }
    } -ArgumentList $useForce, $useMonitor, $useBackgroundMonitor
    
    if ($result -like "Error*") {
        Write-ColorOutput $result -ForegroundColor Red
    } else {
        Write-ColorOutput $result -ForegroundColor Green
    }
    
    Pause
}
