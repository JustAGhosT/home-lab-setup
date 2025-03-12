function Deploy-VPNGatewayComponent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory=$true)]
        [string]$location,
        
        [Parameter(Mandatory=$true)]
        [string]$env,
        
        [Parameter(Mandatory=$true)]
        [string]$loc,
        
        [Parameter(Mandatory=$true)]
        [string]$project,
        
        [Parameter(Mandatory=$true)]
        [array]$commonParams,
        
        [Parameter(Mandatory=$true)]
        [string]$templatesPath,
        
        [Parameter(Mandatory=$false)]
        [switch]$Monitor,
        
        [Parameter(Mandatory=$false)]
        [switch]$BackgroundMonitor
    )

    Write-Log -Message "Deploying VPN gateway using vpn-gateway.bicep" -Level Info
    $templateFile = Join-Path -Path $templatesPath -ChildPath "vpn-gateway.bicep"
    $resourceName = "$env-$loc-vpng-$project"
    
    # Create a proper parameters array for the VPN Gateway template
    $vpnGatewayParams = @(
        "--resource-group"
        $ResourceGroup
    )
    
    # Add the necessary parameters for the VPN Gateway template
    $vpnGatewayParams += @(
        "--parameters"
        "location=$location"
        "env=$env"
        "loc=$loc"
        "project=$project"
        "enableVpnGateway=true"
    )
    
    # Get the virtual network name from common parameters
    $vnetName = ""
    foreach ($param in $commonParams) {
        if ($param -match "vnetName=(.+)") {
            $vnetName = $Matches[1]
            break
        }
        # Also check for existingVnetName which might be used
        if ($param -match "existingVnetName=(.+)") {
            $vnetName = $Matches[1]
            break
        }
    }
    
    # If we couldn't find the vnet name, construct it based on naming convention
    if ([string]::IsNullOrEmpty($vnetName)) {
        $vnetName = "$env-$loc-vnet-$project"
        Write-Log -Message "Virtual network name not found in parameters, using default: $vnetName" -Level Warning
    }
    
    # Add the existing VNet name parameter
    $vpnGatewayParams += "existingVnetName=$vnetName"
    
    # Add any other parameters that might be needed for the VPN Gateway
    # You can add more parameters here as needed, for example:
    # $vpnGatewayParams += "gatewaySubnetPrefix=10.0.255.0/27"
    # $vpnGatewayParams += "enablePointToSiteVpn=false"
    
    # Use the shared Deploy-Component function and store the result
    $deploymentResult = Deploy-Component -ResourceGroup $ResourceGroup `
                    -TemplateFile $templateFile `
                    -ResourceName $resourceName `
                    -ResourceType "vnet-gateway" `
                    -ComponentName "VPN Gateway" `
                    -CommonParams $vpnGatewayParams `
                    -PollIntervalSeconds 30 `
                    -TimeoutMinutes 60 `
                    -Monitor:$Monitor `
                    -BackgroundMonitor:$BackgroundMonitor
    
    # Add a warning message about VPN Gateway costs if deployment was successful
    if ($deploymentResult -eq $true) {
        Write-ColorOutput -Text "`nIMPORTANT: The VPN Gateway will continue to incur charges until explicitly deleted." -ForegroundColor Yellow
        Write-ColorOutput -Text "Use option 5 to check deployment status. When finished testing, consider deleting the VPN Gateway." -ForegroundColor Yellow
    }
    
    # Return only the deployment result
    return $deploymentResult
}
