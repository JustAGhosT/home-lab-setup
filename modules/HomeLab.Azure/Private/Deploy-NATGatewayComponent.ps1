function Deploy-NATGatewayComponent {
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

    Write-Log -Message "Deploying NAT gateway using nat-gateway.bicep" -Level Info
    $templateFile = Join-Path -Path $templatesPath -ChildPath "nat-gateway.bicep"
    $resourceName = "$env-$loc-natgw-$project"
    if (-not (Invoke-Deployment -TemplateFile $templateFile -ComponentName "NAT Gateway" -ResourceType "nat-gateway" -ResourceName $resourceName -PollIntervalSeconds 10)) {
        return $false
    }

    if ($BackgroundMonitor) {
        Write-Log -Message "Launching background monitoring for NAT Gateway: $resourceName" -Level Info
        $job = Start-BackgroundMonitoring -ResourceGroup $ResourceGroup -ResourceType "nat-gateway" -ResourceName $resourceName -PollIntervalSeconds 10
        Write-Log -Message "Background monitoring started for NAT Gateway (Job ID: $($job.JobId))" -Level Info
        $exportChoice = Read-Host "Export background job info for NAT Gateway? (Y/N)"
        if ($exportChoice -match '^(Y|y)$') { Export-JobInfo -Job $job }
        return $true
    }

    return $true
}