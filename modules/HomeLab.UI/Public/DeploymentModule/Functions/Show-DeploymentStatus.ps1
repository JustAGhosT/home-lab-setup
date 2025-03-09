<#
.SYNOPSIS
    Shows the status of deployed resources
.DESCRIPTION
    Queries Azure for the status of deployed resources and displays them in a formatted way
.PARAMETER Config
    The configuration object containing deployment settings
.PARAMETER TargetInfo
    A formatted string describing the deployment target
.PARAMETER ResourceGroup
    The name of the resource group to check
.PARAMETER Location
    The Azure location of the resources
.EXAMPLE
    Show-DeploymentStatus -Config $config -TargetInfo "[Target: dev-saf-homelab]" -ResourceGroup "dev-saf-rg-homelab" -Location "southafricanorth"
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Show-DeploymentStatus {
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
    
    Write-ColorOutput "Checking deployment status... $TargetInfo" -ForegroundColor Cyan
    
    $result = Start-ProgressTask -Activity "Checking Deployment Status $TargetInfo" -TotalSteps 4 -ScriptBlock {
        # Step 1: Resource Group
        $Global:syncHash.Status = "Checking Resource Group..."
        $Global:syncHash.CurrentStep = 1
        
        $status = az group show --name $ResourceGroup --query "properties.provisioningState" -o tsv 2>$null
        $rgStatus = if ($LASTEXITCODE -eq 0) { $status } else { "Not Found" }
        
        # Step 2: Virtual Network
        $Global:syncHash.Status = "Checking Virtual Network..."
        $Global:syncHash.CurrentStep = 2
        
        $vnetName = "$($Config.env)-$($Config.loc)-vnet-$($Config.project)"
        $vnetStatus = az network vnet show --resource-group $ResourceGroup --name $vnetName --query "provisioningState" -o tsv 2>$null
        $vnetStatus = if ($LASTEXITCODE -eq 0) { $vnetStatus } else { "Not Found" }
        
        # Step 3: VPN Gateway
        $Global:syncHash.Status = "Checking VPN Gateway..."
        $Global:syncHash.CurrentStep = 3
        
        $vpnGatewayName = "$($Config.env)-$($Config.loc)-vpng-$($Config.project)"
        $vpnStatus = az network vnet-gateway show --resource-group $ResourceGroup --name $vpnGatewayName --query "provisioningState" -o tsv 2>$null
        $vpnStatus = if ($LASTEXITCODE -eq 0) { $vpnStatus } else { "Not Found" }
        
        # Step 4: NAT Gateway
        $Global:syncHash.Status = "Checking NAT Gateway..."
        $Global:syncHash.CurrentStep = 4
        
        $natGatewayName = "$($Config.env)-$($Config.loc)-natgw-$($Config.project)"
        $natStatus = az network nat gateway show --resource-group $ResourceGroup --name $natGatewayName --query "provisioningState" -o tsv 2>$null
        $natStatus = if ($LASTEXITCODE -eq 0) { $natStatus } else { "Not Found" }
        
        # Return the status information
        return @{
            ResourceGroup = $rgStatus
            VirtualNetwork = $vnetStatus
            VPNGateway = $vpnStatus
            NATGateway = $natStatus
        }
    }
    
    # Display the results in a formatted way
    Write-ColorOutput "`nDeployment Status for $($TargetInfo):" -ForegroundColor Cyan
    Write-ColorOutput "  Resource Group: $($result.ResourceGroup)" -ForegroundColor $(if ($result.ResourceGroup -eq "Succeeded") { "Green" } else { "Yellow" })
    Write-ColorOutput "  Virtual Network: $($result.VirtualNetwork)" -ForegroundColor $(if ($result.VirtualNetwork -eq "Succeeded") { "Green" } else { "Yellow" })
    Write-ColorOutput "  VPN Gateway: $($result.VPNGateway)" -ForegroundColor $(if ($result.VPNGateway -eq "Succeeded") { "Green" } else { "Yellow" })
    Write-ColorOutput "  NAT Gateway: $($result.NATGateway)" -ForegroundColor $(if ($result.NATGateway -eq "Succeeded") { "Green" } else { "Yellow" })
    
    Pause-ForUser
}
