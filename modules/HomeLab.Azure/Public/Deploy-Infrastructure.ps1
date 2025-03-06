<#
.SYNOPSIS
    Deploys Azure infrastructure for HomeLab.
.DESCRIPTION
    Retrieves global configuration and deploys either the full infrastructure or a specific component
    (network, VPN gateway, or NAT gateway) using the corresponding Bicep templates.
.PARAMETER ComponentsOnly
    Optional. Specifies a single component to deploy ("network", "vpngateway", or "natgateway").
    If not specified, all components will be deployed.
.PARAMETER ResourceGroup
    Optional. The name of the resource group to deploy to. If not provided, it will be constructed from configuration.
.EXAMPLE
    Deploy-Infrastructure -ComponentsOnly "network"
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Deploy-Infrastructure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet("network", "vpngateway", "natgateway")]
        [string]$ComponentsOnly,
        
        [Parameter(Mandatory=$false)]
        [string]$ResourceGroup
    )
    
    # Ensure we're connected to Azure
    if (-not (Connect-AzureAccount)) {
        Write-Log -Message "Failed to connect to Azure. Deployment aborted." -Level Error
        return $false
    }
    
    # Retrieve global configuration
    $config = Get-Configuration
    $env = $config.env
    $loc = $config.loc
    $project = $config.project
    $location = $config.location
    
    # Construct the resource group name if not provided
    if (-not $ResourceGroup) {
        $ResourceGroup = "$env-$loc-rg-$project"
    }
    
    # Check if resource group exists, create if it doesn't
    if (-not (Test-ResourceGroup -ResourceGroupName $ResourceGroup)) {
        Write-Log -Message "Creating resource group '$ResourceGroup' in location '$location'..." -Level Info
        $result = az group create --name $ResourceGroup --location $location
        if (-not $?) {
            Write-Log -Message "Failed to create resource group. Deployment aborted." -Level Error
            return $false
        }
    }
    
    # Get the templates path
    $templatesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Templates"
    
    Write-Log -Message "Starting deployment for resource group: $ResourceGroup" -Level Info
    
    # Deploy the specified component or all components
    if ($ComponentsOnly -eq "network") {
        Write-Log -Message "Deploying network resources using network.bicep" -Level Info
        $templateFile = Join-Path -Path $templatesPath -ChildPath "network.bicep"
        $result = az deployment group create --resource-group $ResourceGroup `
                    --template-file $templateFile `
                    --parameters location=$location env=$env loc=$loc project=$project
        Write-Log -Message "Network deployment completed with status: $($result.provisioningState)" -Level Info
    }
    elseif ($ComponentsOnly -eq "vpngateway") {
        Write-Log -Message "Deploying VPN gateway using vpn-gateway.bicep" -Level Info
        $templateFile = Join-Path -Path $templatesPath -ChildPath "vpn-gateway.bicep"
        $result = az deployment group create --resource-group $ResourceGroup `
                    --template-file $templateFile `
                    --parameters location=$location env=$env loc=$loc project=$project
        Write-Log -Message "VPN gateway deployment completed with status: $($result.provisioningState)" -Level Info
    }
    elseif ($ComponentsOnly -eq "natgateway") {
        Write-Log -Message "Deploying NAT gateway using nat-gateway.bicep" -Level Info
        $templateFile = Join-Path -Path $templatesPath -ChildPath "nat-gateway.bicep"
        $result = az deployment group create --resource-group $ResourceGroup `
                    --template-file $templateFile `
                    --parameters location=$location env=$env loc=$loc project=$project
        Write-Log -Message "NAT gateway deployment completed with status: $($result.provisioningState)" -Level Info
    }
    else {
        Write-Log -Message "Deploying full infrastructure: Network, VPN Gateway, and NAT Gateway" -Level Info
        
        # Deploy network resources
        $networkTemplate = Join-Path -Path $templatesPath -ChildPath "network.bicep"
        Write-Log -Message "Deploying network using $networkTemplate" -Level Info
        $resultNetwork = az deployment group create --resource-group $ResourceGroup `
                            --template-file $networkTemplate `
                            --parameters location=$location env=$env loc=$loc project=$project
        Write-Log -Message "Network deployment completed with status: $($resultNetwork.provisioningState)" -Level Info
        
        # Deploy VPN gateway
        $vpnTemplate = Join-Path -Path $templatesPath -ChildPath "vpn-gateway.bicep"
        Write-Log -Message "Deploying VPN gateway using $vpnTemplate" -Level Info
        $resultVpn = az deployment group create --resource-group $ResourceGroup `
                            --template-file $vpnTemplate `
                            --parameters location=$location env=$env loc=$loc project=$project
        Write-Log -Message "VPN gateway deployment completed with status: $($resultVpn.provisioningState)" -Level Info
        
        # Deploy NAT gateway
        $natTemplate = Join-Path -Path $templatesPath -ChildPath "nat-gateway.bicep"
        Write-Log -Message "Deploying NAT gateway using $natTemplate" -Level Info
        $resultNat = az deployment group create --resource-group $ResourceGroup `
                            --template-file $natTemplate `
                            --parameters location=$location env=$env loc=$loc project=$project
        Write-Log -Message "NAT gateway deployment completed with status: $($resultNat.provisioningState)" -Level Info
    }
    
    Write-Log -Message "Deployment completed successfully." -Level Success
    return $true
}
