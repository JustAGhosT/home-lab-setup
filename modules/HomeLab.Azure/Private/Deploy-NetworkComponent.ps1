function Deploy-NetworkComponent {
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

    Write-Log -Message "Deploying network resources using network.bicep" -Level Info
    $templateFile = Join-Path -Path $templatesPath -ChildPath "network.bicep"
    $resourceName = "$env-$loc-vnet-$project"
    if (-not (Invoke-Deployment -TemplateFile $templateFile -ComponentName "Network" -ResourceType "vnet" -ResourceName $resourceName -PollIntervalSeconds 10)) {
        return $false
    }

    if ($BackgroundMonitor) {
        Write-Log -Message "Initiating background monitoring for Virtual Network: $resourceName" -Level Info
        $job = Start-BackgroundMonitoring -ResourceGroup $ResourceGroup -ResourceType "vnet" -ResourceName $resourceName -PollIntervalSeconds 10
        Write-Log -Message "Background monitoring started for Virtual Network (Job ID: $($job.JobId))" -Level Info
        $exportChoice = Read-Host "Export background job info for Virtual Network? (Y/N)"
        if ($exportChoice -match '^(Y|y)$') { Export-JobInfo -Job $job }
        return $true
    }

    return $true
}