<#
.SYNOPSIS
    Enables or disables a VPN Gateway.
.DESCRIPTION
    Starts or stops a VPN Gateway to control costs without deleting the resource.
    Disabling stops billing for the gateway compute but maintains the configuration.
.PARAMETER ResourceGroup
    The name of the resource group containing the VPN Gateway.
.PARAMETER GatewayName
    The name of the VPN Gateway to enable or disable.
.PARAMETER Action
    The action to perform: "Enable" or "Disable".
.EXAMPLE
    Set-VpnGatewayState -ResourceGroup "dev-eastus-rg-homelab" -GatewayName "dev-eastus-vpng-homelab" -Action "Disable"
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Set-VpnGatewayState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory=$true)]
        [string]$GatewayName,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("Enable", "Disable")]
        [string]$Action
    )
    
    try {
        # Check if the VPN Gateway exists
        $vpnExists = az network vnet-gateway show --resource-group $ResourceGroup --name $GatewayName --query "name" -o tsv 2>$null
        
        if (-not $vpnExists -or $LASTEXITCODE -ne 0) {
            Write-ColorOutput "VPN Gateway '$GatewayName' does not exist in resource group '$ResourceGroup'." -ForegroundColor Red
            return $false
        }
        
        if ($Action -eq "Disable") {
            Write-ColorOutput "Disabling VPN Gateway '$GatewayName'..." -ForegroundColor Yellow
            Write-ColorOutput "This operation may take a few minutes to complete." -ForegroundColor Yellow
            
            # Stop the VPN Gateway
            $result = az network vnet-gateway stop --resource-group $ResourceGroup --name $GatewayName --no-wait
            
            if ($LASTEXITCODE -ne 0) {
                Write-ColorOutput "Failed to disable VPN Gateway." -ForegroundColor Red
                return $false
            }
            
            Write-ColorOutput "VPN Gateway disable operation initiated successfully." -ForegroundColor Green
            Write-ColorOutput "The gateway will stop billing for compute resources when fully stopped." -ForegroundColor Green
            return $true
        }
        else {
            Write-ColorOutput "Enabling VPN Gateway '$GatewayName'..." -ForegroundColor Yellow
            Write-ColorOutput "This operation may take 15-30 minutes to complete." -ForegroundColor Yellow
            
            # Start the VPN Gateway
            $result = az network vnet-gateway start --resource-group $ResourceGroup --name $GatewayName --no-wait
            
            if ($LASTEXITCODE -ne 0) {
                Write-ColorOutput "Failed to enable VPN Gateway." -ForegroundColor Red
                return $false
            }
            
            Write-ColorOutput "VPN Gateway enable operation initiated successfully." -ForegroundColor Green
            Write-ColorOutput "The gateway will start billing for compute resources when fully started." -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-ColorOutput "Error changing VPN Gateway state: $_" -ForegroundColor Red
        return $false
    }
}

