function Deploy-FullInfrastructure {
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

    Write-Log -Message "Deploying full infrastructure (Network, VPN Gateway, NAT Gateway)" -Level Info

    if (-not (Deploy-NetworkComponent -ResourceGroup $ResourceGroup -location $location -env $env -loc $loc -project $project -commonParams $commonParams -templatesPath $templatesPath -Monitor:$Monitor -BackgroundMonitor:$BackgroundMonitor)) {
        Write-Log -Message "Network deployment failed. Stopping full infrastructure deployment." -Level Error
        return $false
    }

    if (-not (Deploy-VPNGatewayComponent -ResourceGroup $ResourceGroup -location $location -env $env -loc $loc -project $project -commonParams $commonParams -templatesPath $templatesPath -Monitor:$Monitor -BackgroundMonitor:$BackgroundMonitor)) {
        Write-Log -Message "VPN Gateway deployment failed. Continuing with remaining components..." -Level Warning
    }

    if (-not (Deploy-NATGatewayComponent -ResourceGroup $ResourceGroup -location $location -env $env -loc $loc -project $project -commonParams $commonParams -templatesPath $templatesPath -Monitor:$Monitor -BackgroundMonitor:$BackgroundMonitor)) {
        Write-Log -Message "NAT Gateway deployment failed. Continuing with remaining components..." -Level Warning
    }

    Write-Log -Message "Full infrastructure deployment completed." -Level Info
    return $true
}
