<#
.SYNOPSIS
    Handles NAT Gateway deployment
.DESCRIPTION
    Deploys NAT Gateway components including public IP and NAT configuration
.PARAMETER Config
    The configuration object containing deployment settings
.PARAMETER TargetInfo
    A formatted string describing the deployment target
.PARAMETER ResourceGroup
    The name of the resource group to deploy to
.PARAMETER Location
    The Azure location to deploy to
.EXAMPLE
    Invoke-NATGatewayDeployment -Config $config -TargetInfo "[Target: dev-saf-homelab]" -ResourceGroup "dev-saf-rg-homelab" -Location "southafricanorth"
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Invoke-NATGatewayDeployment {
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
    
    Write-ColorOutput "Deploying NAT Gateway only... $TargetInfo" -ForegroundColor Cyan
    
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
        # Check if NAT Gateway exists
        $natGatewayName = "$($Config.env)-$($Config.loc)-natgw-$($Config.project)"
        $natExists = az network nat gateway show --resource-group $ResourceGroup --name $natGatewayName --query "name" -o tsv 2>$null
        
        if ($natExists -or $LASTEXITCODE -eq 0) {
            Write-ColorOutput "Warning: NAT Gateway '$natGatewayName' already exists." -ForegroundColor Yellow
            $confirmation = Read-Host "Do you want to delete and recreate the NAT Gateway? (Y/N)"
            
            if ($confirmation -eq "Y" -or $confirmation -eq "y") {
                Write-ColorOutput "Deleting existing NAT Gateway..." -ForegroundColor Yellow
                az network nat gateway delete --resource-group $ResourceGroup --name $natGatewayName --yes 2>$null
                Write-ColorOutput "NAT Gateway deleted. Proceeding with deployment..." -ForegroundColor Green
            }
            else {
                Write-ColorOutput "Proceeding with deployment to existing NAT Gateway..." -ForegroundColor Yellow
                $confirmation = Read-Host "Skip confirmation prompts during deployment? (Y/N)"
                $useForce = ($confirmation -eq "Y" -or $confirmation -eq "y")
            }
        }
    }
    
    $monitorConfirmation = Read-Host "Monitor deployment progress? (F)oreground, (B)ackground, or (N)one"
    $useMonitor = $monitorConfirmation -eq "F" -or $monitorConfirmation -eq "f"
    $useBackgroundMonitor = $monitorConfirmation -eq "B" -or $monitorConfirmation -eq "b"
    
    $result = Start-ProgressTask -Activity "NAT Gateway Deployment $TargetInfo" -TotalSteps 3 -ScriptBlock {
        param($useForce, $useMonitor, $useBackgroundMonitor)
        
        # Step 1: Verify Prerequisites
        $Global:syncHash.Status = "Verifying prerequisites..."
        $Global:syncHash.CurrentStep = 1
        
        # Step 2: Public IP
        $Global:syncHash.Status = "Creating Public IP..."
        $Global:syncHash.CurrentStep = 2
        
        # Step 3: NAT Gateway
        $Global:syncHash.Status = "Deploying NAT Gateway..."
        $Global:syncHash.CurrentStep = 3
        
        try {
            # Call the actual deployment function with appropriate parameters
            if ($useForce -and $useMonitor) {
                Deploy-Infrastructure -ComponentsOnly "natgateway" -Force -Monitor
            } 
            elseif ($useForce -and $useBackgroundMonitor) {
                Deploy-Infrastructure -ComponentsOnly "natgateway" -Force -BackgroundMonitor
            }
            elseif ($useForce) {
                Deploy-Infrastructure -ComponentsOnly "natgateway" -Force
            }
            elseif ($useMonitor) {
                Deploy-Infrastructure -ComponentsOnly "natgateway" -Monitor
            }
            elseif ($useBackgroundMonitor) {
                Deploy-Infrastructure -ComponentsOnly "natgateway" -BackgroundMonitor
            }
            else {
                Deploy-Infrastructure -ComponentsOnly "natgateway"
            }
            
            # If background monitoring was started, show a message
            if ($useBackgroundMonitor) {
                return "Deployment initiated successfully! Background monitoring has been started."
            }
            
            return "NAT Gateway deployment completed successfully!"
        }
        catch {
            return "Error deploying NAT Gateway: $_"
        }
    } -ArgumentList $useForce, $useMonitor, $useBackgroundMonitor
    
    if ($result -like "Error*") {
        Write-ColorOutput $result -ForegroundColor Red
    } else {
        Write-ColorOutput $result -ForegroundColor Green
    }
    
    Pause
}
