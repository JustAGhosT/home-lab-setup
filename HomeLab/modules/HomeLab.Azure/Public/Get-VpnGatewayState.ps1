<#
.SYNOPSIS
    Gets the current state of a VPN Gateway.
.DESCRIPTION
    Retrieves the operational state of a VPN Gateway (Running, Stopped, etc.).
.PARAMETER ResourceGroup
    The name of the resource group containing the VPN Gateway.
.PARAMETER GatewayName
    The name of the VPN Gateway.
.EXAMPLE
    Get-VpnGatewayState -ResourceGroup "dev-eastus-rg-homelab" -GatewayName "dev-eastus-vpng-homelab"
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Get-VpnGatewayState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory=$true)]
        [string]$GatewayName
    )
    
    try {
        # Get the VPN Gateway operational state
        $state = az network vnet-gateway show --resource-group $ResourceGroup --name $GatewayName --query "vpnGatewayGeneration" -o tsv 2>$null
        
        if ($LASTEXITCODE -ne 0) {
            return "Not Found"
        }
        
        return $state
    }
    catch {
        Write-ColorOutput "Error getting VPN Gateway state: $_" -ForegroundColor Red
        return "Error"
    }
}
