<#
.SYNOPSIS
    Handles network infrastructure deployment
.DESCRIPTION
    Deploys network components including virtual network and subnets
.PARAMETER Config
    The configuration object containing deployment settings
.PARAMETER TargetInfo
    A formatted string describing the deployment target
.PARAMETER ResourceGroup
    The name of the resource group to deploy to
.PARAMETER Location
    The Azure location to deploy to
.EXAMPLE
    Invoke-NetworkDeployment -Config $config -TargetInfo "[Target: dev-saf-homelab]" -ResourceGroup "dev-saf-rg-homelab" -Location "southafricanorth"
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Invoke-NetworkDeployment {
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
    
    Write-ColorOutput "Deploying network only... $TargetInfo" -ForegroundColor Cyan
    
    # Initialize variables with default values
    $useForce = $false
    $useMonitor = $false
    $useBackgroundMonitor = $false
    
    # Check if resource group exists
    $rgExists = az group exists --name $ResourceGroup --output tsv 2>$null
    
    if ($rgExists -ne "true") {
        Write-ColorOutput "Resource group '$ResourceGroup' does not exist. Creating it..." -ForegroundColor Yellow
        az group create --name $ResourceGroup --location $Location | Out-Null
    }
    else {
        # Check if network resources exist
        $vnetName = "$($Config.env)-$($Config.loc)-vnet-$($Config.project)"
        $vnetExists = az network vnet show --resource-group $ResourceGroup --name $vnetName --query "name" -o tsv 2>$null
        
        if ($vnetExists -or $LASTEXITCODE -eq 0) {
            Write-ColorOutput "Warning: Virtual Network '$vnetName' already exists." -ForegroundColor Yellow
            $confirmation = Read-Host "Do you want to delete and recreate the network resources? (Y/N)"
            
            if ($confirmation -eq "Y" -or $confirmation -eq "y") {
                Write-ColorOutput "Deleting existing network resources..." -ForegroundColor Yellow
                az network vnet delete --resource-group $ResourceGroup --name $vnetName --yes 2>$null
                Write-ColorOutput "Network resources deleted. Proceeding with deployment..." -ForegroundColor Green
            }
            else {
                Write-ColorOutput "Proceeding with deployment to existing network..." -ForegroundColor Yellow
                $confirmation = Read-Host "Skip confirmation prompts during deployment? (Y/N)"
                $useForce = ($confirmation -eq "Y" -or $confirmation -eq "y")
            }
        }
    }
    
    $monitorConfirmation = Read-Host "Monitor deployment progress? (F)oreground, (B)ackground, or (N)one"
    $useMonitor = $monitorConfirmation -eq "F" -or $monitorConfirmation -eq "f"
    $useBackgroundMonitor = $monitorConfirmation -eq "B" -or $monitorConfirmation -eq "b"
    
    $result = Start-ProgressTask -Activity "Network Deployment $TargetInfo" -TotalSteps 3 -ScriptBlock {
        param($useForce, $useMonitor, $useBackgroundMonitor)
        
        # Step 1: Resource Group
        $Global:syncHash.Status = "Creating/Verifying Resource Group..."
        $Global:syncHash.CurrentStep = 1
        
        # Step 2: Virtual Network
        $Global:syncHash.Status = "Deploying Virtual Network..."
        $Global:syncHash.CurrentStep = 2
        
        # Step 3: Subnets
        $Global:syncHash.Status = "Configuring Subnets..."
        $Global:syncHash.CurrentStep = 3
        
        try {
            # Call the actual deployment function with appropriate parameters
            if ($useForce -and $useMonitor) {
                Deploy-Infrastructure -ComponentsOnly "network" -Force -Monitor
            } 
            elseif ($useForce -and $useBackgroundMonitor) {
                Deploy-Infrastructure -ComponentsOnly "network" -Force -BackgroundMonitor
            }
            elseif ($useForce) {
                Deploy-Infrastructure -ComponentsOnly "network" -Force
            }
            elseif ($useMonitor) {
                Deploy-Infrastructure -ComponentsOnly "network" -Monitor
            }
            elseif ($useBackgroundMonitor) {
                Deploy-Infrastructure -ComponentsOnly "network" -BackgroundMonitor
            }
            else {
                Deploy-Infrastructure -ComponentsOnly "network"
            }
            
            # If background monitoring was started, show a message
            if ($useBackgroundMonitor) {
                return "Deployment initiated successfully! Background monitoring has been started."
            }
            
            return "Network deployment completed successfully!"
        }
        catch {
            return "Error deploying network: $_"
        }
    } -ArgumentList $useForce, $useMonitor, $useBackgroundMonitor
    
    if ($result -like "Error*") {
        Write-ColorOutput $result -ForegroundColor Red
    } else {
        Write-ColorOutput $result -ForegroundColor Green
    }
    
    Pause
}
