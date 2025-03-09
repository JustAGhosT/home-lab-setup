<#
.SYNOPSIS
    Handles VPN Gateway deployment.
.DESCRIPTION
    Deploys VPN Gateway components including public IP and gateway configuration.
    This function displays warnings, checks prerequisites, and then initiates the deployment.
.PARAMETER Config
    The configuration object containing deployment settings.
.PARAMETER TargetInfo
    A formatted string describing the deployment target.
.PARAMETER ResourceGroup
    The name of the resource group to deploy to.
.PARAMETER Location
    The Azure location to deploy to.
.EXAMPLE
    Invoke-VPNGatewayDeployment -Config $config -TargetInfo "[Target: dev-saf-homelab]" -ResourceGroup "dev-saf-rg-homelab" -Location "southafricanorth"
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Invoke-VPNGatewayDeployment {
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
    
    Write-ColorOutput "Deploying VPN Gateway only... $TargetInfo" -ForegroundColor Cyan
    
    # Initialize variables with default values.
    $useForce = $false
    $useMonitor = $false
    $useBackgroundMonitor = $false
    
    # Display important warning about VPN Gateway deployment.
    Write-ColorOutput "`n⚠️ IMPORTANT VPN GATEWAY INFORMATION ⚠️" -ForegroundColor Yellow
    Write-ColorOutput "- Deployment will take 30-45 minutes to complete" -ForegroundColor Yellow
    Write-ColorOutput "- VPN Gateway incurs hourly Azure charges (~$0.30-$1.20/hour depending on SKU)" -ForegroundColor Yellow
    Write-ColorOutput "- Gateway will continue to incur charges until explicitly deleted" -ForegroundColor Yellow
    Write-ColorOutput "- For testing purposes, consider deleting after use to minimize costs`n" -ForegroundColor Yellow
    
    $vpnConfirmation = Read-Host "Are you sure you want to proceed with VPN Gateway deployment? (Y/N)"
    if ($vpnConfirmation -ne "Y" -and $vpnConfirmation -ne "y") {
        Write-ColorOutput "VPN Gateway deployment cancelled." -ForegroundColor Cyan
        Pause
        return
    }
    
    # Check if resource group exists.
    $rgExists = az group exists --name $ResourceGroup --output tsv 2>$null
    if ($rgExists -ne "true") {
        Write-ColorOutput "Resource group '$ResourceGroup' does not exist. Creating it..." -ForegroundColor Yellow
        az group create --name $ResourceGroup --location $Location | Out-Null
    }
    else {
        # Check if VPN Gateway exists.
        $vpnGatewayName = "$($Config.env)-$($Config.loc)-vpng-$($Config.project)"
        $vpnExists = az network vnet-gateway show --resource-group $ResourceGroup --name $vpnGatewayName --query "name" -o tsv 2>$null
        
        if ($vpnExists -or $LASTEXITCODE -eq 0) {
            Write-ColorOutput "Warning: VPN Gateway '$vpnGatewayName' already exists." -ForegroundColor Yellow
            $confirmation = Read-Host "Do you want to delete and recreate the VPN Gateway? (Y/N)"
            
            if ($confirmation -eq "Y" -or $confirmation -eq "y") {
                Write-ColorOutput "Deleting existing VPN Gateway (this may take a few minutes)..." -ForegroundColor Yellow
                az network vnet-gateway delete --resource-group $ResourceGroup --name $vpnGatewayName --yes 2>$null
                Write-ColorOutput "VPN Gateway deleted. Proceeding with deployment..." -ForegroundColor Green
            }
            else {
                Write-ColorOutput "Proceeding with deployment to existing VPN Gateway..." -ForegroundColor Yellow
                $confirmation = Read-Host "Skip confirmation prompts during deployment? (Y/N)"
                $useForce = ($confirmation -eq "Y" -or $confirmation -eq "y")
            }
        }
    }
    
    # Check if the required virtual network exists.
    $vnetName = "$($Config.env)-$($Config.loc)-vnet-$($Config.project)"
    $vnetExists = az network vnet show --resource-group $ResourceGroup --name $vnetName --query "name" -o tsv 2>$null
    if (-not $vnetExists -and $LASTEXITCODE -ne 0) {
        Write-ColorOutput "Warning: Virtual Network '$vnetName' does not exist. VPN Gateway requires a virtual network." -ForegroundColor Yellow
        $networkConfirmation = Read-Host "Would you like to deploy the network first? (Y/N)"
        if ($networkConfirmation -eq "Y" -or $networkConfirmation -eq "y") {
            Write-ColorOutput "Deploying network resources first..." -ForegroundColor Cyan
            try {
                Deploy-Infrastructure -ComponentsOnly "network" -Force
                Write-ColorOutput "Network deployment completed. Proceeding with VPN Gateway deployment..." -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error deploying network: $_" -ForegroundColor Red
                Write-ColorOutput "VPN Gateway deployment cancelled." -ForegroundColor Red
                Pause
                return
            }
        }
        else {
            Write-ColorOutput "VPN Gateway requires a virtual network. Deployment cancelled." -ForegroundColor Red
            Pause
            return
        }
    }
    
    $monitorConfirmation = Read-Host "Monitor deployment progress? (F)oreground, (B)ackground, or (N)one"
    $useMonitor = $monitorConfirmation -eq "F" -or $monitorConfirmation -eq "f"
    $useBackgroundMonitor = $monitorConfirmation -eq "B" -or $monitorConfirmation -eq "b"
    
    # Capture variables to be used in the script block
    $localUseForce = $useForce
    $localUseMonitor = $useMonitor
    $localUseBackgroundMonitor = $useBackgroundMonitor
    
    # Create the script block
    $deploymentScriptBlock = {
        param($useForce, $useMonitor, $useBackgroundMonitor)
        
        # Step 1: Verify Prerequisites
        $Global:syncHash.Status = "Verifying prerequisites..."
        $Global:syncHash.CurrentStep = 1
        
        # Step 2: Public IP
        $Global:syncHash.Status = "Creating Public IP..."
        $Global:syncHash.CurrentStep = 2
        
        # Step 3: Gateway Subnet
        $Global:syncHash.Status = "Configuring Gateway Subnet..."
        $Global:syncHash.CurrentStep = 3
        
        # Step 4: VPN Gateway
        $Global:syncHash.Status = "Deploying VPN Gateway (this may take 30+ minutes)..."
        $Global:syncHash.CurrentStep = 4
        
        try {
            if ($useForce -and $useMonitor) {
                Deploy-Infrastructure -ComponentsOnly "vpngateway" -Force -Monitor
            } 
            elseif ($useForce -and $useBackgroundMonitor) {
                Deploy-Infrastructure -ComponentsOnly "vpngateway" -Force -BackgroundMonitor
            }
            elseif ($useForce) {
                Deploy-Infrastructure -ComponentsOnly "vpngateway" -Force
            }
            elseif ($useMonitor) {
                Deploy-Infrastructure -ComponentsOnly "vpngateway" -Monitor
            }
            elseif ($useBackgroundMonitor) {
                Deploy-Infrastructure -ComponentsOnly "vpngateway" -BackgroundMonitor
            }
            else {
                Deploy-Infrastructure -ComponentsOnly "vpngateway"
            }
            
            if ($useBackgroundMonitor) {
                return "Deployment initiated successfully! Background monitoring has been started."
            }
            return "VPN Gateway deployment initiated successfully! (Full provisioning may take 30+ minutes)"
        }
        catch {
            return "Error deploying VPN Gateway: $_"
        }
    }
    
    # Start the progress task with proper variable passing
    $result = Start-ProgressTask -Activity "VPN Gateway Deployment $TargetInfo" -TotalSteps 4 -ScriptBlock $deploymentScriptBlock -ArgumentList @($localUseForce, $localUseMonitor, $localUseBackgroundMonitor)
    
    if ($result -like "Error*") {
        Write-ColorOutput $result -ForegroundColor Red
    }
    else {
        Write-ColorOutput $result -ForegroundColor Green
        Write-ColorOutput "`nIMPORTANT: The VPN Gateway will continue to incur charges until explicitly deleted." -ForegroundColor Yellow
        Write-ColorOutput "Use option 5 to check deployment status. When finished testing, consider deleting the VPN Gateway." -ForegroundColor Yellow
    }
    
    Pause
}
