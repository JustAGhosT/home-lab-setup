<#
.SYNOPSIS
    Deploys Azure infrastructure for HomeLab.
.DESCRIPTION
    Retrieves global configuration and deploys either the full infrastructure or a specific component
    (network, VPN gateway, or NAT gateway) using the corresponding Bicep templates.
.EXAMPLE
    Deploy-Infrastructure -ComponentsOnly "network"
.NOTES
    Author: Jurie Smit
    Date: March 5, 2025
#>
function Deploy-Infrastructure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ComponentsOnly
    )
    
    # Retrieve global configuration
    $config = Get-Configuration
    $env = $config.env
    $loc = $config.loc
    $project = $config.project
    $location = $config.location  # Note: use the proper key; adjust if needed
    
    # Construct the resource group name based on a naming convention.
    $resourceGroup = "$env-$loc-rg-$project"
    
    Write-Log -Message "Starting deployment for resource group: $resourceGroup" -Level INFO
    
    if ($ComponentsOnly -eq "network") {
        Write-Log -Message "Deploying network resources using network.bicep" -Level INFO
        $result = az deployment group create --resource-group $resourceGroup `
                    --template-file "$PSScriptRoot\network.bicep" `
                    --parameters location=$location env=$env loc=$loc project=$project
        Write-Log -Message "Network deployment result: $result" -Level INFO
    }
    elseif ($ComponentsOnly -eq "vpngateway") {
        Write-Log -Message "Deploying VPN gateway using vpn-gateway.bicep" -Level INFO
        $result = az deployment group create --resource-group $resourceGroup `
                    --template-file "$PSScriptRoot\vpn-gateway.bicep" `
                    --parameters location=$location env=$env loc=$loc project=$project
        Write-Log -Message "VPN gateway deployment result: $result" -Level INFO
    }
    elseif ($ComponentsOnly -eq "natgateway") {
        Write-Log -Message "Deploying NAT gateway using nat-gateway.bicep" -Level INFO
        $result = az deployment group create --resource-group $resourceGroup `
                    --template-file "$PSScriptRoot\nat-gateway.bicep" `
                    --parameters location=$location env=$env loc=$loc project=$project
        Write-Log -Message "NAT gateway deployment result: $result" -Level INFO
    }
    else {
        Write-Log -Message "Deploying full infrastructure: Network, VPN Gateway, and NAT Gateway" -Level INFO
        
        # Deploy network resources
        $resultNetwork = az deployment group create --resource-group $resourceGroup `
                            --template-file "$PSScriptRoot\network.bicep" `
                            --parameters location=$location env=$env loc=$loc project=$project
        Write-Log -Message "Network deployment result: $resultNetwork" -Level INFO
        
        # Deploy VPN gateway
        $resultVpn = az deployment group create --resource-group $resourceGroup `
                            --template-file "$PSScriptRoot\vpn-gateway.bicep" `
                            --parameters location=$location env=$env loc=$loc project=$project
        Write-Log -Message "VPN gateway deployment result: $resultVpn" -Level INFO
        
        # Deploy NAT gateway
        $resultNat = az deployment group create --resource-group $resourceGroup `
                            --template-file "$PSScriptRoot\nat-gateway.bicep" `
                            --parameters location=$location env=$env loc=$loc project=$project
        Write-Log -Message "NAT gateway deployment result: $resultNat" -Level INFO
    }
}

Export-ModuleMember -Function Deploy-Infrastructure
