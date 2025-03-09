function Deploy-VPNGatewayComponent {
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

    Write-Log -Message "Deploying VPN gateway using vpn-gateway.bicep" -Level Info
    $templateFile = Join-Path -Path $templatesPath -ChildPath "vpn-gateway.bicep"
    $resourceName = "$env-$loc-vpng-$project"

    if ($BackgroundMonitor) {
        Write-Log -Message "Launching VPN gateway deployment in background." -Level Info
        # Offload the entire VPN gateway branch to a background job.
        $job = Start-Job -ScriptBlock {
            param($ResourceGroup, $templateFile, $commonParams, $resourceName)
            Write-Output "Background job started for VPN Gateway deployment..."
            $deployCmd = @("az", "deployment", "group", "create", "--template-file", $templateFile) + $commonParams
            Write-Output "Executing: $($deployCmd -join ' ')"
            & $deployCmd[0] $deployCmd[1..($deployCmd.Length-1)] | Out-Null
            Start-BackgroundMonitoring -ResourceGroup $ResourceGroup -ResourceType "vnet-gateway" -ResourceName $resourceName -PollIntervalSeconds 30 -TimeoutMinutes 60
        } -ArgumentList $ResourceGroup, $templateFile, $commonParams, $resourceName
        Write-Log -Message "Background monitoring job started for VPN Gateway (Job ID: $($job.Id))." -Level Info
        $exportChoice = Read-Host "Export background job info for VPN Gateway? (Y/N)"
        if ($exportChoice -match '^(Y|y)$') { Export-JobInfo -Job $job }
        return $true
    }
    else {
        if (-not (Invoke-Deployment -TemplateFile $templateFile -ComponentName "VPN Gateway" -ResourceType "vnet-gateway" -ResourceName $resourceName -PollIntervalSeconds 30 -TimeoutMinutes 60)) {
            return $false
        }
    }
    return $true
}