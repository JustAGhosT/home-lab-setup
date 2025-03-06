<#
.SYNOPSIS
    Enables or disables a NAT Gateway on one or more subnets.
.DESCRIPTION
    Updates the NAT gateway association on specified subnets.
    Use -Enable to associate the NAT gateway with the subnets or -Disable to remove it.
.PARAMETER Enable
    Switch to enable the NAT gateway.
.PARAMETER Disable
    Switch to disable the NAT gateway.
.PARAMETER ResourceGroup
    The resource group in which the virtual network resides.
.PARAMETER NatGatewayName
    (Optional) The name of the NAT gateway. If not provided, a default name is constructed.
.PARAMETER VnetName
    (Optional) The name of the virtual network. If not provided, a default name is constructed.
.PARAMETER SubnetNames
    (Optional) An array of subnet names to update. If not provided, a default set is used.
.EXAMPLE
    NatGatewayEnableDisable -Enable -ResourceGroup "dev-saf-rg-homelab"
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function NatGatewayEnableDisable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ParameterSetName = "Enable")]
        [switch]$Enable,
        [Parameter(Mandatory = $false, ParameterSetName = "Disable")]
        [switch]$Disable,
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,
        [Parameter(Mandatory = $false)]
        [string]$NatGatewayName,
        [Parameter(Mandatory = $false)]
        [string]$VnetName,
        [Parameter(Mandatory = $false)]
        [string[]]$SubnetNames
    )

    # Ensure we're connected to Azure
    if (-not (Connect-AzureAccount)) {
        Write-Log -Message "Failed to connect to Azure. Operation aborted." -Level Error
        return @{ Success = $false; Message = "Failed to connect to Azure." }
    }

    # Retrieve configuration if needed
    $config = Get-Configuration
    if (-not $NatGatewayName) {
        $NatGatewayName = "$($config.env)-$($config.loc)-natgw-$($config.project)"
    }
    if (-not $VnetName) {
        $VnetName = "$($config.env)-$($config.loc)-vnet-$($config.project)"
    }
    if (-not $SubnetNames) {
        $SubnetNames = @("$($config.env)-$($config.project)-snet-default", "$($config.env)-$($config.project)-snet-app")
    }
    
    # Check if resource group exists
    if (-not (Test-ResourceGroup -ResourceGroupName $ResourceGroup)) {
        Write-Log -Message "Resource group '$ResourceGroup' does not exist. Operation aborted." -Level Error
        return @{ Success = $false; Message = "Resource group does not exist." }
    }
    
    if ($Enable) {
        Write-Log -Message "Enabling NAT Gateway '$NatGatewayName' in resource group '$ResourceGroup'" -Level Info
        try {
            foreach ($subnet in $SubnetNames) {
                $cmd = "az network vnet subnet update --resource-group $ResourceGroup --vnet-name $VnetName --name $subnet --nat-gateway $NatGatewayName"
                Write-Log -Message "Executing: $cmd" -Level Debug
                $result = Invoke-Expression $cmd
                if (-not $?) {
                    throw "Command execution failed for subnet $subnet"
                }
            }
            Write-Log -Message "NAT Gateway enabled successfully." -Level Success
            return @{ Success = $true; Message = "NAT Gateway enabled." }
        }
        catch {
            Write-Log -Message "Error enabling NAT Gateway: $_" -Level Error
            return @{ Success = $false; Message = "Failed to enable NAT Gateway: $_" }
        }
    }
    elseif ($Disable) {
        Write-Log -Message "Disabling NAT Gateway '$NatGatewayName' in resource group '$ResourceGroup'" -Level Info
        try {
            foreach ($subnet in $SubnetNames) {
                $cmd = "az network vnet subnet update --resource-group $ResourceGroup --vnet-name $VnetName --name $subnet --remove natGateway"
                Write-Log -Message "Executing: $cmd" -Level Debug
                $result = Invoke-Expression $cmd
                if (-not $?) {
                    throw "Command execution failed for subnet $subnet"
                }
            }
            Write-Log -Message "NAT Gateway disabled successfully." -Level Success
            return @{ Success = $true; Message = "NAT Gateway disabled." }
        }
        catch {
            Write-Log -Message "Error disabling NAT Gateway: $_" -Level Error
            return @{ Success = $false; Message = "Failed to disable NAT Gateway: $_" }
        }
    }
    else {
        Write-Log -Message "No valid operation specified. Use -Enable or -Disable." -Level Error
        return @{ Success = $false; Message = "No operation specified." }
    }
}
