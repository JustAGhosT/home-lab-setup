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
    
    # Use the shared Deploy-Component function and store the result
    $deploymentResult = Deploy-Component -ResourceGroup $ResourceGroup `
                    -TemplateFile $templateFile `
                    -ResourceName $resourceName `
                    -ResourceType "vnet-gateway" `
                    -ComponentName "VPN Gateway" `
                    -CommonParams $commonParams `
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
