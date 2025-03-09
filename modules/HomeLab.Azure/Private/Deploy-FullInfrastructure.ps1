function Deploy-FullInfrastructure {
    param(
        [string]$ResourceGroup,
        [string]$location,
        [string]$env,
        [string]$loc,
        [string]$project,
        [array]$commonParams,
        [string]$templatesPath,
        [switch]$Monitor,
        [switch]$BackgroundMonitor
    )

    Write-Log -Message "Deploying full infrastructure (Network, VPN Gateway, NAT Gateway)" -Level Info

    if (-not (Deploy-NetworkComponent -ResourceGroup $ResourceGroup -location $location -env $env -loc $loc -project $project -commonParams $commonParams -templatesPath $templatesPath -Monitor:$Monitor -BackgroundMonitor:$BackgroundMonitor)) {
        return $false
    }

    if (-not (Deploy-VPNGatewayComponent -ResourceGroup $ResourceGroup -location $location -env $env -loc $loc -project $project -commonParams $commonParams -templatesPath $templatesPath -Monitor:$Monitor -BackgroundMonitor:$BackgroundMonitor)) {
        return $false
    }

    if (-not (Deploy-NATGatewayComponent -ResourceGroup $ResourceGroup -location $location -env $env -loc $loc -project $project -commonParams $commonParams -templatesPath $templatesPath -Monitor:$Monitor -BackgroundMonitor:$BackgroundMonitor)) {
        return $false
    }

    return $true
}